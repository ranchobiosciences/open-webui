# Arcade Branding Change Log

A running log of every branding change made to the Arcade (Open WebUI) project.
All changes made on rbsdev at /opt/open-webui.

---

## Session: 2026-05-19

### Context
Platform: Open WebUI 0.9.2 rebranded as Arcade for Rancho BioSciences.
Brand colors: Green #1F5941, Orange #FF8800, Gray #ECECEC.

---

### Change 1 — Revert green-tinted gray palette (tailwind.css)
**File:** src/tailwind.css
**Reason:** A previous attempt tinted the entire gray palette green. This caused
unselected items in settings/models lists to look washed out and transparent.
Decision: revert to neutral grays and use brand colors as targeted accents only.
**Command:**
  cd /opt/open-webui && git checkout src/tailwind.css

---

### Change 2 — Green sidebar background (dark mode)
**File:** src/lib/components/layout/Sidebar.svelte (line 990)
**Reason:** Option B branding approach — sidebar is the primary branded surface.
Main content area stays neutral for readability.
**What changed:**
  Before: 'bg-gray-50 dark:bg-gray-950'        (mobile)
          'bg-gray-50/70 dark:bg-gray-950/70'   (desktop)
  After:  'bg-gray-50 dark:bg-[#1F5941]'        (mobile)
          'bg-gray-50/70 dark:bg-[#1F5941]'      (desktop)
Light mode sidebar unchanged (bg-gray-50). Dark mode sidebar = brand green #1F5941.
**Rebuild required:** yes — npm run build

---


### Change 3 — Green sidebar in both light and dark mode
**File:** src/lib/components/layout/Sidebar.svelte (line 990)
**Reason:** Light mode sidebar was blending into main content. Decision: use
brand green #1F5941 consistently in both modes for visual identity.
**What changed:**
  Background:
    Before: 'bg-gray-50 dark:bg-[#1F5941]' : 'bg-gray-50/70 dark:bg-[#1F5941]'
    After:  'bg-[#1F5941]' : 'bg-[#1F5941]'
  Text color:
    Before: text-gray-900 dark:text-gray-200
    After:  text-gray-200
  (Dark text on dark green would be unreadable — unified to light text for both modes)
**Rebuild required:** yes — npm run build


### Change 4 — Unified white text + semi-transparent selection overlay (light mode)
**Files:** 
  - src/lib/components/layout/Sidebar.svelte
  - src/lib/components/layout/Sidebar/ChatItem.svelte
**Reason:** Light mode had mixed black/white text on the green sidebar, and
selected chat items (bg-gray-100 = near white) made white text invisible.
Decision: unify all sidebar text to white, use semi-transparent white overlays
for selected/hover states so text stays readable.

**Sidebar.svelte changes:**
  text-black dark:text-white           → text-white           (1 occurrence)
  text-gray-800 dark:text-gray-200     → text-gray-200        (3 occurrences)

