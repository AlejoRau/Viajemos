#!/bin/bash
# Flutter/Dart type checking hook for Claude Code
# Runs dart analyze after every file edit to catch type errors

# Read JSON input from stdin
INPUT=$(cat)

# Extract the file path
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Only run on Dart files
if [[ "$FILE_PATH" != *.dart ]]; then
  exit 0
fi

# Find the project root (where pubspec.yaml lives)
PROJECT_ROOT="$PWD"
while [[ "$PROJECT_ROOT" != "/" ]]; do
  if [[ -f "$PROJECT_ROOT/pubspec.yaml" ]]; then
    break
  fi
  PROJECT_ROOT=$(dirname "$PROJECT_ROOT")
done

if [[ ! -f "$PROJECT_ROOT/pubspec.yaml" ]]; then
  echo "Could not find Flutter project root (pubspec.yaml)" >&2
  exit 0
fi

# Run dart analyze
ANALYZE_OUTPUT=$(cd "$PROJECT_ROOT" && dart analyze --no-congratulate 2>&1)
EXIT_CODE=$?

if [[ $EXIT_CODE -ne 0 ]]; then
  # Feed errors back to Claude via stderr (exit code 2 = blocking, Claude sees the message)
  echo "dart analyze found errors after editing $FILE_PATH:" >&2
  echo "" >&2
  echo "$ANALYZE_OUTPUT" >&2
  echo "" >&2
  echo "Please fix all type errors and analysis issues in the affected files." >&2
  exit 2
fi

exit 0