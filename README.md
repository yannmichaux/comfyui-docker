# ComfyUI + ComfyUI Manager — CUDA 13.2.1 Docker Image

[![GitHub Build](https://img.shields.io/github/actions/workflow/status/yannmichaux/comfyui-/build.yml?style=for-the-badge&logo=github)](https://github.com/yannmichaux/comfyui-/actions)
[![GitHub Release](https://img.shields.io/github/v/release/yannmichaux/comfyui-?style=for-the-badge&logo=github)](https://github.com/yannmichaux/comfyui-/releases)
[![Docker Version](https://img.shields.io/docker/v/yannmichaux/comfyui?sort=semver&style=for-the-badge&logo=docker)](https://hub.docker.com/r/yannmichaux/comfyui/tags)
[![License: MIT](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](LICENSE)
[![ComfyUI](https://img.shields.io/badge/Powered%20by-ComfyUI-blueviolet?style=for-the-badge)](https://github.com/comfyanonymous/ComfyUI)

> A ready-to-run **ComfyUI + ComfyUI Manager** Docker image with **CUDA 13.2.1**, **Python 3.12**, and **PyTorch CU130**, fully GPU-accelerated and optimized for homelabs, servers, and AI workstations.

---

## ✨ Overview

This project provides a production-ready Docker image for running **ComfyUI** with **ComfyUI Manager**:

- 🔧 Base image: `nvidia/cuda:13.2.1-runtime-ubuntu24.04`
- 🐍 Python **3.12** in a dedicated virtual environment
- 🔥 PyTorch (CU130 wheels) for NVIDIA GPU acceleration
- 🧩 ComfyUI + ComfyUI Manager preinstalled
- 📂 Clean volume structure for `input`, `output`, and `models`
- 🌐 Web UI exposed on port **8188**

---

## 📦 Docker Hub & Source Code

- **Docker Hub:** [`yannmichaux/comfyui`](https://hub.docker.com/r/yannmichaux/comfyui)
- **GitHub Repo:** [`yannmichaux/comfyui-`](https://github.com/yannmichaux/comfyui-)

---

## 🧱 Image Contents

The image includes:

- **OS & Runtime**
  - Ubuntu 24.04
  - CUDA 13.0.2 runtime
- **Language & Libraries**
  - Python 3.12 (`/usr/bin/python3.12`)
  - Virtual environment at `/app/venv`
  - PyTorch + torchvision + torchaudio (CU130 wheels)
- **Applications**
  - ComfyUI (cloned from official repo into `/app/comfyui`)
  - ComfyUI Manager (installed in `custom_nodes`)
- **Ports**
  - Exposes port `8188`

---

## 📁 Container Directory Layout

```text
/app/comfyui
├── input/        # Input images
├── output/       # Generated outputs
├── models/       # Checkpoints, LoRAs, VAEs, upscalers...
└── custom_nodes/
    └── ComfyUI-Manager/
```

Mount these directories on the host for persistence.

---

## 🚀 Quick Start

### 1. Pull the versioned Docker image

```bash
docker pull yannmichaux/comfyui:latest
```

### 2. Run the container

```bash
docker run -d \
  --gpus all \
  --name comfyui \
  -p 8188:8188 \
  -v /mnt/comfy/input:/app/comfyui/input \
  -v /mnt/comfy/output:/app/comfyui/output \
  -v /mnt/comfy/models:/app/comfyui/models \
  yannmichaux/comfyui:<version>
```

Access ComfyUI:

```
http://localhost:8188
```

---

## 🐳 docker-compose Example

```yaml
version: "3.9"

services:
  comfyui:
    image: yannmichaux/comfyui:<version>
    container_name: comfyui
    restart: unless-stopped
    ports:
      - "8188:8188"
    volumes:
      - /mnt/comfy/input:/app/comfyui/input
      - /mnt/comfy/output:/app/comfyui/output
      - /mnt/comfy/models:/app/comfyui/models
    deploy:
      resources:
        reservations:
          devices:
            - capabilities: ["gpu"]
    environment:
      - NVIDIA_VISIBLE_DEVICES=all
      - NVIDIA_DRIVER_CAPABILITIES=compute,utility,video
```

## 🧪 Debugging & Tools

- Follow logs: `docker logs -f comfyui`
- Shell into the container: `docker exec -it comfyui bash`
- GPU checks: `nvidia-smi`

---

## 🤝 Contributing

Contributions are welcome!
Open issues, PRs, or feature requests directly on GitHub.

---

## 📜 License (MIT)

This project is licensed under the terms of the **MIT License**.
See the [LICENSE](LICENSE) file for details.

---

## 🙌 Credits

- [ComfyUI](https://github.com/comfyanonymous/ComfyUI)
- [ComfyUI Manager](https://github.com/Comfy-Org/ComfyUI-Manager)
- [NVIDIA CUDA Images](https://hub.docker.com/r/nvidia/cuda)
