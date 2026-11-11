"""Tek fotoğraf için kategori önerisi: linear probe ve zero-shot ilk 3.

Kullanım (ai klasöründen):
    .venv/bin/python scripts/predict.py yol/foto.jpg [yol/foto2.jpg ...]
"""

import json
import sys
from pathlib import Path

import numpy as np
import open_clip
import torch
from PIL import Image, ImageOps

AI_DIR = Path(__file__).resolve().parent.parent


def softmax(logits: np.ndarray) -> np.ndarray:
    e = np.exp(logits - logits.max())
    return e / e.sum()


def print_top3(title: str, codes: list[str], probs: np.ndarray) -> None:
    print(f"  {title}:")
    for i in np.argsort(-probs)[:3]:
        print(f"    {codes[i]:13s} %{100 * probs[i]:.1f}")


def main() -> None:
    probe = json.loads((AI_DIR / "models" / "linear_probe.json").read_text(encoding="utf-8"))
    prompts: dict[str, list[str]] = json.loads((AI_DIR / "prompts.json").read_text(encoding="utf-8"))
    codes = probe["classes"]
    coef, intercept = np.array(probe["coef"]), np.array(probe["intercept"])

    model, _, preprocess = open_clip.create_model_and_transforms(probe["model"], pretrained=probe["pretrained"])
    tokenizer = open_clip.get_tokenizer(probe["model"])
    model.eval()

    with torch.no_grad():
        text = []
        for code in codes:
            t = model.encode_text(tokenizer(prompts[code]))
            t = (t / t.norm(dim=-1, keepdim=True)).mean(dim=0)
            text.append((t / t.norm()).numpy())
        text = np.stack(text)

        for path in sys.argv[1:]:
            image = ImageOps.exif_transpose(Image.open(path)).convert("RGB")
            f = model.encode_image(preprocess(image).unsqueeze(0))
            x = (f / f.norm(dim=-1, keepdim=True))[0].numpy()
            print(path)
            print_top3("linear probe", codes, softmax(coef @ x + intercept))
            print_top3("zero-shot", codes, softmax(100 * text @ x))


if __name__ == "__main__":
    main()
