# ComfyUI + ComfyUI Manager — CUDA 13 Docker Image

[![GitHub Build](https://img.shields.io/github/actions/workflow/status/yannmichaux/comfyui-docker/build-docker.yml?style=for-the-badge&logo=github)](https://github.com/yannmichaux/comfyui-docker/actions)
[![GitHub Release](https://img.shields.io/github/v/release/yannmichaux/comfyui-docker?style=for-the-badge&logo=github)](https://github.com/yannmichaux/comfyui-docker/releases)
[![Docker Version](https://img.shields.io/docker/v/yannmichaux/comfyui?sort=semver&style=for-the-badge&logo=docker)](https://hub.docker.com/r/yannmichaux/comfyui/tags)
[![License: MIT](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](LICENSE)
[![ComfyUI](https://img.shields.io/badge/Powered%20by-ComfyUI-blueviolet?style=for-the-badge)](https://github.com/comfyanonymous/ComfyUI)

> A ready-to-run **ComfyUI + ComfyUI Manager** Docker image with **CUDA 13.2** (PyTorch wheels), **Python 3.12**, and **PyTorch 2.15 (CU132)**, fully GPU-accelerated and optimized for homelabs, servers, and AI workstations.

---

## ✨ Overview

This project provides a production-ready Docker image for running **ComfyUI** with **ComfyUI Manager**:

- 🔧 Base image: `ubuntu:26.04` (CUDA libraries are shipped by the PyTorch wheels)
- 🐍 Python **3.12** (managed by `uv`) in a dedicated virtual environment
- 🔥 PyTorch (CU132 wheels) for NVIDIA GPU acceleration
- 🧩 ComfyUI + ComfyUI Manager (`comfyui_manager` pip package, `--enable-manager`)
- 📂 Clean volume structure for `input`, `output`, and `models`
- 🖥️ Multi-arch: `linux/amd64` and `linux/arm64`
- 🌐 Web UI exposed on port **8188**

---

## 📦 Docker Hub & Source Code

- **Docker Hub:** [`yannmichaux/comfyui`](https://hub.docker.com/r/yannmichaux/comfyui)
- **GitHub Repo:** [`yannmichaux/comfyui-docker`](https://github.com/yannmichaux/comfyui-docker)

---

## 🧱 Image Contents

The image includes:

- **OS & Runtime**
  - Ubuntu 26.04
  - CUDA 13.2 libraries (from the PyTorch `cu132` wheels)
  - Default: NVIDIA driver **R580+** and a Turing or newer GPU (see [GPU & driver compatibility](#-gpu--driver-compatibility) for older setups)
- **Language & Libraries**
  - Python 3.12 (uv-managed, `/usr/local/bin/python3.12`)
  - Virtual environment at `/app/venv` (created on first launch, persist it with a volume)
  - PyTorch + torchvision + torchaudio (CU132 wheels)
- **Applications**
  - ComfyUI (pinned release tag, cloned into `/app/comfyui`)
  - ComfyUI Manager (pip package from `manager_requirements.txt`)
- **Ports**
  - Exposes port `8188`

---

## 📁 Container Directory Layout

```text
/app/comfyui
├── input/        # Input images
├── output/       # Generated outputs
├── models/       # Checkpoints, LoRAs, VAEs, upscalers...
└── custom_nodes/   # Custom nodes installed via the Manager
/app/venv          # Python virtual environment (created on first launch)
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
  -v /mnt/comfy/custom_nodes:/app/comfyui/custom_nodes \
  -v /mnt/comfy/venv:/app/venv \
  yannmichaux/comfyui:<version>
```

Access ComfyUI:

```
http://localhost:8188
```

---

## 🐳 docker-compose Example

```yaml
services:
  comfyui:
    image: yannmichaux/comfyui:latest
    container_name: comfyui
    restart: unless-stopped
    ports:
      - 8188:8188
    volumes:
      - /mnt/comfy/input:/app/comfyui/input
      - /mnt/comfy/output:/app/comfyui/output
      - /mnt/comfy/models:/app/comfyui/models
      - /mnt/comfy/custom_nodes:/app/comfyui/custom_nodes
      - /mnt/comfy/venv:/app/venv
    runtime: nvidia
    environment:
      - NVIDIA_VISIBLE_DEVICES=all
```

## 🎛️ GPU & driver compatibility

PyTorch is installed on first launch, from the index set by the `TORCH_INDEX` environment variable. Override it at runtime (no rebuild needed) to match your host driver and GPU. Check your driver with `nvidia-smi`.

| `TORCH_INDEX` | PyTorch | Host driver | GPUs |
| --- | --- | --- | --- |
| `cu132` *(default)* | 2.15.x | R580+ | Turing (RTX 20xx) and newer |
| `cu134` | 2.15.x | R595+ | Turing and newer |
| `cu130` | 2.14.1 | R580+ | Turing and newer (fallback if `cu132` fails to init CUDA) |
| `cu126` | 2.14.1 | R525+ | Maxwell / Pascal (GTX 9xx/10xx) / Volta, or older drivers |

Changing `TORCH_INDEX` reinstalls PyTorch in the existing venv on next start.

---

## 🔧 Environment variables

| Variable | Default | Description |
| --- | --- | --- |
| `TORCH_INDEX` | `cu132` | PyTorch wheel index, see the table above |
| `COMFYUI_ARGS` | *(empty)* | Extra ComfyUI flags, e.g. `--lowvram --preview-method auto` |
| `COMFYUI_PORT` | `8188` | Port ComfyUI listens on inside the container |

Extra flags can also be passed as the container command (`docker run ... yannmichaux/comfyui:latest --cpu`).

---

## 🗄️ Example: TrueNAS Scale

1. **Apps → Configuration → Settings**: enable **Install NVIDIA Drivers**, then check on the host shell with `nvidia-smi` (driver **580+** required for CUDA 13).
2. Create a dataset, e.g. `/mnt/tank/apps/comfyui`, with sub-folders `input`, `output`, `models`, `custom_nodes`, `venv`.
3. **Apps → Discover Apps → ⋮ → Install via YAML**:

```yaml
services:
  comfyui:
    image: yannmichaux/comfyui:latest
    container_name: comfyui
    restart: unless-stopped
    ports:
      - 8188:8188
    environment:
      - NVIDIA_VISIBLE_DEVICES=all
      # - TORCH_INDEX=cu130   # fallback if your driver is too old for cu132 (PyTorch 2.14.1)
    volumes:
      - /mnt/tank/apps/comfyui/input:/app/comfyui/input
      - /mnt/tank/apps/comfyui/output:/app/comfyui/output
      - /mnt/tank/apps/comfyui/models:/app/comfyui/models
      - /mnt/tank/apps/comfyui/custom_nodes:/app/comfyui/custom_nodes
      - /mnt/tank/apps/comfyui/venv:/app/venv
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: all
              capabilities: [gpu]
```

The first start downloads PyTorch (~4 GB) into the `venv` dataset: follow it in the app logs. Next starts take a few seconds.

---

## ⚙️ Build arguments

| Argument | Default | Description |
| --- | --- | --- |
| `PYTHON_VERSION` | `3.12` | Python used for the venv (`3.13` is the version recommended by ComfyUI) |
| `TORCH_INDEX` | `cu132` | PyTorch wheel index (`cu132`, `cu134`...) |
| `COMFYUI_REF` | `v0.46.3` | ComfyUI tag or branch (`master` for bleeding edge) |

```bash
docker build --build-arg PYTHON_VERSION=3.13 -t comfyui:py313 .
```

Changing `PYTHON_VERSION` recreates `/app/venv` on next start; changing `TORCH_INDEX` upgrades PyTorch in place.

---

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
