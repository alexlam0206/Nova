# Agent Index

This file is the central index/dispatcher for local agent prompt files. Use this file to find and redirect the AI agent to a specific prompt.

How to use
- Open the `AGENTS/` folder and choose an agent prompt file (e.g. `BasicSystemPrompt.md`).
- To temporarily instruct the AI to use a particular agent prompt, copy the desired file's contents into the conversation or reference the file by path.

Available prompts (converted):

- [README](AGENTS/README.md)
- [BasicSystemPrompt](AGENTS/BasicSystemPrompt.md)
- [ReasoningSystemPrompt](AGENTS/ReasoningSystemPrompt.md)
- [VariantASystemPrompt](AGENTS/VariantASystemPrompt.md)
- [VariantBSystemPrompt](AGENTS/VariantBSystemPrompt.md)

(Other `.idechatprompttemplate` files from `xcode-26-system-prompts` are available in the cloned repo at `xcode-26-system-prompts/` if you prefer to inspect originals.)

Redirecting the AI agent
- The simplest manual workflow is to paste the contents of any `Agents/*.md` file into the AI system prompt or your agent configuration.
- If you use a local agent framework that supports an include or pointer file, you can point it to `Agents/<filename>.md`.

If you want, I can now:
- convert every `.idechatprompttemplate` file into `AGENTS/*.md` (I started with a few core prompts),
- add a small script to keep `AGENTS/` in sync with the cloned repo,
- or remove the cloned copy and keep only the `AGENTS/` folder inside this workspace.
