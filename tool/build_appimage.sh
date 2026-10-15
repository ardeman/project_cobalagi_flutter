#!/usr/bin/env bash
# Builds the Linux release as one x86_64 AppImage, for Linux PCs and the
# Steam Deck (SteamOS's system is read-only, so nothing may need installing).
# GTK and GStreamer (audioplayers plays sound through it) are bundled; the
# graphics drivers and glibc come from the system, so build on the oldest
# distribution the AppImage should run on (CI uses Ubuntu 22.04).
#
#   tool/build_appimage.sh   # → build/release/CobaLagi-x86_64.AppImage
#
# The name never changes, so updating is replacing the file: the Steam
# shortcut keeps working, and progress stays in the home folder.
#
# Needs an x86_64 Linux machine with Flutter's Linux build tools and:
#   sudo apt-get install clang cmake ninja-build pkg-config libgtk-3-dev \
#     libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev \
#     gstreamer1.0-plugins-base gstreamer1.0-plugins-good patchelf file
# GitHub Actions runs it after every version bump
# (.github/workflows/release-apks.yml) and adds the AppImage to the release.
set -euo pipefail
cd "$(dirname "$0")/.."

if [ "$(uname -s)-$(uname -m)" != "Linux-x86_64" ]; then
  echo "Build the AppImage on x86_64 Linux." >&2
  exit 1
fi

out="build/release"
appimage="$out/CobaLagi-x86_64.AppImage"

# Pinned so a new upload can't change a release: the linuxdeploy release
# tag and each plugin's commit.
linuxdeploy_tag="1-alpha-20251107-1"
gtk_plugin_commit="7a3fbc31a9e5075073ff8790f26effbac5f84453"
gstreamer_plugin_commit="432af639725bc8b99df12351e86bb2e8a6b3585f"

tools="build/appimage-tools"
mkdir -p "$tools"
fetch() {
  [ -f "$tools/$2" ] || curl -fsSL -o "$tools/$2" "$1"
  chmod +x "$tools/$2"
}
fetch "https://github.com/linuxdeploy/linuxdeploy/releases/download/$linuxdeploy_tag/linuxdeploy-x86_64.AppImage" \
  linuxdeploy-x86_64.AppImage
fetch "https://raw.githubusercontent.com/linuxdeploy/linuxdeploy-plugin-gtk/$gtk_plugin_commit/linuxdeploy-plugin-gtk.sh" \
  linuxdeploy-plugin-gtk.sh
fetch "https://raw.githubusercontent.com/linuxdeploy/linuxdeploy-plugin-gstreamer/$gstreamer_plugin_commit/linuxdeploy-plugin-gstreamer.sh" \
  linuxdeploy-plugin-gstreamer.sh
# linuxdeploy finds its plugins on PATH; CI runners have no FUSE.
export PATH="$PWD/$tools:$PATH"
export APPIMAGE_EXTRACT_AND_RUN=1

flutter build linux --release

# Flutter's bundle stays together in usr/bin: the engine loads lib/libapp.so
# and data/ next to the executable.
appdir="build/AppDir"
rm -rf "$appdir"
mkdir -p "$appdir/usr/bin"
cp -r build/linux/x64/release/bundle/. "$appdir/usr/bin/"

export DEPLOY_GTK_VERSION=3
linuxdeploy-x86_64.AppImage --appdir "$appdir" \
  --executable "$appdir/usr/bin/cobalagi" \
  --desktop-file linux/packaging/cobalagi.desktop \
  --icon-file linux/packaging/cobalagi.png \
  --plugin gtk --plugin gstreamer

# linuxdeploy copied the Flutter and plugin libraries to usr/lib, where the
# executable now looks; drop the copies in usr/bin/lib, but keep the app.
find "$appdir/usr/bin/lib" -name '*.so' ! -name libapp.so -delete

mkdir -p "$out"
rm -f "$appimage"
LDAI_OUTPUT="$appimage" linuxdeploy-x86_64.AppImage --appdir "$appdir" \
  --output appimage
echo "Built $appimage"
