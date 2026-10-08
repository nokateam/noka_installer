#!/data/data/com.termux/files/usr/bin/bash
set -e

PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"
REPO="${NOKA_INSTALLER_REPO:-https://github.com/nokateam/noka_installer}"
RAW="${NOKA_INSTALLER_RAW:-https://raw.githubusercontent.com/nokateam/noka_installer/main}"
BIN="$PREFIX/bin/noka_installer"

case "${TERMUX_ARCH:-$(uname -m)}" in
    aarch64 | arm64)      TARGET="aarch64-linux-android" ;;
    arm | armv7l | armv7) TARGET="armv7-linux-androideabi" ;;
    x86_64 | amd64)       TARGET="x86_64-linux-android" ;;
    i686 | i386 | x86)    TARGET="i686-linux-android" ;;
    *)                    TARGET="" ;;
esac

if [ -z "$TARGET" ]; then
    echo "[!] unsupported architecture: ${TERMUX_ARCH:-$(uname -m)}"
    exit 1
fi

if [ -n "${NOKA_BIN_URL:-}" ]; then
    CANDIDATES="$NOKA_BIN_URL"
else
    CANDIDATES="$RAW/bin/noka_installer-$TARGET
$RAW/bin/noka_installer
$RAW/noka_installer
$REPO/releases/latest/download/noka_installer-$TARGET
$REPO/releases/latest/download/noka_installer"
fi

dpkg --configure -a --force-confold 2>/dev/null || true
pkg update -y
pkg install -y curl ca-certificates coreutils unzip

TMP="$(mktemp -d)"
got=0
for url in $CANDIDATES; do
    echo "[*] fetching $url"
    if curl -fSL --connect-timeout 15 --max-time 180 "$url" -o "$TMP/noka_installer" 2>/dev/null; then
        got=1
        break
    fi
done

if [ "$got" -ne 1 ]; then
    rm -rf "$TMP"
    echo "[!] couldn't download the installer for $TARGET"
    echo "    tell nooba in discord.gg/noka"
    exit 1
fi

install -m755 "$TMP/noka_installer" "$BIN"
rm -rf "$TMP"
echo "[*] installed $BIN"
exec "$BIN" "$@"
