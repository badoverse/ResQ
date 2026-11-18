# ResQ

**An offline emergency kit on a USB stick: AI assistant + offline Wikipedia and medical library + official emergency guides.**

ResQ runs entirely from a USB stick on Windows, macOS and Linux, with no internet, no account, no API key and no installation. Its Android folder lets you set up the same AI and library on a phone, which lasts much longer than a laptop in a blackout.

ResQ is built for **72-hour preparedness**: everything a household needs to get information, guidance and help for three days without internet or outside support. The default content is in Italian and English.

> **In an emergency, call 112.** ResQ's AI can be wrong. For health and safety, rely on the official guides and the offline library first.

*Italiano: [README.it.md](README.it.md)*

---

## What ResQ is (and what it is not)

ResQ is **not a specially trained or fine-tuned model.** It uses general-purpose open models (Qwen 2.5, DeepSeek-R1 and Qwen 2.5 VL) and gives them a fixed set of instructions ([`modelfiles/system-prompt.txt`](modelfiles/system-prompt.txt)):

- introduce itself as ResQ;
- answer in the user's language, briefly and practically;
- say "I'm not sure" instead of making things up;
- always tell the user to call 112 and follow civil-protection instructions in a medical emergency or immediate danger.

What the models know comes from their general training. They have **no extra emergency, first-aid or rescue training**, they don't know recent events, and they can't search the internet. That is why ResQ includes **verified references** next to the AI:

- **Offline library (Kiwix):** the full Italian Wikipedia (text only), Italian Wikipedia medicine, and the English WikiMed medical encyclopedia.
- **Official guides:** Protezione Civile "Io non rischio" leaflets (earthquake, flood, tsunami, volcano) and a multi-hazard booklet.
- **Family emergency sheet:** emergency numbers, contacts, meeting points, health info, and a 72-hour kit checklist (`stick/guide/SCHEDA-EMERGENZA.txt`, in Italian).

Use the AI to explain, summarize, translate or help you find things. Check what matters against the library and the guides.

## Features

- **Browser chat** in Italian or English, with a model picker, image reading (`resq-vision`) and step-by-step reasoning (`resq-think`). The library links sit at the top of the page.
- **Terminal chat** as an alternative (`start-ai terminal`).
- **Fully local:** everything listens on `127.0.0.1` only, and Ollama cloud features are turned off.
- **No conflicts:** it uses ports 11435 (AI) and 8090 (chat + library), so it won't clash with an Ollama already installed on the computer.
- **Android:** ready-to-load GGUF model files plus the PocketPal (AI) and Kiwix (library) apps.

## Models

| ResQ model | Based on | Size | RAM | Good for |
|---|---|---|---|---|
| `resq:1.5b` | Qwen 2.5 1.5B | 1 GB | 4 GB+ | Old or slow computers, quick answers |
| `resq:3b` (default) | Qwen 2.5 3B | 1.9 GB | 6 GB+ | Everyday use |
| `resq-think:1.5b` | DeepSeek-R1 1.5B | 1.1 GB | 4 GB+ | Small step-by-step reasoning |
| `resq-think:7b` | DeepSeek-R1 7B | 4.7 GB | 8 GB+ | Math, logic, planning |
| `resq-vision:7b` | Qwen 2.5 VL 7B | 6 GB | 10 GB+ | Reading photos, screenshots, timetables, forms |

Plain-language descriptions: [`stick/MODELS.txt`](stick/MODELS.txt) / [`stick/MODELLI.txt`](stick/MODELLI.txt).

---

## Requirements

### To build a ResQ stick

| | |
|---|---|
| **USB stick** | **64 GB or more**, USB 3 recommended. The full build uses about **42 GB**; see the options below for smaller builds. |
| **Stick format** | **exFAT**. FAT32 can't hold files over 4 GB, NTFS isn't writable on macOS, and ext4 only works on Linux. |
| **Build computer** | Linux x86_64 or macOS |
| **Tools** | `bash`, `curl`, `tar`, `unzip`, `perl`; plus `zstd` on Linux |
| **Internal disk** | About 20 GB free for the temporary download cache, deleted at the end |
| **Internet** | About 40 GB of downloads. Allow 1–3 hours, depending on your connection. |

### To use a ResQ stick

| | |
|---|---|
| **Windows** | Windows 10 (22H2) or 11, 64-bit (x86_64) |
| **macOS** | macOS 14 Sonoma or later, Intel or Apple Silicon |
| **Linux** | x86_64 with a desktop browser |
| **RAM** | 6 GB+ for the default model (4 GB for the smallest) |
| **Browser** | Any modern browser (Chrome, Edge, Firefox, Safari) |
| **Android (optional)** | Android 10+, 6 GB+ RAM recommended, a USB-C OTG adapter or a computer to copy files |

No internet is needed to use it. A GPU is optional: NVIDIA (Windows/Linux) and Apple Silicon are used automatically, and otherwise it runs on the CPU.

---

## Installation: build your own ResQ stick

1. **Format the stick as exFAT.** This erases it. Name it `RESQ`.
   - **Windows:** File Explorer > right-click the stick > Format > File system **exFAT**, Volume label `RESQ`.
   - **macOS:** Disk Utility > select the stick > Erase > Format **ExFAT**, Scheme **GUID Partition Map**, Name `RESQ`.
   - **Linux:** GNOME Disks > Format Partition > **Other > exFAT**, or `sudo mkfs.exfat -L RESQ /dev/sdX1`. Double-check the device name first.

