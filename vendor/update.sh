#!/bin/bash
SRC_BASE=~/android-kernel/out/android12-5.10/dist
DEST_DIR=.
LOG_FILE=missing_modules.log

declare -A RENAME_MAP=(
    [gps_drv.ko]="gps_drv_dl_v050.ko"
    [mali_mgm.ko]="mali_mgm_mt6879.ko"
    [mali_prot_alloc.ko]="mali_prot_alloc_mt6879.ko"
)

declare -A EXTRA_FILES=(
    [Image.gz]="../Image.gz"
    [mt6879.dtb]="../dtb/mt6879.dtb"
    [dtbo.img]="../dtbo.img"
)

# clear previous log
: > "$LOG_FILE"

shopt -s nullglob

for dest_file in "$DEST_DIR"/*.ko; do
    name=$(basename "$dest_file")

    # Also check if this dest file is itself a rename target — resolve back to source name
    src_name="$name"
    for k in "${!RENAME_MAP[@]}"; do
        if [[ "${RENAME_MAP[$k]}" == "$name" ]]; then
            src_name="$k"
            break
        fi
    done

    # Find matching module in source tree (by original source name)
    src_file=$(find "$SRC_BASE" -type f -name "$src_name" 2>/dev/null | head -n 1)

    if [[ -n "$src_file" ]]; then
        dest_name="${RENAME_MAP[$src_name]:-$src_name}"
        cp "$src_file" "$DEST_DIR/$dest_name"
        if [[ "$dest_name" != "$src_name" ]]; then
            echo "[OK] $src_name -> $dest_name  (from $src_file)"
        else
            echo "[OK] $name  (from $src_file)"
        fi
    else
        echo "[MISSING] $name" | tee -a "$LOG_FILE"
    fi
done

echo
for src_name in "${!EXTRA_FILES[@]}"; do
    dest_path="${EXTRA_FILES[$src_name]}"
    src_file="$SRC_BASE/$src_name"

    if [[ -f "$src_file" ]]; then
        mkdir -p "$(dirname "$dest_path")"
        cp "$src_file" "$dest_path"
        echo "[OK] $src_name -> $dest_path"
    else
        echo "[MISSING] $src_name (expected at $src_file)" | tee -a "$LOG_FILE"
    fi
done

echo
echo "Done. Missing modules (if any) logged to $LOG_FILE"
