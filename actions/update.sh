#!/bin/bash

usage() {
    echo '
    Usage: update.sh <command>  updates the repository in @PROJECT_DIR_REMOTE
    Options:
    upd-curr                    download updates from the @CURRENT_BRANCH having saved changes
    upd-curr-no-stash           download updates from the @CURRENT_BRANCH without saving
    merge-master                download updates from the @MASTER_BRANCH having saved changes
    merge-master-no-stash       download updates from the @MASTER_BRANCH without saving
    chechout-master             checkout to @MASTER_BRANCH
    checkout-current            checkout to @CURRENT_BRANCH

    This script requires env vars. See sync.sh help for more info.
    '
}

# update the local repository
update_local_repo() {
    git --work-tree=$PROJECT_DIR_LOCAL --git-dir=$PROJECT_DIR_LOCAL/.git stash
    git --work-tree=$PROJECT_DIR_LOCAL --git-dir=$PROJECT_DIR_LOCAL/.git pull -r
    git --work-tree=$PROJECT_DIR_LOCAL --git-dir=$PROJECT_DIR_LOCAL/.git stash pop

    retval=$?
    if [[ retval -ne 0 ]]; then
        print_message "git exits woth non-zero result, check for the conflicts" e
        exit 1
    fi
}

#
# run a command on the remote @REMOTE_HOST as @REMOTE_USER
run_remote() {
    local command=$1
    echo Remote command is: $command
    [[ (( ! -f /usr/bin/sshpass) || ( -z $PATH_TO_PASS )) ]] && print_message "sshpass is missing or PATH_TO_PASS is not set" e && exit 1
    sshpass -f $PATH_TO_PASS ssh -t $REMOTE_USER@$REMOTE_HOST "${command}"
}

# update the remote repo from the current branch with stash or without
# 1 - with_stash: 0 - don't save current changes, 1 - save current changes (default)
update_remote_from_current() {
    local with_stash="${1:-1}"

    local git_pull="git --work-tree=$PROJECT_DIR_REMOTE --git-dir=$PROJECT_DIR_REMOTE/.git pull -r"
    local git_stash="git --work-tree=$PROJECT_DIR_REMOTE --git-dir=$PROJECT_DIR_REMOTE/.git stash"
    local git_stash_pop="git --work-tree=$PROJECT_DIR_REMOTE --git-dir=$PROJECT_DIR_REMOTE/.git stash pop"

    if [[ $with_stash -eq 1 ]]; then
        run_remote "$git_stash && $git_pull && $git_stash_pop"
    else
        run_remote "$git_stash && $git_pull"
    fi 
}

# checkout to @CURR_BRANCH
# master: 0 - current branch @CURR_BRANCH, 1 - master branch @MASTER_BRANCH (default)
checkout_remote() {
    local master="${1:-1}"

    local git_stash="git --work-tree=$PROJECT_DIR_REMOTE --git-dir=$PROJECT_DIR_REMOTE/.git stash"
    local git_checkout="git --work-tree=$PROJECT_DIR_REMOTE --git-dir=$PROJECT_DIR_REMOTE/.git checkout $CURR_BRANCH"
    local git_checkout_master="git --work-tree=$PROJECT_DIR_REMOTE --git-dir=$PROJECT_DIR_REMOTE/.git checkout $MASTER_BRANCH"
    local git_pull="git --work-tree=$PROJECT_DIR_REMOTE --git-dir=$PROJECT_DIR_REMOTE/.git pull -r"

    if [[ $master -eq 1 ]]; then 
        run_remote "$git_stash && $git_checkout_master && $git_pull"
    else
        run_remote "$git_stash && $git_checkout && $git_pull"
    fi
}

# update the remote repo from the master branch with stash or without
# 1 - with_stash: 0 - don't save current changes, 1 - save current changes (default)
update_remote_from_master() {
    local with_stash="${1:-1}"

    local git_pull="git --work-tree=$PROJECT_DIR_REMOTE --git-dir=$PROJECT_DIR_REMOTE/.git pull -r"
    local git_checkout_master="git --work-tree=$PROJECT_DIR_REMOTE --git-dir=$PROJECT_DIR_REMOTE/.git checkout $MASTER_BRANCH"
    local git_checkout_current="git --work-tree=$PROJECT_DIR_REMOTE --git-dir=$PROJECT_DIR_REMOTE/.git checkout $CURR_BRANCH"
    local git_merge_master="git --work-tree=$PROJECT_DIR_REMOTE --git-dir=$PROJECT_DIR_REMOTE/.git merge $MASTER_BRANCH"
    local git_stash="git --work-tree=$PROJECT_DIR_REMOTE --git-dir=$PROJECT_DIR_REMOTE/.git stash"
    local git_stash_pop="git --work-tree=$PROJECT_DIR_REMOTE --git-dir=$PROJECT_DIR_REMOTE/.git stash pop"

    if [[ $with_stash -eq 1 ]]; then
        run_remote "$git_stash && $git_checkout_master && $git_pull && $git_checkout_current && $git_checkout_master && $git_stash_pop"
    else
        run_remote "$git_stash && $git_checkout_master && $git_pull && $git_checkout_current && $git_checkout_master"
    fi 
}

case "$1" in
upd-curr)
    update_remote_from_current
    ;;
upd-curr-no-stash)
    update_remote_from_current 0
    ;;
merge-master)
    update_remote_from_master
    ;;
merge-master-no-stash)
    update_remote_from_master 0
    ;;
chechout-master)
    checkout_remote
    ;;
checkout-current)
    checkout_remote 0
    ;;
*)
    usage
    ;;
esac