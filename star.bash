star() {
    local mode arg_mode arguments
    mode=HELP

    if [ $# -eq 0 ]; then
        star-help
        return 0
    fi
    arg_mode=$1

    case $arg_mode in
        add) mode=STORE        ;;
        L|list) mode=LIST      ;;
        l|load) mode=LOAD      ;;
        rename) mode=RENAME    ;;
        rm|remove) mode=REMOVE ;;
        reset) mode=RESET      ;;
        h|help|-h|--help)
            star-help
            return 0
            ;;
        *)
            echo >&2 "Invalid mode: $mode"
            star-help
            return 1
            ;;
    esac
    shift

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
            ;;
        LOAD)
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

    command star $arg_mode $arguments
}