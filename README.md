# Opti runtime

The build of llama.cpp that runs Opti model files, such as [Opti 27B](https://huggingface.co/kacaforyah/Opti-27B).

Opti is a patent-pending compression method (U.S. Provisional Patent Application No. 64/154,967, filed September 15, 2026).
An Opti model file is a normal GGUF that also carries a small extra network for each transformer block. This runtime is a
patch on llama.cpp that loads those tensors and executes that network on each block's output during inference. Everything
else, from the tokenizer to the sampler to the server, is stock llama.cpp. Stock llama.cpp refuses Opti files because of
the extra tensors; this build accepts them and behaves identically to stock llama.cpp on ordinary files.

What the patch does **not** contain is how the extra network is trained. That is the proprietary part of Opti, and it is
not in this repository, the model file, or the patent notice.

## Build

The patch applies to llama.cpp commit `6a1a922d269908a29cbd4b49c27e6a8e7fd10fae`.

```bash
git clone https://github.com/ggml-org/llama.cpp
cd llama.cpp
git checkout 6a1a922d269908a29cbd4b49c27e6a8e7fd10fae
git apply /path/to/opti-runtime.patch
```

NVIDIA (set the architectures for your card; 86 = RTX 3090, 89 = RTX 4090 / L40S, 90 = H100):

```bash
cmake -B build -DGGML_CUDA=ON -DCMAKE_CUDA_ARCHITECTURES="86;89" -DCMAKE_BUILD_TYPE=Release
cmake --build build --config Release -j --target llama-server llama-cli llama-perplexity
```

Apple Silicon (Metal is on by default):

```bash
cmake -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build --config Release -j --target llama-server llama-cli llama-perplexity
```

CPU only: the same as Apple Silicon on any machine. `build.sh` in this repository runs the steps above.

## Run

```bash
build/bin/llama-server -m Opti-27B.gguf --mmproj Opti-27B-mmproj-f16.gguf -ngl 999 -c 16384 --reasoning on
```

That serves the OpenAI-compatible API on port 8080 with image input enabled. Every llama-server flag works as usual.

## Reproduce the numbers

The perplexity table on the model card was produced with `llama-perplexity` on wikitext-2, 1,024-token windows, 96 windows.
Get the test file with llama.cpp's own script (`scripts/get-wikitext-2.sh`), then:

```bash
build/bin/llama-perplexity -m Opti-27B.gguf -f wiki.test.raw -c 1024 --chunks 96 -ngl 999
```

Expected: `Final estimate: PPL = 6.4865 +/- 0.0703` on an RTX 3090 with this build. Other GPUs and Metal land within about
0.01 of that; the llama.cpp reference files in the table (Q4_K_M 6.457, IQ3_XXS 6.928, IQ2_M 7.318) are the standard
quantizations of the same model, measured the same way on the same machine.

## Compatibility

- Files: any GGUF. Opti files are detected by their `corr.*` metadata keys; a file without them runs exactly as on stock llama.cpp.
- Verified on RTX 3090 (sm_86), RTX 4090 and L40S (sm_89), H100 (sm_90), and Apple Silicon (Metal).
- The patch touches the model loader, the recurrent-state memory, the Qwen3.5-family graph, and one CUDA kernel's kernel-width
  limit. It adds no new dependencies.

## License

This patch is released under the Opti Runtime License (see `LICENSE`): you may build, run, modify and share it for evaluation,
research and personal use; commercial use and commercial distribution require a license. llama.cpp itself is MIT-licensed
(copyright the ggml authors); its license and notices apply to the unpatched code and remain in the tree.

Commercial licenses, and the hosted API, are available through the Hugging Face profile that hosts the model.
