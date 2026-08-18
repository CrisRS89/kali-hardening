#!/bin/bash
set -e

# ============================================================
# Kali Linux Hardening Script
# Uso: sudo bash install.sh
# ============================================================

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
ok() { echo -e "${GREEN}[✓]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
err() { echo -e "${RED}[✗]${NC} $1"; exit 1; }

[[ $EUID -ne 0 ]] && err "Ejecutar como root: sudo bash install.sh"

echo "========================================"
echo "  Kali Linux - Hardening de Red"
echo "========================================"

DIR="$(cd "$(dirname "$0")" && pwd)"

# --- 1. Firewall nftables ---
echo -e "\n${YELLOW}[1/8]${NC} Firewall nftables..."
cp "$DIR/nftables/nftables.conf" /etc/nftables.conf
nft -c -f /etc/nftables.conf && nft -f /etc/nftables.conf
systemctl enable --now nftables
ok "nftables activado con política DROP"

# --- 2. Suricata IDS ---
echo -e "\n${YELLOW}[2/8]${NC} Suricata IDS..."
DEBIAN_FRONTEND=noninteractive apt install -y suricata 2>/dev/null
cp "$DIR/suricata/threshold.config" /etc/suricata/
sed -i 's|# threshold-file: /etc/suricata/threshold.config|threshold-file: /etc/suricata/threshold.config|' /etc/suricata/suricata.yaml
sed -i 's/community-id: false/community-id: true/' /etc/suricata/suricata.yaml
suricata-update 2>&1 | tail -1
systemctl enable --now suricata
ok "Suricata activo con reglas actualizadas"

# --- 3. fail2ban ---
echo -e "\n${YELLOW}[3/8]${NC} fail2ban..."
DEBIAN_FRONTEND=noninteractive apt install -y fail2ban 2>/dev/null
systemctl enable --now fail2ban
ok "fail2ban activo (jail SSH)"

# --- 4. crowsec ---
echo -e "\n${YELLOW}[4/8]${NC} CrowdSec..."
DEBIAN_FRONTEND=noninteractive apt install -y crowdsec 2>/dev/null
cscli collections install crowdsecurity/linux 2>&1 | tail -1 2>/dev/null || true
systemctl enable --now crowdsec 2>/dev/null
ok "CrowdSec activo"

# --- 5. sysctl hardening ---
echo -e "\n${YELLOW}[5/8]${NC} Kernel hardening (sysctl)..."
cat "$DIR/sysctl/sysctl.conf" >> /etc/sysctl.conf
sysctl -p 2>/dev/null
ok "Parámetros de red endurecidos"

# --- 6. auditd ---
echo -e "\n${YELLOW}[6/8]${NC} auditd..."
DEBIAN_FRONTEND=noninteractive apt install -y auditd 2>/dev/null
cp "$DIR/auditd/hardening.rules" /etc/audit/rules.d/
auditctl -R /etc/audit/rules.d/hardening.rules 2>/dev/null || true
systemctl enable --now auditd
ok "Auditoría activa"

# --- 7. rkhunter + chkrootkit ---
echo -e "\n${YELLOW}[7/8]${NC} rkhunter + chkrootkit..."
DEBIAN_FRONTEND=noninteractive apt install -y rkhunter chkrootkit 2>/dev/null
rkhunter --propupd 2>&1 | tail -1
cp "$DIR/rkhunter.service" /etc/systemd/system/ 2>/dev/null || true
cp "$DIR/rkhunter.timer" /etc/systemd/system/ 2>/dev/null || true
systemctl daemon-reload 2>/dev/null
systemctl enable --now rkhunter.timer 2>/dev/null || true
ok "Rootkit detection activo (escaneo diario)"

# --- 8. Scripts de monitoreo y defensa ---
echo -e "\n${YELLOW}[8/10]${NC} Scripts de monitoreo y defensa..."
cp "$DIR/scripts/secwatch" /usr/local/bin/secwatch
cp "$DIR/scripts/secwatch-live" /usr/local/bin/secwatch-live
cp "$DIR/scripts/check-arp" /usr/local/bin/check-arp
cp "$DIR/scripts/network-defender.sh" /usr/local/bin/network-defender
cp "$DIR/scripts/arp-monitor.sh" /usr/local/bin/arp-monitor
cp "$DIR/scripts/dhcp-rogue-detect.sh" /usr/local/bin/dhcp-rogue-detect
cp "$DIR/scripts/network-fingerprint.sh" /usr/local/bin/network-fingerprint
cp "$DIR/scripts/whitelist-manager.sh" /usr/local/bin/whitelist-manager
cp "$DIR/scripts/tls-fingerprint.sh" /usr/local/bin/tls-fingerprint
cp "$DIR/scripts/mac-flapping-detect.sh" /usr/local/bin/mac-flapping-detect
cp "$DIR/scripts/active-defense.sh" /usr/local/bin/active-defense
chmod +x /usr/local/bin/secwatch /usr/local/bin/secwatch-live /usr/local/bin/check-arp
chmod +x /usr/local/bin/network-defender /usr/local/bin/arp-monitor
chmod +x /usr/local/bin/dhcp-rogue-detect /usr/local/bin/network-fingerprint
chmod +x /usr/local/bin/whitelist-manager /usr/local/bin/tls-fingerprint
chmod +x /usr/local/bin/mac-flapping-detect /usr/local/bin/active-defense
ok "Todos los scripts instalados"

# --- 9. Herramientas de red adicionales ---
echo -e "\n${YELLOW}[9/10]${NC} Instalando herramientas de red..."
DEBIAN_FRONTEND=noninteractive apt install -y arpwatch dsniff nmap macchanger netdiscover arping tcpdump hping3 p0f snmp tshark aircrack-ng 2>/dev/null
ok "Herramientas de red instaladas"

# --- 10. Configuración de ocultamiento y MAC random ---
echo -e "\n${YELLOW}[10/10]${NC} Configurando ocultamiento y aleatorización..."
mkdir -p /etc/NetworkManager/conf.d
cat > /etc/NetworkManager/conf.d/00-macrandom.conf << 'EOF'
[device]
wifi.scan-rand-mac-address=yes

[connection]
wifi.cloned-mac-address=random
ethernet.cloned-mac-address=random
EOF
systemctl restart NetworkManager 2>/dev/null || true
ok "MAC randomization configurado"

# --- Configurar ARP estática ---
echo -e "\n${YELLOW}[*]${NC} Configurando ARP estática..."
GW_IP=$(ip route | grep default | awk '{print $3}')
GW_MAC=$(arping -c 1 $GW_IP 2>/dev/null | grep -oP 'from \K[0-9a-f:]{17}')
if [ -n "$GW_MAC" ]; then
  ip neigh add $GW_IP lladdr $GW_MAC nud permanent dev eth0 2>/dev/null || true
  echo "up ip neigh add $GW_IP lladdr $GW_MAC nud permanent dev eth0" >> /etc/network/interfaces
  ok "ARP estática para gateway $GW_IP ($GW_MAC)"
fi

# --- Configurar ARPwatch ---
echo -e "\n${YELLOW}[*]${NC} Configurando ARPwatch..."
systemctl enable arpwatch 2>/dev/null || true
systemctl start arpwatch 2>/dev/null || true
ok "ARPwatch configurado para monitoreo ARP"

# --- AppArmor ---
echo -e "\n${YELLOW}[*]${NC} AppArmor..."
aa-enforce /etc/apparmor.d/bin.ping 2>/dev/null || true
ok "AppArmor perfiles enforce"

# --- Crear directorios de logs ---
echo -e "\n${YELLOW}[*]${NC} Creando directorios de logs..."
mkdir -p /var/log/network-defense
mkdir -p /var/log/arp-monitor
mkdir -p /var/log/dhcp-rogue
mkdir -p /var/log/network-fingerprint
mkdir -p /var/log/tls-fingerprint
mkdir -p /var/log/mac-flapping
mkdir -p /var/log/active-defense
mkdir -p /var/log/whitelist-manager
mkdir -p /etc/nftables
ok "Directorios de logs creados"

# --- Inicializar whitelist ---
echo -e "\n${YELLOW}[*]${NC} Inicializando whitelist..."
/usr/local/bin/whitelist-manager init 2>/dev/null || true
ok "Whitelist inicializada"

echo ""
echo "========================================"
echo -e "${GREEN}  Hardening completado${NC}"
echo "========================================"
echo ""
echo "=== COMANDOS ORIGINALES ==="
echo "  sudo secwatch          - Resumen de seguridad"
echo "  sudo secwatch-live     - Monitoreo en vivo"
echo "  sudo check-arp         - Detectar ARP spoofing"
echo ""
echo "=== DEFENSA DE LISTA BLANCA ==="
echo "  sudo whitelist-manager list     - Ver dispositivos autorizados"
echo "  sudo whitelist-manager add IP MAC [desc] - Autorizar dispositivo"
echo "  sudo whitelist-manager remove IP/MAC - Revocar acceso"
echo "  sudo whitelist-manager discover - Auto-descubrir dispositivos"
echo ""
echo "=== DETECCIÓN Y MONITOREO ==="
echo "  sudo network-defender monitor   - Monitorear ARP"
echo "  sudo network-defender scan      - Escaneo completo"
echo "  sudo arp-monitor                - Monitoreo continuo ARP"
echo "  sudo dhcp-rogue-detect          - Detectar DHCP rogue"
echo "  sudo network-fingerprint        - Fingerprinting de red"
echo "  sudo mac-flapping-detect detect - Detectar MAC flapping"
echo ""
echo "=== FINGERPRINTING TLS/OS ==="
echo "  sudo tls-fingerprint ja3        - Capturar hashes JA3"
echo "  sudo tls-fingerprint p0f        - OS fingerprinting"
echo "  sudo tls-fingerprint useragent  - Detectar User-Agents"
echo ""
echo "=== CONTRAMEDIDAS ACTIVAS (usar con precaución) ==="
echo "  sudo active-defense arp-cut <IP>     - Cortar conexión del atacante"
echo "  sudo active-defense tarpit <IP>      - Congelar escáner"
echo "  sudo active-defense blackhole <IP>   - Agujero negro total"
echo "  sudo active-defense wifi-deauth <MAC> - Expulsar del Wi-Fi"
echo "  sudo active-defense inferno <IP>     - Bombardeo de paquetes"
echo "  sudo active-defense ghost            - Modo fantasma (invisibilidad)"
echo "  sudo active-defense stop             - Detener contramedidas"
echo ""
echo "=== OCULTAMIENTO ==="
echo "  sudo sysctl -w net.ipv4.icmp_echo_ignore_all=1  - Ocultar de ping"
echo "  MAC randomization activo en NetworkManager"
echo ""
echo "Accedé a Grafana en http://localhost:3000"
echo "  Usuario: admin / Contraseña: (la que configures)"
