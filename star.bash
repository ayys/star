export _STAR_DIR="/Users/fruchame/Documents/Informatique/Projects/star/test/.star"
# export _STAR_DIR="$HOME/.star"

# Enable (yes) or disable (no) environment variables
export _STAR_EXPORT_ENV_VARIABLES="yes"

# The common prefix of the environment variables created according to the star names
export _STAR_ENV_PREFIX="STAR_"

# A character used to replace slashes in the star names
# This should not be changed
export _STAR_DIR_SEPARATOR="»"

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
    done < <(find "$_STAR_DIR" -xtype l -printf "%f\n")

    # return if no broken link was found
    if [[ ${#broken_stars_name[@]} -le 0 ]]; then
        return 0
    fi

    # else remove each broken link
    for bl in "${broken_stars_name[@]}"; do
        command rm "${_STAR_DIR}/${bl}" || return
    done
}

prune_broken_symlinks

unset -f prune_broken_symlinks

_star_set_variables()
{
    if [[ $_STAR_EXPORT_ENV_VARIABLES != "yes" ]]; then
        return
    fi
    # return if the star directory does not exist
    if [[ ! -d ${_STAR_DIR} ]];then
        return
    fi

    local stars_list star star_name star_path line env_var_name shell

    # list of stars with format: "name path", where path can contain spaces
    stars_list=()
    while IFS= read -r line; do
        # Extract just the star name from each line
        stars_list+=("$line")
    done < <(find "$_STAR_DIR" -type l -printf "%f %l\n")

    for star in "${stars_list[@]}"; do
        star_name=$(echo "$star" | cut -d' ' -f1)
        star_path=$(echo "$star" | cut -d' ' -f2-)
        star_name="${star_name//"${_STAR_DIR_SEPARATOR}"/_}"

        # convert name to a suitable environment variable name
        star_name=$(echo "$star_name" | tr ' +-.!?():,;=' '_' | tr --complement --delete "a-zA-Z0-9_" | tr '[:lower:]' '[:upper:]')

        env_var_name="${_STAR_ENV_PREFIX}${star_name}"

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
    # return if the star directory does not exist
    if [[ ! -d ${_STAR_DIR} ]]; then
        return
    fi

    local variables_list variable env_var_name line star_path

    # get all the environment variables starting with _STAR_ENV_PREFIX
    # format: <NAME>=<VALUE>
    variables_list=()
    while IFS= read -r line; do
        variables_list+=("$line")
    done < <(env | grep "^${_STAR_ENV_PREFIX}")

    for variable in "${variables_list[@]}"; do
        # unset the variable only if its value corresponds to an existing star path (absolute path of a starred directory)
        star_path="$(echo "$variable" | cut -d"=" -f2-)"
        if ! find "${_STAR_DIR}" -type l -printf "%l\n" | grep "^${star_path}$" &> /dev/null ; then
            continue
        fi
        env_var_name="$(echo "$variable" | cut -d"=" -f1)"
        unset "$env_var_name"
    done
}

star() {
    local mode arg_mode arguments
    mode=

    if [ $# -eq 0 ]; then
        star-help
        return 0
    fi
    arg_mode=$1
    shift

    case $arg_mode in
        add) mode=STORE        ;;
        L|list) mode=LIST      ;;
        l|load) [[ $# -lt 1 ]] && mode=LIST || mode=LOAD ;;
        rename) mode=RENAME    ;;
        rm|remove) mode=REMOVE ;;
        reset) mode=RESET      ;;
        h|help|-h|--help)
            star-help
            return 0
            ;;
        *)
            echo -e "Invalid mode: $arg_mode\n"
            star-help
            return 1
            ;;
    esac

    arguments=("$@")

    while [ $# -gt 0 ]; do
        if [[ "$1" == "-h" || "$1" == "--help" ]]; then
            star-help --mode="$arg_mode"
            return 0
        fi
        shift
    done

    local ret

    # process the selected mode
    case ${mode} in
        LIST)
            command star list $arguments
            ret=$?
            ;;
        LOAD)
            local load_output
            load_output=$(command star load $arguments)
            ret=$?

            if [[ -d $load_output ]]; then
                cd "$load_output"
            else
                echo -e "$load_output"
            fi
            ;;
        STORE)
            command star "$arg_mode" $arguments
            ret=$?
            # update environment variables
            _star_set_variables
            ;;
        RENAME|REMOVE)
            # remove all env variables while their paths are still known and their names still the same
            _star_unset_variables
            command star "$arg_mode" $arguments
            ret=$?
            # set back environment variables
            _star_set_variables
            ;;
        RESET)
            # remove all env variables while their paths are still known and their names still the same
            _star_unset_variables
            command star "$arg_mode" $arguments
            ret=$?
            ;;
        HELP)
            star-help
            ret=0
            ;;
        *)
            ;;
    esac

    return "$ret"
}

_star_set_variables