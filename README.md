# Ralph

A minimal Bash script for autonomous agentic coding using a "brute-force persistence loop" that feeds an AI its own previous errors until it achieves success.

_There are many Ralph loop implementations. This is no better than the others, but it's mine. I wrote it, I can understand it, and I can enhance it._

## Features

- **Generic AI Integration**: Works with any CLI tool (pi, claude, gemini, vibe, or custom wrappers).
- **State Capture**: Runs a verification command after each attempt to capture the latest errors or state.
- **Simple Configuration**: Just three optional arguments—no environment variables or complex options.

## Quick Start

```bash
# Basic usage with default AI command (pi)
./ralph.sh "Write a factorial function in Python"

# Specify a different AI command
./ralph.sh "Fix tests" "gemini"

# Specify AI command and verification command
./ralph.sh "Fix build" "claude" "make clean && make"
```

## Installation

Just put the ralph.sh file to the root directory of the project and tweak it to your liking.

## Configuration

Edit the defaults at the top of the script if you need to change:
- `AI_COMMAND`: default AI command (default: `pi`)
- `MAX_LOOPS`: maximum iterations before giving up (default: `20`)
- `VERIFY_COMMAND`: default verification command (default: `cat "$OUTPUT_FILE"`)

Example:
```bash
# Edit ralph.sh and change these lines:
AI_COMMAND="claude"
MAX_LOOPS=50
```

## Usage

```text
Usage: ./ralph.sh <task> [ai-command] [verify-command]

Arguments:
  task           The task description for the AI (required)
  ai-command     AI command to run (default: pi)
  verify-command Command to capture state after each iteration (default: cat "$OUTPUT_FILE")

The AI command must read a prompt from stdin and output to stdout. Note: `gemini` is handled specially and receives the prompt via `-y -p` flags (non-interactive mode).
The verification command can reference $OUTPUT_FILE (the temporary output file).
```

## How It Works

1. **Wrap the task**: Ralph appends a small universal footer to your task prompt asking the AI to end every response with either `RALPH_CONTINUE` (more work remains) or `RALPH_DONE` (fully complete). Your task prompt needs no magic strings.
2. **Consult AI**: Sends the wrapped prompt and the previous iteration's output to the AI tool.
3. **Verify success**: Checks that the AI responded with `RALPH_DONE` **and** that the verification command exits 0. Both must be true.
4. **Iterate**: If either condition fails, stores the AI response + verification output as state for the next iteration and loops.
5. **Finalize**: Strips the internal tokens from the final output, cleans up temp files, and exits.

## Troubleshooting

- **AI output polluted**: The script sends all logs to `stderr`, so your AI tool's output should be clean on `stdout`.
- **Command not found**: Ensure your tool is in the PATH or use an absolute path.
- **Max loops reached**: Increase `MAX_LOOPS` in the script or improve your verification command to provide better feedback.

## License

MIT