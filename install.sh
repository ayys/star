#!/usr/bin/env bash
# install.sh — install or package star

usage() {
	cat << EOF
Usage: install.sh [OPTIONS]
Install or package star. 

By default, creates a configuration file (config.sh) which summarizes the installation
and can be used to reproduce the exact same installation later.

OPTIONS
    -h, --help              Show this help message and exit.

    --release               Create a release package instead of installing.
                            The release package will be created by installing files into release/star-VERSION,
                            and then creating a tarball from that directory.
                            The tarball will contain all files from bin, libexec, share, as well as install.sh, LICENSE, and README.md at the top level.

    --destdir=DESTDIR       Temporary staging directory for installation (default: empty)

    -i, --input=FILE        Use an existing configuration file to set installation parameters (default: config.sh).
EOF
}

main() {
	# parse arguments
	local mode="install"

	DESTDIR="${DESTDIR:-}"
	CONFIG_INPUT="config.sh"

	local opt

	while [[ $# -gt 0 ]]; do
		opt="$1"
		shift
		case "$opt" in
			-h|--help)
				usage
				exit 0
				;;
			--release) mode="release" ;;
			--destdir|--destdir=*)
				local value
				if [[ ${#opt} -eq 2 ]]; then
					value="$1"
					shift
				else
					value="${opt#*=}"
				fi
				DESTDIR=$value
				;;
			-i|--input|--input=*)
				local value
				if [[ ${#opt} -eq 2 ]]; then
					value="$1"
					shift
				else
					value="${opt#*=}"
				fi
				CONFIG_INPUT=$value
				;;
			*)
				echo "Invalid option: $opt" >&2
				exit 1
				;;
		esac
	done

	if [[ -f "$CONFIG_INPUT" ]]; then
		. "$CONFIG_INPUT"
	else
		echo "Error: $CONFIG_INPUT not found. Please run configure first and provide a valid configuration file." >&2
		exit 1
	fi

	if [[ -z "${SOURCEDIR+x}" || -z "${PREFIX+x}" || -z "${BINDIR+x}" || -z "${LIBEXECDIR+x}" || -z "${SHAREDIR+x}" || -z "${VERSION+x}" ]]; then
		echo "Error: Configuration file $CONFIG_INPUT is missing required variables. Please run configure first." >&2
		exit 1
	fi

	if [[ "$mode" == "release" ]]; then
		DESTDIR="$(realpath --canonicalize-missing "release/star-$VERSION")"
		rm -rf "$DESTDIR"
		mkdir -p "$DESTDIR"
		echo "Creating release package in $DESTDIR"
		echo ""
	fi

	# ensure trailing slash
	[[ -n $DESTDIR ]] && DESTDIR="${DESTDIR%/}/"

	echo "### INITIALIZING MANIFEST"
	init_manifest
	echo "Local manifest: $MANIFEST"
	echo "Final manifest will be stored at: $DESTMANIFEST"

	echo ""
	echo "### INSTALLATION"
	install_files
	echo "Finished installing files."

	if [[ "$mode" == "release" ]]; then
		echo ""
		echo "### INSTALLING ADDITIONAL RELEASE FILES"
		install_additional_release_files
		echo "Finished installing additional release files."
	fi

	echo ""
	echo "### FINALIZING MANIFEST"
	install -Dm644 "$MANIFEST" "$DESTMANIFEST"
	echo "Final manifest stored at: $DESTMANIFEST"

	echo ""
	echo "### SUMMARY"
	echo "Installation completed at $(realpath "${DESTDIR}${PREFIX}")."
	echo "Installed files are listed in: ${DESTMANIFEST}"

	if [[ "$mode" == "release" ]]; then
		echo ""
		echo "### CREATING RELEASE TARBALL"
		create_release_tarball
	fi

	# when installing, offer to migrate stars from 1.x to 2.x
	if [[ "$mode" == "install" ]]; then
		echo ""
		echo "### MIGRATION FROM 1.x TO 2.x"
		migration_1x_to_2x
	fi

	# when installing, check that the bin directory is in PATH
	if [[ "$mode" == "install" ]] && ! echo ":$PATH:" | grep -q ":${BINDIR}:" ; then
		echo "" >&2
		echo "Warning: The installation directory '$BINDIR' is not in your PATH." >&2
		echo "You may want to add the following line to your shell configuration file (e.g., ~/.bashrc or ~/.zshrc):" >&2
		echo "" >&2
		echo "    export PATH=\"${BINDIR}:\$PATH\"" >&2
		echo "" >&2
		echo "After adding it, do not forget to source your shell configuration file again." >&2
	fi
}

### Specific util functions ###
init_manifest() {
	MANIFEST="manifest.txt"

	local dest
	# if creating a release, manifest is stored at the root of the release,
	# else stored in the share directory
	if [[ "$mode" == "release" ]]; then
		dest="${DESTDIR}${PREFIX}"
	else
		dest="${DESTDIR}${SHAREDIR}"
	fi

	# ensure trailing slash
	[[ -n $dest ]] && dest="${dest%%/}/"

	DESTMANIFEST="$(realpath "${dest}manifest.txt")"
	if [[ -f "$DESTMANIFEST" ]]; then
		echo "A manifest already exists at '$DESTMANIFEST'. Content:"
		cat "$DESTMANIFEST"
		echo ""
		echo "Continuing will overwrite this manifest, and may overwrite existing installed files."
		echo "If a star installation already exists at '${DESTDIR}${PREFIX}', you may want to delete it first."
		echo ""
		while true; do
			echo -n "Continue installation? [y/N] "
			read -r
			case $REPLY in
				[Yy]|[Yy][Ee][Ss])
					break
					;;
				[Nn]|[Nn][Oo]|"")
					echo "Aborting installation."
					exit 0
					;;
				*) echo "Not a valid answer.";;
			esac
		done
		rm "$MANIFEST"
	fi
	touch "$MANIFEST"
}

