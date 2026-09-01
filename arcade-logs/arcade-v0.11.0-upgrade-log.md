# Arcade — Open WebUI v0.9.2 → v0.11.0 Upgrade Log

**Branch:** `arcade-upgrade-v11` (baseline = `prod-main` = `origin/main` `b33b0725e`)
**Upgrade window:** 2026-07-29 → 2026-08-03
**Merge commit:** `5042faf05` — `Merge tag 'v0.11.0' into arcade-upgrade-v11`

Purpose: upgrade the Arcade fork from Open WebUI 0.9.2 to 0.11.0, preserving all
Arcade customizations (native tools, skills, async-DB layer, branding). This log
records every issue found and the fix applied, for tracking and for the prod rollout.

---

## 0. Merge & build

**What:** Merged upstream tag `v0.11.0` into the fork. 76 conflicts resolved.
- i18n translations (61 files) → took upstream.
- CI workflows (`.github/workflows/*`) → kept ours (upstream deleted them).
- `ModelSettingsModal.svelte` → accepted upstream deletion (nothing referenced it).
- `env.py`, and ~11 frontend `.svelte` components → hand-merged (kept Arcade branding, adopted upstream structure).
- All custom **backend** (native function-calling tools, `skills`, async `get_model_by_id`) auto-merged intact.

**Build notes (important for prod):**
- Frontend build OOMs with the default Node heap → must run:
  `NODE_OPTIONS=--max-old-space-size=8192 npm run build`
- Backend deps: `pip install -r backend/requirements.txt` (no `uv` on the box).
- Real database path: `/opt/open-webui/backend/data/webui.db` — the app resolves it
  from the `DATA_DIR` env var (default `BACKEND_DIR/data`), **not** the service's
  `WEBUI_DATA_DIR`. When running alembic/scripts manually, set `DATA_DIR` accordingly.

---

## 1. Startup crash — `WEBUI_SECRET_KEY` now mandatory  (commit `977ef6a06`)

**Issue:** 0.11.0 makes `WEBUI_SECRET_KEY` a hard requirement — `env.py` does
`raise SystemExit(...)` if it is empty while auth is enabled. The service launches
via `dev.sh` (raw `uvicorn`), which never set the key → the app exited on startup →
systemd showed "active" but nothing bound port 8080 → 503 / "service unavailable".

**Root cause:** 0.9.2 silently fell back to the built-in default `t0p-s3cr3t`
(`os.getenv('WEBUI_SECRET_KEY', os.getenv('WEBUI_JWT_SECRET_KEY', 't0p-s3cr3t'))`).
All existing sessions **and** OAuth/SSO data were encrypted with `t0p-s3cr3t`.
0.11.0 removed the fallback.

**Fix:** `backend/dev.sh` now sets the key, defaulting to the original value so
existing sessions/OAuth survive:
`export WEBUI_SECRET_KEY="${WEBUI_SECRET_KEY:-t0p-s3cr3t}"`

> Security debt: `t0p-s3cr3t` is a weak known default (it was already the effective
> key on 0.9.2, so no new exposure). Rotating to a strong key later requires a
> deliberate re-encryption pass and will log all users out — do it as planned
> maintenance, NOT during the upgrade.

---

## 2. Database migration

**Issue:** On first 0.11.0 boot, an alembic step logged
`Online migration expected to match one row when updating '461111b60977' to
'3ff2c63645b8' in 'alembic_version'; 0 found` — a transient desync from a fork
migration (`461111b60977`, "add missing primary keys") rebuilding tables via
`batch_alter_table` on a populated SQLite DB.

**Resolution:** `run_migrations` in `config.py` swallows the error and the service
`Restart=always` retried; the DB self-completed to head `f0bd01a18a3d`. Verified the
schema is complete (all new columns present). No manual `alembic stamp` was needed.
(Runbook if a future upgrade sticks: stop service → `sudo su openwebui` → activate
venv → `cd backend/open_webui` → set `DATA_DIR` + `WEBUI_SECRET_KEY` → `alembic
current` / `history` / `stamp <rev>` / `upgrade head`. Back up the DB first.)

