# arcade-DEVPLAN-2026 — Developer Workflow Guide

> **Purpose**: The exact, end-to-end procedure for making a change to the
> Arcade (Open WebUI) deployment — from "I want to rename the platform" to
> "the change is live for users", including how to **test on
> `test-arcade.rbsdev.net` first** and how to roll back if something breaks.
>
> **Audience**: developers new to this repo who already understand the
> structure (see `arcade-README2026.md` first).
>
> **Author**: Aish Pathak — branch `arcade-test` — Apr 2026

---

## 0. Pre-flight (one-time setup, do this once)

### 0.1 Verify SSH access
```bash
ssh -p 2212 aishpathak@rbsdev.net          # or `ssh rbsdev` if ~/.ssh/config alias is set
```

### 0.2 Verify group membership
```bash
groups
# must include: openwebdev   ← required to write inside /opt/open-webui
# must include: sudo         ← required to restart the systemd service
```
If `openwebdev` is missing:
```bash
sudo usermod -aG openwebdev $USER
exit                                       # log out
ssh rbsdev                                 # log back in (group changes need new session)
groups                                     # verify openwebdev now appears
```

### 0.3 Tell git who you are
```bash
git config --global user.name  "Aish Pathak"
git config --global user.email "aish.pathak@ranchobiosciences.com"
git config --global --add safe.directory /opt/open-webui
git config --global --add safe.directory /opt/open-webui/.git
```

### 0.4 Have GitHub credentials ready
You will need to push to `https://github.com/ranchobiosciences/open-webui.git`.
Use a **personal access token** (PAT) — not your password — when git prompts.
Generate one at <https://github.com/settings/tokens> with `repo` scope. Save it
in a password manager.

---

## 1. Mental model: how a change reaches users

```
┌──────────────────────────────────────────────────────────────────────────┐
│  EDIT     → BRANCH     → TEST locally on the server      → COMMIT/PR    │
│                          (test-arcade.rbsdev.net = test)                │
│                                                                         │
│  Backend (.py) edit:                                                    │
│      uvicorn --reload picks it up automatically (~2s)                   │
│                                                                         │
│  Frontend (.svelte/.ts/.css) edit:                                      │
│      run `npm run build` → /opt/open-webui/build/ regenerates            │
│      browser hard-refresh (Ctrl+Shift+R) to see                         │
│                                                                         │
│  Static asset (logos, favicon, custom.css):                             │
│      replace file in /opt/open-webui/static/                             │
│      browser hard-refresh                                               │
│                                                                         │
│  Env var change (.env) or systemd unit:                                 │
│      sudo systemctl restart open-webui                                  │
└──────────────────────────────────────────────────────────────────────────┘
```

**Important**: this server (`test-arcade.rbsdev.net`) is the **test environment**.
You confirm the change works here, then promote to prod via a GitHub PR that
the production deploy pulls in. We do **not** edit the prod server directly.

> 🔍 We don't have direct access to the prod server from this box. The
> assumption is that prod also pulls from `ranchobiosciences/open-webui` on
> some branch (typically `main`). If that's not the case at your org, ask
> the platform owner (`kabenla`) for the exact prod-deploy procedure and
> append it to §6 of this doc.

---

## 2. The standard 8-step workflow

For **every** change, follow these eight steps in order.

### Step 1 — Sync `main` and create a feature branch

```bash
cd /opt/open-webui
git fetch origin
git checkout main
git pull --ff-only origin main
git checkout -b feat/short-descriptive-name      # e.g. feat/rename-arcade
```

Branch naming convention:
- `feat/...`    new feature / change
- `fix/...`     bug fix
- `chore/...`   non-functional (deps, formatting, docs)

### Step 2 — Make your edits

Open the relevant files in your editor of choice (vim, nano, VS Code Remote-SSH).
The `arcade-README2026.md` "Branding & customization" table tells you which file
controls what.

### Step 3 — If frontend was touched, build it

```bash
cd /opt/open-webui
npm install            # only if package.json changed since last build
npm run build          # writes to /opt/open-webui/build/  (~30–60s)
```

You **don't** need to do this for backend-only or static-asset-only changes.

### Step 4 — If env vars (`.env`) or the systemd unit were touched, restart

```bash
sudo systemctl restart open-webui
sudo systemctl status open-webui            # verify "active (running)"
journalctl -u open-webui.service -n 50      # check for startup errors
```

For backend Python edits **without** env changes, skip this step — `--reload`
already restarted the worker.

