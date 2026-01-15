#!/usr/bin/env bash
#==============================================================================
# COLORS.SH - Professional logging utilities with colors and icons
#==============================================================================

# Guard against multiple sourcing
[[ -n "${_COLORS_SH_LOADED:-}" ]] && return 0
_COLORS_SH_LOADED=1

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GRAY='\033[0;90m'
BOLD='\033[1m'
RESET='\033[0m'

# Icons (Unicode)
ICON_CHECK="✓"
ICON_CROSS="✗"
ICON_WARN="⚠"
ICON_INFO="→"
ICON_STAR="★"
ICON_ROCKET="🚀"
ICON_LOCK="🔒"
ICON_CLOCK="⏱"

#------------------------------------------------------------------------------
# Logging functions
#------------------------------------------------------------------------------

log_info() {
    echo -e "${CYAN}${ICON_INFO}${RESET} ${GRAY}[INFO]${RESET}  $*"
}

log_success() {
    echo -e "${GREEN}${ICON_CHECK}${RESET} ${GREEN}[OK]${RESET}    $*"
}

log_warn() {
    echo -e "${YELLOW}${ICON_WARN}${RESET} ${YELLOW}[WARN]${RESET}  $*"
}

log_error() {
    echo -e "${RED}${ICON_CROSS}${RESET} ${RED}[ERROR]${RESET} $*" >&2
}

log_step() {
    echo -e "${BLUE}${ICON_INFO}${RESET} ${BOLD}$*${RESET}"
}

log_done() {
    echo -e "${GREEN}${ICON_STAR}${RESET} ${GREEN}${BOLD}[SUCCESS]${RESET} $*"
}

log_dry() {
    echo -e "${MAGENTA}[DRY-RUN]${RESET} Would execute: $*"
}

#------------------------------------------------------------------------------
# Section headers
#------------------------------------------------------------------------------

print_header() {
    local title="$1"
    local width=60
    local padding=$(( (width - ${#title} - 2) / 2 ))
    local line=""
    
    for ((i=0; i<width; i++)); do line+="═"; done
    
    echo ""
    echo -e "${CYAN}╔${line}╗${RESET}"
    printf "${CYAN}║${RESET}%*s ${BOLD}%s${RESET} %*s${CYAN}║${RESET}\n" $padding "" "$title" $((padding - (${#title} % 2))) ""
    echo -e "${CYAN}╚${line}╝${RESET}"
    echo ""
}

print_section() {
    local title="$1"
    local width=50
    local dashes=""
    
    for ((i=0; i<width; i++)); do dashes+="─"; done
    
    echo ""
    echo -e "${GRAY}${dashes}${RESET}"
    echo -e "${BOLD}${title}${RESET}"
    echo -e "${GRAY}${dashes}${RESET}"
}

#------------------------------------------------------------------------------
# Progress indicators
#------------------------------------------------------------------------------

spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    
    while ps -p "$pid" > /dev/null 2>&1; do
        for ((i=0; i<${#spinstr}; i++)); do
            printf "\r${CYAN}%s${RESET} Working..." "${spinstr:$i:1}"
            sleep $delay
        done
    done
    printf "\r"
}

#------------------------------------------------------------------------------
# Confirmation prompt
#------------------------------------------------------------------------------

confirm() {
    local prompt="${1:-Continue?}"
    local default="${2:-n}"
    local response
    
    if [[ "$default" == "y" ]]; then
        prompt="${prompt} [Y/n]: "
    else
        prompt="${prompt} [y/N]: "
    fi
    
    echo -en "${YELLOW}?${RESET} ${prompt}"
    read -r response
    
    response="${response:-$default}"
    [[ "$response" =~ ^[Yy]$ ]]
}

#------------------------------------------------------------------------------
# Status display
#------------------------------------------------------------------------------

print_status() {
    local label="$1"
    local value="$2"
    local color="${3:-$RESET}"
    
    printf "  ${GRAY}%-20s${RESET} ${color}%s${RESET}\n" "${label}:" "$value"
}

print_divider() {
    echo -e "${GRAY}────────────────────────────────────────────────────────────${RESET}"
}
