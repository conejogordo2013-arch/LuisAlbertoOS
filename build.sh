#!/usr/bin/env bash
set -euo pipefail

echo "Building LuisAlbertoOS..."

command -v nasm >/dev/null 2>&1 || { echo "Error: nasm is required to build LuisAlbertoOS." >&2; exit 1; }
command -v dd >/dev/null 2>&1 || { echo "Error: dd is required to build LuisAlbertoOS." >&2; exit 1; }

mkdir -p boot kernel apps drivers libs bin

# 1. Bootloader and kernel
nasm -f bin boot/LABootL.asm -o bin/boot.bin
nasm -f bin kernel/LAKernel.asm -o bin/kernel.bin

# The bootloader currently reads 40 sectors (20 KiB) starting at sector 2.
kernel_size=$(wc -c < bin/kernel.bin)
max_kernel_size=$((40 * 512))
if (( kernel_size > max_kernel_size )); then
    echo "Error: kernel.bin is ${kernel_size} bytes; bootloader limit is ${max_kernel_size} bytes." >&2
    exit 1
fi

# 2. Apps
nasm -f bin apps/sample1.laa.asm -o bin/sample1.laa
nasm -f bin apps/textedit.laa.asm -o bin/textedit.laa
nasm -f bin apps/taskmgr.laa.asm -o bin/taskmgr.laa
nasm -f bin apps/LATextedit.asm -o bin/LATextedit.laa

# 3. Create image once
dd if=/dev/zero of=LuisAlbertoOS.img bs=512 count=2880 status=none

# 4. Bootloader and kernel
dd if=bin/boot.bin of=LuisAlbertoOS.img conv=notrunc status=none
dd if=bin/kernel.bin of=LuisAlbertoOS.img seek=1 conv=notrunc status=none

# 5. Apps (manual sectors)
dd if=bin/sample1.laa    of=LuisAlbertoOS.img seek=19 conv=notrunc status=none
dd if=bin/textedit.laa   of=LuisAlbertoOS.img seek=21 conv=notrunc status=none
dd if=bin/taskmgr.laa    of=LuisAlbertoOS.img seek=23 conv=notrunc status=none
dd if=bin/LATextedit.laa of=LuisAlbertoOS.img seek=25 conv=notrunc status=none

# 6. Mock FS directory (optional demo data). Entry size: 26 bytes.
python3 - <<'PY'
from pathlib import Path
entry = bytearray(512)
name = b"test.txt"
entry[0:len(name)] = name
entry[16:20] = (31).to_bytes(4, "little")
entry[20:24] = (15).to_bytes(4, "little")
entry[24] = 1  # FLAG_FILE
entry[25] = 0  # root parent
Path("bin/mock_dir.bin").write_bytes(entry)
PY
dd if=bin/mock_dir.bin of=LuisAlbertoOS.img seek=30 conv=notrunc status=none
printf 'Hello from FS!\n\0' > bin/mock_test.txt
dd if=bin/mock_test.txt of=LuisAlbertoOS.img seek=31 conv=notrunc status=none

echo "Build complete."