### Step 5 — Test on the live test server

Open `https://test-arcade.rbsdev.net` in a browser. **Hard-refresh** with
`Ctrl+Shift+R` (Windows) or `Cmd+Shift+R` (Mac) to bypass the cache. Walk
through your change manually. Tail the logs while clicking around to catch
500s:

```bash
journalctl -u open-webui.service -f
```

### Step 6 — Commit and push

```bash
git status
git diff
git add -A                     # or list specific files
git commit -m "feat: rename platform to Arcade"
git push -u origin feat/rename-arcade
```

If git prompts for credentials, paste your **GitHub username + PAT**.

### Step 7 — Open a Pull Request

On GitHub: <https://github.com/ranchobiosciences/open-webui/pulls> → "New pull
request" → base = `main`, compare = `feat/rename-arcade`. Fill out:
- **What** changed (1–2 sentences)
- **Why**
- **How to test** (URL, what to click, expected behavior)
- **Screenshot** if it's a UI change

Request review from `kabenla` (or your platform owner).

### Step 8 — After merge, clean up

```bash
cd /opt/open-webui
git checkout main
git pull --ff-only origin main
git branch -d feat/rename-arcade
git push origin --delete feat/rename-arcade
```

The production deployment will pull the new `main` on its next sync (cadence
depends on the prod-deploy procedure — confirm with the platform owner).

---

## 3. Worked example #1 — Rename the platform "Open WebUI" → "Arcade"

This is the simplest possible change because **most of it is config, not code**.

### 3a. Decide the depth of the rename

| Change                               | Where                              | Code edit? |
| ------------------------------------ | ---------------------------------- | ---------- |
| Tab title, sidebar header, login screen | `WEBUI_NAME` env var          | No         |
| Drop the `(Open WebUI)` suffix       | `backend/open_webui/env.py:136-137`| Yes (1 line) |
| Logo on splash / sidebar             | `/static/splash*.png`, `favicon*`  | No (file replace) |
| Hardcoded "Open WebUI" in tooltips/components | `src/lib/components/...`  | Yes (Svelte edits + rebuild) |

For a **full** rename, do all four. For a **quick** rename, just the first row
gets you 90% there.

### 3b. The minimal rename

```bash
cd /opt/open-webui
git checkout main && git pull --ff-only origin main
git checkout -b feat/rename-arcade
```

Edit `.env`:
```bash
nano .env
# add or change this line:
WEBUI_NAME=Arcade
```

(If you also want to drop the `(Open WebUI)` suffix that `env.py` appends,
edit `backend/open_webui/env.py` and comment out lines 136–137:
```python
WEBUI_NAME = os.environ.get("WEBUI_NAME", "Open WebUI")
# if WEBUI_NAME != "Open WebUI":          # disabled to allow clean custom name
#     WEBUI_NAME += " (Open WebUI)"
```
)

Restart:
```bash
sudo systemctl restart open-webui
journalctl -u open-webui.service -n 30 --no-pager   # confirm clean startup
```

Test:
1. Open `https://test-arcade.rbsdev.net` → tab title should say "Arcade".
2. Log out → login screen header should say "Arcade".
3. Sidebar / About modal → should say "Arcade".

### 3c. Replace the logo

```bash
# from your laptop, scp the new logo files in:
scp -P 2212 ~/path/to/arcade-splash.png       aishpathak@rbsdev.net:/opt/open-webui/static/splash.png
scp -P 2212 ~/path/to/arcade-splash-dark.png  aishpathak@rbsdev.net:/opt/open-webui/static/splash-dark.png
scp -P 2212 ~/path/to/arcade-favicon.png      aishpathak@rbsdev.net:/opt/open-webui/static/favicon.png
# repeat for favicon-96x96.png, favicon.svg, apple-touch-icon.png as needed
```

Recommended sizes:
- `splash.png` / `splash-dark.png` — 512 px tall, transparent PNG
- `favicon.png` — 256×256 PNG
- `favicon-96x96.png` — 96×96 PNG
- `apple-touch-icon.png` — 180×180 PNG

Hard-refresh the browser to see them. No service restart needed (these are
served directly from `/static/`).

### 3d. Commit and ship

```bash
git add .env backend/open_webui/env.py static/splash.png static/splash-dark.png static/favicon.png
git commit -m "feat: rebrand to Arcade (name, logo, favicon)"
git push -u origin feat/rename-arcade
# then open the PR on GitHub (Step 7 above)
```

