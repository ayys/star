#!/usr/bin/env bash

usage() {
    cat << EOF
Usage: uninstall.sh [OPTIONS]
Uninstall star by removing installed files and data files (and if specified configuration files).

Manifest file:
    This script uses a manifest file to determine which files to remove. This manifest is created during installation.
    It should be located at: \${_STAR_HOME}/share/star/manifest.txt
    where \${_STAR_HOME} is the installation directory (e.g. /usr/local/share/star).
    If the manifest file is not found, the uninstallation will be aborted.
    The option --input can be used to specify a different manifest file.

By default:
    - data files are removed. Use the --keep-data option to keep them.
    - configuration files are kept. Use the --remove-config option to remove them.

OPTIONS
    -h, --help              Show this help message and exit.

    -k, --keep-data         Keep data files (default: remove data files).

    -r, --remove-config     Remove configuration files (default: keep configuration files).

    -i, --input=FILE        Use the specified manifest file (default: \${_STAR_HOME}/share/star/manifest.txt).
EOF
}

main() {
	local keep_data=0
    local keep_config=1
    local input_manifest=""
    local manifest=""

	local opt
	while [[ $# -gt 0 ]]; do
		opt="$1"
		shift
		case "$opt" in
			-h|--help)
				usage
				exit 0
				;;
            -k|--keep-data)
                keep_data=1
                ;;
            -r|--remove-config)
                keep_config=0
                ;;
            -i|--input=*)
                local value
                if [[ ${#opt} -eq 2 ]]; then
                    value="$1"
                    shift
                else
                    value="${opt#*=}"
                fi

                input_manifest=$value
                ;;
			*)
				echo "Invalid option: $opt" >&2
				exit 1
				;;
		esac
	done

    if [[ -n $input_manifest ]]; then
        manifest="$input_manifest"
        _STAR_HOME="$(dirname "$(dirname "$(dirname "$manifest")")")"
        export _STAR_HOME
    else
        if [[ -z "$_STAR_HOME" ]]; then
            echo "Error: _STAR_HOME is not set. Please set it or provide a manifest file using --input." >&2
            exit 1
        fi
        manifest="$_STAR_HOME/share/star/manifest.txt"
    fi

    if [[ ! -f "$manifest" ]]; then
        echo "Error: Manifest file '$manifest' not found. Aborting uninstallation." >&2
        echo "Please provide a valid manifest file using the --input option or ensure _STAR_HOME is set correctly." >&2
        exit 1
    fi

    export PATH="${_STAR_HOME}/bin:$PATH"
    echo "### INITIALIZING STAR ENVIRONMENT"
    echo "Trying to initialize star environment for uninstallation."
    echo "Using \${_STAR_HOME}=$_STAR_HOME"
    echo "Running: eval \"\$(command star init bash)\""
    echo ""
    if eval "$(command star init bash)"; then
        echo "Star environment initialized successfully."
        echo "This installation will remove files listed in the manifest, and will use _STAR_DATA_HOME and _STAR_CONFIG_FILE if set to remove additional files."
    else
        echo "Failed to initialize star environment, continuing without it."
        echo "This installation will only remove files listed in the manifest."
    fi
    echo ""

    echo "### SUMMARY OF UNINSTALLATION"
    echo "Uninstalling star using manifest: $manifest"
    echo ""
    echo "The following files will be removed:"
    while IFS= read -r; do
        echo " - ${_STAR_HOME}/${REPLY}"
    done < "$manifest"
    echo ""
    if [[ $keep_data -eq 0 && -n "$_STAR_DATA_HOME" ]]; then
        echo "The following data files will be removed."
        if [[ -d "$_STAR_DATA_HOME/stars" ]]; then
            echo "Stars:"
            if command -v column >/dev/null 2>&1; then
                find "$_STAR_DATA_HOME/stars" -maxdepth 1 -type l -printf " - %f -> %l\n" | column -t
            else
                find "$_STAR_DATA_HOME/stars" -maxdepth 1 -type l -printf " - %f -> %l\n"
            fi
        fi
    else
        if [[ -z "$_STAR_DATA_HOME" ]]; then
            echo "Warning: _STAR_DATA_HOME is not set. Data files location is unknown (if there are any)."
            echo "To manually remove them, run 'star reset'."
        else
            echo "Data files will not be removed."
        fi
    fi
    echo ""
    if [[ -z $_STAR_CONFIG_FILE ]]; then
        echo "Warning: _STAR_CONFIG_FILE is not set. Configuration file location is unknown (if there is one)."
    fi
    if [[ -f $_STAR_CONFIG_FILE ]]; then
        echo "Configuration file located at: $_STAR_CONFIG_FILE"
        if [[ $keep_config -eq 0 ]]; then
            echo "The configuration file will be removed."
        else
            echo "The configuration file will be kept."
        fi
    else
        echo "No configuration file to remove."
    fi

    echo ""
    while true; do
        echo -n "Proceed with the uninstallation? [yn] "
        read -r
        case $REPLY in
            [Yy]|[Yy][Ee][Ss])
                break
                ;;
            [Nn]|[Nn][Oo])
                echo "Uninstallation aborted."
                exit 0
                ;;
            *) echo "Not a valid answer.";;
        esac
    done

    if [[ $keep_data -eq 0 && -n "$_STAR_DATA_HOME" ]]; then
        echo ""
        echo "### UNINSTALLATION - removing data files"
        if [[ -d "$_STAR_DATA_HOME/stars" ]]; then
            rm -rf "$_STAR_DATA_HOME/stars"
            echo "Removed stars directory: $_STAR_DATA_HOME/stars"
        else
            echo "No stars directory found at: $_STAR_DATA_HOME/stars"
        fi

        if [[ -d "$_STAR_DATA_HOME" && -z $(ls -A "$_STAR_DATA_HOME") ]]; then
            rmdir "$_STAR_DATA_HOME" && echo "Removed data home directory: $_STAR_DATA_HOME"
        else
            echo "Data home directory not empty or does not exist: $_STAR_DATA_HOME"
        fi
    fi

    if [[ $keep_config -eq 0 && -f $_STAR_CONFIG_FILE ]]; then
        echo ""
        echo "### UNINSTALLATION - removing configuration file"
        rm -f "$_STAR_CONFIG_FILE"
        echo "Removed configuration file: $_STAR_CONFIG_FILE"
    fi

    echo ""
    echo "### UNINSTALLATION - removing installed files"
    local files_to_remove=()
    while IFS= read -r; do
        files_to_remove+=("${_STAR_HOME}/${REPLY}")
    done < "$manifest"
    files_to_remove+=("$manifest")  # remove the manifest file itself

    local f
    for f in "${files_to_remove[@]}"; do
        if [[ -f "$f" || -L "$f" ]]; then
            rm -f "$f"
            echo "Removed file: $f"

            # while parent directory is empty, remove it then go up one level
            local parent_dir
            parent_dir="$(dirname "$f")"
            while [[ "$parent_dir" != "$_STAR_HOME" && "$parent_dir" != "/" && -d "$parent_dir" && -z "$(command ls -A "$parent_dir")" ]]; do
                rmdir "$parent_dir"
                echo "Removed empty directory: $parent_dir"
                parent_dir="$(dirname "$parent_dir")"
            done
        else
            echo "File not found, skipping: $f"
        fi
    done

    echo ""
    echo "### SUMMARY"
    echo "Uninstallation completed."
    echo "Do not forget to remove any remaining data or configuration files if needed."
    echo "If you added any star-related exports or initializations to your shell configuration files, please remove them manually."
    echo ""
    echo "Thank you for using star!"
}

main "$@"