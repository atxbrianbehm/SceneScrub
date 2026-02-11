FROM nvidia/cuda:12.8.0-devel-ubuntu22.04

WORKDIR /app

# Install Python 3.10 + system deps
RUN apt-get update && \
    apt-get install -y python3 python3-pip python3-venv git wget && \
    ln -sf /usr/bin/python3 /usr/bin/python && \
    rm -rf /var/lib/apt/lists/*

# Clone SHARP
RUN git clone https://github.com/apple/ml-sharp.git /app/ml-sharp

# Install all SHARP deps from its own requirements (no version conflicts)
WORKDIR /app/ml-sharp
ENV TORCH_CUDA_ARCH_LIST="7.0;7.5;8.0;8.6;8.9;9.0"
RUN pip install --no-cache-dir -r requirements.txt

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
