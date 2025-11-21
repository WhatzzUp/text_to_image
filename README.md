# text_to_image

Dockerized ComfyUI workflow: wan 2.2 image generation.json

## Contents

- `Dockerfile` - Docker container configuration for running this ComfyUI workflow
- `workflow_base.json` - Base workflow (fixed nodes) kept server-side
- `handler.py` - Accepts slim input (prompts + sampler params) and injects into the base workflow
- `example-request.json` - Minimal request payload (only variable fields)

## Usage

```bash
# Build the Docker image
docker build -t text_to_image .

# Run the container locally (exposes ComfyUI, uses custom handler)
docker run -p 8188:8188 text_to_image
```

Serverless: the handler merges your slim input into `workflow_base.json` and forwards it to the default ComfyUI worker handler.

## Slim API Request Example

See `example-request.json`. Only send:

- `prompt_positive`, `prompt_negative`
- Optional sampler settings: `steps`, `cfg`, `sampler_name`, `scheduler`, `denoise`, `seed`
