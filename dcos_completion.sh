# _foo() 
# {
#     local cur prev opts
#     COMPREPLY=()
#     cur="${COMP_WORDS[COMP_CWORD]}"
#     prev="${COMP_WORDS[COMP_CWORD-1]}"
#     opts="--help --verbose --version"

#     if [[ ${cur} == -* ]] ; then
#         COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
#         return 0
#     fi
# }
# complete -F _foo foo

shopt -s extglob

# This took heavy inspiration from https://github.com/docker/docker/blob/9058ec3be5edaa313caa02371ebe7d7ac64f2faa/contrib/completion/bash/docker
# subcommand handling etc

# Transforms a multiline list of strings into a single line string
# with the words separated by "|".
# This is used to prepare arguments to __docker_pos_first_nonflag().
__dcos_to_alternatives() {
	local parts=( $1 )
	local IFS='|'
	echo "${parts[*]}"
}

# Transforms a multiline list of options into an extglob pattern
# suitable for use in case statements.
__dcos_to_extglob() {
	local extglob=$( __dcos_to_alternatives "$1" )
	echo "@($extglob)"
}

__dcos_log(){
    echo "$1" >> ./temp.txt
    return 0;
}

__dcos_childCommand(){

	local subcommands="$1"
	local counter=$(($command_pos + 1))
__dcos_log ""
__dcos_log childCommand.enter
__dcos_log childCommand.counter=$counter.cword=$cword.
__dcos_log childCommand.currentWord=${words[$counter]}.
__dcos_log childCommand.optionsToMatch=$(__dcos_to_extglob "$subcommands")
__dcos_log child.Command.chain=$currentCommandChain 

	while [ $counter -le $cword ]; do
		case "${words[$counter]}" in
# 			"")
# 				local completions_func=_dcos${currentCommandChain}
# __dcos_log childCommand.invoke=$completions_func            
# 				declare -F $completions_func >/dev/null && $completions_func
# __dcos_log childCommand.retis.$ret 
# 				return $ret
# 				;;
			"")
__dcos_log childCommand.ret1
				return 1
				;;
			$(__dcos_to_extglob "$subcommands") )
				command_pos=$counter
				local subcommand=${words[$counter]}
                currentCommandChain="${currentCommandChain}_${subcommand}"
				local completions_func=_dcos${currentCommandChain}
__dcos_log childCommand.invoke=$completions_func            
				declare -F $completions_func >/dev/null && $completions_func
                local ret=$?
__dcos_log childCommand.retis.$ret 
				return $ret
				;;
		esac
		(( counter++ ))
	done
__dcos_log childCommand.ret1
	return 1
}

_dcos_auth(){
    local subcommands="
        login
        logout
    "
__dcos_log auth.enter.

   	__dcos_childCommand "$subcommands" && return

__dcos_log auth.noChildMatch.cur=$cur.
	case "$cur" in
		-*)
__dcos_log auth.matchSwitch.
			COMPREPLY=( $( compgen -W "--help --info" -- "$cur" ) )
			;;
		*)
__dcos_log auth.matchCommand.
			COMPREPLY=( $( compgen -W "$subcommands" -- "$cur" ) )
			;;
	esac

	return 0;
}
# TODO - config
# TODO - help
# TODO - job

# TODO marathon-app-add file completion
# _dcos_marathon_app_add(){
# 	COMPREPLY=( $( compgen -W "--help --info --config-schema" -- "$cur" ) )
# }
_dcos_marathon_app(){
    local subcommands="
		about
		add
		list
		remove
		restart
		show
		start
		stop
		kill
		update
		version
    "

__dcos_log marathon.app.enter.

   	__dcos_childCommand "$subcommands" && return

	case "$cur" in
		"")
__dcos_log marathon.app.noCur.
			COMPREPLY=( $( compgen -W "$subcommands") )
			;;
		*)
__dcos_log marathon.app.cur=$cur.
			COMPREPLY=( $( compgen -W "$subcommands" -- "$cur" ) )
			;;
	esac
	return 0;
}
_dcos_marathon(){
    local subcommands="
        about
        app
        deployment
        group
        pod
        task
    "

   	__dcos_childCommand "$subcommands" && return

	case "$cur" in
		-*)
			COMPREPLY=( $( compgen -W "--help --info --config-schema" -- "$cur" ) )
			;;
		*)
			COMPREPLY=( $( compgen -W "$subcommands" -- "$cur" ) )
			;;
	esac
	return 0;	
}

# TODO - package
# TODO - service
# TODO - task

_dcos()
{
    local commands="
        auth
        config
        help
        marathon
        node
        package
        service
        task
    "
    COMPREPLY=()
    local cur prev words cword
	_get_comp_words_by_ref -n : cur prev words cword

    # current="${COMP_WORDS[COMP_CWORD]}"
    # previous="${COMP_WORDS[COMP_CWORD-1]}"

    currentCommandChain=""
   	command_pos=0
    __dcos_childCommand "$commands" && return

    __dcos_log main.$cur.
	case "$cur" in
		-*)
			COMPREPLY=( $( compgen -W "--help --version --debug" -- "$cur" ) )
			;;
		*)
			COMPREPLY=( $( compgen -W "$commands" -- "$cur" ) )
			;;
	esac


    # # complete top-level commands
    # if [[ ${COMP_CWORD} == 1 ]] ; then 
    #     COMPREPLY=( $(compgen -W "${commands}" -- ${current}) )
    #     return 0
    # fi
    # if [[ ${COMP_CWORD} -ge 2 ]] ; then
    #     currentWordIndex=1
    #     currentCommandChain=""
    #     __dcos_childCommand "$commands" && return       
    # fi 

}
complete -F _dcos dcos

## Notes
# create a subcommands function like the docker one, but we need to go deeper than cmd+subcmd
# e.g. dcos marathon group list
# so...have a global variable that stores the command chain and find sub command at current level
# then set the cmd chain to include that and call into that function
# all functions then call the subcommand function as per docker style
# could then use this at the top-level, i.e. to complete the first level of commads as well


# bar[0]=123
# $echo ${bar[0]}
#     123
# $ bar[1]=asd
# $ echo ${bar[1]}
#     asd
# $ echo ${bar[0]}
#     123
# $ echo ${#bar[@]}
#     2
