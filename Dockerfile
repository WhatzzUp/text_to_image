# Base image with comfyui worker
FROM runpod/worker-comfyui:5.5.0-base

# Default workdir
WORKDIR /workspace

# Faster startup: skip ComfyUI-Manager and disable auto-scan of model dirs
ENV COMFYUI_SKIP_MANAGER=1 \
    COMFYUI_ARGS="--headless --disable-auto-scan"

# Keep only the nodes/models that the workflow needs, drop everything else to avoid startup scans.
# Preserve ComfyUI-Manager files so the comfy CLI keeps working, but skip it at runtime via env.
RUN find /comfyui/custom_nodes -mindepth 1 -maxdepth 1 ! -name 'ComfyUI-Manager' -exec rm -rf {} + \
 && rm -rf /comfyui/models/* \
 && mkdir -p /comfyui/models/{diffusion_models,clip,vae,loras} /comfyui/custom_nodes

# Install only required custom nodes
RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/* \
 && comfy node install --exit-on-fail ComfyUI-GGUF@1.1.6 \
 && comfy node install --exit-on-fail rgthree-comfy@1.0.2511091959

# download only the models used by the workflow
RUN comfy model download --url https://huggingface.co/QuantStack/Wan2.2-T2V-A14B-GGUF/resolve/main/LowNoise/Wan2.2-T2V-A14B-LowNoise-Q8_0.gguf --relative-path models/diffusion_models --filename Wan2.2-T2V-A14B-LowNoise-Q8_0.gguf
RUN comfy model download --url https://huggingface.co/Comfy-Org/Wan_2.2_ComfyUI_Repackaged/resolve/main/split_files/vae/wan_2.1_vae.safetensors --relative-path models/vae --filename wan_2.1_vae.safetensors
RUN comfy model download --url https://huggingface.co/Comfy-Org/Wan_2.1_ComfyUI_repackaged/resolve/main/split_files/text_encoders/umt5_xxl_fp8_e4m3fn_scaled.safetensors --relative-path models/clip --filename umt5_xxl_fp8_e4m3fn_scaled.safetensors
RUN comfy model download --url https://huggingface.co/lightx2v/Wan2.2-Lightning/resolve/main/Wan2.2-T2V-A14B-4steps-lora-rank64-Seko-V1.1/low_noise_model.safetensors --relative-path models/loras --filename low_noise_model.safetensors
# copy all input data (like images or videos) into comfyui (uncomment and adjust if needed)
# COPY input/ /comfyui/input/

# Copy custom handler and base workflow
COPY handler.py workflow_base.json /workspace/
