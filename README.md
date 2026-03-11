# Ralph

A minimal Bash script for autonomous agentic coding using a "brute-force persistence loop" that repeatedly asks an AI to pick the next most important piece of work until the task is done.

_There are many Ralph loop implementations. This is no better than the others, but it's mine. I wrote it, I can understand it, and I can enhance it._

## Features

- **Generic AI Integration**: Works with any CLI tool (pi, claude, gemini, vibe, or custom wrappers).
- **Stateless Iterations**: Each iteration is independent — the AI receives the task fresh and picks the next most important piece of work.
- **Simple Configuration**: Just two optional arguments — no environment variables or complex options.

## Quick Start

```bash
# Basic usage with default AI command (pi)
./ralph.sh "Write a factorial function in Python"

# Specify a different AI command
./ralph.sh "Fix tests" "gemini"
```

## Installation

Just put the ralph.sh file to the root directory of the project and tweak it to your liking.

## Configuration

Edit the defaults at the top of the script if you need to change:
- `AI_COMMAND`: default AI command (default: `pi`)
- `MAX_LOOPS`: maximum iterations before giving up (default: `20`)

Example:
```bash
# Edit ralph.sh and change these lines:
AI_COMMAND="claude"
MAX_LOOPS=50
```

## Usage

```text
Usage: ./ralph.sh <task> [ai-command]

Arguments:
  task       The task description for the AI (required)
  ai-command AI command to run (default: pi)

The AI command must read a prompt from stdin and output to stdout. Note: `gemini` is handled specially and receives the prompt via `-y -p` flags (non-interactive mode).
```

## How It Works

1. **Wrap the task**: Ralph appends a small footer to your task asking the AI to end every response with either `RALPH_CONTINUE` (more work remains) or `RALPH_DONE` (fully complete). Your task prompt needs no magic strings.
2. **Pick one piece of work**: Each iteration the AI is asked to pick the next or single most important piece of work and implement it.
3. **Check for done**: If the AI responds with `RALPH_DONE`, Ralph exits successfully.
4. **Iterate**: Otherwise, Ralph loops and asks again — each iteration starts fresh with just the original task.
5. **Finalize**: Strips the internal tokens from the final output and exits.

## Troubleshooting

- **AI output polluted**: The script sends all logs to `stderr`, so your AI tool's output should be clean on `stdout`.
- **Command not found**: Ensure your tool is in the PATH or use an absolute path.
- **Max loops reached**: Increase `MAX_LOOPS` in the script.

## License

MIT
