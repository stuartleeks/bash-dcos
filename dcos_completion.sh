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
    # echo "$1" >> ./temp.txt
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

#######################################################################################
##
## Completion helpers
##

__dcos_complete_marathon_app_ids(){
	local apps=( $(dcos marathon app list --json | jq --raw-output ".[] | .id") )
	COMPREPLY=( $(compgen -W "${apps[*]}" -- "$cur") )
}
__dcos_complete_marathon_deployment_ids(){
	local apps=( $(dcos marathon deployment list --json | jq --raw-output ".[] | .id") )
	COMPREPLY=( $(compgen -W "${apps[*]}" -- "$cur") )
}
__dcos_complete_marathon_group_ids(){
	local apps=( $(dcos marathon group list --json | jq --raw-output ".[] | .id") )
	COMPREPLY=( $(compgen -W "${apps[*]}" -- "$cur") )
}

#######################################################################################
##
## dcos auth
##


_dcos_auth(){
    local subcommands="
        login
        logout
    "

	case "$cur" in
		-*)
			COMPREPLY=( $( compgen -W "--help --info" -- "$cur" ) )
			;;
		*)
			COMPREPLY=( $( compgen -W "$subcommands" -- "$cur" ) )
			;;
	esac
	return 0;
}

#######################################################################################
##
## dcos config
##

# TODO - config

#######################################################################################
##
## dcos help
##

# TODO - help

#######################################################################################
##
## dcos job
##

# TODO - job


#######################################################################################
##
## dcos marathon
##



##
## dcos marathon about
##
_dcos_marathon_about(){
	return 0; # suppress completion
}

##
## dcos marathon app
##
_dcos_marathon_app_add(){
	COMPREPLY=( $( compgen -o filenames -A file -- "$cur" ) )
	return 0;
}
_dcos_marathon_app_list(){
	COMPREPLY=( $( compgen -W "--json" -- "$cur" ) )
	return 0;
}
_dcos_marathon_app_remove(){
	case "$cur" in
		-*)
			COMPREPLY=( $( compgen -W "--force" -- "$cur" ) )
			;;
		*)
			cur="${cur##*=}"
			__dcos_complete_marathon_app_ids
			return 0
			;;
	esac
	return 0;
}
_dcos_marathon_app_restart(){
	case "$cur" in
		-*)
			COMPREPLY=( $( compgen -W "--force" -- "$cur" ) )
			;;
		*)
			cur="${cur##*=}"
			__dcos_complete_marathon_app_ids
			return 0
			;;
	esac
	return 0;
}
_dcos_marathon_app_show(){
	case "$cur" in
		-*)
			COMPREPLY=( $( compgen -W "--app-version=" -- "$cur" ) ) # TODO complete version numbers
			;;
		*)
			cur="${cur##*=}"
			__dcos_complete_marathon_app_ids
			return 0
			;;
	esac
	return 0;
}
_dcos_marathon_app_start(){
	case "$cur" in
		-*)
			COMPREPLY=( $( compgen -W "--force" -- "$cur" ) )
			;;
		*)
			cur="${cur##*=}"
			__dcos_complete_marathon_app_ids
			return 0
			;;
	esac
	return 0;
}
_dcos_marathon_app_stop(){
	case "$cur" in
		-*)
			COMPREPLY=( $( compgen -W "--force" -- "$cur" ) )
			;;
		*)
			cur="${cur##*=}"
			__dcos_complete_marathon_app_ids
			return 0
			;;
	esac
	return 0;
}
_dcos_marathon_app_kill(){
	case "$cur" in
		-*)
			COMPREPLY=( $( compgen -W "--scale --host=" -- "$cur" ) ) ## TODO complete host
			;;
		*)
			cur="${cur##*=}"
			__dcos_complete_marathon_app_ids
			return 0
			;;
	esac
	return 0;
}
_dcos_marathon_app_list(){
	case "$cur" in
		-*)
			COMPREPLY=( $( compgen -W "--max-count= " -- "$cur" ) )
			;;
		*)
			cur="${cur##*=}"
			__dcos_complete_marathon_app_ids
			return 0
			;;
	esac
	return 0;
}
_dcos_marathon_app_update(){
	case "$cur" in
		-*)
			COMPREPLY=( $( compgen -W "--force" -- "$cur" ) )
			;;
		*)
			cur="${cur##*=}"
			__dcos_complete_marathon_app_ids
			return 0
			;;
	esac ## TODO complete properties
	return 0;
}
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
   	__dcos_childCommand "$subcommands" && return

	case "$cur" in
		"")
			COMPREPLY=( $( compgen -W "$subcommands") )
			;;
		*)
			COMPREPLY=( $( compgen -W "$subcommands" -- "$cur" ) )
			;;
	esac
	return 0;
}
##
## dcos marathon deployment
##

