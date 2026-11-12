# not really needed since I'm not installing additional scripts
#!/bin/bash

create_symlinks() {
    # Get the directory in which this script lives.
    script_dir=$(dirname "$(readlink -f "$0")")

    # Get a list of all files in this directory that start with a dot.
    files=$(find -maxdepth 1 -type f -name ".*")

    # Create a symbolic link to each file in the home directory.
    for file in $files; do
        name=$(basename $file)
        echo "Creating symlink to $name in home directory."
        rm -rf ~/$name
        ln -s $script_dir/$name ~/$name
    done
}

link_claude_config() {
    script_dir=$(dirname "$(readlink -f "$0")")

    mkdir -p ~/.claude/skills
    for skill in "$script_dir"/claude/skills/*/; do
        [ -d "$skill" ] || continue
        name=$(basename -- "$skill")
        echo "Linking Claude skill $name."
        rm -rf ~/.claude/skills/"$name"
        ln -s "${skill%/}" ~/.claude/skills/"$name"
    done

    # Each directory under claude/memory is named after a Claude project
    # (the workspace path with / replaced by -), e.g. -workspaces-obsidian.
    for project in "$script_dir"/claude/memory/*/; do
        [ -d "$project" ] || continue
        name=$(basename -- "$project")
        target=~/.claude/projects/"$name"/memory
        mkdir -p ~/.claude/projects/"$name"
        # Keep memories a session wrote before this ran; the repo's copy wins on conflict.
        if [ -d "$target" ] && [ ! -L "$target" ]; then
            cp -r --update=none "$target"/. "${project%/}"/
            rm -rf "$target"
        fi
        rm -f "$target"
        echo "Linking Claude memory for $name."
        ln -s "${project%/}" "$target"
    done
}

create_symlinks
link_claude_config
