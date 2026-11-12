---
name: daily-brief
description: Write a person's daily work brief for a past day: gather activity from Claude chats, GitHub, Calendar, Drive, Gmail, Slack and Notion, create a Google Doc, and update their Notion tracker. Use when asked to run the daily brief.
---

# Daily Brief

Produces a record of everything a person worked on in one day, so they can scan it before a standup or 1:1. Two outputs per run: (A) one Google Doc per day in Drive, and (B) their Notion tracker updated through the tracker-update skill.

## Inputs

The caller (usually a scheduled task prompt) provides: full name, first name, work email, role, IANA time zone, GitHub user, GitHub orgs, Slack member ID, Notion workspace, Notion user ID, Notion owner option, tracker URL, tracker data source ID, board view name, Drive root folder ID, Drive folders to exclude (optional), and extra style rules (optional).

If a required input is missing in an unattended run, still produce what the available inputs allow and name the gap in the Conclusion.

## 1. Target day

Yesterday in the person's time zone, 12:00 AM to 11:59 PM local, unless the caller names a different date. Convert that window to UTC for every lookup, accounting for daylight saving time.

## 2. Gather

Pull what they did in the window from all of these. Skip any source that is unavailable without failing, and name skipped sources in the Conclusion.

a. **Claude chats**: recent_chats with after/before set to the window, then conversation_search / read_conversation when a snippet is too thin.

b. **GitHub** via the gh CLI for their user, mainly their orgs' repos: commits authored in the window, PRs opened, reviewed or merged, issues filed or commented on. Search queries need is:pull-request or is:issue. Retry once on a 502. Also check memory files for untagged dated lines from Claude Code sessions dated that day, if memory tools are available.

c. **Google Calendar**: list_events on their primary calendar. Include meetings they attended or organized, skip declined ones. For each meeting with attached "Notes by Gemini" or a notes/transcript doc, read it with read_file_content and pull out decisions and action items that belong to them.

d. **Google Drive**: search_files for files they own or edited that day (modifiedTime in the window, plus owner = 'me' or createdTime in the window). Record docs, sheets and decks they created or meaningfully worked on; read briefly only when the title is unclear. Ignore files inside the Daily Brief folder, the excluded folders, and meeting notes already covered in (c).

e. **Gmail**: search_threads with after:YYYY/MM/DD before:YYYY/MM/DD (next day). Cover in:sent, drafts for that range (list_drafts), and inbox threads from real people that need a reply or action from them. Use get_thread when the preview is not enough. Ignore newsletters, promotions, notifications and automated mail.

f. **Slack**: their messages that day (from:<@MEMBER_ID> on:YYYY-MM-DD) for context and open follow-ups.

g. **Notion**, in their workspace:
   - Tracker: fetch the schema, then query rows where Owned by contains their option or Assignee contains their user ID. Read each row's properties and page body (`## Next`, `## Log`). This is the current state of their work.
   - Pages they edited or created that day: search with edited_by_user_ids ["me"] (and created_date_range for the day), sorted by last_edited. Ignore template/onboarding pages and empty "Untitled" rows.
   - Notion meeting notes for the day (query-meeting-notes), treated like (c).

Leave out personal, family and health matters entirely. This is a work log. Merge duplicates across sources into one item.

## 3. Drive location

Inside the root folder: a year folder ("2026"), then a full month-name folder ("November"). Search with parentId before creating, and create a folder only if it does not exist.

Doc title: two-digit day, hyphen, lowercase weekday from this set: mon, tues, wed, thurs, fri, sat, sun. Example: "03-tues".

If a doc with that title already exists in the month folder, stop, report that the day was already processed, and skip step 5. This makes re-running safe.

## 4. Create the doc

Use Google Drive create_file with contentMimeType text/html (converts to a Google Doc) and parentId = the month folder. Keep it brief:

- H1: "Daily Brief: <Weekday>, <Month> <D>, <YYYY>"
- H2 "Summary": 2 to 3 sentences on what the day was about.
- H2 "Did": one-line bullets grouped by project (use Notion task names as groupings where they fit). Concrete: what moved, who with, PR/issue numbers, doc names. Say "drafted" when something was only drafted; never claim something was sent unless a source shows it.
- H2 "Need to do": open follow-ups, unanswered emails, meeting action items, things waiting on others, commitments made that day, and tracker rows that are Blocked or due within 3 days. Add a stale-check line for any In progress row with no activity in any source for 14+ days, asking whether it is still active (do not change that row's Status).
- H2 "Conclusion": 1 to 3 sentences on where things stand and what is fully in their hands next, plus any skipped sources or missing inputs.

If nothing was found for the day, still create the doc with a one-line Summary saying so, and make no Notion changes.

Style: plain, direct, engineer-to-engineer. No hype words. No placeholders or todos addressed to the reader inside the doc. Apply any extra style rules the caller provides.

## 5. Update the tracker

Use the tracker-update skill. Pass the owner option, Notion user ID, tracker data source ID, and the doc's "Did" and "Need to do" items as the changes, each with its date and source. If the tracker-update skill is not available, skip this step and say so in the final report.

## 6. Verify and report

Read the doc back once to confirm it has content. End with the doc title and its link, then the change list returned by tracker-update.

## Guardrails

Never send emails or messages, never share Drive files, and never edit or delete anything other than creating the folders and the doc above and the tracker changes made through tracker-update.
