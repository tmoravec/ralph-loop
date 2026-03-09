#!/usr/bin/env bash
# Test custom verification command

set -e

MOCK_AI="/tmp/mock_verify.sh"
cat > "$MOCK_AI" << 'EOF'
#!/bin/bash
echo "AI attempt"
if [ -f /tmp/testfile ]; then
    echo "Found file"
    echo "TASK_SUCCESS"
else
    echo "No file yet"
fi
EOF
chmod +x "$MOCK_AI"

echo "=== Testing custom verification command ==="
./ralph.sh "Create file" "$MOCK_AI" "touch /tmp/testfile && echo 'File created'"

rm -f "$MOCK_AI" /tmp/testfile
echo "=== Done ==="