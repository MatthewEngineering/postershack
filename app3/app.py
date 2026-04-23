from dotenv import load_dotenv
load_dotenv()

import os
import gradio as gr
from huggingface_hub import InferenceClient

client = InferenceClient(
    provider="nscale",
    api_key=os.environ["HF_TOKEN"],
)

def generate_image(prompt: str) -> object:
    if not prompt.strip():
        return None
    return client.text_to_image(
        prompt,
        model="black-forest-labs/FLUX.1-schnell:cheapest",
    )

with gr.Blocks(title="Postershack — Image Generator", theme=gr.themes.Soft()) as demo:
    gr.Markdown("# Postershack Image Generator\nPowered by FLUX.1-schnell via HuggingFace Inference")

    with gr.Row():
        with gr.Column(scale=1):
            prompt = gr.Textbox(
                label="Prompt",
                placeholder="Describe the image you want to generate…",
                lines=4,
            )
            generate_btn = gr.Button("Generate", variant="primary")
        with gr.Column(scale=1):
            output = gr.Image(label="Generated Image", type="pil")

    generate_btn.click(fn=generate_image, inputs=prompt, outputs=output)
    prompt.submit(fn=generate_image, inputs=prompt, outputs=output)

if __name__ == "__main__":
    demo.launch()
