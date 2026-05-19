# DRIVER ROADMAP - LuisAlbertoOS

Este documento detalla el estado de cada familia de drivers del sistema.

## Leyenda de estado (10 niveles)
- `X` = completado al 100% (release-ready)
- `#` = casi cerrado (99%, faltan pruebas/regresión final)
- `*` = cerca de terminarse (fase final, faltan detalles de cierre)
- `O` = fase media (funcionalidad parcial, pruebas básicas, falta cobertura)
- `+` = progreso sólido (después de `&`, antes de `O`)
- `&` = etapa intermedia temprana (después de `-`, antes de `+`)
- `-` = muy temprano (stub/probe inicial, sin ruta completa)
- `\` = semilla técnica inicial (después de `/`, antes de `-`)
- `/` = pre-inicio (más temprano que `.`; idea/base preliminar)
- `.` = sin iniciar (caja vacía)

Orden de avance:
`.` -> `/` -> `\` -> `-` -> `&` -> `+` -> `O` -> `*` -> `#` -> `X`

---

## 1) Red (NIC / Stack L2-L4)

| Familia / Chipset | Estado | Detección PCI | Init HW | TX/RX básico | Integración shell (`activate/devices`) | Notas |
|---|---|---|---|---|---|---|
| Realtek RTL8139 | # | X | O | O | X | Driver principal de red, casi cerrado; pendiente regresión final. |
| Intel PRO/1000 (base E1000) | O | O | O | - | X | Ruta existente de activación y pruebas de desarrollo. |
| Intel 82540EM | & | - | - | . | - | Stub funcional inicial; en transición hacia fase media. |
| Intel 82545EM | & | - | - | . | - | Stub funcional inicial; en transición hacia fase media. |
| Intel 82546EB | & | - | - | . | - | Stub funcional inicial; en transición hacia fase media. |
| Intel E1000e ICH8 | - | - | - | . | - | Variante declarada para futura implementación. |
| Intel E1000e ICH9 | - | - | - | . | - | Variante declarada para futura implementación. |
| Intel E1000e ICH10 | - | - | - | . | - | Variante declarada para futura implementación. |
| Intel I217 | - | - | - | . | - | Variante declarada para futura implementación. |
| Intel I218 | - | - | - | . | - | Variante declarada para futura implementación. |
| Intel I219 | - | - | - | . | - | Variante declarada para futura implementación. |
| Realtek RTL8169 | & | - | - | . | O | Activación y reporte conectados; pendiente ruta I/O real. |
| Realtek RTL8168 | - | - | - | . | - | Stub de familia RTL pendiente de integrar al comando. |
| Realtek RTL8111 | - | - | - | . | - | Stub de familia RTL pendiente de integrar al comando. |
| Realtek RTL8110 | - | - | - | . | - | Stub de familia RTL pendiente de integrar al comando. |
| Realtek RTL8101 | / | . | . | . | . | Pre-inicio documentado, aún sin integración. |
| Realtek RTL8100 | / | . | . | . | . | Pre-inicio documentado, aún sin integración. |
| Realtek RTL8125 (2.5GbE) | \ | . | . | . | . | Semilla técnica iniciada; aún sin integración shell. |
| AMD PCnet AM79C970/971/972/973/975 | - | - | - | . | O | Alias `pcnet` + stubs de familia. |

### Estado general de red
- Subsistema operativo con enfoque actual en RTL8139.
- Intel/Realtek/PCnet adicionales están en fase de expansión por stubs y aliases.

---

## 2) Audio

| Familia / Chipset | Estado | Detección | Init HW | Reproducción básica | Integración shell | Notas |
|---|---|---|---|---|---|---|
| AC97 | + | O | O | O | X | Muy avanzado en uso base; transición a fase de cierre. |
| SB16 | O | O | O | - | X | Soporte de prueba heredado. |
| Intel HD Audio (HDA) | + | - | - | . | O | Activación integrada y cercano a fase media real. |

### Estado general de audio
- AC97 y SB16 son la base de pruebas.
- HDA en etapa inicial (estructura y presencia).

---

## 3) Almacenamiento (block)

| Familia / Controlador | Estado | Detección | Lectura | Escritura | Integración FS | Notas |
|---|---|---|---|---|---|---|
| ATA PIO | O | O | O | O | O | Base del backend tradicional junto a RAM FS. |
| RAM FS | # | X | X | X | X | Casi cerrado; falta validación final de estrés y regresión. |
| Floppy | O | O | O | O | O | Integrado con rutas A:/ y comandos read/write. |
| CDROM ATAPI básico | O | O | O | . | O | Usado en modo lectura para D:/. |
| SATA AHCI | & | - | - | . | - | Presencia activable desde shell; falta lectura real. |
| NVMe PCIe | & | - | - | . | - | Presencia activable desde shell; falta identify/lectura. |
| Intel ICH6 IDE | - | - | - | . | - | Placeholder de compatibilidad legacy. |
| Intel PIIX3 IDE | - | - | - | . | - | Placeholder de compatibilidad legacy. |
| Intel PIIX4 IDE | - | - | - | . | - | Placeholder de compatibilidad legacy. |

### Estado general de almacenamiento
- Camino funcional actual: RAM FS + ATA/Floppy/CDROM.
- AHCI/NVMe/IDE legacy nuevos en fase de arquitectura y descubrimiento.

---

## 4) USB / buses host

| Controlador USB | Estado | Detección PCI | Init HC | Enumeración dispositivos | Driver de clase | Notas |
|---|---|---|---|---|---|---|
| USB 1.0 UHCI | \ | - | - | . | . | Semilla técnica inicial del controlador host. |
| USB 2.0 EHCI | - | - | - | . | . | Stub inicial solamente. |
| USB 3.0 xHCI | & | - | - | . | . | Integración temprana en progreso. |

