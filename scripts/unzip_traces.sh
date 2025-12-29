#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")/.."

find . type f -name 'pfuzzer_output.zip' -print0 \
| while IFS= read -r -d '' ZIPFILE; do
	DIR="$(dirname "$ZIPFILE")"
	echo "Restoring in: $DIR"
	unzip -o "$ZIPFILE" -d "$DIR"
done
