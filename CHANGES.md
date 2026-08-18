# Mejoras de Defensa de Red - Resumen

## Archivos Agregados/Modificados

### 1. `nftables/nftables.conf` (MODIFICADO)
- **Bloqueo dinámico de MACs**: Conjunto `blocked_macs` para bloquear MACs sospechosas
- **Rate limit ARP**: Limita paquetes ARP a 10/segundo para prevenir ARP flood
- **Protección DHCP**: Rate limit de paquetes DHCP para prevenir starvation
- **Tabla dinámica**: Bloqueo automático de IPs/MACs maliciosos

### 2. `scripts/network-defender.sh` (NUEVO)
Script principal de defensa con las siguientes funciones:
- `monitor`: Monitoreo de tabla ARP
- `scan`: Escaneo completo de red
- `detect-dhcp`: Detección de servidores DHCP rogue
- `block-mac`: Bloqueo manual de MACs
- `scan-suspect`: Escaneo de dispositivos sospechosos
- `continuous`: Monitoreo continuo
- `report`: Generación de reportes de seguridad

### 3. `scripts/arp-monitor.sh` (NUEVO)
- Monitoreo continuo de cambios en tabla ARP
- Detección de MAC spoofing
- Logs en `/var/log/arp-monitor/`
- Alertas en tiempo real

### 4. `scripts/dhcp-rogue-detect.sh` (NUEVO)
- Detección de servidores DHCP no autorizados
- Comparación con gateway legítimo
- Bloqueo automático de rogue DHCP
- Logs en `/var/log/dhcp-rogue/`

### 5. `scripts/network-fingerprint.sh` (NUEVO)
- Fingerprinting completo de dispositivos en red
- Detección de servicios (DHCP, DNS, etc.)
- Verificación de integridad del gateway
- Logs en `/var/log/network-fingerprint/`

### 6. `install.sh` (MODIFICADO)
- Instalación de herramientas adicionales (arpwatch, dsniff, nmap, etc.)
- Copia de los nuevos scripts
- Configuración de ARPwatch
- Creación de directorios de logs

### 7. `README.md` (MODIFICADO)
- Documentación de los nuevos comandos
- Descripción de protecciones contra spoofing
- Estructura actualizada del repositorio

---

## Cómo Usar

### Instalación
```bash
git clone https://github.com/CrisRS89/kali-hardening.git
cd kali-hardening
sudo bash install.sh
```

### Uso Básico
```bash
# Ver estado de seguridad
sudo secwatch

# Monitoreo en tiempo real
sudo secwatch-live

# Verificar ARP spoofing
sudo check-arp
```

### Nuevos Comandos
```bash
# Sistema completo de defensa
sudo network-defender monitor          # Monitorear ARP
sudo network-defender scan             # Escaneo completo
sudo network-defender detect-dhcp      # Detectar DHCP rogue
sudo network-defender block-mac XX:XX:XX:XX:XX:XX  # Bloquear MAC
sudo network-defender scan-suspect <IP>  # Escanear sospechoso
sudo network-defender continuous       # Monitoreo continuo

# Monitoreo ARP continuo
sudo arp-monitor eth0 5  # Interfaz, intervalo en segundos

# Detección DHCP rogue
sudo dhcp-rogue-detect eth0

# Fingerprinting de red
sudo network-fingerprint eth0
```

---

## Logs y Monitoreo

### Ubicación de Logs
- `/var/log/network-defense/` - Logs generales de defensa
- `/var/log/arp-monitor/` - Monitoreo ARP
- `/var/log/dhcp-rogue/` - Detección DHCP rogue
- `/var/log/network-fingerprint/` - Fingerprinting de red

### Monitoreo Continuo
Para monitoreo 24/7, ejecutar en background o configurar cron:
```bash
# Ejecutar monitoreo ARP en background
nohup sudo arp-monitor eth0 5 &

# O configurar cron para escaneos periódicos
sudo crontab -e
# Agregar: */5 * * * * /usr/local/bin/network-defender scan >> /var/log/network-defense/cron.log 2>&1
```

---

## Protecciones Implementadas

| Tipo de Ataque | Protección | Herramienta |
|----------------|------------|-------------|
| MAC Spoofing | Bloqueo dinámico de MACs | nftables + network-defender |
| ARP Spoofing | ARP estática + monitoreo | check-arp + arp-monitor |
| ARP Flood | Rate limiting | nftables |
| DHCP Starvation | Rate limiting DHCP | nftables |
| DHCP Rogue Server | Detección y bloqueo | dhcp-rogue-detect |
| IP Spoofing | Anti-spoofing en raw | nftables |
| Denegación de Internet | Monitoreo y bloqueo | network-defender |

---

## Identificación del Individuo

Para identificar al atacante:

1. **Ejecutar escaneo completo**:
   ```bash
   sudo network-defender scan
   ```

2. **Monitorear cambios ARP**:
   ```bash
   sudo arp-monitor eth0 5
   ```

3. **Buscar MACs que rotan IPs**:
   ```bash
   sudo network-fingerprint eth0
   ```

4. **Revisar logs**:
   ```bash
   sudo network-defender report
   ```

5. **Escaneo de puertos al sospechoso**:
   ```bash
   sudo network-defender scan-suspect <IP_SOSPECHOSA>
   ```

Los logs en `/var/log/network-defense/` y `/var/log/arp-monitor/` contendrán evidencia de los cambios de IP/MAC del atacante.
