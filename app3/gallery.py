import os
import uuid
import json
import tempfile
from datetime import datetime, timezone
from io import BytesIO

import gradio as gr
from google.cloud import storage as gcs
from PIL import Image

_gcs_client = gcs.Client(project=os.environ["GOOGLE_CLOUD_PROJECT"])
_bucket = _gcs_client.bucket(os.environ["GCS_BUCKET_NAME"])
METADATA_BLOB = "metadata.json"


def load_metadata() -> list:
    try:
        return json.loads(_bucket.blob(METADATA_BLOB).download_as_text())
    except Exception:
        return []


def save_image(image, prompt: str):
    name = f"{uuid.uuid4()}.png"
    buf = BytesIO()
    image.save(buf, format="PNG")
    _bucket.blob(name).upload_from_string(buf.getvalue(), content_type="image/png")
    records = load_metadata()
    records.insert(0, {"file": name, "prompt": prompt, "ts": datetime.now(timezone.utc).isoformat()})
    _bucket.blob(METADATA_BLOB).upload_from_string(json.dumps(records), content_type="application/json")


def load_gallery_with_meta() -> tuple:
    records = load_metadata()[:20]
    images, meta = [], []
    for r in records:
        try:
            data = _bucket.blob(r["file"]).download_as_bytes()
            images.append((Image.open(BytesIO(data)), r["prompt"]))
            meta.append(r)
        except Exception:
            continue
    return images, meta


def _on_select(evt: gr.SelectData, meta: list):
    if meta and evt.index < len(meta):
        fname = meta[evt.index]["file"]
        return gr.update(visible=True), fname, f"**Selected:** `{fname}`"
    return gr.update(visible=False), "", ""


def _delete(filename: str):
    if filename:
        try:
            _bucket.blob(filename).delete()
        except Exception:
            pass
        records = [r for r in load_metadata() if r["file"] != filename]
        _bucket.blob(METADATA_BLOB).upload_from_string(
            json.dumps(records), content_type="application/json"
        )
    images, meta = load_gallery_with_meta()
    return images, meta, gr.update(visible=False), "", "", gr.update(visible=False)


def _download(filename: str):
    if not filename:
        return gr.update(visible=False)
    data = _bucket.blob(filename).download_as_bytes()
    tmp = tempfile.NamedTemporaryFile(delete=False, suffix=".png")
    tmp.write(data)
    tmp.close()
    return gr.update(value=tmp.name, visible=True)


def _upload(filepath):
    if filepath is None:
        return load_gallery_with_meta()
    img = Image.open(filepath)
    save_image(img, "Uploaded image")
    return load_gallery_with_meta()


def build_tab() -> tuple:
    """Build the Gallery tab UI. Returns (gallery, gallery_meta) for use in demo.load."""
    with gr.TabItem("Gallery"):
        gallery_meta = gr.State([])
        selected_file = gr.State("")

        with gr.Row():
            refresh_btn = gr.Button("Refresh", variant="secondary")
            upload_btn = gr.UploadButton("Upload Image", file_types=["image"], variant="secondary")

        gallery = gr.Gallery(
            label="Previously generated images",
            columns=3,
            object_fit="cover",
            height="auto",
        )

        with gr.Row(visible=False) as action_bar:
            selected_label = gr.Markdown("")
            download_btn = gr.Button("Download", variant="secondary", size="sm")
            delete_btn = gr.Button("Delete", variant="stop", size="sm")

        download_file = gr.File(label="Download", visible=False, interactive=False)

        refresh_btn.click(fn=load_gallery_with_meta, inputs=[], outputs=[gallery, gallery_meta])

        gallery.select(
            fn=_on_select,
            inputs=[gallery_meta],
            outputs=[action_bar, selected_file, selected_label],
        )

        delete_btn.click(
            fn=_delete,
            inputs=[selected_file],
            outputs=[gallery, gallery_meta, action_bar, selected_file, selected_label, download_file],
        )

        download_btn.click(fn=_download, inputs=[selected_file], outputs=[download_file])

        upload_btn.upload(fn=_upload, inputs=[upload_btn], outputs=[gallery, gallery_meta])

    return gallery, gallery_meta
