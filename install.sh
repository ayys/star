#!/usr/bin/env bash
# install.sh — install or package star

set -euo pipefail

script_dir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# Load configuration if available
if [[ -f config.sh ]]; then
	. ./config.sh
else
	echo "Warning: config.sh not found, run configure program first." >&2
	exit 1
fi

mode="install"
DESTDIR="${DESTDIR:-}"
while [[ $# -gt 0 ]]; do
	case "$1" in
		--release) mode="release" ;;
		--destdir=*) DESTDIR="${1#*=}" ;;
		--destdir) shift; DESTDIR="$1" ;;
		*) echo "Unknown option: $1" >&2; exit 1 ;;
	esac
	shift
done

if [[ "$mode" == "release" ]]; then
	DESTDIR="$PWD/release/star-$VERSION"
	echo "Creating release package in $DESTDIR"
fi

BINDIR="$DESTDIR$BINDIR"
LIBEXECDIR="$DESTDIR$LIBEXECDIR"
SHAREDIR="$DESTDIR$SHAREDIR"

# Create directories
mkdir -p "$BINDIR" "$LIBEXECDIR" "$SHAREDIR"

# Install files
install -m 755 "$script_dir/bin/star" "$BINDIR/star"
find "$script_dir/libexec/star/" -type f ! -name "*.sh" -exec install -m 755 {} "$LIBEXECDIR/" \; 2>/dev/null || true
install -m 644 "$script_dir/libexec/star/"*.sh "$LIBEXECDIR/" 2>/dev/null || true
install -m 644 "$script_dir/share/star/"* "$SHAREDIR/" 2>/dev/null || true

# Generate manifest
manifest="$SHAREDIR/manifest.txt"
find "$DESTDIR$PREFIX" -type f | sed "s|$DESTDIR$PREFIX||" | sort > "$manifest"

if [[ "$mode" == "release" ]]; then
	(
		cd "$(dirname "$DESTDIR$PREFIX")"
		tar --sort=name --owner=0 --group=0 --numeric-owner \
			-czf "star-$VERSION.tar.gz" "star-$VERSION"
		echo "Release created: $(pwd)/star-$VERSION.tar.gz"
	)
else
	echo "Installed star $VERSION into $DESTDIR$PREFIX"
	echo "Manifest written to: $manifest"
fi
