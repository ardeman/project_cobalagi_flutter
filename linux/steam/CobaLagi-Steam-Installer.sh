#!/usr/bin/env bash
# Adds Coba Lagi to Steam as a non-Steam game, with its library artwork, so
# it plays from Game Mode on the Steam Deck. CobaLagi-Steam-Installer.desktop,
# attached to each GitHub release, downloads it from master and runs it;
# it also runs on its own in Desktop Mode, in Konsole:
#   bash CobaLagi-Steam-Installer.sh [path/to/CobaLagi-x86_64.AppImage]
# Without a path it downloads the newest AppImage from the GitHub release
# into ~/Applications (if that fails, it looks next to itself, one folder
# up, in ~/Downloads and in ~/Applications); with a path it moves that file
# there, so the shortcut never breaks. It closes Steam while it edits each
# Steam user's shortcuts.vdf (keeping a .bak copy), and starts Steam again.
# Running it again updates the game, the shortcut and the artwork instead
# of adding a second one. The library pictures come from artwork/ next to
# it (in the repo), else from GitHub (the newest on master).
# It also adds "Uninstall Coba Lagi" to the Desktop Mode menu, which runs
#   bash CobaLagi-Steam-Installer.sh --uninstall
# to take the game, its Steam shortcut and pictures away again (asking
# before it deletes the players' progress).
# STEAM_DIR overrides where Steam lives (for testing).
set -euo pipefail
mode=add
if [ "${1:-}" = "--uninstall" ]; then mode=remove; shift; fi

# Shows which step it is on, bold when it runs in a terminal.
steps=6
[ "$mode" = remove ] && steps=4
done_steps=0
step() {
  done_steps=$((done_steps + 1))
  if [ -t 1 ]; then
    printf '\n\033[1m[%d/%d] %s\033[0m\n' "$done_steps" "$steps" "$1"
  else
    printf '\n[%d/%d] %s\n' "$done_steps" "$steps" "$1"
  fi
}
here="$(cd "$(dirname "$0")" && pwd)"
name="CobaLagi-x86_64.AppImage"
apps="$HOME/Applications"

repo="ardeman/project_cobalagi_flutter"
mkdir -p "$apps"

# The newest release's AppImage link, test releases (pre-releases) too,
# which GitHub's "latest" link leaves out.
newest_url() {
  curl -fsSL "https://api.github.com/repos/$repo/releases?per_page=10" |
    python3 -c '
import json, sys
for release in json.load(sys.stdin):
    for asset in release["assets"]:
        if asset["name"] == sys.argv[1]:
            print(asset["browser_download_url"]); sys.exit()
sys.exit(1)' "$name"
}

# Downloads the newest AppImage into ~/Applications; false if it can't.
download() {
  local url part="$apps/$name.part"
  command -v curl >/dev/null || return 1
  url="$(newest_url)" || return 1
  # .../download/v2.6.1%2B22/<name>: say which version it is.
  local tag="${url%/*}"
  tag="${tag##*/v}"
  tag="${tag/\%2B/ (build }"
  echo "Version ${tag}$([[ $tag == *build* ]] && echo ")")"
  curl -fL --progress-bar -o "$part" "$url" || { rm -f "$part"; return 1; }
  mv -f "$part" "$apps/$name"
}

