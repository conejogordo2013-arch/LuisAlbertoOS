# Roadmap técnico LuisAlbertoOS

## Estabilidad
- [x] Handler robusto de page faults/excepciones con pantalla de crash consistente (sin reinicio espontáneo).
- [x] Logging persistente en memoria circular para eventos de IRQ/excepciones/syscalls.
- [x] Comando `lastpanic` enriquecido con últimos eventos y contexto de fallo.
- [x] Guardas/validación contra corrupción de buffers (shell, FS y drivers).

## Filesystem real
- [ ] Implementar FAT12/FAT16 simple **o** evolucionar FS propio con metadata robusta.
- [x] Persistencia real en floppy/ATA (lectura/escritura verificable tras reboot).
- [x] Directorios reales más completos (subdirectorios + metadatos básicos).
- [x] Carga de apps desde FS (no desde sectores fijos).

## Drivers
- [x] PCI scan genérico para inventario de hardware.
- [x] Detección real de BARs para RTL8139/E1000/AC97.
- [x] Teclado por IRQ estable (sin pérdida de input).
- [ ] Timer estable con scheduler real (preempción y latencia controlada).
- [x] Mouse PS/2 funcional.

## Userland
- [ ] ABI simple para aplicaciones.
- [ ] Loader ELF o formato `.laa` documentado y estable.
- [ ] Syscalls para archivos, pantalla, teclado y memoria.
- [ ] Librería estándar pequeña para apps.

## Interfaz
- [x] Shell con historial de comandos.
- [x] Autocompletado.
- [x] Colores.
- [x] TUI básica.
