# BrainiacPlus Copilot Instructions

Apply these rules for every prompt in this repository.

## Always-On Context
- Read and follow `.github/agents/AI_VISION.md` as the primary project vision and constraints.
- Prefer multi-agent routing: pick the correct domain agent before proposing edits.
- Stay within the allowed domain paths for the selected agent.

## Prompt Contract (for every chat prompt)
- Summarize the request in 1 line and confirm AI_VISION alignment.
- Select the domain agent and list allowed paths before editing.
- If a change affects multiple domains, split tasks or ask for approval.

## Output Expectations
- Provide concise, production-ready guidance and code changes only when requested.
- Keep responses short and structured; avoid unnecessary verbosity.
- When suggesting code changes, include file paths and minimal diffs.

## Safety and Scope
- Do not propose edits to build outputs or generated files.
- Do not touch `pubspec.yaml` or `lib/main.dart` unless explicitly requested.
- If a request is ambiguous, ask for clarification before editing.

## Prompt Handling
- Treat the user message as the source of truth and combine it with AI_VISION.
- If the request conflicts with AI_VISION constraints, explain the conflict and suggest alternatives.