**ChatItem.svelte changes:**
  bg-gray-100 dark:bg-gray-900         → bg-white/20 dark:bg-gray-900     (2x, active)
  bg-gray-100 dark:bg-gray-950         → bg-white/20 dark:bg-gray-950     (2x, selected)
  group-hover:bg-gray-100 ...          → group-hover:bg-white/10 ...      (2x, hover)
  from-gray-100 dark:from-gray-900     → from-[#1F5941] dark:from-gray-900 (1x, gradient)
  from-gray-100 dark:from-gray-950     → from-[#1F5941] dark:from-gray-950 (2x, gradient)

Dark mode classes untouched throughout.
**Rebuild required:** yes — npm run build


### Change 5 — Unified white text across remaining sidebar sub-components
**Files:** ChatItem.svelte, ChannelItem.svelte, RecursiveFolder.svelte, PinnedModelItem.svelte
**Reason:** Sub-components still had explicit dark text not caught in earlier pass.
  ChatItem.svelte:        text-gray-900 dark:text-gray-100 -> text-white dark:text-gray-100
  ChannelItem.svelte:     text-black                       -> text-white
  RecursiveFolder.svelte: text-gray-700 dark:text-gray-300 -> text-gray-200
  PinnedModelItem.svelte: text-gray-800 dark:text-gray-200 -> text-gray-200
**Rebuild required:** yes

### Change 6 — Orange unread chat indicator (dot + left border)
**File:** src/lib/components/layout/Sidebar/ChatItem.svelte
**Reason:** Blue unread dot replaced with orange brand color. Left border added
for a subtle, non-flashy unread indicator spanning the full row height.
  Dot:    bg-sky-500 -> bg-[#FF8800]
  Border: border-l-2, border-[#FF8800] when unread / border-transparent when read
**Rebuild required:** yes


### Change 7 — Arcade name: white text + larger font
**File:** src/lib/components/layout/Sidebar.svelte (line 1023, id=sidebar-webui-name)
**Reason:** App name was dark (text-gray-850) in light mode, invisible on green
sidebar. Also increased font size for visual prominence.
**Changes:**
  text-gray-850 dark:text-white  →  text-white   (white in both modes)
  (no size class)                →  text-lg       (18px)
**Rebuild required:** yes — npm run build


### Change 8 — Arcade name font size bumped to XL
**File:** src/lib/components/layout/Sidebar.svelte (id=sidebar-webui-name)
**Change:** text-lg → text-xl (20px)
**Rebuild required:** yes — npm run build


### Change 9 — Orange subsection headers + larger font
**Files:**
  - src/lib/components/layout/Sidebar.svelte (line 1512)
  - src/lib/components/common/Folder.svelte (lines 20, 155)
**Reason:** Section labels (Today, Yesterday, Previous 7/30 days, Folders) were
tiny gray text, hard to spot on the green sidebar. Changed to orange brand color
and bumped from text-xs to text-sm for readability.
**Changes:**
  Sidebar.svelte: text-xs text-gray-500 dark:text-gray-500 font-medium
               -> text-sm text-[#FF8800] dark:text-[#FF8800] font-medium
  Folder.svelte:  buttonClassName default: text-gray-600 dark:text-gray-400
               -> text-[#FF8800] dark:text-[#FF8800]
  Folder.svelte:  button label: text-xs font-medium -> text-sm font-medium
**Rebuild required:** yes — npm run build


### Change 10 — Subsection headers: orange -> bold black
**Files:** src/lib/components/layout/Sidebar.svelte, src/lib/components/common/Folder.svelte
**Reason:** Orange headers didn't look right. Bold black on green background
provides clean contrast in both light and dark modes.
**Changes:**
  Sidebar.svelte: text-[#FF8800] dark:text-[#FF8800] font-medium -> text-black dark:text-black font-bold
  Folder.svelte:  buttonClassName: text-[#FF8800] dark:text-[#FF8800] -> text-black dark:text-black font-bold
  Folder.svelte:  button: font-medium -> font-bold
**Rebuild required:** yes — npm run build


### Change 11 — Subsection headers: black -> brand gray #ECECEC
**Files:** src/lib/components/layout/Sidebar.svelte, src/lib/components/common/Folder.svelte
**Reason:** Black headers looked poor on green. Brand gray #ECECEC provides
softer contrast that fits the overall aesthetic.
**Changes:**
  text-black dark:text-black -> text-[#ECECEC] dark:text-[#ECECEC] (both files)
**Rebuild required:** yes — npm run build


### Change 12 — Subsection headers: revert font size to text-xs
**Files:** src/lib/components/layout/Sidebar.svelte, src/lib/components/common/Folder.svelte
**Reason:** text-sm made headers look oversized compared to chat titles.
Reverted to original text-xs. Color (#ECECEC) and font-bold retained.
**Changes:**
  text-sm -> text-xs (both files, header labels only)
**Rebuild required:** yes — npm run build

