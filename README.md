# Kali Linux Hardening

Hardening automatizado de red y monitoreo para Kali Linux. Firewall, IDS, anti-rootkits, auditoría, dashboard gráfico, lista blanca de dispositivos y contramedidas activas.

## Instalación

```bash
git clone https://github.com/CrisRS89/kali-hardening.git
cd kali-hardening
sudo bash install.sh
```

## Componentes Principales

| Herramienta | Función |
|---|---|
| **nftables** | Firewall con lista blanca, anti-spoofing, bloqueo dinámico |
| **Suricata** | IDS/IPS con +50.000 reglas y JA3 fingerprinting |
| **fail2ban** | Bloqueo de IPs por intentos fallidos SSH |
| **CrowdSec** | IPS colaborativo con blocklists |
| **auditd** | Monitoreo de cambios en archivos críticos |
| **AppArmor** | Control de acceso obligatorio por perfiles |
| **rkhunter** | Escaneo diario de rootkits |
| **Grafana + Loki** | Dashboard web unificado de logs |
| **ARPwatch** | Monitoreo continuo de cambios ARP |
| **MAC Randomization** | Aleatorización automática de MAC (NetworkManager) |

---

## LISTA BLANCA (Enfoque Principal)

Solo dispositivos autorizados pueden acceder a la red:

```bash
# Ver dispositivos autorizados
sudo whitelist-manager list

# Autorizar nuevo dispositivo
sudo whitelist-manager add 192.168.1.100 aa:bb:cc:dd:ee:ff "Mi PC"

# Revocar acceso
sudo whitelist-manager remove 192.168.1.100

# Auto-descubrir dispositivos en red
sudo whitelist-manager discover

# Ver estado
sudo whitelist-manager status
```

---

## DETECCIÓN Y MONITOREO

```bash
# Resumen de seguridad
sudo secwatch

# Monitoreo en tiempo real
sudo secwatch-live

# Detectar ARP spoofing
sudo check-arp

# Sistema completo de defensa
sudo network-defender monitor          # Monitorear ARP
sudo network-defender scan             # Escaneo completo de red
sudo network-defender detect-dhcp      # Detectar DHCP rogue
sudo network-defender block-mac XX:XX:XX:XX:XX:XX  # Bloquear MAC
sudo network-defender scan-suspect <IP>  # Escanear sospechoso

# Monitoreo ARP continuo
sudo arp-monitor eth0 5

# Detección DHCP rogue
sudo dhcp-rogue-detect eth0

# Fingerprinting de red
sudo network-fingerprint eth0

# MAC flapping detection
sudo mac-flapping-detect detect
sudo mac-flapping-detect monitor
```

---

## FINGERPRINTING TLS/OS

Identifica dispositivos por huellas digitales de aplicación:

```bash
# Capturar hashes JA3 (TLS fingerprinting)
sudo tls-fingerprint ja3

# OS fingerprinting pasivo con p0f
sudo tls-fingerprint p0f

# Detectar User-Agents sospechosos
sudo tls-fingerprint useragent

# Análisis de comportamiento
sudo tls-fingerprint behavior

# Ejecutar todos los análisis
sudo tls-fingerprint all
```

---

## CONTRAMEDIDAS ACTIVAS

**⚠️ Usar con precaución - Estas herramientas son ofensivas**

```bash
# Cortar conexión del atacante vía ARP spoofing
sudo active-defense arp-cut <IP_atacante>

# Congelar escáner del atacante (TARPIT)
sudo active-defense tarpit <IP_atacante>

# Crear agujero negro total
sudo active-defense blackhole <IP_atacante>

# Expulsar del Wi-Fi (desautenticación)
sudo active-defense wifi-deauth <MAC_atacante>

# Bombardeo de paquetes
sudo active-defense inferno <IP_atacante>

# Modo fantasma (invisibilidad total)
sudo active-defense ghost

# Detener todas las contramedidas
sudo active-defense stop
```

---

## OCULTAMIENTO

```bash
# Ocultar de ping (ICMP)
sudo sysctl -w net.ipv4.icmp_echo_ignore_all=1
sudo sysctl -w net.ipv4.icmp_echo_ignore_broadcasts=1

# MAC randomization (automático tras instalación)
# Configurado en /etc/NetworkManager/conf.d/00-macrandom.conf

# Restaurar respuestas ICMP
sudo sysctl -w net.ipv4.icmp_echo_ignore_all=0
```

---

## Dashboard

Accedé a Grafana en `http://localhost:3000` (usuario: `admin`, contraseña a configurar).

## Estructura

```
kali-hardening/
├── install.sh                    # Script de instalación automatizada
├── README.md
├── nftables/
│   └── nftables.conf             # Firewall con lista blanca
├── suricata/
│   ├── suricata.yaml             # IDS/IPS con JA3
│   └── threshold.config          # Supresión de reglas ruidosas
├── auditd/
│   └── hardening.rules           # Reglas de auditoría
├── sysctl/
│   └── sysctl.conf               # Parámetros de hardening
├── scripts/
│   ├── secwatch                  # Panel de monitoreo
│   ├── secwatch-live             # Monitoreo en tiempo real
│   ├── check-arp                 # Detección de ARP spoofing
│   ├── network-defender.sh       # Sistema de defensa completo
│   ├── arp-monitor.sh            # Monitoreo continuo ARP
│   ├── dhcp-rogue-detect.sh      # Detección DHCP rogue
│   ├── network-fingerprint.sh    # Fingerprinting de red
│   ├── whitelist-manager.sh      # Gestión de lista blanca
│   ├── tls-fingerprint.sh        # JA3/p0f/User-Agent
│   ├── mac-flapping-detect.sh    # Detección MAC flapping
│   └── active-defense.sh         # Contramedidas activas
├── grafana-datasource.yaml       # Datasource Loki
├── grafana-dashboard.json        # Dashboard de seguridad
└── CHANGES.md                    # Documentación de cambios
```

## Protecciones Implementadas

| Tipo de Ataque | Protección | Comando |
|----------------|------------|---------|
| MAC Spoofing | Lista blanca + bloqueo dinámico | `whitelist-manager` |
| ARP Spoofing | ARP estática + monitoreo | `check-arp`, `arp-monitor` |
| ARP Flood | Rate limiting | nftables |
| DHCP Starvation | Rate limiting DHCP | nftables |
| DHCP Rogue Server | Detección y bloqueo | `dhcp-rogue-detect` |
| IP Spoofing | Anti-spoofing en raw | nftables |
| Port Scanning | TARPIT + rate limiting | `active-defense tarpit` |
| TLS Fingerprinting | JA3 hashes | `tls-fingerprint ja3` |
| OS Fingerprinting | p0f pasivo | `tls-fingerprint p0f` |
| MAC Flapping | Detección automática | `mac-flapping-detect` |
| Identificación en Red | Modo fantasma | `active-defense ghost` |

## Logs

- `/var/log/network-defense/` - Defensa general
- `/var/log/arp-monitor/` - Monitoreo ARP
- `/var/log/dhcp-rogue/` - DHCP rogue
- `/var/log/network-fingerprint/` - Fingerprinting
- `/var/log/tls-fingerprint/` - TLS/JA3/p0f
- `/var/log/mac-flapping/` - MAC flapping
- `/var/log/active-defense/` - Contramedidas
- `/var/log/whitelist-manager/` - Lista blanca
