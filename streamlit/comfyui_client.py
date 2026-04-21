"""
ComfyUI API client — handles WebSocket progress streaming and REST image retrieval.
"""

import copy
import json
import random
import urllib.request
import uuid
from io import BytesIO
from typing import Generator

import websocket
from PIL import Image

_server_address: str = ""


def init(host: str, port: int) -> None:
    global _server_address
    _server_address = f"{host}:{port}"


def _http(path: str) -> str:
    return f"http://{_server_address}{path}"


def _ws() -> str:
    return f"ws://{_server_address}/ws"


def _queue_prompt(workflow: dict, client_id: str) -> str:
    payload = json.dumps({"prompt": workflow, "client_id": client_id}).encode()
    req = urllib.request.Request(
        _http("/prompt"),
        data=payload,
        headers={"Content-Type": "application/json"},
    )
    try:
        with urllib.request.urlopen(req) as resp:
            return json.loads(resp.read())["prompt_id"]
    except urllib.error.HTTPError as e:
        body = e.read().decode(errors="replace")
        raise RuntimeError(f"ComfyUI rejected prompt (HTTP {e.code}): {body}") from None


def _get_history(prompt_id: str) -> dict:
    with urllib.request.urlopen(_http(f"/history/{prompt_id}")) as resp:
        return json.loads(resp.read())


def _download_image(filename: str, subfolder: str, folder_type: str) -> Image.Image:
    params = f"filename={filename}&subfolder={subfolder}&type={folder_type}"
    with urllib.request.urlopen(_http(f"/view?{params}")) as resp:
        return Image.open(BytesIO(resp.read())).copy()


def inject_prompt(
    workflow: dict,
    positive: str,
    negative: str,
    seed: int | None = None,
) -> dict:
    wf = copy.deepcopy(workflow)
    if seed is None:
        seed = random.randint(0, 2**32 - 1)

    for node in wf.values():
        inputs = node.get("inputs", {})
        if node["class_type"] == "CLIPTextEncode":
            if inputs.get("text") == "POSITIVE_PROMPT_PLACEHOLDER":
                inputs["text"] = positive
            elif inputs.get("text") == "NEGATIVE_PROMPT_PLACEHOLDER":
                inputs["text"] = negative
        if node["class_type"] == "KSampler":
            inputs["seed"] = seed

    return wf


def generate(
    workflow: dict,
    positive: str,
    negative: str,
    seed: int | None = None,
) -> Generator[dict, None, Image.Image]:
    """
    Generator that streams progress and returns a PIL Image.

    Yields dicts:
      {"type": "progress", "value": float}   0.0–1.0
      {"type": "status", "message": str}

    The final PIL Image is returned via StopIteration.value:
      try:
          while True: event = next(gen)
      except StopIteration as e:
          image = e.value
    """
    client_id = str(uuid.uuid4())
    wf = inject_prompt(workflow, positive, negative, seed)

    ws = websocket.WebSocket()
    ws.connect(f"{_ws()}?clientId={client_id}")

    try:
        prompt_id = _queue_prompt(wf, client_id)
        yield {"type": "status", "message": "Queued — waiting for ComfyUI..."}

        while True:
            raw = ws.recv()

            if isinstance(raw, bytes):
                continue

            msg = json.loads(raw)
            msg_type = msg.get("type")

            if msg_type == "progress":
                data = msg["data"]
                yield {"type": "progress", "value": data["value"] / data["max"]}

            elif msg_type == "executing":
                data = msg["data"]
                if data.get("node") is None and data.get("prompt_id") == prompt_id:
                    break

            elif msg_type == "execution_error":
                raise RuntimeError(f"ComfyUI execution error: {msg['data']}")

    finally:
        ws.close()

    history = _get_history(prompt_id)
    outputs = history.get(prompt_id, {}).get("outputs", {})
    for node_output in outputs.values():
        if "images" in node_output:
            img = node_output["images"][0]
            return _download_image(img["filename"], img["subfolder"], img["type"])

    raise RuntimeError("No image found in ComfyUI output — check ComfyUI logs.")
