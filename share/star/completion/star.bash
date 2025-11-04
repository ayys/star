# bash and zsh completion for star

# https://askubuntu.com/questions/68175/how-to-create-script-with-auto-complete
# https://web.archive.org/web/20190328055722/https://debian-administration.org/article/316/An_introduction_to_bash_completion_part_1
# https://web.archive.org/web/20140405211529/http://www.debian-administration.org/article/317/An_introduction_to_bash_completion_part_2
#
# https://unix.stackexchange.com/questions/273948/bash-completion-for-user-without-access-to-etc
# https://unix.stackexchange.com/questions/4219/how-do-i-get-bash-completion-for-command-aliases

# Provides completion for this "star" tool, and for its different aliases (see aliases below).
_complete_star()
{
    # character used to replace slashes in the star names
    local star_dir_separator="»"
    
    # clean up previous completions
    COMPREPLY=()

    # determine the completion mode
    local mode=""
    local first_cw="${COMP_WORDS[0]}"
    local second_cw="${COMP_WORDS[1]}"

    if [[ "${COMP_CWORD}" -eq 1 ]]; then
        # single word completion, i.e. "star" and aliases

        case "${first_cw}" in
            star)       mode=starmodes ;;
            # functions and aliases
            sadd)       mode=currentdirs ;;
            sremove)    mode=starnamesfiltered ;;
            unstar)     mode=starnamesfiltered ;;
            sload)      mode=starnames ;;
        esac
    elif [[ "${COMP_CWORD}" -eq 2 ]]; then
        # two words completions

        case "${first_cw}" in
            star)
                # star <MODE> completions
                case "${second_cw}" in
                    rename)     mode=starnames ;;
                    load|l)     mode=starnames ;;
                    add)        mode=currentdirs ;;
                    help|h)     mode=starmodes ;;
                    remove|rm)  mode=starnamesfiltered ; local current_star_names=() ;;
                    *) return 0 ;;  # no completion for other subcommands
                esac
            ;;
            sremove|unstar)
                # sremove <STAR_NAME> completions
                mode=starnamesfiltered ; local current_star_names=("${COMP_WORDS[@]:1}")
                ;;
        esac
    elif [[ "${COMP_CWORD}" -ge 3 && "${first_cw}" == "star" ]]; then
        # three or more words completion, corresponding to "star remove <STAR_NAME> ..."

        case "${second_cw}" in
            remove|rm)  mode=starnamesfiltered ; local current_star_names=("${COMP_WORDS[@]:2}") ;;
            *) return 0 ;;  # no completion for other subcommands
        esac
    else
        return 0
    fi

    local cur="${COMP_WORDS[COMP_CWORD]}"

    case "${mode}" in
        starmodes)
            # select all star modes
            local starmodes_opts="add load rename remove list reset config help"
            while IFS='' read -r; do COMPREPLY+=("$REPLY"); done < <(compgen -W "${starmodes_opts}" -- "${cur}")
            return 0
            ;;
        starnames)
            # select all star names
            local star_names
            star_names=$([[ -d "${_STAR_DATA_HOME}/stars" ]] && command find "${_STAR_DATA_HOME}/stars" -type l -not -xtype l -printf "%f ")
            while IFS='' read -r; do COMPREPLY+=("$REPLY"); done < <(compgen -W "${star_names//${star_dir_separator}/\/}" -- "${cur}")
            return 0
            ;;
        starnamesfiltered)
            # select all star names that are not yet used in the command line

            # select all star names
            local star_names=()
            if [[ -d "${_STAR_DATA_HOME}/stars" ]]; then
                while IFS= read -r; do star_names+=("$REPLY"); done < <(command find "${_STAR_DATA_HOME}/stars" -type l -not -xtype l -printf "%f\n")
            fi

            # Only keep the star names that are not yet used in the command line. 
            # Star names that are already in the command line are stored in $current_star_names.
            local final_star_names=()
            local star_name
            for star_name in "${star_names[@]}"; do
                if [[ ! " ${current_star_names[*]} " =~ [[:space:]]${star_name//${star_dir_separator}/\/}[[:space:]] ]]; then
                    final_star_names+=("${star_name}")
                fi
            done

            local print_final_star_names="${final_star_names[*]}"

            while IFS='' read -r; do COMPREPLY+=("$REPLY"); done < <(compgen -W "${print_final_star_names//${star_dir_separator}/\/}" -- "${cur}")
            return 0
            ;;
        currentdirs)
            # suggest directories at the location of the current directory, or directory being typed
            while IFS='' read -r; do COMPREPLY+=("$REPLY"); done < <(compgen -d -- "${cur}")
            return 0
            ;;
        default)
            ;;
    esac
}

# activate completion for star command
complete -F _complete_star star

# create useful aliases
alias sadd="star add"       # star add
alias slist="star list"     # star list
alias sremove="star remove" # star remove
alias unstar="star remove"  # star remove
alias sconfig="star config" # star config

# function that can be used as alias for both: 
# - "star list" (without argument)
# - "star load" (whith argument)
sload() {
    if [[ $# -eq 0 ]]; then
        star list
    else
        star load "$@"
    fi
}

# activate completion for the aliases
complete -F _complete_star sload
complete -F _complete_star sadd
complete -F _complete_star slist
complete -F _complete_star sremove
complete -F _complete_star unstar
