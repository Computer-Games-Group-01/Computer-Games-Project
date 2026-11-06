# Computer Games Project Group 1

Team project in the course Computer Games & Visual Effects (University of Tübingen, winter term 26/27) · Theme: _Fractured Gravity_

Underwater swarm game: we don't control the school of fish, we control gravity. Using Gravity Fields, you steer, split and rescue a boids swarm from enemies controlled by reinforcement learning.

> Engine: Godot 4.7.2-stable (standard version, GDScript) · Renderer: <Forward+ / Mobile / Compatibility>

---

## 1. Once per machine: prerequisites

### 1.1 Install Git + Git LFS

|System|Command / download|
|---|---|
|Windows|Install [Git for Windows](https://git-scm.com/download/win) (includes Git LFS and Git Credential Manager)|
|macOS|`brew install git git-lfs`|
|Linux (Debian/Ubuntu)|`sudo apt install git git-lfs`|

Then run once in a terminal:

```bash
git lfs install
```

Without this step, images, sounds and models arrive only as small text files, and the project is broken.

You need at least **Git 2.45.2** (check with `git --version`). Older versions abort when cloning repos that use LFS (see [Common problems](#5-common-problems)). To update on Windows:

```bash
git update-git-for-windows
```

### 1.2 Set your Git identity

```bash
git config --global user.name  "First Last"
git config --global user.email "your-github-email@example.com"
```

The email should match your GitHub account, otherwise commits won't be attributed to you (important for the peer assessment).

### 1.3 GitHub access

- Accept the invitation to the organization or repo (email or github.com → Notifications)
- Set up authentication for Git, one of these options:
    - **Windows:** do nothing; on your first `git push`, Git Credential Manager opens in the browser
    - **macOS/Linux:** install the [GitHub CLI](https://cli.github.com/) and run `gh auth login`
    - alternatively an SSH key ([guide](https://docs.github.com/en/authentication/connecting-to-github-with-ssh))

Your GitHub password does not work for `git push` over HTTPS.

### 1.4 Install Godot 4.7.2

- Download only from the official archive: [https://godotengine.org/download/archive/](https://godotengine.org/download/archive/) → **4.7.2-stable** → **Standard** variant for your system
- **Not** the .NET variant: we only use GDScript
- **Do not** install via Steam, itch.io or a package manager: they auto-update to newer versions, and then Godot modifies project files when opening the project
- All of us must run **exactly the same version**. Update only after agreeing as a team
- Check: _Help → About Godot_ shows `v4.7.2.stable.official`

Note: if we later integrate the RL enemies via ONNX, that requires the .NET variant. Then everyone switches together, only after agreeing as a team.

Optional (only needed for builds): Export Templates 4.7.2 via _Editor → Manage Export Templates → Download and Install_.

### 1.5 Code editor (optional)

Godot's built-in script editor is enough. If you prefer an external editor: **VS Code** + the **godot-tools** extension, then set the editor in Godot under _Editor → Editor Settings → Text Editor → External_.

### 1.6 Reinforcement learning only


> [!Warning] Important
> Not tested yet, but a possible starting point.


If you work on the RL enemies, you additionally need Python 3 and the [godot-rl](https://github.com/edbeeching/godot_rl_agents) package (Python version as per its docs):

```bash
python -m venv rl/.venv
# Windows: rl\.venv\Scripts\activate   ·   macOS/Linux: source rl/.venv/bin/activate
pip install godot-rl
```

RL work initially happens in the `rl/` folder, separate from the game in `game/`. Nobody else needs this.

### 1.7 C++ (GDExtension) only, once we need it

If you write C++ code, you additionally need Python 3, SCons (`pip install scons`) and a C++ compiler (Windows: Visual Studio Build Tools with "Desktop development with C++", macOS: `xcode-select --install`, Linux: gcc/clang). Nobody else needs this; the precompiled libraries are in the repo.

---

## 2. Clone and open the project

Always use the **HTTPS URL**, not `git@github.com:…`. Over SSH the LFS download often fails on Windows, even if the clone itself works.

```bash
git clone https://github.com/<org>/<repo>.git
cd <repo>
git lfs ls-files     # should list assets (once there are any)
```

If the clone ends with `warning: Clone succeeded, but checkout failed.`, don't keep working; check [Common problems](#5-common-problems) instead.

1. Start Godot → **Import** → select `game/project.godot` in the cloned folder
2. On first open, Godot imports all assets; this takes a moment
3. Check: close Godot, then run `git status`. It must show `nothing to commit, working tree clean`. If not: don't commit anything, report it to the team

---

## 3. Working rules

### Git

- **`git pull` first, then open Godot.** Close Godot before pulling or switching branches
- One branch per task: `feature/<short-description>` (e.g. `feature/gravity-field`)
- Changes go into `main` only via pull request. `main` must always run
- Commit and merge small and often; that keeps conflicts small
- Always stage everything: `git add -A`, so `.uid` and `.import` files are included

### Godot

- Move or rename files only in Godot's **FileSystem dock**, never in Explorer/Finder
- `.uid` and `.import` files belong in the repo. Don't delete them, don't ignore them
- Only one person edits a given `.tscn` at a time. Who is editing which scene is tracked in the GitHub Project (label `scene-lock`)
- For experiments, use your own test scene: `game/levels/sandbox/sandbox_<name>.tscn`
- Change Project Settings (Input Map, Layer Names, Autoloads) only after agreeing as a team; `project.godot` is prone to conflicts

### Code style (GDScript)

- Tabs; files and folders in `snake_case`, nodes in `PascalCase`
- Static types: `var speed: float = 200.0`
- Tuning values as `@export` or in `.tres` resources, don't hardcode them
- Python in the `rl/` folder: 4 spaces

---

## 4. Project structure

```
<repo>/
├── .github/       PR template
├── docs/          Pitch, devlogs, presentations, moodboards
├── rl/            RL training (Python), initially separate from the game
├── game/          Godot project (project.godot)
│   ├── assets/    Raw data (art, audio, fonts, shaders), no logic
│   ├── core/      Autoloads: Events (signal bus), GameState
│   ├── flock/     Boid system (Flock, BoidSettings)
│   ├── fields/    The player's Gravity Fields
│   ├── enemies/   Enemies (hand-written, later RL-controlled)
│   ├── levels/    Level scenes, sandbox/ for personal test scenes
│   ├── ui/
│   ├── tools/     Debug overlays, editor scripts
│   └── addons/    Third-party plugins
├── .editorconfig
├── .gitattributes
├── .gitignore
└── README.md
```

Godot lives in the `game/` subfolder. That way Godot imports neither `docs/` nor `rl/`.

### Git LFS

Images, audio, 3D models, fonts and ONNX models are stored in Git LFS (see `.gitattributes`). **SVG is not LFS**; it stays in regular Git as a text file. Videos and raw trailer footage don't belong in the repo, but in a shared folder (e.g. Drive).

---

## 5. Common problems

|Problem|Solution|
|---|---|
|Clone aborts: `fatal: active post-checkout hook found during git clone`|Git version too old (bug in Git ≤ 2.45.1 with LFS). Update Git (`git update-git-for-windows`), delete the folder, clone again|
|Clone aborts: `smudge filter lfs failed … Permission denied (publickey)`|Cloned with the SSH URL, LFS can't authenticate. In the folder: `git remote set-url origin https://github.com/<org>/<repo>.git`, then `git restore --source=HEAD :/` and `git lfs pull`|
|Images/sounds missing or broken, file contains `version https://git-lfs…`|`git lfs install`, then `git lfs pull`|
|Many modified `.uid`/`.tscn` files after opening|Wrong Godot version or didn't pull before opening. Don't commit; discard the changes (`git restore .`), pull, reopen|
|`project.godot` modified although nothing was changed|Check the Godot version (_Help → About_)|
|Push rejected: `protected branch`|Expected. Merge via branch + pull request|
|Merge conflict in a `.tscn`|Don't merge by hand. Pick one version (`git checkout --ours/--theirs <file>`) and redo the other side's changes in Godot|

---

## 6. Contact

- Communication: Discord
- Tasks: GitHub Project (board)
- Design document: <Link>
- Setup questions: Leon Kaspers
