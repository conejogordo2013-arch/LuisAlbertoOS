#!/usr/bin/env bash
set -euo pipefail

echo "Building LuisAlbertoOS..."

command -v nasm >/dev/null 2>&1 || { echo "Error: nasm is required to build LuisAlbertoOS." >&2; exit 1; }
command -v dd >/dev/null 2>&1 || { echo "Error: dd is required to build LuisAlbertoOS." >&2; exit 1; }

mkdir -p boot kernel apps drivers libs bin

# Disk layout (LBA sectors, 512 bytes each):
#   0       boot sector
#   1..112  kernel image loaded by boot/LABootL.asm at 1000:0000 (112 sectors)
#   128..   apps and optional demo data, safely outside the kernel window
KERNEL_LOAD_SECTORS=112
KERNEL_START_LBA=1
APP_SAMPLE_LBA=160
APP_TEXTEDIT_LBA=162
APP_TASKMGR_LBA=164
APP_LATEXTEDIT_LBA=166
APP_HELLO_ELF_LBA=168
FS_DIR_LBA=208
FS_DATA_LBA=209

# 1. Bootloader and kernel
nasm -f bin boot/LABootL.asm -o bin/boot.bin
nasm -f bin kernel/LAKernel.asm -o bin/kernel.bin

kernel_size=$(wc -c < bin/kernel.bin)
max_kernel_size=$((KERNEL_LOAD_SECTORS * 512))
kernel_end_lba=$((KERNEL_START_LBA + KERNEL_LOAD_SECTORS))
first_payload_lba=$APP_SAMPLE_LBA
if (( kernel_size > max_kernel_size )); then
    echo "Error: kernel.bin is ${kernel_size} bytes; bootloader limit is ${max_kernel_size} bytes." >&2
    exit 1
fi
if (( first_payload_lba < kernel_end_lba )); then
    echo "Error: payload LBA ${first_payload_lba} overlaps kernel load window ending before LBA ${kernel_end_lba}." >&2
    exit 1
fi

# 2. Apps
nasm -f bin apps/sample1.laa.asm -o bin/sample1.laa
nasm -f bin apps/textedit.laa.asm -o bin/textedit.laa
nasm -f bin apps/taskmgr.laa.asm -o bin/taskmgr.laa
nasm -f bin apps/LATextedit.asm -o bin/LATextedit.laa
nasm -f bin apps/hello.elf.asm -o bin/hello.elf

# 3. Create image once
dd if=/dev/zero of=LuisAlbertoOS.img bs=512 count=2880 status=none

# 4. Bootloader and kernel
dd if=bin/boot.bin of=LuisAlbertoOS.img conv=notrunc status=none
dd if=bin/kernel.bin of=LuisAlbertoOS.img seek=${KERNEL_START_LBA} conv=notrunc status=none

# 5. Apps (manual sectors outside the kernel load window)
dd if=bin/sample1.laa    of=LuisAlbertoOS.img seek=${APP_SAMPLE_LBA} conv=notrunc status=none
dd if=bin/textedit.laa   of=LuisAlbertoOS.img seek=${APP_TEXTEDIT_LBA} conv=notrunc status=none
dd if=bin/taskmgr.laa    of=LuisAlbertoOS.img seek=${APP_TASKMGR_LBA} conv=notrunc status=none
dd if=bin/LATextedit.laa of=LuisAlbertoOS.img seek=${APP_LATEXTEDIT_LBA} conv=notrunc status=none
dd if=bin/hello.elf     of=LuisAlbertoOS.img seek=${APP_HELLO_ELF_LBA} conv=notrunc status=none

# 6. Mock FS directory (optional demo data). Entry size: 26 bytes.
FS_DATA_LBA=${FS_DATA_LBA} python3 - <<'PY'
import os
from pathlib import Path
entry = bytearray(512)
name = b"test.txt"
entry[0:len(name)] = name
entry[16:20] = int(os.environ["FS_DATA_LBA"]).to_bytes(4, "little")
entry[20:24] = (15).to_bytes(4, "little")
entry[24] = 1  # FLAG_FILE
entry[25] = 0  # root parent
Path("bin/mock_dir.bin").write_bytes(entry)
PY
dd if=bin/mock_dir.bin of=LuisAlbertoOS.img seek=${FS_DIR_LBA} conv=notrunc status=none
printf 'Hello from FS!\n\0' > bin/mock_test.txt
dd if=bin/mock_test.txt of=LuisAlbertoOS.img seek=${FS_DATA_LBA} conv=notrunc status=none

echo "Build complete."
