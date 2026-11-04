---
name: pr-review
description: Review a GitHub pull request against Joshua's standards and submit an approve or request-changes verdict without asking. Use when given a PR number or URL to review, or when asked to review a diff or branch.
allowed-tools: Bash(bash ${CLAUDE_SKILL_DIR}/checks.sh *)
---

# PR Review

Review the PR, decide, and submit the review. Do not ask for permission to approve or request changes.

## Hard rules

- Never merge, enable auto-merge, close, or push to the PR branch. Merging belongs to the engineer, or to another maintainer for outside contributors.
- Submit exactly one verdict: `--approve` or `--request-changes`. Never use `--comment` as a way to avoid deciding.
- If `gh pr review --approve` fails because you are the PR author, submit the same body with `--comment` and state the verdict on its first line.

## Procedure

1. Load the `dev-standards:code-taste` skill. It is the coding standard for this review.
2. Run the deterministic checks:
   ```
   bash ${CLAUDE_SKILL_DIR}/checks.sh <pr-number-or-url>
   ```
   Every line starting with `BLOCKING:` goes into the review as a blocking item, word for word. Every line starting with `NIT:` goes in as a nit, word for word. Do not re-verify what the script already decided.
3. Read the linked issue(s), if any, in full: `gh issue view <n>`.
4. Read the full diff: `gh pr diff <n>`. For any change whose correctness depends on surrounding code, read the whole file, not only the hunk.
5. Run local checks when the repo is checked out: the project's typecheck, lint, and tests for the touched packages. Failures are blocking.
6. Go through the checklist below and classify every finding by severity.
7. Submit the review with inline comments and the summary body.

## Checklist

**Issue and intent**
- A linked issue exists (the script checks this). A missing issue is a nit, not a blocker.
- When an issue is linked, it describes the problem, the expected behavior, and enough context to judge a solution. A one-line issue is not ample. Request that it be expanded.
- The change solves what the issue asks for: no less, and no unrelated extras.

**Scope**
- The PR does one thing. If it mixes concerns (a feature plus an unrelated refactor, two features, a fix plus a dependency upgrade), name how to split it, listing which files or changes belong in each PR. Splitting is a should-fix, not a blocker.
- A PR that is too large to review with confidence should be split, even if it's all one concern. Propose split points (for example: types and data layer first, then logic, then UI). This is also a should-fix.
- Formatting churn or renames in untouched code count as unrelated changes.

**UI**
- If the change adds UI or changes how anything looks and the PR body has no screenshots (the script checks this), request before and after screenshots. For a new UI, request screenshots of each new state (empty, loading, error, populated). Missing screenshots are a nit, not a blocker.

**Correctness**
- Breaking logic: wrong conditions, off-by-one errors, unhandled states, race conditions, a changed contract that existing callers rely on.
- Redundant logic: conditions that are always true or always false, checks the caller already guarantees, code that duplicates something the codebase already provides.
- Error handling and edge cases: null and empty inputs, failed async paths, swallowed errors. Errors follow the `code-taste` rules (custom error class, callout helper, no try/catch outside boundaries).

**Security**
- Injection (SQL, shell, path traversal, template), unvalidated input at trust boundaries, missing auth or permission checks, SSRF, unsafe deserialization.
- Secrets in code, fixtures, logs, or error messages. Sensitive data in logs.
- New network exposure (ports, endpoints, CORS changes).

**Repeated code**
- Duplicated blocks inside the PR, or reimplementing something that already exists in the codebase. Point to the existing implementation.

**Standards**
- Everything in `code-taste`: readability rules, single-purpose functions in top-down classes, doc comments on every export, naming, types, the language deviations.
- Naming and structure satisfy tsconfig, lint, and CI. Tooling failures are blocking. Also flag names that pass tooling but violate `code-taste`.
- Environment variables are read only by the central config module.
- Data access goes through the repository layer.

**Tests**
- New or changed logic has tests. Tests live in the mirrored test tree.
- Tests assert behavior, not implementation details.

**Dependencies**
- Each new dependency is justified in the PR body and its license is compatible with the project's license (MIT for RocketRide).
- Lockfile changes match the manifest changes. An unexplained lockfile churn is blocking.

**Debris**
- No `console.log`, `print`, or debug output; no commented-out code; no dead code.
- Every TODO links an issue.

**Public surface**
- Changes to public APIs, SDKs, wire protocols (for RocketRide, the WebSocket protocol), pipeline JSON schema, CLI flags, or config keys are backward compatible, or the break is called out in the PR body with a migration path.
- Docs and the changelog are updated for any public surface change.

**Performance**
- N+1 queries, unbounded loops or collections, sync I/O on hot paths, unnecessary allocations or copies in hot code, leaks or lifetime bugs in C++ async code.
- A performance issue is excusable only when all of these hold:
  - A TODO comment at the site explains the tradeoff.
  - The TODO links an open issue that describes the fix.
  - The reason is real (shipping a blocking fix, waiting on a dependency, the cost measured as negligible at current scale). "Will fix later" or "good enough for now" is not a reason.
  - The fix is in motion: the issue is assigned or scheduled.

  If any of these is missing, the performance issue is blocking.

## Severity

- **Blocking**: anything the script flags as `BLOCKING:` (merge conflicts, failing CI), failing tooling, security issues, breaking logic, missing tests for new logic, an unexcused performance issue, a `code-taste` violation that hurts readability in a way a reader would trip on.
- **Should fix**: real problems that don't make the PR wrong to merge (a PR that should be split for scope or size, a weak name, a missing edge-case test, a doc comment that's present but unclear).
- **Nit**: preference-level polish, and anything the script flags as `NIT:` (no linked issue, branch behind the base branch, missing UI screenshots).

**Verdict:** any blocking item means request changes. Zero blocking items means approve, with should-fix items and nits included as non-blocking comments.

## Output

Post the specific findings as inline comments on the relevant lines. Each inline comment is a concrete ask with its severity tag, for example `[blocking] Replace this ternary with an if block (code-taste: readability).`

The review body is the summary:

```
**Verdict: Request changes** (or **Verdict: Approve**)

One or two sentences on what the PR does and the overall state.

**Blocking**
- `path/to/file.ts:42` Concrete ask.

**Should fix**
- `path/to/file.ts:88` Concrete ask.

**Nits**
- `path/to/file.ts:12` Concrete ask.

**Split plan** (only when a split is recommended)
- PR 1: what goes in it.
- PR 2: what goes in it.
```

Omit empty sections. Every item is an action ("extract X into Y", "add a test for the empty-list case"), never just an observation.

Submit with:

```
gh pr review <n> --request-changes --body-file <summary.md>
gh pr review <n> --approve --body-file <summary.md>
```

After submitting, report the verdict and the summary back in the conversation.
