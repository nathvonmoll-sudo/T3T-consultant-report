# Consultation Report Agent — Machine Setup

This covers everything needed to make the `/consultation-report` agent work end-to-end for a T3T consultant on Claude Desktop, plus how to push the agent itself to the team.

Terminology note: in Claude's interface this is managed under **Skills**, so where you actually click it says "Skills". Everywhere else we call it the **agent**, which is how T3T refers to it.

This setup matches the current, simplified pipeline: the `ms365` MCP server (config file) plus the `filesystem` connector (added through the app), with Claude's built-in code execution sandbox handling video frame extraction. The old `t3t-video` stdio MCP server from the original repo is **deprecated, do not install it.**

---

## 1. Provisioning and updating the agent (Team accounts)

T3T is on Claude **Team**, so the agent is provisioned once by an owner and appears for everyone. Individual consultants do not upload it themselves.

### Zip the agent folder first

The agent is a folder (`consultation-report/`) containing `SKILL.md` plus `assets/`, `reference/`, and `scripts/` subfolders. It **must be uploaded as a `.zip` of the whole folder** so those subfolders survive. Uploading loose files, or zipping the files without the folder, breaks the structure and the agent will not run.

On Windows: right-click the `consultation-report` folder, choose **Send to > Compressed (zipped) folder**. That produces `consultation-report.zip` with the folder and all subfolders intact.

### Who adds it, and how

An **organization owner** adds it:

1. Owner clicks their profile icon (bottom-left) > **Settings**.
2. Go to **Organization settings > Skills**.
3. Confirm **Code execution and file creation** and **Skills** are both toggled on. (Skills need code execution to run.)
4. In the **Organization skills** section, click **+ Add**.
5. Select `consultation-report.zip` (it must contain `SKILL.md` at the top of the folder).
6. It is provisioned to everyone immediately and appears for each consultant under **Customize > Skills**.

Org-provisioned agents are on by default for all members. A member can toggle it off for themselves but cannot delete it.

### Replacing the agent with a new iteration

There is no in-place "update" step for a provisioned agent. To push a new version:

1. Zip the updated `consultation-report/` folder as above.
2. Owner goes to **Organization settings > Skills > Organization skills**.
3. Remove the existing `consultation-report` entry.
4. Click **+ Add** and upload the new `consultation-report.zip`.

The new version then appears for every consultant automatically. Consultants should start a fresh conversation to pick up the new version.

---

## 2. Prerequisites to install MCP servers

| Requirement | Why | Check |
|---|---|---|
| **Node.js** (LTS, v18+) | The `ms365` MCP server runs on Node | `node -v` in a terminal |
| **Claude Desktop** | Runs the MCP server, connector, and agent | run the app |

You do **not** need to install Python, ffmpeg, or any pip packages locally. All report rendering (`build_report.py`) and video frame extraction run inside Claude's sandboxed code execution environment, which is provisioned per session by Anthropic.

---

## 3. The `ms365` MCP server — `claude_desktop_config.json`

**File location:**
- Windows: `%APPDATA%\Claude\claude_desktop_config.json`
- Mac: `~/Library/Application Support/Claude/claude_desktop_config.json`

There are two known issues on Windows that shape the setup below:

- **The `%APPDATA%\Claude` folder (logs, config file) is not always created on install.** If it is missing, nothing reads a config you never had a place to put. You create the folder and file yourself.
- **Even with a correct `npx`-based config, the server sometimes does not load after a restart.** The reliable fix is to point the config directly at the globally-installed server binary (`ms-365-mcp-server.cmd`) rather than at `npx`.

Both are handled by the two branches below.

### Branch A — the folder and config file do not exist yet

A PowerShell script in the same GitHub repo (`setup-claude-ms365.ps1`) handles this. What it does:

