# Mac Setup Guide for Clepsy Development

> **Goal**: Transfer all Clepsy project files from Windows to Mac and set up development environment

---

## Phase 1: Transfer Project Files

### What to Transfer

You need to copy the **entire Clepsy project folder** from Windows to Mac:

```
Clepsy/
├── docs/
│   ├── plans/
│   │   └── 2026-01-31-clepsy-mvp.md          ← Implementation plan
│   ├── data-architecture.md                   ← Architecture reference
│   ├── clepsy_prd.md                          ← Product requirements
│   ├── clepsy_mvb.md                          ← Brand guidelines
│   ├── dashboard_specs.md                     ← Dashboard specs
│   ├── onboarding_specs.md                    ← Onboarding specs
│   ├── earning_specs.md                       ← Earning mechanics
│   ├── settings_specs.md                      ← Settings specs
│   ├── Error State specs.md                   ← Error handling
│   └── clepsy_mascot_asset_guide.md          ← Asset guidelines
└── (Xcode project will be created on Mac)
```

### Transfer Methods (Choose One)

#### **Option A: Cloud Storage** (Recommended - Easiest)

1. **On Windows**:
   ```bash
   # Zip the entire Clepsy folder
   cd C:\Users\josue\Documents\Builds
   # Right-click Clepsy folder → Send to → Compressed (zipped) folder
   ```

2. Upload `Clepsy.zip` to:
   - **Google Drive** (recommended)
   - **Dropbox**
   - **iCloud Drive**
   - **OneDrive**

3. **On Mac**:
   - Download `Clepsy.zip`
   - Double-click to extract
   - Move to `~/Documents/Builds/Clepsy`

#### **Option B: USB Drive** (Fast, No Internet)

1. **On Windows**:
   - Copy entire `Clepsy` folder to USB drive

2. **On Mac**:
   - Plug in USB drive
   - Copy `Clepsy` folder to `~/Documents/Builds/Clepsy`

#### **Option C: Git Repository** (Best for Version Control)

