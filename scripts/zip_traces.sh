#!/bin/bash

cd "$(dirname "$0")/.."

find . -mindepth 2 -maxdepth 2 -type d | while read -r dir; do
	echo "Processing $dir"
	(
		cd "$dir"
		zip -r pfuzzer_output.zip . -x 'notes.txt'
		find . -type f ! -name 'pfuzzer_output.zip' ! -name 'notes.txt' -delete
	)
done
