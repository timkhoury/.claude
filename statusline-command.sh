#!/bin/bash

# Read JSON input from stdin
input=$(cat)

# Extract values using jq
cwd=$(echo "$input" | jq -r '.workspace.current_dir')

# Extract session info
context_percent=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
total_cost=$(echo "$input" | jq -r '.cost.total_cost_usd // empty')

# Change to the current directory
cd "$cwd" 2>/dev/null || cd ~

# Get directory (truncated, repo-aware like Starship)
get_directory() {
    local dir="$PWD"
    local home="$HOME"

    # Replace home with ~
    dir="${dir/#$home/~}"

    # If in a git repo, show path from repo root
    if git rev-parse --show-toplevel >/dev/null 2>&1; then
        local repo_root=$(git rev-parse --show-toplevel)
        local repo_name=$(basename "$repo_root")
        local rel_path="${PWD#$repo_root}"

        if [ "$rel_path" = "" ]; then
            echo "$repo_name"
        else
            echo "$repo_name$rel_path"
        fi
    else
        # Truncate to last 3 components
        echo "$dir" | awk -F/ '{
            if (NF <= 3) print $0
            else print ".../" $(NF-1) "/" $NF
        }'
    fi
}

# Get git branch and status (like Starship)
get_git_info() {
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        return
    fi

    # Get branch name
    local branch=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)

    # Get git status indicators
    local status_output=$(git status --porcelain 2>/dev/null)
    local indicators=""

    if echo "$status_output" | grep -q "^??"; then
        indicators="${indicators}?"
    fi
    if echo "$status_output" | grep -q "^ M"; then
        indicators="${indicators}!"
    fi
    if echo "$status_output" | grep -q "^A "; then
        indicators="${indicators}+"
    fi
    if echo "$status_output" | grep -q "^D "; then
        indicators="${indicators}✘"
    fi
    if echo "$status_output" | grep -q "^R "; then
        indicators="${indicators}»"
    fi

    # Check if stashed
    if git rev-parse --verify refs/stash >/dev/null 2>&1; then
        indicators="${indicators}\$"
    fi

    # Check ahead/behind
    local ahead_behind=$(git rev-list --left-right --count @{upstream}...HEAD 2>/dev/null)
    if [ -n "$ahead_behind" ]; then
        local behind=$(echo "$ahead_behind" | cut -f1)
        local ahead=$(echo "$ahead_behind" | cut -f2)
        if [ "$ahead" -gt 0 ]; then
            indicators="${indicators}⇡"
        fi
        if [ "$behind" -gt 0 ]; then
            indicators="${indicators}⇣"
        fi
    fi

    printf " on  %s" "$branch"
    if [ -n "$indicators" ]; then
        printf " [%s]" "$indicators"
    fi
}

# Detect language/tool context (like Starship)
get_context() {
    local context=""

    # Node.js
    if [ -f "package.json" ]; then
        local node_version=$(node --version 2>/dev/null | sed 's/v//')
        if [ -n "$node_version" ]; then
            context="${context} via  ${node_version}"
        fi
    fi

    # Python
    if [ -f "requirements.txt" ] || [ -f "pyproject.toml" ] || [ -f "setup.py" ]; then
        local python_version=$(python3 --version 2>/dev/null | awk '{print $2}')
        if [ -n "$python_version" ]; then
            context="${context} via 🐍 ${python_version}"
        fi
    fi

    # Java
    if [ -f "pom.xml" ] || [ -f "build.gradle" ] || [ -f "build.gradle.kts" ]; then
        local java_version=$(java -version 2>&1 | head -n 1 | awk -F'"' '{print $2}')
        if [ -n "$java_version" ]; then
            context="${context} via ☕ ${java_version}"
        fi
    fi

    # Ruby
    if [ -f "Gemfile" ]; then
        local ruby_version=$(ruby --version 2>/dev/null | awk '{print $2}')
        if [ -n "$ruby_version" ]; then
            context="${context} via 💎 ${ruby_version}"
        fi
    fi

    # Go
    if [ -f "go.mod" ]; then
        local go_version=$(go version 2>/dev/null | awk '{print $3}' | sed 's/go//')
        if [ -n "$go_version" ]; then
            context="${context} via 🐹 ${go_version}"
        fi
    fi

    # Rust
    if [ -f "Cargo.toml" ]; then
        local rust_version=$(rustc --version 2>/dev/null | awk '{print $2}')
        if [ -n "$rust_version" ]; then
            context="${context} via 🦀 ${rust_version}"
        fi
    fi

    echo "$context"
}

# Get session info (context usage and cost)
get_session_info() {
    local info=""

    # Context window usage percentage
    if [ -n "$context_percent" ]; then
        info="ctx:${context_percent}%"
    fi

    # Total cost
    if [ -n "$total_cost" ]; then
        local cost_formatted=$(printf "%.2f" "$total_cost")
        if [ -n "$info" ]; then
            info="${info} | \$${cost_formatted}"
        else
            info="\$${cost_formatted}"
        fi
    fi

    if [ -n "$info" ]; then
        printf " [%s]" "$info"
    fi
}

# Build the status line
dir=$(get_directory)
session_info=$(get_session_info)

# Output the status line
printf "%s%s" "$dir" "$session_info"