### Estado general USB
- Sin stack USB activo todavía; solo placeholders para comenzar implementación.

---

## 5) Video / Entrada

| Subsistema | Estado | Inicialización | Uso en shell/desktop | Notas |
|---|---|---|---|---|
| VGA básico | O | O | O | Base de interfaz visual actual. |
| Teclado PS/2 | O | O | X | Entrada principal de comandos. |
| Mouse PS/2 | O | O | O | Contadores/estado disponibles en shell. |

---

## 6) Integración actual en comandos del sistema

| Comando | Cobertura actual |
|---|---|
| `devices` | Reporta estado de FS, red principal, audio principal, ATA, floppy, CDROM, SATA. |
| `activate` | Activa/probea `rtl8139`, `e1000`, `ac97`, `sb16`, `ata`, `floppy`, `cdrom`, `sata`, `ram` y aliases (`rtl8169`, `pcnet`, `intelhda`). |
| `data` | Muestra diagnóstico global con campos de dispositivos y subsistemas base. |

---

## 7) Priorización recomendada (siguientes fases)

### Fase A (corto plazo)
1. Consolidar `e1000` real (TX/RX estable) y validar en `net`.
2. Integrar RTL8169 real reutilizando estructura PCI/net actual.
3. Completar Intel HDA mínimo (init + tono/beep de validación).

### Fase B (medio plazo)
1. Implementar AHCI lectura básica de sector.
2. Añadir enumeración USB mínima (UHCI/EHCI/xHCI: detect + reset + puertos).
3. Mejorar tabla `devices` para incluir nuevas familias de stubs.

### Fase C (largo plazo)
1. NVMe cola admin + identify + lectura bloque.
2. Red 2.5GbE (RTL8125) y variantes Intel I217/I218/I219.
3. Pruebas cruzadas completas en QEMU/Bochs/VirtualBox.

---

## 8) Inventario de archivos de drivers (actual)

### Red
- `drivers/rtl8139.lasys`
- `drivers/e1000.lasys`
- `drivers/rtl8169.lasys`
- `drivers/pcnet.lasys`
- `drivers/rtl_net_variants.lasys`
- `drivers/intel_pro1000_variants.lasys`
- `drivers/pcnet_variants.lasys`

### Audio
- `drivers/ac97.lasys`
- `drivers/sb16.lasys`
- `drivers/intelhda.lasys`

### Almacenamiento / Bus
- `drivers/ata.lasys`
- `drivers/storage_extra.lasys`
- `drivers/storage_bus_stubs.lasys`

### Entrada / Video
- `drivers/keyboard.lasys`
- `drivers/mouse_ps2.lasys`
- `drivers/vga_image.lasys`

---

## 9) Criterio para marcar un driver en `X`
Un driver pasa a `X` únicamente si cumple:
1. Detección real del hardware objetivo.
2. Inicialización estable sin colgar el sistema.
3. Operación mínima end-to-end (I/O real).
4. Exposición de estado en shell (`devices`/`data`) o API equivalente.
5. Prueba reproducible documentada.


---

## 10) Avance de esta iteración (progreso incremental)

Para seguir avanzando hacia el objetivo final (todo en `X`), en esta iteración se deja trazado un plan ejecutable por hitos y definición de “Done” por bloque técnico.

### Hito R1 - Red base endurecida (RTL8139 + E1000)
- [ ] Unificar capa de RX/TX entre RTL8139 y E1000.
- [ ] Añadir pruebas de smoke para `net up`, `net send`, `net recv`.
- [ ] Registrar errores de ring/buffer en `data`/`devices`.
- **Salida esperada:** RTL8139 y E1000 pasan de `O` a `X` al cumplir I/O real + estabilidad.

### Hito R2 - Variantes de red (Intel/Realtek/PCnet)
- [ ] Detectar IDs PCI por familia (tabla de IDs por variante).
- [ ] Enlazar aliases `rtl8169` y `pcnet` a init real, no solo wrapper.
- [ ] Exponer estado por variante en `devices`.
- **Salida esperada:** variantes principales pasan de `-` a `O`.

### Hito A1 - Audio moderno
- [ ] Mantener AC97/SB16 en regresión cero.
- [ ] Subir Intel HDA de stub a init funcional mínimo.
- [ ] Agregar prueba de tono/PCM corto para validación de salida.
- **Salida esperada:** HDA pasa de `-` a `O`.

### Hito S1 - Almacenamiento moderno
- [ ] AHCI: detectar controlador + lectura LBA mínima.
- [ ] NVMe: `identify` + lectura bloque mínima.
- [ ] Telemetría de errores de I/O en shell.
- **Salida esperada:** AHCI/NVMe pasan de `-` a `O`.

### Hito U1 - USB host
- [ ] UHCI/EHCI/xHCI: detección PCI y reset de host controller.
- [ ] Enumeración mínima de puertos.
- [ ] Bitácora de eventos en diagnóstico.
- **Salida esperada:** USB 1.0/2.0/3.0 pasan de `-` a `O`.

## 11) Criterios de promoción de estado

Para evitar marcar `X` sin respaldo, cada salto de estado debe cumplir:
- `.` -> `-`: existe archivo driver + símbolo init/probe + compilación limpia.
- `-` -> `O`: init real parcial + al menos un flujo funcional validable.
- `O` -> `X`: cobertura funcional mínima completa + estabilidad + evidencia reproducible.

## 12) Meta final

Objetivo: converger progresivamente hasta que todo el roadmap quede en `X` con evidencia técnica y pruebas reproducibles por subsistema.
