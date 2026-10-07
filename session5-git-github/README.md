# Session 5: Git and GitHub — Homework

> **Student:** Radhey Kawasthi (Enrollment: 10242)

This README documents the two Git homework tasks. Every command below was executed on a real local repository and the actual terminal output is shown inside the code blocks.

---

## Task 1: `git commit -m` vs `git commit -a -m`

### The difference

| Command | What it does |
| :--- | :--- |
| `git commit -m "msg"` | Commits **only the files that are already staged** (added to the index with `git add`). Modified-but-unstaged files are **not** committed. |
| `git commit -a -m "msg"` | Automatically **stages all modified/deleted *tracked* files** and commits them in one step — it skips the separate `git add`. |

> **Important:** `-a` only stages files Git already knows about (**tracked** files). Brand-new (untracked) files are **never** picked up by `-a` — you still need `git add` for them.

### Hands-on test

**Step 1 — create a file and try `git commit -m` WITHOUT `git add`:**

```bash
$ git init -b main
Initialized empty Git repository in C:/Users/Lenovo/.../git-demo/.git/

$ echo "version 1" > file1.txt
$ git status --short
?? file1.txt

$ git commit -m "add file1"
On branch main

Initial commit

Untracked files:
  (use "git add <file>..." to include in what will be committed)
	file1.txt

nothing added to commit but untracked files present (use "git add" to track)
```

`git commit -m` **refused** — nothing was staged, so there was nothing to commit.

**Step 2 — stage first, then `git commit -m` works:**

```bash
$ git add file1.txt
$ git commit -m "add file1"
[main (root-commit) c01da83] add file1
 1 file changed, 1 insertion(+)
 create mode 100644 file1.txt
```

**Step 3 — now modify the tracked file AND create a new untracked file, then use `git commit -a -m`:**

```bash
$ echo "version 2" > file1.txt     # modify TRACKED file
$ echo "new file" > file2.txt      # create UNTRACKED file
$ git status --short
 M file1.txt
?? file2.txt

$ git commit -a -m "update file1 with -a flag"
[main dbe1d4a] update file1 with -a flag
 1 file changed, 1 insertion(+), 1 deletion(-)

$ git status --short
?? file2.txt
```

### What I observed

* `git commit -a -m` automatically staged the **modified tracked file** (`file1.txt`) and committed it — no `git add` needed.
* The **untracked file** (`file2.txt`) was left behind (`?? file2.txt` still shows after the commit) — proving `-a` does **not** add new files.
* `git commit -m` alone fails when nothing is staged.

---

## Task 2: Git Cherry-Pick

**Goal:** create commits on `main`, create a `feature` branch with its own commits, then copy **one specific commit** from `feature` onto `main` without merging the whole branch.

### Step 1 — Make 4 commits on `main`

```bash
$ git log --oneline        # on main
cfdbe0e add README
f149503 add file2
dbe1d4a update file1 with -a flag
c01da83 add file1
```

### Step 2 — Create a new branch and make 3 commits on it

```bash
$ git checkout -b feature
Switched to a new branch 'feature'

$ echo "feature work 1" > feat1.txt  && git add feat1.txt  && git commit -m "feature: add feat1"
$ echo "IMPORTANT FIX"  > bugfix.txt && git add bugfix.txt && git commit -m "feature: important bugfix"
$ echo "feature work 3" > feat3.txt  && git add feat3.txt  && git commit -m "feature: add feat3"

$ git log --oneline        # on feature
140f0e0 feature: add feat3
e4b838f feature: important bugfix      <-- the commit we will cherry-pick
2b58f9f feature: add feat1
cfdbe0e add README
f149503 add file2
dbe1d4a update file1 with -a flag
c01da83 add file1
```

### Step 3 — Switch back to `main` and cherry-pick the bugfix commit

```bash
$ git checkout main
Switched to branch 'main'

$ ls                        # bugfix.txt does NOT exist on main yet
file1.txt
file2.txt
README.txt

$ git cherry-pick e4b838f
[main ac181bd] feature: important bugfix
 Date: Wed Oct 7 23:32:16 2026 +0530
 1 file changed, 1 insertion(+)
 create mode 100644 bugfix.txt
```

### Step 4 — Verify the change is on `main`

```bash
$ ls
bugfix.txt          <-- the cherry-picked file is now here
file1.txt
file2.txt
README.txt

$ cat bugfix.txt
IMPORTANT FIX

$ git log --oneline        # on main
ac181bd feature: important bugfix      <-- NEW commit hash, same change
cfdbe0e add README
f149503 add file2
dbe1d4a update file1 with -a flag
c01da83 add file1
```

### What I observed

* `git cherry-pick e4b838f` copied **exactly one commit** from `feature` onto `main` — the other feature commits (`feat1.txt`, `feat3.txt`) were **not** brought over.
* The cherry-picked commit gets a **new commit hash** (`ac181bd` ≠ `e4b838f`) but keeps the **same commit message and change**.
* This is how you grab a single fix from a branch without merging everything.

### Cherry-pick quick reference

```bash
git cherry-pick <commit-hash>     # copy one commit onto the current branch
git cherry-pick <h1> <h2>         # copy several commits
git cherry-pick --continue        # continue after resolving a conflict
git cherry-pick --abort           # cancel a cherry-pick
```
