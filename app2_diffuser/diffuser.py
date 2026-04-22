"""
Diffusers MVP — Text-to-Image with Stable Diffusion
Uses: diffusers, torch, Pillow, gradio
Install: pip install diffusers transformers accelerate torch gradio Pillow
"""

import torch
from diffusers import StableDiffusionPipeline, DPMSolverMultistepScheduler
from PIL import Image
import gradio as gr

# ── Model setup ─────────────────────────────────────────────────────────────
MODEL_ID = "runwayml/stable-diffusion-v1-5"

def load_pipeline():
    """Load pipeline with the best available device."""
    device = (
        "cuda" if torch.cuda.is_available()
        else "mps" if torch.backends.mps.is_available()
        else "cpu"
    )

    # MPS (Apple Silicon) produces NaN with float16 → use float32
    dtype = torch.float16 if device == "cuda" else torch.float32

    pipe = StableDiffusionPipeline.from_pretrained(
        MODEL_ID,
        torch_dtype=dtype,
        safety_checker=None,          # Remove for production use
        requires_safety_checker=False,
    )

    # Faster scheduler (DPM-Solver++ is great for quality at low steps)
    pipe.scheduler = DPMSolverMultistepScheduler.from_config(
        pipe.scheduler.config
    )

    pipe = pipe.to(device)

    # Memory optimisations when not on CPU
    if device != "cpu":
        pipe.enable_attention_slicing()

    print(f"✅  Pipeline loaded on {device.upper()}")
    return pipe, device


# ── Inference ────────────────────────────────────────────────────────────────
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
    """Run one inference pass and return a PIL image."""
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


# ── Gradio UI ────────────────────────────────────────────────────────────────
def build_ui(pipe):
    def infer(prompt, negative_prompt, steps, guidance, width, height, seed):
        if not prompt.strip():
            return None, "⚠️  Please enter a prompt."
        try:
            img = generate(pipe, prompt, negative_prompt, steps, guidance,
                           width, height, int(seed))
            return img, "✅  Done!"
        except Exception as e:
            return None, f"❌  Error: {e}"

    with gr.Blocks(title="Diffusers MVP", theme=gr.themes.Soft()) as demo:
        gr.Markdown("# 🖼️  Diffusers MVP\nText-to-image with Stable Diffusion v1.5")

        with gr.Row():
            with gr.Column(scale=1):
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
                    steps    = gr.Slider(10, 50, value=20, step=1,  label="Steps")
                    guidance = gr.Slider(1,  20, value=7.5, step=0.5, label="Guidance")

                with gr.Row():
                    width  = gr.Dropdown([512, 640, 768], value=512, label="Width")
                    height = gr.Dropdown([512, 640, 768], value=512, label="Height")

                seed   = gr.Number(value=-1, label="Seed (-1 = random)")
                btn    = gr.Button("Generate 🚀", variant="primary")
                status = gr.Textbox(label="Status", interactive=False)

            with gr.Column(scale=1):
                output = gr.Image(label="Generated image", type="pil")

        btn.click(
            fn=infer,
            inputs=[prompt, negative, steps, guidance, width, height, seed],
            outputs=[output, status],
        )

        gr.Examples(
            examples=[
                ["a serene Japanese garden at sunrise, golden light, ultra-detailed", "", 25, 7.5, 512, 512, 42],
                ["cyberpunk city at night, neon lights, rain reflections, 8k", "blurry, cartoon", 30, 8.0, 512, 512, 7],
                ["portrait of a wizard, oil painting, dramatic lighting", "photo, realistic", 20, 7.0, 512, 512, -1],
            ],
            inputs=[prompt, negative, steps, guidance, width, height, seed],
        )

    return demo


# ── Entry point ───────────────────────────────────────────────────────────────
if __name__ == "__main__":
    pipe, device = load_pipeline()
    demo = build_ui(pipe)
    demo.launch(share=False)   # set share=True for a public ngrok tunnel