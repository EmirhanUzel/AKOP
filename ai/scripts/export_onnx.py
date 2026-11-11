"""CLIP görsel kodlayıcısı + linear probe'u tek ONNX dosyasına aktarır ve PyTorch ile karşılaştırır.

Kullanım (ai klasöründen):
    .venv/bin/python scripts/export_onnx.py

Girdi: models/linear_probe.json (train_linear_probe.py çıktısı)
Çıktı:
    models/akop_category.onnx   girdi "image" [N,3,224,224] float32, çıktı "probabilities" [N,8]
    models/akop_category.json   sınıflar ve ön işleme ayarları (.NET tarafı bunu okur)

ReportService'teki ön işleme buradaki preprocess() ile aynı olmalı:
kısa kenar 224'e, uzun kenar int(224 · uzun / kısa) (bicubic) → ortadan 224×224 kırpma → [0,1] → kanal bazında (x - mean) / std, RGB, CHW.
"""

import json
import time
from pathlib import Path

import numpy as np
import onnxruntime as ort
import open_clip
import torch
from PIL import Image, ImageOps

AI_DIR = Path(__file__).resolve().parent.parent
MODELS_DIR = AI_DIR / "models"
IMAGE_SIZE = 224
MEAN = [0.48145466, 0.4578275, 0.40821073]
STD = [0.26862954, 0.26130258, 0.27577711]
IMAGE_EXTENSIONS = {".jpg", ".jpeg", ".png", ".webp"}


class CategoryModel(torch.nn.Module):
    """Normalize edilmiş fotoğraf → CLIP temsili → L2 normalize → linear probe → softmax."""

    def __init__(self, clip_model, coef: np.ndarray, intercept: np.ndarray):
        super().__init__()
        self.visual = clip_model.visual
        self.linear = torch.nn.Linear(coef.shape[1], coef.shape[0])
        self.linear.weight.data = torch.tensor(coef, dtype=torch.float32)
        self.linear.bias.data = torch.tensor(intercept, dtype=torch.float32)

    def forward(self, image: torch.Tensor) -> torch.Tensor:
        features = self.visual(image)
        features = features / features.norm(dim=-1, keepdim=True)
        return torch.softmax(self.linear(features), dim=-1)


def preprocess(path: Path) -> np.ndarray:
    """open_clip ön işlemesinin PyTorch'suz karşılığı; .NET tarafına örnek."""
    image = ImageOps.exif_transpose(Image.open(path)).convert("RGB")
    # torchvision ile birebir: uzun kenar aşağı yuvarlanır (int), kırpma başlangıcı en yakına yuvarlanır
    short, long = min(image.size), max(image.size)
    new_long = int(IMAGE_SIZE * long / short)
    width, height = (IMAGE_SIZE, new_long) if image.width <= image.height else (new_long, IMAGE_SIZE)
    image = image.resize((width, height), Image.BICUBIC)
    left, top = round((width - IMAGE_SIZE) / 2), round((height - IMAGE_SIZE) / 2)
    image = image.crop((left, top, left + IMAGE_SIZE, top + IMAGE_SIZE))
    x = np.asarray(image, dtype=np.float32) / 255.0
    x = (x - np.array(MEAN, dtype=np.float32)) / np.array(STD, dtype=np.float32)
    return x.transpose(2, 0, 1)


def main() -> None:
    probe = json.loads((MODELS_DIR / "linear_probe.json").read_text(encoding="utf-8"))
    clip_model, _, clip_preprocess = open_clip.create_model_and_transforms(probe["model"], pretrained=probe["pretrained"])
    model = CategoryModel(clip_model, np.array(probe["coef"]), np.array(probe["intercept"])).eval()

    onnx_path = MODELS_DIR / "akop_category.onnx"
    torch.onnx.export(
        model, torch.zeros(1, 3, IMAGE_SIZE, IMAGE_SIZE), onnx_path,
        input_names=["image"], output_names=["probabilities"],
        dynamic_axes={"image": {0: "batch"}, "probabilities": {0: "batch"}},
        opset_version=17, dynamo=False,
    )
    (MODELS_DIR / "akop_category.json").write_text(json.dumps({
        "model": f"{probe['model']} ({probe['pretrained']}) + linear probe (C={probe['C']})",
        "classes": probe["classes"],
        "input": "image", "output": "probabilities",
        "preprocessing": {"size": IMAGE_SIZE, "resize": "shortest side, bicubic", "crop": "center",
                          "scale": "1/255", "mean": MEAN, "std": STD, "layout": "NCHW", "channels": "RGB"},
    }, indent=1), encoding="utf-8")
    print(f"dışa aktarıldı: {onnx_path.name} ({onnx_path.stat().st_size / 1e6:.0f} MB)")

    # Doğrulama: aynı fotoğraflarda PyTorch (open_clip ön işlemesi) ile ONNX (numpy ön işlemesi)
    test_dir = AI_DIR / "data" / "test"
    paths = sorted(p for p in test_dir.rglob("*") if p.suffix.lower() in IMAGE_EXTENSIONS)[::10]
    session = ort.InferenceSession(onnx_path, providers=["CPUExecutionProvider"])
    max_diff, same_top1, elapsed = 0.0, 0, 0.0
    for path in paths:
        with torch.no_grad():
            image = ImageOps.exif_transpose(Image.open(path)).convert("RGB")
            expected = model(clip_preprocess(image).unsqueeze(0))[0].numpy()
        start = time.perf_counter()
        actual = session.run(None, {"image": preprocess(path)[None]})[0][0]
        elapsed += time.perf_counter() - start
        max_diff = max(max_diff, float(np.abs(expected - actual).max()))
        same_top1 += int(expected.argmax() == actual.argmax())
    print(f"doğrulama: {len(paths)} fotoğraf · aynı ilk tahmin {same_top1}/{len(paths)} · "
          f"en büyük olasılık farkı {max_diff:.4f} · ONNX ortalama {1000 * elapsed / len(paths):.0f} ms")


if __name__ == "__main__":
    main()
