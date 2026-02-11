FROM runpod/pytorch:2.2.0-py3.10-cuda12.1.1-devel-ubuntu22.04

WORKDIR /app

# Install system deps
RUN apt-get update && apt-get install -y git wget && rm -rf /var/lib/apt/lists/*

# Clone SHARP
RUN git clone https://github.com/apple/ml-sharp.git /app/ml-sharp

# Install SHARP deps in stages to isolate failures
WORKDIR /app/ml-sharp

# Install core deps first (no CUDA compilation needed)
RUN pip install --no-cache-dir \
    timm click imageio[ffmpeg] pillow-heif plyfile scipy matplotlib

# Install gsplat (needs CUDA compilation — set build env vars)
ENV TORCH_CUDA_ARCH_LIST="7.0;7.5;8.0;8.6;8.9;9.0"
RUN pip install --no-cache-dir gsplat

# Install SHARP itself (editable install from the cloned repo)
RUN pip install --no-cache-dir -e .

# Install RunPod SDK
RUN pip install --no-cache-dir runpod

# Pre-download model checkpoint (~400MB, baked into image for instant cold starts)
RUN mkdir -p /root/.cache/torch/hub/checkpoints && \
    wget -q -O /root/.cache/torch/hub/checkpoints/sharp_2572gikvuh.pt \
    https://ml-site.cdn-apple.com/models/sharp/sharp_2572gikvuh.pt

# Verify installation
RUN sharp --help

WORKDIR /app
COPY handler.py /app/handler.py

CMD ["python", "-u", "/app/handler.py"]
