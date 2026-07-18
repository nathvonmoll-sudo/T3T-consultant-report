# Using the Consultation Report Agent

A quick guide to running `/consultation-report` — from starting the recording on your call through to getting the finished `.docx`.

---

## Step 0: Start recording and transcribing on the call

This has to happen **at the start of the meeting**, or there's no transcript for the agent to work from later.

1. In the Teams call toolbar, click **More (...)**.
2. Select **Record and transcribe**.
3. Click **Start recording**.

That's it — Teams handles the rest in the background. If this step is skipped, no transcript is generated for that call and there is nothing for the agent to build a report from afterward, regardless of which workflow below you use.

---

## Starting the agent

There are two ways to call it:

**Type `/` and select it from the list**
Type `/` in the chat box, then choose **consultation-report** from the menu that appears.

**Just ask for it in plain language**
The agent also triggers off normal requests, for example:
- "Can you write up the consult I had with Corné this morning?"
- "Do the consultation report for the payroll call with [client]."
- "Generate the report for today's ERP session."
- "Document the meeting I just had — HR & Payroll consult."

Either way works. The "/" method is faster if you know exactly what you want; plain language is fine if you're just describing what happened.

---

## Path A — Manual upload (no MCP server)

Use this if the `ms365` MCP server isn't set up on your machine yet, or you'd rather just hand Claude the transcript directly.

1. **Get the transcript from Teams.** Either:
   - Open the **Teams chat** created automatically for that call, and download the `.vtt` transcript file from there, **or**
   - Go to **OneDrive → Files → Recordings**, find the recording for that call, and download its transcript from there.
2. **Bring it into Claude.** Either drag and drop the `.vtt` file straight into the chat, or click the **+** icon and choose **Open file** to attach it.
3. **Ask for the report** — either type `/` and select **consultation-report**, or just ask directly, e.g. "Can you do the consultation report for this call?"

Claude will work from the transcript you've uploaded, ask for anything else it needs (screenshots, client/case details, etc.), and produce the `.docx`.

---

## Path B — Full automation (with the `ms365` MCP server)

Use this once the `ms365` MCP server and filesystem connector are set up (see the machine setup doc if that's not done yet). Nothing needs to be downloaded or uploaded by hand — the agent finds everything itself.

1. **Call the agent** — `/consultation-report`, or ask for it in plain language.
2. **Give it context about the meeting**: always name who it was with and give a specific time, rather than a vague reference like "this morning" — that's what lets the agent identify the right recording without confusion. For example:
   - "Do the consultation report for the call with Corné Pistorius at 9:15am today."
   - "Write up the payroll consult with [client] from Tuesday at 2pm."

That context matters because the agent has to go and *find* the right recording and transcript itself — in your OneDrive Recordings folder, via the `ms365` connection — rather than being handed a file. A specific name and time lets it identify the correct recording directly; if there's still more than one candidate, it will check with you before proceeding.

From there it fetches the transcript, pulls in your screenshots, checks for relevant client emails, and puts together the `.docx` for your review before it goes onto the ticket.
