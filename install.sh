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

mkdir -p "$SHAREDIR"
manifest="$SHAREDIR/manifest.txt"

if [[ -f "$manifest" ]]; then
	rm "$manifest"
fi

install_file() {
    local mode="$1" src="$2" dest_dir="$3" dest_file="$4"
	local dest="$dest_dir/$dest_file"
    install -Dm"$mode" "$src" "$dest"
    echo "$dest_file" >> "$manifest"
}

install_file 755 "$script_dir/bin/star" "$BINDIR" "bin/star"

install_file 755 "$script_dir/libexec/star/star-deps" "$LIBEXECDIR" "libexec/star/star-deps"
install_file 755 "$script_dir/libexec/star/star-help" "$LIBEXECDIR" "libexec/star/star-help"
install_file 755 "$script_dir/libexec/star/star-list" "$LIBEXECDIR" "libexec/star/star-list"
install_file 755 "$script_dir/libexec/star/star-prune" "$LIBEXECDIR" "libexec/star/star-prune"
install_file 644 "$script_dir/libexec/star/star-setcolors.sh" "$LIBEXECDIR" "libexec/star/star-setcolors.sh"

install_file 644 "$script_dir/share/star/VERSION" "$SHAREDIR" "share/star/VERSION"
install_file 644 "$script_dir/share/star/completion/star.bash" "$SHAREDIR" "share/star/completion/star.bash"
install_file 644 "$script_dir/share/star/config/star_config.sh.template" "$SHAREDIR" "share/star/config/star_config.sh.template"
install_file 644 "$script_dir/share/star/init/star.bash" "$SHAREDIR" "share/star/init/star.bash"

# add more files when in release mode
if [[ "$mode" == "release" ]]; then
	install_file 755 "$script_dir/configure" "$DESTDIR" "configure"
	install_file 755 "$script_dir/install.sh" "$DESTDIR" "install.sh"
	install_file 644 "$script_dir/LICENSE" "$DESTDIR" "LICENSE"
	install_file 644 "$script_dir/README.md" "$DESTDIR" "README.md"
fi

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
