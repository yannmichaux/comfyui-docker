# CUDA libraries come from the PyTorch wheels (nvidia-* pip packages), so a plain
# Ubuntu base is enough. Using nvidia/cuda:*-runtime would add ~3 GB of duplicated
# libraries and force a host driver >= the image's CUDA version (NVIDIA_REQUIRE_CUDA).
FROM ubuntu:26.04

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Python version used for the venv (managed by uv, independent from the system python3).
# ComfyUI officially recommends 3.13; 3.12 is kept for custom-node compatibility.
ARG PYTHON_VERSION=3.12
# PyTorch wheel index (cu132 = default CUDA for PyTorch >= 2.15; cu130 stops at 2.14.1)
ARG TORCH_INDEX=cu132
# ComfyUI git ref (tag or branch). Use "master" for bleeding edge.
ARG COMFYUI_REF=v0.46.3

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    UV_LINK_MODE=copy \
    UV_PYTHON_INSTALL_DIR=/opt/python \
    UV_NO_CACHE=1 \
    TZ=Etc/UTC \
    PYTHON_VERSION=${PYTHON_VERSION} \
    TORCH_INDEX=${TORCH_INDEX} \
    NVIDIA_VISIBLE_DEVICES=all \
    NVIDIA_DRIVER_CAPABILITIES=compute,utility,graphics,video \
    COMFYUI_PORT=8188

# 1. Base system dependencies (build tools for 3D nodes, OpenGL/EGL, ffmpeg)
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    wget \
    curl \
    nano \
    ca-certificates \
    build-essential \
    ffmpeg \
    libgl1 \
    libglib2.0-0 \
    libopengl0 \
    libegl1 \
    && rm -rf /var/lib/apt/lists/*

# 2. uv + managed Python (no deadsnakes PPA, system python3 left untouched)
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /usr/local/bin/
RUN uv python install ${PYTHON_VERSION} && \
    ln -sf "$(uv python find ${PYTHON_VERSION})" /usr/local/bin/python${PYTHON_VERSION}

# 3. Clone ComfyUI (ComfyUI-Manager is now a pip package, see manager_requirements.txt)
WORKDIR /app
RUN git clone --depth 1 --branch ${COMFYUI_REF} https://github.com/Comfy-Org/ComfyUI.git comfyui

WORKDIR /app/comfyui

# 4. Create directories for fallback/structure
RUN mkdir -p /app/comfyui/input \
    /app/comfyui/output \
    /app/comfyui/models \
    /app/comfyui/custom_nodes \
    /app/comfyui/user/default

EXPOSE 8188

# 5. Entrypoint (creates/updates the venv stored in the /app/venv volume)
COPY --chmod=755 entrypoint.sh /app/entrypoint.sh

ENTRYPOINT ["/app/entrypoint.sh"]
