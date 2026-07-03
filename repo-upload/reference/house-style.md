# T3T Consultation Report — House Style

How a consult becomes a report. Learned from three real signed reports (Reboni, John Thompson, MLN). The **structure is fixed**; the job is filling three sections in the right voice.

## The fixed structure (the template handles this)
Company header table → Sage City boilerplate → **Scope of Consultation** → **Actions Performed** → **To Do** → hours table → sign-off → signature table → footer. Only Scope / Actions / To Do / the header fields / hours are written; everything else is boilerplate the renderer preserves.

## Voice rules

> **Target: clearer and more complete than the current T3T reports — not more verbose.** The legacy reports are sometimes *too* terse and drop real decisions (MLN's report never mentioned the tax-forcing or the source-code split). We improve on them two ways: **coverage** (capture every material action/decision, nothing dropped) and **wording** (phrase each item clearly and professionally). Keep it scannable: short, well-formed lines, not paragraphs.

1. **Clear, self-contained lines.** Each line should read on its own. Prefer a clean short clause over a bare keyword: "Earnings split confirmed for SARS — normal hours to code 3601, overtime to 3607" beats "3601/3607 split". Still a line, not a paragraph.
2. **Comprehensive coverage.** Capture *every distinct action or decision* as its own line — don't collapse three decisions into one. The material items legacy reports tend to drop (the source-code split, the tax-forcing, the company split, the rehire handling) each earn a line.
3. **Record the *what*, not the *how* or *why*.** "ACB Files: ... FNB File used for permanent staff" — not a paragraph explaining FNB's cut-off. The mechanics and reasoning stay out.
4. **Nest related items.** A parent line with indented children: `Load 2 Companies → Permanent / Casuals`; `ACB Files → ...`.
5. **Scope = the task type, usually one line.** "Needs analysis." / "Performance management" / "BRD Document Discussion".
6. **Actions = past-tense facts of what was done.** Screenshots embed inline right after the action they evidence.
7. **To Do = forward commitments, each tagged with an owner.** "Lerusha will mark the casual staff in red…", "We will then capture the June finances…". **May be empty** if everything was finalised in the call.
8. **Exclude chatter.** No company politics, no social talk, no staff gossip. Just the client/employee/payroll facts. (E.g. MLN's "people leaving and coming back" discussion did *not* appear in the report.)
9. **Hours** is the consultant's billing call (call duration is a hint, not the answer). Leave for confirmation.

## Evidence (screenshots and video frames)
Images go inline in Actions Performed, gathered in a strict order with every image viewed and selected before inclusion — never blind by timestamp.

- **Consultant screenshots are primary.** They were captured deliberately, so they're high-signal. View each, match to a transcript point by capture time, keep only the relevant ones, redact and place them. This also tells you which points are already covered.
- **Frames fill the gaps only.** For actions with no screenshot where a system-state image would help, pull candidate frames, view them, and keep only those passing the test below. A frame is never pulled for a point a screenshot already covers, so the two never compete. Often the right number of gap-frames is zero.
- **A frame/screenshot may only evidence a system-state artefact** — a config screen changed, a permission granted, a payslip/report generated, a field captured, an error hit. **Never** talking points, an agenda, a doc/slide/README walked through, a webcam, an idle desktop, a transition, or anything that just restates a bullet. But **read the frame before you disqualify it**: a live config/permissions screen is easy to wave off as "just a doc on screen" at a glance — confirm what's actually there (OCR if text-dense) so you don't drop a real artefact you misread.
- **Context-only frames** (Step 5c) are pulled to *read* what's on screen — to identify which spreadsheet/document a source is, or resolve an ambiguous reference — then discarded. Transcript-cue-driven (pull where someone opens/refers to a doc), never embedded, never time-sampled.
- **Data-gathering / needs-analysis consults** often have *no* qualifying embedded images — the real evidence is the *sources*. Zero images is a normal, correct outcome.

**Redaction is mandatory.** This is a client-facing signed document. Before any image is embedded: crop to the artefact, then strip browser tab/bookmark bars, taskbar, notifications, other windows, the self-cam, and any stray email/filename/bookmark. Measure boundaries on the actual image rather than guessing. Cropped images are reviewed with the consultant before rendering.

## Sources used (declared) — NEW section
Declare the **inputs the work rested on** — the client emails and attachments whose data was used (the take-on sheet, the YTD spreadsheet, the month-by-month file). Keep this distinct from action screenshots:
- **Sources used** = *inputs* — what information the work relied on. Usually client **emails / attachments**, pulled from the mailbox.
- **Action screenshots** = *evidence of what was done* — system state, inline with the action.

Declare each source as a clear line, with its screenshot where available, e.g.:
"Client email (11 June) — *MLN Salaries Mar 2025 – Feb 2026*, month-by-month values  *[screenshot]*".
These render in a **Sources Used** section after To Do.

## Recommendations / Instructions (declared) — optional section
Separate from To-Dos. **To-Do** = a committed forward action with an owner ("Lerusha will send the sheet"). **Recommendations / Instructions** = guidance the client or consultant gave that isn't a committed task — standing instructions for how to handle things going forward, or advice given ("on the next run, use the FNB file for permanent staff", "we recommend splitting the companies before take-on"). If it's a thing someone agreed to *do*, it's a To-Do; if it's a thing someone said *should be done* as guidance, it's here. Omit the section entirely if nothing fits — don't pad it.

---

## Worked examples (use as few-shot)

### Example A — short, prose-ish (Reboni Furniture, "BRD Document Discussion")
- **Scope:** BRD Document Discussion
- **Actions:** A meeting was held with Joan and Sabine to discuss the detail of the BRD Document; the necessary changes were made; Joan will complete the missing information on the Job Titles. Afterwards they will confirm the document and sign off.
- **To Do:** (none)
- **Hours:** 1.00

### Example B — config task with screenshots (John Thompson, "Performance management")
- **Scope:** Performance management
- **Actions:**
  - Please load the attached Performance Contract for Ryno Dace.  *[screenshot]*
  - Key performance area  *[screenshot]*
  - Position  *[screenshot]*
  - Contract released  *[screenshot]*
- **To Do:** (none)
- **Hours:** 0.5

### Example C — involved, nested + owner-tagged To-Dos (MLN, "Needs analysis")
- **Scope:** Needs analysis.
- **Actions:**
  - IRP5s not submitted for period 2025 – 2026
  - Load 2 Companies → Permanent / Casuals
  - Employee take-on sheet provided  *[email screenshot]*
  - Year-to-date values captured as per the sheet provided  *[email screenshot]*
  - ACB Files → Permanent paid 28th / Casuals paid 1st / FNB for permanent / Standard Bank for late
- **To Do:**
  - Lerusha will mark the casual staff in red and send the completed sheet
  - Load the employees in 2 companies → Permanent / Casual
  - Complete the YTD figures for March 2025 – February 2026
  - Lerusha will send the Financials for March, April, and May 2026 by COB
  - We will then capture the June finances on the payroll for Payment on the 26th
- **Hours:** 1.0

> Note the range: A is two sentences, B is four fragments + shots, C is nested with owner-tagged To-Dos. Detail scales with how involved the consult was — but the voice (terse, factual, no chatter) is constant.
