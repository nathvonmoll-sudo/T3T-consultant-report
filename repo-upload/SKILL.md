---
name: consultation-report
description: Generate a T3T consulting report from a regular client consultation or meeting. Use whenever the user wants to "write up", "do the report for", "generate the consulting report", or "document" a consult/meeting/call - especially HR & Payroll or ERP consults that need the standard T3T Consultation Report (Scope / Actions Performed / To Do, on the Sage template). Works from a Teams recording + transcript on OneDrive via the ms365 MCP, plus screenshots from the consultant's local machine and client emails as auditable source references. Produces the filled .docx in T3T's real template. NOT for Sage/internal calls (not billable, no report) and NOT for the ticket-suggestion project.
---

# T3T Consultation Report

Turn one consult into the standard T3T Consultation Report `.docx`. The report is an evidence + billing record the client signs off, then it goes onto the Freshdesk ticket and Shahida checks dates + hours before it's sent.

**Division of labour:** you do the judgement (read the transcript, decide what goes in each section, in house style); the bundled script does the deterministic rendering into the exact template. Don't hand-build the .docx — always render via the script.

---

## MCP Servers Required

- **ms365** (`@softeria/ms-365-mcp-server --org-mode`) — OneDrive, Teams transcripts, email
- **filesystem** (`@modelcontextprotocol/server-filesystem`) — local screenshots folder

Video frame extraction runs in Claude's built-in **code execution** sandbox, not an MCP server (mechanics in Step 4b–4c, where the recording is downloaded and frames are pulled).

---

## One-Time Setup — Code Execution for Frame Extraction

Frames are extracted in Claude's code execution sandbox, which is created fresh per session — there's no persistent local server to configure, start, or keep alive. Two account settings need to be enabled once per consultant:

- Settings → Capabilities → **Code execution and file creation**: on
- Same panel → **Allow network egress** → add `times3technologies-my.sharepoint.com` and `*.sharepoint.com` to the domain allowlist. This is only needed for the direct file download in Step 4c; `ms365` MCP calls are **not** governed by this setting and work regardless.
- If those domains were just added, start a **new** conversation before relying on them — a settings change may not apply to a chat already in progress.

---

## Step 1: Find the Recording

Search OneDrive for the recording by client name or date:
```
ms365: search-onedrive-files  q="[client name]"  →  .mp4 in Recordings folder
ms365: get-drive-item         →  get lastModifiedDateTime, name, size
ms365: get-download-url       →  pre-authenticated URL for frame extraction
```
Duration and resolution come from ffmpeg's own stderr output when the file is opened for extraction (see Step 4c) — no separate lookup call needed.

---

## Step 2: Derive the Meeting Timeframe

The recording filename encodes the meeting start time in local time (SAST = UTC+2):

```
Call with Corné Pistorius-20260620_091523-Meeting Recording.mp4
                            ^^^^^^^^ ^^^^^^
                            YYYYMMDD HHMMSS  →  09:15:23 SAST on 20 June
```

Calculate:
```
meeting_date  = YYYYMMDD from filename
meeting_start = HHMMSS from filename  (SAST)
meeting_end   = meeting_start + duration_seconds
meeting_start_utc = meeting_start - 2h
meeting_end_utc   = meeting_end   - 2h
```

This window drives screenshot filtering and email search. It is more reliable than estimating from `lastModifiedDateTime`.

---

## Step 3: Get the Transcript

Transcripts are NOT stored as separate files in OneDrive. The text is embedded in the `.mp4` container and only accessible via the Teams Graph API. There are two paths depending on call type.

### Path A — Scheduled meeting (calendar invite)
Requires: `OnlineMeetingTranscript.Read.All` ✅

```
1. Find the meeting:
   Microsoft 365: outlook_calendar_search  query="[client name]"
   Microsoft 365: read_resource (calendar URI)  →  get onlineMeeting.joinWebUrl

2. Get the meeting ID:
   ms365: list-online-meetings  filter=joinWebUrl eq '{url}'  →  meetingId

3. List transcripts for that meeting:
   GET /users/{userId}/onlineMeetings/{meetingId}/transcripts
   ms365: list-meeting-transcripts  meetingId={id}  →  transcriptId

4. Fetch the VTT content:
   GET /users/{userId}/onlineMeetings/{meetingId}/transcripts/{transcriptId}/content
   ms365: get-meeting-transcript-content  →  VTT text
```

