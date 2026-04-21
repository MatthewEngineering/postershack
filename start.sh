#!/bin/bash
set -e

echo "Starting Postershack..."
echo "Note: On Mac with Docker Desktop, generation runs on CPU (~3-8 min/image)."
echo "For faster generation on M4, consider running ComfyUI natively outside Docker."
echo ""

docker compose up --build
