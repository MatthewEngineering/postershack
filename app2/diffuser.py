"""
Diffusers MVP — Text-to-Image with Stable Diffusion
Uses: diffusers, torch, Pillow, gradio
Install: pip install diffusers transformers accelerate torch gradio Pillow
"""

import torch
from diffusers import StableDiffusionPipeline, DPMSolverMultistepScheduler
from PIL import Image
import gradio as gr

# ── Available models ─────────────────────────────────────────────────────────
# Key = friendly display name shown in the UI dropdown
# "id"       = HuggingFace repo ID
# "azure"    = True means it's tuned to run on CPU (no GPU required)
#              → safe for Azure Container Apps with no GPU allocation
MODELS = {
    "Fast — Azure / CPU-safe (small SD)": {
        "id": "OFA-Sys/small-stable-diffusion-v0",
        "azure": True,
    },
    "Standard (SD v1.5)": {
        "id": "runwayml/stable-diffusion-v1-5",
        "azure": False,
    },
    "Realistic Photos (Realistic Vision v1.4)": {
        "id": "SG161222/Realistic_Vision_V1.4",
        "azure": False,
    },
    "Anime / Art Style (Waifu Diffusion)": {
        "id": "hakurei/waifu-diffusion",
        "azure": False,
    },
}

DEFAULT_MODEL = "Fast — Azure / CPU-safe (small SD)"

# Cache so switching back to the same model doesn't re-download
_pipeline_cache: dict = {}


# ── Model loading ─────────────────────────────────────────────────────────────
def load_pipeline(model_name: str):
    if model_name in _pipeline_cache:
        return _pipeline_cache[model_name]

    model_id = MODELS[model_name]["id"]
    azure_mode = MODELS[model_name]["azure"]

    device = (
        "cuda" if torch.cuda.is_available()
        else "mps" if torch.backends.mps.is_available()
        else "cpu"
    )

    # Azure Container Apps have no GPU — force CPU for azure-flagged models
    if azure_mode:
        device = "cpu"

    # MPS and CPU need float32; CUDA is fine with float16
    dtype = torch.float16 if device == "cuda" else torch.float32

    pipe = StableDiffusionPipeline.from_pretrained(
        model_id,
        torch_dtype=dtype,
        safety_checker=None,
        requires_safety_checker=False,
    )

    pipe.scheduler = DPMSolverMultistepScheduler.from_config(
        pipe.scheduler.config
    )

    pipe = pipe.to(device)

    if device != "cpu":
        pipe.enable_attention_slicing()

    print(f"Pipeline '{model_name}' loaded on {device.upper()}")
    _pipeline_cache[model_name] = pipe
    return pipe


# ── Inference ─────────────────────────────────────────────────────────────────
def generate(
    pipe,
    prompt: str,
    negative_prompt: str = "",
    steps: int = 20,
    guidance: float = 7.5,
    width: int = 512,
    height: int = 512,
    seed: int = -1,
) -> Image.Image:
    generator = None
    if seed >= 0:
        generator = torch.Generator().manual_seed(seed)

    result = pipe(
        prompt=prompt,
        negative_prompt=negative_prompt or None,
        num_inference_steps=steps,
        guidance_scale=guidance,
        width=width,
        height=height,
        generator=generator,
    )
    return result.images[0]


# ── Gradio UI ─────────────────────────────────────────────────────────────────
def build_ui():
    def infer(model_name, prompt, negative_prompt, steps, guidance, width, height, seed):
        if not prompt.strip():
            return None, "Please enter a prompt."
        try:
            pipe = load_pipeline(model_name)
            img = generate(pipe, prompt, negative_prompt, steps, guidance,
                           width, height, int(seed))
            return img, "Done!"
        except Exception as e:
            return None, f"Error: {e}"

    with gr.Blocks(title="Diffusers MVP", theme=gr.themes.Soft()) as demo:
        gr.Markdown("## Text-to-Image — Stable Diffusion")

        with gr.Row():
            with gr.Column(scale=1):
                model_selector = gr.Dropdown(
                    choices=list(MODELS.keys()),
                    value=DEFAULT_MODEL,
                    label="Model",
                )
                gr.Markdown(
                    "_The **Azure / CPU-safe** model runs without a GPU "
                    "and is the only one guaranteed to work in Azure Container Apps._",
                    elem_classes=["gr-hint"],
                )

                prompt = gr.Textbox(
                    label="Prompt",
                    placeholder="a photo of an astronaut riding a horse on Mars",
                    lines=3,
                )
                negative = gr.Textbox(
                    label="Negative prompt",
                    placeholder="blurry, low quality, watermark",
                    lines=2,
                )

                with gr.Row():
                    steps    = gr.Slider(10, 50, value=20, step=1,   label="Steps")
                    guidance = gr.Slider(1,  20, value=7.5, step=0.5, label="Guidance")

                with gr.Row():
                    width  = gr.Dropdown([512, 640, 768], value=512, label="Width")
                    height = gr.Dropdown([512, 640, 768], value=512, label="Height")

                seed   = gr.Number(value=-1, label="Seed  (-1 = random)")
                btn    = gr.Button("Generate", variant="primary")
                status = gr.Textbox(label="Status", interactive=False)

            with gr.Column(scale=1):
                output = gr.Image(label="Generated image", type="pil")

        btn.click(
            fn=infer,
            inputs=[model_selector, prompt, negative, steps, guidance, width, height, seed],
            outputs=[output, status],
        )

        gr.Examples(
            examples=[
                [DEFAULT_MODEL, "a serene Japanese garden at sunrise, golden light", "", 20, 7.5, 512, 512, 42],
                ["Standard (SD v1.5)", "cyberpunk city at night, neon lights, rain reflections", "blurry, cartoon", 30, 8.0, 512, 512, 7],
                ["Realistic Photos (Realistic Vision v1.4)", "portrait of a wizard, dramatic lighting", "cartoon, anime", 20, 7.0, 512, 512, -1],
            ],
            inputs=[model_selector, prompt, negative, steps, guidance, width, height, seed],
        )

    return demo


# ── Entry point ───────────────────────────────────────────────────────────────
if __name__ == "__main__":
    demo = build_ui()
    demo.launch(share=False)   # set share=True for a public ngrok tunnel
