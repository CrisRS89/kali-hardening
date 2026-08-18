#!/bin/bash
# ============================================================
# whitelist-manager.sh - Gestión de Lista Blanca de Dispositivos
# ENFOQUE PRINCIPAL: Solo dispositivos autorizados
# ============================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

WHITELIST_FILE="/etc/nftables/whitelist.conf"
LOG_DIR="/var/log/whitelist-manager"
WHITELIST_LOG="$LOG_DIR/whitelist-changes.log"

mkdir -p "$LOG_DIR" /etc/nftables

log() { echo -e "${GREEN}[✓]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
err() { echo -e "${RED}[✗]${NC} $1"; }
info() { echo -e "${BLUE}[i]${NC} $1"; }

[[ $EUID -ne 0 ]] && { echo -e "${RED}Ejecutar como root${NC}"; exit 1; }

# ============================================================
# INICIALIZAR LISTA BLANCA BASE
# ============================================================
init_whitelist() {
    echo -e "\n${CYAN}=== INICIALIZANDO LISTA BLANCA ===${NC}"
    
    # Obtener MAC del gateway
    GW_IP=$(ip route | grep default | awk '{print $3}')
    GW_MAC=$(arping -c 1 -I eth0 "$GW_IP" 2>/dev/null | grep -oP 'from \K[0-9a-f:]{17}' | head -1)
    
    # Obtener MAC本地
    LOCAL_MAC=$(ip link show eth0 | grep ether | awk '{print $2}')
    
    # Crear archivo de whitelist
    cat > "$WHITELIST_FILE" << EOF
# ============================================================
# WHITELIST - Dispositivos Autorizados
# Generado: $(date)
# 
# Formato: MAC_IP_DESCRIPCION
# Solo los dispositivos listados pueden acceder a la red
# ============================================================

# Gateway (CRÍTICO - NO ELIMINAR)
$GW_IP $GW_MAC GATEWAY-PRINCIPAL

# Este dispositivo (CRÍTICO)
$(hostname -I | awk '{print $1}') $LOCAL_MAC LOCAL-HOST

# --- AGREGAR DISPOSITIVOS AUTORIZADOS ABAJO ---
# Formato: IP MAC DESCRIPCION
# Ejemplo: 192.168.1.100 aa:bb:cc:dd:ee:ff MI-PC
EOF
    
    log "Lista blanca inicial creada en $WHITELIST_FILE"
    echo "$(date) Whitelist inicializada" >> "$WHITELIST_LOG"
    
    # Aplicar a nftables
    apply_whitelist
}

# ============================================================
# APLICAR LISTA BLANCA A NFTABLES
# ============================================================
apply_whitelist() {
    echo -e "\n${CYAN}=== APLICANDO LISTA BLANCA ===${NC}"
    
    # Limpiar conjunto actual
    nft flush set inet filter whitelist_macs 2>/dev/null || true
    nft flush set inet filter whitelist_ips 2>/dev/null || true
    
    # Leer y aplicar cada entrada
    while IFS=' ' read -r ip mac desc; do
        # Ignorar comentarios y líneas vacías
        [[ "$ip" =~ ^#.*$ || -z "$ip" ]] && continue
        
        # Agregar MAC a whitelist
        nft add element inet filter whitelist_macs { "$mac" }
        nft add element inet filter whitelist_ips { "$ip" }
        
        log "Autorizado: $ip ($mac) - $desc"
        
    done < "$WHITELIST_FILE"
    
    log "Lista blanca aplicada al firewall"
    echo "$(date) Whitelist aplicada" >> "$WHITELIST_LOG"
}

# ============================================================
# AGREGAR DISPOSITIVO A LISTA BLANCA
# ============================================================
add_device() {
    local ip="$1"
    local mac="$2"
    local desc="${3:-Dispositivo autorizado}"
    
    if [ -z "$ip" ] || [ -z "$mac" ]; then
        err "Uso: $0 add <IP> <MAC> [descripción]"
        return 1
    fi
    
    # Validar formato MAC
    if ! echo "$mac" | grep -qE '^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$'; then
        err "Formato de MAC inválido: $mac"
        return 1
    fi
    
    # Verificar si ya existe
    if grep -q "$mac" "$WHITELIST_FILE" 2>/dev/null; then
        warn "MAC $mac ya está en la whitelist"
        return 1
    fi
    
    # Agregar al archivo
    echo "$ip $mac $desc" >> "$WHITELIST_FILE"
    
    # Agregar a nftables en vivo
    nft add element inet filter whitelist_macs { "$mac" }
    nft add element inet filter whitelist_ips { "$ip" }
    
    log "Dispositivo agregado: $ip ($mac) - $desc"
    echo "$(date) AGREGADO: $ip $mac $desc" >> "$WHITELIST_LOG"
}

# ============================================================
# REMOVER DISPOSITIVO DE LISTA BLANCA
# ============================================================
remove_device() {
    local identifier="$1"  # Puede ser IP o MAC
    
    if [ -z "$identifier" ]; then
        err "Uso: $0 remove <IP_O_MAC>"
        return 1
    fi
    
    # Buscar en el archivo
    if grep -q "$identifier" "$WHITELIST_FILE"; then
        # Obtener MAC para remover de nftables
        local mac=$(grep "$identifier" "$WHITELIST_FILE" | awk '{print $2}')
        local ip=$(grep "$identifier" "$WHITELIST_FILE" | awk '{print $1}')
        
        # Remover del archivo (manteniendo comentarios)
        sed -i "/$identifier/d" "$WHITELIST_FILE"
        
        # Remover de nftables
        nft delete element inet filter whitelist_macs { "$mac" } 2>/dev/null || true
        nft delete element inet filter whitelist_ips { "$ip" } 2>/dev/null || true
        
        log "Dispositivo removido: $identifier"
        echo "$(date) REMOVIDO: $identifier" >> "$WHITELIST_LOG"
    else
        err "Dispositivo no encontrado: $identifier"
        return 1
    fi
}

# ============================================================
# LISTAR DISPOSITIVOS EN LISTA BLANCA
# ============================================================
list_whitelist() {
    echo -e "\n${CYAN}=== LISTA BLANCA DE DISPOSITIVOS ===${NC}"
    echo ""
    printf "%-18s %-18s %s\n" "IP" "MAC" "DESCRIPCIÓN"
    echo "------------------------------------------------------------"
    
    while IFS=' ' read -r ip mac desc; do
        [[ "$ip" =~ ^#.*$ || -z "$ip" ]] && continue
        printf "%-18s %-18s %s\n" "$ip" "$mac" "$desc"
    done < "$WHITELIST_FILE"
    
    echo ""
    info "Total dispositivos autorizados: $(grep -v '^#' "$WHITELIST_FILE" | grep -v '^$' | wc -l)"
}

# ============================================================
# ESCANEO Y AUTO-DESCUBRIMIENTO
# ============================================================
auto_discover() {
    echo -e "\n${CYAN}=== AUTO-DESCUBRIMIENTO DE DISPOSITIVOS ===${NC}"
    echo "Esto escaneará la red y te preguntará qué dispositivos agregar"
    echo ""
    
    # Obtener subnet
    SUBNET=$(ip addr show eth0 | grep -oP 'inet \K[0-9./]+' | head -1)
    NETWORK_BASE=$(echo "$SUBNET" | cut -d'.' -f1-3)
    
    info "Escaneando red: $SUBNET"
    
    # Escaneo rápido
    for i in $(seq 1 254); do
        IP="${NETWORK_BASE}.${i}"
        if arping -c 1 -W 1 -I eth0 "$IP" >/dev/null 2>&1; then
            MAC=$(ip neigh show "$IP" 2>/dev/null | awk '{print $5}' | head -1)
            
            if [ -n "$MAC" ] && [ "$MAC" != "FAILED" ]; then
                # Verificar si ya está en whitelist
                if grep -q "$MAC" "$WHITELIST_FILE" 2>/dev/null; then
                    echo -e "${GREEN}✓${NC} $IP ($MAC) - YA AUTORIZADO"
                else
                    echo -e "${YELLOW}?${NC} $IP ($MAC) - NO AUTORIZADO"
                    read -p "¿Agregar este dispositivo? (s/n): " -n 1 -r
                    echo
                    if [[ $REPLY =~ ^[Ss]$ ]]; then
                        read -p "Descripción: " desc
                        add_device "$IP" "$MAC" "${desc:-Descubierto}"
                    fi
                fi
            fi
        fi
    done
    
    log "Auto-descubrimiento completado"
}

# ============================================================
# MONITOREO DE VIOLACIONES DE LISTA BLANCA
# ============================================================
monitor_violations() {
    echo -e "\n${CYAN}=== MONITOREO DE VIOLACIONES ===${NC}"
    echo "Presiona Ctrl+C para detener"
    
    while true; do
        # Buscar en logs de nftables violaciones
        violations=$(journalctl -u nftables --no-pager -n 50 2>/dev/null | grep "UNKNOWN-MAC\|BLOCKED-MAC" || true)
        
        if [ -n "$violations" ]; then
            warn "¡VIOLACIONES DETECTADAS!"
            echo "$violations"
            
            # Extraer MACs no autorizadas
            unauthorized_macs=$(echo "$violations" | grep -oP 'src=([0-9a-f:]{17})' | cut -d'=' -f2 | sort -u)
            
            for mac in $unauthorized_macs; do
                if [ -n "$mac" ]; then
                    # Buscar IP asociada
                    ip=$(ip neigh show | grep "$mac" | awk '{print $1}' | head -1)
                    
                    echo -e "${RED}MAC NO AUTORIZADA: $mac${NC}"
                    echo -e "${RED}IP Asociada: $ip${NC}"
                    
                    # Registrar incidente
                    echo "$(date) VIOLACION: MAC=$mac IP=$ip" >> "$LOG_DIR/violations.log"
                fi
            done
        fi
        
        sleep 10
    done
}

# ============================================================
# GENERAR REGLAS SURICATA PARA WHITELIST
# ============================================================
generate_suricata_rules() {
    echo -e "\n${CYAN}=== GENERANDO REGLAS SURICATA PARA WHITELIST ===${NC}"
    
    RULES_FILE="/etc/suricata/rules/whitelist.rules"
    
    cat > "$RULES_FILE" << 'EOF'
# ============================================================
# Reglas Suricata - Lista Blanca
# Generado automáticamente - No editar manualmente
# ============================================================

# Alerta para dispositivos no autorizados
alert tcp any any -> $HOME_NET any (msg:"UNAUTHORIZED DEVICE - TCP Connection"; sid:1000001; rev:1;)
alert udp any any -> $HOME_NET any (msg:"UNAUTHORIZED DEVICE - UDP Connection"; sid:1000002; rev:1;)

# Detección de MAC spoofing (cambios frecuentes)
alert arp any any -> any any (msg:"POSSIBLE MAC SPOOFING - ARP"; sid:1000003; rev:1;)

# Detección de DHCP rogue
alert udp any 67 -> any 68 (msg:"ROGUE DHCP SERVER DETECTED"; sid:1000004; rev:1;)

# Fingerprinting - JA3
alert tls any any -> any any (msg:"TLS FINGERPRINT CAPTURED"; ja3.hash; sid:1000005; rev:1;)

# Detección de escaneo de puertos
alert tcp any any -> $HOME_NET any (msg:"PORT SCAN DETECTED"; flags:S; threshold:type both, track by_src, count 20, seconds 60; sid:1000006; rev:1;)
EOF
    
    log "Reglas Suricata generadas en $RULES_FILE"
}

# ============================================================
# MOSTRAR AYUDA
# ============================================================
show_help() {
    echo -e "${CYAN}"
    echo "╔═══════════════════════════════════════════════════════╗"
    echo "║     WHITELIST MANAGER - Gestión de Lista Blanca      ║"
    echo "╠═══════════════════════════════════════════════════════╣"
    echo "║  Solo dispositivos autorizados pueden acceder         ║"
    echo "╚═══════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    echo "Uso: $0 [comando] [opciones]"
    echo ""
    echo "Comandos:"
    echo "  init              - Inicializar whitelist con gateway y host local"
    echo "  add <IP> <MAC> [desc] - Agregar dispositivo"
    echo "  remove <IP|MAC>   - Remover dispositivo"
    echo "  list              - Listar dispositivos autorizados"
    echo "  apply             - Aplicar whitelist al firewall"
    echo "  discover          - Auto-descubrir dispositivos en red"
    echo "  monitor           - Monitorear violaciones"
    echo "  generate-rules    - Generar reglas Suricata"
    echo "  status            - Ver estado actual"
}

# ============================================================
# VER ESTADO
# ============================================================
show_status() {
    echo -e "\n${CYAN}=== ESTADO DE LISTA BLANCA ===${NC}"
    
    echo -e "\n${YELLOW}Dispositivos en whitelist:${NC}"
    grep -v '^#' "$WHITELIST_FILE" | grep -v '^$' | wc -l
    
    echo -e "\n${YELLOW}MACs en nftables:${NC}"
    nft list set inet filter whitelist_macs 2>/dev/null | grep -c "ether_addr" || echo "0"
    
    echo -e "\n${YELLOW}IPs en nftables:${NC}"
    nft list set inet filter whitelist_ips 2>/dev/null | grep -c "ipv4_addr" || echo "0"
    
    echo -e "\n${YELLOW}MACs bloqueadas:${NC}"
    nft list set inet filter blocked_macs 2>/dev/null | grep -c "ether_addr" || echo "0"
    
    echo -e "\n${YELLOW}Últimas violaciones:${NC}"
    tail -5 "$LOG_DIR/violations.log" 2>/dev/null || echo "Sin violaciones registradas"
}

# ============================================================
# MAIN
# ============================================================
case "${1:-help}" in
    init)
        init_whitelist
        ;;
    add)
        add_device "$2" "$3" "${4:-Dispositivo autorizado}"
        ;;
    remove)
        remove_device "$2"
        ;;
    list)
        list_whitelist
        ;;
    apply)
        apply_whitelist
        ;;
    discover)
        auto_discover
        ;;
    monitor)
        monitor_violations
        ;;
    generate-rules)
        generate_suricata_rules
        ;;
    status)
        show_status
        ;;
    help|*)
        show_help
        ;;
esac
