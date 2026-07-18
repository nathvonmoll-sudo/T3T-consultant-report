# Consultation Report Agent — How It Works

**Version:** v1 (baseline)
**Agent package:** `consultation_report_v1.zip`
**Companion docs:** `SETUP.md` (machine setup) and `Using_the_Consultation_Report_Agent.md` (day-to-day use)

Terminology note: in Claude's interface this is managed under "Skills," so where you click it says Skills. Everywhere at T3T we call it the agent, and this document uses that term throughout.

---

## What the agent does

The `/consultation-report` agent turns a single client consult into the standard T3T Consultation Report `.docx`. That report is the evidence and billing record the client signs off. It then goes onto the Freshdesk ticket, where Shahida checks the dates and hours before it is sent.

It covers regular client consultations, HR & Payroll and ERP consults in particular. It is not used for Sage or internal calls, which are not billable and get no report, and it is not the ticket-suggestion project.

The design rests on one principle: a clean division of labour. The agent does the judgement, reading the transcript, deciding what belongs in each section, and writing it in T3T's house voice. A bundled Python script does the deterministic rendering into the exact template. The `.docx` is never hand-built.

---

## How a run works

End to end, a run moves through the same pipeline every time:

1. **Find the recording** in OneDrive by client name and date.
2. **Derive the meeting timeframe** from the timestamp encoded in the recording filename. This window drives screenshot filtering and email search.
3. **Get the transcript** through the Teams Graph API. There are two paths depending on the call type: scheduled meetings with a calendar invite, and ad-hoc or 1:1 calls.
4. **Gather evidence.** Consultant screenshots come first as the primary source; video frames are pulled only to fill the gaps screenshots leave. Every image is viewed, cropped, redacted, and reviewed with the consultant before it goes in.
5. **Find client emails.** These become the Sources Used section, a permanent audit trail of the inputs the work rested on.
6. **Write the report** as a `report.json` file, in house style.
7. **Render** that JSON into the template with the script.
8. **Present the draft `.docx`** for a short consultant review before it goes onto the ticket.

There are two ways to feed the agent. Path A is manual: hand it the `.vtt` transcript directly, no MCP server needed. Path B is full automation: with the `ms365` MCP server and the filesystem connector set up, the agent finds the recording, transcript, screenshots, and emails itself. The usage doc covers both.

---

## Folder structure

The agent is a single folder, zipped whole and provisioned org-wide. Zipping the folder rather than the loose files is what keeps the subfolders intact (`SETUP.md` covers the packaging step):

```
consultation_report_v1/
├── SKILL.md
├── assets/
│   └── T3T_Consultation_report_Template.dotx
├── reference/
│   └── house-style.md
└── scripts/
    └── build_report.py
```

Each part has one job. `SKILL.md` is the process, `house-style.md` is the voice, the template is the shell, and the script is the press that stamps one into the other.

---

## SKILL.md — the instructions

`SKILL.md` sits at the top of the folder and is the brain of the agent. It is what Claude reads to run the whole pipeline: the step-by-step flow, the exact `ms365` and filesystem calls at each stage, the two transcript API paths, the evidence-gathering rules, the `report.json` schema, and the final render command.

The description block at the top of the file is what makes the agent trigger on plain-language requests like "write up the consult I had this morning." Everything else in the folder is something `SKILL.md` points to. It tells Claude to follow `reference/house-style.md` for voice, to render with `scripts/build_report.py`, and that the script fills the template in `assets/`. In other words, `SKILL.md` is the only file that drives the run; the other three are resources it reaches for.

---

## reference/ — the voice and structure

This folder holds `house-style.md`, the rulebook for turning a consult into a report in T3T's real voice. It was learned from three actual signed reports (Reboni, John Thompson, and MLN), so it reflects how the reports genuinely read rather than a generic template.

It covers the fixed report structure (which parts are written and which are boilerplate), the voice rules (clear self-contained lines, capture every material action and decision, record the what and not the how, nest related items, owner-tag the To-Dos, exclude chatter), the evidence rules (screenshots primary, frames to fill gaps, redaction mandatory), and the definitions of the Sources Used and Recommendations / Instructions sections. It closes with worked examples that act as few-shot patterns, spanning a short prose-style report, a config task with screenshots, and an involved report with nested, owner-tagged To-Dos.

The agent uses it at the writing step. When Claude decides what goes in each section and how to phrase it, it follows `house-style.md`, so every report lands in the same voice regardless of who ran it or how involved the consult was. Keeping the voice in its own file means refining how reports read is a matter of editing this one document, without touching the script or the template.

---

## assets/ — the real template

This folder holds `T3T_Consultation_report_Template.dotx`, T3T's actual Sage-branded Consultation Report template, the same one the client signs off. It carries all the fixed furniture: the company header table, the Sage City boilerplate, the Scope, Actions Performed, and To Do headings, the hours table, the sign-off, the signature table, and the footer and logo.

The agent uses it through the script. The script opens this template and fills only the written parts into it, preserving everything else exactly. Because the output is the real template rather than a rebuilt lookalike, the `.docx` is client-ready and on-brand every time.

One format note: the file is a `.dotx` (a Word template), which python-docx will not open directly. The script converts it to a working `.docx` on the way in. This is handled automatically and needs nothing by hand.

---

## scripts/ — the renderer

This folder holds `build_report.py`, the deterministic renderer. It takes the `report.json` Claude writes and produces the finished `.docx` in the template.

It handles converting the `.dotx` template to a working `.docx`, filling the header table (company, contact person, case number, consultant, date), inserting Scope, Actions, To Do, and the optional Sources Used and Recommendations / Instructions sections after their headings, nesting sub-items, embedding images inline with their captions, and filling the hours table. Images are normalised through Pillow on the way in, so frames produced by ffmpeg embed cleanly rather than being rejected.

The agent uses it at the render step. After writing `report.json`, Claude runs:

```
python scripts/build_report.py report.json -o "<Company>_<YYYY_MM_DD>.docx"
```

Claude never hand-builds the document; the script guarantees the output is always the exact template with consistent formatting. The link between the two sides is the `report.json` contract: the script reads a fixed set of keys (`meta`, `scope`, `actions`, `todo`, `sources`, `instructions`, `hours`), so the field names must match exactly. `sources` and `instructions` are optional, and their headings render only when those keys are present.

---

## Change Log

This log records what changed in each version of the agent, newest first. Each entry names the version, the matching package (`consultation_report_vN.zip`), the date, and a short summary of what changed and why, so this document and the deployed agent always stay in step.

v1 is the baseline, so there are no changes to record yet.

_No entries yet._