### Path B — Ad-hoc / 1:1 / spontaneous call
Requires: `CallTranscripts.Read.All` (delegated)

These calls have no onlineMeetingId. Use the dedicated `adhocCall` endpoint instead:

```
1. Get all ad-hoc transcripts in the meeting date range:
   GET /users/{userId}/adhocCall/getAllTranscripts(
     filter='startDateTime ge {meeting_date}T00:00:00Z 
             and endDateTime le {meeting_date}T23:59:59Z'
   )
   →  returns list of transcript metadata objects with id and createdDateTime

2. Identify the right transcript by createdDateTime matching the meeting window

3. Fetch the VTT content:
   GET /users/{userId}/adhocCall/transcripts/{transcriptId}/content
   →  returns clean VTT stream
```

Use `ms365: graph-batch` or `ms365: read_resource` to call these URIs directly if Softeria doesn't have a dedicated adhocCall tool.

### If no transcript exists
Transcription must have been actively started during the call (either manually or via policy). If the consultant didn't enable it, no transcript was generated regardless of which API path you use. In this case, ask the consultant to paste key points manually.

**Transcript quality note:** Auto-generated speech-to-text — Afrikaans, names, and payroll jargon (EMP501, IRP5, 3601/3607) will be mangled. Work from the gist; flag uncertain names rather than guessing.

