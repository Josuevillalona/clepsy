# Mac Transfer Checklist

Use this checklist to ensure you transfer everything you need from Windows to Mac.

---

## 📦 Files to Transfer

### Required Documents (All in `docs/` folder)

- [ ] `docs/plans/2026-01-31-clepsy-mvp.md` - **CRITICAL** - Implementation plan (29 tasks)
- [ ] `docs/data-architecture.md` - **CRITICAL** - Architecture reference
- [ ] `docs/mac-setup-guide.md` - **CRITICAL** - This setup guide
- [ ] `docs/clepsy_prd.md` - Product requirements
- [ ] `docs/clepsy_mvb.md` - Brand guidelines
- [ ] `docs/dashboard_specs.md` - Dashboard specifications
- [ ] `docs/onboarding_specs.md` - Onboarding flow specs
- [ ] `docs/earning_specs.md` - Earning mechanics
- [ ] `docs/settings_specs.md` - Settings screen specs
- [ ] `docs/Error State specs.md` - Error handling
- [ ] `docs/clepsy_mascot_asset_guide.md` - Character asset guide

### Root Files

- [ ] `TRANSFER-CHECKLIST.md` - This checklist
- [ ] `README.md` (will be created during Task 29)
- [ ] `.gitignore` (if exists)

---

## 🖥️ Mac Setup Steps

### Phase 1: Transfer Files

- [ ] Choose transfer method (Cloud/USB/Git)
- [ ] Copy entire `Clepsy` folder to Mac
- [ ] Place in `~/Documents/Builds/Clepsy`
- [ ] Verify all files transferred correctly

### Phase 2: Install Development Tools

- [ ] Install Xcode from App Store (~15 GB, 30-60 min)
- [ ] Run `sudo xcode-select --install`
- [ ] Accept Xcode license: `sudo xcodebuild -license accept`
- [ ] Verify Xcode: `xcodebuild -version`

### Phase 3: Install Package Manager

- [ ] Install Homebrew: `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`
- [ ] Add Homebrew to PATH (follow install instructions)
- [ ] Verify Homebrew: `brew --version`

### Phase 4: Install Git

- [ ] Install Git: `brew install git`
- [ ] Configure name: `git config --global user.name "Your Name"`
- [ ] Configure email: `git config --global user.email "your@email.com"`
- [ ] Verify Git: `git --version`

### Phase 5: Install Claude Code

- [ ] Install Claude Code: `brew install anthropics/claude/claude-code`
- [ ] Login: `claude login`
- [ ] Verify: `claude --version`

---

## ✅ Verification

Run these commands to verify everything is ready:

```bash
# Navigate to project
cd ~/Documents/Builds/Clepsy

# Check all tools
xcodebuild -version        # Should show Xcode 15.x
brew --version             # Should show Homebrew 4.x
git --version              # Should show git 2.x
claude --version           # Should show claude-code version

# Check files
ls docs/plans/             # Should show 2026-01-31-clepsy-mvp.md
ls docs/                   # Should show all spec files
```

### All Green? ✅

- [ ] Xcode installed and working
- [ ] Homebrew installed
- [ ] Git configured
- [ ] Claude Code installed and authenticated
- [ ] All project files present in `~/Documents/Builds/Clepsy`

---

## 🚀 Ready to Build!

Once all boxes are checked:

```bash
cd ~/Documents/Builds/Clepsy
claude
```

Then in Claude Code session:

```
Execute the implementation plan in docs/plans/2026-01-31-clepsy-mvp.md
starting with Task 0: Project Setup
```

---

## 📞 Need Help?

If you get stuck, refer to:
- `docs/mac-setup-guide.md` - Detailed setup instructions
- `docs/data-architecture.md` - Architecture decisions
- `docs/plans/2026-01-31-clepsy-mvp.md` - Step-by-step implementation

**Common Issues**:
- "command not found: claude" → Reinstall Claude Code via Homebrew
- "Xcode not installed" → Install from App Store
- "Files not found" → Verify you're in `~/Documents/Builds/Clepsy` directory

---

Good luck! 🍀
