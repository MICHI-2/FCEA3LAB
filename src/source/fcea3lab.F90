! FCEA3LAB support module.
!
! Added for FCEA3LAB (2026-10-04): an unofficial, redistributable build of the
! NASA CEA v3 legacy CLI. Not part of the upstream NASA CEA distribution.
!
! Provides the directory of the running executable so that thermo.lib and
! trans.lib shipped next to the executable are found regardless of the
! current working directory or the build-time install prefix.
!
! It also implements the CEA2 (FCEA2) ".plt" plot file: the variables listed
! after "plot" in the output dataset are written one row per point, with the
! CEA2 variable-name rules (see plot_value) and the CEA2 format
! ('#',2x,20A12 header / (1x,1p,20E12.4) rows, at most 20 variables).
module fcea3lab
    use, intrinsic :: iso_c_binding
    use, intrinsic :: iso_fortran_env, only: dp => real64
    implicit none
    private
    public :: fcea3lab_banner, get_exe_dir, get_cwd, clean_path_input
    public :: plot_point, plot_setup, plot_active, plot_add, plot_flush, plot_n

    integer, parameter :: plot_max_vars = 20
    integer, parameter :: plot_name_len = 15

    ! Values of one output point, already in the units used in the .out file.
    ! perf/perf_fr: pi/p, mach, ae/at, cf, ivac, isp (equilibrium / frozen)
    type :: plot_point
        real(dp) :: p = 0, t = 0, rho = 0, h = 0, u = 0, g = 0, s = 0
        real(dp) :: m = 0, mw = 0, cp = 0, gam = 0, son = 0
        real(dp) :: vis = 0, cond = 0, cond_fr = 0, pran = 0, pran_fr = 0
        real(dp) :: dlnt = 0, dlnp = 0
        real(dp) :: of = 0, pf = 0, phi = 0, fa = 0, req = 0
        logical  :: rocket = .false.
        real(dp) :: perf(6) = 0, perf_fr(6) = 0
        logical  :: det = .false.
        real(dp) :: p1 = 0, t1 = 0, h1 = 0, gam1 = 0, son1 = 0, vel = 0, detmach = 0
        character(plot_name_len), allocatable :: species(:)
        real(dp), allocatable :: x(:)
    end type

    integer :: plot_n = 0
    character(plot_name_len) :: plot_names(plot_max_vars)
    real(dp), allocatable :: plot_rows(:, :)
    integer :: plot_nrow = 0
    integer :: plot_unit = -1
    logical :: plot_opened = .false.

    character(*), parameter :: fcea3lab_banner = &
        'FCEA3LAB 1.1 -- unofficial build of NASA CEA 3.3.4 with local patches (not a NASA release)'

    interface
#if defined(CEA_OS_WINDOWS)
        function GetModuleFileNameA(hmodule, buf, nsize) bind(C, name='GetModuleFileNameA')
            import :: c_ptr, c_char, c_int32_t
            type(c_ptr), value :: hmodule
            character(kind=c_char) :: buf(*)
            integer(c_int32_t), value :: nsize
            integer(c_int32_t) :: GetModuleFileNameA
        end function
#elif defined(CEA_OS_APPLE)
        function ns_get_executable_path(buf, bufsize) bind(C, name='_NSGetExecutablePath')
            import :: c_char, c_int, c_int32_t
            character(kind=c_char) :: buf(*)
            integer(c_int32_t) :: bufsize
            integer(c_int) :: ns_get_executable_path
        end function
#else
        function readlink(path, buf, bufsize) bind(C, name='readlink')
            import :: c_char, c_size_t, c_intptr_t
            character(kind=c_char) :: path(*)
            character(kind=c_char) :: buf(*)
            integer(c_size_t), value :: bufsize
            integer(c_intptr_t) :: readlink
        end function
#endif
#if defined(CEA_OS_WINDOWS)
        function c_getcwd(buf, size) bind(C, name='_getcwd')
            import :: c_ptr, c_char, c_int
            character(kind=c_char) :: buf(*)
            integer(c_int), value :: size
            type(c_ptr) :: c_getcwd
        end function
#else
        function c_getcwd(buf, size) bind(C, name='getcwd')
            import :: c_ptr, c_char, c_size_t
            character(kind=c_char) :: buf(*)
            integer(c_size_t), value :: size
            type(c_ptr) :: c_getcwd
        end function
#endif
    end interface

