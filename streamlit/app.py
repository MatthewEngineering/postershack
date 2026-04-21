import json
import os
from io import BytesIO
from pathlib import Path

import streamlit as st

import comfyui_client

COMFYUI_HOST = os.environ.get("COMFYUI_HOST", "localhost")
COMFYUI_PORT = int(os.environ.get("COMFYUI_PORT", "8188"))
DEFAULT_MODEL = os.environ.get("DEFAULT_MODEL", "sd15")

comfyui_client.init(COMFYUI_HOST, COMFYUI_PORT)

WORKFLOW_DIR = Path(__file__).parent / "workflows"
WORKFLOWS = {"sd15": WORKFLOW_DIR / "sd15.json"}


@st.cache_data
def load_workflow(name: str) -> dict:
    with open(WORKFLOWS[name]) as f:
        return json.load(f)


st.set_page_config(
    page_title="Postershack",
    page_icon="🎨",
    layout="centered",
    initial_sidebar_state="collapsed",
)

st.title("Postershack")
st.caption("AI-powered poster generation")

with st.sidebar:
    st.header("Settings")
    model_choice = st.selectbox(
        "Model",
        options=list(WORKFLOWS.keys()),
        index=list(WORKFLOWS.keys()).index(DEFAULT_MODEL) if DEFAULT_MODEL in WORKFLOWS else 0,
    )
    use_random_seed = st.checkbox("Random seed", value=True)
    seed_input = st.number_input(
        "Seed",
        min_value=0,
        max_value=2**32 - 1,
        value=42,
        disabled=use_random_seed,
    )
    seed = None if use_random_seed else int(seed_input)

with st.form("generation_form"):
    positive_prompt = st.text_area(
        "Describe your poster",
        placeholder="A vintage travel poster of Tokyo at night, art deco style, bold colors",
        height=100,
    )
    negative_prompt = st.text_input(
        "Negative prompt (optional)",
        value="blurry, low quality, deformed, ugly, watermark",
    )
    submitted = st.form_submit_button("Generate", use_container_width=True, type="primary")

if submitted:
    if not positive_prompt.strip():
        st.warning("Please enter a description.")
        st.stop()

    workflow = load_workflow(model_choice)
    progress_bar = st.progress(0.0, text="Starting...")
    status_text = st.empty()
    image_placeholder = st.empty()

    try:
        gen = comfyui_client.generate(workflow, positive_prompt.strip(), negative_prompt.strip(), seed)
        result_image = None

        try:
            while True:
                event = next(gen)
                if event["type"] == "progress":
                    val = event["value"]
                    progress_bar.progress(val, text=f"Generating... {int(val * 100)}%")
                elif event["type"] == "status":
                    status_text.text(event["message"])
        except StopIteration as e:
            result_image = e.value

        progress_bar.progress(1.0, text="Done!")
        status_text.empty()

        if result_image:
            image_placeholder.image(result_image, use_column_width=True)
            buf = BytesIO()
            result_image.save(buf, format="PNG")
            st.download_button(
                label="Download PNG",
                data=buf.getvalue(),
                file_name="postershack_output.png",
                mime="image/png",
            )

    except ConnectionRefusedError:
        st.error(
            "Cannot connect to ComfyUI. The backend may still be downloading the model "
            "on first run — this takes 2-3 minutes. Please wait and try again."
        )
    except RuntimeError as e:
        st.error(f"Generation failed: {e}")
