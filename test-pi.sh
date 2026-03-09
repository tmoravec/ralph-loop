#!/usr/bin/env bash
# Test with pi command (if installed) or mock

if command -v pi >/dev/null 2>&1; then
    echo "pi is installed, running actual test (may take a moment)..."
    ./ralph-loop.sh "Write 'Hello, World!' in Python"
else
    echo "pi not installed, using mock..."
    MOCK_PI="/tmp/mock_pi.sh"
    cat > "$MOCK_PI" << 'EOF'
#!/bin/bash
cat
echo "print('Hello, World!')"
echo "TASK_SUCCESS"
EOF
    chmod +x "$MOCK_PI"
    ./ralph-loop.sh "Write 'Hello, World!' in Python" "$MOCK_PI"
    rm "$MOCK_PI"
fi