# Rules for all coding agents

## How to talk to me
- Keep answers short. Don't write text I won't read.
- Use simple English. No fancy words, no long intros, no summaries of what you just did.
- Keep solutions simple. Only add complexity when it's really needed, and say why in one line.
- Don't repeat my question back to me or list every step you took.
- When you finish a task, tell me in 1-3 lines: what changed and anything I need to do.
- If you're not sure what I want, ask one short question before starting big work.
- When I ask you to teach me something: explain why it's needed, then how to use it, then a small example I can run. One concept at a time.

## Environment
- OS: Omarchy (Arch Linux based). Use pacman or yay for packages. Never suggest apt or brew.
- Respect Omarchy's setup. Don't overwrite its default configs; ask before changing anything in ~/.config.
- Don't run sudo or change files outside the project without asking me.

## How to work
- Read the relevant files before editing. Don't guess how code works.
- Make the smallest change that solves the problem. Don't touch unrelated code.
- Don't create extra files (docs, READMEs, notes) unless I ask.
- Don't add new dependencies without asking.
- After changes, run the build/tests and tell me the real result. Never say it works if you didn't check.
- If something fails twice, stop and tell me what's wrong instead of trying random fixes.

## Code style
- Write simple, readable code over clever code.
- Follow the style already used in the project.
- Comments only where the code isn't obvious.
