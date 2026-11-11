"""CLIP temsilleri üzerinde linear probe (lojistik regresyon) eğitir ve test setinde ölçer.

Kullanım (ai klasöründen):
    .venv/bin/python scripts/train_linear_probe.py

Girdi: data/train/<KOD>/ (eğitim), data/test/<KOD>/ (test), prompts.json (zero-shot karşılaştırması)
Çıktı:
    models/linear_probe.json   sınıflandırıcı ağırlıkları (ONNX/.NET'e taşımak için)
    results/linear_probe*.md   test sonuçları
Temsiller data/features/ altında önbelleğe alınır.
"""

import json
from pathlib import Path

import numpy as np
import open_clip
import torch
from PIL import Image, ImageOps
from sklearn.linear_model import LogisticRegression
from sklearn.model_selection import StratifiedKFold, cross_val_score

from report import write_report

AI_DIR = Path(__file__).resolve().parent.parent
MODEL_NAME = "ViT-B-32-quickgelu"
PRETRAINED = "openai"
IMAGE_EXTENSIONS = {".jpg", ".jpeg", ".png", ".webp"}
C_GRID = [0.1, 0.3, 1.0, 3.0, 10.0, 30.0, 100.0]
DUPLICATE_THRESHOLD = 0.95  # CLIP temsillerinin kosinüs benzerliği


def list_images(root: Path, codes: list[str]) -> list[tuple[Path, str]]:
    return [(p, c) for c in codes if (root / c).is_dir()
            for p in sorted((root / c).iterdir()) if p.suffix.lower() in IMAGE_EXTENSIONS]


def encode_images(model, preprocess, items, device, cache: Path) -> np.ndarray:
    keys = [str(p) for p, _ in items]
    if cache.exists():
        saved = np.load(cache, allow_pickle=True)
        if list(saved["keys"]) == keys:
            return saved["features"]
    features = []
    with torch.no_grad():
        for path, _ in items:
            image = ImageOps.exif_transpose(Image.open(path)).convert("RGB")
            f = model.encode_image(preprocess(image).unsqueeze(0).to(device))
            features.append((f / f.norm(dim=-1, keepdim=True))[0].float().cpu().numpy())
    features = np.stack(features)
    cache.parent.mkdir(parents=True, exist_ok=True)
    np.savez(cache, keys=np.array(keys), features=features)
    return features


def to_predictions(items, probabilities, codes, root: Path) -> list[dict]:
    out = []
    for (path, actual), probs in zip(items, probabilities):
        ranked = np.argsort(-probs)
        out.append({"file": str(path.relative_to(root)), "actual": actual, "predicted": codes[ranked[0]],
                    "confidence": round(float(probs[ranked[0]]), 4), "top3": [codes[i] for i in ranked[:3]]})
    return out


def main() -> None:
    prompts: dict[str, list[str]] = json.loads((AI_DIR / "prompts.json").read_text(encoding="utf-8"))
    codes = list(prompts.keys())
    train_items = list_images(AI_DIR / "data" / "train", codes)
    test_items = list_images(AI_DIR / "data" / "test", codes)
    print(f"eğitim: {len(train_items)} · test: {len(test_items)}")

    device = "cuda" if torch.cuda.is_available() else "cpu"
    model, _, preprocess = open_clip.create_model_and_transforms(MODEL_NAME, pretrained=PRETRAINED)
    tokenizer = open_clip.get_tokenizer(MODEL_NAME)
    model = model.to(device).eval()

    features_dir = AI_DIR / "data" / "features"
    x_train = encode_images(model, preprocess, train_items, device, features_dir / "train.npz")
    x_test = encode_images(model, preprocess, test_items, device, features_dir / "test.npz")
    # Sızıntı kontrolü: test fotoğrafının neredeyse aynısı olan eğitim fotoğrafları çıkarılır
    # (veri setlerinde aynı görselin döndürülmüş/kırpılmış kopyaları ve tekrar gönderilen ihbarlar var)
    similarity = x_train @ x_test.T
    duplicates = similarity.max(axis=1) >= DUPLICATE_THRESHOLD
    if duplicates.any():
        print(f"testle neredeyse aynı {int(duplicates.sum())} eğitim fotoğrafı çıkarıldı:",
              [str(train_items[i][0].relative_to(AI_DIR / 'data' / 'train')) for i in np.where(duplicates)[0]][:20])
    train_items = [item for item, dup in zip(train_items, duplicates) if not dup]
    x_train = x_train[~duplicates]
    y_train = np.array([codes.index(c) for _, c in train_items])

    # C değeri yalnızca eğitim setinde çapraz doğrulamayla seçilir; test seti seçimde kullanılmaz
    folds = StratifiedKFold(n_splits=5, shuffle=True, random_state=0)
    scores = {c: cross_val_score(LogisticRegression(C=c, max_iter=5000), x_train, y_train, cv=folds).mean() for c in C_GRID}
    best_c = max(scores, key=scores.get)
    print("çapraz doğrulama:", {c: round(s, 3) for c, s in scores.items()}, "-> C =", best_c)

    classifier = LogisticRegression(C=best_c, max_iter=5000).fit(x_train, y_train)
    probe_probs = classifier.predict_proba(x_test)

    # Karşılaştırma için aynı temsillerle zero-shot olasılıkları
    with torch.no_grad():
        text = []
        for texts in prompts.values():
            t = model.encode_text(tokenizer(texts).to(device))
            t = (t / t.norm(dim=-1, keepdim=True)).mean(dim=0)
            text.append((t / t.norm()).float().cpu().numpy())
    logits = 100 * x_test @ np.stack(text).T
    zero_shot_probs = np.exp(logits - logits.max(axis=1, keepdims=True))
    zero_shot_probs /= zero_shot_probs.sum(axis=1, keepdims=True)

    extra = {"model": f"{MODEL_NAME} ({PRETRAINED})", "train_images": len(train_items),
             "train_per_class": {c: int((y_train == i).sum()) for i, c in enumerate(codes)},
             "C": best_c, "cv_accuracy": round(scores[best_c], 4)}
    test_root = AI_DIR / "data" / "test"
    write_report("linear_probe_v1", codes, to_predictions(test_items, probe_probs, codes, test_root), extra)
    # Ağırlık ayarlanmadan sabit yarı yarıya karışım; test setine göre seçilmedi
    write_report("linear_probe_v1_plus_zero_shot", codes,
                 to_predictions(test_items, 0.5 * probe_probs + 0.5 * zero_shot_probs, codes, test_root),
                 {**extra, "blend": "0.5 linear probe + 0.5 zero-shot"})

    models_dir = AI_DIR / "models"
    models_dir.mkdir(exist_ok=True)
    (models_dir / "linear_probe.json").write_text(json.dumps({
        "model": MODEL_NAME, "pretrained": PRETRAINED, "classes": codes, "C": best_c,
        "note": "Girdi: L2 normalize edilmiş CLIP görsel temsili. Olasılık = softmax(coef · x + intercept)",
        "coef": classifier.coef_.round(6).tolist(), "intercept": classifier.intercept_.round(6).tolist(),
    }), encoding="utf-8")
    print("model kaydedildi: models/linear_probe.json")


if __name__ == "__main__":
    main()
