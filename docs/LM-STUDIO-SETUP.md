# Complete LM Studio Setup on Apple Silicon macOS

This guide starts before LM Studio is installed and ends with a local OpenAI-compatible model endpoint ready for OpenCode.

## What LM Studio provides

LM Studio has three relevant layers:

- **LM Studio Desktop** provides model discovery, downloads, chat, settings, and the Developer server interface.
- **The `lms` CLI** manages models, runtimes, loading, logs, and the local server from Terminal.
- **The local API server** lets OpenCode and other programs send requests to loaded models.

The desktop app and CLI manage the model. The API server is the bridge OpenCode uses.

## Hardware and storage planning

The reference setup uses an Apple Silicon MacBook Pro with 24 GB of unified memory.

The three language models occupy about 26 GB on disk in the tested variants:

| Model | Approximate tested disk size |
|---|---:|
| Qwen 3.5 9B | 5.98 GB |
| Gemma 3 12B | 8.07 GB |
| GPT-OSS 20B | 12.10 GB |

Keep additional free space for downloads, temporary files, context caches, projects, and macOS. Download size and memory requirements vary by quantization and model format.

Do not assume all three models can remain loaded simultaneously on a 24 GB machine. Keep one primary language model loaded for the most predictable performance.

### Smaller Macs

This has not been tested on a Mac with less than 24 GB. A reasonable approach is to download only Qwen 3.5 9B (`lms get qwen/qwen3.5-9b`) instead of using `--download-models`, run `lms load --estimate-only` first, and begin with a context length of 16384 or lower. The bootstrap loads Qwen with a 32768 context, so on a smaller Mac run `lms unload --all` afterwards and reload it with the smaller context shown below.

## Option A: Install with Homebrew

```bash
brew install --cask lm-studio
open -a "LM Studio"
```

Complete any first-launch screens. LM Studio must be launched at least once before the bundled `lms` CLI is available.

