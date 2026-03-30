# Homie UI Redesign — Spec

**Date:** 2026-03-30
**Status:** Approved

---

## Goal

Replace the current inline-style React UI with a modern, mobile-first PWA design using Tailwind CSS and shadcn/ui. Target aesthetic: Todoist / Apple Reminders — clean, warm, fast.

---

## Stack Additions

| Package | Purpose |
|---------|---------|
| `tailwindcss` + `postcss` + `autoprefixer` | Utility CSS |
| `@tailwindcss/typography` (optional) | Not needed for this scope |
| shadcn/ui (manual copy-paste of primitives) | Card, Button, Input, Select, Checkbox, Badge |
| `lucide-react` | Icons (ShoppingCart, CheckCircle2, Plus, Trash2) |
| Inter (Google Fonts via CSS `@import`) | Typography |

shadcn/ui components are copied into `src/components/ui/` as source files (not an npm package). Run `npx shadcn@latest init` then add individual components.

---

## Color System

Defined as CSS custom properties in `src/index.css`:

```css
:root {
  --coral:       #F26B5B;   /* primary accent */
  --coral-light: #FEF0EE;   /* badge bg, hover tint */
  --surface:     #FAFAF9;   /* page background — warm off-white */
  --card:        #FFFFFF;
  --text:        #1C1917;   /* stone-900 */
}
```

Tailwind config extends these as `colors.coral`, `colors.coral-light`, `colors.surface`.

---

## Typography

- **Font:** Inter, loaded via `@import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600&display=swap')` in `index.css`
- **Base:** `font-family: 'Inter', sans-serif` on `body`
- Item names: `font-medium`
- Category headers: `text-xs font-semibold uppercase tracking-widest text-stone-400`
- Metadata (qty/unit): `text-sm text-stone-400`

---

## Layout

Full-height mobile shell (no horizontal scroll, max-w-lg centered on desktop):

```
┌─────────────────────────┐
│  Header (sticky, top)   │   "Homie" wordmark + unchecked count badge
├─────────────────────────┤
│                         │
│  Scrollable item feed   │   pb-[180px] to clear sticky card + nav
│                         │
│  [Empty state]          │   shown when active tab has no items
│                         │
├─────────────────────────┤
│  Add item card (sticky) │   bottom: 64px (above nav)
├─────────────────────────┤
│  Bottom nav (fixed)     │   h-16, List | Checked tabs
└─────────────────────────┘
```

---

## Components

### `Header`

- Fixed/sticky top, white bg, `border-b border-stone-100`
- Left: "Homie" in `text-xl font-semibold text-stone-900`
- Right: coral `Badge` showing unchecked item count (hidden at 0)

### `AddItemForm`

Sticky above bottom nav (`fixed bottom-16 inset-x-0`), rendered only when `activeTab === 'list'`.

shadcn `Card` with `shadow-lg rounded-t-2xl`:
- Row 1: `Input` for name (placeholder "Add an item…", autofocus on mobile tap)
- Row 2 (inline): qty `Input` (w-16), unit `Input` (w-20), category `Select` (flex-1), coral `Button` with `Plus` icon

Category options: produce, dairy, meat, bakery, frozen, drinks, other.

### `ItemList`

- Items grouped by category (existing logic kept)
- Category header: `text-xs font-semibold uppercase tracking-widest text-stone-400 px-4 pt-4 pb-1`
- No card wrapper around groups — flat list, breathing room between categories

### `ItemRow`

- Full-width row: `flex items-center gap-3 px-4 py-3`
- `Checkbox` with `accent-[--coral]` / shadcn checked state styled coral
- Item name (`font-medium`, `line-through text-stone-400` when checked)
- qty + unit in `text-sm text-stone-400` (e.g. "2 kg")
- Category `Badge` (`bg-coral-light text-coral text-xs`, shown only in Checked tab or if user wants)
- `Trash2` icon button: `text-stone-300 hover:text-red-400 transition-colors`, appears always on mobile (no hover-only)
- Checked rows get `opacity-60 transition-opacity`

### `EmptyState`

Centered in the scrollable area:
- `ShoppingCart` icon, 56px, `text-stone-200`
- `"Your list is empty"` — `text-stone-400 font-medium mt-3`
- Sub-text differs by tab:
  - List tab: `"Add your first item below"`
  - Checked tab: `"Nothing checked off yet"`

### `BottomNav`

Fixed bottom, full-width, `h-16 bg-white border-t border-stone-100`:
- Two equal tabs: **List** (ShoppingCart) and **Checked** (CheckCircle2)
- Active tab: `text-coral` + 2px top border coral indicator
- Inactive tab: `text-stone-400`
- Checked tab renders a small count badge (coral, top-right of icon) when checked items > 0

---

## App.jsx Changes

```
activeTab: 'list' | 'checked'   ← new state
```

- `list` tab shows `items.filter(i => !i.checked)` + AddItemForm
- `checked` tab shows `items.filter(i => i.checked)` + "Clear all" button in header area
- All CRUD handlers remain unchanged

---

## File Structure After

```
src/
  index.css                      ← Tailwind directives, CSS vars, Inter import
  main.jsx                       ← unchanged (add Tailwind class to root if needed)
  App.jsx                        ← add activeTab state, tab-based filtering
  api.js                         ← unchanged
  components/
    ui/                          ← shadcn primitives
      button.jsx
      card.jsx
      input.jsx
      select.jsx
      checkbox.jsx
      badge.jsx
    Header.jsx                   ← new
    AddItemForm.jsx               ← rewritten
    ItemList.jsx                  ← rewritten
    ItemRow.jsx                   ← rewritten
    EmptyState.jsx                ← new
    BottomNav.jsx                 ← new
tailwind.config.js               ← new
postcss.config.js                ← new
```

---

## Not In Scope

- Dark mode
- Animations beyond Tailwind transitions
- Drag-to-reorder
- Offline/sync indicator
- PWA icon updates
- Backend changes

---

## Success Criteria

1. App renders correctly on a 390px-wide viewport (iPhone 14)
2. All existing CRUD operations work unchanged
3. Bottom nav switches between List and Checked views
4. Empty state shown when a tab has no items
5. TLS / production build passes (`npm run build` succeeds)
