#!/bin/bash
# ============================================================
# dhcp-rogue-detect.sh - Detectar servidores DHCP no autorizados
# ============================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

LOG_DIR="/var/log/dhcp-rogue"
LOG_FILE="$LOG_DIR/rogue-detect.log"

mkdir -p "$LOG_DIR"
touch "$LOG_FILE"

IFACE="${1:-eth0}"

echo -e "${YELLOW}=== Deteccion de Rogue DHCP Server ===${NC}"
echo "Interfaz: $IFACE"
echo ""

# Obtener informacion del gateway legitimo
GW_IP=$(ip route | grep default | awk '{print $3}')
GW_MAC=$(ip neigh show "$GW_IP" | awk '{print $5}')

echo -e "${GREEN}Gateway legitimo: $GW_IP ($GW_MAC)${NC}"
echo ""

# Capturar paquetes DHCP durante 10 segundos
echo -e "${YELLOW}Capturando trafico DHCP (10 segundos)...${NC}"

# Capturar DHCP OFFER y ACK (respuestas del servidor)
dhcp_responses=$(timeout 10 tcpdump -i "$IFACE" -n port 67 or port 68 -c 50 2>/dev/null || true)

if [ -n "$dhcp_responses" ]; then
    echo -e "\n${YELLOW}=== RESPUESTAS DHCP CAPTURADAS ===${NC}"
    echo "$dhcp_responses"
    
    # Extraer MACs de servidores DHCP
    dhcp_macs=$(echo "$dhcp_responses" | grep -oP '([0-9a-f]{2}:){5}[0-9a-f]{2}' | sort -u)
    
    echo -e "\n${YELLOW}=== SERVIDORES DHCP DETECTADOS ===${NC}"
    
    for mac in $dhcp_macs; do
        # Obtener IP asociada al MAC
        dhcp_ip=$(ip neigh show | grep "$mac" | awk '{print $1}' | head -1)
        
        if [ -n "$dhcp_ip" ]; then
            if [ "$mac" = "$GW_MAC" ] || [ "$dhcp_ip" = "$GW_IP" ]; then
                echo -e "${GREEN}Servidor DHCP legitimo: $dhcp_ip ($mac)${NC}"
            else
                echo -e "${RED}¡POSSIBLE ROGUE DHCP SERVER!${NC}"
                echo -e "${RED}IP: $dhcp_ip${NC}"
                echo -e "${RED}MAC: $mac${NC}"
                
                # Registrar incidente
                timestamp=$(date '+%Y-%m-%d %H:%M:%S')
                echo "$timestamp ROGUE DHCP DETECTED - IP: $dhcp_ip MAC: $mac" >> "$LOG_FILE"
                
                # Bloquear servidor rogue
                echo -e "${YELLOW}Bloqueando servidor rogue...${NC}"
                nft add element inet filter blocked_macs { "$mac" } 2>/dev/null || true
                
                echo -e "${GREEN}Servidor rogue bloqueado${NC}"
            fi
        fi
    done
else
    echo -e "${GREEN}No se detectaron respuestas DHCP externas${NC}"
fi

# Verificar si hay multiples servidores DHCP activos
echo -e "\n${YELLOW}=== VERIFICANDO SERVIDORES DHCP ACTIVOS ===${NC}"

# Intentar discover desde esta maquina
echo "Enviando DHCPDISCOVER..."
dhclient -v "$IFACE" 2>&1 | grep -E "DHCP|OFFER|ACK" || true

echo -e "\n${GREEN}Verificacion completada${NC}"
echo "Logs guardados en: $LOG_FILE"
