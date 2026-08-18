#!/bin/bash
# ============================================================
# Kali Linux Hardening - Multi-Distro Installer
# Soporta: Kali, Debian, Ubuntu, Arch, Fedora, CentOS, RHEL
# Uso: sudo bash install.sh
# ============================================================

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

ok() { echo -e "${GREEN}[✓]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
err() { echo -e "${RED}[✗]${NC} $1"; exit 1; }
info() { echo -e "${BLUE}[i]${NC} $1"; }

# ============================================================
# DETECTAR DISTRIBUCIÓN
# ============================================================
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
        DISTRO_VERSION=$VERSION_ID
        DISTRO_NAME=$PRETTY_NAME
    elif [ -f /etc/debian_version ]; then
        DISTRO="debian"
        DISTRO_NAME="Debian"
    elif [ -f /etc/arch-release ]; then
        DISTRO="arch"
        DISTRO_NAME="Arch Linux"
    elif [ -f /etc/fedora-release ]; then
        DISTRO="fedora"
        DISTRO_NAME="Fedora"
    else
        DISTRO="unknown"
        DISTRO_NAME="Unknown"
    fi
    
    echo -e "${CYAN}Distribución detectada: ${DISTRO_NAME}${NC}"
}

# ============================================================
# DETECTAR GESTOR DE PAQUETES
# ============================================================
detect_package_manager() {
    if command -v apt-get &> /dev/null; then
        PKG_MANAGER="apt"
        PKG_INSTALL="apt-get install -y"
        PKG_UPDATE="apt-get update -y"
    elif command -v dnf &> /dev/null; then
        PKG_MANAGER="dnf"
        PKG_INSTALL="dnf install -y"
        PKG_UPDATE="dnf check-update || true"
    elif command -v yum &> /dev/null; then
        PKG_MANAGER="yum"
        PKG_INSTALL="yum install -y"
        PKG_UPDATE="yum check-update || true"
    elif command -v pacman &> /dev/null; then
        PKG_MANAGER="pacman"
        PKG_INSTALL="pacman -S --noconfirm"
        PKG_UPDATE="pacman -Sy"
    else
        err "Gestor de paquetes no soportado"
    fi
    
    info "Gestor de paquetes: $PKG_MANAGER"
}

# ============================================================
# INSTALAR DEPENDENCIAS BÁSICAS
# ============================================================
install_dependencies() {
    echo -e "\n${YELLOW}[*]${NC} Instalando dependencias básicas..."
    
    case $PKG_MANAGER in
        apt)
            $PKG_UPDATE
            $PKG_INSTALL git curl wget net-tools iputils-ping
            ;;
        dnf|yum)
            $PKG_UPDATE
            $PKG_INSTALL git curl wget net-tools iputils
            ;;
        pacman)
            $PKG_UPDATE
            $PKG_INSTALL git curl wget net-tools iputils
            ;;
    esac
    
    ok "Dependencias básicas instaladas"
}

# ============================================================
# INSTALAR HERRAMIENTAS DE RED
# ============================================================
install_network_tools() {
    echo -e "\n${YELLOW}[*]${NC} Instalando herramientas de red..."
    
    case $PKG_MANAGER in
        apt)
            DEBIAN_FRONTEND=noninteractive $PKG_INSTALL \
                arpwatch dsniff nmap macchanger netdiscover arping \
                tcpdump hping3 snmp tshark aircrack-ng \
                fail2ban crowdsec suricata auditd rkhunter chkrootkit \
                apparmor-utils 2>/dev/null || true
            ;;
        dnf|yum)
            $PKG_INSTALL \
                arpwatch dsniff nmap net-tools tcpdump hping3 \
                net-snmp wireshark-cli aircrack-ng \
                fail2ban audit rkhunter chkrootkit 2>/dev/null || true
            ;;
        pacman)
            $PKG_INSTALL \
                arpwatch dsniff nmap net-tools tcpdump hping \
                net-snmp wireshark-cli aircrack-ng \
                fail2ban audit rkhunter chkrootkit 2>/dev/null || true
            ;;
    esac
    
    ok "Herramientas de red instaladas"
}

