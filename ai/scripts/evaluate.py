"""CLIP zero-shot sınıflandırmayı test setinde ölçer.

Kullanım (ai klasöründen):
    .venv/bin/python scripts/evaluate.py
    .venv/bin/python scripts/evaluate.py --prompts prompts.json --name deneme2

Test seti: data/test/<KATEGORI_KODU>/*.jpg
Sonuçlar: results/<ad>.json ve results/<ad>.md
"""

import argparse
import json
import time
from datetime import datetime
from pathlib import Path

import open_clip
import torch
from PIL import Image, ImageOps

AI_DIR = Path(__file__).resolve().parent.parent
IMAGE_EXTENSIONS = {".jpg", ".jpeg", ".png", ".webp"}

# OpenAI ağırlıkları QuickGELU ile eğitildi; "-quickgelu" olmadan sonuçlar sessizce bozulur
MODEL_NAME = "ViT-B-32-quickgelu"
PRETRAINED = "openai"


def load_test_set(data_dir: Path, codes: list[str]) -> list[tuple[Path, str]]:
    items = []
    for code in codes:
        folder = data_dir / code
        if not folder.is_dir():
            continue
        for path in sorted(folder.iterdir()):
            if path.suffix.lower() in IMAGE_EXTENSIONS:
                items.append((path, code))
    return items


def encode_prompts(model, tokenizer, prompts: dict[str, list[str]], device: str) -> torch.Tensor:
    """Her kategori için tariflerin ortalama temsilini döner (prompt ensembling)."""
    vectors = []
    with torch.no_grad():
        for texts in prompts.values():
            features = model.encode_text(tokenizer(texts).to(device))
            features /= features.norm(dim=-1, keepdim=True)
            mean = features.mean(dim=0)
            vectors.append(mean / mean.norm())
    return torch.stack(vectors)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--data", default=str(AI_DIR / "data" / "test"))
    parser.add_argument("--prompts", default=str(AI_DIR / "prompts.json"))
    parser.add_argument("--name", default="zero_shot")
    args = parser.parse_args()

    prompts: dict[str, list[str]] = json.loads(Path(args.prompts).read_text(encoding="utf-8"))
    codes = list(prompts.keys())
    items = load_test_set(Path(args.data), codes)
    if not items:
        raise SystemExit("Test setinde fotoğraf bulunamadı.")

    device = "cuda" if torch.cuda.is_available() else "cpu"
    model, _, preprocess = open_clip.create_model_and_transforms(MODEL_NAME, pretrained=PRETRAINED)
    tokenizer = open_clip.get_tokenizer(MODEL_NAME)
    model = model.to(device).eval()

    text_features = encode_prompts(model, tokenizer, prompts, device)

    confusion = {actual: {predicted: 0 for predicted in codes} for actual in codes}
    predictions = []
    top3_hits = 0
    started = time.time()

    with torch.no_grad():
        for path, actual in items:
            image = ImageOps.exif_transpose(Image.open(path)).convert("RGB")
            image_features = model.encode_image(preprocess(image).unsqueeze(0).to(device))
            image_features /= image_features.norm(dim=-1, keepdim=True)
            probabilities = (100 * image_features @ text_features.T).softmax(dim=-1)[0]

            ranked = probabilities.argsort(descending=True).tolist()
            predicted = codes[ranked[0]]
            top3 = [codes[i] for i in ranked[:3]]

            confusion[actual][predicted] += 1
            top3_hits += actual in top3
            predictions.append({
                "file": str(path.relative_to(Path(args.data))),
                "actual": actual,
                "predicted": predicted,
                "confidence": round(probabilities[ranked[0]].item(), 4),
                "top3": top3,
            })

    elapsed = time.time() - started
    total = len(items)
    correct = sum(confusion[c][c] for c in codes)
    per_class = {
        c: {
            "count": sum(confusion[c].values()),
            "correct": confusion[c][c],
            "accuracy": round(confusion[c][c] / max(1, sum(confusion[c].values())), 4),
        }
        for c in codes
    }

    result = {
        "name": args.name,
        "date": datetime.now().isoformat(timespec="seconds"),
        "model": f"{MODEL_NAME} ({PRETRAINED})",
        "device": device,
        "images": total,
        "accuracy": round(correct / total, 4),
        "top3_accuracy": round(top3_hits / total, 4),
        "ms_per_image": round(1000 * elapsed / total, 1),
        "per_class": per_class,
        "confusion": confusion,
        "prompts": prompts,
        "predictions": predictions,
    }

    results_dir = AI_DIR / "results"
    results_dir.mkdir(exist_ok=True)
    (results_dir / f"{args.name}.json").write_text(json.dumps(result, ensure_ascii=False, indent=1), encoding="utf-8")

    lines = [
        f"# {args.name}",
        "",
        f"- Model: {result['model']} · Cihaz: {device}",
        f"- Fotoğraf: {total} · Doğruluk: **%{100 * result['accuracy']:.1f}** · İlk 3'te doğru: %{100 * result['top3_accuracy']:.1f}",
        f"- Fotoğraf başına süre: {result['ms_per_image']} ms",
        "",
        "## Kategori bazında",
        "",
        "| Kategori | Fotoğraf | Doğru | Doğruluk |",
        "|---|---|---|---|",
    ]
    for c in codes:
        p = per_class[c]
        lines.append(f"| {c} | {p['count']} | {p['correct']} | %{100 * p['accuracy']:.0f} |")
    lines += ["", "## Karışıklık matrisi (satır: gerçek, sütun: tahmin)", "",
              "| | " + " | ".join(codes) + " |", "|---|" + "---|" * len(codes)]
    for actual in codes:
        lines.append(f"| **{actual}** | " + " | ".join(str(confusion[actual][p]) for p in codes) + " |")
    (results_dir / f"{args.name}.md").write_text("\n".join(lines) + "\n", encoding="utf-8")

    print("\n".join(lines[:4]))
    for c in codes:
        p = per_class[c]
        print(f"  {c:13s} {p['correct']:3d}/{p['count']:3d}  %{100 * p['accuracy']:.0f}")


if __name__ == "__main__":
    main()
