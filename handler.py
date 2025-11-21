"""
Custom handler that lets the client send only the variable parts
(prompts, sampler params). We merge them into the stored base workflow
and then forward to the default ComfyUI worker handler.

Expected input:
{
  "prompt_positive": "...",         # required
  "prompt_negative": "...",         # required
  "steps": 8,                       # optional, defaults from base
  "cfg": 3,                         # optional
  "sampler_name": "euler",          # optional
  "scheduler": "beta",              # optional
  "denoise": 1,                     # optional
  "seed": 123456789012345           # optional; random if missing
}
"""

import copy
import json
import random

import runpod

# Import the default comfy worker handler from the base image.
import rp_handler

with open("workflow_base.json", "r", encoding="utf-8") as f:
    _BASE = json.load(f)["workflow"]


def _build_workflow(params: dict) -> dict:
    """Inject user params into a fresh copy of the base workflow."""
    wf = copy.deepcopy(_BASE)

    # Required prompts
    pos = params.get("prompt_positive")
    neg = params.get("prompt_negative")
    if not pos or not neg:
        raise ValueError("prompt_positive and prompt_negative are required")

    wf["112"]["inputs"]["text"] = pos
    wf["117"]["inputs"]["text"] = neg

    # KSampler updates (node 170)
    ks = wf["170"]["inputs"]
    if "steps" in params:
        ks["steps"] = int(params["steps"])
    if "cfg" in params:
        ks["cfg"] = float(params["cfg"])
    if "sampler_name" in params:
        ks["sampler_name"] = params["sampler_name"]
    if "scheduler" in params:
        ks["scheduler"] = params["scheduler"]
    if "denoise" in params:
        ks["denoise"] = params["denoise"]
    ks["seed"] = int(params.get("seed", random.randint(0, 2**48 - 1)))

    return {"workflow": wf}


def handler(event: dict):
    """Build full workflow and delegate to the upstream comfy handler."""
    params = event.get("input", {})
    try:
        full_input = _build_workflow(params)
    except Exception as exc:  # noqa: BLE001
        return {"error": str(exc)}

    # Preserve other event fields if present (e.g., env metadata)
    forward_event = copy.deepcopy(event)
    forward_event["input"] = full_input
    return rp_handler.handler(forward_event)


runpod.serverless.start({"handler": handler})
