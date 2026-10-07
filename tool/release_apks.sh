#!/usr/bin/env bash
# Builds the release APKs (one per Android architecture, plus a universal
# one that runs on every device) and publishes them
# as a GitHub Release, tagged v<name>+<build> from pubspec.yaml, with the
# build's release notes from store/<locale>/changelogs/<build>.txt.
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

(cd "$out" && shasum -a 256 ./*.apk | sed 's| \./| |' > SHA256SUMS.txt)

notes="$out/notes.md"
{
  echo "Coba Lagi $name (build $build) for Android."
  echo
  echo "**Which file?** Not sure: \`universal\` runs on every device but is"
  echo "the largest. Smaller downloads: \`arm64-v8a\` for most phones and"
  echo "tablets, \`armeabi-v7a\` for older 32-bit devices, \`x86_64\` for"
  echo "emulators and Chromebooks."
  echo
  echo "These APKs are signed with the upload key, not Google Play's key, so"
  echo "they can't update a copy installed from Google Play (or the other way"
  echo "round): uninstall first, which removes the players' progress."
  echo
  echo "## What's new"
  echo
  cat "store/en-US/changelogs/$build.txt"
  echo
  echo "## Yang baru"
  echo
  cat "store/id/changelogs/$build.txt"
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
gh release create "$tag" "$out"/*.apk "$out/SHA256SUMS.txt" \
  --target "$(git rev-parse HEAD)" \
  --title "Coba Lagi $name (build $build)" \
  --notes-file "$notes" \
  "${flags[@]}"
