FROM python:3.11-slim

WORKDIR /app

# System deps needed by torch/Pillow
RUN apt-get update && apt-get install -y --no-install-recommends \
        libgl1 \
        libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

# Install Python deps first (layer-cached until requirements change)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY diffuser.py .

# Gradio listens on 7860; Azure Container Apps routes to this port
EXPOSE 7860

# Gradio must bind to 0.0.0.0 inside a container
ENV GRADIO_SERVER_NAME=0.0.0.0
ENV GRADIO_SERVER_PORT=7860
ENV GRADIO_ANALYTICS_ENABLED=False

CMD ["python", "diffuser.py"]
