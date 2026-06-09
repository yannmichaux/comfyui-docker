FROM nvidia/cuda:13.3.0-runtime-ubuntu26.04

SHELL ["/bin/bash", "-c"]

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    TZ=Etc/UTC

# 1. Add PPA for Python (Maintenu pour la compatibilité des outils système)
RUN apt-get update && apt-get install -y --no-install-recommends \
    software-properties-common && \
    add-apt-repository ppa:deadsnakes/ppa -y && \
    apt-get update && \
    rm -rf /var/lib/apt/lists/*

# 2. Base system dependencies (Inclus les outils de compilation pour les fixs de nœuds 3D)
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    wget \
    curl \
    nano \
    ca-certificates \
    build-essential \
    python3.12 \
    python3.12-venv \
    python3.12-dev \
    python3-pip \
    ffmpeg \
    libgl1 \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

# 3. Alias python3.12 -> python / pip
RUN ln -sf /usr/bin/python3.12 /usr/bin/python && \
    ln -sf /usr/bin/python3.12 /usr/bin/python3 && \
    ln -sf /usr/bin/pip3 /usr/bin/pip

# 4. Application directories
WORKDIR /app

# 5. Clone ComfyUI
RUN git clone https://github.com/Comfy-Org/ComfyUI.git comfyui

WORKDIR /app/comfyui

# 6. Install ComfyUI-Manager
RUN mkdir -p /app/comfyui/custom_nodes && \
    git clone https://github.com/Comfy-Org/ComfyUI-Manager.git /app/comfyui/custom_nodes/ComfyUI-Manager

# 7. Create directories for fallback/structure
RUN mkdir -p /app/comfyui/input \
    /app/comfyui/output \
    /app/comfyui/models \
    /app/comfyui/user/default

# 8. Configuring environment variables and exposed port
ENV COMFYUI_PORT=8188
EXPOSE 8188

# 9. Writing the dynamic Entrypoint script
RUN echo -e '#!/bin/bash\n\
if [ ! -f "/app/venv/bin/python" ]; then\n\
    echo "--------------------------------------------------------"\n\
    echo "🔄 Volume /app/venv est vide (First launch)."\n\
    echo "📦 Creating Python 3.12 virtual environment..."\n\
    echo "--------------------------------------------------------"\n\
    python3.12 -m venv /app/venv\n\
    /app/venv/bin/pip install --upgrade pip uv\n\
    \n\
    echo "📦 Installing PyTorch optimized for CUDA 13.3..."\n\
    /app/venv/bin/python -m uv pip install torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/cu130\n\
    \n\
    echo "📦 Installing base dependencies for ComfyUI..."\n\
    /app/venv/bin/python -m uv pip install -r /app/comfyui/requirements.txt\n\
else\n\
    echo "--------------------------------------------------------"\n\
    echo "✅ Existing virtual environment detected in the volume."\n\
    echo "--------------------------------------------------------"\n\
    # Optional: Ensure uv is available for future Manager fixes\n\
    /app/venv/bin/python -m pip install --quiet uv\n\
fi\n\
\n\
echo "🚀 Starting ComfyUI on port 8188..."\n\
exec /app/venv/bin/python main.py --listen 0.0.0.0 --port 8188\n\
' > /app/entrypoint.sh && chmod +x /app/entrypoint.sh

ENTRYPOINT ["/app/entrypoint.sh"]