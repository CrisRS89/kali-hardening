#!/bin/bash
# ============================================================
# network-fingerprint.sh - Fingerprinting de dispositivos en red
# Identifica dispositivos por multiples metodos
# ============================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

IFACE="${1:-eth0}"
OUTPUT_DIR="/var/log/network-fingerprint"

mkdir -p "$OUTPUT_DIR"

echo -e "${YELLOW}=== NETWORK FINGERPRINTING ===${NC}"
echo "Interfaz: $IFACE"
echo ""

# Obtener subnet
SUBNET=$(ip addr show "$IFACE" | grep -oP 'inet \K[0-9./]+' | head -1)
if [ -z "$SUBNET" ]; then
    echo -e "${RED}No se pudo detectar subnet${NC}"
    exit 1
fi

NETWORK_BASE=$(echo "$SUBNET" | cut -d'.' -f1-3)
echo -e "${BLUE}Subnet: $SUBNET${NC}"
echo ""

# ============================================================
# 1. ESCANEO ARP
# ============================================================
echo -e "${YELLOW}=== 1. ESCANEO ARP ===${NC}"

# Escaneo rapido con arping
echo "Escaneando con arping..."
> "$OUTPUT_DIR/arp-scan.txt"

for i in $(seq 1 254); do
    IP="${NETWORK_BASE}.${i}"
    if arping -c 1 -W 1 -I "$IFACE" "$IP" >/dev/null 2>&1; then
        MAC=$(ip neigh show "$IP" 2>/dev/null | awk '{print $5}' | head -1)
        if [ -n "$MAC" ] && [ "$MAC" != "FAILED" ]; then
            echo "$IP $MAC" >> "$OUTPUT_DIR/arp-scan.txt"
            echo -e "${GREEN}Activo: $IP ($MAC)${NC}"
        fi
    fi
done

echo ""

# ============================================================
# 2. ESCANEO DE PUERTOS A DISPOSITIVOS ACTIVOS
# ============================================================
echo -e "${YELLOW}=== 2. ESCANEO DE PUERTOS ===${NC}"

if [ -f "$OUTPUT_DIR/arp-scan.txt" ]; then
    while IFS=' ' read -r ip mac; do
        if [ -n "$ip" ]; then
            echo -e "${BLUE}Escaneando $ip ($mac)...${NC}"
            
            # Escaneo rapido de puertos comunes
            nmap -sT -T4 --top-ports 20 "$ip" -oN "$OUTPUT_DIR/nmap-${ip}.txt" 2>/dev/null || true
            
            # Detectar SO
            nmap -O --osscan-guess "$ip" 2>/dev/null | grep -i "OS" >> "$OUTPUT_DIR/os-detection.txt" || true
        fi
    done < "$OUTPUT_DIR/arp-scan.txt"
fi

echo ""

# ============================================================
# 3. DETECCION DE SERVICIOS
# ============================================================
echo -e "${YELLOW}=== 3. DETECCION DE SERVICIOS ===${NC}"

if [ -f "$OUTPUT_DIR/arp-scan.txt" ]; then
    while IFS=' ' read -r ip mac; do
        if [ -n "$ip" ]; then
            echo -e "${BLUE}Detectando servicios en $ip...${NC}"
            
            # DHCP server?
            if nmap -sU -p 67 "$ip" 2>/dev/null | grep -q "open"; then
                echo -e "${RED}DHCP Server detectado en $ip${NC}"
                echo "$ip $mac DHCP_SERVER" >> "$OUTPUT_DIR/services-detected.txt"
            fi
            
            # DNS server?
            if nmap -sU -p 53 "$ip" 2>/dev/null | grep -q "open"; then
                echo -e "${RED}DNS Server detectado en $ip${NC}"
                echo "$ip $mac DNS_SERVER" >> "$OUTPUT_DIR/services-detected.txt"
            fi
            
            # ARP spoofing tools?
            if nmap -sT -p 80,443,8080 "$ip" 2>/dev/null | grep -q "open"; then
                echo "$ip $mac WEB_SERVER" >> "$OUTPUT_DIR/services-detected.txt"
            fi
        fi
    done < "$OUTPUT_DIR/arp-scan.txt"
fi

echo ""

# ============================================================
# 4. VERIFICAR INTEGRIDAD DEL GATEWAY
# ============================================================
echo -e "${YELLOW}=== 4. VERIFICACION DEL GATEWAY ===${NC}"

GW_IP=$(ip route | grep default | awk '{print $3}')
GW_MAC_REAL=$(arping -c 3 -I "$IFACE" "$GW_IP" 2>/dev/null | grep -oP 'from \K[0-9a-f:]{17}' | head -1)
GW_MAC_TABLE=$(ip neigh show "$GW_IP" | awk '{print $5}')

echo "Gateway IP: $GW_IP"
echo "MAC en tabla ARP: $GW_MAC_TABLE"
echo "MAC verificada: $GW_MAC_REAL"

if [ "$GW_MAC_TABLE" != "$GW_MAC_REAL" ] && [ -n "$GW_MAC_REAL" ]; then
    echo -e "${RED}¡ALERTA! MAC del gateway no coincide - POSIBLE ARP SPOOFING${NC}"
    echo "$(date) ARP SPOOFING DETECTED - GW: $GW_IP - MAC_TABLE: $GW_MAC_TABLE - MAC_REAL: $GW_MAC_REAL" >> "$OUTPUT_DIR/alerts.txt"
else
    echo -e "${GREEN}Gateway verificado correctamente${NC}"
fi

echo ""

# ============================================================
# 5. RESUMEN
# ============================================================
echo -e "${YELLOW}=== RESUMEN ===${NC}"

TOTAL_DEVICES=$(wc -l < "$OUTPUT_DIR/arp-scan.txt" 2>/dev/null || echo "0")
echo "Total dispositivos activos: $TOTAL_DEVICES"

if [ -f "$OUTPUT_DIR/services-detected.txt" ]; then
    echo ""
    echo "Servicios detectados:"
    cat "$OUTPUT_DIR/services-detected.txt"
fi

if [ -f "$OUTPUT_DIR/alerts.txt" ]; then
    echo ""
    echo -e "${RED}ALERTAS:${NC}"
    cat "$OUTPUT_DIR/alerts.txt"
fi

echo ""
echo "Logs guardados en: $OUTPUT_DIR"