---

## 3. Theme restoration  (commits `977ef6a06`, `9eb2b8466`)

The merge favored upstream's neutral 0.11 styling; these restored the Arcade look.

- **`src/app.css`:** re-added the `@font-face` blocks (Archivo, Mona Sans,
  InstrumentSerif) and `.font-primary` / `.font-secondary` (dropped by the merge);
  copied the font files back into `static/assets/fonts/`. Also lightened the dimmest
  muted grays in dark mode (`.dark .dark:text-gray-500/600`, `.dark .text-gray-500`
  → `gray-400`) for readability.
- **Sidebar (`Sidebar.svelte`, `ChatItem.svelte`):** the sidebar is a green gradient
  (`#163D2F`→`#1A4B38`→`#1F5941`) in **both** modes, so all sidebar text was forced
  light (upstream had made it dark → invisible in light mode). Restored the
  translucent selection overlay `bg-white/20 dark:bg-gray-900` (blackish in dark,
  subtle white in light) uniformly across chat items + buttons; removed the logo
  hover; orange `#FF8800` unread dot; orange user-menu hover; white divider; logo/
  title sizing (`h-8`, `text-2xl`, `font-primary`).
- **Admin + Workspace tabs** (`admin/+layout.svelte`, `admin/Users.svelte`,
  `workspace/+layout.svelte`): upstream used a faint `text-gray-300 dark:text-gray-600`
  → changed to black/white adaptive `text-gray-900 dark:text-white`.
- **Settings modal (`SettingsModal.svelte`):** restored the Arcade-green active-tab
  underline `border-b-2 border-[#1F5941]`; made inactive tabs readable; settings
  group headings colored (light `#E67A00` / dark `#FFB347`).
- **High-contrast mode:** scoped CSS so sidebar text stays light on the green in
  HC light mode (HC otherwise darkens muted text → invisible on green); HC still
  applies everywhere else.

---

## 4. SSO login button  (commit `665deb42f`)

**Issue:** Clicking "Continue with Rancho Azure AD" did nothing but show
"The email or password provided is incorrect."

**Root cause:** the OAuth provider buttons in `src/routes/auth/+page.svelte` lacked
`type="button"`, so inside the login `<form>` they acted as **submit** buttons —
they submitted the empty password form (→ `INVALID_CRED`) instead of navigating to
`/oauth/{provider}/login`.

**Fix:** added `type="button"` to the OAuth provider buttons. The OAuth flow itself
was verified healthy (clean 302 to Microsoft with the correct
`redirect_uri=.../oauth/oidc/callback`).

---

## 5. SSO — EXPIRED Azure client secret  ⚠️ OPEN (external, not code)

**Issue:** After the button fix, SSO reached Microsoft, came back to the callback,
and failed. Log:
`AADSTS7000222: The provided client secret keys for app
'238e756e-5c49-48d2-826e-99a61c4acf29' are expired.` (surfaced to the UI as the
generic "email or password incorrect").

**Root cause:** the Azure AD (Entra) **client secret has expired** — unrelated to
the upgrade. Token exchange at `/v1/responses` /token fails.

**Fix (NOT code — needs Azure AD admin / Rancho IT):**
1. Azure portal → App registrations → app `238e756e-5c49-48d2-826e-99a61c4acf29`
   (tenant `72e6eb9a-fcb3-48b4-8dc5-7fb39a973cfa`) → Certificates & secrets →
   new client secret.
2. Update `OAUTH_CLIENT_SECRET` in `.env` — **both test and prod** (same app reg).
3. Restart the service.

OIDC config lives in `.env` (`OAUTH_CLIENT_ID`, `OPENID_PROVIDER_URL`,
`OPENID_REDIRECT_URI=.../oauth/oidc/callback`, `OAUTH_PROVIDER_NAME="Rancho Azure AD"`,
`OAUTH_MERGE_ACCOUNTS_BY_EMAIL=true`).

---

## 6. Raw GPT reasoning models erroring on `/chat/completions`  (commit `a75d7f092`)

