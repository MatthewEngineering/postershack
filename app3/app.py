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
        model="black-forest-labs/FLUX.1-schnell",
    )

with gr.Blocks(title="Postershack — Image Generator", theme=gr.themes.Soft()) as demo:
    gr.Markdown("# Postershack Image Generator")

    with gr.Tabs():
        with gr.Tab("Generate"):
            gr.Markdown(
                "Designed using FLUX.1-schnell via HuggingFace Inference &nbsp;|&nbsp; "
                "[Model](https://huggingface.co/black-forest-labs/FLUX.1-schnell)"
            )
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

            EXAMPLES = [
                ["Misty Forest",     "A misty forest at dawn with golden light filtering through ancient trees"],
                ["Moon Portrait",    "A cinematic portrait of an astronaut on the moon, Earth reflected in the visor"],
                ["Cyber City",       "A futuristic city skyline at night, neon reflections on wet streets"],
                ["Mountain Dragon",  "A dragon perched on a snow-capped mountain peak, wings spread wide"],
                ["Aurora Lake",      "Swirling aurora borealis over a frozen Scandinavian lake, long exposure"],
                ["Artisan Table",    "A rustic wooden table with artisan bread, olive oil, and fresh herbs, studio lighting"],
                ["Venice Canal",     "An oil painting of a Venice canal at sunset, gondolas reflected in golden water"],
                ["Dewdrop Web",      "A macro photograph of a dewdrop on a spider web, rainbow refraction"],
                ["Storm Lighthouse", "A lone lighthouse on a rocky cliff during a stormy night, dramatic waves"],
                ["Zen Garden",       "A Japanese zen garden with raked sand, mossy stones, and cherry blossoms"],
                ["Lost Library",     "An abandoned library with sunbeams cutting through dusty air, books piled high"],
                ["Steampunk Ship",   "A steampunk airship floating above a Victorian city, brass gears and exhaust"],
                ["Moonlit Wolf",     "A wolf howling at a full moon over a snow-covered pine forest, blue hour"],
                ["Coral Reef",       "An underwater coral reef teeming with tropical fish, crystal clear turquoise water"],
                ["Blacksmith Forge", "A medieval blacksmith's forge, glowing embers, sparks flying, dramatic shadows"],
                ["Old Fisherman",    "A photorealistic portrait of an elderly fisherman with weathered skin and kind eyes"],
                ["Nordic Interior",  "A minimalist Scandinavian living room, white walls, warm wood, morning light"],
                ["Tokyo Alley",      "A cyberpunk street market in a rainy Tokyo alley, neon signs, food stalls"],
                ["Lavender Fields",  "A field of lavender in Provence at golden hour, a farmhouse in the distance"],
                ["Spice Mandala",    "An intricate mandala made of colorful spices and flowers, flat lay, overhead"],
                ["Star Trails",      "A time-lapse composite of star trails above the Sahara desert, sand dunes silhouette"],
                ["Reading Nook",     "A cozy reading nook by a rain-streaked window, candle, cup of tea, autumn outside"],
                ["Diving Eagle",     "A hyperrealistic eagle in mid-dive, feathers sharp, mountain valley below"],
                ["Mars Greenhouse",  "A futuristic greenhouse on Mars, lush green plants inside, red barren landscape outside"],
                ["Melting Clocks",   "A surreal painting of a giant clock melting over a desert canyon, Dalí style"],
                ["Lion Portrait",    "A close-up of a lion's face, golden hour backlight, mane blowing in the wind"],
                ["Tea Ceremony",     "A traditional Japanese tea ceremony, cherry blossoms falling through a paper screen"],
                ["Retro Diner",      "A neon-lit 1980s American diner at night, rain on the pavement, retro cars"],
                ["Roman Colosseum",  "An ancient Roman colosseum at dusk, moody storm clouds, dramatic lighting"],
                ["Bioluminescence",  "A bioluminescent beach at night, glowing blue waves lapping white sand"],
                ["Balloon Festival", "A hot air balloon festival at sunrise, dozens of colorful balloons over green hills"],
                ["Glowing Forest",   "A dark forest path with glowing mushrooms and fireflies, fantasy mood"],
            ]

            title_col = gr.Textbox(visible=False)
            gr.Markdown("### Example prompts")
            gr.Examples(examples=EXAMPLES, inputs=[title_col, prompt])

            generate_btn.click(fn=generate_image, inputs=prompt, outputs=output)
            prompt.submit(fn=generate_image, inputs=prompt, outputs=output)

        with gr.Tab("Settings"):
            gr.Markdown(
                "## Billing\n"
                "[View HuggingFace Billing](https://huggingface.co/settings/billing)"
            )

if __name__ == "__main__":
    demo.launch(mcp_server=True)
