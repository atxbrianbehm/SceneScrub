FROM python:3.10-slim

WORKDIR /app

# System deps for building gsplat, downloading model, etc.
RUN apt-get update && \
    apt-get install -y --no-install-recommends git wget build-essential && \
    rm -rf /var/lib/apt/lists/*

# Install PyTorch (CPU for build — GPU available at runtime)
RUN pip install --no-cache-dir torch torchvision --index-url https://download.pytorch.org/whl/cpu

# Clone SHARP
RUN git clone https://github.com/apple/ml-sharp.git /app/ml-sharp
WORKDIR /app/ml-sharp

# Install SHARP's Python deps (skip gsplat for now — needs CUDA)
RUN pip install --no-cache-dir \
    click timm "imageio[ffmpeg]" matplotlib pillow-heif plyfile scipy

# Install SHARP package itself (editable)
RUN pip install --no-cache-dir --no-deps -e .

# Install gsplat (will JIT compile CUDA kernels on first GPU run)
RUN pip install --no-cache-dir --no-build-isolation gsplat || \
    pip install --no-cache-dir gsplat --no-binary gsplat || \
    echo "gsplat will be installed at runtime"

# Install RunPod SDK
RUN pip install --no-cache-dir runpod

# Pre-download model checkpoint (~400MB)
RUN mkdir -p /root/.cache/torch/hub/checkpoints && \
    wget -q -O /root/.cache/torch/hub/checkpoints/sharp_2572gikvuh.pt \
    https://ml-site.cdn-apple.com/models/sharp/sharp_2572gikvuh.pt

WORKDIR /app
COPY handler.py /app/handler.py

CMD ["python", "-u", "/app/handler.py"]
