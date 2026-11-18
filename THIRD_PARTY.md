# Third-party components

ResQ's own code (launchers, chat page, builder, docs) is MIT-licensed; see [LICENSE](LICENSE).
`build-stick.sh` downloads the components below from their official sources. None of them are stored in this repository, and each keeps its own license.

| Component | Version | Source | License |
|---|---|---|---|
| Ollama (Linux, Windows, macOS) | 0.32.5 | [github.com/ollama/ollama](https://github.com/ollama/ollama) | MIT |
| kiwix-serve (kiwix-tools) | 3.8.1 | [download.kiwix.org](https://download.kiwix.org/release/kiwix-tools/) | GPL-3.0 |
| Kiwix for Android | 3.13.0 | [download.kiwix.org](https://download.kiwix.org/release/kiwix-android/) | GPL-3.0 |
| PocketPal AI (Android) | 1.24.0 | [github.com/a-ghorbani/pocketpal-ai](https://github.com/a-ghorbani/pocketpal-ai) | MIT |
| Qwen 2.5 1.5B Instruct (`resq:1.5b`) | Ollama `qwen2.5:1.5b` | [ollama.com/library/qwen2.5](https://ollama.com/library/qwen2.5) | Apache-2.0 |
| Qwen 2.5 3B Instruct (`resq:3b`) | Ollama `qwen2.5:3b` | [ollama.com/library/qwen2.5](https://ollama.com/library/qwen2.5) | **Qwen Research License (non-commercial)** |
| DeepSeek-R1 Distill 1.5B / 7B (`resq-think`) | Ollama `deepseek-r1:1.5b`, `:7b` | [ollama.com/library/deepseek-r1](https://ollama.com/library/deepseek-r1) | MIT (base models: Apache-2.0) |
| Qwen 2.5 VL 7B (`resq-vision:7b`) | Ollama `qwen2.5vl:7b` | [ollama.com/library/qwen2.5vl](https://ollama.com/library/qwen2.5vl) | Apache-2.0 |
| Wikipedia ZIM files (Italian, Italian medicine, English WikiMed) | 2026-10 / 2026-11 | [download.kiwix.org/zim](https://download.kiwix.org/zim/wikipedia/) | Text: CC BY-SA 4.0 (Wikipedia contributors) |
| "Io non rischio" leaflets and multi-hazard booklet | 2024 / 2025 | Dipartimento della Protezione Civile and Prefetture ([iononrischio.gov.it](https://www.iononrischio.gov.it)) | © DPC. Downloaded by the builder for personal use, not redistributed here. |

Check each project's license before redistributing a built stick, especially for commercial use.
