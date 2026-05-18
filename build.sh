#!/usr/bin/env bash
set -euo pipefail

echo "Building LuisAlbertoOS..."

command -v nasm >/dev/null 2>&1 || { echo "Error: nasm is required to build LuisAlbertoOS." >&2; exit 1; }
command -v dd >/dev/null 2>&1 || { echo "Error: dd is required to build LuisAlbertoOS." >&2; exit 1; }

mkdir -p boot kernel apps drivers libs bin

# Disk layout (LBA sectors, 512 bytes each):
#   0       boot sector
#   1..80   kernel load window read by boot/LABootL.asm (80 sectors)
#   104..   apps and optional demo data, safely outside the kernel window
SECTOR_SIZE=512
DISK_SECTORS=2880
KERNEL_LOAD_SECTORS=80
KERNEL_START_LBA=1
APP_SAMPLE_LBA=104
APP_TEXTEDIT_LBA=106
APP_TASKMGR_LBA=108
APP_LATEXTEDIT_LBA=110
FS_DIR_LBA=144
FS_DATA_LBA=145

sectors_for_file() {
    local bytes=$1
    echo $(((bytes + SECTOR_SIZE - 1) / SECTOR_SIZE))
}

# 1. Bootloader and kernel
nasm -f bin boot/LABootL.asm -o bin/boot.bin
nasm -f bin kernel/LAKernel.asm -o bin/kernel.bin

boot_size=$(wc -c < bin/boot.bin)
if (( boot_size != SECTOR_SIZE )); then
    echo "Error: boot.bin must be exactly ${SECTOR_SIZE} bytes; got ${boot_size}." >&2
    exit 1
fi

kernel_size=$(wc -c < bin/kernel.bin)
max_kernel_size=$((KERNEL_LOAD_SECTORS * SECTOR_SIZE))
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

declare -a APP_FILES=(
    "bin/sample1.laa:${APP_SAMPLE_LBA}:sample1"
    "bin/textedit.laa:${APP_TEXTEDIT_LBA}:textedit"
    "bin/taskmgr.laa:${APP_TASKMGR_LBA}:taskmgr"
    "bin/LATextedit.laa:${APP_LATEXTEDIT_LBA}:LATextedit"
)

next_reserved_lba=${FS_DIR_LBA}
for app in "${APP_FILES[@]}"; do
    IFS=':' read -r app_file app_lba app_name <<< "${app}"
    app_size=$(wc -c < "${app_file}")
    app_sectors=$(sectors_for_file "${app_size}")
    app_end_lba=$((app_lba + app_sectors))

    if (( app_end_lba > next_reserved_lba )); then
        echo "Error: ${app_name} (${app_size} bytes) occupies LBAs ${app_lba}..$((app_end_lba - 1)), overlapping reserved LBA ${next_reserved_lba}." >&2
        exit 1
    fi
done

# 3. Create image once
dd if=/dev/zero of=LuisAlbertoOS.img bs=${SECTOR_SIZE} count=${DISK_SECTORS} status=none

# 4. Bootloader and kernel
dd if=bin/boot.bin of=LuisAlbertoOS.img conv=notrunc status=none
dd if=bin/kernel.bin of=LuisAlbertoOS.img seek=${KERNEL_START_LBA} conv=notrunc status=none

# 5. Apps (manual sectors outside the kernel load window)
dd if=bin/sample1.laa    of=LuisAlbertoOS.img seek=${APP_SAMPLE_LBA} conv=notrunc status=none
dd if=bin/textedit.laa   of=LuisAlbertoOS.img seek=${APP_TEXTEDIT_LBA} conv=notrunc status=none
dd if=bin/taskmgr.laa    of=LuisAlbertoOS.img seek=${APP_TASKMGR_LBA} conv=notrunc status=none
dd if=bin/LATextedit.laa of=LuisAlbertoOS.img seek=${APP_LATEXTEDIT_LBA} conv=notrunc status=none

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
