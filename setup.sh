#!/usr/bin/env bash
set -euo pipefail
trap 'echo "❌ Error en la línea ${LINENO}. Último comando: [${BASH_COMMAND}]" >&2' ERR

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

MODULES_DIR="${SCRIPT_DIR}/modules"
ALL_MODULES=()

for f in "${MODULES_DIR}"/[0-9]*.sh; do
    [ -f "$f" ] && ALL_MODULES+=("$f")
done
readonly ALL_MODULES

print_help() {
    cat <<EOF
Uso: ./setup.sh [OPCIONES]

Opciones:
  --help          Muestra esta ayuda
  --list          Lista los módulos disponibles
  --only <n>      Ejecuta solo el módulo <n> (ej: --only 03)
  --skip <n>      Salta el módulo <n> (ej: --skip 06)
  --yes           Ejecuta todos los módulos sin confirmar

Ejemplo:
  ./setup.sh                          # Ejecuta todos los módulos
  ./setup.sh --only 03                # Solo herramientas de desarrollo
  ./setup.sh --skip 06                # No configurar terminal
  ./setup.sh --only 03 --only 06      # Solo dev tools + terminal
EOF
}

list_modules() {
    info "Módulos disponibles:"
    for f in "${ALL_MODULES[@]}"; do
        name="$(basename "$f" .sh)"
        desc="$(grep -oP '(?<=# MODULE_DESC: ).*' "$f" 2>/dev/null || echo 'Sin descripción')"
        echo "  ${name}  →  ${desc}"
    done
}

RUN_ONLY=()
SKIP=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --help|-h)
            print_help
            exit 0
            ;;
        --list|-l)
            list_modules
            exit 0
            ;;
        --only)
            shift
            RUN_ONLY+=("$1")
            ;;
        --skip)
            shift
            SKIP+=("$1")
            ;;
        --yes|-y)
            # Non-interactive: no prompts needed (no-op)
            ;;
        *)
            warn "Opción desconocida: $1"
            print_help
            exit 1
            ;;
    esac
    shift
done

# Filtrar módulos a ejecutar
MODULES_TO_RUN=()
for f in "${ALL_MODULES[@]}"; do
    base="$(basename "$f" | cut -d- -f1)"

    # Skip?
    skip_module=false
    for s in "${SKIP[@]}"; do
        if [ "$base" = "$s" ]; then
            skip_module=true
            break
        fi
    done
    $skip_module && continue

    # Only?
    if [ ${#RUN_ONLY[@]} -gt 0 ]; then
        found=false
        for o in "${RUN_ONLY[@]}"; do
            if [ "$base" = "$o" ]; then
                found=true
                break
            fi
        done
        $found || continue
    fi

    MODULES_TO_RUN+=("$f")
done

echo ""
echo "============================================="
echo "  🚀  LINUX CONF — SETUP AUTOMATIZADO"
echo "============================================="
echo ""

if [ ${#MODULES_TO_RUN[@]} -eq 0 ]; then
    warn "No hay módulos para ejecutar."
    exit 0
fi

for f in "${MODULES_TO_RUN[@]}"; do
    echo "═══════════════════════════════════════════"
    info "▶️  Ejecutando: $(basename "$f")"
    echo "═══════════════════════════════════════════"
    echo ""
    bash "$f"
    echo ""
    success "✔  $(basename "$f") finalizado."
    echo ""
done

echo "============================================="
success "🎉 Todos los módulos completados exitosamente."
echo "============================================="
