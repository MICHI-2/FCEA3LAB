FCEA3LAB 1.1 — mac / Linux 版のビルド
============================================================================

mac と Linux はバイナリの形式が違い（Mach-O と ELF）、さらに mac は
Apple Silicon（arm64）と Intel（x86_64）でも別物です。そのため、使う機械と
同じ種類の機械でビルドします。一度ビルドしたフォルダは、同じ種類の機械なら
そのまま配れます。

手順
----
  1. 準備
       mac  : Homebrew を入れたうえで  brew install gcc cmake
       Linux: sudo apt install gfortran cmake   （Ubuntu/Debian の場合）
  2. このフォルダで
       sh build_unix.sh
  3. 最後に「完了」と出れば、FCEA3LAB/ フォルダができている。
     フォルダごと好きな場所に置き、Windows 版と同じように使う:
       cd 作業フォルダ
       /path/to/FCEA3LAB/FCEA3LAB mycase
     （引数なしで起動すると、FCEA2 と同じくファイル名を聞かれる）

  スクリプトは最後に、データベースを置いていない別のフォルダから全サンプルを
  実行して確認する。「FAIL」が出たら配布しないこと。

Mac が手元に無い場合（GitHub Actions）
------------------------------------
  このフォルダをそのまま GitHub のリポジトリ（非公開で可）に push し、
  Actions タブ → build-macos → Run workflow を押す。Apple Silicon 版と
  Intel Mac 版が GitHub の macOS 機でビルド・動作確認され、実行ページ下部の
  Artifacts から FCEA3LAB-1.1-macos-arm64.tar.gz / -macos-x86_64.tar.gz を
  取得できる（設定は .github/workflows/build-macos.yml）。

使い方・FCEA2 との違い・照合結果は README.txt（Windows 版と共通）を参照。

中身
----
  src/               NASA CEA v3.3.4 (2f79a64) に patches/ を当て済みのソース
  patches/           当てた修正の差分（0001: 異常終了の修正, 0002: 配布用の変更, 0003: .plt 出力, 0004: 入力ファイルの探し方）
  build_unix.sh      ビルドと動作確認
  samples/ data_src/ README.txt MODIFICATIONS.txt LICENSE.txt NOTICE.txt
