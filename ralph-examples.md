# Ralph Loop Examples

## Basic Usage
```bash
./ralph-loop.sh "Write a Python function that calculates factorial"
```

## Swapping AI Tools

The script is designed to work with any AI command-line tool that reads prompts from stdin and outputs to stdout.

### Example 1: Claude Code
```bash
# Edit the AI_COMMAND variable in the script:
AI_COMMAND="claude-code"
```

### Example 2: Gemini CLI
```bash
AI_COMMAND="gemini-cli --temperature 0.7"
```

### Example 3: Vibe
```bash
AI_COMMAND="vibe --model gpt-4"
```

### Example 4: OpenAI API via curl
You may need to write a wrapper script:
```bash
#!/bin/bash
# openai-wrapper.sh
API_KEY="your-key"
prompt=$(cat)
curl -s https://api.openai.com/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $API_KEY" \
  -d "{
    \"model\": \"gpt-4\",
    \"messages\": [{\"role\": \"user\", \"content\": \"$prompt\"}],
    \"temperature\": 0.7
  }" | jq -r '.choices[0].message.content'
```
Then set:
```bash
AI_COMMAND="./openai-wrapper.sh"
```

## Custom Verification Commands

The verification command runs after each AI attempt to capture the current state.

### Example: Node.js project
```bash
VERIFICATION_COMMAND="npm test 2>&1 || echo 'Tests failed'"
```

### Example: C++ build
```bash
VERIFICATION_COMMAND="make clean && make 2>&1 || echo 'Build failed'"
```

### Example: File system check
```bash
VERIFICATION_COMMAND="ls -la project/ && cat project/output.log 2>/dev/null || echo 'No output'"
```

## Setting Promise String

The promise string is what the AI must output to indicate success.

### Example: Specific success indicator
```bash
PROMISE_STRING="ALL_TESTS_PASS"
```

### Example: JSON output
```bash
PROMISE_STRING='"status": "success"'
```

## Environment Variables Override

You can override configuration via environment variables:
```bash
export AI_COMMAND="gemini-cli"
export MAX_LOOPS=50
export PROMISE_STRING="SUCCESS"
export RALPH_VERIFICATION_COMMAND="npm test"
./ralph-loop.sh "Your task"
```

## Advanced: Dynamic Verification Command

For complex workflows, you can write a separate verification script:
```bash
#!/bin/bash
# verify.sh
# Run tests, capture output, return status
if npm test > test_output.txt 2>&1; then
  echo "TASK_SUCCESS"
  cat test_output.txt
else
  cat test_output.txt
fi
```
Then set:
```bash
VERIFICATION_COMMAND="./verify.sh"
```

## Troubleshooting

### AI command not found
Ensure the AI tool is in your PATH or use the full path.

### AI tool requires different input method
Modify the `run_ai()` function in the script to match your tool's API.

### Verification command fails
Test the verification command outside the script first. Use `bash -x` for debugging.

### Output file grows too large
Adjust the verification command to capture only relevant output, or add cleanup steps.