⚠ **Before committing `.env`**, double-check it doesn't contain new secrets you
don't want in git history. The current `.env` is already tracked, but be
cautious with OAuth/keys.

---

## 4. Worked example #2 — A GUI change (e.g. add a sidebar item, change a color)

### 4a. Find the file

For a sidebar change, the relevant components live under
`src/lib/components/layout/Sidebar/`. Use grep to locate the exact spot:

```bash
grep -rn 'Workspace\|workspace' src/lib/components/layout/Sidebar/ | head
```

For a color change, edit either `src/app.css`, `tailwind.config.js`, or the
specific component's `<style>` block.

### 4b. Edit, build, refresh

```bash
cd /opt/open-webui
git checkout main && git pull --ff-only origin main
git checkout -b feat/sidebar-add-arcade-link

# … edit files …

npm run build                              # 30–60 s
```

Browser → `https://test-arcade.rbsdev.net` → hard-refresh (`Ctrl+Shift+R`).

### 4c. Iterate quickly with a hot-reload dev server (optional)

For UI work, running `npm run dev` gives you instant Vite hot-reload at
`http://localhost:5173`. You'll need an SSH tunnel from your laptop:

```bash
ssh -p 2212 -L 5173:localhost:5173 aishpathak@rbsdev.net
# then on the server:
cd /opt/open-webui && npm run dev
# on your laptop, open http://localhost:5173
```

CORS is already configured for `http://localhost:5173` in `dev.sh`, so the
dev frontend can talk to the production backend on the same machine.

When done, `Ctrl+C` the dev server. **Don't** ship without running
`npm run build` — `npm run dev` doesn't update `/opt/open-webui/build/`.

### 4d. Commit and ship — same as Step 6+ above

---

## 5. Worked example #3 — A backend logic change (a new API route)

### 5a. Add the route

Edit (or create) a router under `backend/open_webui/routers/`. Pattern:

```python
from fastapi import APIRouter, Depends
from open_webui.utils.auth import get_current_user

router = APIRouter()

@router.get("/hello")
async def hello(user=Depends(get_current_user)):
    return {"message": f"Hello, {user.name}"}
```

If it's a new file, register it in `backend/open_webui/main.py` (look for the
big `from open_webui.routers import (...)` block near the top, then for the
matching `app.include_router(...)` lower down).

### 5b. Watch it auto-reload

Save the file, then:
```bash
journalctl -u open-webui.service -f
# you should see uvicorn detect the change and restart within ~2s
```

### 5c. Hit it

```bash
curl -H "Authorization: Bearer <JWT>" https://test-arcade.rbsdev.net/api/v1/<your-route>/hello
```
(The JWT is in `localStorage.token` after you log in via the browser.)

### 5d. Add a frontend call (optional)

In `src/lib/apis/<domain>/index.ts`, add a typed wrapper that does
`fetch(...).then(res => res.json())`. Import and call it from the component
that needs it.

### 5e. Build, test, commit, PR — same as before

---

## 6. Promoting from test → production

> **TODO**: Confirm with `kabenla` and replace this section with the actual
> prod-deploy procedure used by Rancho. The most likely options are listed
> below.

Possibilities:

1. **GitHub-driven**: prod server has a cron/CI that pulls `main` periodically.
   Merging the PR is enough — wait for the next sync.
2. **Manual pull**: an operator runs `git pull && systemctl restart open-webui`
   on the prod box on a schedule (e.g. weekly maintenance window).
3. **Tag-driven**: tag a release (`git tag v0.x.y && git push --tags`); prod
   deploys whatever is at the latest tag.

Until confirmed, **assume option 2** and notify the platform owner after merge.

---

## 7. Testing checklist (before opening a PR)

Run through this every time:

- [ ] Service is healthy: `systemctl is-active open-webui` returns `active`.
- [ ] No new errors in the journal during the last 5 minutes:
      `journalctl -u open-webui.service --since "5 min ago" | grep -iE 'error|trace'`
- [ ] **Login flow works** — log out, log back in via Azure AD (this exercises
      OAuth, sessions, and the frontend bootstrap).
- [ ] **Open a chat, send a message, get a response** — end-to-end smoke test.
- [ ] **Hard-refresh** the page (`Ctrl+Shift+R`) — confirms no cached old build.
- [ ] **Console clean** — open DevTools, look for red errors (some yellow warnings
      are normal — pyodide, deprecation notices).
