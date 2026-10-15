#!/usr/bin/env bash
# Builds the release APKs (one per Android architecture, plus a universal
# one that runs on every device) and publishes them, with the Linux AppImage
# when tool/build_appimage.sh has built it (and CobaLagi-Steam.zip, which
# adds it to Steam: linux/steam/), as a GitHub Release, tagged
# v<name>+<build> from pubspec.yaml, with the build's release notes from
# store/<locale>/changelogs/<build>.txt.
#
#   tool/release_apks.sh            # build, then publish as a pre-release
#   tool/release_apks.sh --dry-run  # build and show what would be published
#   tool/release_apks.sh --latest   # publish as the latest full release
#
# GitHub Actions runs it after every version bump
# (.github/workflows/release-apks.yml), with the upload key from the
# repository's secrets; it also runs locally with android/key.properties.
set -euo pipefail
cd "$(dirname "$0")/.."

dry_run=false
prerelease=true
for arg in "$@"; do
  case "$arg" in
    --dry-run) dry_run=true ;;
    --latest) prerelease=false ;;
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
if [ ! -f android/key.properties ]; then
  echo "android/key.properties is missing: APKs would be debug-signed." >&2
  exit 1
fi
for locale in en-US id; do
  if [ ! -f "store/$locale/changelogs/$build.txt" ]; then
    echo "No release notes in store/$locale/changelogs/$build.txt." >&2
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
export COBALAGI_GITHUB_APK=1
flutter build apk --release --split-per-abi
# The universal APK last: it has its own file name, so both sets remain.
flutter build apk --release

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
steam_zip="CobaLagi-Steam.zip"
if [ -f "build/release/$appimage" ]; then
  cp "build/release/$appimage" "$out/"
  rm -rf "$out/CobaLagi-Steam"
  mkdir -p "$out/CobaLagi-Steam"
  cp -R linux/steam/add_to_steam.sh linux/steam/artwork "$out/CobaLagi-Steam/"
  (cd "$out" && rm -f "$steam_zip" && zip -qr "$steam_zip" CobaLagi-Steam)
  rm -rf "$out/CobaLagi-Steam"
else
  appimage=""
  steam_zip=""
fi
files=("$out"/*.apk)
if [ -n "$appimage" ]; then files+=("$out/$appimage" "$out/$steam_zip"); fi

(cd "$out" && shasum -a 256 ./*.apk ${appimage:+"./$appimage"} ${steam_zip:+"./$steam_zip"} |
  sed 's| \./| |' > SHA256SUMS.txt)

notes="$out/notes.md"
# One line per paragraph: GitHub keeps every line break in release notes.
{
  echo "## What's new"
  echo
  cat "store/en-US/changelogs/$build.txt"
  echo
  echo "## Yang baru"
  echo
  cat "store/id/changelogs/$build.txt"
  echo
  echo "## Which file?"
  echo
  echo "| File | For |"
  echo "|---|---|"
  echo "| \`cobalagi-$name-build$build-universal.apk\` | Any Android device. Pick this if you're not sure (largest download). |"
  echo "| \`cobalagi-$name-build$build-arm64-v8a.apk\` | Most phones and tablets |"
  echo "| \`cobalagi-$name-build$build-armeabi-v7a.apk\` | Older 32-bit devices |"
  echo "| \`cobalagi-$name-build$build-x86_64.apk\` | Emulators and Chromebooks |"
  if [ -n "$appimage" ]; then
    echo "| \`$appimage\` | Linux PCs and the Steam Deck |"
    echo "| \`$steam_zip\` | Adds the AppImage to Steam, with its artwork (Steam Deck) |"
  fi
  echo
  echo "## Before you install"
  echo
  echo "- **No automatic updates:** this copy doesn't update itself. For automatic updates, install Coba Lagi from Google Play instead."
  echo "- **Updating:** install a newer APK from here over the old one; progress stays. Any APK of a newer release installs over any APK of an older one, whichever file you picked before."
  echo "- **Google Play copies:** these APKs are signed with the upload key, not Google Play's key, so they can't update a copy installed from Google Play (or the other way round). Uninstall first, which removes the players' progress."
  if [ -n "$appimage" ]; then
    echo "- **Linux:** make the AppImage executable (\`chmod +x $appimage\`, or Properties → Permissions) and open it. It needs no installing and keeps progress in your home folder. To update, replace the old file with the new one (same name): progress stays."
    echo "- **Steam Deck:** in Desktop Mode, download the AppImage and \`$steam_zip\`, unzip it (right-click → Extract → Extract archive here), open the \`CobaLagi-Steam\` folder and run \`add_to_steam.sh\` (right-click → Run In Konsole). It moves the AppImage to the Applications folder in your home folder, adds Coba Lagi to Steam with its pictures, and restarts Steam; it then plays in Game Mode too, by touch or with the Deck's controls. To update, download the new AppImage and run \`add_to_steam.sh\` again: progress stays."
  fi
  echo "- **Checksums:** \`SHA256SUMS.txt\` lists each file's SHA-256."
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
