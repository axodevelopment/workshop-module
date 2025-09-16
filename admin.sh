#!/bin/bash

# Admin Main Script
# Usage: ./admin.sh [command]
# Commands: get-users, check-resources, pvcs

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="${SCRIPT_DIR}/resources/scripts"

# Function to print usage
show_usage() {
    echo -e "${BLUE}===========================================${NC}"
    echo -e "${BLUE}  Admin Script${NC}"
    echo -e "${BLUE}===========================================${NC}"
    echo ""
    echo "Usage: $0 [command]"
    echo ""
    echo "Available commands:"
    echo -e "  ${GREEN}getusers${NC}           - Gets a list of users based upon project naming"
    echo -e "  ${GREEN}checkresources${NC}     - Checks resources per user"
    echo -e "  ${GREEN}pvcs${NC}               - Check/deploy required components"
    echo ""
    echo "Examples:"
    echo "  $0 getusers"
    echo "  $0 checkresources"
    echo "  $0 pvcs"
    echo ""
}

# run a script
run_script() {
    local script_name=$1
    local script_path="${SCRIPTS_DIR}/${script_name}"
    
    if [[ -f "$script_path" ]]; then
        echo -e "${BLUE}Running: ${script_name}${NC}"
        echo ""
        
        # Make script executable if it isn't already
        chmod +x "$script_path"
        
        # Execute the script
        exec "$script_path"
    else
        echo -e "${RED}Error: Script not found: ${script_path}${NC}"
        echo -e "${YELLOW}Expected scripts in: ${SCRIPTS_DIR}${NC}"
        exit 1
    fi
}


case "${1:-}" in
    "getusers")
        run_script "get-users.sh"
        ;;
    "checkresources")
        run_script "check-resources.sh"
        ;;
    "pvcs")
        run_script "pvcs.sh"
        ;;
    "help"|"-h"|"--help")
        show_usage
        ;;
    "")
        echo -e "${RED}Error: No command specified${NC}"
        echo ""
        show_usage
        exit 1
        ;;
    *)
        echo -e "${RED}Error: Unknown command '${1}'${NC}"
        echo ""
        show_usage
        exit 1
        ;;
esac