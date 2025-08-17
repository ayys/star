#!/usr/bin/env bash

# Directory in which to store the symlinks (stars)
# Will be created if it does not exist, and will be removed when resetting star
export _STAR_DIR="$HOME/.star"

# Enable (yes) or disable (no) environment variables
export _STAR_EXPORT_ENV_VARIABLES="yes"

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

_star_set_variables()
{
    if [[ $_STAR_EXPORT_ENV_VARIABLES != "yes" ]]; then
        return
    fi

    local stars_list star star_name star_path line env_var_name shell

    stars_list=()
    while IFS= read -r line; do
        # Extract just the star name from each line
        stars_list+=("$line")
    done < <(find "${_STAR_DIR}" -type l -printf "%f %l\n")

    for star in "${stars_list[@]}"; do
        star_name="${star%% *}"
        star_path="${star##* }"
        star_name="${star_name//"${_STAR_DIR_SEPARATOR}"/_}"

        # convert name to a suitable environment variable name
        star_name=$(echo "$star_name" | tr ' +-.!?():,;=' '_' | tr -cd "a-zA-Z0-9_" | tr '[:lower:]' '[:upper:]')

        env_var_name="${_STAR_ENV_PREFIX}${star_name//"${_STAR_DIR_SEPARATOR}"/_}"

        if test -n "$ZSH_VERSION"; then
            shell=zsh
        elif test -n "$BASH_VERSION"; then
            shell=bash
        fi

        # do not overwrite the variable if it already exists
        case $shell in
            zsh)    [ -z "${(P)env_var_name+x}" ] || continue ;;
            bash)   [ -z "${!env_var_name+x}" ] || continue ;;
        esac

        export "$env_var_name"="$star_path"
    done
}

_star_unset_variables()
{
    local variables_list variable env_var_name line star_path

    # get all the environment variables starting with _STAR_ENV_PREFIX
    # format: <NAME>=<VALUE>
    variables_list=()
    while IFS= read -r line; do
        variables_list+=("$line")
    done < <(env | grep "^${_STAR_ENV_PREFIX}")

    for variable in "${variables_list[@]}"; do
        # unset the variable only if its value corresponds to an existing star path (absolute path of a starred directory)
        star_path="$(echo "$variable" | cut -d"=" -f2)"
        if ! find "${_STAR_DIR}" -type l -printf "%l\n" | grep "^${star_path}$" &> /dev/null ; then
            continue
        fi
        env_var_name="$(echo "$variable" | cut -d"=" -f1)"
        unset "$env_var_name"
    done
}

# _star_prune
# Remove all broken symlinks in the ".star" directory.
# A broken symlink corresponds to a starred directory that does not exist anymore.
_star_prune()
{
    # return if the star directory does not exist
    if [[ ! -d ${_STAR_DIR} ]];then
        return
    fi

    local broken_stars_name bl
    broken_stars_name=( $(find $_STAR_DIR -xtype l -printf "%f\n") )

    # return if no broken link was found
    if [[ ${#broken_stars_name[@]} -le 0 ]]; then
        return
    fi

    # else remove each broken link
    for bl in "${broken_stars_name[@]}"; do
        rm "${_STAR_DIR}/${bl}" || return
    done
}

_star_usage()
{
    cat << EOF
Usage: star [MODE [ARGUMENTS]...]

Without MODE:
- Show this help message.

With MODE:
- Will execute the feature associated with this mode.
- MODE can be one of add, list, load, remove, reset, help, or one of their shortnames (such as -h for help).

MODE
    add [NAME]
        Add the current directory to the list of starred directories.
        The new star will be named after NAME if provided, otherwise it will
        use the basename of the current directory.
        NAME must be unique (among all stars).
        NAME can contain slashes /.

    list, L
        List all starred directories, sorted according to last load (top ones are the last loaded stars).

    load, l [STAR]
        Navigate (cd) into the starred directory.
        Equivalent to "star list" when no starred directory is given.

        STAR should be the name or index of a starred directory.
        (one that is listed using "star list").

    rename <EXISTING_STAR> <NEW_STAR_NAME>
        Rename an existing star.

    remove, rm <STAR> [STAR]...
        Remove one or more starred directories.

        STAR should be the name of a starred directory.

    reset [-f|--force]
        Remove the ".star" directory (hence remove the starred directories).
        The argument -f or --force will force the reset without prompting the user.

    help, h, --help, -h
        displays this message

ALIASES
The following aliases are provided:
    sL
        corresponds to "star list"
    sl
        corresponds to "star load"
    srm, unstar
        both corresponds to "star remove"
    sa, sah
        both corresponds to "star add"

EOF
}

star()
{
    _star_prune

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
                # If there's an argument after "add", use it as star name
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
                    echo "Missing argument. Usage: star rename <EXISTING_STAR> <NEW_STAR_NAME>"
                    return
                fi
                rename_src="${1//\//"${_STAR_DIR_SEPARATOR}"}"
                rename_dst="${2//\//"${_STAR_DIR_SEPARATOR}"}"
                break
                ;;
            "rm"|"remove" )
                if [[ $# -eq 0 ]]; then
                    echo "Missing argument. Usage: star remove <STAR> [STAR]..."
                    return
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
                echo >&2 "Invalid mode: $opt"
                return
                ;;
       esac
    done

    # process the selected mode
    case ${mode} in
        STORE)
            if [[ ! -d "${_STAR_DIR}" ]]; then
                mkdir "${_STAR_DIR}"
            fi

            src_dir=$(pwd)

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
                return
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
                        echo -e "Directory already starred with maximum possible path: ${COLOR_STAR}${dst_name_slash}${COLOR_RESET}"
                        return
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
                    echo -e "A directory is already starred with the name \"${dst_name_slash}\": ${COLOR_STAR}${dst_name_slash}${COLOR_RESET} -> ${COLOR_PATH}${target_path}${COLOR_RESET}"
                    return
                fi
            fi

            ln -s "${src_dir}" "${_STAR_DIR}/${dst_name}" || return
            echo -e "Added new starred directory: ${COLOR_STAR}${dst_name//"${_STAR_DIR_SEPARATOR}"//}${COLOR_RESET} -> ${COLOR_PATH}${src_dir}${COLOR_RESET}"

            # update environment variables
            _star_set_variables
            ;;
        LOAD)
            if [[ ! -d "${_STAR_DIR}" ]];then
                echo "No star can be loaded because there is no starred directory."
                return
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
                    return
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
                cd -P "${_STAR_DIR}/${star_to_load}" || return
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
                    return
                fi

                mv "${_STAR_DIR}/${rename_src}" "${_STAR_DIR}/${rename_dst}" || return
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
                return
            fi

            # remove all env variables while their paths are still known
            _star_unset_variables

            for star in "${stars_to_remove[@]}"; do
                if [[ -e "${_STAR_DIR}/${star}" ]]; then
                    rm "${_STAR_DIR}/${star}" || return
                    echo -e "Removed starred directory: ${COLOR_STAR}${star//"${_STAR_DIR_SEPARATOR}"//}${COLOR_RESET}"
                else
                    echo -e "Couldn't find any starred directory with the name: ${COLOR_STAR}${star//"${_STAR_DIR_SEPARATOR}"//}${COLOR_RESET}"
                fi
            done
            # re create the other environment variables
            _star_set_variables
            ;;
        RESET)
            if [[ ! -d "${_STAR_DIR}" ]];then
                echo "No \".star\" directory to remove."
                return
            fi

            if [[ "${force_reset}" -eq 1 ]]; then
                # remove all env variables while their paths are still known
                _star_unset_variables

                rm -r "${_STAR_DIR}" && echo "All stars and the \".star\" directory have been removed." || echo "Failed to remove the \".star\" directory."
                return
            fi

            while true; do
                echo -n "Remove the \".star\" directory? (removes all starred directories) y/N "
                read user_input
                case $user_input in
                    [Yy]*|yes )
                        # remove all env variables while their paths are still known
                        _star_unset_variables

                        rm -r "${_STAR_DIR}" && echo "All stars and the \".star\" directory have been removed." || echo "Failed to remove the \".star\" directory."
                        return;;
                    # case "" corresponds to pressing enter
                    # by default, pressing enter aborts the reset
                    [Nn]*|no|"" )
                        echo "Aborting reset." 
                        return;;
                    * )
                        echo "Not a valid answer.";;
                esac
            done
            ;;
        HELP)
            _star_usage
            return
            ;;
        *)
            ;;
    esac
}

