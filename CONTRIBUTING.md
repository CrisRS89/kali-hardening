# Contribuir a Kali Linux Hardening

¡Gracias por tu interés en contribuir!

## Cómo Contribuir

### Reportar Bugs
1. Abre un [issue](https://github.com/CrisRS89/kali-hardening/issues)
2. Incluye:
   - Distribución de Linux usada
   - Versión del kernel (`uname -r`)
   - Pasos para reproducir
   - Logs de error

### Sugerir Mejoras
1. Abre un issue con la etiqueta `enhancement`
2. Describe la mejora y su uso

### Enviar Código
1. Fork el repositorio
2. Crea una rama (`git checkout -b feature/nueva-feature`)
3. Haz tus cambios
4. Prueba en tu distribución
5. Commit (`git commit -m 'Agregar nueva feature'`)
6. Push (`git push origin feature/nueva-feature`)
7. Abre un Pull Request

## Guía de Código

### Scripts Bash
- Usar `set -e` al inicio
- Incluir comentarios explicativos
- Manejar errores graceful
- Soportar múltiples distros cuando sea posible

### Nuevos Scripts
- Colocar en `scripts/`
- Agregar al `install.sh`
- Actualizar `README.md`
- Incluir uso en los comentarios

### Testing
Probar en al menos:
- Kali Linux
- Ubuntu/Debian
- Arch Linux (si es posible)

## Preguntas?
Abre un issue con la etiqueta `question`.
