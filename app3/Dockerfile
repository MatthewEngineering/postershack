FROM python:3.11-slim

WORKDIR /app

# Install Python deps first (layer-cached until requirements change)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py gallery.py ./

# Gradio listens on 7860; Cloud Run routes to this port
EXPOSE 8080

# Gradio must bind to 0.0.0.0 inside a container
ENV GRADIO_SERVER_NAME=0.0.0.0
ENV GRADIO_SERVER_PORT=8080
ENV GRADIO_ANALYTICS_ENABLED=False

CMD ["python", "app.py"]
