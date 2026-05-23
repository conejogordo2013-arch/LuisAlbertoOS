# LuisAlbertoOS: GUI + ELF + Desktop (implementación mínima funcional)

## 1) Arquitectura del sistema
- Kernel monolítico en x86 protegido (32-bit).
- ABI por `int 0x80` para apps ELF.
- Render por framebuffer con backbuffer y composición por frame.
- Window manager simple (ventana activa + drag + redraw).

## 2) Layout del proyecto
- `boot/` arranque y salto a kernel.
- `kernel/` núcleo, scheduler, syscalls, GUI, ELF loader.
- `drivers/` teclado, mouse PS/2, video y buses.
- `apps/` aplicaciones binarias (LAA y ELF).
- `build.sh` pipeline de compilación e imagen.

## 3) ELF loader completo
- Parser ELF32 mínimo (`e_ident`, program headers, `PT_LOAD`).
- Carga segmentos a `p_vaddr`.
- Obtiene `e_entry` y ejecuta con stack dedicado.

## 4) Syscalls base (kernel side)
- `1` print_text
- `10` draw_pixel
- `11` draw_rect
- `12` get_key
- `6` exit_process

## 5) Framebuffer driver
- Backbuffer lineal y `present` por copia a VRAM.
- Primitivas: clear, draw_pixel, fill_rect.

## 6) Mouse driver PS/2 con cursor
- PS/2 IRQ12 activo con paquete de 3 bytes.
- Cursor renderizado por compositor GUI existente.

## 7) Window system mínimo
- Ventana con `x,y,w,h,title`.
- Ventana activa y enfoque por click.
- Arrastre con mouse + invalidación/redraw.

## 8) Desktop compositor loop
- `clear -> wallpaper -> windows -> cursor -> present`.
- Frecuencia controlada por loop principal existente.

## 9) Ejemplo de aplicación ELF
- `apps/hello.elf.asm`:
  - Imprime texto.
  - Dibuja rectángulo.
  - Dibuja pixel.
  - Invoca `exit`.

## 10) Script de compilación
- `build.sh` compila boot/kernel/apps.
- Genera `LuisAlbertoOS.img`.
- Incluye compilación de `hello.elf`.
