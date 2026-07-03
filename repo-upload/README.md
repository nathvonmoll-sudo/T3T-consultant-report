# T3T Consultation Report — Claude Skill

Turns a client consultation (Teams recording + transcript on OneDrive, plus consultant screenshots and client emails) into a completed T3T Consultation Report `.docx`, filled into the real Sage-branded template. Built for HR & Payroll and ERP consults that need an evidence + billing record before they go onto the Freshdesk ticket.

This is the **current version** of the pipeline. It replaces an earlier version of this project (see [`nathvonmoll-sudo/T3T---consultant-report`](https://github.com/nathvonmoll-sudo/T3T---consultant-report)) that used a dedicated `t3t-video` stdio MCP server for video frame extraction. That server has been retired — frame extraction now runs inside Claude's built-in code execution sandbox, which is simpler to set up and doesn't need a persistent local process.

For full machine setup instructions (MCP servers, config file contents, account settings, folders), see **`SETUP.md`** in this repo.

---

## What it does

1. Finds the Teams recording for a consult on OneDrive (`ms365` MCP)
2. Derives the exact meeting time window from the recording's filename
3. Pulls the Teams transcript via the Graph API (scheduled meetings or ad-hoc calls)
4. Gathers evidence images — consultant screenshots first, video frames only to fill gaps — with every image reviewed and redacted before use
5. Matches client emails to the work done, to build an auditable "Sources Used" list
6. Writes a structured `report.json` in T3T house style
7. Renders it into the exact `.dotx` template via a deterministic script
8. Hands the draft back for a quick consultant review before it goes on the ticket

## Division of labour

- **Claude does the judgement**: reading the transcript, deciding what belongs in each section, matching evidence to actions, writing in house style.
- **The bundled script (`scripts/build_report.py`) does the rendering**: it's deterministic and always produces the exact T3T template (boilerplate, sign-off, footer/logo intact). The report is never hand-built directly into the `.docx`.

## What's in this skill folder

```
consultation-report/
├── SKILL.md                                   # the full workflow Claude follows
├── assets/
│   └── T3T_Consultation_report_Template.dotx  # the real template
├── reference/
│   └── house-style.md                         # writing style rules for report text
└── scripts/
    └── build_report.py                        # renders report.json → .docx
```

## Requirements to run it

- Claude Desktop with **Code execution and file creation** enabled
- MCP servers: `ms365` (OneDrive, Teams transcripts, email) and `filesystem` (screenshots folder)
- Network egress allowlist entries for `*.sharepoint.com` (recording download only)
- A Freshdesk-issued case number, and the transcription toggle actually turned on during the call — no toggle, no transcript, no automatic report

See **`SETUP.md`** for the full walkthrough.

## Scope

- ✅ Client HR & Payroll / ERP consults that are billable
- ❌ Sage/internal calls — not billable, no report generated
- ❌ The ticket-suggestion project — separate system entirely
- Other report types (e.g. onboarding) are sibling skills sharing this template and renderer, not covered here

## Known limitations

- Ad-hoc/1:1 call transcripts require the `CallTranscripts.Read.All` Graph permission, which needs Global Admin approval on the T3T tenant
- Auto-generated transcripts mangle Afrikaans, names, and payroll jargon (EMP501, IRP5, 3601/3607) — Claude works from the gist and flags uncertain names rather than guessing
- If transcription wasn't started during the call, no transcript can be retrieved afterward by any method
