#!/usr/bin/env bash
# Builds the release APKs (one per Android architecture, plus a universal
# one that runs on every device) and publishes them, with the Linux AppImage
# when tool/build_appimage.sh has built it (and CobaLagi-Steam-Installer.sh, which
# adds it to Steam: linux/steam/) and the Windows and macOS zips when CI has
# built them,
# as a GitHub Release, tagged
# v<name>+<build> from pubspec.yaml, with the build's release notes from
# store/changelogs/<locale>/<build>.txt.
#
#   tool/release_apks.sh            # build, then publish as a pre-release
#   tool/release_apks.sh --dry-run  # build and show what would be published
#   tool/release_apks.sh --latest   # publish as the latest full release
#   tool/release_apks.sh --build-only  # only build the APKs (CI's android job)
#   tool/release_apks.sh --skip-build  # publish APKs already in
#                                      # build/app/outputs/flutter-apk (CI)
#
# GitHub Actions runs it after every version bump
# (.github/workflows/release-apks.yml), with the upload key from the
# repository's secrets; it also runs locally with android/key.properties.
set -euo pipefail
cd "$(dirname "$0")/.."

dry_run=false
prerelease=true
build_apks=true
publish=true
for arg in "$@"; do
  case "$arg" in
    --dry-run) dry_run=true ;;
    --latest) prerelease=false ;;
    --build-only) publish=false ;;
    --skip-build) build_apks=false ;;
    *) echo "Unknown option: $arg" >&2; exit 2 ;;
  esac
done

version="$(sed -n 's/^version: *//p' pubspec.yaml)"
name="${version%+*}"
build="${version#*+}"
tag="v$version"
out="build/release/$tag"

# Without the upload key, release builds are debug-signed and would not
# install over each other; never publish those.
if $build_apks && [ ! -f android/key.properties ]; then
  echo "android/key.properties is missing: APKs would be debug-signed." >&2
  exit 1
fi
for locale in en-US id; do
  if [ ! -f "store/changelogs/$locale/$build.txt" ]; then
    echo "No release notes in store/changelogs/$locale/$build.txt." >&2
    exit 1
  fi
done
# In CI the workflow checks out exactly the pushed commit.
if ! $dry_run && [ -z "${GITHUB_ACTIONS:-}" ]; then
  if [ -n "$(git status --porcelain)" ]; then
    echo "Commit or stash your changes first: the release is tagged at HEAD." >&2
    exit 1
  fi
  git fetch --quiet origin
  if [ "$(git rev-parse HEAD)" != "$(git rev-parse '@{u}')" ]; then
    echo "Push first: HEAD differs from its upstream branch." >&2
    exit 1
  fi
fi
if ! $dry_run; then
  if gh release view "$tag" >/dev/null 2>&1; then
    echo "Release $tag already exists. Bump the build number first." >&2
    exit 1
  fi
fi

# GitHub's own version codes, so any newer APK installs over any older one
# (android/app/build.gradle.kts).
if $build_apks; then
  export COBALAGI_GITHUB_APK=1
  flutter build apk --release --split-per-abi --dart-define=GITHUB_RELEASE=true
  # The universal APK last: it has its own file name, so both sets remain.
  flutter build apk --release --dart-define=GITHUB_RELEASE=true
fi
if ! $publish; then
  echo "Built the APKs in build/app/outputs/flutter-apk."
  exit 0
fi

rm -rf "$out"
mkdir -p "$out"
for abi in arm64-v8a armeabi-v7a x86_64; do
  cp "build/app/outputs/flutter-apk/app-$abi-release.apk" \
    "$out/cobalagi-$name-build$build-$abi.apk"
done
cp build/app/outputs/flutter-apk/app-release.apk \
  "$out/cobalagi-$name-build$build-universal.apk"
# Built on Linux (in CI, by another job), so it is optional here.
appimage="CobaLagi-x86_64.AppImage"
# The Steam installer is a launcher, like Decky's: double-clicked, it runs
# the newest CobaLagi-Steam-Installer.sh from master, which downloads the
# AppImage and the library pictures itself.
steam_script="CobaLagi-Steam-Installer.desktop"
if [ -f "build/release/$appimage" ]; then
  cp "build/release/$appimage" "$out/"
  cp "linux/steam/$steam_script" "$out/"
else
  appimage=""
  steam_script=""
fi
# Built on Windows (in CI, by another job), so it is optional too.
windows_zip="CobaLagi-Windows-x64.zip"
if [ -f "build/release/$windows_zip" ]; then
  cp "build/release/$windows_zip" "$out/"
else
  windows_zip=""
