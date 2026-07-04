#!/usr/bin/env bash

if [ -n "${COMMON_LOADED:-}" ]; then
    return 0
fi
COMMON_LOADED=true

BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RESET='\033[0m'

info()    { echo -e "${CYAN}${BOLD}ℹ️  $*${RESET}"; }
success() { echo -e "${GREEN}${BOLD}✅ $*${RESET}"; }
warn()    { echo -e "${YELLOW}${BOLD}⚠️  $*${RESET}"; }

append_zshrc_block() {
    local marker="$1"
    local block="$2"
    if ! grep -qF "${marker}" "${HOME}/.zshrc" 2>/dev/null; then
        printf '\n%s\n' "${block}" >> "${HOME}/.zshrc"
        success "Bloque '${marker}' añadido a ~/.zshrc"
    else
        warn "Bloque '${marker}' ya presente en ~/.zshrc, omitiendo."
    fi
}
