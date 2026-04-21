# ~/nixos-config/kb/tools/ingest-pdf.sh
#!/usr/bin/env bash
set -euo pipefail

PDF="$1"
OUT_DIR="/kb/processed"
mkdir -p "$OUT_DIR"

# Extract text (tries native first, OCR if needed)
pdftotext "$PDF" - 2>/dev/null || tesseract <(pdftoppm -png "$PDF") - > "${OUT_DIR}/$(basename "$PDF" .pdf).txt"

echo "Processed: $PDF → ${OUT_DIR}/$(basename "$PDF" .pdf).txt"