fi
# Signed and notarized in CI (macos.yml), so it is optional too.
macos_zip="CobaLagi-macOS.zip"
if [ -f "build/release/$macos_zip" ]; then
  cp "build/release/$macos_zip" "$out/"
else
  macos_zip=""
fi
files=("$out"/*.apk)
if [ -n "$appimage" ]; then files+=("$out/$appimage" "$out/$steam_script"); fi
if [ -n "$windows_zip" ]; then files+=("$out/$windows_zip"); fi
if [ -n "$macos_zip" ]; then files+=("$out/$macos_zip"); fi

(cd "$out" && shasum -a 256 ./*.apk ${appimage:+"./$appimage"} ${steam_script:+"./$steam_script"} \
  ${windows_zip:+"./$windows_zip"} ${macos_zip:+"./$macos_zip"} |
  sed 's| \./| |' > SHA256SUMS.txt)

notes="$out/notes.md"
# Each file in the table links to its download, so it can be clicked.
repo="$(git remote get-url origin | sed -E 's#^(https://github.com/|git@github.com:)##; s#\.git$##')"
download="https://github.com/$repo/releases/download/${tag//+/%2B}"
file_link() { echo "[\`$1\`]($download/$1)"; }
# One line per paragraph: GitHub keeps every line break in release notes.
# Each language folds open on its own (release notes run no scripts), English
# open; the blank lines around the Markdown inside <details> are required.
# say <English> <Indonesian> prints the line in the language being written.
say() { if [ "$lang" = en ]; then echo "$1"; else echo "$2"; fi; }
language_notes() {
  say "### What's new" "### Yang baru"
  echo
  cat "store/changelogs/$(say en-US id)/$build.txt"
  echo
  say "### Which file?" "### File yang mana?"
  echo
  say "| File | For |" "| File | Untuk |"
  echo "|---|---|"
  echo "| $(file_link "cobalagi-$name-build$build-universal.apk") | $(say "Any Android device. Pick this if you're not sure (largest download)." "Semua perangkat Android. Pilih ini kalau ragu (unduhan paling besar).") |"
  echo "| $(file_link "cobalagi-$name-build$build-arm64-v8a.apk") | $(say "Most phones and tablets" "Kebanyakan ponsel dan tablet") |"
  echo "| $(file_link "cobalagi-$name-build$build-armeabi-v7a.apk") | $(say "Older 32-bit devices" "Perangkat 32-bit yang lebih lama") |"
  echo "| $(file_link "cobalagi-$name-build$build-x86_64.apk") | $(say "Emulators and Chromebooks" "Emulator dan Chromebook") |"
  if [ -n "$appimage" ]; then
    echo "| $(file_link "$appimage") | $(say "Linux PCs and the Steam Deck" "PC Linux dan Steam Deck") |"
    echo "| $(file_link "$steam_script") | $(say "Installs the newest Coba Lagi on the Steam Deck and adds it to Steam, with its pictures" "Memasang Coba Lagi terbaru di Steam Deck dan menambahkannya ke Steam, lengkap dengan gambarnya") |"
  fi
  if [ -n "$windows_zip" ]; then
    echo "| $(file_link "$windows_zip") | $(say "Windows 10 and 11 PCs (64-bit)" "PC Windows 10 dan 11 (64-bit)") |"
  fi
  if [ -n "$macos_zip" ]; then
    echo "| $(file_link "$macos_zip") | $(say "Macs with Apple silicon (M1 or newer), macOS 12 or later" "Mac dengan Apple silicon (M1 atau lebih baru), macOS 12 atau lebih baru") |"
  fi
  echo
  say "### Before you install" "### Sebelum memasang"
  echo
  say "- **No automatic updates:** this copy doesn't update itself. For automatic updates, install Coba Lagi from Google Play instead." \
    "- **Tidak update otomatis:** salinan ini tidak memperbarui dirinya sendiri. Untuk update otomatis, pasang Coba Lagi dari Google Play."
  say "- **Updating:** install a newer APK from here over the old one; progress stays. Any APK of a newer release installs over any APK of an older one, whichever file you picked before." \
    "- **Memperbarui:** pasang APK yang lebih baru dari sini di atas yang lama; kemajuan tetap tersimpan. APK mana pun dari rilis yang lebih baru bisa dipasang di atas APK mana pun dari rilis yang lebih lama, file mana pun yang dulu kamu pilih."
  say "- **Google Play copies:** these APKs are signed with the upload key, not Google Play's key, so they can't update a copy installed from Google Play (or the other way round). Uninstall first, which removes the players' progress." \
    "- **Salinan dari Google Play:** APK ini ditandatangani dengan kunci unggah, bukan kunci Google Play, jadi tidak bisa memperbarui salinan yang dipasang dari Google Play (begitu juga sebaliknya). Copot dulu salinan lama, dan kemajuan para pemain ikut terhapus."
  if [ -n "$appimage" ]; then
    say "- **Linux:** make the AppImage executable (\`chmod +x $appimage\`, or Properties → Permissions) and open it. It needs no installing and keeps progress in your home folder. To update, replace the old file with the new one (same name): progress stays." \
      "- **Linux:** jadikan AppImage bisa dijalankan (\`chmod +x $appimage\`, atau Properties → Permissions) lalu buka. Tidak perlu dipasang, dan kemajuan disimpan di folder home kamu. Untuk memperbarui, ganti file lama dengan yang baru (namanya sama): kemajuan tetap tersimpan."
    say "- **Steam Deck:** in Desktop Mode, download \`$steam_script\` and double-click it (if asked, choose Continue or Execute). It downloads the newest Coba Lagi into the Applications folder in your home folder, adds it to Steam with its pictures, and restarts Steam, showing each step as it goes; Coba Lagi then plays in Game Mode too, by touch or with the Deck's controls. To update, run it again: progress stays. To remove it, open \"Uninstall Coba Lagi\" from the app menu in Desktop Mode." \
      "- **Steam Deck:** di Desktop Mode, unduh \`$steam_script\` lalu klik dua kali (kalau ditanya, pilih Continue atau Execute). Skrip ini mengunduh Coba Lagi terbaru ke folder Applications di folder home kamu, menambahkannya ke Steam dengan gambarnya, lalu memulai ulang Steam, sambil menunjukkan tiap langkahnya; setelah itu Coba Lagi juga bisa dimainkan di Game Mode, dengan sentuhan atau tombol Deck. Untuk memperbarui, jalankan lagi: kemajuan tetap tersimpan. Untuk menghapusnya, buka \"Uninstall Coba Lagi\" dari menu aplikasi di Desktop Mode."
  fi
  if [ -n "$windows_zip" ]; then
    say "- **Windows:** extract the zip (right-click → Extract All) and open \`cobalagi.exe\` in the \"Coba Lagi\" folder. It needs no installing and keeps progress in your user folder (AppData). The app isn't code-signed yet, so the first time Windows may say it protected your PC: choose More info → Run anyway. To update, replace the old folder with the new one: progress stays." \
      "- **Windows:** ekstrak zip-nya (klik kanan → Extract All) lalu buka \`cobalagi.exe\` di folder \"Coba Lagi\". Tidak perlu dipasang, dan kemajuan disimpan di folder pengguna kamu (AppData). Aplikasi ini belum ditandatangani kode, jadi pertama kali Windows mungkin bilang telah melindungi PC kamu: pilih More info → Run anyway. Untuk memperbarui, ganti folder lama dengan yang baru: kemajuan tetap tersimpan."
  fi
  if [ -n "$macos_zip" ]; then
    say "- **Mac:** open the zip and drag \"Coba Lagi\" into Applications. It is signed and checked by Apple, so it opens without a warning. To update, replace it with the new one: progress stays. The Mac App Store version updates itself and shares progress with this one." \
      "- **Mac:** buka zip-nya lalu seret \"Coba Lagi\" ke Applications. Aplikasi ini ditandatangani dan diperiksa Apple, jadi terbuka tanpa peringatan. Untuk memperbarui, ganti dengan yang baru: kemajuan tetap tersimpan. Versi Mac App Store memperbarui dirinya sendiri dan berbagi kemajuan dengan versi ini."
  fi
  say "- **Checksums:** \`SHA256SUMS.txt\` lists each file's SHA-256." \
    "- **Checksum:** \`SHA256SUMS.txt\` berisi SHA-256 tiap file."
}
{
  echo "<details open><summary><b>English</b></summary>"
  echo
  lang=en language_notes
  echo
  echo "</details>"
  echo "<details><summary><b>Bahasa Indonesia</b></summary>"
  echo
  lang=id language_notes
  echo
  echo "</details>"
} > "$notes"

echo
echo "Release $tag:"
ls -1 "$out"
if $dry_run; then
  echo
  cat "$notes"
  echo
  echo "Dry run: nothing published."
  exit 0
fi

flags=()
if $prerelease; then flags+=(--prerelease); else flags+=(--latest); fi
gh release create "$tag" "${files[@]}" "$out/SHA256SUMS.txt" \
  --target "$(git rev-parse HEAD)" \
  --title "Coba Lagi $name (build $build)" \
  --notes-file "$notes" \
  "${flags[@]}"
