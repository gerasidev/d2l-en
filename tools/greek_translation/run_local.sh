#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 /path/to/english-d2l-repo /path/to/greek-output-repo" >&2
  exit 2
fi

SOURCE_ROOT="$(realpath "$1")"
OUTPUT_ROOT="$(realpath "$2")"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

if [[ -f "$SCRIPT_DIR/translate_book.py" ]]; then
  cp "$SCRIPT_DIR/translate_book.py" "$TMP_DIR/translate_book.py"
else
  cat "$SCRIPT_DIR"/bootstrap/translate_book.py.b64.* | base64 --decode > "$TMP_DIR/translate_book.py"
fi

if [[ -f "$SCRIPT_DIR/validate_translation.py" ]]; then
  cp "$SCRIPT_DIR/validate_translation.py" "$TMP_DIR/validate_translation.py"
else
  cat "$SCRIPT_DIR"/bootstrap/validate_translation.py.b64.* | base64 --decode > "$TMP_DIR/validate_translation.py"
fi

python "$TMP_DIR/translate_book.py" \
  --root "$SOURCE_ROOT" \
  --output-dir "$OUTPUT_ROOT" \
  --terms "$SCRIPT_DIR/terms.txt"

cp "$TMP_DIR/translate_book.py" "$OUTPUT_ROOT/tools/greek_translation/translate_book.py"
cp "$TMP_DIR/validate_translation.py" "$OUTPUT_ROOT/tools/greek_translation/validate_translation.py"

PYTHONPATH="$OUTPUT_ROOT/tools/greek_translation" \
python "$OUTPUT_ROOT/tools/greek_translation/validate_translation.py" \
  --source-root "$SOURCE_ROOT" \
  --translated-root "$OUTPUT_ROOT"

echo "Greek first pass completed and validated in: $OUTPUT_ROOT"
