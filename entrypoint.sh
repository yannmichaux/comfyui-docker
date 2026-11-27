#!/bin/bash
set -euo pipefail

VENV=/app/venv
VENV_PY="$VENV/bin/python"
MARKER="$VENV/.comfyui-docker-env"
COMFY=/app/comfyui
PYTHON_BIN="/usr/local/bin/python${PYTHON_VERSION}"
TORCH_URL="https://download.pytorch.org/whl/${TORCH_INDEX}"

uvpip() { uv pip install --python "$VENV_PY" "$@"; }

current_py=""
if [ -x "$VENV_PY" ]; then
    current_py="$("$VENV_PY" -c 'import sys; print(f"{sys.version_info[0]}.{sys.version_info[1]}")' 2>/dev/null || true)"
fi

# (Re)create the venv when missing, broken, or built for another Python version
if [ "$current_py" != "$PYTHON_VERSION" ]; then
    echo "--------------------------------------------------------"
    if [ -n "$(ls -A "$VENV" 2>/dev/null)" ]; then
        echo "⚠️  Venv in /app/venv is unusable or uses Python '${current_py:-unknown}'."
        echo "♻️  Recreating it with Python ${PYTHON_VERSION} (custom-node deps will be reinstalled"
        echo "    by ComfyUI-Manager / on next node install)."
        find "$VENV" -mindepth 1 -delete
    else
        echo "🔄 Volume /app/venv is empty (first launch)."
    fi
    echo "📦 Creating Python ${PYTHON_VERSION} virtual environment..."
    echo "--------------------------------------------------------"
    uv venv --seed --python "$PYTHON_BIN" "$VENV"
    uvpip --upgrade pip uv
fi

# Install / upgrade PyTorch when the venv is new or the CUDA wheel index changed
if [ "$(cat "$MARKER" 2>/dev/null || true)" != "torch=${TORCH_INDEX}" ]; then
    echo "📦 Installing PyTorch (${TORCH_INDEX})..."
    # --reinstall-package also allows switching to an older index (e.g. cu130 -> torch 2.14.1)
    uvpip --upgrade torch torchvision torchaudio --index-url "$TORCH_URL" \
        --reinstall-package torch --reinstall-package torchvision --reinstall-package torchaudio

    echo "📦 Installing rembg with GPU support..."
    # Optional: onnxruntime-gpu wheels are not available for every platform/CUDA combo
    uvpip "rembg[gpu]" || echo "⚠️  rembg[gpu] could not be installed, continuing without it."

    echo "torch=${TORCH_INDEX}" > "$MARKER"
fi

# Always sync ComfyUI + Manager requirements (no-op when already satisfied),
# so a newer image with new requirements works with an existing venv volume.
echo "📦 Syncing ComfyUI and ComfyUI-Manager requirements..."
uvpip -r "$COMFY/requirements.txt" -r "$COMFY/manager_requirements.txt"

echo "🚀 Starting ComfyUI on port ${COMFYUI_PORT}..."
cd "$COMFY"
# Extra ComfyUI flags: COMFYUI_ARGS env (e.g. "--lowvram --preview-method auto") and/or container command
read -r -a EXTRA_ARGS <<< "${COMFYUI_ARGS:-}"
exec "$VENV_PY" main.py --listen 0.0.0.0 --port "${COMFYUI_PORT}" --enable-manager "${EXTRA_ARGS[@]}" "$@"
