# GUI x86_64 módulos NASM

Compilar módulos:

```bash
make -f Makefile.x86_64
```

Módulos:
- `gui/desktop64.asm`: loop de desktop, clear framebuffer, rectángulos.
- `gui/font64.asm`: `draw_char64` y `draw_string64` con bitmap 8x16.
- `window/window64.asm`: estructura de ventanas, create/close/redraw.
- `userapps/cmd.elf64.asm`: app mínima de usuario (placeholder syscall).