**If the transcript-content call hangs:** `get-meeting-transcript-content` streams the VTT body from a Graph redirect and can time out / hang while the metadata calls (`list-meeting-transcripts`, etc.) all succeed — this is a transport hang on the local MCP bridge, **not** a permissions problem (if you got the transcript ID, you have access). Ask the consultant to restart the local MCP servers, then retry — the `meetingId` and `transcriptId` you already resolved stay valid, so you resume at the content fetch without redoing the lookups. (This is specific to the `ms365` transcript-streaming call; video frame extraction no longer goes through a local MCP server — it runs in the code execution sandbox, per Step 4 — so it isn't exposed to this class of hang.)


---

## Step 4: Gather Action Evidence — Screenshots First, Frames to Fill Gaps

Evidence images go inline in **Actions Performed**. They are gathered in a strict order: **consultant screenshots are primary**, video frames only fill the gaps screenshots leave. Whatever the source, **every image is viewed and selected before it goes in — never include an image blind by timestamp.**

### 4a. Consultant screenshots — the primary source (do this first)
The consultant deliberately captured these at moments they judged worth capturing, so they are high-signal by construction. Start here.
```
filesystem: list_directory  path="C:\Users\<username>\Pictures\Screenshots"
```
Filter to files whose `lastModified` falls within `[meeting_start_utc, meeting_end_utc]`. Then, for each candidate:
1. **View it** (read the actual image — do not rely on the filename or timestamp alone).
2. **Match it to a transcript point** by its capture time — a screenshot at 09:32 matches what was being done around 09:32.
3. **Keep only the relevant ones.** A screenshot that shows a real system-state artefact tied to an action stays; an accidental capture, a duplicate, or one that doesn't map to anything in the report is dropped.
4. **Redact + crop** the keepers (see 4e) and place each inline against its action.

After this pass you have a set of placed screenshots and — importantly — a clear list of **which transcript points are now covered**.

> If the screenshots folder isn't accessible, add it to the filesystem connector's `claude_desktop_config.json`:
> ```json
> "C:\\Users\\<username>\\Pictures\\Screenshots"
> ```

### 4b. Download the recording once (before pulling any frames)
Frames are extracted from a **local copy** of the recording, not by streaming the OneDrive URL — ffmpeg's HTTPS input crashes (deterministic segfault) in the code execution sandbox on any `https://` input, so the URL must be downloaded to disk first. Do this once per session; every frame in 4c and 4d then seeks against the same local file.

```python
import requests
# download_url comes from ms365: get-download-url (Step 1) — unaffected by the egress allowlist
r = requests.get(download_url, stream=True)
with open("/tmp/recording.mp4", "wb") as f:
    for chunk in r.iter_content(chunk_size=8192):
        f.write(chunk)
# Confirm the saved byte count matches what get-download-url reported before trusting the file —
# a mismatch usually means an auth/redirect HTML page was saved instead of real video.
```

```bash
pip install imageio-ffmpeg   # ships a working static ffmpeg binary inside the wheel — no
                             # secondary download (unlike e.g. static-ffmpeg, which fetches
                             # the binary from a second host that may 403 on the allowlist).
python3 -c "import imageio_ffmpeg; print(imageio_ffmpeg.get_ffmpeg_exe())"   # -> <ffmpeg_path>
```

**Duration/resolution** print to ffmpeg's stderr the moment the file is opened (e.g. `Duration: 00:16:14.56 ... 1920x1080 ... 16 fps`) — read that rather than a separate probe. A standalone `ffprobe` is not confirmed bundled with `imageio-ffmpeg`; don't assume it's available.

**90-second-per-cell limit:** each code execution call has a hard 90s wall-clock cap. At measured rates (~35MB/s download, ~7.25MB per minute of footage at typical consult bitrate) a single call comfortably covers several hours of recording, so this rarely bites. For an unusually long or high-bitrate recording, split the download and the extractions across separate calls — sandbox files persist between calls in the same conversation, so the local copy stays available.

**Cleanup:** delete `/tmp/recording.mp4` once the needed frames are out — don't leave a full client recording sitting in the sandbox. (Sandbox contents are ephemeral across conversations anyway, but clean up explicitly.)

### 4c. Video frames — fill the gaps only (do this after screenshots)
Look at the actions that have **no screenshot** but where an image would strengthen the report. Only these gaps are candidates for a frame — never pull a frame for a point a screenshot already covers. Extract with a local `-ss` seek against the downloaded file:
```
<ffmpeg_path> -ss <seconds> -i /tmp/recording.mp4 -frames:v 1 -update 1 -q:v 2 -vf scale=1280:-1 -y frame_<seconds>.jpg
```
`-update 1` is required — without it, current ffmpeg builds refuse to write a single fixed-name jpg. Convert transcript time to seconds: `(action_time - meeting_start).total_seconds()`. Pull the candidates, then **view each one and select only the useful ones.**

**The bar: does this frame add significant information?** A frame earns its place if it conveys something substantive that the text alone doesn't — a system-state artefact (a config screen changed, a permission granted, a payslip/report generated, a field captured, an error hit) **or** a meaningful moment of a point that was covered, where seeing it genuinely adds to a reader's understanding. What it must **not** be is decoration or filler: an idle desktop, a transition/loading frame, a webcam or self-view with nothing else on screen, or a frame that merely restates a bullet while adding nothing. If a frame carries real information about the work or the discussion, it can go in; if it's just there to "have an image," leave it out and let the text carry it. In many consults the right number of gap-filling frames is still small — quality over quantity.

> **Read the frame before you disqualify it — don't misread an artefact as chatter.** The judgement above is easy to over-apply in the strict direction. A real Azure/Sage/config screen that is *foreground* can be waved away as "just a doc being walked through" on a careless glance, especially when a webcam tile or browser chrome is also in shot. Before you drop a frame, confirm what is *actually* on screen: if the image is text-dense or you're not certain, OCR it (`tesseract frame.jpg - --psm 6`) and read the result rather than trusting a glance. Judge on **what the OCR/read confirms**, not on a first impression. A confident "that's just the markdown" that turns out to be the live permissions grid is the exact failure this guards against.

> **Batch generously — local seeks are cheap.** Each `ffmpeg -ss` call is a fast local seek against the already-downloaded file (~0.2s each), so there's no per-frame cost worth rationing. The only ceiling is the 90-second-per-cell wall clock if you chain a very large number of extractions in one call — pull as many candidates per pass as you need, just don't chain so many in a single cell that it risks the timeout.

**When a verbal cue points at a specific system state, sample the cue window — don't settle for one or two far-apart frames.** A line like "as you can see, X is not granted" / "here it shows the error" names an on-screen artefact. Two frames 10s apart can both land on a transition and miss it. Instead sample the cue window at ~2–3s spacing, and check the whole frame — the artefact may be foreground while a webcam or IDE sits beside it, or it may surface only when a background tab is brought forward. Only conclude "no qualifying frame here" after the window is actually covered, not after 1–2 samples.

Redact + crop the keepers (4e) and place them inline.

### 4d. Context-only frames — to understand a source or an ambiguous moment (never embedded)
Separately from evidence, frames can be pulled purely to *read what was on screen* and then **discarded** — they are never embedded. This is transcript-driven, not time-sampled:
- **Scan the transcript for verbal cues** that a document, sheet, or page is being opened or referred to — "let me open the take-on sheet", "if you look at this tab", "I'll pull up the YTD file", "open the employee screen".
- **Pull a frame at that moment** (same local `ffmpeg -ss` seek as 4c) and view it to identify the artefact: the spreadsheet filename, which Sage module, what the dialog actually said, what "this" referred to.
- **Use it to write more accurate text** — especially to identify a **Sources Used** entry (which sheet/document the work rested on) — then throw it away.

Keep this targeted: pull a context frame *only* where the transcript points at a specific document or an ambiguous reference, not as a blanket sweep of the recording. Each pull should trace to a specific cue in the transcript.

### 4e. Redaction + crop — mandatory on every embedded image, then review
A consult report is a client-facing, signed, audit-trail document, so no raw image is embedded as-is. For each screenshot or frame you intend to keep:
1. **Crop to what matters.** Trim black letterbox bars; zoom to the region that carries the information (the dialog, the table, the permission row, the screen being discussed).
2. **Strip everything personal or out-of-scope.** Remove or cover: browser tab/bookmark bars, open-tab titles, the Windows taskbar, notification toasts, other open windows, the self-cam thumbnail, and any visible email address, filename, or bookmark that isn't part of what the image is showing. The consultant's browsing context, unrelated client names, and personal files must not appear.
3. **Present the cropped keepers to the consultant for review *before* rendering** — show each proposed image with its caption and confirm it's clean and worth including. Do not bake images into the .docx unsubmitted.

```python
from PIL import Image, ImageDraw
img = Image.open("frame_245.jpg")
img = img.crop((left, top, right, bottom))      # zoom to what matters, drop chrome/bars
ImageDraw.Draw(img).rectangle([x0, y0, x1, y1], fill="white")  # cover any residual personal info
img.convert("RGB").save("frame_245_clean.jpg", quality=92)
```
Measure boundaries on the actual image rather than guessing pixel offsets — chrome positions vary by frame. (The renderer normalises images through Pillow on the way in, so a cropped frame embeds without error — but the crop, redaction, and review are judgement steps.)

---
## Step 5: Find Client Emails → Sources Used

Emails from the client are the primary source references — more auditable than screenshots, and permanent. They become the **Sources Used** section.

This step runs *after* evidence-gathering (Step 4) on purpose: by now you've often already seen which documents were on screen (via context frames, Step 4d), so matching an email/attachment to a source is confirmation rather than blind inference.

### 5a. Search for emails around the meeting
```
Microsoft 365: outlook_email_search
  sender="[client email or domain]"
  afterDateTime="[meeting_date - 7 days]"
  beforeDateTime="[meeting_date + 1 day]"
  limit=10
```

Also search Sent Items to catch emails the consultant sent to the client:
```
Microsoft 365: outlook_email_search
  recipient="[client email]"
  afterDateTime="[meeting_date - 7 days]"
  beforeDateTime="[meeting_date + 1 day]"
  folderName="Sent Items"
  limit=10
```

### 5b. Pull attachment names
For each promising email, check what files were attached:
```
ms365: list-mail-attachments  messageId=[email id]  →  filename, size, contentType
```

### 5c. Match emails to what was used in the transcript
Scan the transcript for document references — explicit names, data values, column names, or phrases like "the file you sent", "your employee list", "that payslip". Match by:

| Signal | Confidence |
|--------|-----------|
| Transcript names the file exactly ("the April EMP501 you sent") | High |
| Transcript mentions a data value that appears in the email body ("R12,500") | High |
| Only one attachment of that type from that client that week | Medium |
| General reference ("the document") + multiple candidates | Low → flag for consultant |

For ambiguous matches, present the 2–3 candidates and ask the consultant to confirm rather than guess.

> **Disambiguating with a context frame.** If the transcript references a document but you can't tell which email/attachment it is, scan the transcript for the moment it was opened on screen ("let me open the take-on sheet", "if you look at this file") and pull a **context-only frame** there (see Step 4d) to read the actual filename or contents. Use it to identify the source, then discard the frame — it is never embedded.

### 5d. Format the Sources Used entry
Each source entry should be self-contained and auditable:
```
"worksheet.xlsx — email from corné@client.co.za, 19 Jun 13:04"
"April payslips (EMP.pdf) — email from hr@client.co.za, 18 Jun 09:32"
"Employee list (staff_june.xlsx) — email from corné@client.co.za, 15 Jun 16:45"
```

No screenshot needed — the email is the source record and cannot be deleted.

---

## Step 6: Write the Report

1. **Confirm it's billable.** No report for Sage/internal calls.
2. **Read the whole transcript first.** Identify: task type, actions taken, forward commitments, decisions. Ignore chatter.
3. **Follow house style** (`reference/house-style.md`): clear self-contained lines, what-not-how, nest related items, owner-tag To-Dos.
4. **Write `report.json`:** (field names must match exactly — the renderer reads these keys)
```json
{
  "meta": {
    "company_name": "",
    "contact_person": "",
    "case_nr": "",
    "consultant": "",
    "date": "YYYY.MM.DD"
  },
  "scope": "One-line task description.",
  "actions": [
    {
      "text": "Action description",
      "sub": ["nested detail", "another nested detail"],
      "image": "shots/frame_245_clean.jpg",
      "caption": "What the image shows"
    }
  ],
  "todo": [
    { "text": "Forward commitment — owner named in the text, e.g. 'Lerusha will send the sheet'." }
  ],
  "sources": [
    { "text": "worksheet.xlsx — email from corné@client.co.za, 19 Jun 13:04" }
  ],
  "instructions": [
    { "text": "Forward instruction or recommendation distinct from a To-Do." }
  ],
  "hours": { "hours": "1.0", "travel": "", "total": "1.0" }
}
```
- `image`/`caption` are optional per item and may be attached to any action, todo, source, or instruction line.
- Owner tagging for To-Dos goes **inside the `text`** ("Lerusha will…"), not a separate field.
- `sources` and `instructions` are optional — omit the key entirely if empty; their headings only render when present.
5. **Render:** `python scripts/build_report.py report.json -o "<Company>_<YYYY_MM_DD>.docx"`
   > **Guard against rendering a stale `report.json`.** `create_file` refuses to overwrite an existing path — if a `report.json` from a previous run is already there, a naive create silently fails and the build renders the **old** content while looking successful. Write this run's JSON to a **fresh per-run path** (e.g. a timestamped working dir), or overwrite explicitly (`cat > report.json <<'EOF'` / check the write succeeded). After rendering, **confirm the doc matches this call** — spot-check that the Scope/first action in the `.docx` are the ones you just wrote, not leftovers. Never present a render you haven't verified came from this run's JSON.
6. **Present the .docx** — draft for ~5-minute consultant review before going to the ticket. Hours is a hint from duration; consultant confirms.

---

## Sections (quick reference)

- **Scope:** Task type, one line. ("Needs analysis.", "Performance management setup.")
- **Actions Performed:** What was done; clear lines; action screenshots/frames inline. Evidence of config work.
- **To Do:** Forward commitments, owner-tagged. May be empty.
- **Sources Used:** Client emails/attachments that provided data for the work. Permanent audit trail. Omit if none.
- **Recommendations / Instructions:** Forward instructions or recommendations the client/consultant gave that aren't agreed To-Do commitments (e.g. "next time do X", "we recommend Y"). Optional — omit if none.

---

## Header Facts

| Field | Source |
|-------|--------|
| Company | Freshdesk ticket — ask if missing |
| Contact Person | Freshdesk ticket — ask if missing |
| Case Nr | Freshdesk ticket — ask if missing |
| Consultant | Context — ask if missing |
| Date | Parse YYYYMMDD from recording filename |
| Hours | `duration_seconds ÷ 3600` as starting point — consultant confirms |

---

## Notes

- **Workflow requirement:** Transcription must be actively started during the call for a transcript to exist. If the consultant didn't enable it, no transcript was generated and no API can retrieve it.
- This skill covers **regular consultation/meeting reports only.** Other report types (onboarding, etc.) are sibling skills sharing this template and renderer.
- **`mcp-server/server.py` in this repo is deprecated**, kept for reference only. It implemented the old `t3t-video` stdio MCP server, retired in favour of the code-execution approach above. Don't add it back to `claude_desktop_config.json` for new setups.