1. Creates the `%APPDATA%\Claude` folder if it is missing.
2. Checks whether `%APPDATA%\npm\ms-365-mcp-server.cmd` exists yet (i.e. whether the global install has been run). If not, it just prints a warning telling you to install it and re-run — it does not install anything itself.
3. If `claude_desktop_config.json` does not exist, it writes a fresh one with the `ms365` block pointing at the full `.cmd` path. If a config file already exists, it leaves it alone and instead prints the `ms365` block to paste in yourself (see Branch B).
4. Prints the remaining next steps (install, login, add the Filesystem connector, restart Claude Desktop).

It never installs the npm package itself and never touches the filesystem connector. Run it, or do the same by hand.

By hand, create `%APPDATA%\Claude\claude_desktop_config.json` with:

```json
{
  "mcpServers": {
    "ms365": {
      "command": "C:\\Users\\<username>\\AppData\\Roaming\\npm\\ms-365-mcp-server.cmd",
      "args": ["--org-mode"]
    }
  }
}
```

Replace `<username>` with the actual Windows username on that machine. Use the full literal path: Claude Desktop does not expand `%APPDATA%` inside the config.

The script does **not** add a filesystem server. The filesystem connector is added through the app (see below), not the config file.

### Branch B — a folder and config file already exist

Do **not** replace the whole file, especially if other servers (Gmail, Calendar, WhatsApp, etc.) are already in it. Open the existing file and add just the `ms365` block inside the existing `mcpServers` object:

```json
    "ms365": {
      "command": "C:\\Users\\<username>\\AppData\\Roaming\\npm\\ms-365-mcp-server.cmd",
      "args": ["--org-mode"]
    }
```

Watch the commas: every entry in `mcpServers` except the last needs a trailing comma.

**Do NOT add** a `t3t-video` entry. If you are migrating an old config, delete that block entirely.

### Install and log in to the server

The `.cmd` path in the config only exists after a global install. In PowerShell:

Install (this is what creates `...\AppData\Roaming\npm\ms-365-mcp-server.cmd`):

```
npm install -g @softeria/ms-365-mcp-server
```

Then log in:

```
ms-365-mcp-server --login
```

Follow the device-code prompt and sign in with the **T3T work account**. (If `ms-365-mcp-server` is not found on PATH in that terminal, either open a fresh terminal or run `npx @softeria/ms-365-mcp-server --login` instead. `--org-mode` is what points the server at the T3T tenant rather than a personal Microsoft account, which is why it stays in the config `args`.)

One permission is worth knowing about up front: ad-hoc or 1:1 Teams calls with no calendar invite need `CallTranscripts.Read.All`, which requires Global Admin consent. On the T3T tenant that is **Stephan**. Scheduled-meeting transcripts do not need this.

### Fully restart Claude Desktop

After editing the config and logging in, **fully quit and reopen** Claude Desktop (quit completely, not just close the window). It only reads the server list on a clean start.

### Add the filesystem connector

The filesystem access is added through the app, not the config file:

1. In Claude Desktop, go to **Customize > Connectors**.
2. Click **add** / **Browse connectors**.
3. Find **Filesystem** and click it.
4. Click **Install**.
5. Add the folder where that consultant saves screenshots. That is the only folder the agent needs.

The screenshots folder is usually `Pictures\Screenshots` (the Windows Snipping Tool / Win+Shift+S default). If a consultant saves screenshots somewhere else, use that path instead.

---

## 4. Account settings (owner does this once for the team)

Because T3T is on Claude Team, these are set once by an **owner** at the organization level, not by each consultant.

Owner steps:

1. Owner clicks their profile icon (bottom-left) > **Settings**.
2. Go to **Organization settings > Capabilities**.
3. Turn on **Code execution and file creation**. This is what runs `build_report.py` and the video frame extraction. Without it the agent cannot render the `.docx` at all.
4. Still under **Capabilities**, find **Allow network egress** (it sits under Code execution). Set it to **Package managers and specific domains** (the Team default is package-managers-only, which blocks SharePoint).
5. In the domain list, click **Add** and add both:
   - `times3technologies-my.sharepoint.com`
   - `*.sharepoint.com`
