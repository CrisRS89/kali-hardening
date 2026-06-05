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

# --- 8. Scripts de monitoreo ---
echo -e "\n${YELLOW}[8/8]${NC} Scripts de monitoreo..."
cp "$DIR/scripts/secwatch" /usr/local/bin/secwatch
cp "$DIR/scripts/secwatch-live" /usr/local/bin/secwatch-live
cp "$DIR/scripts/check-arp" /usr/local/bin/check-arp
chmod +x /usr/local/bin/secwatch /usr/local/bin/secwatch-live /usr/local/bin/check-arp
ok "Scripts instalados: secwatch, secwatch-live, check-arp"

# --- ARP estática ---
echo -e "\n${YELLOW}[*]${NC} Configurando ARP estática..."
GW_IP=$(ip route | grep default | awk '{print $3}')
GW_MAC=$(arping -c 1 $GW_IP 2>/dev/null | grep -oP 'from \K[0-9a-f:]{17}')
if [ -n "$GW_MAC" ]; then
  ip neigh add $GW_IP lladdr $GW_MAC nud permanent dev eth0 2>/dev/null || true
  echo "up ip neigh add $GW_IP lladdr $GW_MAC nud permanent dev eth0" >> /etc/network/interfaces
  ok "ARP estática para gateway $GW_IP ($GW_MAC)"
fi

# --- AppArmor ---
echo -e "\n${YELLOW}[*]${NC} AppArmor..."
aa-enforce /etc/apparmor.d/bin.ping 2>/dev/null || true
ok "AppArmor perfiles enforce"

echo ""
echo "========================================"
echo -e "${GREEN}  Hardening completado${NC}"
echo "========================================"
echo ""
echo "Comandos útiles:"
echo "  sudo secwatch        - Resumen de seguridad"
echo "  sudo secwatch-live   - Monitoreo en vivo"
echo "  sudo check-arp       - Detectar ARP spoofing"
echo ""
echo "Accedé a Grafana en http://localhost:3000"
echo "  Usuario: admin / Contraseña: (la que configures)"