**Issue:** All raw `gpt-5.*` / `o-series` connection models returned only an error
and no output:
`Function tools with reasoning_effort are not supported for gpt-5.6-terra in
/v1/chat/completions. To use function tools, use /v1/responses or set
reasoning_effort to 'none'.`

**Root cause:** 0.11 attaches function tools (native FC / web search / knowledge) to
`/chat/completions` requests. OpenAI rejects **function tools + reasoning_effort**
together for reasoning models. (Worked on 0.9.2 because tools weren't attached that way.)

**Fix:** `backend/open_webui/routers/openai.py` — in `openai_reasoning_model_handler`,
strip function tools for reasoning models so they answer normally (no live web on the
raw model). For reasoning **+** web search together, use the `openai_responses.*`
pipe models (which use `/v1/responses`).

---

## 7. Pipe strict mode vs. `update_memory`  ⚠️ DB-ONLY (not in git)

**Issue:** The pipe model `OpenAI: gpt-5.6-thinking-xhigh` (`/v1/responses` path)
failed with:
`HTTP 400 invalid_function_parameters — Invalid schema for function 'update_memory':
'additionalProperties' is required to be supplied and to be false (tools[N].parameters)`.

**Root cause:** the `openai_responses_api_manifold_latest` pipe forced `strict=True`
on all function tools. OpenAI **strict** function-calling requires
`additionalProperties: false` + fully-defined properties on every (incl. nested)
object schema. The builtin `update_memory` tool takes `operations: list[dict]`
(free-form) → its auto-generated schema (`items: {type: object}`) can't satisfy
strict → rejected.

**Fix:** changed `transform_tools(... strict=True ...)` → `strict=False` in the pipe
(with a documenting comment). Web search is unaffected (it's a built-in tool, not a
function tool, so strict never applied to it).

> **⚠️ This change lives ONLY in the database** (`function.content` for
> `openai_responses_api_manifold_latest`) — it is NOT a repo file and is NOT in git.
> It must be **re-applied on prod**: Workspace → Functions → "OpenAI Responses API
> Manifold Latest" → Edit → set `strict=False` in the `transform_tools` call → Save
> (UI save reloads live, no restart needed). It would also be lost if the function is
> ever re-imported from the upstream toolkit (jrkropp/open-webui-developer-toolkit).
> Test backup: `/home/aishpathak/openai_responses_pipe.pre-strict-fix.bak`.

---

## Commits on `arcade-upgrade-v11`

```
a75d7f092  Fix raw reasoning models (gpt-5+/o-series) erroring on /chat/completions
665deb42f  Fix OAuth login buttons submitting the password form
9eb2b8466  Theme: readable Workspace tabs + high-contrast sidebar fix
977ef6a06  Fix v0.11.0 upgrade: secret-key handling + restore Arcade theme
5042faf05  Merge tag 'v0.11.0' into arcade-upgrade-v11
```

---

## Prod rollout checklist

1. Deploy branch `arcade-upgrade-v11` to prod.
2. **`dev.sh`:** ensure the `WEBUI_SECRET_KEY` block is present (defaults to
   `t0p-s3cr3t`) — **critical** or every prod user loses SSO/sessions.
3. Backend deps: `pip install -r backend/requirements.txt`.
4. Frontend build: `NODE_OPTIONS=--max-old-space-size=8192 npm run build`.
5. **Re-apply the pipe `strict=False` fix** on prod (§7 — DB-only, do via
   Workspace → Functions UI).
6. **Rotate the Azure client secret** (§5) and set `OAUTH_CLIENT_SECRET` in prod `.env`.
7. Restart the service; verify migrations reach head.
8. Tell prod users to **hard-refresh once** (stale PWA service worker after a
   frontend upgrade) or the UI looks broken.
9. **Security:** rotate the OpenAI API keys that were exposed during debugging
   (connection 0 on `api.openai.com` + the pipe's `API_KEY` valve).

## Still open
- Azure client secret rotation (Rancho IT) — standard SSO blocked until done.
- Re-enable the admin "Default webhook" (`events.webhooks`, Azure Logic App) once
  SSO logs in cleanly — it was disabled to stop the new-user-signup email loop.
