#!/usr/bin/env bash
# Builds the Opti runtime: llama.cpp at the pinned commit plus opti-runtime.patch.
#   ./build.sh            # Metal on Apple Silicon, CPU elsewhere
#   ./build.sh cuda 86    # NVIDIA, CUDA architectures (86 = RTX 3090, 89 = RTX 4090 / L40S, 90 = H100)
set -euo pipefail
COMMIT=6a1a922d269908a29cbd4b49c27e6a8e7fd10fae
HERE=$(cd "$(dirname "$0")" && pwd)
[ -d llama.cpp ] || git clone https://github.com/ggml-org/llama.cpp
cd llama.cpp
git checkout -q "$COMMIT"
git apply --check "$HERE/opti-runtime.patch" 2>/dev/null && git apply "$HERE/opti-runtime.patch" || echo "patch already applied"
if [ "${1:-}" = "cuda" ]; then
  cmake -B build -DGGML_CUDA=ON -DCMAKE_CUDA_ARCHITECTURES="${2:-86;89}" -DCMAKE_BUILD_TYPE=Release
else
  cmake -B build -DCMAKE_BUILD_TYPE=Release
fi
cmake --build build --config Release -j --target llama-server llama-cli llama-perplexity
echo "built: $(pwd)/build/bin/llama-server, llama-cli, llama-perplexity"
