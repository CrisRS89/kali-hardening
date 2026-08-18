#!/bin/bash
# ============================================================
# mac-flapping-detect.sh - Detección de MAC Flapping en Switch
# Detecta cuando un dispositivo cambia frecuentemente de puerto
# ============================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

LOG_DIR="/var/log/mac-flapping"
FLAPPING_LOG="$LOG_DIR/flapping-events.log"
MAC_HISTORY="$LOG_DIR/mac-history.log"

mkdir -p "$LOG_DIR"

log() { echo -e "${GREEN}[✓]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
alert() { echo -e "${RED}[!!!]${NC} $1"; }
info() { echo -e "${BLUE}[i]${NC} $1"; }

[[ $EUID -ne 0 ]] && { echo -e "${RED}Ejecutar como root${NC}"; exit 1; }

# ============================================================
# 1. DETECCIÓN BÁSICA DE MAC FLAPPING
# ============================================================
detect_basic_flapping() {
    echo -e "\n${CYAN}=== DETECCIÓN BÁSICA DE MAC FLAPPING ===${NC}"
    info="Monitoreando cambios de MAC en tabla ARP..."
    echo ""
    
    # Capturar estado inicial
    local initial_state=$(ip neigh show | awk '{print $5, $1}' | sort)
    
    echo "Estado inicial de ARP:"
    echo "$initial_state" | head -20
    echo "..."
    
    # Monitorear cambios durante 60 segundos
    info "Monitoreando cambios (60 segundos)..."
    
    local changes=0
    local start_time=$(date +%s)
    
    while true; do
        local current_state=$(ip neigh show | awk '{print $5, $1}' | sort)
        
        if [ "$current_state" != "$initial_state" ]; then
            changes=$((changes + 1))
            
            # Detectar qué MAC cambió
            local changed_macs=$(diff <(echo "$initial_state") <(echo "$current_state") | \
                grep -E "^[<>]" | awk '{print $2}' | sort -u)
            
            for mac in $changed_macs; do
                if [ -n "$mac" ] && [ "$mac" != "FAILED" ]; then
                    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
                    local associated_ips=$(ip neigh show | grep "$mac" | awk '{print $1}' | tr '\n' ' ')
                    
                    alert "CAMBIO DETECTADO - MAC: $mac"
                    echo "  IPs asociadas: $associated_ips"
                    echo "  Veces que ha cambiado: $changes"
                    
                    # Registrar evento
                    echo "$timestamp MAC=$mac CHANGES=$changes IPS=$associated_ips" >> "$FLAPPING_LOG"
                    
                    # Verificar si es flapping (más de 3 cambios en 60 segundos)
                    if [ $changes -gt 3 ]; then
                        alert "¡MAC FLAPPING CONFIRMADO!"
                        echo "  MAC $mac ha cambiado $changes veces en 60 segundos"
                        echo "  Posible MAC spoofing o dispositivo malicioso"
                        
                        # Bloquear MAC sospechosa
                        nft add element inet filter blocked_macs { "$mac" } 2>/dev/null || true
                        echo "  MAC bloqueada temporalmente"
                    fi
                fi
            done
            
            initial_state="$current_state"
        fi
        
        # Verificar tiempo transcurrido
        local current_time=$(date +%s)
        local elapsed=$((current_time - start_time))
        
        if [ $elapsed -ge 60 ]; then
            break
        fi
        
        sleep 2
    done
    
    echo ""
    info "Monitoreo completado. Cambios totales detectados: $changes"
}

# ============================================================
# 2. ANÁLISIS DE TABLA MAC DEL SWITCH (via LLDP/CDP)
# ============================================================
analyze_switch_tables() {
    echo -e "\n${CYAN}=== ANÁLISIS DE TABLA MAC DEL SWITCH ===${NC}"
    info="Intentando obtener información del switch..."
    echo ""
    
    # Método 1: LLDP (Link Layer Discovery Protocol)
    info "Buscando vecinos LLDP..."
    if command -v lldpctl &> /dev/null; then
        lldpctl show 2>/dev/null || warn "No se detectaron vecinos LLDP"
    else
        warn "lldpctl no disponible"
    fi
    
    # Método 2: CDP (Cisco Discovery Protocol)
    info "Buscando vecinos CDP..."
    if command -v cdp &> /dev/null; then
        cdp show 2>/dev/null || warn "No se detectaron vecinos CDP"
    fi
    
    # Método 3: SNMP query al switch (si está configurado)
    info "Intentando SNMP query..."
    if command -v snmpwalk &> /dev/null; then
        # Configurar según tu switch
        SNMP_COMMUNITY="${SNMP_COMMUNITY:-public}"
        SWITCH_IP="${SWITCH_IP:-}"
        
        if [ -n "$SWITCH_IP" ]; then
            info "Consultando MAC address table del switch $SWITCH_IP..."
            snmpwalk -v2c -c "$SNMP_COMMUNITY" "$SWITCH_IP" 1.3.6.1.2.1.17.4.3.1 2>/dev/null || \
                warn "No se pudo acceder al switch via SNMP"
        else
            warn "SWITCH_IP no configurado"
            info "Configurar con: export SWITCH_IP=<ip_del_switch>"
        fi
    else
        warn "snmpwalk no disponible"
        info "Instalar con: apt install snmp"
    fi
    
    # Método 4: SSH al switch (si tienes acceso)
    info "Si tienes acceso SSH al switch, ejecutar:"
    echo "  show mac address-table"
    echo "  show cdp neighbors"
    echo "  show lldp neighbors"
}

# ============================================================
# 3. MONITOREO CONTINUO CON ALERTAS
# ============================================================
continuous_monitoring() {
    echo -e "\n${CYAN}=== MONITOREO CONTINUO DE MAC FLAPPING ===${NC}"
    info="Presiona Ctrl+C para detener"
    echo ""
    
    # Archivo para tracking de cambios por MAC
    local mac_changes=$(mktemp)
    
    # Inicializar contador
    declare -A change_count
    
    while true; do
        local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
        
        # Obtener tabla ARP actual
        local current_arp=$(ip neigh show | awk '{print $1, $5}' | sort)
        
        # Comparar con anterior
        if [ -f "$MAC_HISTORY.last" ]; then
            local previous_arp=$(cat "$MAC_HISTORY.last")
            
            if [ "$current_arp" != "$previous_arp" ]; then
                # Analizar cambios
                local changed_entries=$(diff <(echo "$previous_arp") <(echo "$current_arp") | \
                    grep -E "^[<>]" | awk '{print $2, $3}')
                
                while IFS=' ' read -r ip mac; do
                    if [ -n "$mac" ] && [ "$mac" != "FAILED" ]; then
                        # Incrementar contador para esta MAC
                        change_count[$mac]=$(( ${change_count[$mac]:-0} + 1 ))
                        
                        local count=${change_count[$mac]}
                        
                        # Alertar según severidad
                        if [ $count -ge 5 ]; then
                            alert "CRÍTICO - MAC FLAPPING SEVERO"
                            echo "  MAC: $mac"
                            echo "  Cambios totales: $count"
                            echo "  Último cambio: $ip"
                            echo "$timestamp CRITICAL MAC=$mac CHANGES=$count IP=$ip" >> "$FLAPPING_LOG"
                            
                            # Bloquear inmediatamente
                            nft add element inet filter blocked_macs { "$mac" } 2>/dev/null || true
                            echo "  ¡MAC BLOQUEADA!"
                            
                        elif [ $count -ge 3 ]; then
                            alert "ALTO - Posible MAC spoofing"
                            echo "  MAC: $mac - Cambios: $count"
                            echo "$timestamp HIGH MAC=$mac CHANGES=$count IP=$ip" >> "$FLAPPING_LOG"
                            
                        elif [ $count -ge 2 ]; then
                            warn "MEDIO - Comportamiento inusual"
                            echo "  MAC: $mac - Cambios: $count"
                            echo "$timestamp MEDIUM MAC=$mac CHANGES=$count IP=$ip" >> "$FLAPPING_LOG"
                        fi
                    fi
                done <<< "$changed_entries"
            fi
        fi
        
        # Guardar estado actual
        echo "$current_arp" > "$MAC_HISTORY.last"
        
        sleep 5
    done
    
    rm -f "$mac_changes"
}

# ============================================================
# 4. HISTORIAL DE CAMBIOS POR MAC
# ============================================================
show_mac_history() {
    echo -e "\n${CYAN}=== HISTORIAL DE CAMBIOS POR MAC ===${NC}"
    
    if [ -f "$FLAPPING_LOG" ]; then
        echo -e "\n${YELLOW}Últimos eventos de flapping:${NC}"
        tail -20 "$FLAPPING_LOG"
        
        echo -e "\n${YELLOW}MACs con más cambios:${NC}"
        awk '{print $2}' "$FLAPPING_LOG" | sort | uniq -c | sort -rn | head -10
    else
        info "No hay historial de flapping registrado"
    fi
}

# ============================================================
# 5. GENERAR REGLAS DE BLOQUEO AUTOMÁTICO
# ============================================================
generate_auto_block_rules() {
    echo -e "\n${CYAN}=== GENERANDO REGLAS DE BLOQUEO AUTOMÁTICO ===${NC}"
    
    local rules_file="/etc/nftables/mac-flapping-rules.nft"
    
    cat > "$rules_file" << 'EOF'
# ============================================================
# Reglas de bloqueo automático por MAC flapping
# Generado por mac-flapping-detect.sh
# ============================================================

table inet filter {
    set auto_blocked_flapping { type ether_addr \; flags dynamic,timeout 3600 \; }
    
    chain input {
        # Bloquear MACs con flapping severo
        ether saddr @auto_blocked_flapping log prefix "[NFT-FLAPPING-BLOCK] " drop
    }
}
EOF
    
    log "Reglas de bloqueo automático generadas en $rules_file"
    info "Cargar con: nft -f $rules_file"
}

# ============================================================
# 6. REPORTE COMPLETO
# ============================================================
generate_report() {
    echo -e "\n${CYAN}=== REPORTE DE MAC FLAPPING ===${NC}"
    
    local report_file="$LOG_DIR/report-$(date '+%Y%m%d-%H%M%S').txt"
    
    {
        echo "=========================================="
        echo "REPORTE DE MAC FLAPPING"
        echo "Fecha: $(date)"
        echo "=========================================="
        
        echo -e "\n--- EVENTOS DE FLAPPING ---"
        cat "$FLAPPING_LOG" 2>/dev/null || echo "Sin eventos"
        
        echo -e "\n--- ESTADO ACTUAL ARP ---"
        ip neigh show
        
        echo -e "\n--- MACS BLOQUEADAS ---"
        nft list set inet filter blocked_macs 2>/dev/null || echo "No disponible"
        
        echo -e "\n--- ESTADÍSTICAS ---"
        if [ -f "$FLAPPING_LOG" ]; then
            echo "Total eventos: $(wc -l < "$FLAPPING_LOG")"
            echo "MACs únicas afectadas: $(awk '{print $2}' "$FLAPPING_LOG" | cut -d= -f2 | sort -u | wc -l)"
        fi
        
    } > "$report_file"
    
    log "Reporte generado: $report_file"
    cat "$report_file"
}

# ============================================================
# MAIN
# ============================================================
echo -e "${CYAN}"
echo "╔═══════════════════════════════════════════════════════╗"
echo "║   MAC FLAPPING DETECTOR - Detección de Spoofing      ║"
echo "╚═══════════════════════════════════════════════════════╝"
echo -e "${NC}"

case "${1:-help}" in
    detect)
        detect_basic_flapping
        ;;
    switch)
        analyze_switch_tables
        ;;
    monitor)
        continuous_monitoring
        ;;
    history)
        show_mac_history
        ;;
    rules)
        generate_auto_block_rules
        ;;
    report)
        generate_report
        ;;
    help|*)
        echo "Uso: $0 [comando]"
        echo ""
        echo "Comandos:"
        echo "  detect    - Detección básica de MAC flapping"
        echo "  switch    - Analizar tablas MAC del switch"
        echo "  monitor   - Monitoreo continuo con alertas"
        echo "  history   - Ver historial de cambios"
        echo "  rules     - Generar reglas de bloqueo automático"
        echo "  report    - Generar reporte completo"
        ;;
esac
