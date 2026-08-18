#!/bin/bash
# ============================================================
# tls-fingerprint.sh - Fingerprinting TLS/JA3 y OS (p0f)
# Identifica dispositivos por huellas digitales de aplicación
# ============================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

LOG_DIR="/var/log/tls-fingerprint"
JA3_LOG="$LOG_DIR/ja3-hashes.log"
P0F_LOG="$LOG_DIR/p0f-fingerprints.log"
USERAGENT_LOG="$LOG_DIR/user-agents.log"

mkdir -p "$LOG_DIR"

log() { echo -e "${GREEN}[✓]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
info() { echo -e "${BLUE}[i]${NC} $1"; }

[[ $EUID -ne 0 ]] && { echo -e "${RED}Ejecutar como root${NC}"; exit 1; }

# ============================================================
# 1. CAPTURAR HASHES JA3
# ============================================================
capture_ja3() {
    echo -e "\n${CYAN}=== CAPTURANDO FINGERPRINTS JA3 ===${NC}"
    info "JA3 es un hash que identifica exclusivamente cada cliente TLS"
    echo ""
    
    # Verificar si Suricata está configurado con JA3
    if grep -q "ja3" /etc/suricata/suricata.yaml 2>/dev/null; then
        log "Suricata tiene JA3 habilitado"
        
        # Buscar hashes JA3 en logs de Suricata
        info "Buscando hashes JA3 en eve.json..."
        grep -i "ja3" /var/log/suricata/eve.json 2>/dev/null | \
            jq -c 'select(.tls != null) | {src_ip, ja3: .tls.ja3, ja3_hash: .tls.ja3_hash, ja3_str: .tls.ja3_str}' 2>/dev/null | \
            tee -a "$JA3_LOG" || warn "No se encontraron hashes JA3 aún"
    else
        warn "JA3 no está habilitado en Suricata"
        info "Para habilitar JA3 en Suricata:"
        echo "  1. Editar /etc/suricata/suricata.yaml"
        echo "  2. Agregar: - ja3"
        echo "  3. En app-layer-protocols.tls"
    fi
    
    # Método alternativo con tcpdump
    echo ""
    info "Método alternativo: captura directa con tcpdump"
    info "Capturando tráfico TLS (10 segundos)..."
    
    timeout 10 tcpdump -i eth0 -n port 443 -w "$LOG_DIR/tls-capture.pcap" 2>/dev/null || true
    
    if [ -f "$LOG_DIR/tls-capture.pcap" ]; then
        log "Captura TLS guardada en $LOG_DIR/tls-capture.pcap"
        info "Analizar con: tshark -r $LOG_DIR/tls-capture.pcap -Y tls.handshake.type==1 -T fields -e ip.src -e tls.handshake.extensions_server_name"
    fi
}

# ============================================================
# 2. ANÁLISIS PASIVO CON p0f
# ============================================================
analyze_p0f() {
    echo -e "\n${CYAN}=== ANÁLISIS OS FINGERPRINTING CON p0f ===${NC}"
    info "p0f identifica el SO analizando paquetes TCP/IP"
    echo ""
    
    # Verificar si p0f está instalado
    if ! command -v p0f &> /dev/null; then
        warn "p0f no está instalado"
        info "Instalando p0f..."
        apt-get install -y p0f 2>/dev/null || {
            warn "No se pudo instalar p0f"
            info "Compilando desde fuente..."
            cd /tmp
            git clone https://github.com/p0f/p0f.git 2>/dev/null
            cd p0f && make 2>/dev/null
            cp p0f /usr/local/bin/
            cd -
        }
    fi
    
    info "Iniciando p0f en modo pasivo (30 segundos)..."
    
    # Ejecutar p0f en modo pasivo
    timeout 30 p0f -i eth0 -o "$P0F_LOG.tmp" 2>/dev/null || true
    
    if [ -f "$P0F_LOG.tmp" ]; then
        # Parsear resultados
        echo -e "\n${YELLOW}=== DISPOSITIVOS DETECTADOS POR p0f ===${NC}"
        
        # Extraer información relevante
        grep -E "ip=|os=|link=" "$P0F_LOG.tmp" 2>/dev/null | \
            awk -F'[][]' '{print $2}' | \
            sort | uniq | \
            tee -a "$P0F_LOG"
        
        rm -f "$P0F_LOG.tmp"
    else
        warn "p0f no capturó tráfico (¿tráfico insuficiente?)"
    fi
}

# ============================================================
# 3. DETECCIÓN DE USER-AGENT SOSPECHOSOS
# ============================================================
detect_user_agents() {
    echo -e "\n${CYAN}=== DETECCIÓN DE USER-AGENTS ===${NC}"
    info="Buscando User-Agents en tráfico HTTP..."
    echo ""
    
    # Capturar tráfico HTTP
    info "Capturando tráfico HTTP (10 segundos)..."
    timeout 10 tcpdump -i eth0 -n port 80 -A 2>/dev/null | \
        grep -oP 'User-Agent: \K.*' | \
        sort | uniq -c | sort -rn | \
        tee -a "$USERAGENT_LOG" || warn "No se capturaron User-Agents"
    
    # Buscar User-Agents sospechosos (scripts automatizados)
    echo ""
    info "Buscando User-Agents sospechosos..."
    
    suspicious_patterns=(
        "python"
        "curl"
        "wget"
        "perl"
        "ruby"
        "go-http"
        "java"
        "axios"
        "requests"
        "scrapy"
        "bot"
        "spider"
        "crawler"
    )
    
    for pattern in "${suspicious_patterns[@]}"; do
        if grep -qi "$pattern" "$USERAGENT_LOG" 2>/dev/null; then
            warn "User-Agent sospechoso detectado: $pattern"
            grep -i "$pattern" "$USERAGENT_LOG"
        fi
    done
}

# ============================================================
# 4. ANÁLISIS DE COMPORTAMIENTO
# ============================================================
analyze_behavior() {
    echo -e "\n${CYAN}=== ANÁLISIS DE COMPORTAMIENTO ===${NC}"
    info="Analizando patrones de tráfico..."
    echo ""
    
    # Analizar patrones de conexión
    info "Top 10 IPs por volumen de conexión:"
    netstat -tn 2>/dev/null | awk '{print $5}' | cut -d: -f1 | sort | uniq -c | sort -rn | head -10
    
    echo ""
    info "Conexiones activas por puerto:"
    netstat -tn 2>/dev/null | awk '{print $4}' | cut -d: -f2 | sort | uniq -c | sort -rn | head -10
    
    # Detectar escaneo de puertos
    echo ""
    info "Buscando patrones de escaneo..."
    ss -tn state established 2>/dev/null | \
        awk '{print $5}' | cut -d: -f1 | sort | uniq -c | sort -rn | \
        awk '$1 > 10 {print "Posible escaneo:", $2, "-", $1, "conexiones"}'
}

# ============================================================
# 5. CAPTURAR FIRMAS TLS COMPLETAS
# ============================================================
capture_tls_fingerprints() {
    echo -e "\n${CYAN}=== CAPTURA DE FIRMAS TLS ===${NC}"
    info="Capturando ClientHello para fingerprinting..."
    echo ""
    
    # Usar tshark para extraer extensiones TLS
    if command -v tshark &> /dev/null; then
        info "Extrayendo extensiones TLS con tshark..."
        
        # Capturar 30 segundos de tráfico TLS
        timeout 30 tshark -i eth0 -Y "tls.handshake.type == 1" -T fields \
            -e ip.src \
            -e tls.handshake.extensions_server_name \
            -e tls.handshake.signature_algorithms \
            -e tls.handshake.supported_versions \
            2>/dev/null | tee -a "$LOG_DIR/tls-extensions.log" || warn "tshark no disponible"
    else
        warn "tshark no está instalado"
        info "Instalar con: apt install tshark"
    fi
}

# ============================================================
# 6. BASE DE DATOS DE FINGERPRINTS CONOCIDOS
# ============================================================
create_fingerprint_db() {
    echo -e "\n${CYAN}=== CREANDO BASE DE DATOS DE FINGERPRINTS ===${NC}"
    
    DB_FILE="$LOG_DIR/fingerprint-db.json"
    
    cat > "$DB_FILE" << 'EOF'
{
  "known_fingerprints": [],
  "suspicious_fingerprints": [],
  "blocked_fingerprints": [],
  "last_updated": ""
}
EOF
    
    log "Base de datos de fingerprints creada en $DB_FILE"
}

# ============================================================
# 7. REPORTES
# ============================================================
generate_report() {
    echo -e "\n${CYAN}=== REPORTE DE FINGERPRINTING ===${NC}"
    
    REPORT_FILE="$LOG_DIR/report-$(date '+%Y%m%d-%H%M%S').txt"
    
    {
        echo "=========================================="
        echo "REPORTE DE FINGERPRINTING TLS/OS"
        echo "Fecha: $(date)"
        echo "=========================================="
        
        echo -e "\n--- HASHES JA3 CAPTURADOS ---"
        cat "$JA3_LOG" 2>/dev/null || echo "Sin datos"
        
        echo -e "\n--- FINGERPRINTS OS (p0f) ---"
        cat "$P0F_LOG" 2>/dev/null || echo "Sin datos"
        
        echo -e "\n--- USER-AGENTS DETECTADOS ---"
        cat "$USERAGENT_LOG" 2>/dev/null || echo "Sin datos"
        
        echo -e "\n--- EXTENSIONES TLS ---"
        cat "$LOG_DIR/tls-extensions.log" 2>/dev/null || echo "Sin datos"
        
    } > "$REPORT_FILE"
    
    log "Reporte generado: $REPORT_FILE"
    cat "$REPORT_FILE"
}

# ============================================================
# MAIN
# ============================================================
echo -e "${CYAN}"
echo "╔═══════════════════════════════════════════════════════╗"
echo "║   TLS/OS FINGERPRINTING - Identificación Avanzada    ║"
echo "╚═══════════════════════════════════════════════════════╝"
echo -e "${NC}"

case "${1:-help}" in
    ja3)
        capture_ja3
        ;;
    p0f)
        analyze_p0f
        ;;
    useragent)
        detect_user_agents
        ;;
    behavior)
        analyze_behavior
        ;;
    tls)
        capture_tls_fingerprints
        ;;
    init-db)
        create_fingerprint_db
        ;;
    report)
        generate_report
        ;;
    all)
        capture_ja3
        analyze_p0f
        detect_user_agents
        analyze_behavior
        capture_tls_fingerprints
        ;;
    help|*)
        echo "Uso: $0 [comando]"
        echo ""
        echo "Comandos:"
        echo "  ja3        - Capturar hashes JA3 (TLS fingerprinting)"
        echo "  p0f        - Análisis OS fingerprinting pasivo"
        echo "  useragent  - Detectar User-Agents sospechosos"
        echo "  behavior   - Análisis de comportamiento de red"
        echo "  tls        - Capturar firmas TLS completas"
        echo "  init-db    - Inicializar base de datos de fingerprints"
        echo "  report     - Generar reporte completo"
        echo "  all        - Ejecutar todos los análisis"
        ;;
esac
