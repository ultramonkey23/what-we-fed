#!/usr/bin/env python3
"""Agent-usable asset generation orchestration.

Supports:
- Manifest-driven image generation through ComfyUI's HTTP API.
- Existing deterministic procedural generation scripts in this repo.

This intentionally excludes GUI-only tools from automation.
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from dataclasses import dataclass
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
MANIFEST_PATH = ROOT / "docs" / "ai" / "ASSET_MANIFEST.json"
IMAGE_CATEGORIES = {"creature_sprite", "projectile"}
STYLE_ANCHOR_SUFFIX = (
    "in the style of 2D dark fantasy concept art, high-contrast chiaroscuro, "
    "biological horror, visceral textures, bone-carving aesthetics, sharp silhouettes, "
    "muted palette of charcoal-grey, dried-blood crimson, and tarnished gold, "
    "no glowing particles, no soft gradients, flat 2D game asset, white background, "
    "inspired by Darkest Dungeon and Bloodborne."
)


@dataclass(frozen=True)
class ManifestEntry:
    """Minimal entry view used by this orchestrator."""

    id: str
    category: str
    status: str
    target_path: str
    prompt: str

    @property
    def target_fs_path(self) -> Path:
        if not self.target_path.startswith("res://"):
            raise ValueError(f"{self.id}: unsupported target_path '{self.target_path}'")
        rel = self.target_path.removeprefix("res://").replace("\\", "/").lstrip("/")
        return ROOT / rel


def _load_manifest(path: Path) -> dict[str, Any]:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError as exc:
        raise SystemExit(f"Manifest not found: {path}") from exc
    except json.JSONDecodeError as exc:
        raise SystemExit(f"Manifest JSON decode failed: {path}: {exc}") from exc


def _manifest_entries(path: Path) -> list[ManifestEntry]:
    raw = _load_manifest(path)
    items = raw.get("manifest")
    if not isinstance(items, list):
        raise SystemExit(f"Invalid manifest format in {path}: missing 'manifest' array")

    entries: list[ManifestEntry] = []
    for item in items:
        if not isinstance(item, dict):
            continue
        entry_id = str(item.get("id", "")).strip()
        category = str(item.get("category", "")).strip()
        status = str(item.get("status", "")).strip().lower()
        target_path = str(item.get("target_path", "")).strip()
        prompt = str(item.get("prompt", "")).strip()
        if not entry_id or not category or not status or not target_path:
            continue
        entries.append(
            ManifestEntry(
                id=entry_id,
                category=category,
                status=status,
                target_path=target_path,
                prompt=prompt,
            )
        )
    return entries


def _filter_entries(
    entries: list[ManifestEntry],
    *,
    status: str | None,
    category: str | None,
    ids: set[str] | None,
    image_only: bool,
) -> list[ManifestEntry]:
    result = entries
    if status:
        want = status.strip().lower()
        result = [e for e in result if e.status == want]
    if category:
        result = [e for e in result if e.category == category]
    if ids:
        result = [e for e in result if e.id in ids]
    if image_only:
        result = [e for e in result if e.category in IMAGE_CATEGORIES]
    return result


def _normalize_base_url(url: str) -> str:
    return url.rstrip("/")


def _probe_comfy_api(base_url: str, *, timeout_seconds: float = 2.0) -> bool:
    req = urllib.request.Request(url=f"{base_url}/system_stats")
    try:
        with urllib.request.urlopen(req, timeout=timeout_seconds) as response:
            raw = response.read().decode("utf-8")
        json.loads(raw) if raw else {}
        return True
    except (urllib.error.URLError, json.JSONDecodeError):
        return False


def _discover_comfy_local_ports() -> list[int]:
    user_home = Path.home()
    candidate_dirs = [
        user_home / "Documents" / "ComfyUI" / "user",
        user_home / "ComfyUI" / "user",
    ]

    ports: list[int] = []
    for directory in candidate_dirs:
        if not directory.is_dir():
            continue
        logs = sorted(
            directory.glob("comfyui_*.log"),
            key=lambda p: p.stat().st_mtime,
            reverse=True,
        )
        for log_path in logs[:6]:
            match = re.fullmatch(r"comfyui_(\d+)\.log", log_path.name)
            if not match:
                continue
            try:
                port = int(match.group(1))
            except ValueError:
                continue
            ports.append(port)

    # Keep insertion order while removing duplicates.
    return list(dict.fromkeys(ports))


def _resolve_comfy_base_url(preferred_url: str) -> str:
    preferred = _normalize_base_url(preferred_url)
    candidates: list[str] = [preferred]

    if preferred in ("http://127.0.0.1:8188", "http://localhost:8188"):
        candidates.extend(["http://127.0.0.1:8000", "http://localhost:8000"])
        for port in _discover_comfy_local_ports():
            candidates.extend([f"http://127.0.0.1:{port}", f"http://localhost:{port}"])

    # Keep insertion order while removing duplicates.
    unique_candidates = list(dict.fromkeys(candidates))
    for base_url in unique_candidates:
        if _probe_comfy_api(base_url):
            if base_url != preferred:
                print(f"info: ComfyUI reachable at {base_url} (requested {preferred})")
            return base_url

    tried = ", ".join(unique_candidates)
    raise RuntimeError(
        "ComfyUI API is not reachable. "
        f"Tried: {tried}. "
        "Start ComfyUI and/or pass --comfyui-url explicitly (for example: http://127.0.0.1:8000)."
    )


def _http_json(url: str, payload: dict[str, Any] | None = None) -> dict[str, Any]:
    data = None
    headers = {}
    if payload is not None:
        data = json.dumps(payload).encode("utf-8")
        headers["Content-Type"] = "application/json"
    req = urllib.request.Request(url=url, data=data, headers=headers)
    try:
        with urllib.request.urlopen(req, timeout=30) as response:
            raw = response.read().decode("utf-8")
            return json.loads(raw) if raw else {}
    except urllib.error.URLError as exc:
        raise RuntimeError(f"HTTP request failed: {url}: {exc}") from exc
    except json.JSONDecodeError as exc:
        raise RuntimeError(f"Invalid JSON response from {url}: {exc}") from exc


def _comfy_workflow(
    *,
    checkpoint: str,
    prompt: str,
    negative_prompt: str,
    width: int,
    height: int,
    steps: int,
    cfg: float,
    sampler: str,
    seed: int,
    filename_prefix: str,
) -> dict[str, Any]:
    return {
        "4": {
            "inputs": {"ckpt_name": checkpoint},
            "class_type": "CheckpointLoaderSimple",
        },
        "5": {
            "inputs": {"width": width, "height": height, "batch_size": 1},
            "class_type": "EmptyLatentImage",
        },
        "6": {
            "inputs": {"text": prompt, "clip": ["4", 1]},
            "class_type": "CLIPTextEncode",
        },
        "7": {
            "inputs": {"text": negative_prompt, "clip": ["4", 1]},
            "class_type": "CLIPTextEncode",
        },
        "3": {
            "inputs": {
                "seed": seed,
                "steps": steps,
                "cfg": cfg,
                "sampler_name": sampler,
                "scheduler": "normal",
                "denoise": 1,
                "model": ["4", 0],
                "positive": ["6", 0],
                "negative": ["7", 0],
                "latent_image": ["5", 0],
            },
            "class_type": "KSampler",
        },
        "8": {
            "inputs": {"samples": ["3", 0], "vae": ["4", 2]},
            "class_type": "VAEDecode",
        },
        "9": {
            "inputs": {"filename_prefix": filename_prefix, "images": ["8", 0]},
            "class_type": "SaveImage",
        },
    }


def _queue_comfy_prompt(base_url: str, workflow: dict[str, Any]) -> str:
    payload = {
        "prompt": workflow,
        "client_id": "what-we-fed-asset-orchestrator",
    }
    response = _http_json(f"{base_url}/prompt", payload)
    prompt_id = str(response.get("prompt_id", "")).strip()
    if not prompt_id:
        raise RuntimeError(f"ComfyUI did not return prompt_id: {response}")
    return prompt_id


def _wait_for_comfy_images(
    base_url: str,
    prompt_id: str,
    *,
    timeout_seconds: float,
    poll_interval_seconds: float,
) -> list[dict[str, Any]]:
    deadline = time.time() + timeout_seconds
    history_url = f"{base_url}/history/{prompt_id}"

    while time.time() < deadline:
        history = _http_json(history_url)
        prompt_data = history.get(prompt_id)
        if isinstance(prompt_data, dict):
            outputs = prompt_data.get("outputs", {})
            if isinstance(outputs, dict):
                for node_data in outputs.values():
                    if not isinstance(node_data, dict):
                        continue
                    images = node_data.get("images")
                    if isinstance(images, list) and images:
                        return [img for img in images if isinstance(img, dict)]
        time.sleep(poll_interval_seconds)
    raise TimeoutError(f"Timed out waiting for ComfyUI output for prompt {prompt_id}")


def _download_comfy_image(base_url: str, image_meta: dict[str, Any], out_path: Path) -> None:
    filename = str(image_meta.get("filename", "")).strip()
    subfolder = str(image_meta.get("subfolder", "")).strip()
    out_type = str(image_meta.get("type", "output")).strip() or "output"
    if not filename:
        raise RuntimeError(f"ComfyUI image metadata missing filename: {image_meta}")

    query = urllib.parse.urlencode(
        {"filename": filename, "subfolder": subfolder, "type": out_type}
    )
    url = f"{base_url}/view?{query}"
    req = urllib.request.Request(url=url)
    try:
        with urllib.request.urlopen(req, timeout=30) as response:
            image_bytes = response.read()
    except urllib.error.URLError as exc:
        raise RuntimeError(f"Failed to download ComfyUI image: {url}: {exc}") from exc

    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_bytes(image_bytes)


def _append_style_anchor(prompt: str) -> str:
    if not prompt.strip():
        return STYLE_ANCHOR_SUFFIX
    low = prompt.lower()
    if "dark fantasy" in low and "sharp_silhouette" in low:
        return prompt
    return f"{prompt.rstrip('. ')}. {STYLE_ANCHOR_SUFFIX}"


def _manifest_list_cmd(args: argparse.Namespace) -> int:
    entries = _manifest_entries(Path(args.manifest))
    selected = _filter_entries(
        entries,
        status=args.status,
        category=args.category,
        ids=set(args.ids) if args.ids else None,
        image_only=args.image_only,
    )

    if args.json:
        print(
            json.dumps(
                [
                    {
                        "id": e.id,
                        "category": e.category,
                        "status": e.status,
                        "target_path": e.target_path,
                    }
                    for e in selected
                ],
                indent=2,
            )
        )
        return 0

    if not selected:
        print("No manifest entries matched filters.")
        return 0

    print(f"Matched entries: {len(selected)}")
    for e in selected:
        print(f"- {e.id} [{e.category}] ({e.status}) -> {e.target_path}")
    return 0


def _manifest_generate_cmd(args: argparse.Namespace) -> int:
    if args.provider != "comfyui":
        raise SystemExit("Unsupported provider. Use '--provider comfyui'.")
    if not args.checkpoint:
        raise SystemExit("--checkpoint is required for comfyui generation.")

    entries = _manifest_entries(Path(args.manifest))
    selected = _filter_entries(
        entries,
        status=args.status,
        category=args.category,
        ids=set(args.ids) if args.ids else None,
        image_only=True,
    )
    if args.limit is not None:
        selected = selected[: args.limit]

    if not selected:
        print("No manifest image entries matched filters.")
        return 0

    base_url = ""
    if not args.dry_run:
        base_url = _resolve_comfy_base_url(args.comfyui_url)
    generated = 0
    skipped = 0

    for entry in selected:
        target = entry.target_fs_path
        if target.exists() and not args.overwrite:
            print(f"skip {entry.id}: target exists ({target.relative_to(ROOT)})")
            skipped += 1
            continue

        prompt = entry.prompt.strip()
        if not prompt:
            print(f"skip {entry.id}: missing prompt in manifest")
            skipped += 1
            continue
        if not args.no_style_anchor:
            prompt = _append_style_anchor(prompt)

        if args.dry_run:
            print(f"dry-run {entry.id}: {target.relative_to(ROOT)}")
            continue

        workflow = _comfy_workflow(
            checkpoint=args.checkpoint,
            prompt=prompt,
            negative_prompt=args.negative_prompt,
            width=args.width,
            height=args.height,
            steps=args.steps,
            cfg=args.cfg,
            sampler=args.sampler,
            seed=args.seed + generated if args.seed >= 0 else int(time.time() * 1000) + generated,
            filename_prefix=f"what_we_fed/{entry.id}",
        )
        prompt_id = _queue_comfy_prompt(base_url, workflow)
        images = _wait_for_comfy_images(
            base_url,
            prompt_id,
            timeout_seconds=args.timeout_seconds,
            poll_interval_seconds=args.poll_seconds,
        )
        _download_comfy_image(base_url, images[0], target)
        print(f"generated {entry.id}: {target.relative_to(ROOT)}")
        generated += 1

    print(f"done: generated={generated} skipped={skipped} dry_run={args.dry_run}")
    return 0


def _run_python_script(script_path: Path) -> None:
    result = subprocess.run(
        [sys.executable, str(script_path)],
        cwd=str(ROOT),
        check=False,
    )
    if result.returncode != 0:
        raise RuntimeError(f"Script failed with exit code {result.returncode}: {script_path}")


def _procedural_refresh_cmd(args: argparse.Namespace) -> int:
    scripts: list[Path] = []
    if args.preset in ("combat_projectiles", "all"):
        scripts.append(ROOT / "tools" / "generate_shot_sprites.py")
    if args.preset in ("v2_visuals", "all"):
        scripts.append(ROOT / "tools" / "generate_visual_replacements.py")

    for script in scripts:
        print(f"run {script.relative_to(ROOT)}")
        _run_python_script(script)
    print(f"done: ran {len(scripts)} script(s)")
    return 0


def _build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="What We Fed agent-usable asset generation orchestrator."
    )
    sub = parser.add_subparsers(dest="command", required=True)

    p_list = sub.add_parser("manifest-list", help="List manifest entries.")
    p_list.add_argument("--manifest", default=str(MANIFEST_PATH))
    p_list.add_argument("--status", default="pending")
    p_list.add_argument("--category")
    p_list.add_argument("--ids", nargs="*")
    p_list.add_argument("--image-only", action="store_true")
    p_list.add_argument("--json", action="store_true")
    p_list.set_defaults(func=_manifest_list_cmd)

    p_gen = sub.add_parser(
        "manifest-generate",
        help="Generate pending image assets from manifest using a headless provider.",
    )
    p_gen.add_argument("--manifest", default=str(MANIFEST_PATH))
    p_gen.add_argument("--provider", choices=["comfyui"], default="comfyui")
    p_gen.add_argument("--status", default="pending")
    p_gen.add_argument("--category")
    p_gen.add_argument("--ids", nargs="*")
    p_gen.add_argument("--limit", type=int)
    p_gen.add_argument("--overwrite", action="store_true")
    p_gen.add_argument("--dry-run", action="store_true")
    p_gen.add_argument("--no-style-anchor", action="store_true")

    p_gen.add_argument("--comfyui-url", default="http://127.0.0.1:8188")
    p_gen.add_argument("--checkpoint", required=False)
    p_gen.add_argument("--negative-prompt", default="blurry, lowres, text, logo, watermark")
    p_gen.add_argument("--width", type=int, default=1024)
    p_gen.add_argument("--height", type=int, default=1024)
    p_gen.add_argument("--steps", type=int, default=28)
    p_gen.add_argument("--cfg", type=float, default=6.5)
    p_gen.add_argument("--sampler", default="euler")
    p_gen.add_argument(
        "--seed",
        type=int,
        default=-1,
        help="Base seed. Use -1 to derive from current time.",
    )
    p_gen.add_argument("--timeout-seconds", type=float, default=180.0)
    p_gen.add_argument("--poll-seconds", type=float, default=1.0)
    p_gen.set_defaults(func=_manifest_generate_cmd)

    p_proc = sub.add_parser(
        "procedural-refresh",
        help="Run deterministic, in-repo procedural generation scripts.",
    )
    p_proc.add_argument(
        "--preset",
        choices=["combat_projectiles", "v2_visuals", "all"],
        default="all",
    )
    p_proc.set_defaults(func=_procedural_refresh_cmd)
    return parser


def main() -> int:
    parser = _build_parser()
    args = parser.parse_args()
    try:
        return int(args.func(args))
    except Exception as exc:  # pragma: no cover - top-level error surface
        print(f"error: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