1. **On Windows** (if you haven't already):
   ```bash
   cd C:\Users\josue\Documents\Builds\Clepsy
   git init
   git add .
   git commit -m "Initial commit: Clepsy documentation and specs"
   ```

2. Push to GitHub:
   ```bash
   # Create new repo at github.com/yourusername/clepsy
   git remote add origin https://github.com/yourusername/clepsy.git
   git branch -M main
   git push -u origin main
   ```

3. **On Mac**:
   ```bash
   cd ~/Documents/Builds
   git clone https://github.com/yourusername/clepsy.git
   cd clepsy
   ```

---

## Phase 2: Mac Development Environment Setup

### Step 1: Install Xcode

1. **Open App Store** on Mac
2. Search for **"Xcode"**
3. Click **"Get"** (it's free, but ~15 GB download)
4. Wait for installation (~30-60 minutes depending on internet speed)

5. **After installation**:
   ```bash
   # Open Terminal and run:
   sudo xcode-select --install
   ```

6. **Accept Xcode license**:
   ```bash
   sudo xcodebuild -license accept
   ```

7. **Verify installation**:
   ```bash
   xcodebuild -version
   # Should show: Xcode 15.x or later
   ```

### Step 2: Install Homebrew (Package Manager)

```bash
# Open Terminal and run:
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Follow the instructions to add Homebrew to PATH
# Usually involves running these commands:
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"

# Verify installation:
brew --version
```

### Step 3: Install Git

```bash
brew install git

# Configure git:
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# Verify:
git --version
```

### Step 4: Install Claude Code CLI

```bash
# Install Claude Code
brew install anthropics/claude/claude-code

# Verify installation:
claude --version

# Login to Claude:
claude login
# This will open a browser to authenticate with your Anthropic account
```

---

## Phase 3: Install Claude Code Skills

Claude Code skills are stored in `~/.claude/skills/`. You need to install the skills that were available in your Windows session.

### Available Skills (from your Windows session):

1. **keybindings-help** - Customize keyboard shortcuts
2. **find-skills** - Discover and install agent skills
3. **frontend-design** - Create production-grade frontend interfaces
4. **swiftui-animation** - SwiftUI animations and transitions
5. **swiftui-expert-skill** - SwiftUI best practices
6. **writing-plans** - Create implementation plans (we used this!)

### Install Skills on Mac

```bash
# Create skills directory if it doesn't exist
mkdir -p ~/.claude/skills

# Option A: Install skills via Claude Code
# In your terminal, start Claude Code:
claude

# Then in Claude Code, ask:
# "Install the following skills: frontend-design, swiftui-expert-skill, swiftui-animation, writing-plans"

# Option B: If skills aren't available via find-skills, they'll be auto-available
# when you use Claude Code (built-in skills)
```

**Note**: Most of these skills are built-in to Claude Code, so they should be available automatically when you run `claude` on Mac.

---

## Phase 4: Verify Setup

### Checklist

Run these commands in Terminal to verify everything is ready:

```bash
# 1. Check Xcode
xcodebuild -version
# ✅ Should show: Xcode 15.x

# 2. Check Homebrew
brew --version
# ✅ Should show: Homebrew 4.x

# 3. Check Git
git --version
# ✅ Should show: git version 2.x

# 4. Check Claude Code
claude --version
# ✅ Should show: claude-code version x.x.x

# 5. Check project files exist
ls ~/Documents/Builds/Clepsy/docs/plans/
# ✅ Should show: 2026-01-31-clepsy-mvp.md

# 6. Check documentation
ls ~/Documents/Builds/Clepsy/docs/
# ✅ Should show: clepsy_prd.md, data-architecture.md, etc.
```

---

## Phase 5: Start Development with Claude Code

### Launch Claude Code in Project Directory

```bash
# Navigate to project
cd ~/Documents/Builds/Clepsy

# Start Claude Code
claude

# Claude will now have access to all your project files!
```

### Verify Claude Can See Your Files

In the Claude Code session, try:

```
Read the implementation plan at docs/plans/2026-01-31-clepsy-mvp.md
```

Claude should be able to read and display your plan.

---

## Phase 6: Start Building Clepsy

### Option 1: Execute Full Plan Automatically

```bash
# In Claude Code session:
cd ~/Documents/Builds/Clepsy

# Then ask Claude:
"Please execute the implementation plan in docs/plans/2026-01-31-clepsy-mvp.md.
Start with Task 0 (Project Setup) and proceed task-by-task with TDD approach."
```

### Option 2: Manual Task-by-Task Approach

```bash
# In Claude Code session:
"Let's start implementing Clepsy. Begin with Task 0: Project Setup from the plan."

# Claude will:
# 1. Read the task from the plan
# 2. Create Xcode project
# 3. Set up folder structure
# 4. Configure frameworks
# 5. Make initial commit
```

---

## Troubleshooting

### Issue: "Command not found: claude"

**Solution**:
```bash
# Ensure Homebrew is in PATH
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
source ~/.zprofile

# Reinstall Claude Code
brew install anthropics/claude/claude-code
```

### Issue: "Xcode not installed"

**Solution**:
- Open App Store → Search "Xcode" → Install
- Or download from developer.apple.com/xcode

### Issue: Claude Code can't find project files

**Solution**:
```bash
# Make sure you're in the right directory
cd ~/Documents/Builds/Clepsy
pwd
# Should show: /Users/yourname/Documents/Builds/Clepsy

# List files to confirm
ls docs/
```

### Issue: Git not configured

**Solution**:
```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

---

## What You'll Have After Setup

✅ **Mac Development Environment**:
- Xcode 15+ with iOS 16 SDK
- Homebrew package manager
- Git version control
- Claude Code CLI

✅ **Project Files**:
- All documentation (PRD, specs, architecture)
- Implementation plan (29 tasks)
- Brand guidelines and assets

✅ **Claude Code Skills**:
- SwiftUI expert skill
- Frontend design skill
- Animation skill
- Writing plans skill

✅ **Ready to Build**:
- Can create Xcode project
- Can run tests
- Can execute implementation plan
- Can commit code

---

## Quick Start Commands (Copy-Paste)

```bash
# 1. Navigate to project
cd ~/Documents/Builds/Clepsy

# 2. Start Claude Code
claude

# 3. In Claude session, start building:
# "Execute the implementation plan in docs/plans/2026-01-31-clepsy-mvp.md starting with Task 0"
```

---

## Sync Between Windows & Mac (Optional)

If you want to keep working on both machines:

### Setup Git Sync

**On Mac**:
```bash
cd ~/Documents/Builds/Clepsy
git init
git add .
git commit -m "Initial commit from Mac"
git remote add origin https://github.com/yourusername/clepsy.git
git push -u origin main
```

**On Windows** (to pull Mac changes):
```bash
cd C:\Users\josue\Documents\Builds\Clepsy
git pull origin main
```

**On Mac** (to pull Windows changes):
```bash
cd ~/Documents/Builds/Clepsy
git pull origin main
```

---

## Apple Developer Account (Required for Device Testing)

⚠️ **Important**: You'll need this to test on a physical iPhone (Screen Time API doesn't work in simulator)

1. Go to https://developer.apple.com/account
2. Sign in with your Apple ID
3. Enroll in Apple Developer Program ($99/year)
4. Wait for approval (~24 hours)

**For now**: You can build and run in simulator for initial development. Device testing comes later in the plan.

---

## Next Steps

1. ✅ Complete Phase 1-5 (setup)
2. ✅ Verify all checklist items
3. ✅ Launch Claude Code in project directory
4. ✅ Ask Claude to start executing the implementation plan

**You're ready to build Clepsy! 🚀**
