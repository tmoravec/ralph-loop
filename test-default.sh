#!/usr/bin/env bash
# Test default verification command

set -e

MOCK_AI="/tmp/mock_default.sh"
cat > "$MOCK_AI" << 'EOF'
#!/bin/bash
echo "AI attempt"
echo "TASK_SUCCESS"
EOF
chmod +x "$MOCK_AI"

echo "=== Testing default verification command ==="
./ralph-loop.sh "Task" "$MOCK_AI"

rm -f "$MOCK_AI"
echo "=== Done ==="