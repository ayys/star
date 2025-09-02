#!/usr/bin/env bash

script_dir=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

export _STAR_DIR="${script_dir}/test/.star"

# Enable (yes) or disable (no) environment variables
export _STAR_EXPORT_ENV_VARIABLES="no"

# The common prefix of the environment variables created according to the star names
export _STAR_ENV_PREFIX="STAR_"

# A character used to replace slashes in the star names
# This should not be changed
export _STAR_DIR_SEPARATOR="»"

if [ -t 1 ]; then
    # Check for truecolor support
    if [ "$COLORTERM" = "truecolor" ] || [ "$COLORTERM" = "24bit" ]; then
        _STAR_COLOR_STAR="\033[38;2;255;131;0m"  # Orange for star names
        _STAR_COLOR_PATH="\033[38;2;1;169;130m"  # HPE Way
    else
        # Use 256-color approximation
        _STAR_COLOR_STAR="\033[38;5;214m"
        _STAR_COLOR_PATH="\033[38;5;36m"
    fi
else
    # No color for non-interactive sessions (not a TTY)
    _STAR_COLOR_STAR=""
    _STAR_COLOR_PATH=""
fi
export _STAR_COLOR_STAR
export _STAR_COLOR_PATH

# TODO: move config file to $HOME/config/