- [ ] **No regressions** in the part of the UI you didn't change. If you edited
      the sidebar, click into Workspace and Admin too.
- [ ] Linters pass: `npm run lint`.
- [ ] If frontend changed, build artifact is fresh: check
      `stat /opt/open-webui/build/index.html` modtime is recent.

---

## 8. Rollback procedure (if your change breaks the test server)

```bash
cd /opt/open-webui

# Option A: revert the working tree to the last good commit
git status                                  # confirm what's modified
git checkout -- <files-you-edited>          # discard one file
# OR
git reset --hard origin/main                # NUCLEAR: discards ALL local changes

# Option B: switch back to main while you debug on a side branch
git stash                                   # save your edits for later
git checkout main

# Then rebuild / restart so the live site matches the rolled-back state:
npm run build                               # only if you'd rebuilt frontend earlier
sudo systemctl restart open-webui
```

If you committed (locally) but haven't pushed, `git reset --hard HEAD~1`
removes the last local commit. **Never** force-push to `main`.

---

## 9. Common pitfalls & gotchas

| Symptom                                                    | Likely cause                                               | Fix |
| ---------------------------------------------------------- | ---------------------------------------------------------- | --- |
| Edit isn't visible in the browser                          | Browser cache                                              | Hard-refresh `Ctrl+Shift+R`. |
| Frontend edit isn't visible even after hard-refresh        | Forgot `npm run build`                                     | `cd /opt/open-webui && npm run build` |
| `.env` change isn't taking effect                          | Service wasn't restarted                                   | `sudo systemctl restart open-webui` |
| Brand name shows as "Arcade (Open WebUI)"                  | `env.py` lines 136–137 add the suffix                      | Comment out those two lines (see §3b). |
| 500s after a backend edit                                  | Syntax error — `--reload` started a broken worker          | `journalctl -u open-webui.service -n 50` to see the traceback |
| `git push` rejected                                        | Branch already exists / not authorized                     | Pull-rebase, or check your GitHub PAT scope |
| `Permission denied` editing files in `/opt/open-webui`     | Not in `openwebdev` group                                  | See §0.2 |
| OAuth login bounces back to login screen                   | `WEBUI_URL` or `OPENID_REDIRECT_URI` mismatch in `.env`    | Confirm both still match `https://test-arcade.rbsdev.net` |
| Sockets/streaming disconnect after deploy                  | `WEBUI_VERSION`/`WEBUI_DEPLOYMENT_ID` changed → frontend forced reload | This is by design; tell users to hard-refresh once. |

---

## 10. Glossary of operations

| I want to ...                                  | Run                                                |
| ---------------------------------------------- | -------------------------------------------------- |
| See if the service is running                  | `systemctl status open-webui`                      |
| Restart the service                            | `sudo systemctl restart open-webui`                |
| Tail logs                                      | `journalctl -u open-webui.service -f`              |
| Search logs for an error in the last hour      | `journalctl -u open-webui.service --since "1 hour ago" \| grep -i error` |
| Rebuild the frontend                           | `cd /opt/open-webui && npm run build`              |
| Run a dev frontend with hot-reload             | `cd /opt/open-webui && npm run dev` (port 5173)    |
| Format code                                    | `npm run format` and `npm run format:backend`      |
| Lint                                           | `npm run lint`                                     |
| Show what files I've changed                   | `git status` and `git diff`                        |
| Discard a single uncommitted file              | `git checkout -- <file>`                           |
| See recent commits                             | `git log --oneline -20`                            |
| Switch to someone else's branch                | `git fetch origin && git checkout <branch>`        |
| See env vars the service is using              | `sudo cat /etc/systemd/system/open-webui.service`  |

---

## 11. First small upgrade — suggested practice run

Once you're comfortable with this doc, do a **trivial** change end-to-end as a
dry run before tackling anything real. Example:

1. Branch: `chore/test-deploy-aish`
2. Edit `static/custom.css` → add `body { /* arcade test */ }`
3. Hard-refresh `https://test-arcade.rbsdev.net` — confirm no visual change
   but `view-source` shows the comment.
4. Commit, push, open PR titled "chore: deploy pipeline test (no-op)".
5. After merge, delete the branch.

This exercises every step (branch, edit, deploy, browser-verify, commit, PR,
cleanup) without risking breakage. **Do this first.**

---

*End of developer plan. Pair this with `arcade-README2026.md` for the
architectural reference.*