install_files() {
	install_file 755 "$SOURCEDIR/bin/star" "$BINDIR" "star"

	install_file 755 "$SOURCEDIR/libexec/star/star-deps" "$LIBEXECDIR" "star-deps"
	install_file 755 "$SOURCEDIR/libexec/star/star-help" "$LIBEXECDIR" "star-help"
	install_file 755 "$SOURCEDIR/libexec/star/star-list" "$LIBEXECDIR" "star-list"
	install_file 755 "$SOURCEDIR/libexec/star/star-prune" "$LIBEXECDIR" "star-prune"
	install_file 644 "$SOURCEDIR/libexec/star/star-setcolors.sh" "$LIBEXECDIR" "star-setcolors.sh"

	install_file 644 "$SOURCEDIR/share/star/VERSION" "$SHAREDIR" "VERSION"
	install_file 644 "$SOURCEDIR/share/star/completion/star.bash" "$SHAREDIR" "completion/star.bash"
	install_file 644 "$SOURCEDIR/share/star/config/star_config.sh.template" "$SHAREDIR" "config/star_config.sh.template"
	install_file 644 "$SOURCEDIR/share/star/init/star.bash" "$SHAREDIR" "init/star.bash"
}

install_additional_release_files() {
	install_file 755 "$SOURCEDIR/configure" "$PREFIX" "configure"
	install_file 755 "$SOURCEDIR/install.sh" "$PREFIX" "install.sh"
	install_file 644 "$SOURCEDIR/LICENSE" "$PREFIX" "LICENSE"
	install_file 644 "$SOURCEDIR/README.md" "$PREFIX" "README.md"
}

install_file() {
	local mode="$1"
	local src="$2"
	local dest_dir="$3"
	local dest_file="$4"

	local dest
	dest="$(realpath --canonicalize-missing "${DESTDIR}${dest_dir}/$dest_file")"
	echo "Running: install -Dm$mode $src $dest"
	install -Dm"$mode" "$src" "$dest"

	local dest_file_relative_path
	dest_file_relative_path="$(realpath --relative-to="${DESTDIR}${PREFIX}" "$dest")"
	echo "$dest_file_relative_path" >> "$MANIFEST"
}

create_release_tarball() {
	local tarball="star-$VERSION.tar.gz"
	local tarball_relative_path
	tarball_relative_path="$(realpath --relative-to="${PWD}" "$tarball")"
	echo "Creating tarball: $tarball_relative_path"
	tar --sort=name --owner=0 --group=0 --numeric-owner -czf "$tarball" -C "$SOURCEDIR/release" "star-$VERSION"
	echo "Finished creating release tarball: $tarball_relative_path"
}

# Migrate from star 1.x to 2.x
#
# in 1.x, stars were stored in ~/.star/
# in 2.x, stars are stored in ${_STAR_DATA_HOME}/stars/
migration_1x_to_2x() {
	if [[ ! -d "$HOME/.star" ]]; then
		echo "Skipping migration from 1.x to 2.x: no stars found in '$HOME/.star'."
		return 0
	fi

	# echo ""
	# echo "### MIGRATION FROM 1.x TO 2.x"
	echo "Detected stars from an older star version, stored in '$HOME/.star':"
	if command -v column >/dev/null 2>&1; then
		find "$HOME/.star" -maxdepth 1 -type l -printf "- %f -> %l\n" | column -t
	else
		find "$HOME/.star" -maxdepth 1 -type l -printf "- %f -> %l\n"
	fi

	# detect where the new data home should be
	local data_home
	data_home="$(eval "$("$SOURCEDIR/bin/star" init bash)" ; env | grep "^_STAR_DATA_HOME=" | cut -d'=' -f2- )"

	if [[ $? != 0 || -z "$data_home" || ! -d "$data_home" ]]; then
		return 0
	fi

	echo ""
	echo "The new star version will store stars in '${data_home}/stars/'."
	echo ""

	local migrate_stars=no
	while true; do
		echo -n "Do you want to move/copy the stars to the new location? (move/copy/no) [m/C/n] "
		read -r
		case $REPLY in
			[Mm])
				migrate_stars=move
				break
				;;
			[Cc]|"")
				migrate_stars=copy
				break
				;;
			[Nn]|[Nn][Oo])
				migrate_stars=no
				break
				;;
			*) echo "Not a valid answer.";;
		esac
	done

	if [[ "$migrate_stars" == "no" ]]; then
		echo "Skipping migration of stars."
		return 0
	fi

	mkdir -p "${data_home}/stars/"
	if [[ "$migrate_stars" == "move" ]]; then
		mv "$HOME/.star/"* "${data_home}/stars/"
		echo "Moved stars from $HOME/.star/ to ${data_home}/stars/"
	elif [[ "$migrate_stars" == "copy" ]]; then
		cp -r "$HOME/.star/"* "${data_home}/stars/"
		echo "Copied stars from $HOME/.star/ to ${data_home}/stars/"
	fi

	echo ""
	while true; do
		echo -n "Delete the old stars directory '$HOME/.star/'? [y/n] "
		read -r
		case $REPLY in
			[Yy]|[Yy][Ee][Ss])
				rm -rf "$HOME/.star/"
				echo "Deleted old stars directory '$HOME/.star/'."
				break
				;;
			[Nn]|[Nn][Oo])
				echo "Keeping old stars directory '$HOME/.star/'."
				break
				;;
			*) echo "Not a valid answer.";;
		esac
	done
}

main "$@"