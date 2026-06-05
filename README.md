# Kali Linux Hardening

Hardening automatizado de red y monitoreo para Kali Linux. Firewall, IDS, anti-rootkits, auditoría y dashboard gráfico.

## Instalación

```bash
git clone <repo-url>
cd kali-hardening
sudo bash install.sh
```

## Componentes

| Herramienta | Función |
|---|---|
| **nftables** | Firewall con política DROP, anti-spoofing, rate limit SSH |
| **Suricata** | IDS/IPS con +50.000 reglas de detección |
| **fail2ban** | Bloqueo de IPs por intentos fallidos SSH |
| **CrowdSec** | IPS colaborativo con blocklists |
| **auditd** | Monitoreo de cambios en archivos críticos |
| **AppArmor** | Control de acceso obligatorio por perfiles |
| **rkhunter** | Escaneo diario de rootkits |
| **Grafana + Loki** | Dashboard web unificado de logs |
| **ARP estática** | Protección contra ARP spoofing |

## Uso

```bash
sudo secwatch           # Resumen de seguridad
sudo secwatch-live      # Alertas en tiempo real (Suricata + firewall)
sudo check-arp          # Detectar ARP spoofing
```

## Dashboard

Accedé a Grafana en `http://localhost:3000` (usuario: `admin`, contraseña a configurar).

## Estructura

```
kali-hardening/
├── install.sh           # Script de instalación automatizada
├── README.md
├── nftables/
│   └── nftables.conf    # Reglas del firewall
├── suricata/
│   ├── suricata.yaml    # Configuración de Suricata
│   └── threshold.config # Supresión de reglas ruidosas
├── auditd/
│   └── hardening.rules  # Reglas de auditoría
├── sysctl/
│   └── sysctl.conf      # Parámetros de hardening del kernel
├── scripts/
│   ├── secwatch         # Panel de monitoreo
│   ├── secwatch-live    # Monitoreo en tiempo real
│   └── check-arp        # Detección de ARP spoofing
├── grafana-datasource.yaml  # Datasource Loki para Grafana
└── grafana-dashboard.json   # Dashboard de seguridad
```
