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

    # process the selected mode
    case ${mode} in
        STORE)
            ;;
        LIST)
            command star list "${arguments[*]}"
            return $?
            ;;
        LOAD)
            local load_res load_output
            load_output=$(command star load "${arguments[*]}")
            load_res=$?

            if [[ -d $load_output ]]; then
                cd "$load_output"
            else
                echo -e "$load_output"
            fi
            return $load_res
            ;;
        RENAME)
            ;;
        REMOVE)
            ;;
        RESET)
            ;;
        HELP)
            star-help
            return 0
            ;;
        *)
            ;;
    esac

    command star "$arg_mode" "${arguments[*]}"
}