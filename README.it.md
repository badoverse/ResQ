# ResQ

**Un kit di emergenza offline su chiavetta USB: assistente AI + Wikipedia e biblioteca medica offline + guide ufficiali di emergenza.**

ResQ funziona interamente da una chiavetta USB su Windows, macOS e Linux. Non servono internet, account, chiavi API o installazioni. La cartella Android permette di preparare la stessa AI e la stessa biblioteca anche sul telefono, che in un blackout dura molto più di un computer.

ResQ è pensato per la **preparazione alle 72 ore**: tutto quello che serve a una famiglia per informarsi, orientarsi e farsi aiutare per tre giorni senza internet e senza aiuti esterni. I contenuti predefiniti sono in italiano e in inglese.

> **In emergenza chiama il 112.** L'AI di ResQ può sbagliare. Per salute e sicurezza fidati prima delle guide ufficiali e della biblioteca offline.

*English: [README.md](README.md)*

---

## Cos'è ResQ (e cosa non è)

ResQ **non è un modello addestrato apposta.** Usa modelli aperti di uso generale (Qwen 2.5, DeepSeek-R1, Qwen 2.5 VL) con istruzioni fisse ([`modelfiles/system-prompt.txt`](modelfiles/system-prompt.txt)):

- presentarsi come ResQ;
- rispondere nella lingua dell'utente, in modo breve e pratico;
- dire "non sono sicuro" invece di inventare;
- per emergenze mediche o pericoli immediati, dire sempre di chiamare il 112 e seguire la Protezione Civile.

Quello che i modelli sanno viene dal loro addestramento generale. **Non hanno un addestramento specifico su emergenze, primo soccorso o soccorso.** Non conoscono le notizie recenti e non possono cercare su internet. Per questo ResQ affianca all'AI delle **fonti verificate**:

- **Biblioteca offline (Kiwix):** Wikipedia in italiano completa (solo testo), medicina di Wikipedia in italiano, enciclopedia medica WikiMed in inglese.
- **Guide ufficiali:** pieghevoli "Io non rischio" della Protezione Civile (terremoto, alluvione, maremoto, vulcano) e il libretto multirischio.
- **Scheda di emergenza della famiglia:** numeri di emergenza, contatti, punti di ritrovo, salute e checklist del kit per 72 ore (`stick/guide/SCHEDA-EMERGENZA.txt`).

Usa l'AI per farti spiegare, riassumere, tradurre o trovare informazioni. Le cose importanti controllale nella biblioteca e nelle guide.

## Modelli

| Modello ResQ | Basato su | Dimensione | RAM | Va bene per |
|---|---|---|---|---|
| `resq:1.5b` | Qwen 2.5 1.5B | 1 GB | 4 GB+ | Computer vecchi o lenti, risposte rapide |
| `resq:3b` (predefinito) | Qwen 2.5 3B | 1.9 GB | 6 GB+ | Uso di tutti i giorni |
| `resq-think:1.5b` | DeepSeek-R1 1.5B | 1.1 GB | 4 GB+ | Piccoli ragionamenti passo passo |
| `resq-think:7b` | DeepSeek-R1 7B | 4.7 GB | 8 GB+ | Calcoli, logica, pianificazione |
| `resq-vision:7b` | Qwen 2.5 VL 7B | 6 GB | 10 GB+ | Leggere foto, screenshot, orari, moduli |

## Requisiti

**Per creare la chiavetta:**
- chiavetta da **64 GB o più** (meglio USB 3), formattata **exFAT**: la versione completa occupa circa 42 GB;
- un computer Linux x86_64 o macOS, con `bash`, `curl`, `tar`, `unzip` e `perl` (su Linux anche `zstd`);
- circa 20 GB liberi sul disco interno, per i download temporanei;
- internet: circa 40 GB da scaricare, da 1 a 3 ore.

**Per usare la chiavetta:**
- Windows 10 (22H2) o 11 a 64 bit, macOS 14 o successivi (Intel o Apple Silicon), oppure Linux x86_64;
- almeno 6 GB di RAM per il modello predefinito (4 GB per il più piccolo) e un browser qualsiasi;
- Android (facoltativo): Android 10 o successivo, meglio con 6 GB di RAM.

Per usarla non serve internet.

## Installazione

1. **Formatta la chiavetta in exFAT** (cancella tutto) e chiamala `RESQ`.
   - Windows: Esplora file > tasto destro sulla chiavetta > Formatta > **exFAT**.
   - Mac: Utility Disco > Inizializza > **ExFAT**, schema **Mappa partizione GUID**.
   - Linux: Dischi > Formatta partizione > **exFAT**.
2. Scarica il progetto:
   ```bash
   git clone https://github.com/badoverse/ResQ.git && cd ResQ
   ```
3. Avvia il costruttore indicando dove è montata la chiavetta:
   ```bash
   ./build-stick.sh /run/media/$USER/RESQ     # Linux (Ubuntu: /media/$USER/RESQ)
   ./build-stick.sh /Volumes/RESQ             # Mac
   ```
   Scarica tutto dalle fonti ufficiali e controlla i checksum. Se si interrompe, puoi rilanciarlo.
   Versioni più leggere: `--skip-wikipedia` (−10.7 GB), `--skip-big-models` (−10.7 GB) e `--skip-android` (−4.4 GB). Con tutte e tre occupa circa 16 GB, quindi basta una chiavetta da 32 GB.
4. Espelli la chiavetta in modo sicuro.

**Copiare una chiavetta pronta:** copia tutto il contenuto nella cartella principale di un'altra chiavetta exFAT da almeno 64 GB. Funziona allo stesso modo.

## Uso

- **Windows:** doppio clic su `start-ai.bat`. Se compare "PC protetto da Windows": **Ulteriori informazioni > Esegui comunque**.
- **Mac:** la prima volta tasto destro su `start-ai.command` > **Apri**. Se è ancora bloccato: Impostazioni di Sistema > Privacy e sicurezza > **Apri comunque**.
- **Linux:** `bash /percorso/di/RESQ/start-ai.sh`

Si apre il browser su `http://127.0.0.1:8090/`. Scegli il modello, scrivi e premi Invio. Per chiudere, torna alla finestra nera o del Terminale e premi Invio.

**Android:** segui [`stick/android/LEGGIMI-ANDROID.txt`](stick/android/LEGGIMI-ANDROID.txt). Fallo **prima** che serva, e provalo una volta in modalità aereo.

## Licenza

Il codice e i documenti di ResQ sono rilasciati con licenza [MIT](LICENSE). I componenti scaricati mantengono le loro licenze: vedi [THIRD_PARTY.md](THIRD_PARTY.md). In particolare **Qwen 2.5 3B (`resq:3b`) usa la Qwen Research License, che non consente l'uso commerciale.**

ResQ è un progetto indipendente: non è affiliato né approvato da Protezione Civile, Kiwix, Wikipedia, Ollama, Alibaba (Qwen) o DeepSeek.
