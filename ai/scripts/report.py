"""Değerlendirme sonuçlarını results/<ad>.json ve results/<ad>.md olarak yazar."""

import json
from datetime import datetime
from pathlib import Path

AI_DIR = Path(__file__).resolve().parent.parent


def write_report(name: str, codes: list[str], predictions: list[dict], extra: dict) -> dict:
    """predictions: {"file", "actual", "predicted", "confidence", "top3"} listesi."""
    confusion = {actual: {predicted: 0 for predicted in codes} for actual in codes}
    for p in predictions:
        confusion[p["actual"]][p["predicted"]] += 1

    total = len(predictions)
    correct = sum(confusion[c][c] for c in codes)
    top3 = sum(p["actual"] in p["top3"] for p in predictions)
    per_class = {
        c: {
            "count": sum(confusion[c].values()),
            "correct": confusion[c][c],
            "accuracy": round(confusion[c][c] / max(1, sum(confusion[c].values())), 4),
        }
        for c in codes
    }
    result = {
        "name": name,
        "date": datetime.now().isoformat(timespec="seconds"),
        **extra,
        "images": total,
        "accuracy": round(correct / total, 4),
        "top3_accuracy": round(top3 / total, 4),
        "per_class": per_class,
        "confusion": confusion,
        "predictions": predictions,
    }

    results_dir = AI_DIR / "results"
    results_dir.mkdir(exist_ok=True)
    (results_dir / f"{name}.json").write_text(json.dumps(result, ensure_ascii=False, indent=1), encoding="utf-8")

    lines = [f"# {name}", ""]
    lines += [f"- {key}: {value}" for key, value in extra.items() if not isinstance(value, (dict, list))]
    lines += [
        f"- Fotoğraf: {total} · Doğruluk: **%{100 * result['accuracy']:.1f}** · İlk 3'te doğru: %{100 * result['top3_accuracy']:.1f}",
        "",
        "## Kategori bazında",
        "",
        "| Kategori | Fotoğraf | Doğru | Doğruluk |",
        "|---|---|---|---|",
    ]
    lines += [f"| {c} | {per_class[c]['count']} | {per_class[c]['correct']} | %{100 * per_class[c]['accuracy']:.0f} |" for c in codes]
    lines += ["", "## Karışıklık matrisi (satır: gerçek, sütun: tahmin)", "",
              "| | " + " | ".join(codes) + " |", "|---|" + "---|" * len(codes)]
    lines += [f"| **{a}** | " + " | ".join(str(confusion[a][p]) for p in codes) + " |" for a in codes]
    (results_dir / f"{name}.md").write_text("\n".join(lines) + "\n", encoding="utf-8")

    print(f"{name}: doğruluk %{100 * result['accuracy']:.1f} · ilk 3 %{100 * result['top3_accuracy']:.1f}")
    for c in codes:
        print(f"  {c:13s} {per_class[c]['correct']:3d}/{per_class[c]['count']:3d}  %{100 * per_class[c]['accuracy']:.0f}")
    return result
