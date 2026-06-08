FROM nvidia/cuda:13.3.0-runtime-ubuntu26.04

SHELL ["/bin/bash", "-c"]

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    TZ=Etc/UTC

# 1. Base system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    wget \
    curl \
    nano \
    ca-certificates \
    build-essential \
    python3.13 \
    python3.13-venv \
    python3.13-dev \
    python3-pip \
    ffmpeg \
    libgl1 \
    && rm -rf /var/lib/apt/lists/*

# 2. Alias python3.13 -> python / pip
RUN ln -sf /usr/bin/python3.13 /usr/bin/python && \
    ln -sf /usr/bin/python3.13 /usr/bin/python3 && \
    ln -sf /usr/bin/pip3 /usr/bin/pip

# 3. Application directories
WORKDIR /app

# 4. Clone ComfyUI
RUN git clone https://github.com/Comfy-Org/ComfyUI.git comfyui

WORKDIR /app/comfyui

# 5. Create and activate virtual environment
RUN python3.13 -m venv /app/venv
ENV PATH="/app/venv/bin:$PATH"

# 6. Install PyTorch CU130 (generic example, adjust if the exact version changes)
RUN pip install torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/cu130

# 7. Install ComfyUI dependencies
RUN pip install -r requirements.txt

# 8. Install ComfyUI-Manager (custom_nodes)
RUN mkdir -p /app/comfyui/custom_nodes && \
    git clone https://github.com/Comfy-Org/ComfyUI-Manager.git /app/comfyui/custom_nodes/ComfyUI-Manager

# 9. Create directories for volumes
RUN mkdir -p /app/comfyui/input \
    /app/comfyui/output \
    /app/comfyui/models \
    /app/comfyui/models/lora \
    /app/comfyui/models/checkpoints \
    /app/comfyui/models/vae \
    /app/comfyui/models/controlnet

# 10. Useful environment variables
ENV COMFYUI_PORT=8188

# 11. Expose the web port
EXPOSE 8188

# 12. Startup command
#   --listen 0.0.0.0 => accessible via Docker
CMD ["python", "main.py", "--listen", "0.0.0.0", "--port", "8188"]
