# Ralph Loop

A robust, generic Bash script for autonomous agentic coding using a "brute-force persistence loop" that feeds an AI its own previous errors until it achieves success.

## Features

- **Generic AI Integration**: Works with any CLI tool (claude-code, gemini-cli, vibe, or custom wrappers).
- **State Capture**: Runs a verification command after each attempt to capture the latest errors or state.
- **Robustness**: Handles file truncation issues and provides clean state management.
- **Prompt Templating**: Customize exactly how the task and state are presented to the AI.
- **Flexible Options**: Override everything via environment variables or command-line arguments.
- **Color Logging**: Clear, readable output with informational tags sent to stderr.

## Installation

```bash
curl -o ralph-loop.sh https://raw.githubusercontent.com/yourusername/ralph/main/ralph-loop.sh
chmod +x ralph-loop.sh
```

## Quick Start

```bash
# Basic usage
./ralph-loop.sh "Write a factorial function in Python"

# With flags
./ralph-loop.sh "Fix tests" --ai-command "gemini-cli" --max-loops 10

# With verification command
./ralph-loop.sh "Fix build" --verify "make clean && make"
```

## Usage

```text
Usage: ./ralph-loop.sh [options] [task]

Options:
  -a, --ai-command <cmd>      AI command to run (default: claude-code)
  -m, --max-loops <num>       Maximum iterations (default: 20)
  -p, --promise <string>      String to signal success (default: TASK_SUCCESS)
  -v, --verbose <level>       Verbosity level 0-2 (default: 1)
  -c, --verify <cmd>          Verification command (default: cat "$OUTPUT_FILE")
  -h, --help                  Show help
```

## Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `AI_COMMAND` | AI tool to use | `claude-code` |
| `MAX_LOOPS` | Max iterations | `20` |
| `PROMISE_STRING` | Success indicator | `TASK_SUCCESS` |
| `RALPH_VERIFICATION_COMMAND` | State capture command | `cat "$OUTPUT_FILE"` |
| `RALPH_PROMPT_TEMPLATE` | Custom prompt structure | See script |
| `VERBOSE` | Logging level | `1` |

### Prompt Templates
Use `{TASK}`, `{STATE}`, and `{PROMISE}` as placeholders:
```bash
export RALPH_PROMPT_TEMPLATE="Task: {TASK}\nState: {STATE}\nSuccess if: {PROMISE}"
```

## How It Works

1. **Capture State**: Runs the verification command to get initial context.
2. **Consult AI**: Sends the task and current state to the AI tool.
3. **Verify Success**: Checks the AI response for the `PROMISE_STRING`.
4. **Iterate**: If not found, appends the AI's response to the state, runs the verification command again, and loops.
5. **Finalize**: Cleans up temporary state files and exits with success or failure.

## Troubleshooting

- **AI output polluted**: The script sends all logs to `stderr`, so your AI tool's output should be clean on `stdout`.
- **Command not found**: Ensure your tool is in the PATH or use an absolute path.
- **Max loops reached**: Increase `--max-loops` or improve your verification command to provide better feedback.

## License

MIT