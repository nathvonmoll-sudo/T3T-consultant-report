# Consultation Report Skill — Machine Setup

This covers everything needed on a **new computer** (Claude Desktop) to make the `/consultation-report` skill work end-to-end. It does **not** cover installing the skill folder itself — that's just dropping the skill into your Claude Desktop skills location.

This setup matches the **current, simplified pipeline**: `ms365` + `filesystem` MCP servers, plus Claude's built-in code execution sandbox for video frame extraction. The old `t3t-video` stdio MCP server from the original repo is **deprecated — do not install it.**

---

## 1. Prerequisites to install

| Requirement | Why | Check |
|---|---|---|
| **Node.js** (LTS, v18+) | Both MCP servers run via `npx` | `node -v` in a terminal |
| **Claude Desktop** | Runs the MCP servers + the skill | — |
| **Python 3** is *not* required locally | Rendering (`build_report.py`) and frame extraction both run inside Claude's **code execution sandbox**, not on your machine | — |

You do **not** need to install Python, ffmpeg, or any pip packages locally — none of the report generation runs on your laptop's own Python. Everything happens inside Claude's sandboxed code execution environment, which is provisioned per-session by Anthropic.

---

## 2. MCP servers — `claude_desktop_config.json`

**File location:**
- Windows: `%APPDATA%\Claude\claude_desktop_config.json`
- Mac: `~/Library/Application Support/Claude/claude_desktop_config.json`

Open it (create it if it doesn't exist) and make sure it contains **both** of these servers. If other servers (Gmail, Google Calendar, WhatsApp, etc.) are already in there, just add `ms365` and `filesystem` alongside them inside the same `mcpServers` object — don't replace the whole file if you already have other entries.

```json
{
  "mcpServers": {
    "ms365": {
      "command": "npx",
      "args": ["-y", "@softeria/ms-365-mcp-server", "--org-mode"]
    },
    "filesystem": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-filesystem",
        "C:\\Users\\<username>\\Desktop",
        "C:\\Users\\<username>\\Downloads",
        "C:\\Users\\<username>\\Documents",
        "C:\\Users\\<username>\\Pictures\\Screenshots"
      ]
    }
  }
}
```

Replace `<username>` with the actual Windows username on that machine.

**Do NOT add** a `t3t-video` entry — the video MCP server is retired. If you're migrating a config from the old repo, delete that block entirely.

### Notes on the `filesystem` server
- Every folder the skill needs to read (screenshots, downloads, etc.) must be **explicitly listed** as an argument — the server can only see folders you name here.
- The consult screenshots live at `Pictures\Screenshots` by default (Windows Snipping Tool / Win+Shift+S default save location) — if a consultant saves screenshots somewhere else, add that path too.
- After editing this file, **fully quit and restart Claude Desktop** (not just close the window) for the new server list to load.

### Notes on the `ms365` server
- `--org-mode` is required — it's what points the server at the T3T tenant rather than a personal Microsoft account.
- On first use, it will trigger a Microsoft login flow (device code or browser popup) — sign in with the T3T work account.
- Two Graph permissions matter for transcripts:
  - `OnlineMeetingTranscript.Read.All` — needed for scheduled Teams meetings. Usually already available.
  - `CallTranscripts.Read.All` (delegated) — needed for ad-hoc/1:1 calls with no calendar invite. This one requires **Global Admin consent**. On the T3T tenant that's **Stephan** — if a new consultant hits a permissions error on ad-hoc call transcripts, that's the one to ask him to approve.
- You can install it on the terminal before first use to get it cached npx `-y @softeria/ms-365-mcp-server --help`
---

## 3. Claude account settings (per consultant, one-time)

In Claude Desktop: **Settings → Capabilities**

1. Turn on **Code execution and file creation** — this is what runs `build_report.py` and does the video frame extraction. Without it, the skill cannot render the `.docx` at all.
2. In the same panel, find **Allow network egress** and add these two domains to the allowlist:
   - `times3technologies-my.sharepoint.com`
   - `*.sharepoint.com`

   This is only used for one thing: downloading the Teams recording directly from OneDrive inside the sandbox (Step 4b of the skill). The `ms365` MCP calls themselves are unaffected by this setting either way.
3. **Start a brand-new conversation** after changing this setting. A conversation already in progress won't pick up an allowlist change made mid-session.

---

## 4. Filesystem folders — what to actually grant

At minimum, the `filesystem` server args (see config above) should include:

- `Desktop`, `Downloads`, `Documents` — general working folders
- `Pictures\Screenshots` — where consultant screenshots land during/after a call

If the skill ever reports it can't see the screenshots folder, it means that path isn't in the `args` list above — add it and restart Claude Desktop.

---

## 5. What the skill installs on its own (no setup needed)

These happen automatically, inside the code execution sandbox, every session — nothing to configure ahead of time:

- `pip install imageio-ffmpeg` — gives a working static ffmpeg binary for frame extraction (Step 4b of the skill)
- `python-docx` / `Pillow` — used by `build_report.py` and the redaction/crop step; these are standard in the sandbox environment already

There is no persistent local server for video — the sandbox is created fresh each conversation.

---

## 6. Quick verification checklist

Run through this once after setup, before relying on it for a real client report:

- [ ] `claude_desktop_config.json` has `ms365` and `filesystem`, no `t3t-video`
- [ ] Claude Desktop fully restarted after editing the config
- [ ] Signed in to `ms365` with the T3T work account (try `ms365: list-calendars` or similar to confirm)
- [ ] Code execution and file creation is **on**
- [ ] `*.sharepoint.com` and `times3technologies-my.sharepoint.com` are in the network egress allowlist
- [ ] Started a fresh conversation after the settings change above
- [ ] Screenshot folder path confirmed and listed in the `filesystem` args
- [ ] Skill folder (`consultation-report/`, with `SKILL.md`, `assets/`, `reference/`, `scripts/`) is in place in the Claude Desktop skills location

---

## 7. Common setup-stage errors

| Symptom | Likely cause |
|---|---|
| Skill can't find the screenshots folder | Path missing from `filesystem` server's `args`, or restart skipped |
| `get-download-url` file fails to download in sandbox | Egress allowlist domains not added, or added but conversation wasn't restarted |
| Ad-hoc call transcript access denied | `CallTranscripts.Read.All` not yet approved by Stephan (Global Admin) |
| `ms365` tools not appearing at all | Config JSON malformed (check commas/brackets), or Claude Desktop wasn't restarted |
| ffmpeg download step fails in sandbox | Code execution not enabled in Settings → Capabilities |