# Uninstalling needs neither: the AppImage is where installing put it.
appimage="$apps/$name"
art=""
if [ "$mode" = add ]; then
  appimage=""
  step "Getting the game"
  if [ -n "${1:-}" ]; then
    echo "Using $1"
    candidates=("$1")
  elif download; then
    candidates=("$apps/$name")
  else
    echo "Couldn't download it; looking for a downloaded copy instead." >&2
    candidates=("$here/$name" "$here/../$name" "$HOME/Downloads/$name" \
      "$apps/$name")
  fi
  for candidate in "${candidates[@]}"; do
    if [ -f "$candidate" ]; then
      appimage="$(cd "$(dirname "$candidate")" && pwd)/$(basename "$candidate")"
      break
    fi
  done
  if [ -z "$appimage" ]; then
    echo "Can't find $name. Download it from the latest release, then run this again." >&2
    exit 1
  fi

  if [ "$appimage" != "$apps/$name" ]; then
    mv -f "$appimage" "$apps/$name"
  fi
  appimage="$apps/$name"
  chmod +x "$appimage"

  art="$here/artwork"
  if [ ! -f "$art/capsule.png" ]; then
    art="$(mktemp -d)"
    trap 'rm -rf "$art"' EXIT
  fi
  step "Getting the pictures for the Steam library"
  for picture in capsule wide hero logo icon; do
    if [ "$art" = "$here/artwork" ] && [ -f "$art/$picture.png" ]; then
      echo "  $picture: from the folder next to this script"
    elif curl -fsSL -o "$art/$picture.png" \
        "https://raw.githubusercontent.com/$repo/master/linux/steam/artwork/$picture.png"; then
      echo "  $picture: downloaded"
    else
      echo "  $picture: couldn't download it; Steam shows its own picture there." >&2
    fi
  done
fi

steam_dir="${STEAM_DIR:-}"
if [ -z "$steam_dir" ]; then
  for candidate in "$HOME/.local/share/Steam" "$HOME/.steam/steam" \
      "$HOME/.var/app/com.valvesoftware.Steam/.local/share/Steam"; do
    if [ -d "$candidate/userdata" ]; then steam_dir="$candidate"; break; fi
  done
fi
if [ -z "$steam_dir" ] || [ ! -d "$steam_dir/userdata" ]; then
  echo "Can't find Steam. Open Steam and sign in once, then run this again." >&2
  exit 1
fi

# Steam rewrites shortcuts.vdf when it closes, so it must not be running.
restart=""
steam_args=()
step "Closing Steam for a moment"
if [ -n "${STEAM_DIR:-}" ] || ! pgrep -x steam >/dev/null; then
  echo "Steam isn't running."
else
  echo "Waiting for Steam to close..."
  restart=1
  # Start it again with the options it runs with now: on the Steam Deck a
  # plain `steam` opens Big Picture, even in Desktop Mode.
  pid="$(pgrep -o -x steam)"
  { IFS= read -r -d '' _ || true  # the program itself
    while IFS= read -r -d '' arg; do
      case "$arg" in
        -srt-logger-opened) ;;
        -*) steam_args+=("$arg") ;;
      esac
    done
  } 2>/dev/null < "/proc/$pid/cmdline" || true
  steam -shutdown >/dev/null 2>&1 || true
  for _ in $(seq 60); do
    pgrep -x steam >/dev/null || break
    sleep 1
  done
  if pgrep -x steam >/dev/null; then
    echo "Steam didn't close. Quit it (Steam → Exit), then run this again." >&2
    exit 1
  fi
fi

if [ "$mode" = add ]; then
  step "Adding Coba Lagi to Steam"
else
  step "Removing Coba Lagi from Steam"
fi
python3 - "$steam_dir" "$appimage" "$art" "$mode" <<'PY'
import glob, json, os, shutil, struct, sys, zlib

steam_dir, appimage, art, mode = sys.argv[1:5]
NAME = "Coba Lagi"
exe = f'"{appimage}"'
start_dir = f'"{os.path.dirname(appimage)}/"'
ENC = ("utf-8", "surrogateescape")

# Binary VDF: a type byte, a key, a value; 0x08 ends a map.
def read_map(b, i):
    items = []
    while True:
        t = b[i]; i += 1
        if t == 8:
            return items, i
        j = b.index(0, i); key = b[i:j].decode(*ENC); i = j + 1
        if t == 0:
            value, i = read_map(b, i)
        elif t == 1:
            j = b.index(0, i); value = b[i:j].decode(*ENC); i = j + 1
        elif t == 2:
            value = struct.unpack_from("<I", b, i)[0]; i += 4
        elif t == 7:
            value = struct.unpack_from("<Q", b, i)[0]; i += 8
        else:
            raise ValueError(f"unknown VDF type {t} at byte {i - 1}")
        items.append([t, key, value])