contains

    function get_cwd() result(dir)
        ! Current working directory, or an empty string if unavailable.
        character(:), allocatable :: dir
        integer, parameter :: nmax = 4096
        character(kind=c_char) :: buf(nmax)
        type(c_ptr) :: p
        integer :: n
        buf = c_null_char
#if defined(CEA_OS_WINDOWS)
        p = c_getcwd(buf, int(nmax, c_int))
#else
        p = c_getcwd(buf, int(nmax, c_size_t))
#endif
        dir = ''
        if (.not. c_associated(p)) return
        n = 0
        do while (n < nmax)
            if (buf(n+1) == c_null_char) exit
            n = n + 1
        end do
        dir = repeat(' ', n)
        do n = 1, len(dir)
            dir(n:n) = buf(n)
        end do
    end function

    function clean_path_input(s) result(r)
        ! Clean a file name typed or dropped into a terminal: trim blanks and
        ! tabs, strip surrounding quotes, and undo backslash-escaped blanks
        ! ("My\ Folder") that the macOS Terminal inserts on drag and drop.
        character(*), intent(in) :: s
        character(:), allocatable :: r
        character(len(s)) :: t
        integer :: i, j, n
        t = s
        do i = 1, len(t)
            if (t(i:i) == char(9) .or. t(i:i) == char(13)) t(i:i) = ' '
        end do
        t = adjustl(t)
        n = len_trim(t)
        if (n >= 2) then
            if ((t(1:1) == '"' .and. t(n:n) == '"') .or. (t(1:1) == "'" .and. t(n:n) == "'")) then
                t = t(2:n-1)
                n = n - 2
            end if
        end if
        r = ''
        i = 1
        do while (i <= n)
            j = i
            if (t(i:i) == '\' .and. i < n) then
                if (t(i+1:i+1) == ' ') j = i + 1
            end if
            r = r // t(j:j)
            i = j + 1
        end do
    end function

    function get_exe_dir() result(dir)
        ! Directory (without trailing separator) of the running executable,
        ! or an empty string if it cannot be determined.
        character(:), allocatable :: dir
        integer, parameter :: nmax = 4096
        character(kind=c_char) :: buf(nmax)
        character(len=nmax) :: path
        integer :: n, i
#if defined(CEA_OS_APPLE)
        integer(c_int32_t) :: sz
#endif
#if defined(CEA_OS_WINDOWS)
        n = int(GetModuleFileNameA(c_null_ptr, buf, int(nmax, c_int32_t)))
#elif defined(CEA_OS_APPLE)
        sz = int(nmax, c_int32_t)
        if (ns_get_executable_path(buf, sz) == 0) then
            n = 0
            do while (n < nmax)
                if (buf(n+1) == c_null_char) exit
                n = n + 1
            end do
        else
            n = 0
        end if
#else
        n = int(readlink('/proc/self/exe'//c_null_char, buf, int(nmax - 1, c_size_t)))
#endif
        dir = ''
        if (n <= 0 .or. n >= nmax) return
        path = ''
        do i = 1, n
            path(i:i) = buf(i)
        end do
        do i = n, 1, -1
            if (path(i:i) == '/' .or. path(i:i) == '\') then
                dir = path(1:i-1)
                return
            end if
        end do
    end function

    !-------------------------------------------------------------------
    ! .plt support
    !-------------------------------------------------------------------

    subroutine plot_setup(raw)
        ! Read the plot variable list of one problem from its raw input text.
        ! CEA2 rules: in the "outp" dataset, after a word beginning with "pl",
        ! every non-numeric word that is not an output keyword (cal, tran/trn,
        ! trac, short, massf, deb/dbg, si...; here also long) is a plot variable.
        character(*), intent(in) :: raw
        integer :: pos, eol, k, ntok
        character(:), allocatable :: line
        character(64) :: tok(256)
        logical :: in_outp, plotting
        character(4) :: c4

        plot_n = 0
        plot_nrow = 0
        if (allocated(plot_rows)) deallocate(plot_rows)
        in_outp = .false.
        plotting = .false.
        pos = 1
        do while (pos <= len(raw))
            eol = index(raw(pos:), new_line('a'))
            if (eol == 0) then
                line = raw(pos:)
                pos = len(raw) + 1
            else
                line = raw(pos:pos+eol-2)
                pos = pos + eol
            end if
            call split_words(line, tok, ntok)
            if (ntok == 0) cycle
            c4 = lower(tok(1)(1:4))
            k = 1
            if (any(c4 == ['prob', 'reac', 'outp', 'only', 'omit', 'inse', 'end ', 'ther', 'tran'])) then
                in_outp = (c4 == 'outp')
                k = 2
            end if
            if (.not. in_outp) cycle
            do while (k <= ntok)
                call classify(tok(k))
                k = k + 1
            end do
        end do

    contains

        subroutine classify(w)
            character(*), intent(in) :: w
            character(5) :: lw
            if (is_number(w)) return
            lw = lower(w(1:min(5, len_trim(w))))
            if (lw(1:3) == 'cal') return
            if (lw(1:4) == 'tran' .or. lw(1:3) == 'trn') return
            if (lw(1:4) == 'trac') return
            if (lw == 'short') return
            if (lw == 'massf') return
            if (lw(1:3) == 'deb' .or. lw(1:3) == 'dbg') return
            if (lw(1:2) == 'si') return
            if (lw(1:4) == 'long') return
            if (plotting) then
                if (plot_n < plot_max_vars) then
                    plot_n = plot_n + 1
                    plot_names(plot_n) = w
                end if
            else if (lw(1:2) == 'pl') then
                plotting = .true.
            end if
        end subroutine

    end subroutine

    logical function plot_active()
        plot_active = plot_n > 0
    end function

    subroutine plot_add(pt)
        type(plot_point), intent(in) :: pt
        real(dp), allocatable :: tmp(:, :)
        integer :: i
        if (plot_n == 0) return
        if (.not. allocated(plot_rows)) allocate(plot_rows(plot_max_vars, 64))
        if (plot_nrow == size(plot_rows, 2)) then
            allocate(tmp(plot_max_vars, 2*size(plot_rows, 2)))
            tmp(:, 1:plot_nrow) = plot_rows(:, 1:plot_nrow)
            call move_alloc(tmp, plot_rows)
        end if
        plot_nrow = plot_nrow + 1
        do i = 1, plot_n
            plot_rows(i, plot_nrow) = plot_value(plot_names(i), pt)
        end do
    end subroutine

    subroutine plot_flush(stem)
        ! Append this problem's block to <stem>.plt (created on first use),
        ! like CEA2: header, one row per point, header again.
        character(*), intent(in) :: stem
        integer :: i, j
        if (plot_n == 0) return
        if (.not. plot_opened) then
            open(newunit=plot_unit, file=stem//'.plt', status='replace', action='write')
            plot_opened = .true.
        end if
        write(plot_unit, '("#",2x,20A12)') (plot_names(j)(1:12), j=1,plot_n)
        do i = 1, plot_nrow
            write(plot_unit, '(1x,1p,20E12.4)') (plot_rows(j, i), j=1,plot_n)
        end do
        write(plot_unit, '("#",2x,20A12)') (plot_names(j)(1:12), j=1,plot_n)
        flush(plot_unit)
        plot_nrow = 0
    end subroutine

    function plot_value(name, pt) result(v)
        ! CEA2 name rules (case-sensitive, matched on leading characters):
        !  - a '1' after the first character selects the initial state of a
        !    detonation: p1 t1 h1 gam1 son1 (so "p/p1" gives p1, as in CEA2)
        !  - thermodynamic: p t rho h u g s m mw cp gam son vis cond pran
        !    dlnt dlnp, with "fz"/"fr" for frozen cond/pran
        !  - mixture: o/f %f f/a phi r (equivalence ratio r)
        !  - rocket: pi/p (pip) mach ae cf ivac isp; with fz/fr -> frozen values
        !  - detonation: vel (detonation velocity), mach
        !  - otherwise a product species name -> mole (or mass) fraction
        ! Unknown names give 0, as in CEA2.
        character(*), intent(in) :: name
        type(plot_point), intent(in) :: pt
        real(dp) :: v
        character(plot_name_len) :: w
        logical :: frz
        integer :: i

        w = name
        v = 0.0d0
        if (index(w(2:), '1') /= 0) then
            if (.not. pt%det) return
            if (w(1:3) == 'son') then
                v = pt%son1
            else if (w(1:3) == 'gam') then
                v = pt%gam1
            else if (w(1:1) == 'h') then
                v = pt%h1
            else if (w(1:1) == 't') then
                v = pt%t1
            else if (w(1:1) == 'p') then
                v = pt%p1
            end if
            return
        end if

        if (index(w, 'dlnt') /= 0) then
            v = pt%dlnt
        else if (index(w, 'dlnp') /= 0) then
            v = pt%dlnp
        else if (w(1:4) == 'pran') then
            v = merge(pt%pran_fr, pt%pran, index(w(3:), 'fz') /= 0 .or. index(w(3:), 'fr') /= 0)
        else if (w(1:4) == 'cond') then
            v = merge(pt%cond_fr, pt%cond, index(w(3:), 'fz') /= 0 .or. index(w(3:), 'fr') /= 0)
        else if (w(1:3) == 'phi') then
            v = pt%phi
        else if (w(1:2) == 'p ') then
            v = pt%p
        else if (w(1:1) == 't') then
            v = pt%t
        else if (w(1:3) == 'rho') then
            v = pt%rho
        else if (w(1:1) == 'h') then
            v = pt%h
        else if (w(1:1) == 'u') then
            v = pt%u
        else if (w(1:3) == 'gam') then
            v = pt%gam
        else if (w(1:3) == 'son') then
            v = pt%son
        else if (w(1:2) == 'g ') then
            v = pt%g
        else if (w(1:2) == 's ') then
            v = pt%s
        else if (w(1:1) == 'm' .and. w(1:2) /= 'ma') then
            v = merge(pt%mw, pt%m, w(1:2) == 'mw')
        else if (w(1:2) == 'cp') then
            v = pt%cp
        else if (w(1:3) == 'vis') then
            v = pt%vis
        else if (w(1:3) == 'o/f') then
            v = pt%of
        else if (w(1:2) == '%f') then
            v = pt%pf
        else if (w(1:3) == 'f/a') then
            v = pt%fa
        else if (w(1:1) == 'r') then
            v = pt%req
        else if (pt%rocket .and. (w(1:4) == 'pi/p' .or. w(1:3) == 'pip' .or. w(1:4) == 'mach' .or. &
                 w(1:2) == 'ae' .or. w(1:2) == 'cf' .or. w(1:4) == 'ivac' .or. w(1:3) == 'isp')) then
            frz = index(w(2:), 'fz') /= 0 .or. index(w(2:), 'fr') /= 0
            if (w(1:4) == 'pi/p' .or. w(1:3) == 'pip') then
                i = 1
            else if (w(1:4) == 'mach') then
                i = 2
            else if (w(1:2) == 'ae') then
                i = 3
            else if (w(1:2) == 'cf') then
                i = 4
            else if (w(1:4) == 'ivac') then
                i = 5
            else
                i = 6
            end if
            v = merge(pt%perf_fr(i), pt%perf(i), frz)
        else if (pt%det .and. index(w, 'vel') /= 0) then
            v = pt%vel
        else if (pt%det .and. index(w, 'mach') /= 0) then
            v = pt%detmach
        else if (allocated(pt%species)) then
            do i = 1, size(pt%species)
                if (trim(adjustl(pt%species(i))) == trim(w) .or. &
                    ('*'//trim(adjustl(pt%species(i))) == trim(w))) then
                    v = pt%x(i)
                    return
                end if
            end do
        end if
    end function

    subroutine split_words(line, tok, ntok)
        ! Split on blanks, tabs, commas and '='; drop comments ('#' or '!').
        character(*), intent(in) :: line
        character(64), intent(out) :: tok(:)
        integer, intent(out) :: ntok
        integer :: i, start
        character :: c
        logical :: sep
        ntok = 0
        start = 0
        do i = 1, len(line) + 1
            if (i <= len(line)) then
                c = line(i:i)
                if (c == '#' .or. c == '!') then
                    sep = .true.
                else
                    sep = (c == ' ' .or. c == char(9) .or. c == ',' .or. c == '=' .or. c == char(13))
                end if
            else
                sep = .true.
            end if
            if (sep) then
                if (start > 0 .and. ntok < size(tok)) then
                    ntok = ntok + 1
                    tok(ntok) = line(start:i-1)
                end if
                start = 0
                if (i <= len(line)) then
                    if (line(i:i) == '#' .or. line(i:i) == '!') exit
                end if
            else if (start == 0) then
                start = i
            end if
        end do
    end subroutine

    logical function is_number(w)
        character(*), intent(in) :: w
        real(dp) :: x
        integer :: ios
        character :: c
        is_number = .false.
        if (len_trim(w) == 0) return
        c = w(1:1)
        if (.not. (index('0123456789+-.', c) > 0)) return
        read(w, *, iostat=ios) x
        is_number = (ios == 0)
    end function

    function lower(s) result(r)
        character(*), intent(in) :: s
        character(len(s)) :: r
        integer :: i, ic
        r = s
        do i = 1, len(s)
            ic = iachar(s(i:i))
            if (ic >= iachar('A') .and. ic <= iachar('Z')) r(i:i) = achar(ic + 32)
        end do
    end function

end module