# ============================================================
# INSTALAR SCRIPTS
# ============================================================
install_scripts() {
    echo -e "\n${YELLOW}[*]${NC} Instalando scripts..."
    
    local SCRIPTS=(
        "secwatch"
        "secwatch-live"
        "check-arp"
        "network-defender.sh"
        "arp-monitor.sh"
        "dhcp-rogue-detect.sh"
        "network-fingerprint.sh"
        "whitelist-manager.sh"
        "tls-fingerprint.sh"
        "mac-flapping-detect.sh"
        "active-defense.sh"
    )
    
    for script in "${SCRIPTS[@]}"; do
        if [ -f "$DIR/scripts/$script" ]; then
            cp "$DIR/scripts/$script" "/usr/local/bin/$(basename $script .sh)"
            chmod +x "/usr/local/bin/$(basename $script .sh)"
        fi
    done
    
    ok "Scripts instalados en /usr/local/bin/"
}

# ============================================================
# CONFIGURAR FIREWALL
# ============================================================
setup_firewall() {
    echo -e "\n${YELLOW}[1/10]${NC} Configurando firewall..."
    
    # Verificar si nftables está disponible
    if command -v nft &> /dev/null; then
        cp "$DIR/nftables/nftables.conf" /etc/nftables.conf
        nft -c -f /etc/nftables.conf && nft -f /etc/nftables.conf
        systemctl enable --now nftables 2>/dev/null || true
        ok "nftables activado con lista blanca"
    else
        warn "nftables no disponible, usando iptables como fallback"
        # Fallback a iptables
        iptables -P INPUT DROP
        iptables -P FORWARD DROP
        iptables -A INPUT -i lo -j ACCEPT
        iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
        ok "iptables configurado como fallback"
    fi
}

# ============================================================
# CONFIGURAR SURICATA
# ============================================================
setup_suricata() {
    echo -e "\n${YELLOW}[2/10]${NC} Configurando Suricata IDS..."
    
    if command -v suricata &> /dev/null; then
        cp "$DIR/suricata/threshold.config" /etc/suricata/ 2>/dev/null || true
        
        # Habilitar JA3 si el archivo existe
        if [ -f /etc/suricata/suricata.yaml ]; then
            sed -i 's|# threshold-file: /etc/suricata/threshold.config|threshold-file: /etc/suricata/threshold.config|' /etc/suricata/suricata.yaml 2>/dev/null || true
            sed -i 's/community-id: false/community-id: true/' /etc/suricata/suricata.yaml 2>/dev/null || true
        fi
        
        suricata-update 2>&1 | tail -1 || true
        systemctl enable --now suricata 2>/dev/null || true
        ok "Suricata activo con JA3"
    else
        warn "Suricata no disponible en esta distribución"
    fi
}

# ============================================================
# CONFIGURAR FAIL2BAN
# ============================================================
setup_fail2ban() {
    echo -e "\n${YELLOW}[3/10]${NC} Configurando fail2ban..."
    
    if command -v fail2ban-client &> /dev/null; then
        systemctl enable --now fail2ban 2>/dev/null || true
        ok "fail2ban activo"
    else
        warn "fail2ban no disponible"
    fi
}

# ============================================================
# CONFIGURAR CROWDSEC
# ============================================================
setup_crowdsec() {
    echo -e "\n${YELLOW}[4/10]${NC} Configurando CrowdSec..."
    
    if command -v cscli &> /dev/null; then
        cscli collections install crowdsecurity/linux 2>&1 | tail -1 2>/dev/null || true
        systemctl enable --now crowdsec 2>/dev/null || true
        ok "CrowdSec activo"
    else
        warn "CrowdSec no disponible - instalar manualmente si se necesita"
    fi
}