6. Save.

This egress allowance is used for one thing: downloading the Teams recording directly from OneDrive inside the sandbox (Step 4b of the agent). The `ms365` MCP calls are unaffected by this setting either way.

Each consultant should **start a brand-new conversation** after these settings are applied. A conversation already in progress will not pick up a capabilities change made mid-session.

---

## 5. Filesystem folder — what to actually grant

The filesystem connector only needs **one** folder: wherever that consultant saves screenshots during and after a call (default `Pictures\Screenshots`).

Everything else the agent reads (the Teams recording and transcript) comes through the `ms365` server and the sandbox, not the local filesystem, so extra folders like Desktop or Downloads are not required. Add them only if a particular consultant's workflow saves screenshots there.

If the agent ever reports it cannot see the screenshots folder, that path was not added when the Filesystem connector was installed. Reopen **Customize > Connectors > Filesystem** and add it.

---

## 6. What the agent installs on its own (no setup needed)

These happen automatically inside the code execution sandbox every session, nothing to configure ahead of time:

- `pip install imageio-ffmpeg` gives a working static ffmpeg binary for frame extraction (Step 4b of the agent).
- `python-docx` and `Pillow` are used by `build_report.py` and the redaction/crop step; these are standard in the sandbox already.

There is no persistent local server for video. The sandbox is created fresh each conversation.

---

## 7. Quick verification checklist

Run through this once after setup, before relying on it for a real client report:

- [ ] Agent (`consultation-report.zip`) provisioned by an owner under **Organization settings > Skills**, and it appears for the consultant under **Customize > Skills**
- [ ] `node -v` returns v18+
- [ ] `npm install -g @softeria/ms-365-mcp-server` has run (so `...\npm\ms-365-mcp-server.cmd` exists)
- [ ] `%APPDATA%\Claude\claude_desktop_config.json` exists, has an `ms365` block pointing at the `.cmd` binary, and no `t3t-video`
- [ ] Signed in to `ms365` with the T3T work account (try `ms365: list-calendars` to confirm)
- [ ] Filesystem connector installed via **Customize > Connectors**, with the screenshots folder added
- [ ] Owner has enabled **Code execution and file creation** in **Organization settings > Capabilities**
- [ ] Owner has set **Allow network egress** to package managers and specific domains, with `*.sharepoint.com` and `times3technologies-my.sharepoint.com` added
- [ ] Claude Desktop fully quit and reopened after editing the config
- [ ] Fresh conversation started after the settings changes above

---

## 8. Common setup-stage errors

| Symptom | Likely cause |
|---|---|
| Agent does not appear for a consultant | Not provisioned org-wide yet, or the consultant toggled it off in Customize > Skills |
| Agent uploaded but subfolders missing / it misbehaves | Zipped the files instead of the folder, so `assets/`, `reference/`, `scripts/` were flattened. Re-zip the whole folder |
| `ms365` tools not appearing at all | `%APPDATA%\Claude` or the config file was never created, config JSON is malformed (check commas/brackets), or the `.cmd` path is wrong. Also confirm the global install actually ran |
| `ms365` config looks correct but server still does not load on restart | The `npx`-based config quirk. Switch the `command` to the full `ms-365-mcp-server.cmd` path and fully restart |
| Sign-in loops or fails | Not logged in via `ms-365-mcp-server --login`, or signed into a personal account instead of the T3T work account |
| Ad-hoc call transcript access denied | `CallTranscripts.Read.All` not yet approved by Stephan (Global Admin) |
| `get-download-url` file fails to download in sandbox | Network egress not set to allow the SharePoint domains, or set but the conversation was not restarted |
| ffmpeg download step fails in sandbox | Code execution not enabled in Organization settings > Capabilities |
| Agent cannot find the screenshots folder | Screenshots path not added when the Filesystem connector was installed |