# Remove all broken symlinks in the ".star" directory.
# A broken symlink corresponds to a starred directory that does not exist anymore.
prune_broken_symlinks() {
    # return if the star directory does not exist
    if [[ -z ${_STAR_DIR+x} || ! -d ${_STAR_DIR} ]]; then
        return 2
    fi
    local broken_stars_name bl line

    broken_stars_name=()

    while IFS= read -r line; do
        # Extract just the star name from each line
        broken_stars_name+=("$line")
    done < <(star-list --dir="$_STAR_DIR" --names --broken)

    # return if no broken link was found
    if [[ ${#broken_stars_name[@]} -le 0 ]]; then
        return 0
    fi

    # else remove each broken link
    for bl in "${broken_stars_name[@]}"; do
        command rm "${_STAR_DIR}/${bl}" || return
    done
}

main() {
    prune_broken_symlinks

    # all variables are local except _STAR_DIR and _STAR_DIR_SEPARATOR
    local star_to_store stars_to_remove star_to_load mode rename_src rename_dst
    local dst_name dst_name_slash dst_basename
    local star stars_list stars_list_str stars_path src_dir opt current_pwd user_input force_reset
    local existing_star existing_star_display target_path line
    
    # Color codes for consistent styling
    # Universal color reset
    local COLOR_RESET="\033[0m"
    # Cast global variables into locals to enable potential reformat without
    # having to rename all variables inside the function
    local COLOR_STAR="${_STAR_COLOR_STAR}"
    local COLOR_PATH="${_STAR_COLOR_PATH}"


    # Parse the arguments
    star_to_store=""
    stars_to_remove=()
    force_reset=0
    mode=HELP

    while [[ $# -gt 0 ]]; do
        opt="$1"
        shift

        # remove multiple stars
        if [[ ${mode} == REMOVE ]]; then
            stars_to_remove+=("${opt//\//"${_STAR_DIR_SEPARATOR}"}")
            continue
        fi

        case "$opt" in
            "--" ) break 2;;
            "-" ) break 2;;
            "add" )
                mode=STORE

                # first argument has to be the relative path
                if [[ $# -lt 1 ]]; then
                    echo -e "Missing argument.\n"
                    star-help --mode=add
                    return 1
                fi
                src_dir=$(realpath "$1")
                shift
                if [[ ! -d $src_dir ]]; then
                    echo -e "Directory does not exist: '$src_dir'.\n"
                    return 2
                fi

                # If there's another argument, use it as star name
                if [[ $# -gt 0 && ! "$1" =~ ^- ]]; then
                    star_to_store="$1"
                    shift
                fi
                break
                ;;
            "reset" )
                mode=RESET
                if [[ "$1" == "-f" || "$1" == "--force" ]]; then
                    force_reset=1
                fi
                break
                ;;
            "l"|"load" )
                # load without arguments is equivalent to "star list"
                if [[ $# -eq 0 ]]; then
                    mode=LIST
                    break 2
                fi
                star_to_load="${1//\//"${_STAR_DIR_SEPARATOR}"}"
                mode=LOAD
                shift
                ;;
            "rename" )
                mode=RENAME
                if [[ $# -lt 2 ]]; then
                    echo -e "Missing argument(s).\n"
                    star-help --mode=rename
                    return 1
                fi
                rename_src="${1//\//"${_STAR_DIR_SEPARATOR}"}"
                rename_dst="${2//\//"${_STAR_DIR_SEPARATOR}"}"
                break
                ;;
            "rm"|"remove" )
                if [[ $# -lt 1 ]]; then
                    echo -e "Missing argument(s).\n"
                    star-help --mode=remove
                    return 1
                fi
                stars_to_remove+=("${1//\//"${_STAR_DIR_SEPARATOR}"}")
                mode=REMOVE
                shift
                ;;
            "L"|"list" )
                mode=LIST
                # handle the "list" case immediately, no matter the other parameters
                break
                ;;
            "h"|"help"|"-h"|"--help" )
                mode=HELP
                break 2
                ;;
            *)
                echo -e "Invalid mode: $opt\n"
                star-help
                return 2
                ;;
       esac
    done

    # process the selected mode
    case ${mode} in
        STORE)
            if [[ ! -d "${_STAR_DIR}" ]]; then
                mkdir "${_STAR_DIR}"
            fi

            if [[ ! "${star_to_store}" == "" ]]; then
                # replace slashes by dir separator char: a star name can contain slashes
                dst_name="${star_to_store//\//"${_STAR_DIR_SEPARATOR}"}"
            else
                dst_name=$(basename "${src_dir}")
            fi

            # do not star this directory if it is already starred (even under another name)
            stars_path=( "$(find "$_STAR_DIR" -printf "%l\n")" )
            if [[ "${stars_path[*]}" =~ (^|[[:space:]])${src_dir}($|[[:space:]]) ]]; then
                # Find the star name for this directory
                existing_star=$(find "$_STAR_DIR" -type l -printf "%f %l\n" | grep " ${src_dir}$" | head -n1 | cut -d' ' -f1)
                existing_star_display=${existing_star//"${_STAR_DIR_SEPARATOR}"//}
                echo -e "Directory ${COLOR_PATH}${src_dir}${COLOR_RESET} is already starred as ${COLOR_STAR}${existing_star_display}${COLOR_RESET}."
                return 0
            fi

            # star names have to be unique: When adding a new starred directory using the basename of the path,
            # if the name is already taken then it will try to concatenate the previous folder from the path,
            # and will do this until the names are different or when there is no previous folder (root folder)
            # example:
            # in ~/foo/config:
            #   star would add a new star called "config" that refers to the absolute path to ~/foo/config
            # then in ~/bar/config:
            #   star would try to add a new star called "config", but there would be a conflict, so it would
            # add a new star called "bar/config"
            # 
            # As it is not possible to use slashes in file names, we use the special char _STAR_DIR_SEPARATOR to split "bar" and "config", 
            # that will be replaced by a slash when printing the star name or suggesting completion.
            # The variable _STAR_DIR_SEPARATOR must not be manualy changed, as it would cause the non-recognition of previously starred directories (their star name could contain that separator).
            if [[ "${star_to_store}" == "" ]]; then
                current_pwd=$(pwd)
                while [[ -e ${_STAR_DIR}/${dst_name} ]]; do
                    dst_name_slash=${dst_name//"${_STAR_DIR_SEPARATOR}"//}
                    dst_basename=$(basename "${current_pwd%%"$dst_name_slash"}")

                    if [[ "${dst_basename}" == "/" ]]; then
                        echo -e "Directory already starred with maximum possible path: ${COLOR_STAR}${dst_name_slash}${COLOR_RESET}."
                        return 0
                    fi

                    dst_name="${dst_basename}${_STAR_DIR_SEPARATOR}${dst_name}"
                done
            # When adding a new starred directory with a given name (as argument),
            # then the name should not already exist
            else
                dst_name_slash=${dst_name//"${_STAR_DIR_SEPARATOR}"//}
                if [[ -e ${_STAR_DIR}/${dst_name} ]]; then
                    # Get the path without adding colors in the find command
                    target_path=$(find "${_STAR_DIR}/${dst_name}" -type l -printf "%l\n")
                    echo -e "A directory is already starred with the name \"${dst_name_slash}\": ${COLOR_STAR}${dst_name_slash}${COLOR_RESET} -> ${COLOR_PATH}${target_path}${COLOR_RESET}."
                    return 0
                fi
            fi

            if ! ln -s "${src_dir}" "${_STAR_DIR}/${dst_name}"; then
                local res=$?
                echo -e "Failed to add a new starred directory: ${COLOR_STAR}${dst_name//"${_STAR_DIR_SEPARATOR}"//}${COLOR_RESET} -> ${COLOR_PATH}${src_dir}${COLOR_RESET}."
                return $res
            fi
            echo -e "Added new starred directory: ${COLOR_STAR}${dst_name//"${_STAR_DIR_SEPARATOR}"//}${COLOR_RESET} -> ${COLOR_PATH}${src_dir}${COLOR_RESET}."

            # update environment variables
            _star_set_variables
            ;;
        LOAD)
            if [[ ! -d "${_STAR_DIR}" ]]; then
                echo "No star can be loaded because there is no starred directory."
                return 0
            fi

            # Check if argument is purely numeric
            if [[ "${star_to_load}" =~ ^[0-9]+$ ]]; then
                # Get the list of stars sorted by access time (same as LIST mode)
                stars_list=()
                while IFS= read -r line; do
                    # Extract just the star name from each line
                    stars_list+=("$line")
                done < <(find "${_STAR_DIR}" -type l -printf "%As %f\n" | sort -nr | cut -d" " -f2-)
                
                # Check if the index is valid
                if [[ "${star_to_load}" -lt 1 || "${star_to_load}" -gt "${#stars_list[@]}" ]]; then
                    echo -e "Invalid star index: ${COLOR_STAR}${star_to_load}${COLOR_RESET}. Valid range is 1-${#stars_list[@]}."
                    return 2
                fi
                
                # Use shell detection to handle both bash and zsh
                if [[ -n "${ZSH_VERSION}" ]]; then
                    star_to_load="${stars_list[$star_to_load]}"
                else
                    star_to_load="${stars_list[$((star_to_load-1))]}"
                fi
            fi

            if [[ ! -e ${_STAR_DIR}/${star_to_load} ]]; then
                echo -e "Star ${COLOR_STAR}${star_to_load}${COLOR_RESET} does not exist."
            else
                if ! cd -P "${_STAR_DIR}/${star_to_load}"; then
                    local res=$?
                    echo -e "Failed to load star with name \"${COLOR_STAR}${star_to_load}${COLOR_RESET}\"."
                    return $res
                fi
                # update access time
                touch -ah "${_STAR_DIR}/${star_to_load}"
            fi
            ;;
        LIST)
            if [[ ! -d "${_STAR_DIR}" ]];then
                echo "No \".star\" directory (will be created when adding new starred directories)."
            else
                # sort according to access time (last accessed is on top)
                # Use printf to generate the formatted output with colors and add index numbers to the output for easy reference
                stars_list_str=$(find "${_STAR_DIR}" -type l -printf "%As %f %l\n" | sort -nr |
                            awk -v star="${COLOR_STAR}" -v path="${COLOR_PATH}" -v reset="${COLOR_RESET}" \
                            '{printf "%s: %s%s%s -> %s%s%s\n", (NR), star, $2, reset, path, $3, reset}' |
                            column -t)
                echo "${stars_list_str//"${_STAR_DIR_SEPARATOR}"//}"
            fi
            ;;
        RENAME)
            # remove the environment variable corresponding to the old name
            # (easier to remove all environment variables)
            _star_unset_variables

            if [[ -e "${_STAR_DIR}/${rename_src}" ]]; then
                if [[ -e "${_STAR_DIR}/${rename_dst}" ]]; then
                    echo -e "There is already a star named ${COLOR_STAR}${rename_dst}${COLOR_RESET}."
                    return 0
                fi

                if ! mv "${_STAR_DIR}/${rename_src}" "${_STAR_DIR}/${rename_dst}"; then
                    local res=$?
                    echo -e "Failed to rename star ${COLOR_STAR}${rename_src//"${_STAR_DIR_SEPARATOR}"//}${COLOR_RESET} to ${COLOR_STAR}${rename_dst//"${_STAR_DIR_SEPARATOR}"//}${COLOR_RESET}."
                    return $res
                fi
                echo -e "Renamed star ${COLOR_STAR}${rename_src//"${_STAR_DIR_SEPARATOR}"//}${COLOR_RESET} to ${COLOR_STAR}${rename_dst//"${_STAR_DIR_SEPARATOR}"//}${COLOR_RESET}."
            else
                echo -e "Star ${COLOR_STAR}${rename_src}${COLOR_RESET} does not exist."
            fi

            # update environment variables
            _star_set_variables
            ;;
        REMOVE)
            if [[ ! -d "${_STAR_DIR}" ]];then
                echo "No star can be removed, as there is not any starred directory."
                return 0
            fi

            # remove all env variables while their paths are still known
            _star_unset_variables

            for star in "${stars_to_remove[@]}"; do
                if [[ -e "${_STAR_DIR}/${star}" ]]; then
                    if ! command rm "${_STAR_DIR}/${star}"; then
                        local res=$?
                        echo -e "Failed to remove starred directory: ${COLOR_STAR}${star//"${_STAR_DIR_SEPARATOR}"//}${COLOR_RESET}."
                        return $res
                    fi
                    echo -e "Removed starred directory: ${COLOR_STAR}${star//"${_STAR_DIR_SEPARATOR}"//}${COLOR_RESET}."
                else
                    echo -e "Couldn't find any starred directory with the name: ${COLOR_STAR}${star//"${_STAR_DIR_SEPARATOR}"//}${COLOR_RESET}."
                fi
            done
            # re create the other environment variables
            _star_set_variables
            ;;
        RESET)
            if [[ ! -d "${_STAR_DIR}" ]];then
                echo "No \".star\" directory to remove."
                return 0
            fi

            if [[ "${force_reset}" -eq 1 ]]; then
                # remove all env variables while their paths are still known
                _star_unset_variables

                command rm -r "${_STAR_DIR}" && echo "All stars and the \".star\" directory have been removed." || echo "Failed to remove the \".star\" directory."
                return $?
            fi

            while true; do
                echo -n "Remove the \".star\" directory? (removes all starred directories) y/N "
                read user_input
                case $user_input in
                    [Yy]*|yes )
                        # remove all env variables while their paths are still known
                        _star_unset_variables

                        command rm -r "${_STAR_DIR}" && echo "All stars and the \".star\" directory have been removed." || echo "Failed to remove the \".star\" directory."
                        return $?
                        ;;
                    # case "" corresponds to pressing enter
                    # by default, pressing enter aborts the reset
                    [Nn]*|no|"" )
                        echo "Aborting reset." 
                        return 0
                        ;;
                    * )
                        echo "Not a valid answer.";;
                esac
            done
            ;;
        HELP)
            star-help
            return
            ;;
        *)
            ;;
    esac
}

main "$@"
exit $?
