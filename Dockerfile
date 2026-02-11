FROM runpod/pytorch:2.2.0-py3.10-cuda12.1.1-devel-ubuntu22.04

WORKDIR /app

# Install system deps
RUN apt-get update && apt-get install -y git wget && rm -rf /var/lib/apt/lists/*

# Clone SHARP and install
RUN git clone https://github.com/apple/ml-sharp.git /app/ml-sharp
WORKDIR /app/ml-sharp
RUN pip install --no-cache-dir -r requirements.txt
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
