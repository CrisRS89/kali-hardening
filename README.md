<div align="center">

# 🛡️ Kali Linux Hardening

### Sistema Completo de Defensa de Red

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Linux](https://img.shields.io/badge/Linux-Kali%20|%20Debian%20|%20Ubuntu%20|%20Arch-blue.svg)](https://www.linux.org/)
[![Shell](https://img.shields.io/badge/Shell-Bash-green.svg)](https://www.gnu.org/software/bash/)
[![Firewall](https://img.shields.io/badge/Firewall-nftables-orange.svg)](https://www.netfilter.org/projects/nftables/)
[![IDS](https://img.shields.io/badge/IDS-Suricata-red.svg)](https://suricata.io/)

**Protección multicapa contra MAC spoofing, ARP spoofing, DHCP starvation y más.**

[Instalación](#-instalación) • [Características](#-características) • [Uso](#-uso) • [Scripts](#-scripts) • [Contribuir](#-contribuir)

</div>

---

## 📋 Tabla de Contenidos

- [Descripción](#-descripción)
- [Características](#-características)
- [Instalación](#-instalación)
- [Uso Rápido](#-uso-rápido)
- [Scripts Detallados](#-scripts-detallados)
- [Protecciones](#-protecciones-implementadas)
- [Logs y Monitoreo](#-logs-y-monitoreo)
- [Contribuir](#-contribuir)
- [Licencia](#-licencia)

---

## 🎯 Descripción

**Kali Linux Hardening** es un sistema completo de defensa de red diseñado para proteger contra ataques de Capa 2 y Capa 3 en redes locales.

### El Problema que Resuelve

¿Alguien en tu red está:
- 🔄 Rotando su dirección MAC para evadir bloqueos?
- 🌐 Cambiando su IP frecuentemente?
- 🚫 Denegando tu acceso a internet?
- 🎭 Suplantando tu identidad en la red?

**Esta herramienta te protege contra todos esos ataques.**

### El Enfoque: Lista Blanca

En lugar de intentar bloquear al atacante (que siempre encuentra formas de evadir), implementamos un enfoque de **Lista Blanca**: solo los dispositivos que tú autorizas pueden acceder a la red.

---

## ✨ Características

### 🛡️ Defensa en Capas

| Capa | Protección | Herramienta |
|------|------------|-------------|
| **Física** | Detección de puerto switch | mac-flapping-detect |
| **Enlace** | Lista blanca MAC + ARP estática | whitelist-manager |
| **Red** | Anti-spoofing + Rate limiting | nftables |
| **Transporte** | TLS fingerprinting (JA3) | tls-fingerprint |
| **Aplicación** | User-Agent detection | tls-fingerprint |

### 🔍 Detección Avanzada

- **JA3 Fingerprinting**: Identifica al atacante aunque cambie IP y MAC (firma TLS única)
- **p0f**: OS fingerprinting pasivo por patrones TCP/IP
- **MAC Flapping**: Detecta el puerto físico del switch donde está conectado el intruso
- **ARPwatch**: Monitoreo continuo de cambios en la tabla ARP

### ⚔️ Contramedidas Activas

- **ARP Spoofing Ofensivo**: Cortar conexión del atacante
- **TARPIT**: Congelar sus escáneres
- **Blackhole**: Crear agujero negro total
- **WiFi Deauth**: Expulsar del Wi-Fi
- **Ghost Mode**: Invisibilidad total en la red

### 🌍 Multi-Distribución

Compatible con:
- Kali Linux
- Debian / Ubuntu / Linux Mint
- Arch Linux / Manjaro
- Fedora / CentOS / RHEL
- Windows (WSL2)

---

## 🚀 Instalación

### Requisitos Previos

```bash
# Dependencias básicas (se instalan automáticamente)
sudo apt update
sudo apt install -y git curl wget
```

### Instalación Rápida

```bash
# Clonar repositorio
git clone https://github.com/CrisRS89/kali-hardening.git
cd kali-hardening

# Ejecutar instalador (detecta tu distro automáticamente)
sudo bash install.sh
```

### Instalación por Distribución

<details>
<summary><b>Kali Linux / Debian / Ubuntu</b></summary>

```bash
sudo apt update && sudo apt install -y git
git clone https://github.com/CrisRS89/kali-hardening.git
cd kali-hardening
sudo bash install.sh
```
</details>

<details>
<summary><b>Arch Linux / Manjaro</b></summary>

```bash
sudo pacman -S git base-devel
git clone https://github.com/CrisRS89/kali-hardening.git
cd kali-hardening
sudo bash install.sh
```
</details>

<details>
<summary><b>Fedora / CentOS / RHEL</b></summary>

```bash
sudo dnf install -y git
git clone https://github.com/CrisRS89/kali-hardening.git
cd kali-hardening
sudo bash install.sh
```
</details>

<details>
<summary><b>Windows (WSL2)</b></summary>

```powershell
# Instalar WSL2 con Ubuntu
wsl --install -d Ubuntu

# Dentro de WSL2
sudo apt update && sudo apt install -y git
git clone https://github.com/CrisRS89/kali-hardening.git
cd kali-hardening
sudo bash install.sh
```
</details>

---

## ⚡ Uso Rápido

### Primeros Pasos

```bash
# 1. Ver estado del sistema
sudo secwatch

# 2. Inicializar lista blanca con tus dispositivos
sudo whitelist-manager discover

# 3. Ver dispositivos autorizados
sudo whitelist-manager list
```

### Comandos Esenciales

```bash
# 🔍 Detección
sudo network-defender scan          # Escaneo completo de red
sudo tls-fingerprint all            # Fingerprinting TLS/OS
sudo mac-flapping-detect detect     # Detectar MAC spoofing

# 🛡️ Protección
sudo active-defense ghost           # Modo fantasma (invisibilidad)
sudo whitelist-manager list         # Ver lista blanca

# ⚔️ Contraataque (usar con precaución)
sudo active-defense arp-cut <IP>    # Cortar conexión del atacante
sudo active-defense tarpit <IP>     # Congelar escáner
```

---

## 📚 Scripts Detallados

### 📋 whitelist-manager - Gestión de Lista Blanca

**El componente principal del sistema.**

```bash
# Inicializar con gateway y host local
sudo whitelist-manager init

# Agregar dispositivo autorizado
sudo whitelist-manager add 192.168.1.100 aa:bb:cc:dd:ee:ff "Mi PC"

# Remover dispositivo
sudo whitelist-manager remove 192.168.1.100

# Auto-descubrir dispositivos en red
sudo whitelist-manager discover

# Ver estado
sudo whitelist-manager status
```

### 🔍 tls-fingerprint - Identificación Avanzada

**Identifica al atacante aunque cambie IP y MAC.**

```bash
# Capturar hashes JA3 (firma TLS única por navegador/herramienta)
sudo tls-fingerprint ja3

# OS fingerprinting pasivo con p0f
sudo tls-fingerprint p0f

# Detectar User-Agents sospechosos (scripts automatizados)
sudo tls-fingerprint useragent

# Ejecutar todos los análisis
sudo tls-fingerprint all
```

### 🎯 active-defense - Contramedidas Activas

**⚠️ Herramientas ofensivas - Usar solo dentro de tu red local.**

```bash
# Modo fantasma (invisibilidad total)
sudo active-defense ghost

# Cortar conexión del atacante
sudo active-defense arp-cut 192.168.1.50

# Congelar escáner del atacante
sudo active-defense tarpit 192.168.1.50

# Crear agujero negro
sudo active-defense blackhole 192.168.1.50

# Expulsar del Wi-Fi
sudo active-defense wifi-deauth AA:BB:CC:DD:EE:FF

# Detener todas las contramedidas
sudo active-defense stop
```

### 🔎 mac-flapping-detect - Detección Física

**Detecta el puerto del switch donde está conectado el intruso.**

```bash
# Detección básica
sudo mac-flapping-detect detect

# Monitoreo continuo con alertas
sudo mac-flapping-detect monitor

# Ver historial de cambios
sudo mac-flapping-detect history
```

### 📡 network-defender - Defensa Completa

```bash
# Monitorear ARP
sudo network-defender monitor

# Escaneo completo
sudo network-defender scan

# Detectar DHCP rogue
sudo network-defender detect-dhcp

# Bloquear MAC específica
sudo network-defender block-mac AA:BB:CC:DD:EE:FF
```

### 🌐 arp-monitor - Monitoreo Continuo

```bash
# Monitoreo con intervalo de 5 segundos
sudo arp-monitor eth0 5

# Monitoreo en background
nohup sudo arp-monitor eth0 5 &
```

---

## 🛡️ Protecciones Implementadas

| Tipo de Ataque | Protección | Script |
|----------------|------------|--------|
| MAC Spoofing | Lista blanca + bloqueo dinámico | `whitelist-manager` |
| ARP Spoofing | ARP estática + monitoreo | `arp-monitor` |
| ARP Flood | Rate limiting (5 paquetes/seg) | `nftables` |
| DHCP Starvation | Rate limiting DHCP | `nftables` |
| DHCP Rogue Server | Detección y bloqueo | `dhcp-rogue-detect` |
| IP Spoofing | Anti-spoofing completo | `nftables` |
| Port Scanning | TARPIT + rate limiting | `active-defense` |
| TLS Fingerprinting | JA3 hashes | `tls-fingerprint` |
| OS Fingerprinting | p0f pasivo | `tls-fingerprint` |
| MAC Flapping | Detección automática | `mac-flapping-detect` |
| WiFi Attacks | Desautenticación | `active-defense` |
| Identificación | Modo fantasma | `active-defense ghost` |

---

## 📊 Logs y Monitoreo

### Ubicación de Logs

```
/var/log/
├── network-defense/      # Logs generales de defensa
├── arp-monitor/          # Monitoreo ARP
├── dhcp-rogue/           # Detección DHCP rogue
├── network-fingerprint/  # Fingerprinting de red
├── tls-fingerprint/      # TLS/JA3/p0f
├── mac-flapping/         # MAC flapping
├── active-defense/       # Contramedidas
└── whitelist-manager/    # Lista blanca
```

### Dashboard Grafana

Accedé a `http://localhost:3000` (usuario: `admin`)

---

## 🤝 Contribuir

Las contribuciones son bienvenidas. Por favor:

1. Fork el proyecto
2. Crea una rama para tu feature (`git checkout -b feature/nueva-feature`)
3. Commit tus cambios (`git commit -m 'Agregar nueva feature'`)
4. Push a la rama (`git push origin feature/nueva-feature`)
5. Abre un Pull Request

---

## 📄 Licencia

Este proyecto está bajo la Licencia MIT - ver el archivo [LICENSE](LICENSE) para detalles.

---

## 🙏 Agradecimientos

- [Suricata](https://suricata.io/) - IDS/IPS
- [nftables](https://www.netfilter.org/projects/nftables/) - Firewall
- [p0f](https://rozman.com/p0f/) - OS Fingerprinting
- [arpwatch](https://ee.lbl.gov/) - Monitoreo ARP
- [aircrack-ng](https://www.aircrack-ng.org/) - Análisis Wi-Fi

---

<div align="center">

**¿Encontraste un bug?** [Abrí un issue](https://github.com/CrisRS89/kali-hardening/issues)

**¿Necesitas ayuda?** Revisa la [documentación](https://github.com/CrisRS89/kali-hardening/wiki)

</div>
