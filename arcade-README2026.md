# arcade-README2026 — Repo Structure & Architecture Reference

> **Purpose**: Onboarding/reference doc for the Rancho `open-webui` fork running on
> `test-arcade.rbsdev.net`. Captures **how** the codebase, deployment, and config
> are wired together so developers can navigate it confidently before making changes.
>
> **Author**: Aish Pathak — branch `arcade-test` — Apr 2026
> **Companion doc**: `arcade-DEVPLAN-2026.md` (developer workflow / how-to guide)

---

## 1. What this is

This server hosts **Rancho's fork of [Open WebUI](https://github.com/open-webui/open-webui)** —
a self-hosted ChatGPT-like web app that talks to LLM backends (Ollama, OpenAI,
Anthropic, Google) and adds RAG, tools, OAuth, and admin controls.

- **GitHub fork**: `https://github.com/ranchobiosciences/open-webui.git`
- **Public test URL**: `https://test-arcade.rbsdev.net`
- **Authentication**: Microsoft Azure AD (Rancho tenant) via OIDC
- **Server host**: `test-arcade-rbsdev-net` (resolves to `148.113.210.23`)
- **Repo path on server**: `/opt/open-webui`

---

## 2. Stack at a glance

| Layer         | Tech                                                                                    |
| ------------- | --------------------------------------------------------------------------------------- |
| Frontend      | SvelteKit 5 + TypeScript + Tailwind 4 + Vite 5                                          |
| Backend       | FastAPI + uvicorn + SQLAlchemy (Python 3.11)                                            |
| DB            | SQLite (default) / Postgres / MySQL via SQLAlchemy                                      |
| Realtime      | Socket.IO (path `/ws/socket.io`)                                                        |
| Vector store  | ChromaDB (default) / OpenSearch                                                         |
| Auth          | OIDC (Azure AD), JWT, optional LDAP                                                     |
| Process mgr   | `systemd` unit `open-webui.service`                                                     |
| Reverse proxy | (Upstream — terminates HTTPS for `test-arcade.rbsdev.net`, proxies to `localhost:8080`) |

The single FastAPI process serves **both the API and the built static frontend**
on port `8080`. There is no separate web server for the frontend in production.

---

## 3. Server topology — what runs where

```
                         ┌─────────────────────────────────────────────┐
   HTTPS (Internet)      │  test-arcade.rbsdev.net (148.113.210.23)    │
   ───────────────►      │                                             │
                         │  ┌──────────────────────────────────────┐   │
                         │  │ HTTPS terminator (upstream proxy)    │   │
                         │  │ — TLS, then proxies to 127.0.0.1:8080│   │
                         │  └──────────────┬───────────────────────┘   │
                         │                 │                           │
                         │  ┌──────────────▼───────────────────────┐   │
                         │  │ open-webui.service (systemd)         │   │
                         │  │  user: openwebui  group: openwebdev  │   │
                         │  │  cwd:  /opt/open-webui/backend       │   │
                         │  │                                      │   │
                         │  │  bash -c "export WEBUI_DATA_DIR=...  │   │
                         │  │      && . venv/bin/activate          │   │
                         │  │      && . dev.sh"                    │   │
                         │  │                                      │   │
                         │  │  uvicorn open_webui.main:app         │   │
                         │  │      --host 0.0.0.0 --port 8080      │   │
                         │  │      --reload                        │   │
                         │  └────────┬─────────────────────────────┘   │
                         │           │                                 │
                         │      Serves:                                │
                         │      - /api/*       FastAPI routes          │
                         │      - /ws/*        Socket.IO               │
                         │      - /static/*    /opt/open-webui/static  │
                         │      - /            /opt/open-webui/build   │
                         │                       (SPA fallback)        │
                         │                                             │
                         │  External services this talks to:           │
                         │     • Ollama at localhost:11434             │
                         │     • Azure AD OIDC (login.microsoftonline) │
                         │     • OpenAI/Anthropic/Gemini (if keys set) │
                         └─────────────────────────────────────────────┘
```

