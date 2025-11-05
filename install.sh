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
	DESTDIR="release/star-$VERSION"
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

# add more files when in release mode
if [[ "$mode" == "release" ]]; then
	mkdir -p "$DESTDIR"
	install -m 755 "$script_dir/configure" "$DESTDIR/configure"
	install -m 755 "$script_dir/install.sh" "$DESTDIR/install.sh"
	install -m 644 "$script_dir/LICENSE" "$DESTDIR/LICENSE"
	install -m 644 "$script_dir/README.md" "$DESTDIR/README.md"
fi

# Generate manifest
manifest="$SHAREDIR/manifest.txt"
find "$DESTDIR$PREFIX" -type f | sed "s|$DESTDIR$PREFIX||" | sort > "$manifest"

if [[ "$mode" == "release" ]]; then
	(
		tar --sort=name --owner=0 --group=0 --numeric-owner \
			-czf "star-$VERSION.tar.gz" -C "$DESTDIR/.." "star-$VERSION"
		echo "Release created: $(pwd)/star-$VERSION.tar.gz"
	)
else
	echo "Installed star $VERSION into $DESTDIR$PREFIX"
	echo "Manifest written to: $manifest"
fi
