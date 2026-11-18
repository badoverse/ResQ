ResQ - offline emergency stick: AI assistant + offline library + emergency guides
================================================================================
(Italiano: LEGGIMI.txt)

Everything on this stick works WITHOUT internet. Nothing is installed on the computer,
and nothing you type is sent anywhere. No account, no key, no cost.

IN AN EMERGENCY: CALL 112. The AI can be wrong. For health and safety,
trust the official guides in the "guide" folder and the offline library first.

WHAT IS ON THE STICK
  guide/       Official Protezione Civile leaflets (earthquake, flood, tsunami...)
               and SCHEDA-EMERGENZA.txt, a family emergency sheet to fill in and print
  library/     Offline Wikipedia (Italian, full text) + medical encyclopedias
               (Italian and English WikiMed). Opened through the chat page.
  models/      ResQ AI models (based on open models: Qwen 2.5, DeepSeek-R1, Qwen 2.5 VL)
  android/     Files and apps for Android phones (see android/LEGGIMI-ANDROID.txt)
  MODELS.txt   Which AI model to pick, in plain words

START (opens the chat and the library in your web browser)
  Windows : double-click start-ai.bat
            If Windows says "Windows protected your PC": More info > Run anyway.
            If the firewall asks: Allow. It only talks to this computer.
  Mac     : right-click start-ai.command > Open (the first time; later double-click).
            If it is still blocked: System Settings > Privacy & Security > Open Anyway.
  Linux   : bash /path/to/RESQ/start-ai.sh

  The browser opens http://127.0.0.1:8090/ - pick a model at the top, type, press Enter.
  Links to the offline library are at the top of the page.
  To stop: go back to the black/Terminal window and press Enter.
  Chats are saved automatically: reopen them from the History button. They are stored in the
  browser of that computer, not on the stick.

  Do not double-click chat.html directly: it only works when opened by start-ai.

OTHER COMMANDS (Windows: start-ai.bat ..., Mac: bash start-ai.command ...)
  start-ai.sh terminal              chat in the terminal instead of the browser
  start-ai.sh run resq:3b           terminal chat with a specific model
  start-ai.sh pull llama3.2:3b      download another model onto the stick (needs internet)
  start-ai.sh list                  show models on the stick
  start-ai.sh rm MODEL              delete a model from the stick

MODELS ON THE STICK  (plain-language guide: see MODELS.txt)
  resq:1.5b         986 MB  fastest, basic answers - NOT for emergencies
  resq:3b           1.9 GB  good everyday balance (default)
  resq:7b           4.7 GB  best answers, best for emergencies; needs ~8 GB RAM
  resq-think:1.5b   1.1 GB  small "thinking" model - NOT for emergencies
  resq-think:7b     4.7 GB  stronger reasoning, needs ~8 GB RAM
  resq-vision:7b    6.0 GB  reads images (use the Image button); needs ~10 GB RAM

NOTES
  - Everything listens on 127.0.0.1 only: other devices on the network cannot reach it.
    AI server port 11435 (won't clash with an installed Ollama), chat + library port 8090.
  - Cloud features are turned off (OLLAMA_NO_CLOUD=1): it is fully local.
  - Context is 8192 tokens. On low-RAM computers lower it: set OLLAMA_CONTEXT_LENGTH=4096 before starting.
  - Running from USB: the first answer takes longer (the model loads from the stick).
  - In an emergency use resq:7b (8 GB+ RAM) or resq:3b. On battery, resq:3b uses less power.
  - NVIDIA GPUs are used automatically on Windows/Linux; Apple Silicon GPUs on Mac.
  - Eject the stick safely before unplugging.

LAYOUT
  ollama/bin, ollama/lib   AI for Linux        kiwix/linux      library server for Linux
  ollama/windows           AI for Windows      kiwix/windows    library server for Windows
  ollama/mac               AI for macOS        kiwix/mac-*      library server for macOS
  chat.html                the chat page (served by the library server)

Versions: Ollama 0.32.5, kiwix-serve 3.8.1. Library: Wikipedia snapshots from Oct/Nov 2026.
