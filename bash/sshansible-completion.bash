# Bash completion for sshansible.py
_sshansible_hosts() {
	case ${COMP_WORDS[$COMP_CWORD]} in
		-*)
			COMPREPLY=($(compgen -W "--help --inventory" -- ${COMP_WORDS[$COMP_CWORD]}))
			;;
		*)
			if [ ${COMP_WORDS[(($COMP_CWORD - 1))]} == "--inventory" ]; then
				COMPREPLY=($(compgen -f "${COMP_WORDS[$COMP_CWORD]}"))
			else
				COMPREPLY=($(compgen -W "$(sshansible.py --complete-hosts)" "${COMP_WORDS[$COMP_CWORD]}"))
			fi
			;;
	esac
}

complete -F _sshansible_hosts sshansible.py