def write_map(items):
    out = bytearray()
    for t, key, value in items:
        out.append(t); out += key.encode(*ENC) + b"\0"
        if t == 0: out += write_map(value)
        elif t == 1: out += value.encode(*ENC) + b"\0"
        elif t == 2: out += struct.pack("<I", value)
        elif t == 7: out += struct.pack("<Q", value)
    out.append(8)
    return bytes(out)

def field(entry, key):
    for item in entry:
        if item[1].lower() == key.lower():
            return item
    return None

def put(entry, t, key, value):
    item = field(entry, key)
    if item: item[0], item[2] = t, value
    else: entry.append([t, key, value])

users = [d for d in glob.glob(os.path.join(steam_dir, "userdata", "*"))
         if os.path.basename(d).isdigit() and os.path.basename(d) != "0"]
if not users and mode == "remove":
    sys.exit()
if not users:
    sys.exit("No Steam user found. Open Steam and sign in once, then run this again.")

for user in users:
    config = os.path.join(user, "config")
    os.makedirs(config, exist_ok=True)
    path = os.path.join(config, "shortcuts.vdf")
    if os.path.exists(path) and os.path.getsize(path) > 0:
        with open(path, "rb") as f: data = f.read()
        root, _ = read_map(data, 0)
        shutil.copyfile(path, path + ".bak")
    else:
        root = []
    shortcuts = field(root, "shortcuts")
    if shortcuts is None:
        shortcuts = [0, "shortcuts", []]; root.append(shortcuts)
    entries = shortcuts[2]

    entry = None
    for _, _, e in entries:
        app_name = field(e, "AppName"); target = field(e, "Exe")
        if (app_name and app_name[2] == NAME) or \
           (target and target[2].strip('"').endswith("/CobaLagi-x86_64.AppImage")):
            entry = e; break
    if mode == "remove":
        if entry is None: continue
        entries[:] = [[0, str(i), e] for i, (_, _, e) in
                      enumerate(x for x in entries if x[2] is not entry)]
        appid = field(entry, "appid")
        if appid:
            for old in glob.glob(os.path.join(config, "grid", f"{appid[2]}*")):
                os.remove(old)
        with open(path, "wb") as f: f.write(write_map(root))
        print(f"Removed Coba Lagi for Steam user {os.path.basename(user)}.")
        continue
    if entry is None:
        entry = [[2, "appid", zlib.crc32((exe + NAME).encode()) | 0x80000000],
                 [1, "AppName", NAME], [1, "Exe", ""], [1, "StartDir", ""],
                 [1, "icon", ""], [1, "ShortcutPath", ""], [1, "LaunchOptions", ""],
                 [2, "IsHidden", 0], [2, "AllowDesktopConfig", 1],
                 [2, "AllowOverlay", 1], [2, "OpenVR", 0], [2, "Devkit", 0],
                 [1, "DevkitGameID", ""], [2, "DevkitOverrideAppID", 0],
                 [2, "LastPlayTime", 0], [1, "FlatpakAppID", ""], [0, "tags", []]]
        entries.append([0, str(len(entries)), entry])
    # Keep an appid Steam already gave the shortcut: its artwork is named by it.
    if field(entry, "appid") is None:
        put(entry, 2, "appid", zlib.crc32((exe + NAME).encode()) | 0x80000000)
    appid = field(entry, "appid")[2]

    grid = os.path.join(config, "grid")
    os.makedirs(grid, exist_ok=True)
    for src, dst in [("capsule", f"{appid}p"), ("wide", f"{appid}"),
                     ("hero", f"{appid}_hero"), ("logo", f"{appid}_logo"),
                     ("icon", f"{appid}_icon")]:
        picture = os.path.join(art, src + ".png")
        if not os.path.isfile(picture): continue  # Not downloaded: keep any old one.
        for old in glob.glob(os.path.join(grid, dst + ".*")):
            if not old.endswith(".json"): os.remove(old)
        shutil.copyfile(picture, os.path.join(grid, dst + ".png"))
    with open(os.path.join(grid, f"{appid}.json"), "w") as f:
        json.dump({"nVersion": 1, "logoPosition": {"pinnedPosition": "BottomLeft",
                   "nWidthPct": 50, "nHeightPct": 50}}, f)

    put(entry, 1, "AppName", NAME)
    put(entry, 1, "Exe", exe)
    put(entry, 1, "StartDir", start_dir)
    put(entry, 1, "icon", os.path.join(grid, f"{appid}_icon.png"))

    with open(path, "wb") as f: f.write(write_map(root))
    print(f"Added Coba Lagi for Steam user {os.path.basename(user)}.")
