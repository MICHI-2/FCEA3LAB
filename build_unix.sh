#!/bin/sh
# FCEA3LAB を mac / Linux でビルドする。
#   src/ は NASA CEA v3.3.4 (2f79a64) に patches/ を当て済みのソース。
#   必要なもの: gfortran, cmake (3.19 以上)
#     mac  : Homebrew で  brew install gcc cmake
#     Linux: Ubuntu/Debian で  sudo apt install gfortran cmake
#   成果物: ./FCEA3LAB/ (FCEA3LAB, thermo.lib, trans.lib)
#
#   sh build_unix.sh
set -eu
cd "$(dirname "$0")"
HERE="$(pwd)"

need() { command -v "$1" >/dev/null 2>&1 || { echo "ERROR: $1 が見つかりません。$2" >&2; exit 1; }; }
OS="$(uname -s)"
if [ "$OS" = "Darwin" ]; then
    HINT="brew install gcc cmake"
    # Homebrew の gfortran は gfortran-14 のように版付きの名前のことがある（環境変数 FC で指定も可）
    FC="${FC:-$(command -v gfortran || ls /opt/homebrew/bin/gfortran-* /usr/local/bin/gfortran-* 2>/dev/null | head -1 || true)}"
    CC_="$(command -v clang || command -v cc)"
else
    HINT="sudo apt install gfortran cmake"
    FC="${FC:-$(command -v gfortran || true)}"
    CC_="$(command -v gcc || command -v cc)"
fi
[ -n "$FC" ] || { echo "ERROR: gfortran が見つかりません。$HINT" >&2; exit 1; }
need cmake "$HINT"

# 配布先に gfortran が無くても動くよう、ランタイムは静的にリンクする。
#   Linux: 完全静的（glibc の版にも依存しない。ビルド機より古いディストリでも動く）
#   mac  : 完全静的は不可なので Fortran ランタイムだけ静的
#   mac のフラグは gfortran でリンクする対象だけに渡す（CMAKE_Fortran_STANDARD_LIBRARIES）。
#   全言語共通のリンクフラグにすると、CMake の C コンパイラ（clang）の確認で
#   "unsupported option '-static-libgcc'" になって止まる。
if [ "$OS" = "Linux" ]; then
    LDFLAGS_X="-static"
    FLIBS_X=""
else
    LDFLAGS_X=""
    # Homebrew の gfortran は Apple Silicon / Intel とも libquadmath も引き込む
    FLIBS_X="-static-libgfortran -static-libgcc -static-libquadmath"
fi

rm -rf build
cmake -S src -B build \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_Fortran_COMPILER="$FC" \
    -DCMAKE_C_COMPILER="$CC_" \
    -DCMAKE_Fortran_FLAGS="-fimplicit-none -ffree-line-length-none" \
    -DCMAKE_INSTALL_PREFIX=/opt/fcea3lab \
    -DCMAKE_EXE_LINKER_FLAGS="$LDFLAGS_X" \
    -DCMAKE_Fortran_STANDARD_LIBRARIES="$FLIBS_X" \
    -DCEA_ENABLE_BIND_C=ON \
    -DCEA_ENABLE_BIND_CXX=OFF \
    -DCEA_ENABLE_BIND_PYTHON=OFF \
    -DCEA_ENABLE_BIND_MATLAB=OFF \
    -DCEA_ENABLE_BIND_EXCEL=OFF \
    -DCEA_BUILD_TESTING=OFF
cmake --build build -j 4

rm -rf FCEA3LAB
mkdir -p FCEA3LAB
cp build/source/cea FCEA3LAB/FCEA3LAB
cp build/thermo.lib build/trans.lib FCEA3LAB/
cp -R samples data_src LICENSE.txt NOTICE.txt MODIFICATIONS.txt README.txt patches FCEA3LAB/ 2>/dev/null || true
{
    echo "FCEA3LAB 1.1  ($OS $(uname -m))"
    echo "upstream: NASA CEA v3.3.4-18-g2f79a64 + patches 0001-0004"
    echo "compiler: $("$FC" --version | head -1)"
    echo "built:    $(date '+%Y-%m-%d %H:%M')"
} > FCEA3LAB/BUILD_INFO.txt

echo
echo "== 依存ライブラリ（gfortran 由来のものが無いこと）"
if [ "$OS" = "Darwin" ]; then
    otool -L FCEA3LAB/FCEA3LAB
    # Homebrew 由来の dylib が残っていると、Homebrew の無い Mac では起動しない
    if otool -L FCEA3LAB/FCEA3LAB | tail -n +2 | grep -E "homebrew|/usr/local/|gfortran|quadmath|libgcc" >/dev/null; then
        echo "ERROR: Homebrew/gfortran の動的ライブラリに依存している（配布先で動かない）" >&2
        exit 1
    fi
else
    ldd FCEA3LAB/FCEA3LAB || true
fi

echo
echo "== 動作確認（別フォルダから、データベースを置かずに実行）"
T="$(mktemp -d)"
cp samples/*.inp "$T/"
cd "$T"
FAIL=0
for f in *.inp; do
    n="${f%.inp}"
    if echo "$n" | "$HERE/FCEA3LAB/FCEA3LAB" >/dev/null 2>&1 && [ -s "$n.out" ]; then
        echo "  ok   $n"
    else
        echo "  FAIL $n"; FAIL=1
    fi
done
cd "$HERE"
rm -rf "$T"
[ $FAIL -eq 0 ] || { echo "動作確認に失敗したケースがあります" >&2; exit 1; }
echo
echo "完了: $HERE/FCEA3LAB/  （フォルダごと配布する）"
if [ "$OS" = "Darwin" ]; then
    echo "注意: このバイナリは $(uname -m) 専用。Apple Silicon と Intel Mac は別々にビルドする。"
    echo "      ダウンロードした人の Mac で止められたら:  xattr -dr com.apple.quarantine <解凍したフォルダ>"
fi
