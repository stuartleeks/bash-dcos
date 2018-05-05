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

# TODO look at how to cache some of this :-)

__dcos_complete_clusters(){
	# This is very slow...
	# local clusters=( $(dcos cluster list --json | jq --raw-output ".[] | .name") )

	# So instead...
	local clusters=$(sed -n -e 's/name = "\(.*\)"/\1/p' ~/.dcos/clusters/*/dcos.toml)

	COMPREPLY=( $(compgen -W "${clusters[*]}" -- "$cur") )
}

__dcos_complete_job_ids(){
	local jobs=( $(dcos job list --json | jq --raw-output ".[] | .id") )
	COMPREPLY=( $(compgen -W "${jobs[*]}" -- "$cur") )
}

__dcos_complete_marathon_app_ids(){
	local apps=( $(dcos marathon app list --json | jq --raw-output ".[] | .id") )
	COMPREPLY=( $(compgen -W "${apps[*]}" -- "$cur") )
}
__dcos_complete_marathon_deployment_ids(){
	local deployments=( $(dcos marathon deployment list --json | jq --raw-output ".[] | .id") )
	COMPREPLY=( $(compgen -W "${deployments[*]}" -- "$cur") )
}
__dcos_complete_marathon_group_ids(){
	local groups=( $(dcos marathon group list --json | jq --raw-output ".[] | .id") )
	COMPREPLY=( $(compgen -W "${groups[*]}" -- "$cur") )
}
__dcos_complete_marathon_task_ids(){
	local tasks=( $(dcos marathon task list --json | jq --raw-output ".[] | .id") )
	COMPREPLY=( $(compgen -W "${tasks[*]}" -- "$cur") )
}

__dcos_complete_package_names(){
	local packages=( $(dcos package search --json | jq --raw-output ".[] | .[]  | .name") )
	COMPREPLY=( $(compgen -W "${packages[*]}" -- "$cur") )
}
__dcos_complete_package_repo_names(){
	local repos=( $(dcos package repo list --json | jq --raw-output ".[] | .[]  | .name") )
	COMPREPLY=( $(compgen -W "${repos[*]}" -- "$cur") )
}

__dcos_complete_service_ids(){
	local jobs=( $(dcos service --json | jq --raw-output ".[] | .id") )
	COMPREPLY=( $(compgen -W "${jobs[*]}" -- "$cur") )
}
__dcos_complete_service_names(){
	local jobs=( $(dcos service --json | jq --raw-output ".[] | .name") )
	COMPREPLY=( $(compgen -W "${jobs[*]}" -- "$cur") )
}

__dcos_complete_task_ids(){
	local tasks=( $(dcos task ls | grep "===>" | awk '{print $2}') )
	COMPREPLY=( $(compgen -W "${tasks[*]}" -- "$cur") )
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
_dcos_config_set(){
	# TODO consider completing name
	return 0;
}
_dcos_config_show(){
	# TODO complete name
	return 0;
}
_dcos_config_unset(){
	# TODO complete name
	return 0;
}
_dcos_config_validate(){
	return 0;
}
_dcos_config(){
    local subcommands="
        set
		show
		unset
		validate
    "

   	__dcos_childCommand "$subcommands" && return

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
## dcos help
##

# TODO - help

#######################################################################################
##
## dcos cluster
##
_dcos_cluster_attach() {
	__dcos_complete_clusters
	return 0
}

_dcos_cluster_list() {
	COMPREPLY=( $( compgen -W "--attached --json" -- "$cur" ) )
	return 0
}

_dcos_cluster_remove(){
	case "$cur" in
		-*)
			COMPREPLY=( $( compgen -W "--all" -- "$cur" ) )
			;;
		*)
			cur="${cur##*=}"
			__dcos_complete_clusters
			return 0
			;;
	esac
	return 0;
}

_dcos_cluster_rename(){
	__dcos_complete_clusters
	return 0;
}

_dcos_cluster_setup(){
	case "$cur" in
		-*)
			COMPREPLY=( $( compgen -W "--insecure --no-check --ca-certs= --provider= --username= --password= --password-file= --password-env= --private-key=" -- "$cur" ) )
			;;
		*)
			;;
	esac
	return 0;
}

_dcos_cluster(){
    local subcommands="attach list rename remove setup"

    __dcos_childCommand "$subcommands" && return

	case "$cur" in
		-*)
			COMPREPLY=( $( compgen -W "--help --info --version" -- "$cur" ) )
			;;
		*)
			COMPREPLY=( $( compgen -W "$subcommands" -- "$cur" ) )
			;;
	esac
	return 0;
}

#######################################################################################
##
## dcos job
##

# TODO - job
_dcos_job_add(){
	COMPREPLY=( $( compgen -o filenames -A file -- "$cur" ) )
	return 0;
}
_dcos_job_remove(){
	case "$cur" in
		-*)
			COMPREPLY=( $( compgen -W "--stop-current-job-runs" -- "$cur" ) )
			;;
		*)
			cur="${cur##*=}"
			__dcos_complete_job_ids
			return 0
			;;
	esac
	return 0;
}
_dcos_job_show(){
	__dcos_complete_job_ids
	return 0;
}
_dcos_job_update(){
	COMPREPLY=( $( compgen -o filenames -A file -- "$cur" ) )
	return 0;
}
_dcos_job_kill(){
	# TODO complete run-id
	case "$cur" in
		-*)
			COMPREPLY=( $( compgen -W "--all" -- "$cur" ) )
			;;
		*)
			cur="${cur##*=}"
			__dcos_complete_job_ids
			return 0
			;;
	esac
	return 0;
}
_dcos_job_run(){
	__dcos_complete_job_ids
	return 0;
}
_dcos_job_list(){
	COMPREPLY=( $( compgen -W "--json" -- "$cur" ) )
	return 0;
}
_dcos_job_schedule_add(){
	## TODO complete schedule file
	__dcos_complete_job_ids
	return 0;
}
_dcos_job_schedule_show(){
	case "$cur" in
		-*)
			COMPREPLY=( $( compgen -W "--json" -- "$cur" ) )
			;;
		*)
			cur="${cur##*=}"
			__dcos_complete_job_ids
			;;
	esac
	return 0;	
}
_dcos_job_schedule_remove(){
	## TODO complete schedule-id
	__dcos_complete_job_ids
	return 0;
}
_dcos_job_schedule_update(){
	## TODO complete schedule file
	__dcos_complete_job_ids
	return 0;
}
_dcos_job_schedule(){
    local subcommands="
        add
		show
		remove
		update
    "

   	__dcos_childCommand "$subcommands" && return

	COMPREPLY=( $( compgen -W "$subcommands" -- "$cur" ) )
	return 0;	
}
_dcos_job_history(){
	case "$cur" in
		-*)
			COMPREPLY=( $( compgen -W "--json --show-failures" -- "$cur" ) )
			;;
		*)
			cur="${cur##*=}"
			__dcos_complete_job_ids
			;;
	esac
	return 0;	
}
## TODO "show runs"
_dcos_job(){
    local subcommands="
        add
		remove
		show
		update
		kill
		run
		list
		schedule
		history
    "

   	__dcos_childCommand "$subcommands" && return

	case "$cur" in
		-*)
			COMPREPLY=( $( compgen -W "--help --version --config-schema --info" -- "$cur" ) )
			;;
		*)
			COMPREPLY=( $( compgen -W "$subcommands" -- "$cur" ) )
			;;
	esac
	return 0;	
}
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

_dcos_marathon_pod_add(){
	return 0; ## TODO add pod-id completion
}
_dcos_marathon_pod_kill(){
	return 0; ## TODO add pod-id completion, and instance ids
}
_dcos_marathon_pod_list(){
	COMPREPLY=( $( compgen -W "--json" -- "$cur" ) )
	return 0;
}
_dcos_marathon_pod_remove(){
	case "$cur" in
		-*)
			COMPREPLY=( $( compgen -W "--force" -- "$cur" ) )
			;;
		*)
			cur="${cur##*=}"
			## TODO add pod-id completion
			return 0
			;;
	esac
	return 0;
}
_dcos_marathon_pod_show(){
	return 0; ## TODO add pod-id completion
}
_dcos_marathon_pod_update(){
	case "$cur" in
		-*)
			COMPREPLY=( $( compgen -W "--force" -- "$cur" ) )
			;;
		*)
			cur="${cur##*=}"
			## TODO add pod-id completion
			return 0
			;;
	esac
	return 0;
}
_dcos_marathon_pod(){
    local subcommands="
		add
		kill
		list
		remove
		show
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
## dcos marathon task
##


_dcos_marathon_task_list(){
	COMPREPLY=( $( compgen -W "--json" -- "$cur" ) )
	return 0;
}
_dcos_marathon_task_stop(){
	case "$cur" in
		-*)
			COMPREPLY=( $( compgen -W "--wipe" -- "$cur" ) )
			;;
		*)
			cur="${cur##*=}"
			__dcos_complete_marathon_task_ids
			return 0
			;;
	esac
	return 0;
}
_dcos_marathon_task_show(){
	__dcos_complete_marathon_task_ids
	return 0;
}
_dcos_marathon_task(){
    local subcommands="
		list
		stop
		show
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

_dcos_package_describe(){
	case "$cur" in
		-*)
			# TODO complete options file
			COMPREPLY=( $( compgen -W "--app --cli --config --render --package-versions --options=" -- "$cur" ) )
			;;
		*)
			cur="${cur##*=}"
			__dcos_complete_package_names
			return 0
			;;
	esac
	return 0;
}
_dcos_package_install(){
	case "$cur" in
		-*)
			# TODO complete options file
			# TODO complete app id
			# TODO complete package version
			COMPREPLY=( $( compgen -W "--cli --app --app-id= --package-version= --option= --yes" -- "$cur" ) )
			;;
		*)
			cur="${cur##*=}"
			__dcos_complete_package_names
			return 0
			;;
	esac
	return 0;
}
_dcos_package_list(){
	case "$cur" in
		-*)
			# TODO complete app id
			COMPREPLY=( $( compgen -W "--json --cli --app-id= " -- "$cur" ) )
			;;
		*)
			cur="${cur##*=}"
			__dcos_complete_package_names
			return 0
			;;
	esac
	return 0;
}
_dcos_package_search(){
	case "$cur" in
		-*)
			# TODO complete app id
			COMPREPLY=( $( compgen -W "--json" -- "$cur" ) )
			;;
		*)
			;;
	esac
	return 0;
}
_dcos_package_repo_add(){
	case "$cur" in
		-*)
			# TODO complete app id
			COMPREPLY=( $( compgen -W "--index" -- "$cur" ) )
			;;
		*)
			;;
	esac
	return 0;
}
_dcos_package_repo_remove(){
	__dcos_complete_package_repo_names
	return 0;
}
_dcos_package_repo_list(){
	case "$cur" in
		-*)
			# TODO complete app id
			COMPREPLY=( $( compgen -W "--json" -- "$cur" ) )
			;;
		*)
			;;
	esac
	return 0;
}
_dcos_package_repo(){
    local subcommands="
        add
		remove
		list
    "
   	__dcos_childCommand "$subcommands" && return
	case "$cur" in
		-*)
			;;
		*)
			COMPREPLY=( $( compgen -W "$subcommands" -- "$cur" ) )
			;;
	esac
	return 0;	
}
_dcos_package(){
    local subcommands="
        describe
		install
		list
		search
		repo
		uninstall
		update
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
## dcos service
##

_dcos_service_log(){
	# TODO complete file
	case "$cur" in
		-*)
			COMPREPLY=( $( compgen -W "--follow --lines= --ssh-config-file" -- "$cur" ) )
			;;
		*)
			cur="${cur##*=}"
			__dcos_complete_service_names
			return 0
			;;
	esac
	return 0;
}
_dcos_service_shutdown(){
	__dcos_complete_service_ids
	return 0
}
_dcos_service(){
    local subcommands="
        log
		shutdown
    "

   	__dcos_childCommand "$subcommands" && return

	case "$cur" in
		-*)
			COMPREPLY=( $( compgen -W "--help --info --completed --inactive --json" -- "$cur" ) ) ## TODO split these out as they're not all valid together'
			;;
		*)
			COMPREPLY=( $( compgen -W "$subcommands" -- "$cur" ) )
			;;
	esac
	return 0;	
}


#######################################################################################
##
## dcos task
##

_dcos_task_log(){
	case "$cur" in
		-*)
			COMPREPLY=( $( compgen -W "--completed --follow --lines=" -- "$cur" ) )
			;;
		*)
			cur="${cur##*=}"
			__dcos_complete_task_ids
			return 0
			;;
	esac
	return 0;
}
_dcos_task_ls(){
	case "$cur" in
		-*)
			COMPREPLY=( $( compgen -W "--long --completed" -- "$cur" ) )
			;;
		*)
			cur="${cur##*=}"
			__dcos_complete_task_ids
			return 0
			;;
	esac
	## TODO - handle path completion
	return 0;
}
_dcos_task(){
    local subcommands="
        log
		ls
    "

   	__dcos_childCommand "$subcommands" && return

	case "$cur" in
		-*)
			COMPREPLY=( $( compgen -W "--help --info --completed --json" -- "$cur" ) )
			;;
		*)
			COMPREPLY=( $( compgen -W "$subcommands" -- "$cur" ) )
			;;
	esac
	return 0;
}

_dcos()
{
    local commands="
        auth
        cluster
        config
        help
		job
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
