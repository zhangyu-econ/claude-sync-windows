#!/bin/bash
# Claude Context Sync Extended - Full sync installer (Windows-compatible)
# Usage: curl -sSL https://raw.githubusercontent.com/zhangyu-econ/claude-sync-windows/main/install-full.sh | bash -s -- REPO_URL [essential|full]

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}Claude Context Sync Extended Installer (Windows)${NC}"
echo "=================================================="

# Get arguments
GITHUB_REPO="${1:-}"
SYNC_LEVEL="${2:-essential}"

if [ -z "$GITHUB_REPO" ]; then
    echo -e "${BLUE}Enter your GitHub repository URL:${NC}"
    read -r GITHUB_REPO
fi

if [[ ! "$GITHUB_REPO" =~ ^https://github\.com/[^/]+/[^/]+(.git)?$ ]]; then
    echo -e "${RED}Invalid GitHub repository URL${NC}"
    exit 1
fi

if [[ ! "$GITHUB_REPO" =~ \.git$ ]]; then
    GITHUB_REPO="${GITHUB_REPO}.git"
fi

# Validate sync level
if [[ "$SYNC_LEVEL" != "essential" && "$SYNC_LEVEL" != "full" ]]; then
    echo -e "${YELLOW}Invalid sync level '$SYNC_LEVEL', using 'essential'${NC}"
    SYNC_LEVEL="essential"
fi

echo -e "${BLUE}Installing Claude Context Sync Extended...${NC}"
echo "Repository: $GITHUB_REPO"
echo "Sync Level: $SYNC_LEVEL"

# Detect Python command (Windows uses 'python', Linux/macOS uses 'python3')
PYTHON_CMD=""
if command -v python &>/dev/null; then
    PY_VER=$(python --version 2>&1 | grep -oP '\d+' | head -1)
    if [ "$PY_VER" = "3" ]; then
        PYTHON_CMD="python"
    fi
fi
if [ -z "$PYTHON_CMD" ] && command -v python3 &>/dev/null; then
    PYTHON_CMD="python3"
fi
if [ -z "$PYTHON_CMD" ]; then
    echo -e "${RED}Python 3 not found. Please install Python 3 first.${NC}"
    exit 1
fi
echo "Using Python: $PYTHON_CMD"

# Create directories
mkdir -p ~/.claude-code/slash-commands
mkdir -p ~/.claude-sync

# Download the extended sync script (Windows-compatible version)
echo "Downloading claude-sync-extended.py..."
curl -sSL -o ~/claude-sync-extended.py \
    https://raw.githubusercontent.com/zhangyu-econ/claude-sync-windows/main/claude-sync-extended.py

# Create enhanced slash commands
echo "Creating extended slash commands..."

# /sync-full-setup
cat > ~/.claude-code/slash-commands/sync-full-setup.md << 'EOF'
Configure Claude Context Sync Extended with full data synchronization.

```bash
if [ -z "$1" ]; then
    echo "Usage: /sync-full-setup <github-repo-url> [essential|full]"
    echo "Sync levels:"
    echo "  essential - CLAUDE.md, settings, sessions, MCP configs"
    echo "  full      - Everything including shell snapshots, slash commands"
    exit 1
fi

LEVEL="${2:-essential}"
python ~/claude-sync-extended.py setup --git-repo "$1" --level "$LEVEL"
echo "Extended sync configured!"
echo "Run /sync-status to see what will be synced"
```
EOF

# /sync-status
cat > ~/.claude-code/slash-commands/sync-status.md << 'EOF'
Show detailed Claude Context Sync status and what will be synced.

```bash
python ~/claude-sync-extended.py status
```
EOF

# /sync-pull-full
cat > ~/.claude-code/slash-commands/sync-pull-full.md << 'EOF'
Pull ALL Claude data from remote repository (sessions, settings, MCP configs).

```bash
cd ~
echo "Pulling full Claude data from remote..."
python ~/claude-sync-extended.py pull
echo "Full data sync completed!"
```
EOF

# /sync-push-full
cat > ~/.claude-code/slash-commands/sync-push-full.md << 'EOF'
Push ALL Claude data to remote repository for other PCs to access.

```bash
cd ~
echo "Pushing full Claude data to remote..."
python ~/claude-sync-extended.py push
echo "All data pushed to remote!"
```
EOF

# /sync-full
cat > ~/.claude-code/slash-commands/sync-full.md << 'EOF'
Perform complete bidirectional sync of ALL Claude data.

```bash
cd ~
echo "Performing full Claude data sync..."
python ~/claude-sync-extended.py sync
echo "Complete sync finished!"
```
EOF

# Keep the simple commands too
cat > ~/.claude-code/slash-commands/sync-pull.md << 'EOF'
Pull Claude context from remote (essential data only).

```bash
cd ~
python ~/claude-sync-extended.py pull
echo "Essential data synchronized"
```
EOF

cat > ~/.claude-code/slash-commands/sync-push.md << 'EOF'
Push Claude context to remote (essential data only).

```bash
cd ~
python ~/claude-sync-extended.py push
echo "Essential data pushed"
```
EOF

# Setup with provided repo and level
echo ""
echo -e "${BLUE}Configuring with repository and sync level...${NC}"
$PYTHON_CMD ~/claude-sync-extended.py setup --git-repo "$GITHUB_REPO" --level "$SYNC_LEVEL"

# Show status
echo ""
echo -e "${BLUE}Current sync configuration:${NC}"
$PYTHON_CMD ~/claude-sync-extended.py status

# Try initial sync
echo ""
echo -e "${BLUE}Attempting initial sync...${NC}"
if $PYTHON_CMD ~/claude-sync-extended.py push 2>/dev/null; then
    echo -e "${GREEN}Initial sync successful${NC}"
else
    echo -e "${YELLOW}Initial sync skipped (repository might be empty - run a manual push)${NC}"
fi

echo ""
echo -e "${GREEN}Claude Context Sync Extended installed!${NC}"
echo ""
echo -e "${BLUE}Available commands:${NC}"
echo "Essential sync:"
echo "  /sync-pull          - Pull context and basic settings"
echo "  /sync-push          - Push context and basic settings"
echo ""
echo "Extended sync:"
echo "  /sync-pull-full     - Pull ALL Claude data (sessions, MCP, etc.)"
echo "  /sync-push-full     - Push ALL Claude data"
echo "  /sync-full          - Complete bidirectional sync"
echo "  /sync-status        - Show detailed sync status"
echo ""
echo -e "${BLUE}What gets synced at '$SYNC_LEVEL' level:${NC}"

if [ "$SYNC_LEVEL" = "essential" ]; then
    echo "  CLAUDE.md context files"
    echo "  Claude settings (~/.claude.json)"
    echo "  Conversation sessions"
    echo "  MCP server configurations"
    echo "  Todo lists"
else
    echo "  Everything from 'essential' plus:"
    echo "  Shell integration snapshots"
    echo "  Custom slash commands"
    echo "  All user preferences"
fi

echo ""
echo -e "${BLUE}Quick start:${NC}"
echo "1. Use /sync-push-full to upload your current Claude setup"
echo "2. On other PCs, install with same repo and run /sync-pull-full"
echo "3. All your sessions, settings, and configs will be synchronized!"
