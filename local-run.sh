#!/bin/bash

# Check for python-is-python3 installed
if ! command -v python &>/dev/null; then
	echo "It appears you do not have python-is-python3 installed"
	exit 1
fi

# Check for zola being installed
if ! command -v zola &>/dev/null; then
	echo "zola could not be found please install it from https://www.getzola.org/documentation/getting-started/installation"
	exit 1
fi

# Check for correct slugify package
PYTHON_ERROR=$(eval "python -c 'from slugify import slugify; print(slugify(\"Test String One\"))'" 2>&1)

if [[ $PYTHON_ERROR != "test-string-one" ]]; then
	if [[ $PYTHON_ERROR =~ "NameError" ]]; then
		echo "It appears you have the wrong version of slugify installed, the required pip package is python-slugify"
	else
		echo "It appears you do not have slugify installed. Install it with 'pip install python-slugify'"
	fi
	exit 1
fi

# Check for rtoml package
PYTHON_ERROR=$(eval "python -c 'import rtoml'" 2>&1)

if [[ $PYTHON_ERROR =~ "ModuleNotFoundError" ]]; then
	echo "It appears you do not have rtoml installed. Install it with 'pip install rtoml'"
	exit 1
fi
#handle tilde expansion without eval
expand_tilde() {
	tilde_less="${1#\~/}"
	[ "$1" != "$tilde_less" ] && tilde_less="$HOME/$tilde_less"
	printf '%s' "$tilde_less"
}
# Check that the vault got set
if [[ -z "${VAULT}" ]]; then
	if [[ -f ".vault_path" ]]; then
		export VAULT=$(expand_tilde $(cat .vault_path))
	else
		echo "Path to the obsidian vault is not set, please set the path using in the $(.vault_path) file or $VAULT env variable"
		exit 1
	fi
fi

# Pull environment variables from the vault's netlify.toml when building (by generating env.sh to be sourced)
python env.py
source env.sh
# Set the site and repo url as local since locally built
export SITE_URL=local
export REPO_URL=local

# Remove previous build and sync Zola template contents
rm -rf build
rsync -a zola/ build
rsync -a content/ build/content
echo yeet
# Use obsidian-export to export markdown content from obsidian
mkdir -p build/content/docs build/__docs
export_args=()
if [ -z "$STRICT_LINE_BREAKS" ] || [[ $STRICT_LINE_BREAKS == @("y"| "yes" | "true" | "1") ]]; then
	export_args+=(--hard-linebreaks)
fi
if [ ! -z "$SUBDIR_START" ]; then
	echo $SUBDIR_START
	export_args+=(--start-at $SUBDIR_START)
fi

#redirect obsidian-export output to /dev/null to avoid printing the entire vault contents
bin/obsidian-export --frontmatter=never "${export_args[@]}" --no-recursive-embeds $VAULT build/__docs #>/dev/null 2>&1

# Run conversion script
source env.sh && python convert.py && rm env.sh

# Serve Zola site
zola --root=build serve >/dev/null 2>&1
