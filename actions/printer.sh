#!/bin/bash

YELLOW='\033[0;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

#accepts:
#1 text
#2 mode: i - info, e - error, no param - usual
print_message ()
{
    local message="$1"
    local mode="$2"

    if [[ ! -z "$1" ]]; then
        case $mode in
        i)
            echo -e "${GREEN}[INFO] $1${NC}"
        ;;
        e)
            echo -e "${RED}[ERROR] $1${NC}"
        ;;
        w)
            echo -e "${YELLOW}[WARNING] $1${NC}"
        ;;
        *)
            echo -e "[STATUS] $1"
        ;;
        esac
    fi
}
