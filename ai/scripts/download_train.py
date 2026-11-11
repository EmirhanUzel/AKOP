"""Linear probe için eğitim fotoğraflarını indirir (test setiyle çakışmadan).

Kaynaklar:
- SF 311 Cases (DataSF): kayıt verisi PDDL; fotoğraflar vatandaşlara ait, yalnızca yerel kullanım.
- Road Issues Detection Dataset (Hugging Face): CC0-1.0.

Kullanım (ai klasöründen):
    .venv/bin/python scripts/download_train.py --per-category 150

Çıktı: data/train/<KATEGORI_KODU>/ ve data/train/manifest_train.json
Etiketler elle kontrol edilmez; eğitim verisinde bir miktar gürültü olması beklenir.
"""

import argparse
import hashlib
import json
import random
import urllib.parse
import urllib.request
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

from huggingface_hub import HfApi, hf_hub_download

AI_DIR = Path(__file__).resolve().parent.parent
SF_API = "https://data.sfgov.org/resource/vw6y-z8j6.json"
HF_REPO = "Programmer-RD-AI/road-issues-detection-dataset"
SEED = 7  # test seti 42 ile seçildi; farklı tohum

# Her kategori: (kaynak, SF filtresi veya HF klasörü, pay)
PLAN = {
    "ROAD_DAMAGE": [("sf", "service_name='Sidewalk and Curb' AND service_subtype='pavement_defect'", 0.5),
                    ("hf", "data/Road Issues/Pothole Issues", 0.5)],
    "WATER_LEAK": [("sf", "service_name='Sewer' AND service_subtype='water_leak'", 1.0)],
    "LIGHTING": [("sf", "service_name='Streetlights' AND service_subtype='light'", 1.0)],
    "WASTE": [("sf", "service_name='Street and Sidewalk Cleaning' AND service_subtype='garbage_and_debris'", 1.0)],
    "SIDEWALK": [("sf", "service_name='Sidewalk and Curb' AND service_subtype='sidewalk_defect'", 1.0)],
    "PARK": [("sf", "service_name='Tree Maintenance' AND service_subtype='damaged_tree'", 0.5),
             ("sf", "service_name='Tree Maintenance' AND service_subtype='landscaping'", 0.5)],
    "TRAFFIC_SIGN": [("sf", "service_name='MTA Parking Traffic Signs High Priority' AND service_subtype in('stop','warning')", 0.7),
                     ("hf", "data/Road Issues/Broken Road Sign Issues", 0.3)],
    "OTHER": [("sf", "service_name='Graffiti Public'", 0.7),
              ("hf", "data/Public Cleanliness + Environmental Issues/Vandalism Issues", 0.3)],
}


def test_identifiers() -> tuple[set[str], set[str]]:
    test_dir = AI_DIR / "data" / "test"
    sf_ids, hf_paths = set(), set()
    for name, key, target in (("manifest_sf.json", "service_request_id", sf_ids), ("manifest_hf.json", "path", hf_paths)):
        path = test_dir / name
        if path.exists():
            target.update(str(item[key]) for item in json.loads(path.read_text(encoding="utf-8")))
    return sf_ids, hf_paths


def fetch(url: str) -> bytes | None:
    try:
        request = urllib.request.Request(url, headers={"User-Agent": "AKOP-research/1.0"})
        with urllib.request.urlopen(request, timeout=30) as response:
            if not response.headers.get("Content-Type", "").startswith("image/"):
                return None
            data = response.read()
            return data if len(data) >= 5000 else None
    except Exception:
        return None


def sf_candidates(where: str, exclude: set[str], rng: random.Random) -> list[dict]:
    query = {
        "$select": "service_request_id, service_name, service_subtype, media_url",
        "$where": f"media_url IS NOT NULL AND requested_datetime > '2024-06-01' AND {where}",
        "$order": "requested_datetime DESC",
        "$limit": "3000",
    }
    with urllib.request.urlopen(SF_API + "?" + urllib.parse.urlencode(query), timeout=120) as response:
        rows = json.load(response)
    rows = [r for r in rows
            if "cloudinary" in r["media_url"]["url"]
            and r["media_url"]["url"].lower().endswith((".jpg", ".jpeg", ".png"))
            and str(r["service_request_id"]) not in exclude]
    rng.shuffle(rows)
    return rows


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--per-category", type=int, default=150)
    args = parser.parse_args()

    rng = random.Random(SEED)
    sf_exclude, hf_exclude = test_identifiers()
    hf_files = HfApi().list_repo_files(HF_REPO, repo_type="dataset")
    train_dir = AI_DIR / "data" / "train"
    manifest = []

    for code, sources in PLAN.items():
        out_dir = train_dir / code
        out_dir.mkdir(parents=True, exist_ok=True)
        saved = 0
        for kind, selector, share in sources:
            want = round(args.per_category * share)
            got = 0
            if kind == "sf":
                rows = sf_candidates(selector, sf_exclude, rng)
                with ThreadPoolExecutor(max_workers=8) as pool:
                    for row, data in zip(rows, pool.map(lambda r: fetch(r["media_url"]["url"]), rows)):
                        if got >= want:
                            break
                        if data is None:
                            continue
                        name = f"sf_{row['service_request_id']}.jpg"
                        (out_dir / name).write_bytes(data)
                        manifest.append({"file": f"{code}/{name}", "source": "SF 311", "service_request_id": row["service_request_id"],
                                         "subtype": row.get("service_subtype"), "url": row["media_url"]["url"]})
                        got += 1
            else:
                images = sorted(f for f in hf_files
                                if f.startswith(selector + "/") and f.lower().endswith((".jpg", ".jpeg", ".png"))
                                and f not in hf_exclude)
                for path in rng.sample(images, min(want, len(images))):
                    local = hf_hub_download(HF_REPO, path, repo_type="dataset")
                    name = f"hf_{hashlib.sha1(path.encode()).hexdigest()[:12]}{Path(path).suffix.lower()}"
                    (out_dir / name).write_bytes(Path(local).read_bytes())
                    manifest.append({"file": f"{code}/{name}", "source": "Road Issues (HF, CC0)", "path": path})
                    got += 1
            saved += got
        print(f"{code:13s} {saved}")

    (train_dir / "manifest_train.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=1), encoding="utf-8")
    print("toplam:", len(manifest))


if __name__ == "__main__":
    main()
