#!/bin/bash

PROJECT_DIR_SANDBOX="/home/anast/repo/ztn-linux"
BINARY_TREE="install" 
INDEX="index"

[ ! -d "$PROJECT_DIR_SANDBOX/$BINARY_TREE" ] && mkdir -p "$PROJECT_DIR_SANDBOX/$BINARY_TREE" > /dev/null 2>&1

if [ -e "$PROJECT_DIR_SANDBOX/$BINARY_TREE/$INDEX" ]; then
    input="$PROJECT_DIR_SANDBOX/$BINARY_TREE/$INDEX"
    while read -r line; do
        #later put mv
        echo "$line"
    done <"$input
fi