Official Homebrew cask: [LM Studio](https://formulae.brew.sh/cask/lm-studio)

## Option B: Download the application manually

Download the Apple Silicon build from:

[LM Studio download page](https://lmstudio.ai/download?os=mac)

Open the downloaded disk image, move LM Studio to Applications, and launch it once.

## Verify the CLI

```bash
lms --help
lms runtime ls
```

The CLI ships with LM Studio. If `lms` is not found, reopen LM Studio, complete its first launch, and open a new Terminal window.

If it is still not found, LM Studio's own documentation says to add it to your `PATH` with the bootstrap command that ships next to it, then open a new Terminal window:

```bash
~/.lmstudio/bin/lms bootstrap
```

The repository scripts also look in `~/.lmstudio/bin` themselves, so they work even before your shell finds `lms`.

Official reference: [LM Studio CLI](https://lmstudio.ai/docs/cli)

## Download models in the desktop app

1. Open LM Studio.
2. Open **Discover**.
3. Search for the model name.
4. Choose a quantization that fits the Mac.
5. Download the model.
6. Repeat for each desired model.

Suggested search names:

```text
Qwen 3.5 9B
Gemma 3 12B
GPT-OSS 20B
Nomic Embed Text v1.5
```

## Download models with the CLI

Search and download the three language models:

```bash
lms get qwen/qwen3.5-9b
lms get google/gemma-3-12b
lms get openai/gpt-oss-20b
```

The optional embedding model is much smaller. Its download name differs from the key that LM Studio lists afterwards:

```bash
lms get nomic-ai/nomic-embed-text-v1.5
lms ls   # lists it as text-embedding-nomic-embed-text-v1.5
```

If more than one format or quantization is available, LM Studio asks which one to download. To deliberately inspect all download options:

```bash
lms get qwen/qwen3.5-9b --always-show-download-options
```

Apple Silicon supports MLX and GGUF models. Filter search results when a particular runtime is desired:

```bash
lms get qwen/qwen3.5-9b --mlx
lms get qwen/qwen3.5-9b --gguf
```

Exact catalog results can change as publishers release new variants. Confirm the final local model key with `lms ls` and use that exact key in OpenCode.

Official reference: [`lms get`](https://lmstudio.ai/docs/cli/local-models/get)

## Inspect downloaded and loaded models

```bash
lms ls
lms ps
```

`lms ls` lists files available on disk. `lms ps` lists models currently loaded into memory.

## Estimate memory before loading

```bash
lms load --estimate-only qwen/qwen3.5-9b --context-length 32768
lms load --estimate-only google/gemma-3-12b --context-length 16384
lms load --estimate-only openai/gpt-oss-20b --context-length 16384
```

Context length consumes additional memory. Start conservatively if the estimate approaches available unified memory.

## Load the primary coding model

```bash
lms load qwen/qwen3.5-9b --gpu max --context-length 32768
```

If memory pressure is high, unload all models and retry with a smaller context:

```bash
lms unload --all
lms load qwen/qwen3.5-9b --gpu max --context-length 16384
```

An idle time-to-live can release memory automatically:

```bash
lms load qwen/qwen3.5-9b --gpu max --context-length 16384 --ttl 3600
```

Official reference: [`lms load`](https://lmstudio.ai/docs/cli/local-models/load)

## Start the API server

In LM Studio Desktop:

1. Open **Developer**.
2. Select or confirm the loaded model.
3. Start the local server.
4. Keep the host bound to localhost for this setup.

Command-line equivalent:

```bash
lms server start --port 1234 --bind 127.0.0.1
lms server status
```

Using `127.0.0.1` prevents other devices on the network from contacting LM Studio directly. OpenCode remote pairing can expose the OpenCode interface while LM Studio remains local-only.

Official reference: [LM Studio local server](https://lmstudio.ai/docs/developer/core/server)

## Verify both API styles

Check the native LM Studio model endpoint:

```bash
curl -sS http://127.0.0.1:1234/api/v1/models | jq
```

Check the OpenAI-compatible endpoint used by this OpenCode configuration:

```bash
curl -sS http://127.0.0.1:1234/v1/models | jq
```

The native endpoint provides LM Studio-specific model management. The `/v1` endpoint provides compatibility for tools expecting OpenAI request formats.

## Run a direct inference test

```bash
curl -sS http://127.0.0.1:1234/v1/chat/completions \
  -H 'Content-Type: application/json' \
  -d '{
    "model": "qwen/qwen3.5-9b",
    "messages": [
      {"role": "user", "content": "Reply with exactly LM_STUDIO_OK"}
    ],
    "temperature": 0
  }' | jq -r '.choices[0].message.content'
```

Expected response:

```text
LM_STUDIO_OK
```

`./scripts/verify-local-stack.sh --inference` sends this same request and reports PASS or FAIL.

## Verify tool-call capability

LM Studio supports custom tools through its OpenAI-compatible chat and responses endpoints. OpenCode supplies the actual file and shell tools. The selected model must be capable of reliably producing structured tool requests.

Official reference: [LM Studio tool use](https://lmstudio.ai/docs/developer/openai-compat/tools)

## Logs and diagnostics

Stream requests reaching LM Studio:

```bash
lms log stream
```

Useful status commands:

```bash
lms ls
lms ps
lms server status
lms runtime ls
```

These commands help separate four common problems: a missing model file, a model not loaded into memory, an inactive server, or an unavailable runtime.

## Updating LM Studio

For a Homebrew installation:

```bash
brew update
brew upgrade --cask lm-studio
```

LM Studio can also update itself. Check model compatibility and rerun the repository verification script after a major update.

## Fully local operation

After the application, runtime, and models are downloaded, LM Studio inference can operate offline. OpenCode can also use the local endpoint without paid API tokens. GitHub, package downloads, web searches, and remote pairing still require internet access.

Official reference: [LM Studio offline operation](https://lmstudio.ai/docs/app/offline)
