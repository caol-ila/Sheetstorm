"""GitHub Models client — OpenAI-API-compatible wrapper for Azure AI Foundry."""

import base64
import os
import time
from pathlib import Path
from typing import Optional

import fitz  # PyMuPDF
import openai
from PIL import Image


# Models available on GitHub Models with vision capability
VISION_MODELS = [
    "gpt-4o",
    "gpt-4o-mini",
    "Llama-3.2-90B-Vision-Instruct",
]

# Models actually supporting image input (verified at test time)
IMAGE_CAPABLE_MODELS = [
    "gpt-4o",
    "gpt-4o-mini",
    "Llama-3.2-90B-Vision-Instruct",
]

GITHUB_MODELS_ENDPOINT = "https://models.inference.ai.azure.com"


class AuthError(Exception):
    """Raised when no valid GitHub token is found."""


class GitHubModelsClient:
    """Client for GitHub Models / Azure AI Foundry vision inference."""

    def __init__(self, model: str = "gpt-4o-mini", token: Optional[str] = None):
        resolved_token = token or os.environ.get("GITHUB_TOKEN") or _gh_cli_token()
        if not resolved_token:
            raise AuthError(
                "No GitHub token found. Set GITHUB_TOKEN env var or run `gh auth login`."
            )
        self.client = openai.OpenAI(
            base_url=GITHUB_MODELS_ENDPOINT,
            api_key=resolved_token,
        )
        self.model = model
        self._cost_tracker = {"prompt_tokens": 0, "completion_tokens": 0, "calls": 0}

    def vision_query(
        self,
        image_path: Path,
        prompt: str,
        max_tokens: int = 2048,
        retry: int = 3,
    ) -> str:
        """Send an image + text prompt to the model, return text response."""
        b64 = _encode_image(image_path)
        mime = "image/png" if str(image_path).lower().endswith(".png") else "image/jpeg"

        messages = [
            {
                "role": "user",
                "content": [
                    {"type": "text", "text": prompt},
                    {"type": "image_url", "image_url": {"url": f"data:{mime};base64,{b64}"}},
                ],
            }
        ]

        for attempt in range(retry):
            try:
                resp = self.client.chat.completions.create(
                    model=self.model,
                    messages=messages,
                    max_tokens=max_tokens,
                )
                usage = resp.usage
                if usage:
                    self._cost_tracker["prompt_tokens"] += usage.prompt_tokens
                    self._cost_tracker["completion_tokens"] += usage.completion_tokens
                self._cost_tracker["calls"] += 1
                return resp.choices[0].message.content or ""
            except openai.RateLimitError:
                if attempt < retry - 1:
                    time.sleep(10 * (attempt + 1))
                else:
                    raise
            except openai.BadRequestError as e:
                # Model may not support vision — surface clearly
                raise ValueError(f"Model {self.model} rejected request: {e}") from e

        return ""  # unreachable, satisfies type checker

    def text_query(self, prompt: str, max_tokens: int = 1024) -> str:
        """Send a text-only prompt."""
        resp = self.client.chat.completions.create(
            model=self.model,
            messages=[{"role": "user", "content": prompt}],
            max_tokens=max_tokens,
        )
        usage = resp.usage
        if usage:
            self._cost_tracker["prompt_tokens"] += usage.prompt_tokens
            self._cost_tracker["completion_tokens"] += usage.completion_tokens
        self._cost_tracker["calls"] += 1
        return resp.choices[0].message.content or ""

    def cost_summary(self) -> dict:
        """Return token usage summary for cost estimation."""
        return dict(self._cost_tracker)


def pdf_page_to_png(pdf_path: Path, page_index: int = 0, dpi: int = 150) -> Path:
    """Render a PDF page to a PNG file next to the PDF.  Returns PNG path."""
    out_path = pdf_path.parent / f"{pdf_path.stem}_page{page_index}.png"
    if out_path.exists():
        return out_path

    doc = fitz.open(str(pdf_path))
    page = doc[page_index]
    mat = fitz.Matrix(dpi / 72, dpi / 72)
    pix = page.get_pixmap(matrix=mat, colorspace=fitz.csRGB)
    pix.save(str(out_path))
    doc.close()
    return out_path


def extract_patch(
    image_path: Path, x: int, y: int, w: int = 64, h: int = 64
) -> Path:
    """Extract a 64×64 patch from an image. Returns path to patch PNG."""
    out_path = image_path.parent / f"{image_path.stem}_patch_{x}_{y}.png"
    if out_path.exists():
        return out_path
    img = Image.open(image_path)
    patch = img.crop((x, y, x + w, y + h))
    patch.save(str(out_path))
    return out_path


def _encode_image(image_path: Path) -> str:
    with open(image_path, "rb") as f:
        return base64.b64encode(f.read()).decode()


def _gh_cli_token() -> Optional[str]:
    """Try to get token from `gh auth token`."""
    try:
        import subprocess
        result = subprocess.run(
            ["gh", "auth", "token"],
            capture_output=True,
            text=True,
            timeout=5,
        )
        token = result.stdout.strip()
        return token if token else None
    except Exception:
        return None