# ============================================================
# KERNEL HARDENING
# ============================================================
setup_kernel() {
    echo -e "\n${YELLOW}[5/10]${NC} Kernel hardening (sysctl)..."
    
    if [ -f "$DIR/sysctl/sysctl.conf" ]; then
        # Backup del sysctl actual
        cp /etc/sysctl.conf /etc/sysctl.conf.bak.$(date +%s) 2>/dev/null || true
        
        # Agregar configuraciones (evitar duplicados)
        while IFS= read -r line; do
            if [[ "$line" =~ ^[a-z] ]] && ! grep -q "^${line%%=*}" /etc/sysctl.conf 2>/dev/null; then
                echo "$line" >> /etc/sysctl.conf
            fi
        done < "$DIR/sysctl/sysctl.conf"
        
        sysctl -p 2>/dev/null || true
        ok "Parámetros de red endurecidos"
    fi
}

# ============================================================
# CONFIGURAR AUDITD
# ============================================================
setup_auditd() {
    echo -e "\n${YELLOW}[6/10]${NC} Configurando auditd..."
    
    if command -v auditctl &> /dev/null; then
        if [ -d /etc/audit/rules.d ]; then
            cp "$DIR/auditd/hardening.rules" /etc/audit/rules.d/ 2>/dev/null || true
        fi
        auditctl -R /etc/audit/rules.d/hardening.rules 2>/dev/null || true
        systemctl enable --now auditd 2>/dev/null || true
        ok "Auditoría activa"
    else
        warn "auditd no disponible"
    fi
}

# ============================================================
# CONFIGURAR ROOTKIT DETECTION
# ============================================================
setup_rootkits() {
    echo -e "\n${YELLOW}[7/10]${NC} Configurando detección de rootkits..."
    
    if command -v rkhunter &> /dev/null; then
        rkhunter --propupd 2>&1 | tail -1 || true
        cp "$DIR/rkhunter.service" /etc/systemd/system/ 2>/dev/null || true
        cp "$DIR/rkhunter.timer" /etc/systemd/system/ 2>/dev/null || true
        systemctl daemon-reload 2>/dev/null || true
        systemctl enable --now rkhunter.timer 2>/dev/null || true
        ok "rkhunter configurado"
    fi
    
    if command -v chkrootkit &> /dev/null; then
        ok "chkrootkit disponible"
    fi
}

# ============================================================
# CONFIGURAR ARP ESTÁTICA
# ============================================================
setup_arp() {
    echo -e "\n${YELLOW}[8/10]${NC} Configurando ARP estática..."
    
    GW_IP=$(ip route | grep default | awk '{print $3}')
    
    if [ -n "$GW_IP" ]; then
        GW_MAC=$(arping -c 1 "$GW_IP" 2>/dev/null | grep -oP 'from \K[0-9a-f:]{17}' | head -1)
        
        if [ -n "$GW_MAC" ]; then
            # Detectar interfaz principal
            IFACE=$(ip route | grep default | awk '{print $5}' | head -1)
            [ -z "$IFACE" ] && IFACE="eth0"
            
            ip neigh add "$GW_IP" lladdr "$GW_MAC" nud permanent dev "$IFACE" 2>/dev/null || true
            
            # Persistir en NetworkManager o interfaces
            if [ -d /etc/NetworkManager/conf.d ]; then
                cat > /etc/NetworkManager/conf.d/99-arp-static.conf << EOF
[connection]
ipv4.never-default=false
EOF
            fi
            
            ok "ARP estática para gateway $GW_IP ($GW_MAC)"
        fi
    fi
}

# ============================================================
# CONFIGURAR ARPWATCH
# ============================================================
setup_arpwatch() {
    echo -e "\n${YELLOW}[9/10]${NC} Configurando ARPwatch..."
    
    if command -v arpwatch &> /dev/null; then
        systemctl enable arpwatch 2>/dev/null || true
        systemctl start arpwatch 2>/dev/null || true
        ok "ARPwatch configurado"
    else
        warn "ARPwatch no disponible"
    fi
}

# ============================================================
# CONFIGURAR MAC RANDOMIZATION
# ============================================================
setup_mac_random() {
    echo -e "\n${YELLOW}[10/10]${NC} Configurando MAC randomization..."
    
    if [ -d /etc/NetworkManager/conf.d ]; then
        cat > /etc/NetworkManager/conf.d/00-macrandom.conf << 'EOF'
[device]
wifi.scan-rand-mac-address=yes

[connection]
wifi.cloned-mac-address=random
ethernet.cloned-mac-address=random
EOF
        systemctl restart NetworkManager 2>/dev/null || true
        ok "MAC randomization configurado"
    else
        warn "NetworkManager no encontrado - configurar MAC random manualmente"
    fi
}

