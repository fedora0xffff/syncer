#!/bin/bash
dir="$(dirname "$0")"
source "${dir}/printer.sh"

#TODO: config file with variables
usage() {
    echo '
    Usage example: sync.sh sync <dir_to_sync> <sync_direction>   synchronizes changes (by def., from local to remote with stash)
    Options:
    
    sync
    1 - sync_direction          sync changed to builder (0, by default), synct changed on builder to the local host (1)
    2 - dir_to_sync             a directory to synchronize, @PROJECT_DIR_[LOCAL | REMOTE]
    
    diff
    1 - dir_diff                a directory to see diff in files for

    !!! Make sure to use these parameters consistently, meaning if sync_direction=1, 
    then dir_to_sync must be a remote dir

    The following environment variables must be set:
    REMOTE_USER             the remote user to connect to via ssh
    CURR_BRANCH             the current branch to work on
    MASTER_BRANCH           the branch to get updates from
    REMOTE_HOST             the remote host to connect to via ssh
    PATH_TO_PASS            path to the pass file for the remote host
    PROJECT_DIR_REMOTE      the remote project dir to sync
    PROJECT_DIR_LOCAL       current local workdir
    EXCLUDE_PATH            path to exclude list

    Also, make sure to set up a password file to load it using sshpass.
    All paths must not have'/' at the end.
    '
}

# synchronize remote directories
# 1 - sync direction: to builder: 0 (default), from builder 1
# 2 - a specific directory to sync inside the project. Default is the @PROJECT_DIR_LOCAL (must have no '/' at the end)
sync_dir() {
    local sync_direction="${1:-0}"

    if [[ $sync_direction -eq 0 ]]; then 
        dir_to_sync="${2:-$PROJECT_DIR_LOCAL}"
        print_message "Syncing: $dir_to_sync, $sync_direction (first)"
        sshpass -f $PATH_TO_PASS rsync --progress -avcr --exclude-from="$EXCLUDE_PATH" "$dir_to_sync/" "$REMOTE_USER@$REMOTE_HOST:$PROJECT_DIR_REMOTE"
    else 
        dir_to_sync="${2:-$PROJECT_DIR_REMOTE}"
        print_message "Syncing: $dir_to_sync, $sync_direction (second)"
        sshpass -f $PATH_TO_PASS rsync --progress -avcr --exclude-from="$EXCLUDE_PATH" "$REMOTE_USER@$REMOTE_HOST:$dir_to_sync/" "$PROJECT_DIR_LOCAL"
    fi
}

# synchronize remote sandbox tmp directory with packages and bins
# 1 - a specific directory to sync inside the project. Default is the @PROJECT_DIR_LOCAL (must have no '/' at the end)
sync_dir_sandbox() {
    print_message "Syncing sandbox: $PROJECT_DIR_LOCAL/$BINARY_TREE"
    sshpass -f $PATH_TO_PASS_SANDBOX rsync --progress -avcr --exclude-from="$EXCLUDE_PATH" "$PROJECT_DIR_LOCAL/$BINARY_TREE/" "$REMOTE_USER_SANDBOX@$REMOTE_SANDBOX:$PROJECT_DIR_LOCAL/$BINARY_TREE"
}

# show diff files comparing either from local to remote, or from remote to local
# 1 - compare direction: to builder: 0 (default), from builder 1
show_diff_files() {
    local dir="${1:-$PROJECT_DIR_LOCAL}"
    local status=""
    echo $dir
    print_message "Files changed:" 
    print_message "$(sshpass -f $PATH_TO_PASS rsync --progress --dry-run -acr --exclude-from="$EXCLUDE_PATH" "$dir/" "$REMOTE_USER@$REMOTE_HOST:$PROJECT_DIR_REMOTE")" i
}

# show diff files on sandbox in the binary tree directory (or which bins have been recently rebuilt)
show_diff_files_sandbox() {
    local index_file="$PROJECT_DIR_LOCAL/$BINARY_TREE/index"
    print_message "Generating the index file $index_file..."
    local dir="$PROJECT_DIR_LOCAL/$BINARY_TREE"
    sshpass -f $PATH_TO_PASS rsync --progress --dry-run -acr --exclude-from="$EXCLUDE_PATH" "$dir/" "$REMOTE_USER@$REMOTE_HOST:$$PROJECT_DIR_LOCAL/$BINARY_TREE" > "$index_file"
}

# sends files to a remote (to ~)
# 1 dest_host - remote host to send to in the form: user@ip
# 2 passw - path to the passw file
# 3 - absolute paths to files to send, separated by the whitespace
send_files_to () {
    local dest_host="$1"
    local passw="$2"
    print_message "Sending files to $dest_host, pass file: $passw..."
    read -a files <<< "$3"
    for file in "${files[@]}"; do
        print_message "Sending: $file" i
        sshpass -f $passw scp "$file" "$dest_host":
    done
}

main() {
    [[ (( "$1" = "help" ) || ( "$1" = "--help" )) ]] && usage && exit 1

    case "$1" in 
    sync)
        echo $1
        if [[( ( ! -z $3 ) && ( ! -d $3) )]]; then
            print_message "Path $3 is not a valid directory" e
            exit 1
        fi
        sync_dir "$2" "$3"
    ;;
    diff)
        if [[( ( ! -z $2 ) && ( ! -d $2) )]]; then
            print_message "Path $2 is not a valid directory" e
            exit 1
        fi
        show_diff_files "$2"
    ;;
    send-files-builder)
        send_files_to "$REMOTE_USER@$REMOTE_HOST" "$PATH_TO_PASS" "$2"
    ;;
    send-files-sandbox)
        send_files_to "$REMOTE_USER_SANDBOX@$REMOTE_SANDBOX" "$PATH_TO_PASS_SANDBOX" "$2"
    ;;
    get-index-and-sync)
        show_diff_files_sandbox
        sync_dir_sandbox
    ;;
    *) 
        print_message "choose a command" e
        usage
    ;;
    esac
}


main $1 $2 $3