#!/bin/bash

pip install -r __site/requirements.txt

# Avoid copying over netlify.toml (will ebe exposed to public API)
echo "netlify.toml" >>__obsidian/.gitignore

# Sync Zola template contents
rsync -a __site/zola/ __site/build
rsync -a __site/content/ __site/build/content

export_args=()
if [ -z "$STRICT_LINE_BREAKS" ] || [[ $STRICT_LINE_BREAKS == @("y"| "yes" | "true" | "1") ]]; then
	export_args+=(--hard-linebreaks)
fi
if [ ! -z "$SUBDIR_START" ]; then
	echo $SUBDIR_START
	export_args+=(--start-at $SUBDIR_START)
fi

# Use obsidian-export to export markdown content from obsidian
mkdir -p __site/build/content/docs __site/build/__docs

__site/bin/obsidian-export "${export_args[@]}" --no-recursive-embeds __obsidian __site/build/__docs

# Run conversion script
python __site/convert.py

# Build Zola site
zola --root __site/build build --output-dir public
