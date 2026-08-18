#!/bin/bash
# ============================================================
# arp-monitor.sh - Monitoreo continuo de ARP
# Detecta cambios en la tabla ARP y alerta
# ============================================================

set -e

LOG_DIR="/var/log/arp-monitor"
ARP_LOG="$LOG_DIR/arp-changes.log"
ALERT_LOG="$LOG_DIR/alerts.log"

mkdir -p "$LOG_DIR"
touch "$ARP_LOG" "$ALERT_LOG"

IFACE="${1:-eth0}"
INTERVAL="${2:-5}"

echo "=== ARP Monitor - Interfaz: $IFACE - Intervalo: ${INTERVAL}s ==="
echo "Logs en: $LOG_DIR"
echo "Presiona Ctrl+C para detener"
echo ""

# Guardar estado inicial
ip neigh show | awk '{print $1, $5}' | sort > "$LOG_DIR/arp-state-$$"

while true; do
    # Obtener estado actual
    current=$(ip neigh show | awk '{print $1, $5}' | sort)
    current_full=$(ip neigh show)
    
    # Comparar con el anterior
    if [ -f "$LOG_DIR/arp-state-last.txt" ]; then
        previous=$(cat "$LOG_DIR/arp-state-last.txt")
        
        if [ "$current" != "$previous" ]; then
            timestamp=$(date '+%Y-%m-%d %H:%M:%S')
            
            # Detectar cambios especificos
            # Nuevos dispositivos
            new_devices=$(diff <(echo "$previous") <(echo "$current") | grep '^>' | awk '{print $2}')
            removed_devices=$(diff <(echo "$previous") <(echo "$current") | grep '^<' | awk '{print $2}')
            
            if [ -n "$new_devices" ]; then
                echo "[$timestamp] NUEVOS DISPOSITIVOS:" >> "$ALERT_LOG"
                echo "$new_devices" >> "$ALERT_LOG"
                
                # Verificar si el MAC es conocido o sospechoso
                for ip in $new_devices; do
                    mac=$(ip neigh show "$ip" 2>/dev/null | awk '{print $5}')
                    if [ -n "$mac" ] && [ "$mac" != "FAILED" ]; then
                        # Verificar si es el gateway
                        gw_ip=$(ip route | grep default | awk '{print $3}')
                        if [ "$ip" != "$gw_ip" ]; then
                            echo "[$timestamp] NUEVO DISPOSITIVO: $ip ($mac)" >> "$ALERT_LOG"
                        fi
                    fi
                done
            fi
            
            if [ -n "$removed_devices" ]; then
                echo "[$timestamp] DISPOSITIVOS REMOVIDOS:" >> "$ALERT_LOG"
                echo "$removed_devices" >> "$ALERT_LOG"
            fi
            
            # Detectar cambios de MAC en la misma IP (spoofing)
            for ip in $(echo "$current" | awk '{print $1}'); do
                old_mac=$(echo "$previous" | grep "^$ip " | awk '{print $2}')
                new_mac=$(echo "$current" | grep "^$ip " | awk '{print $2}')
                
                if [ -n "$old_mac" ] && [ -n "$new_mac" ] && [ "$old_mac" != "$new_mac" ] && [ "$new_mac" != "FAILED" ]; then
                    echo "[$timestamp] ¡POSIBLE MAC SPOOFING! IP: $ip - MAC anterior: $old_mac - MAC actual: $new_mac" >> "$ALERT_LOG"
                    echo "ALERTA: Cambio de MAC detectado en $ip" >&2
                fi
            done
            
            # Registrar el cambio
            echo "$timestamp CAMBIO ARP:" >> "$ARP_LOG"
            diff <(echo "$previous") <(echo "$current") >> "$ARP_LOG" || true
            echo "---" >> "$ARP_LOG"
            
            echo "[$timestamp] Cambio detectado en tabla ARP"
        fi
    fi
    
    # Guardar estado actual como anterior
    echo "$current" > "$LOG_DIR/arp-state-last.txt"
    
    sleep "$INTERVAL"
done
