#!/bin/bash
set -e

MODELS_DIR="/workspace/ComfyUI/models/checkpoints"
mkdir -p "$MODELS_DIR"

MODEL_FILE="$MODELS_DIR/v1-5-pruned-emaonly.safetensors"
# Minimum expected size for a valid safetensors checkpoint (~3.8 GB)
MIN_SIZE=3800000000

is_valid_model() {
    [ -f "$1" ] && [ "$(stat -c%s "$1" 2>/dev/null || stat -f%z "$1")" -gt "$MIN_SIZE" ]
}

if ! is_valid_model "$MODEL_FILE"; then
    [ -f "$MODEL_FILE" ] && echo "[postershack] Existing file looks corrupt (too small), re-downloading..."
    echo "[postershack] Downloading SD 1.5 fp16 (~2 GB)..."
    # Use civitai mirror as primary — more reliable for Docker environments
    wget --progress=bar:force \
         -O "$MODEL_FILE" \
         "https://huggingface.co/stable-diffusion-v1-5/stable-diffusion-v1-5/resolve/main/v1-5-pruned-emaonly.safetensors"
    if ! is_valid_model "$MODEL_FILE"; then
        echo "[postershack] ERROR: Download failed or file is corrupt." >&2
        rm -f "$MODEL_FILE"
        exit 1
    fi
    echo "[postershack] Download complete."
else
    echo "[postershack] SD 1.5 model already present, skipping download."
fi

echo "[postershack] Starting ComfyUI..."
exec python3 main.py \
    --listen 0.0.0.0 \
    --port 8188 \
    --output-directory /workspace/ComfyUI/output \
    --cpu \
    ${COMFYUI_EXTRA_ARGS}
