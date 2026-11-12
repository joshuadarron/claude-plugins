# daily-brief

Two skills that keep a running record of your work and keep everyone's Notion tracker in the same shape.

- **tracker-update**: the team's standard Notion tracker format. It handles the schema, the status rules, when something becomes a row or a checklist item, and the `## Next` / `## Log` page body. You can use it by hand ("log this to my tracker") or let the daily brief call it.
- **daily-brief**: a nightly run that gathers yesterday's work from Claude chats, GitHub, Calendar, Drive, Gmail, Slack and Notion, writes a Google Doc, and updates your tracker through tracker-update.

The skills never send email or messages, never share files, and never delete anything.

## Install in Claude (required for the nightly loop)

1. Download `daily-brief.zip` and `tracker-update.zip` from the latest `daily-brief-v*` release on this repo's Releases page.
2. In Claude, go to **Customize > Skills > + > Create skill > Upload a skill**. Upload each ZIP, then make sure both are toggled on.
3. In **Settings > Capabilities**, make sure **Code execution and file creation** is on.

To update, download the new release and upload both ZIPs again.

## Install in Claude Code (optional)

```
npx skills add <this repo> --skill daily-brief --skill tracker-update -a claude-code -g
```

`npx skills update` pulls newer versions later.

## Prerequisites

- Connectors: Google Drive, Google Calendar, Gmail, Slack, Notion
- **Search and reference chats** turned on in Settings
- An empty Drive folder named `Daily Brief`
- A Notion tracker with these properties: Task name, Status (Not started / In progress / Blocked / Done), Priority (P0 / P1 / P2), Owned by (multi-select), Assignee (person), Task type, Start date, Due date, Description, Waiting on, PR / Issues. Add a board view grouped by Status and filtered to Assignee = you. If the schema doesn't match, tracker-update stops and reports the mismatch instead of writing.

## Create the nightly loop

Open a new Claude chat, paste this with your values filled in, and send it:

```
Create a scheduled task called "Daily brief" that runs every night at midnight Pacific in a fresh session, with Google Drive, Google Calendar, Gmail, Slack and Notion attached. The task prompt is:

Run the daily-brief skill for yesterday with these values:
- Name: <your full name> (first name <first name>)
- Email: <work email>
- Role: <title> at RocketRide
- Time zone: America/Los_Angeles
- GitHub user: <github handle>, orgs: rocketride-org
- Slack member ID: <member id>
- Notion workspace: <workspace name>
- Notion user ID: <notion user id>
- Notion owner option: <your name in the Owned by field>
- Tracker URL: <tracker database url>
- Tracker data source: <collection://...>
- Board view: <board view name>
- Drive root folder ID: <Daily Brief folder id>
- Excluded Drive folders: none
```

Finding your IDs:

- **Drive folder ID**: the last segment of the folder URL.
- **Slack member ID**: Profile > More > Copy member ID.
- **Notion IDs**: ask Claude in a chat with Notion connected: "what's my Notion user id, and the data source id for <tracker URL>".

After it's created:

1. Open the task's settings and set approval to **Automatically approve**, or every run stalls on its first write.
2. Check that all five connectors are attached to the task itself. Connectors on your account are not automatically attached to scheduled runs.
3. Run it once manually and check the doc and the Notion changes.

## Notes

- **Re-running is safe.** If a doc for that day already exists, the run stops and skips Notion.
- **GitHub** comes from the gh CLI. If the run environment has no GitHub access, the run skips it and names it in the doc's Conclusion.
- **Skipped sources** are always listed in the Conclusion, so a missing connector is easy to spot.

## Releasing changes

Edit the skills, bump `version` in `.claude-plugin/plugin.json`, and open a PR. CI validates the skills and fails the PR if the version wasn't bumped. Merging to main publishes a `daily-brief-v<version>` release with both ZIPs attached.
