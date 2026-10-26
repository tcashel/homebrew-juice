---
name: use-juice-history
description: Retrieve bounded, cited evidence from the user's local Juice coding-session history. Use when asked why a line or commit exists, when the user explicitly refers to a repeated error or earlier attempt, when resuming named prior work, when unfamiliar code lacks rationale and changing it risks regression, or when the user wants Juice's exact Context Note. Do not use for general web knowledge, ordinary current-worktree inspection, or facts already present in the active conversation.
---

# Use Juice history

Treat Juice as an evidence source, not an oracle. Retrieve the smallest repository-scoped result that can resolve the uncertainty, preserve its coverage language, and let the current agent reason from the returned evidence.

## Check availability

Use the connected Juice MCP tools when present; `juice_status` reports access
and index freshness. Otherwise run `juice status`. This skill uses the
eight-operation agent surface from ADR 0053. If the installation exposes older
names, upgrade Juice and reload the client's tools before using this workflow;
removed names are not fallback aliases in the new surface.

- If a connected MCP tool or its grant is unavailable, ask the user to open Juice and repair **Settings → Connections**. Retry only after the state changes.
- If the `juice` command exists but CLI access is unavailable, ask the user to open Juice and enable **Settings → Advanced → Agent API → Juice CLI access**.
- If `juice` is absent on Apple Silicon macOS 26.3 or newer, give the exact install commands: `brew tap tcashel/juice`, `brew trust --cask tcashel/juice/juice-app`, then `brew install --cask juice-app`.
- On Linux, Windows, Intel Macs, or older macOS, say that the Juice app is not supported on this host and continue without historical claims. Do not recommend an impossible install.
- Never bypass a missing, revoked, or expired grant.

## Route the question

1. For orientation in an unfamiliar repository, call `juice_session_list` with `repo`, or search for the specific uncertainty with `juice_search`. Inspect the matching session before drawing conclusions.
2. For an unfamiliar file or line range, call `juice_why` with a `target` such as `Sources/App.swift:42-60` and `repo`. Use `juice_blame` when the question is line attribution, then expand only the returned session or commit.
3. For a repeated error, abandoned approach, or “last time” question, call `juice_search` with a narrow `repo`. Expand the strongest result with `juice_session_transcript`, passing the hit's `leafSourceID` as `session`, its `generation`, and a bounded range or `around` message index. A short search page carries per-term counts and suggestions; widening or changing match mode is an explicit choice.
4. For what a session changed or committed, call `juice_session_explain` with `session`. Use `session: "last"` with `repo` for the most recent work. Follow its counts with `juice_session_facts` and one `kind`: `files`, `commits`, `subagents`, `commands`, `images`, or `artifacts`. Recorded command exit status is evidence about that command, not proof of current runtime health.
5. For why a commit or session exists, call `juice_why` with `kind: "commit"`, `commit`, and `repo`, or `kind: "session"`, `session`, and `repo`. The commit form includes changed files and integration evidence.
6. Stop when the evidence answers the question or Juice reports missing or ambiguous coverage. Do not broaden to other repositories without the user's explicit scope.

Use equivalent `juice` CLI commands with `--json` when MCP is unavailable but the local CLI is connected.

Both transports return the same `juice/v1` envelope. Read `data` together with
`applied`, `freshness`, `page`, `next`, and `warnings`; use `page.nextCursor`
to continue. Shared inputs are flat (`repo`, `session`, `generation`, `from`,
`to`), not nested `filters`. `last` requires a repository scope on MCP unless
the user authorized `all: true`; the CLI can use its current checkout. Use
`fields` (CLI `--fields`) to select small sections of `data` when appropriate.

## Preserve the evidence boundary

- Distinguish an explicit captured human request from correlated errors, commands, edits, tests, and commits.
- Preserve confidence, provenance tier, warnings, omissions, ambiguity, and `not captured` exactly.
- Separate captured history from `live` Git/filesystem/index observations and Juice's `derived` links. Check freshness before treating a recently recorded fact as relevant; Juice cannot observe running processes, environment variables, or servers.
- Never turn temporal proximity, attribution, or a search match into causal intent.
- Cite the returned session, message, commit, file, and line locators that support the answer.
- Prefer pointers and bounded excerpts over full transcripts. Do not include evidence unrelated to the current repository and question.
- Remember that a cloud-backed client may send selected Juice output to its provider after Juice returns it.

## Keep Context Notes canonical

Do not synthesize something and call it a Juice Context Note. The canonical note
is rendered by Juice from the typed Why result with deterministic redaction,
UTF-8 bounds, omission accounting, and an exact preview before copy.

- When the user asks for a **Juice Context Note**, direct them to **Juice →
  Context**, resolve the same file, commit, or session target, inspect the exact
  preview, and copy it there. Do not claim that MCP or CLI output reproduced
  those exact share-safe bytes.
- If the user instead asks you to summarize returned evidence in the current
  conversation, label it **Agent-authored summary**, separate Juice evidence
  from your inference, and preserve confidence, coverage, and `not captured`.
- Never post, send, or write either artifact externally without explicit user
  authorization.

If the user did not ask to share, keep the result inside the current task and use it only to answer or guide the work.

For saved transcript references, retain the source, leaf session ID, message index,
and generation ID. Pass the returned search hit's `generation` to the first
`juice_session_transcript` read; its `page.nextCursor` keeps later pages on
that generation. Treat `legacy_partial` storage as surviving evidence, not a
complete original log. Never silently substitute the latest generation for a
saved reference that is unavailable.