**Key facts**

- The systemd unit at `/etc/systemd/system/open-webui.service` runs `dev.sh`,
  not `start.sh`. That means uvicorn is started with `--reload` — **backend
  code changes auto-restart the worker** (no manual restart needed for `.py` edits).
- Only port `8080` is exposed by the application. HTTPS termination happens
  upstream (we don't have visibility into that proxy from this server).
- Logs are written to the systemd journal (`journalctl -u open-webui.service`).

---

## 4. Directory layout (top level)

```
/opt/open-webui/
├── backend/              ← Python FastAPI application
│   ├── open_webui/         ← actual package (main.py, routers/, models/, ...)
│   ├── dev.sh              ← launcher used by systemd (uvicorn --reload)
│   ├── start.sh            ← prod-style launcher (no --reload, multi-worker)
│   ├── venv/               ← Python virtualenv (deps from pyproject.toml)
│   ├── requirements.txt    ← pinned deps mirror
│   └── data/               ← runtime data (DB, uploads, vectors) — ⚠ persistent
│
├── src/                  ← SvelteKit frontend source
│   ├── app.html            ← HTML shell + splash screen
│   ├── routes/             ← pages (file-based routing)
│   ├── lib/
│   │   ├── apis/           ← typed wrappers for backend HTTP calls
│   │   ├── components/     ← Svelte components (chat, admin, layout, ...)
│   │   ├── stores/         ← global state (writable stores)
│   │   ├── constants/      ← compile-time constants (APP_NAME, URLs, ...)
│   │   ├── i18n/locales/   ← translations (en-US, fr-FR, ja-JP, ...)
│   │   └── utils/
│   └── tailwind.css
│
├── build/                ← VITE BUILD OUTPUT (frontend artifact). DO NOT EDIT.
│                            Regenerated by `npm run build`. Served by FastAPI.
│
├── static/               ← raw static assets served at `/static/*`
│   ├── favicon*            ← browser tab icon
│   ├── splash*.png         ← splash screen logos (light + dark)
│   ├── custom.css          ← user-overridable CSS hook (currently empty)
│   ├── themes/             ← extra themes (rosepine etc.)
│   ├── audio/              ← notification sounds
│   └── manifest.json       ← PWA manifest
│
├── docs/                 ← upstream docs (apache.md, CONTRIBUTING, SECURITY)
├── docker-compose*.yaml  ← upstream Docker recipes (NOT used here)
├── Dockerfile            ← upstream Docker recipe (NOT used here)
├── package.json          ← frontend deps + npm scripts
├── pyproject.toml        ← backend deps (Python project metadata)
├── svelte.config.js      ← SvelteKit config
├── vite.config.ts        ← Vite bundler config
├── tailwind.config.js    ← Tailwind theme/plugin config
├── tsconfig.json         ← TypeScript compiler config
├── .env                  ← runtime env vars for the backend ⚠ contains secrets
├── .env.example          ← template
├── CHANGELOG.md          ← upstream changelog
├── README.md             ← upstream README
└── (this file)
```

**Permissions note**: most files are owned by `kabenla:openwebdev`. To write
inside `/opt/open-webui` your user must be in the `openwebdev` group:

```bash
groups            # check — should include `openwebdev`
sudo usermod -aG openwebdev $USER && exit   # add yourself, then reconnect SSH
```

---

## 5. Frontend deep-dive (`src/`)

### 5.1 Framework

[**SvelteKit**](https://kit.svelte.dev/) with **file-based routing**. Each
folder under `src/routes/` corresponds to a URL path:

```
src/routes/
├── +layout.svelte       ← root layout (loaded for every page)
├── +layout.js           ← root load function
├── auth/+page.svelte    ← /auth (login screen)
├── error/+page.svelte   ← /error
├── (app)/               ← grouped routes — all real app pages
│   ├── +layout.svelte     ← inner layout (sidebar, navbar)
│   ├── +page.svelte       ← /         (chat home)
│   ├── home/              ← /home
│   ├── c/[id]/            ← /c/<chat-id>   (chat view)
│   ├── channels/          ← /channels/...  (group chat)
│   ├── notes/             ← /notes/...
│   ├── workspace/         ← /workspace/{tools,skills,models,functions}
│   ├── playground/        ← /playground
│   └── admin/             ← /admin/{settings,users,evaluations,functions,analytics}
├── s/[id]/              ← /s/<id>     (shared chat, public)
└── watch/               ← /watch      (?)
```

The `(app)` folder name in parentheses is a SvelteKit convention — it's a
**layout group**, not part of the URL.

### 5.2 The page-load flow

1. Browser loads `app.html` → shows the splash screen (logo at `/static/splash.png`).
2. SvelteKit hydrates the root `+layout.svelte`.
3. `+layout.svelte`'s `onMount` calls `getBackendConfig()` → `GET /api/config`.
4. The backend response populates the `config` and `WEBUI_NAME` Svelte stores.
5. If a session cookie exists, `getSessionUser()` is called; otherwise the user
   is redirected to `/auth`.
6. The splash screen is removed once `loaded = true`.

### 5.3 Where the platform name and title come from

The browser tab title is set in `src/routes/+layout.svelte`:

```svelte
<svelte:head>
	<title>{$WEBUI_NAME}</title>
	<meta name="apple-mobile-web-app-title" content={$WEBUI_NAME} />
	<meta name="description" content={$WEBUI_NAME} />
</svelte:head>
```

`$WEBUI_NAME` is a writable Svelte store defined in `src/lib/stores/index.ts`:

```ts
import { APP_NAME } from '$lib/constants';
export const WEBUI_NAME = writable(APP_NAME); // default before backend responds
```

It's overwritten on app load by:

```ts
const backendConfig = await getBackendConfig(); // GET /api/config
await WEBUI_NAME.set(backendConfig.name);
```

So the **source of truth for the platform name lives on the backend** — see §6.3.

### 5.4 State / stores (`src/lib/stores`)

All cross-component state lives in `src/lib/stores/index.ts` as Svelte writable
stores. Major ones:

| Store             | Holds                                                                   |
| ----------------- | ----------------------------------------------------------------------- |
| `config`          | full backend config blob                                                |
| `user`            | current session user                                                    |
| `WEBUI_NAME`      | platform display name                                                   |
| `WEBUI_VERSION`   | running version reported by backend                                     |
| `theme`           | current theme (`'system' \| 'dark' \| 'light' \| 'her' \| 'oled-dark'`) |
| `socket`          | live Socket.IO connection                                               |
| `chats`, `chatId` | chat list and active chat                                               |
| `models`, `tools` | available models / tools                                                |
| `mobile`, `isApp` | viewport / electron flags                                               |

### 5.5 API client (`src/lib/apis`)

One folder per backend domain (chats, knowledge, retrieval, models, ...). Each
exports typed `fetch` wrappers — that's the contract between frontend and
backend. If you add a backend route, add a wrapper here.

### 5.6 i18n (`src/lib/i18n`)

`i18next` with one folder per locale. English source strings live in
`src/lib/i18n/locales/en-US/translation.json`. To re-extract translatable
strings from the codebase, run `npm run i18n:parse`.

---

## 6. Backend deep-dive (`backend/open_webui/`)

### 6.1 Module layout

```
backend/open_webui/
├── main.py              ← FastAPI app, lifespan, all middleware,
│                          mounts /static and /build, registers routers
├── env.py               ← reads OS env vars at import time → module constants
├── config.py            ← runtime PersistentConfig values (DB-backed),
│                          override env-var values
├── constants.py         ← static constants (e.g. error messages)
├── routers/             ← one file per HTTP route domain
├── models/              ← SQLAlchemy/Pydantic data models
├── internal/            ← DB engine setup, internal migrations
├── migrations/versions/ ← Alembic migrations
├── retrieval/           ← RAG: loaders, vector stores, web search
├── socket/              ← Socket.IO server
├── storage/             ← file storage abstraction (local, S3, ...)
├── static/              ← extra backend-served assets (swagger UI, fonts)
├── tools/               ← server-side tool execution
└── utils/               ← auth, audit, logger, oauth, telemetry, mcp, ...
```

### 6.2 Routers (these are the API endpoints)

`backend/open_webui/routers/` — one file per domain. Each is a FastAPI
`APIRouter`. Mounted under `/api/v1/<name>` (e.g. `/api/v1/auths`, `/api/v1/chats`).

```
analytics  audio       auths     channels  chats      configs
evaluations files       folders   functions groups     images
knowledge  memories    models    notes     ollama     openai
pipelines  prompts     retrieval scim      skills     tasks
terminals  tools       users     utils
```

To find the URL for a feature: `grep -rn '@router' backend/open_webui/routers/<domain>.py`.

### 6.3 Config flow — how a setting reaches the UI

Three layers, lowest-precedence first:

1. **OS environment** (read once at startup): `backend/open_webui/env.py`.
   Each `os.environ.get(...)` becomes a module constant.

   ```python
   WEBUI_NAME = os.environ.get("WEBUI_NAME", "Open WebUI")
   if WEBUI_NAME != "Open WebUI":
       WEBUI_NAME += " (Open WebUI)"   # ⚠ appends suffix unless name == "Open WebUI"
   ```

2. **PersistentConfig** (DB-backed, can be edited live in `/admin/settings`):
   `backend/open_webui/config.py`. Wraps env values so admins can override at
   runtime. Stored in the `config` table.

   ```python
   ENABLE_TITLE_GENERATION = PersistentConfig(
       "ENABLE_TITLE_GENERATION", "task.title.enable",
       os.environ.get("ENABLE_TITLE_GENERATION", "True").lower() == "true",
   )
   ```

3. **App state** (`app.state.WEBUI_NAME = ...` in `main.py`): copied into the
   FastAPI app object, exposed via the `/api/config` endpoint that the frontend
   reads.

The `.env` file at the repo root is loaded by the systemd unit's `dev.sh`
(via `python-dotenv` import inside `env.py`). To take effect for env-var
changes you must restart the service: `sudo systemctl restart open-webui`.
Backend Python code changes pick up automatically thanks to `--reload`.

### 6.4 How the frontend is served

In `main.py`:

```python
app.mount("/static", StaticFiles(directory=STATIC_DIR), name="static")

if os.path.exists(FRONTEND_BUILD_DIR):
    app.mount("/", SPAStaticFiles(directory=FRONTEND_BUILD_DIR, html=True), name="spa-static-files")
```

`FRONTEND_BUILD_DIR` defaults to `/opt/open-webui/build`. So:

- `/api/*` → routers
- `/ws/*` → Socket.IO
- `/static/*` → `/opt/open-webui/static` (raw assets, **edits visible immediately**)
- everything else → SvelteKit's compiled `build/` directory (must be re-built)

---

## 7. Branding & customization — where each thing lives

| What                     | Where                                                       | Reload required? |
| ------------------------ | ----------------------------------------------------------- | ---------------- |
| Platform name            | env var `WEBUI_NAME` → `.env`                               | restart service  |
| Browser tab title        | derived from `$WEBUI_NAME`                                  | (auto)           |
| Splash logo (light/dark) | `static/splash.png`, `static/splash-dark.png`               | hard refresh     |
| Favicon                  | `static/favicon.{png,svg,ico}`, `static/favicon-96x96.png`  | hard refresh     |
| Apple touch icon         | `static/apple-touch-icon.png`                               | hard refresh     |
| PWA name/icons           | `static/manifest.json`                                      | hard refresh     |
| Custom CSS hook          | `static/custom.css` (loaded by `app.html`)                  | hard refresh     |
| Theme color (head meta)  | `static/manifest.json` + inline in `src/app.html`           | rebuild frontend |
| Themes (built-in)        | `static/themes/*.css`                                       | hard refresh     |
| Hardcoded "Open WebUI"   | a few component files (search `grep -rn "Open WebUI" src/`) | rebuild frontend |
| Translatable UI strings  | `src/lib/i18n/locales/*/translation.json`                   | rebuild frontend |
| Banner / announcement    | env `WEBUI_BANNERS` or admin UI → `/admin/settings`         | none (live)      |
| Pending-user overlay     | env `PENDING_USER_OVERLAY_TITLE`                            | restart service  |

⚠ **The `WEBUI_NAME` quirk**: `env.py` lines 135–137 append `" (Open WebUI)"`
to your custom name. To get a clean name (e.g. just "Arcade"), either:

- comment out lines 136–137 of `env.py`, **or**
- set `WEBUI_NAME=Arcade` and accept "Arcade (Open WebUI)" in the UI.

---

## 8. Where logs and runtime data live

| Thing                  | Path / command                                                  |
| ---------------------- | --------------------------------------------------------------- |
| App stdout / stderr    | `journalctl -u open-webui.service -f`                           |
| Service state          | `systemctl status open-webui.service`                           |
| App data (DB, uploads) | `WEBUI_DATA_DIR` = `/home/openwebui/openwebui/app/backend/data` |
| Web access logs        | (upstream proxy — not on this box)                              |
| Build artifact         | `/opt/open-webui/build/`                                        |

---

## 9. Permissions model (on this server)

| Group / user         | Can                                               |
| -------------------- | ------------------------------------------------- |
| `openwebui` (system) | Run the service. Owns runtime data dir.           |
| `openwebdev` group   | Read/write the source tree at `/opt/open-webui/`. |
| `sudo` group         | Restart the service, edit the systemd unit, etc.  |

**To make code changes** you need `openwebdev`. **To restart the service** you
need `sudo`. (Note: the service auto-reloads Python changes, so `sudo` is only
needed for env-var or unit-file edits.)

---

## 10. Quick command cheat sheet

```bash
# Service
sudo systemctl status open-webui
sudo systemctl restart open-webui          # picks up .env / unit-file changes
journalctl -u open-webui.service -f        # tail logs

# Repo (in /opt/open-webui)
git status
git log --oneline -10
git fetch origin
git checkout -b my-feature

# Frontend build
cd /opt/open-webui
npm install                                # first time only
npm run build                              # rebuilds /opt/open-webui/build/

# Linters / formatters
npm run lint                               # eslint + svelte-check + pylint
npm run format                             # prettier
npm run format:backend                     # black

# Find things
grep -rn 'WEBUI_NAME' backend/             # env var usage
grep -rn 'Open WebUI' src/                 # hardcoded brand strings
```

---

## 11. Glossary

- **SvelteKit** — the frontend framework. Files under `src/routes/` are pages.
- **Vite** — the bundler that produces `/opt/open-webui/build/`.
- **Uvicorn** — the ASGI server that runs the FastAPI app.
- **PersistentConfig** — Open WebUI's pattern for env-var defaults that admins
  can override at runtime via the admin UI; values get stored in the DB.
- **SPA fallback** — FastAPI serves `build/index.html` for any unknown path so
  client-side routing works.
- **`--reload`** — uvicorn flag in `dev.sh` that watches `.py` files and
  restarts the worker on change.

---

_End of repo reference. For "how do I make a change and ship it" see
`arcade-DEVPLAN-2026.md`._