2. **Get the code:**
   ```bash
   git clone https://github.com/badoverse/ResQ.git
   cd ResQ
   ```

3. **Install the tools** if they're missing:
   ```bash
   # Debian/Ubuntu
   sudo apt install curl unzip zstd perl
   # Fedora
   sudo dnf install curl unzip zstd perl
   # macOS: curl, tar, unzip and perl are built in. zstd is optional: brew install zstd
   ```

4. **Run the builder** with the path of the mounted stick:
   ```bash
   # Linux
   ./build-stick.sh /run/media/$USER/RESQ      # or /media/$USER/RESQ on Ubuntu
   # macOS
   ./build-stick.sh /Volumes/RESQ
   ```
   It downloads everything from the official sources, verifies the checksums where they're published, creates the ResQ models, and copies it all to the stick. It's safe to re-run if interrupted: finished downloads are reused.

   Smaller builds:

   | Option | Saves | Leaves out |
   |---|---|---|
   | `--skip-wikipedia` | 10.7 GB | the full Italian Wikipedia (the medical encyclopedias stay) |
   | `--skip-big-models` | 10.7 GB | `resq-think:7b` and `resq-vision:7b` |
   | `--skip-android` | ~4.4 GB | the `android/` folder |
   | `--skip-guides` | ~30 MB | the Protezione Civile PDFs |

   With all three size options the build is about 16 GB, so it fits on a **32 GB** stick.

5. **Eject the stick safely.** Done.

**Copying a finished stick:** copy everything on it to the top level of another exFAT stick of 64 GB or more. The copy works the same way: the launchers find their files wherever the stick is mounted.

---

## Usage

| System | Start |
|---|---|
| **Windows** | Double-click `start-ai.bat`. If you see "Windows protected your PC": **More info > Run anyway**. If the firewall asks: **Allow** (it only talks to this computer). |
| **macOS** | The first time, right-click `start-ai.command` > **Open**. If it's still blocked: **System Settings > Privacy & Security > Open Anyway**. Later, just double-click it. |
| **Linux** | `bash /path/to/RESQ/start-ai.sh` |

Your browser opens `http://127.0.0.1:8090/`. Pick a model, type, and press Enter. To stop, go back to the black or Terminal window and press Enter.

Other commands (Windows: `start-ai.bat …`, Mac: `bash start-ai.command …`):

```bash
start-ai.sh terminal            # chat in the terminal instead of the browser
start-ai.sh run resq:3b         # terminal chat with one model
start-ai.sh list                # list models on the stick
start-ai.sh pull qwen2.5:7b     # add another Ollama model (needs internet)
```

**Android:** follow [`stick/android/LEGGIMI-ANDROID.txt`](stick/android/LEGGIMI-ANDROID.txt), which has steps in Italian and English. Do it **before** you need it, and test it once in airplane mode.

---

## Repository layout

```
build-stick.sh            builds a ResQ stick from official sources
modelfiles/
  system-prompt.txt       ResQ's identity and instructions
  models.txt              ResQ model names and the open models they use
stick/                    copied as-is to the stick
  start-ai.sh / .command / .bat   launchers for Linux / macOS / Windows
  chat.html               the browser chat (served by kiwix-serve on 127.0.0.1:8090)
  README.txt, LEGGIMI.txt, MODELS.txt, MODELLI.txt
  guide/SCHEDA-EMERGENZA.txt      family emergency sheet (Italian)
  android/LEGGIMI-ANDROID.txt     Android setup
```

The models, Wikipedia files, apps and PDFs are **not stored in this repository**. They're large and have their own licenses, so the builder downloads them from their official sources.

## How it works

- **AI:** [Ollama](https://ollama.com) portable builds run from the stick, with `OLLAMA_MODELS` pointing to the stick's `models/` folder and `OLLAMA_NO_CLOUD=1` set.
- **Chat page and library:** [kiwix-serve](https://github.com/kiwix/kiwix-tools) serves the ZIM libraries and uses `chat.html` as its welcome page (`--customIndex`). Because the page comes from `http://127.0.0.1:8090`, Ollama's default security settings accept it. Opening the page as a file would have required allowing *every* website to control the local AI.
- **exFAT:** it has no symlinks, so libraries are copied with the links resolved. Models are downloaded to the internal disk first, because Ollama's preallocation is extremely slow on exFAT.

## Known limitations

- The Windows and macOS launchers were written carefully but have had little real-world testing. Please open an issue if something fails.
- Small models make mistakes, and they mostly reason well in English.
- Wikipedia snapshots are from late 2026. Rebuild the stick to refresh them.
- The Protezione Civile PDF links may move. The builder warns you and continues.

## License

The ResQ code and docs in this repository are released under the [MIT License](LICENSE). The components ResQ downloads keep their own licenses; see [THIRD_PARTY.md](THIRD_PARTY.md). In particular, **Qwen 2.5 3B (`resq:3b`) is under the Qwen Research License, which doesn't allow commercial use.**

ResQ is an independent project. It is not affiliated with or endorsed by Protezione Civile, Kiwix, Wikipedia, Ollama, Alibaba (Qwen) or DeepSeek.