# https://askubuntu.com/questions/68175/how-to-create-script-with-auto-complete
# https://web.archive.org/web/20190328055722/https://debian-administration.org/article/316/An_introduction_to_bash_completion_part_1
# https://web.archive.org/web/20140405211529/http://www.debian-administration.org/article/317/An_introduction_to_bash_completion_part_2
#
# https://unix.stackexchange.com/questions/273948/bash-completion-for-user-without-access-to-etc
# https://unix.stackexchange.com/questions/4219/how-do-i-get-bash-completion-for-command-aliases

# _star_completion
# Provides completion for this "star" tool, and for its different aliases (see aliases below).
_star_completion()
{
    _star_prune
    local cur prev opts first_cw second_cw stars_list
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    opts="add load rename remove list reset help"

    # first and second comp words
    first_cw="${COMP_WORDS[COMP_CWORD-COMP_CWORD]}"
    second_cw="${COMP_WORDS[COMP_CWORD-COMP_CWORD+1]}"

    # get list of stars only if ".star" directory exists
    stars_list=$([[ -d "${_STAR_DIR}" ]] && find ${_STAR_DIR} -type l -printf "%f ")

    # in REMOVE mode: suggest all starred directories, even after selecting a first star to remove
    if [[ "${first_cw}" == "srm" \
        || "${first_cw}" == "unstar" \
        || "${second_cw}" == "remove" \
        || "${second_cw}" == "rm" \
    ]]; then
        # suggest all starred directories
        COMPREPLY=( $(compgen -W "${stars_list//"${_STAR_DIR_SEPARATOR}"/\/}" -- ${cur}) )
        return 0
    fi

    case "${prev}" in
        load|l|sl|rename)
            # suggest all starred directories
            COMPREPLY=( $(compgen -W "${stars_list//"${_STAR_DIR_SEPARATOR}"/\/}" -- ${cur}) )
            return 0
            ;;
        star)
            # only suggest options when star is the first comp word
            # to prevent suggesting options in case a starred directory is named "star"
            [ "${COMP_CWORD}" -eq 1 ] && COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
            return 0
            ;;
        reset)
            COMPREPLY=( $(compgen -W "-f --force" -- ${cur}) )
            return 0
            ;;
        *)
            ;;
    esac
}

# create useful aliases
alias sl="star l"       # star load
alias sL="star L"       # star list
alias srm="star rm"     # star remove
alias unstar="star rm"  # star remove
alias sa="star add"     # star add
alias sah="star add"    # star add

# activate completion for this program and the aliases
complete -F _star_completion star
complete -F _star_completion sl
complete -F _star_completion srm
complete -F _star_completion unstar
complete -F _star_completion sah

# remove broken symlinks directly when sourcing this file
_star_prune

# set environment variables
_star_set_variables
