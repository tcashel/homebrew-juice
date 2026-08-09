---
name: use-juice-history
description: Retrieve bounded, cited evidence from the user's local Juice coding-session history. Use when asked why a line or commit exists, when the user explicitly refers to a repeated error or earlier attempt, when resuming named prior work, when unfamiliar code lacks rationale and changing it risks regression, or when the user wants Juice's exact Context Note. Do not use for general web knowledge, ordinary current-worktree inspection, or facts already present in the active conversation.
---

# Use Juice history

Treat Juice as an evidence source, not an oracle. Retrieve the smallest repository-scoped result that can resolve the uncertainty, preserve its coverage language, and let the current agent reason from the returned evidence.

## Check availability

Use the connected Juice MCP tools when present. Otherwise run `juice status`.

- If a connected MCP tool or its grant is unavailable, ask the user to open Juice and repair **Settings → Connections**. Retry only after the state changes.
- If the `juice` command exists but CLI access is unavailable, ask the user to open Juice and enable **Settings → Advanced → Agent API → Juice CLI access**.
- If `juice` is absent on Apple Silicon macOS 26.3 or newer, give the exact install commands: `brew tap tcashel/juice`, `brew trust --cask tcashel/juice/juice-app`, then `brew install --cask juice-app`.
- On Linux, Windows, Intel Macs, or older macOS, say that the Juice app is not supported on this host and continue without historical claims. Do not recommend an impossible install.
- Never bypass a missing, revoked, or expired grant.

## Route the question

1. For orientation in an unfamiliar repository, call `juice_recall` with the repository path. Expand only a fresh returned topic reference that matches the task.
2. For an unfamiliar file or line range, call `juice_why` when available. If an older Juice version does not expose it, call `juice_blame`, then expand only the returned session or commit with `juice_session_explain` or `juice_commit_explain`.
3. For a repeated error, abandoned approach, or “last time” question, call `juice_search` with a narrow repository filter. Expand the strongest result with `juice_get_session`; use `juice_session_explain` when the question is about changes, commits, integration, or the captured human request.
4. For one commit, call `juice_commit_explain`. For the most recent work, call `juice_session_explain` with `selector: "last"` and a repository path.
5. Stop when the evidence answers the question or Juice reports missing or ambiguous coverage. Do not broaden to other repositories without the user's explicit scope.

Use equivalent `juice` CLI commands with `--json` when MCP is unavailable but the local CLI is connected.

## Preserve the evidence boundary

- Distinguish an explicit captured human request from correlated errors, commands, edits, tests, and commits.
- Preserve confidence, provenance tier, warnings, omissions, ambiguity, and `not captured` exactly.
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
