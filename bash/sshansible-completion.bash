# Bash completion for sshansible.py
_sshansible_hosts() {
	case ${COMP_WORDS[$COMP_CWORD]} in
		-*)
			COMPREPLY=($(compgen -W "--help --inventory --scp -l --last" -- ${COMP_WORDS[$COMP_CWORD]}))
			;;
		*)
			if [ ${COMP_WORDS[(($COMP_CWORD - 1))]} == "--inventory" ]; then
				COMPREPLY=($(compgen -f "${COMP_WORDS[$COMP_CWORD]}"))
			else
				for ((i=1; i < $COMP_CWORD - 1; i++)); do
					if [ "${COMP_WORDS[$i]}" == "--scp" ]; then
						COMPREPLY=($(compgen -f "${COMP_WORDS[$COMP_CWORD]}"))
						return
					fi
				done
				COMPREPLY=($(compgen -W "$(sshansible.py --complete-hosts)" "${COMP_WORDS[$COMP_CWORD]}"))
			fi
			;;
	esac
}

complete -F _sshansible_hosts sshansible.py
