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

# Color codes for consistent styling
# Universal color reset
export COLOR_RESET="\033[0m"
# Cast global variables into locals to enable potential reformat without
# having to rename all variables inside the function
export COLOR_STAR="${_STAR_COLOR_STAR}"
export COLOR_PATH="${_STAR_COLOR_PATH}"

# it is strongly recommended to set the number of columns in the 'column' command (--table-columns-limit) and to put the path in the last column, 
# as a path can contain whitespaces (which is the characyer used by 'column' to split columns)
export DISPLAY_FORMAT="<INDEX>: ${COLOR_STAR}%f${COLOR_RESET} -> ${COLOR_PATH}%l${COLOR_RESET}"
export DISPLAY_COLUMN_COMMAND="command column --table --table-columns-limit 3"

# TODO: move config file to $HOME/config/

main() {
    # all variables are local except _STAR_DIR and _STAR_DIR_SEPARATOR
    local star_to_store stars_to_remove star_to_load mode rename_src rename_dst
    local dst_name dst_name_slash dst_basename
    local star stars_list stars_list_str stars_path src_dir opt user_input force_reset
    local existing_star existing_star_display target_path line

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
                    echo -e "star add: missing PATH argument.\n"
                    star-help --mode=add
                    return 1
                fi
                src_dir=$(realpath "$1")
                shift
                if [[ ! -d $src_dir ]]; then
                    echo -e "Directory does not exist: '$src_dir'.\n"
                    return 2
                fi

                # If there's another argument then use it as star name,
                # else the star name will be created from the name of the directory
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
                # first argument should be the name or the index of the star to load
                if [[ $# -lt 1 ]]; then
                    echo -e "star load: missing STAR argument.\n"
                    star-help --mode=load
                    return 1
                fi
                star_to_load="${1//\//"${_STAR_DIR_SEPARATOR}"}"
                mode=LOAD
                shift
                ;;
            "rename" )
                mode=RENAME
                if [[ $# -lt 2 ]]; then
                    echo -e "star rename: missing argument(s).\n"
                    star-help --mode=rename
                    return 1
                fi
                rename_src="${1//\//"${_STAR_DIR_SEPARATOR}"}"
                rename_dst="${2//\//"${_STAR_DIR_SEPARATOR}"}"
                break
                ;;
            "rm"|"remove" )
                if [[ $# -lt 1 ]]; then
                    echo -e "star remove: missing argument(s).\n"
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
                # else get the star name from the name of the directory
                dst_name=$(basename "${src_dir}")
            fi

            # get the paths of all starred directories
            stars_path=()
            while IFS= read -r line; do
                stars_path+=("$line")
            done < <(star-list "$_STAR_DIR" --paths)

            # do not star this directory if it is already starred (even under another name)
            if [[ "${stars_path[*]}" =~ (^|[[:space:]])${src_dir}($|[[:space:]]) ]]; then
                # Find the star name for this directory's path
                existing_star=$(star-list "$_STAR_DIR" --get-name="$src_dir")
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
                # need to store the whitespace-free name in a temporary variable in order to keep the existing path
                local tmp_name=$(echo "${dst_name}" | tr --squeeze-repeats ' ' | tr ' ' '-')

                while [[ -e ${_STAR_DIR}/${tmp_name} ]]; do
                    dst_name_slash=${dst_name//"${_STAR_DIR_SEPARATOR}"//}
                    dst_basename=$(basename "${src_dir%%"$dst_name_slash"}")

                    if [[ "${dst_basename}" == "/" ]]; then
                        echo -e "Directory already starred with maximum possible path: ${COLOR_STAR}${dst_name_slash}${COLOR_RESET}."
                        return 0
                    fi

                    dst_name="${dst_basename}${_STAR_DIR_SEPARATOR}${dst_name}"
                    # update the temporary name in order to check if it exists in the star names
                    tmp_name=$(echo "${dst_name}" | tr --squeeze-repeats ' ' | tr ' ' '-')
                done
                # replace whitespaces with a single dash (needs to be done AFTER looping over paths, to keep the existing paths)
                dst_name=$( echo "${dst_name}" | tr --squeeze-repeats ' ' | tr ' ' '-')

            # When adding a new starred directory with a given name (as argument),
            # then the name should not already exist
            else
                # replace whitespaces with a single dash
                dst_name=$( echo "${dst_name}" | tr --squeeze-repeats ' ' | tr ' ' '-')

                dst_name_slash=${dst_name//"${_STAR_DIR_SEPARATOR}"//}
                if [[ -e ${_STAR_DIR}/${dst_name} ]]; then
                    # Get the path associated with star name
                    target_path=$(star-list "$_STAR_DIR" --get-path="$dst_name")

                    echo -e "A directory is already starred with the name \"${dst_name_slash}\": ${COLOR_STAR}${dst_name_slash}${COLOR_RESET} -> ${COLOR_PATH}${target_path}${COLOR_RESET}."
                    return 0
                fi
            fi

            # if name is purely numeric, add a prefix in order to not mix with index based navigation
            if [[ "${dst_name}" =~ ^[0-9]+$ ]]; then
                dst_name="dir-${dst_name}"
            fi

            if ! ln -s "${src_dir}" "${_STAR_DIR}/${dst_name}"; then
                local res=$?
                echo -e "Failed to add a new starred directory: ${COLOR_STAR}${dst_name//"${_STAR_DIR_SEPARATOR}"//}${COLOR_RESET} -> ${COLOR_PATH}${src_dir}${COLOR_RESET}."
                return $res
            fi
            echo -e "Added new starred directory: ${COLOR_STAR}${dst_name//"${_STAR_DIR_SEPARATOR}"//}${COLOR_RESET} -> ${COLOR_PATH}${src_dir}${COLOR_RESET}."
            ;;
        LOAD)
            if [[ ! -d "${_STAR_DIR}" ]]; then
                echo "No star can be loaded because there is no starred directory."
                return 0
            fi

            # Check if argument is purely numeric
            if [[ "${star_to_load}" =~ ^[0-9]+$ ]]; then
                # Get the list of star names
                stars_list=()
                while IFS= read -r line; do
                    stars_list+=("$line")
                done < <(star-list "${_STAR_DIR}" --names) # TODO: pass sorting parameters to star-list

                # Check if the index is valid
                if [[ "${star_to_load}" -lt 1 || "${star_to_load}" -gt "${#stars_list[@]}" ]]; then
                    echo -e "Invalid star index: ${COLOR_STAR}${star_to_load}${COLOR_RESET}. Valid range is 1-${#stars_list[@]}."
                    return 2
                fi
                
                star_to_load="${stars_list[$((star_to_load-1))]}"
            fi

            if [[ ! -e ${_STAR_DIR}/${star_to_load} ]]; then
                echo -e "Star ${COLOR_STAR}${star_to_load}${COLOR_RESET} does not exist."
            else
                local star_to_load_path
                # get path according to name
                star_to_load_path=$(star-list "$_STAR_DIR" --get-path="$star_to_load")

                if [[ ! -d "$star_to_load_path" ]]; then
                    echo -e "Failed to load star with name \"${COLOR_STAR}${star_to_load}${COLOR_RESET}\": associated directory  \"${COLOR_PATH}${star_to_load_path}${COLOR_RESET}\" does not exist."
                    return 2
                fi
                echo "$star_to_load_path"
                # update access time
                touch -ah "${_STAR_DIR}/${star_to_load}"
            fi
            ;;
        LIST)
            if [[ ! -d "${_STAR_DIR}" ]];then
                echo "No \".star\" directory (will be created when adding new starred directories)."
            else
                # TODO: pass sorting parameters to star-list
                stars_list_str=$(star-list "${_STAR_DIR}" --format="$DISPLAY_FORMAT")
                echo "${stars_list_str//"${_STAR_DIR_SEPARATOR}"//}" | $DISPLAY_COLUMN_COMMAND
            fi
            ;;
        RENAME)
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
            ;;
        REMOVE)
            if [[ ! -d "${_STAR_DIR}" ]];then
                echo "No star can be removed, as there is not any starred directory."
                return 0
            fi

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
            ;;
        RESET)
            if [[ ! -d "${_STAR_DIR}" ]];then
                echo "No \".star\" directory to remove."
                return 0
            fi

            if [[ "${force_reset}" -eq 1 ]]; then
                command rm -r "${_STAR_DIR}" && echo "All stars and the \".star\" directory have been removed." || echo "Failed to remove the \".star\" directory."
                return $?
            fi

            while true; do
                echo -n "Remove the \".star\" directory? (removes all starred directories) y/N "
                read user_input
                case $user_input in
                    [Yy]*|yes )
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
