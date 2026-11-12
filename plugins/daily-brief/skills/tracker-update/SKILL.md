---
name: tracker-update
description: Apply work changes to a person's Notion task tracker in the team's standard format. Use when asked to log, update or sync work to a tracker, or when the daily-brief skill reaches its Notion step.
---

# Tracker Update

Writes work changes into a person's Notion task tracker so every tracker on the team has the same shape. The daily-brief skill calls this for its Notion step, and people can call it by hand ("log this to my tracker").

## Inputs

The caller provides:

- **Owner option**: the person's option in the "Owned by" multi-select
- **Notion user ID**: used for Assignee
- **Tracker data source ID** (collection://...)
- **Changes**: a list of work items, each with what happened, the date, and the source that shows it (PR, issue, email, meeting, doc)

If a value is missing:
- Interactive use: get the user ID with notion-get-self, and ask for the tracker URL if it was not given.
- Unattended use (scheduled run): make no changes, and report which input was missing.

## Standard schema

Fetch the tracker schema first. It must have these properties:

| Property | Type | Values |
|---|---|---|
| Task name | title | |
| Status | status/select | Not started, In progress, Blocked, Done |
| Priority | select | P0, P1, P2 |
| Owned by | multi-select | names |
| Assignee | person | |
| Task type | select | existing options only |
| Start date | date | |
| Due date | date | |
| Description | text | |
| Waiting on | text | |
| PR / Issues | text/url | |

If any property is missing or a Status option does not match, stop and report the mismatch. Do not adapt to a different schema and do not change the schema. Consistent trackers across the team are the reason this skill exists.

## Status rules

Status columns mean: Done = what they have done, In progress / Blocked = what they are working on, Not started = what they need to do.

- **In progress**: a source shows work started.
- **Blocked**: progress stopped because the person is waiting on someone else. Fill in Waiting on.
- **Done**: only when a source shows the work finished: PR merged, issue closed, decision made, deliverable shipped or sent. A draft is not Done.
- **Not started**: a to-do with no work yet.
- Never move a row backwards (for example Done to In progress) unless a source shows it reopened.

## Priority

- **P0**: blocks other people, or has a committed date within 3 days.
- **P1**: planned work for the current cycle.
- **P2**: everything else.

Keep an existing row's priority unless the day's sources give a reason to change it.

## Row or checklist item

For each change, search the tracker by title and keywords before creating anything.

- **Existing row matches**: update it.
- **New row**: only for a substantial work stream, bug, deliverable or commitment with no existing row.
- **Checklist item**: a small follow-up that belongs to an existing task goes in that row's `## Next`, not a new row.
- **Neither**: no rows for single meetings, routine PR reviews or trivial chores.

## Updating an existing row

- Set Status per the rules above.
- Description: 1 to 3 sentences, current state plus next step. Keep useful existing text.
- Waiting on: set when blocked, clear when resolved.
- PR / Issues: add new numbers or links, keep existing ones.
- Due date: set only when a date was committed.
- Make sure Assignee includes the person, or the row will not appear on their board view.

## Creating a row

Set Task name, Status, Priority, Owned by (the person's option plus collaborators that already exist as options), Assignee (the person's user ID), Task type (an existing option), Start date (the day work began, if it began), Due date (if known), Description and PR / Issues. Never create new select or multi-select options.

## Page body format

Every row touched gets exactly these two sections, in this order:

```
## Next
- [ ] concrete next step
- [x] step completed

## Log
- 2026-11-11: what changed that day, 1 to 2 sentences.
```

- `## Next`: the person's concrete next steps for this task. Check off items the day completed and add new ones from the day's action items.
- `## Log`: one line per day, appended at the bottom, dated YYYY-MM-DD. If the day already has a line, extend that line rather than adding a second.
- Create both sections if the page is blank. If the page has other content, leave it alone and add the sections below it.
- Use update_content to check items off and insert_content to append. Never rewrite or delete other content on the page.

## Guardrails

- Only touch rows the person owns or is assigned to, plus rows this skill creates.
- Never edit other people's rows, delete or archive anything, change the schema or views, leave comments, or mention people.
- Base every change only on what a source shows. Do not infer progress.

## Output

Return a change list grouped as Done / In progress / Blocked / Not started. For each row, say whether it was created or updated and what changed. List any changes that could not be applied, with the reason.
