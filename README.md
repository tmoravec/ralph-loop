# Ralph

A minimal Bash script for autonomous agentic coding using a "brute-force persistence loop" that feeds an AI its own previous errors until it achieves success.

_There are many Ralph loop implementations. This is no better than the others, but it's mine. I wrote it, I can understand it, and I can enhance it._

## Features

- **Generic AI Integration**: Works with any CLI tool (pi, claude-code, gemini, vibe, or custom wrappers).
- **State Capture**: Runs a verification command after each attempt to capture the latest errors or state.
- **Simple Configuration**: Just three optional arguments—no environment variables or complex options.

## Quick Start

```bash
# Basic usage with default AI command (pi)
./ralph.sh "Write a factorial function in Python"

# Specify a different AI command
./ralph.sh "Fix tests" "gemini"

# Specify AI command and verification command
./ralph.sh "Fix build" "claude-code" "make clean && make"
```

## Installation

Just put the ralph.sh file to the root directory of the project and tweak it to your liking.

## Configuration

Edit the defaults at the top of the script if you need to change:
- `AI_COMMAND`: default AI command (default: `pi`)
- `MAX_LOOPS`: maximum iterations before giving up (default: `20`)
- `PROMISE_STRING`: success indicator string (default: `TASK_SUCCESS`)
- `VERIFY_COMMAND`: default verification command (default: `cat "$OUTPUT_FILE"`)

Example:
```bash
# Edit ralph.sh and change these lines:
AI_COMMAND="claude-code"
MAX_LOOPS=50
PROMISE_STRING="SUCCESS"
```

## Usage

```text
Usage: ./ralph.sh <task> [ai-command] [verify-command]

Arguments:
  task           The task description for the AI (required)
  ai-command     AI command to run (default: pi)
  verify-command Command to capture state after each iteration (default: cat "$OUTPUT_FILE")

The AI command must read a prompt from stdin and output to stdout.
The verification command can reference $OUTPUT_FILE (the temporary output file).
```

## How It Works

1. **Capture State**: Runs the verification command to get initial context.
2. **Consult AI**: Sends the task and current state to the AI tool.
3. **Verify Success**: Checks the AI response for the `PROMISE_STRING` ("TASK_SUCCESS").
4. **Iterate**: If not found, appends the AI's response to the state, runs the verification command again, and loops.
5. **Finalize**: Cleans up temporary state files and exits with success or failure.

## Troubleshooting

- **AI output polluted**: The script sends all logs to `stderr`, so your AI tool's output should be clean on `stdout`.
- **Command not found**: Ensure your tool is in the PATH or use an absolute path.
- **Max loops reached**: Increase `MAX_LOOPS` in the script or improve your verification command to provide better feedback.

## License

MIT