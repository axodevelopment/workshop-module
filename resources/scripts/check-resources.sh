#!/usr/bin/env bash
# Check each <user>-devspaces namespace for resources declared under ../k8s
# Prints a header per user + ✓/✗ per resource

set -euo pipefail

# ----- colors & counters -----
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
ERRORS=0; OKS=0

print_status() {
  local status="$1" msg="$2"
  case "$status" in
    OK)      echo -e "[${GREEN}✓${NC}] ${msg}"; OKS=$((OKS+1)) ;;
    ERROR)   echo -e "[${RED}✗${NC}] ${msg}"; ERRORS=$((ERRORS+1)) ;;
    INFO)    echo -e "[${BLUE}ℹ${NC}] ${msg}" ;;
  esac
}

# ----- sanity checks -----
if ! command -v oc >/dev/null 2>&1; then
  print_status ERROR "'oc' not found in PATH"
  exit 1
fi
if ! oc whoami >/dev/null 2>&1; then
  print_status ERROR "Not logged in to a cluster (run: oc login ...)"
  exit 1
fi

# ----- locate resources dir -----
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESOURCES_DIR="$(dirname "$SCRIPT_DIR")/k8s"

echo -e "${BLUE}===========================================${NC}"
echo -e "${BLUE}  Check Resources per User Namespace${NC}"
echo -e "${BLUE}===========================================${NC}"

if [[ ! -d "$RESOURCES_DIR" ]]; then
  print_status ERROR "Resources directory not found: ${RESOURCES_DIR}"
  exit 1
fi

# Get devspaces projects (equivalent of: oc get projects | grep -devspaces)
devspaces_projects=$(oc get projects -o name | grep -E 'devspaces$' | cut -d'/' -f2)

if [[ -z "$devspaces_projects" ]]; then
  print_status ERROR "No devspaces projects found"
  exit 1
fi

# Loop over each devspaces project
while IFS= read -r varusrproject; do
  [[ -z "$varusrproject" ]] && continue
  
  # Extract username (remove -devspaces suffix)
  username="${varusrproject%-devspaces}"
  echo ""
  echo -e "${BLUE}User: ${username} | Project: ${varusrproject}${NC}"
  
  # Loop over every file in k8s folder
  for k8s_file in "$RESOURCES_DIR"/*.yaml "$RESOURCES_DIR"/*.yml "$RESOURCES_DIR"/*.json; do
    [[ ! -f "$k8s_file" ]] && continue
    
    # Parse out the kind and metadata.name values
    vark8skind=$(grep -E "^kind:" "$k8s_file" | head -1 | awk '{print $2}' | tr -d '"'"'"'')
    vark8sname=$(grep -E "^\s*name:" "$k8s_file" | head -1 | awk '{print $2}' | tr -d '"'"'"'')
    
    #print_status INFO "kind: $vark8skind, name: $vark8sname"

    # Skip if we couldn't parse kind or name
    if [[ -z "$vark8skind" || -z "$vark8sname" ]]; then
      continue
    fi

    print_status INFO "oc get "$vark8skind" "$vark8sname" -n "$varusrproject""
    
    # Run: oc get $vark8skind $vark8sname -n $varusrproject
    if oc get "$vark8skind" "$vark8sname" -n "$varusrproject" >/dev/null 2>&1; then
      print_status OK "$vark8skind/$vark8sname"
    else
      print_status ERROR "$vark8skind/$vark8sname"
    fi
  done
  
done <<< "$devspaces_projects"

# Final summary
echo ""
echo -e "${BLUE}===========================================${NC}"
echo -e "✓ ${GREEN}${OKS}${NC} resources found"
echo -e "✗ ${RED}${ERRORS}${NC} resources missing"

if [[ $ERRORS -gt 0 ]]; then
  exit 1
else
  exit 0
fi