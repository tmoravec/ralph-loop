#!/usr/bin/env bash
# Test custom verification command and state passing

set -e

MOCK_AI=$(mktemp /tmp/mock_verify_XXXXXX.sh)
TEST_FILE=$(mktemp /tmp/testfile_XXXXXX)
# Ensure cleanup on exit
trap 'rm -f "$MOCK_AI" "$TEST_FILE"' EXIT

# Mock AI that only succeeds if it sees specific text in the prompt 
# that comes from the verification command
cat > "$MOCK_AI" << EOF
#!/bin/bash
PROMPT=\$(cat)
if echo "\$PROMPT" | grep -q "VERIFICATION_SIGNAL_RECEIVED"; then
    echo "TASK_SUCCESS"
else
    echo "No signal found in prompt"
fi
EOF
chmod +x "$MOCK_AI"

echo "=== Testing custom verification command & state passing ==="
# We use a verification command that outputs a signal.
# On the first "initial capture", it will output it.
# Then Loop 1 will see it in the prompt and succeed.
OUTPUT=$(./ralph.sh "Check for signal" "$MOCK_AI" "echo 'VERIFICATION_SIGNAL_RECEIVED'" 2>&1)

if echo "$OUTPUT" | grep -q "Task completed in iteration 1"; then
    echo "[PASS] Custom verification output was correctly passed to AI."
else
    echo "[FAIL] Verification signal not detected by AI or loop failed."
    echo "Output:"
    echo "$OUTPUT"
    exit 1
fi

echo "=== Test complete ==="