PY

step "Starting Steam again"
if [ -n "$restart" ]; then
  (setsid steam ${steam_args[@]+"${steam_args[@]}"} >/dev/null 2>&1 &)
  echo "Steam is starting."
else
  echo "Steam wasn't running; the change shows the next time it opens."
fi
# The uninstaller: a copy of this script, and its entry in the menu.
keep="$HOME/.local/share/cobalagi-steam"
menu="$HOME/.local/share/applications/cobalagi-uninstall.desktop"
if [ "$mode" = remove ]; then
  step "Deleting the game"
  rm -f "$appimage" "$menu"
  rm -rf "$keep"
  # path_provider's folder: the app id, or the program's name.
  data=()
  for folder in "$HOME/.local/share/com.ardeman.cobalagi" \
      "$HOME/.local/share/cobalagi"; do
    [ -d "$folder" ] && data+=("$folder")
  done
  if [ ${#data[@]} -gt 0 ]; then
    answer=""
    read -r -p "Also delete the players' progress? This can't be undone. [y/N] " \
      answer 2>/dev/null </dev/tty || true
    case "$answer" in
      [yY]*) rm -rf "${data[@]}"; echo "Progress deleted." ;;
      *) echo "Progress kept: installing Coba Lagi again brings it back." ;;
    esac
  fi
  echo; echo "Done. Coba Lagi is uninstalled."
  # Opened from the menu, the window would close before it can be read.
  read -r -p "Press Enter to close. " 2>/dev/null </dev/tty || true
else
  step "Adding \"Uninstall Coba Lagi\" to the app menu"
  mkdir -p "$keep" "$(dirname "$menu")"
  script="${BASH_SOURCE[0]}"
  if [ -f "$script" ] && [ "$script" -ef "$keep/CobaLagi-Steam-Installer.sh" ]; then :
  elif [ -f "$script" ]; then cp -f "$script" "$keep/CobaLagi-Steam-Installer.sh"
  fi
  rm -f "$keep/add_to_steam.sh" # Its old name.
  [ -f "$art/icon.png" ] && cp -f "$art/icon.png" "$keep/icon.png"
  if [ -f "$keep/CobaLagi-Steam-Installer.sh" ]; then
    cat >"$menu" <<DESKTOP
[Desktop Entry]
Type=Application
Name=Uninstall Coba Lagi
Comment=Removes Coba Lagi and its Steam shortcut
Exec=bash "$keep/CobaLagi-Steam-Installer.sh" --uninstall
Icon=$keep/icon.png
Terminal=true
Categories=Game;
DESKTOP
  fi
  echo; echo "Done. Coba Lagi is in your Steam library, also in Game Mode."
  echo "To remove it, open \"Uninstall Coba Lagi\" from the app menu."
fi