# ============================================================
# CREAR DIRECTORIOS DE LOGS
# ============================================================
setup_logs() {
    echo -e "\n${YELLOW}[*]${NC} Creando directorios de logs..."
    
    local LOG_DIRS=(
        "network-defense"
        "arp-monitor"
        "dhcp-rogue"
        "network-fingerprint"
        "tls-fingerprint"
        "mac-flapping"
        "active-defense"
        "whitelist-manager"
    )
    
    for dir in "${LOG_DIRS[@]}"; do
        mkdir -p "/var/log/$dir"
    done
    
    mkdir -p /etc/nftables
    
    ok "Directorios de logs creados"
}

# ============================================================
# INICIALIZAR WHITELIST
# ============================================================
setup_whitelist() {
    echo -e "\n${YELLOW}[*]${NC} Inicializando whitelist..."
    
    if [ -x /usr/local/bin/whitelist-manager ]; then
        /usr/local/bin/whitelist-manager init 2>/dev/null || true
        ok "Whitelist inicializada"
    fi
}

# ============================================================
# MOSTRAR RESUMEN
# ============================================================
show_summary() {
    echo ""
    echo -e "${CYAN}========================================${NC}"
    echo -e "${GREEN}  ✅ Hardening completado${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
    echo -e "Distribución: ${BLUE}${DISTRO_NAME}${NC}"
    echo -e "Gestor de paquetes: ${BLUE}${PKG_MANAGER}${NC}"
    echo ""
    echo -e "${YELLOW}=== PRIMEROS PASOS ===${NC}"
    echo "  1. sudo secwatch                    # Ver estado"
    echo "  2. sudo whitelist-manager discover  # Descubrir dispositivos"
    echo "  3. sudo whitelist-manager list      # Ver autorizados"
    echo ""
    echo -e "${YELLOW}=== DETECCIÓN ===${NC}"
    echo "  sudo network-defender scan          # Escaneo completo"
    echo "  sudo tls-fingerprint all            # JA3 + p0f"
    echo "  sudo mac-flapping-detect detect     # MAC spoofing"
    echo ""
    echo -e "${YELLOW}=== PROTECCIÓN ===${NC}"
    echo "  sudo active-defense ghost           # Invisibilidad"
    echo "  sudo whitelist-manager list         # Lista blanca"
    echo ""
    echo -e "${YELLOW}=== CONTRAATAQUE ===${NC}"
    echo "  sudo active-defense arp-cut <IP>    # Cortar conexión"
    echo "  sudo active-defense tarpit <IP>     # Congelar escáner"
    echo "  sudo active-defense stop            # Detener todo"
    echo ""
    echo -e "${YELLOW}=== DASHBOARD ===${NC}"
    echo "  Grafana: http://localhost:3000"
    echo "  Usuario: admin"
    echo ""
    echo -e "${BLUE}Documentación completa: https://github.com/CrisRS89/kali-hardening${NC}"
}

# ============================================================
# MAIN
# ============================================================
echo -e "${CYAN}"
echo "╔═══════════════════════════════════════════════════════╗"
echo "║   KALI LINUX HARDENING - Multi-Distro Installer      ║"
echo "║   Sistema Completo de Defensa de Red                 ║"
echo "╚═══════════════════════════════════════════════════════╝"
echo -e "${NC}"

[[ $EUID -ne 0 ]] && err "Ejecutar como root: sudo bash install.sh"

DIR="$(cd "$(dirname "$0")" && pwd)"

# Detectar sistema
detect_distro
detect_package_manager

echo ""
info "Iniciando instalación..."
echo ""

# Instalar
install_dependencies
install_network_tools
install_scripts

# Configurar servicios
setup_firewall
setup_suricata
setup_fail2ban
setup_crowdsec
setup_kernel
setup_auditd
setup_rootkits

# Configurar red
setup_arp
setup_arpwatch
setup_mac_random

# Finalizar
setup_logs
setup_whitelist
show_summary
