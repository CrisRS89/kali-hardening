#!/bin/bash
# ============================================================
# network-defender.sh - Defensa de red contra MAC/IP spoofing
# Uso: sudo network-defender.sh [opciones]
# ============================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log() { echo -e "${GREEN}[✓]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
err() { echo -e "${RED}[✗]${NC} $1"; }
info() { echo -e "${BLUE}[i]${NC} $1"; }

[[ $EUID -ne 0 ]] && { echo -e "${RED}Ejecutar como root${NC}"; exit 1; }

# Configuracion
IFACE="eth0"
LOG_DIR="/var/log/network-defense"
BLOCKED_FILE="$LOG_DIR/blocked-macs.txt"
KNOWN_DEVICES_FILE="$LOG_DIR/known-devices.txt"
ARP_LOG="$LOG_DIR/arp-changes.log"

mkdir -p "$LOG_DIR"
touch "$BLOCKED_FILE" "$KNOWN_DEVICES_FILE" "$ARP_LOG"

show_banner() {
    echo -e "${CYAN}"
    echo "╔═══════════════════════════════════════════════════════╗"
    echo "║       NETWORK DEFENDER - Anti Spoofing System        ║"
    echo "╠═══════════════════════════════════════════════════════╣"
    echo "║  Proteccion contra MAC spoofing, ARP spoofing,       ║"
    echo "║  DHCP starvation y denegacion de acceso              ║"
    echo "╚═══════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# ============================================================
# 1. MONITOREO DE TABLA ARP
# ============================================================
monitor_arp() {
    echo -e "\n${YELLOW}=== MONITOREO ARP ===${NC}"
    
    info "Tabla ARP actual:"
    ip neigh show
    
    echo -e "\n${YELLOW}=== DETECCION DE CAMBIOS ARP ===${NC}"
    
    # Capturar ARP actual
    local current_arp=$(ip neigh show | awk '{print $1, $5}' | sort)
    
    # Comparar con el guardado
    if [ -f "$LOG_DIR/last-arp-state.txt" ]; then
        local last_arp=$(cat "$LOG_DIR/last-arp-state.txt")
        
        if [ "$current_arp" != "$last_arp" ]; then
            warn "¡CAMBIO DETECTADO EN TABLA ARP!"
            echo "--- Cambios ---"
            diff <(echo "$last_arp") <(echo "$current_arp") || true
            echo "---"
            
            # Registrar cambio
            echo "$(date '+%Y-%m-%d %H:%M:%S') CAMBIO ARP detectado" >> "$ARP_LOG"
            echo "$current_arp" >> "$ARP_LOG"
        else
            log "Tabla ARP estable"
        fi
    fi
    
    # Guardar estado actual
    echo "$current_arp" > "$LOG_DIR/last-arp-state.txt"
}

# ============================================================
# 2. DETECCION DE MAC SPOOFING
# ============================================================
detect_mac_spoofing() {
    echo -e "\n${YELLOW}=== DETECCION MAC SPOOFING ===${NC}"
    
    info "Escaneando red para detectar dispositivos..."
    
    # Obtener gateway
    local gw_ip=$(ip route | grep default | awk '{print $3}')
    local gw_mac=$(arping -c 1 -I "$IFACE" "$gw_ip" 2>/dev/null | grep -oP 'from \K[0-9a-f:]{17}')
    
    echo "Gateway: $gw_ip ($gw_mac)"
    
    # Verificar si el MAC del gateway es legitimo
    local current_gw_mac=$(ip neigh show "$gw_ip" | awk '{print $5}')
    
    if [ "$current_gw_mac" != "$gw_mac" ] && [ -n "$gw_mac" ]; then
        err "¡POSIBLE ARP SPOOFING CONTRA GATEWAY!"
        echo "MAC esperada: $gw_mac"
        echo "MAC actual: $current_gw_mac"
        
        # Bloquear MAC falsa
        nft add element inet filter blocked_macs { "$current_gw_mac" }
        echo "$current_gw_mac" >> "$BLOCKED_FILE"
        
        warn "MAC $current_gw_mac bloqueada temporalmente"
    else
        log "Gateway MAC verificado"
    fi
    
    # Buscar MACs duplicadas
    echo -e "\n${YELLOW}=== VERIFICANDO MACS DUPLICADAS ===${NC}"
    
    local mac_count=$(ip neigh show | awk '{print $5}' | grep -v "FAILED" | sort | uniq -c | sort -rn)
    
    if echo "$mac_count" | grep -q "^[[:space:]]*[2-9]"; then
        warn "¡MACs DUPLICADAS DETECTADAS!"
        echo "$mac_count"
        
        # Obtener MACs con mas de una IP
        local duplicate_macs=$(echo "$mac_count" | awk '$1 > 1 {print $2}')
        
        for mac in $duplicate_macs; do
            if [ -n "$mac" ]; then
                local associated_ips=$(ip neigh show | grep "$mac" | awk '{print $1}')
                warn "MAC $mac asociada a multiples IPs:"
                echo "$associated_ips"
                
                # Registrar como sospechosa
                echo "$(date '+%Y-%m-%d %H:%M:%S') MAC sospechosa: $mac - IPs: $associated_ips" >> "$LOG_DIR/suspicious-macs.log"
            fi
        done
    else
        log "No se detectaron MACs duplicadas"
    fi
    
    # Escaneo completo de la red
    echo -e "\n${YELLOW}=== ESCANEO DE RED ===${NC}"
    
    local subnet=$(ip addr show "$IFACE" | grep -oP 'inet \K[0-9./]+' | head -1)
    
    if [ -n "$subnet" ]; then
        info "Escaneando subnet: $subnet"
        
        # Usar arping para detectar dispositivos
        local network_base=$(echo "$subnet" | cut -d'.' -f1-3)
        
        for i in $(seq 1 254); do
            local ip="${network_base}.${i}"
            if arping -c 1 -W 1 -I "$IFACE" "$ip" >/dev/null 2>&1; then
                local mac=$(ip neigh show "$ip" 2>/dev/null | awk '{print $5}')
                if [ -n "$mac" ] && [ "$mac" != "FAILED" ]; then
                    # Verificar si esta en la lista de bloqueados
                    if grep -q "$mac" "$BLOCKED_FILE" 2>/dev/null; then
                        warn "Dispositivo bloqueado encontrado: $ip ($mac)"
                    fi
                fi
            fi
        done
        
        log "Escaneo completado"
    fi
}

# ============================================================
# 3. DETECCION DE ROGUE DHCP
# ============================================================
detect_rogue_dhcp() {
    echo -e "\n${YELLOW}=== DETECCION ROGUE DHCP ===${NC}"
    
    info "Buscando servidores DHCP no autorizados..."
    
    # Capturar paquetes DHCP
    local dhcp_server=$(timeout 5 tcpdump -i "$IFACE" -n port 67 -c 5 2>/dev/null | grep -oP 'from \K[0-9a-f:]{17}' | head -1)
    
    if [ -n "$dhcp_server" ]; then
        local server_ip=$(ip neigh show | grep "$dhcp_server" | awk '{print $1}')
        local gw_ip=$(ip route | grep default | awk '{print $3}')
        
        if [ "$server_ip" != "$gw_ip" ]; then
            err "¡POSIBLE ROGUE DHCP SERVER!"
            echo "MAC del servidor DHCP: $dhcp_server"
            echo "IP del servidor: $server_ip"
            
            # Bloquear servidor rogue
            nft add element inet filter blocked_macs { "$dhcp_server" }
            echo "$dhcp_server" >> "$BLOCKED_FILE"
            
            warn "Servidor DHCP rogue bloqueado"
        else
            log "Servidor DHCP legitimo detectado"
        fi
    fi
}

# ============================================================
# 4. BLOQUEO DE MAC
# ============================================================
block_mac() {
    local mac="$1"
    local reason="${2:-Manual}"
    
    if [ -z "$mac" ]; then
        err "Uso: $0 block-mac <MAC> [razon]"
        return 1
    fi
    
    info "Bloqueando MAC: $mac"
    
    # Agregar a nftables
    nft add element inet filter blocked_macs { "$mac" }
    
    # Registrar
    echo "$mac" >> "$BLOCKED_FILE"
    echo "$(date '+%Y-%m-%d %H:%M:%S') $mac bloqueada - Razon: $reason" >> "$LOG_DIR/blocked.log"
    
    log "MAC $mac bloqueada exitosamente"
}

# ============================================================
# 5. ESCANEO DE PUERTOS AL SOSPECHOSO
# ============================================================
scan_suspect() {
    local ip="$1"
    
    if [ -z "$ip" ]; then
        err "Uso: $0 scan <IP_SOSPECHOSA>"
        return 1
    fi
    
    echo -e "\n${YELLOW}=== ESCANEO DE PUERTOS: $ip ===${NC}"
    
    info "Escaneando puertos y servicios..."
    nmap -sV -O --top-ports 100 "$ip"
    
    info "Verificando si tiene servicios DHCP/ARP sospechosos..."
    nmap -sU -p 67,68 "$ip" 2>/dev/null || true
}

# ============================================================
# 6. VERIFICAR LEASES DHCP
# ============================================================
check_dhcp_leases() {
    echo -e "\n${YELLOW}=== LEASES DHCP ===${NC}"
    
    if [ -f "/var/lib/dhcp/dhclient.leases" ]; then
        info "Leases DHCP actuales:"
        cat /var/lib/dhcp/dhclient.leases
    fi
    
    if [ -f "/var/lib/dhcp/dhcpd.leases" ]; then
        info "Servidor DHCP leases:"
        cat /var/lib/dhcp/dhcpd.leases
    fi
    
    # Ver si hay cambios recientes
    echo -e "\n${YELLOW}=== ULTIMOS CAMBIOS DHCP ===${NC}"
    journalctl -u dhcpd --no-pager -n 20 2>/dev/null || \
    grep -i dhcp /var/log/syslog 2>/dev/null | tail -20 || \
    warn "No se encontraron logs DHCP"
}

# ============================================================
# 7. REGISTRAR DISPOSITIVO CONOCIDO
# ============================================================
register_known_device() {
    local ip="$1"
    local mac="$2"
    local description="${3:-Dispositivo conocido}"
    
    if [ -z "$ip" ] || [ -z "$mac" ]; then
        err "Uso: $0 register <IP> <MAC> [descripcion]"
        return 1
    fi
    
    echo "$ip $mac $description" >> "$KNOWN_DEVICES_FILE"
    log "Dispositivo registrado: $ip ($mac) - $description"
}

# ============================================================
# 8. MONITOREO CONTINUO
# ============================================================
continuous_monitor() {
    echo -e "\n${YELLOW}=== MONITOREO CONTINUO ===${NC}"
    info "Presiona Ctrl+C para detener"
    
    while true; do
        clear
        show_banner
        echo "$(date '+%Y-%m-%d %H:%M:%S')"
        
        monitor_arp
        detect_mac_spoofing
        
        echo -e "\n${BLUE}Proximo escaneo en 30 segundos...${NC}"
        sleep 30
    done
}

# ============================================================
# 9. GENERAR REPORTE
# ============================================================
generate_report() {
    echo -e "\n${YELLOW}=== REPORTE DE SEGURIDAD ===${NC}"
    
    local report_file="$LOG_DIR/report-$(date '+%Y%m%d-%H%M%S').txt"
    
    {
        echo "=========================================="
        echo "REPORTE DE SEGURIDAD DE RED"
        echo "Fecha: $(date)"
        echo "=========================================="
        
        echo -e "\n--- TABLA ARP ---"
        ip neigh show
        
        echo -e "\n--- INTERFACES DE RED ---"
        ip addr show
        
        echo -e "\n--- ROUTING ---"
        ip route show
        
        echo -e "\n--- MACS BLOQUEADAS ---"
        cat "$BLOCKED_FILE" 2>/dev/null || echo "Ninguna"
        
        echo -e "\n--- DISPOSITIVOS CONOCIDOS ---"
        cat "$KNOWN_DEVICES_FILE" 2>/dev/null || echo "Ninguno"
        
        echo -e "\n--- ULTIMOS LOGS DE SEGURIDAD ---"
        tail -50 "$ARP_LOG" 2>/dev/null || echo "Sin logs"
        
        echo -e "\n--- LEASES DHCP ---"
        cat /var/lib/dhcp/dhclient.leases 2>/dev/null || echo "Sin leases"
        
    } > "$report_file"
    
    log "Reporte generado: $report_file"
    cat "$report_file"
}

# ============================================================
# MAIN
# ============================================================
show_banner

case "${1:-help}" in
    monitor)
        monitor_arp
        ;;
    scan)
        detect_mac_spoofing
        ;;
    detect-dhcp)
        detect_rogue_dhcp
        ;;
    block-mac)
        block_mac "$2" "${3:-Manual}"
        ;;
    scan-suspect)
        scan_suspect "$2"
        ;;
    leases)
        check_dhcp_leases
        ;;
    register)
        register_known_device "$2" "$3" "${4:-Dispositivo conocido}"
        ;;
    continuous)
        continuous_monitor
        ;;
    report)
        generate_report
        ;;
    help|*)
        echo "Uso: $0 [comando] [opciones]"
        echo ""
        echo "Comandos:"
        echo "  monitor         - Monitorear tabla ARP"
        echo "  scan            - Escaneo completo de red"
        echo "  detect-dhcp     - Detectar rogue DHCP"
        echo "  block-mac <MAC> - Bloquear una MAC"
        echo "  scan-suspect <IP> - Escanear dispositivo sospechoso"
        echo "  leases          - Ver leases DHCP"
        echo "  register <IP> <MAC> [desc] - Registrar dispositivo conocido"
        echo "  continuous      - Monitoreo continuo"
        echo "  report          - Generar reporte de seguridad"
        ;;
esac