_dcos_marathon_deployment_list(){
	COMPREPLY=( $( compgen -W "--json" -- "$cur" ) )
	return 0;
}
_dcos_marathon_deployment_rollback(){
	__dcos_complete_marathon_deployment_ids
	return 0;
}
_dcos_marathon_deployment_stop(){
	__dcos_complete_marathon_deployment_ids
	return 0;
}
_dcos_marathon_deployment_watch(){
	case "$cur" in
		-*)
			COMPREPLY=( $( compgen -W "--interval --max-count= " -- "$cur" ) )
			;;
		*)
			cur="${cur##*=}"
			__dcos_complete_marathon_deployment_ids
			return 0
			;;
	esac
	return 0;
}
_dcos_marathon_deployment(){
    local subcommands="
		list
		rollback
		stop
		watch
    "
   	__dcos_childCommand "$subcommands" && return

	case "$cur" in
		"")
			COMPREPLY=( $( compgen -W "$subcommands") )
			;;
		*)
			COMPREPLY=( $( compgen -W "$subcommands" -- "$cur" ) )
			;;
	esac
	return 0;
}

##
## dcos marathon group
##

_dcos_marathon_group_add(){
	COMPREPLY=( $( compgen -o filenames -A file -- "$cur" ) )
	return 0;
}
_dcos_marathon_group_list(){
	COMPREPLY=( $( compgen -W "--json" -- "$cur" ) )
	return 0;
}
_dcos_marathon_group_scale(){
	case "$cur" in
		-*)
			COMPREPLY=( $( compgen -W "--force" -- "$cur" ) )
			;;
		*)
			cur="${cur##*=}"
			__dcos_complete_marathon_group_ids
			return 0
			;;
	esac
	return 0;
}
_dcos_marathon_group_show(){
	case "$cur" in
		-*)
			COMPREPLY=( $( compgen -W "--group-version=" -- "$cur" ) ) # TODO complete version numbers
			;;
		*)
			cur="${cur##*=}"
			__dcos_complete_marathon_group_ids
			return 0
			;;
	esac
	return 0;
}
_dcos_marathon_group_remove(){
	case "$cur" in
		-*)
			COMPREPLY=( $( compgen -W "--force" -- "$cur" ) )
			;;
		*)
			cur="${cur##*=}"
			__dcos_complete_marathon_group_ids
			return 0
			;;
	esac
	return 0;
}
_dcos_marathon_group_update(){
	case "$cur" in
		-*)
			COMPREPLY=( $( compgen -W "--force" -- "$cur" ) )
			;;
		*)
			cur="${cur##*=}"
			__dcos_complete_marathon_group_ids
			return 0
			;;
	esac ## TODO complete properties
	return 0;
}
_dcos_marathon_group(){
    local subcommands="
		add
		list
		scale
		show
		remove
		update
    "
   	__dcos_childCommand "$subcommands" && return

	case "$cur" in
		"")
			COMPREPLY=( $( compgen -W "$subcommands") )
			;;
		*)
			COMPREPLY=( $( compgen -W "$subcommands" -- "$cur" ) )
			;;
	esac
	return 0;
}



##
## dcos marathon pod
##

## TODO


##
## dcos marathon task
##

## TODO


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

#######################################################################################
##
## dcos package
##

# TODO - package

#######################################################################################
##
## dcos service
##

# TODO - service


#######################################################################################
##
## dcos task
##

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

}
complete -F _dcos dcos
