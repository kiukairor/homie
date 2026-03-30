# Homie UI Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace inline-style React UI with a mobile-first Tailwind + shadcn/ui redesign featuring a coral theme, bottom nav (List/Checked tabs), card-based input, and Inter typography.

**Architecture:** All changes are frontend-only (`frontend/`). New shadcn UI primitives go in `src/components/ui/`. Feature components are rewritten in-place. `App.jsx` gains `activeTab` state to filter items by checked/unchecked. No backend changes.

**Tech Stack:** Tailwind CSS v3, lucide-react, clsx, tailwind-merge, shadcn-inspired hand-written UI primitives (no Radix UI), Inter via Google Fonts.

---

## File Map

| Action | Path | Responsibility |
|--------|------|----------------|
| Create | `frontend/tailwind.config.js` | Tailwind theme — coral colors, Inter font |
| Create | `frontend/postcss.config.js` | PostCSS plugins |
| Modify | `frontend/src/index.css` | Tailwind directives, CSS vars, Inter import |
| Create | `frontend/src/lib/utils.js` | `cn()` helper (clsx + tailwind-merge) |
| Create | `frontend/src/components/ui/button.jsx` | Coral-themed Button |
| Create | `frontend/src/components/ui/card.jsx` | Card + CardContent |
| Create | `frontend/src/components/ui/input.jsx` | Styled Input |
| Create | `frontend/src/components/ui/badge.jsx` | Coral Badge |
| Create | `frontend/src/components/Header.jsx` | Sticky header with item count |
| Create | `frontend/src/components/EmptyState.jsx` | Icon + message for empty tabs |
| Create | `frontend/src/components/BottomNav.jsx` | Fixed bottom nav, List/Checked tabs |
| Rewrite | `frontend/src/components/AddItemForm.jsx` | Card-based form, sticky above nav |
| Rewrite | `frontend/src/components/ItemRow.jsx` | Checkbox + Trash2 icon |
| Rewrite | `frontend/src/components/ItemList.jsx` | Category groups + EmptyState |
| Rewrite | `frontend/src/App.jsx` | activeTab state, tab filtering |

---

## Task 1: Install dependencies

**Files:**
- Modify: `frontend/package.json` (via npm install)

- [ ] **Step 1: Install Tailwind and CSS tooling**

```bash
cd /home/ubuntu/src/frontend
npm install -D tailwindcss postcss autoprefixer
```

Expected: packages added to `devDependencies`.

- [ ] **Step 2: Install icon and utility libraries**

```bash
npm install lucide-react clsx tailwind-merge
```

Expected: packages added to `dependencies`.

- [ ] **Step 3: Verify installs**

```bash
npx tailwindcss --version
node -e "require('lucide-react'); console.log('lucide ok')"
node -e "require('clsx'); require('tailwind-merge'); console.log('utils ok')"
```

Expected: version printed, both `ok` lines appear.

---

## Task 2: Configure Tailwind and PostCSS

**Files:**
- Create: `frontend/tailwind.config.js`
- Create: `frontend/postcss.config.js`

- [ ] **Step 1: Create `tailwind.config.js`**

```js
// frontend/tailwind.config.js
/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{js,jsx,ts,tsx}'],
  theme: {
    extend: {
      colors: {
        coral: '#F26B5B',
        'coral-light': '#FEF0EE',
        surface: '#FAFAF9',
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', 'sans-serif'],
      },
    },
  },
  plugins: [],
}
```

- [ ] **Step 2: Create `postcss.config.js`**

```js
// frontend/postcss.config.js
export default {
  plugins: {
    tailwindcss: {},
    autoprefixer: {},
  },
}
```

- [ ] **Step 3: Verify Tailwind can process a file**

```bash
cd /home/ubuntu/src/frontend
echo "@tailwind base; @tailwind components; @tailwind utilities;" | npx tailwindcss --stdin -o /tmp/tw-test.css 2>&1 | head -5
```

Expected: no errors, output line shows bytes written.

- [ ] **Step 4: Commit**

```bash
cd /home/ubuntu/src/frontend
git add tailwind.config.js postcss.config.js package.json package-lock.json
git commit -m "build: install Tailwind CSS, lucide-react, clsx, tailwind-merge"
```

---

## Task 3: Set up CSS foundation and utility

**Files:**
- Modify: `frontend/src/index.css`
- Create: `frontend/src/lib/utils.js`

- [ ] **Step 1: Replace `src/index.css`**

```css
/* frontend/src/index.css */
@import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600&display=swap');

@tailwind base;
@tailwind components;
@tailwind utilities;

@layer base {
  :root {
    --coral: #F26B5B;
    --coral-light: #FEF0EE;
    --surface: #FAFAF9;
  }

  * {
    box-sizing: border-box;
  }

  body {
    @apply bg-surface text-stone-900 font-sans antialiased;
    margin: 0;
  }
}
```

- [ ] **Step 2: Create `src/lib/utils.js`**

```js
// frontend/src/lib/utils.js
import { clsx } from 'clsx'
import { twMerge } from 'tailwind-merge'

export function cn(...inputs) {
  return twMerge(clsx(inputs))
}
```

- [ ] **Step 3: Commit**

```bash
cd /home/ubuntu/src/frontend
git add src/index.css src/lib/utils.js
git commit -m "style: add Tailwind directives, CSS vars, Inter font, cn() utility"
```

---

## Task 4: Create shadcn-style UI primitives

**Files:**
- Create: `frontend/src/components/ui/button.jsx`
- Create: `frontend/src/components/ui/card.jsx`
- Create: `frontend/src/components/ui/input.jsx`
- Create: `frontend/src/components/ui/badge.jsx`

- [ ] **Step 1: Create `src/components/ui/button.jsx`**

```jsx
// frontend/src/components/ui/button.jsx
import { cn } from '../../lib/utils'

export function Button({ className, variant = 'default', size = 'default', ...props }) {
  return (
    <button
      className={cn(
        'inline-flex items-center justify-center rounded-lg font-medium transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-coral/50 disabled:opacity-50 disabled:pointer-events-none',
        variant === 'default' && 'bg-coral text-white hover:bg-coral/90',
        variant === 'ghost' && 'bg-transparent hover:bg-stone-100 text-stone-600',
        variant === 'outline' && 'border border-stone-200 bg-white hover:bg-stone-50 text-stone-700',
        size === 'default' && 'h-9 px-4 text-sm',
        size === 'sm' && 'h-8 px-3 text-xs',
        size === 'lg' && 'h-10 px-6 text-base',
        size === 'icon' && 'h-9 w-9 p-0',
        className
      )}
      {...props}
    />
  )
}
```

- [ ] **Step 2: Create `src/components/ui/card.jsx`**

```jsx
// frontend/src/components/ui/card.jsx
import { cn } from '../../lib/utils'

export function Card({ className, ...props }) {
  return (
    <div
      className={cn('rounded-2xl bg-white shadow-sm border border-stone-100', className)}
      {...props}
    />
  )
}

export function CardContent({ className, ...props }) {
  return <div className={cn('p-3', className)} {...props} />
}
```

- [ ] **Step 3: Create `src/components/ui/input.jsx`**

```jsx
// frontend/src/components/ui/input.jsx
import { forwardRef } from 'react'
import { cn } from '../../lib/utils'

export const Input = forwardRef(({ className, ...props }, ref) => {
  return (
    <input
      ref={ref}
      className={cn(
        'flex h-9 w-full rounded-lg border border-stone-200 bg-white px-3 py-1 text-sm text-stone-900 placeholder:text-stone-400 focus:outline-none focus:ring-2 focus:ring-coral/30 focus:border-coral transition-colors disabled:opacity-50',
        className
      )}
      {...props}
    />
  )
})
Input.displayName = 'Input'
```

- [ ] **Step 4: Create `src/components/ui/badge.jsx`**

```jsx
// frontend/src/components/ui/badge.jsx
import { cn } from '../../lib/utils'

export function Badge({ className, variant = 'default', ...props }) {
  return (
    <span
      className={cn(
        'inline-flex items-center rounded-full px-2 py-0.5 text-xs font-medium',
        variant === 'default' && 'bg-coral-light text-coral',
        variant === 'secondary' && 'bg-stone-100 text-stone-600',
        className
      )}
      {...props}
    />
  )
}
```

- [ ] **Step 5: Commit**

```bash
cd /home/ubuntu/src/frontend
git add src/components/ui/
git commit -m "feat: add shadcn-style UI primitives (Button, Card, Input, Badge)"
```

---

## Task 5: Create Header and EmptyState components

**Files:**
- Create: `frontend/src/components/Header.jsx`
- Create: `frontend/src/components/EmptyState.jsx`

- [ ] **Step 1: Create `src/components/Header.jsx`**

```jsx
// frontend/src/components/Header.jsx
import { Badge } from './ui/badge'

export function Header({ itemCount, onClearChecked, activeTab }) {
  return (
    <header className="sticky top-0 z-10 bg-white/80 backdrop-blur-sm border-b border-stone-100 px-4 h-14 flex items-center justify-between">
      <h1 className="text-xl font-semibold text-stone-900 tracking-tight">Homie</h1>
      <div className="flex items-center gap-2">
        {activeTab === 'list' && itemCount > 0 && (
          <Badge>{itemCount} item{itemCount !== 1 ? 's' : ''}</Badge>
        )}
        {activeTab === 'checked' && itemCount > 0 && (
          <button
            onClick={onClearChecked}
            className="text-sm text-red-400 hover:text-red-500 font-medium transition-colors"
          >
            Clear all
          </button>
        )}
      </div>
    </header>
  )
}
```

- [ ] **Step 2: Create `src/components/EmptyState.jsx`**

```jsx
// frontend/src/components/EmptyState.jsx
import { ShoppingCart, CheckCircle2 } from 'lucide-react'

export function EmptyState({ tab }) {
  const isList = tab === 'list'
  const Icon = isList ? ShoppingCart : CheckCircle2
  return (
    <div className="flex flex-col items-center justify-center py-20 px-4 text-center">
      <Icon className="w-14 h-14 text-stone-200 mb-4" strokeWidth={1.5} />
      <p className="text-stone-400 font-medium">
        {isList ? 'Your list is empty' : 'Nothing checked off yet'}
      </p>
      <p className="text-stone-300 text-sm mt-1">
        {isList ? 'Add your first item below' : 'Check off items from your list'}
      </p>
    </div>
  )
}
```

- [ ] **Step 3: Commit**

```bash
cd /home/ubuntu/src/frontend
git add src/components/Header.jsx src/components/EmptyState.jsx
git commit -m "feat: add Header and EmptyState components"
```

---

## Task 6: Create BottomNav component

**Files:**
- Create: `frontend/src/components/BottomNav.jsx`

- [ ] **Step 1: Create `src/components/BottomNav.jsx`**

```jsx
// frontend/src/components/BottomNav.jsx
import { ShoppingCart, CheckCircle2 } from 'lucide-react'
import { cn } from '../lib/utils'

const TABS = [
  { id: 'list',    label: 'List',    Icon: ShoppingCart  },
  { id: 'checked', label: 'Checked', Icon: CheckCircle2 },
]

export function BottomNav({ activeTab, onTabChange, checkedCount }) {
  return (
    <nav className="fixed bottom-0 inset-x-0 h-16 bg-white border-t border-stone-100 flex z-20 max-w-lg mx-auto left-0 right-0">
      {TABS.map(({ id, label, Icon }) => (
        <button
          key={id}
          onClick={() => onTabChange(id)}
          className={cn(
            'flex-1 flex flex-col items-center justify-center gap-1 relative transition-colors',
            activeTab === id ? 'text-coral' : 'text-stone-400 hover:text-stone-600'
          )}
        >
          {activeTab === id && (
            <span className="absolute top-0 left-1/2 -translate-x-1/2 w-8 h-0.5 bg-coral rounded-full" />
          )}
          <div className="relative">
            <Icon className="w-5 h-5" strokeWidth={1.8} />
            {id === 'checked' && checkedCount > 0 && (
              <span className="absolute -top-1.5 -right-2 bg-coral text-white text-[10px] font-bold rounded-full w-4 h-4 flex items-center justify-center leading-none">
                {checkedCount > 9 ? '9+' : checkedCount}
              </span>
            )}
          </div>
          <span className="text-[11px] font-medium">{label}</span>
        </button>
      ))}
    </nav>
  )
}
```

- [ ] **Step 2: Commit**

```bash
cd /home/ubuntu/src/frontend
git add src/components/BottomNav.jsx
git commit -m "feat: add BottomNav with List/Checked tabs and checked count badge"
```

---

## Task 7: Rewrite AddItemForm

**Files:**
- Modify: `frontend/src/components/AddItemForm.jsx`

- [ ] **Step 1: Rewrite `src/components/AddItemForm.jsx`**

```jsx
// frontend/src/components/AddItemForm.jsx
import { useState } from 'react'
import { Plus } from 'lucide-react'
import { Card, CardContent } from './ui/card'
import { Button } from './ui/button'
import { Input } from './ui/input'
import { cn } from '../lib/utils'

const CATEGORIES = ['produce', 'dairy', 'meat', 'bakery', 'frozen', 'drinks', 'other']

export function AddItemForm({ onAdd }) {
  const [name, setName] = useState('')
  const [quantity, setQuantity] = useState('')
  const [unit, setUnit] = useState('')
  const [category, setCategory] = useState('other')

  const handleSubmit = (e) => {
    e.preventDefault()
    if (!name.trim()) return
    onAdd({
      name: name.trim(),
      quantity: quantity || undefined,
      unit: unit || undefined,
      category,
    })
    setName('')
    setQuantity('')
    setUnit('')
    setCategory('other')
  }

  return (
    <div className="fixed bottom-16 inset-x-0 z-10 px-3 pb-2 max-w-lg mx-auto left-0 right-0">
      <Card className="shadow-lg border-stone-200">
        <CardContent>
          <form onSubmit={handleSubmit} className="flex flex-col gap-2">
            <Input
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder="Add an item…"
              autoComplete="off"
              required
            />
            <div className="flex gap-2">
              <Input
                className="w-16 shrink-0"
                value={quantity}
                onChange={(e) => setQuantity(e.target.value)}
                placeholder="Qty"
              />
              <Input
                className="w-20 shrink-0"
                value={unit}
                onChange={(e) => setUnit(e.target.value)}
                placeholder="Unit"
              />
              <select
                value={category}
                onChange={(e) => setCategory(e.target.value)}
                className="flex-1 h-9 rounded-lg border border-stone-200 bg-white px-2 text-sm text-stone-700 focus:outline-none focus:ring-2 focus:ring-coral/30 focus:border-coral transition-colors"
              >
                {CATEGORIES.map((c) => (
                  <option key={c} value={c}>
                    {c.charAt(0).toUpperCase() + c.slice(1)}
                  </option>
                ))}
              </select>
              <Button type="submit" size="icon" className="shrink-0" aria-label="Add item">
                <Plus className="w-4 h-4" />
              </Button>
            </div>
          </form>
        </CardContent>
      </Card>
    </div>
  )
}
```

- [ ] **Step 2: Commit**

```bash
cd /home/ubuntu/src/frontend
git add src/components/AddItemForm.jsx
git commit -m "feat: rewrite AddItemForm with Card, Input, Button (shadcn/Tailwind)"
```

---

## Task 8: Rewrite ItemRow and ItemList

**Files:**
- Modify: `frontend/src/components/ItemRow.jsx`
- Modify: `frontend/src/components/ItemList.jsx`

- [ ] **Step 1: Rewrite `src/components/ItemRow.jsx`**

```jsx
// frontend/src/components/ItemRow.jsx
import { Trash2 } from 'lucide-react'
import { Badge } from './ui/badge'
import { cn } from '../lib/utils'

export function ItemRow({ item, onToggle, onDelete, showCategory }) {
  return (
    <div className="flex items-center gap-3 px-4 py-3">
      <input
        type="checkbox"
        checked={item.checked}
        onChange={() => onToggle(item.id, item.checked)}
        className="h-5 w-5 rounded border-stone-300 accent-coral shrink-0 cursor-pointer"
        aria-label={`Mark ${item.name} as ${item.checked ? 'unchecked' : 'checked'}`}
      />
      <div className="flex-1 min-w-0">
        <span
          className={cn(
            'font-medium text-stone-900 block truncate transition-colors duration-200',
            item.checked && 'line-through text-stone-400'
          )}
        >
          {item.name}
        </span>
        {(item.quantity || item.unit) && (
          <span className="text-sm text-stone-400">
            {[item.quantity, item.unit].filter(Boolean).join('\u00a0')}
          </span>
        )}
      </div>
      {showCategory && item.category && item.category !== 'other' && (
        <Badge className="shrink-0 capitalize">{item.category}</Badge>
      )}
      <button
        onClick={() => onDelete(item.id)}
        className="text-stone-300 hover:text-red-400 transition-colors shrink-0 p-1 -mr-1"
        aria-label={`Delete ${item.name}`}
      >
        <Trash2 className="w-4 h-4" />
      </button>
    </div>
  )
}
```

- [ ] **Step 2: Rewrite `src/components/ItemList.jsx`**

```jsx
// frontend/src/components/ItemList.jsx
import { ItemRow } from './ItemRow'
import { EmptyState } from './EmptyState'

export function ItemList({ items, activeTab, onToggle, onDelete }) {
  if (items.length === 0) {
    return <EmptyState tab={activeTab} />
  }

  const grouped = items.reduce((acc, item) => {
    const cat = item.category || 'other'
    if (!acc[cat]) acc[cat] = []
    acc[cat].push(item)
    return acc
  }, {})

  const showCategory = activeTab === 'checked'

  return (
    <div>
      {Object.entries(grouped).map(([category, categoryItems]) => (
        <div key={category}>
          <div className="px-4 pt-4 pb-1">
            <span className="text-xs font-semibold uppercase tracking-widest text-stone-400">
              {category}
            </span>
          </div>
          {categoryItems.map((item) => (
            <ItemRow
              key={item.id}
              item={item}
              onToggle={onToggle}
              onDelete={onDelete}
              showCategory={showCategory}
            />
          ))}
        </div>
      ))}
    </div>
  )
}
```

- [ ] **Step 3: Commit**

```bash
cd /home/ubuntu/src/frontend
git add src/components/ItemRow.jsx src/components/ItemList.jsx
git commit -m "feat: rewrite ItemRow (Checkbox + Trash2) and ItemList with EmptyState"
```

---

## Task 9: Rewrite App.jsx

**Files:**
- Modify: `frontend/src/App.jsx`

- [ ] **Step 1: Rewrite `src/App.jsx`**

```jsx
// frontend/src/App.jsx
import { useState, useEffect, useCallback } from 'react'
import { listItems, createItem, updateItem, deleteItem, deleteChecked } from './api'
import { Header } from './components/Header'
import { ItemList } from './components/ItemList'
import { AddItemForm } from './components/AddItemForm'
import { BottomNav } from './components/BottomNav'

export default function App() {
  const [items, setItems] = useState([])
  const [error, setError] = useState(null)
  const [loading, setLoading] = useState(true)
  const [activeTab, setActiveTab] = useState('list')

  const loadItems = useCallback(async () => {
    try {
      const data = await listItems()
      setItems(data)
    } catch (e) {
      setError(e.message)
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => { loadItems() }, [loadItems])

  const handleAdd = async (item) => {
    try {
      const created = await createItem(item)
      setItems((prev) => [...prev, created])
    } catch (e) {
      setError(e.message)
    }
  }

  const handleToggle = async (id, checked) => {
    try {
      const updated = await updateItem(id, { checked: !checked })
      setItems((prev) => prev.map((i) => (i.id === updated.id ? updated : i)))
    } catch (e) {
      setError(e.message)
    }
  }

  const handleDelete = async (id) => {
    try {
      await deleteItem(id)
      setItems((prev) => prev.filter((i) => i.id !== id))
    } catch (e) {
      setError(e.message)
    }
  }

  const handleClearChecked = async () => {
    try {
      await deleteChecked()
      setItems((prev) => prev.filter((i) => !i.checked))
    } catch (e) {
      setError(e.message)
    }
  }

  const checkedCount = items.filter((i) => i.checked).length
  const uncheckedCount = items.filter((i) => !i.checked).length
  const visibleItems = items.filter((i) => (activeTab === 'list' ? !i.checked : i.checked))

  return (
    <div className="min-h-screen bg-surface">
      <div className="max-w-lg mx-auto relative">
        <Header
          itemCount={activeTab === 'list' ? uncheckedCount : checkedCount}
          onClearChecked={handleClearChecked}
          activeTab={activeTab}
        />

        <main className="pb-40">
          {loading ? (
            <div className="flex justify-center py-20">
              <div className="w-6 h-6 border-2 border-coral border-t-transparent rounded-full animate-spin" />
            </div>
          ) : (
            <ItemList
              items={visibleItems}
              activeTab={activeTab}
              onToggle={handleToggle}
              onDelete={handleDelete}
            />
          )}
        </main>

        {error && (
          <div className="fixed top-14 inset-x-0 z-30 px-4 pt-2">
            <div className="bg-red-50 border border-red-200 text-red-600 text-sm rounded-lg px-4 py-3 max-w-lg mx-auto flex items-center justify-between">
              <span>{error}</span>
              <button
                onClick={() => setError(null)}
                className="ml-3 font-bold text-red-400 hover:text-red-600"
                aria-label="Dismiss error"
              >
                ×
              </button>
            </div>
          </div>
        )}

        {activeTab === 'list' && <AddItemForm onAdd={handleAdd} />}

        <BottomNav
          activeTab={activeTab}
          onTabChange={setActiveTab}
          checkedCount={checkedCount}
        />
      </div>
    </div>
  )
}
```

- [ ] **Step 2: Commit**

```bash
cd /home/ubuntu/src/frontend
git add src/App.jsx
git commit -m "feat: rewrite App.jsx with activeTab state and redesigned layout"
```

---

## Task 10: Build verification and final checks

**Files:** None modified — verification only.

- [ ] **Step 1: Run production build**

```bash
cd /home/ubuntu/src/frontend
npm run build 2>&1
```

Expected: `✓ built in` with no errors. Vite outputs files to `dist/`.

- [ ] **Step 2: Check bundle for Tailwind classes**

```bash
grep -l "text-coral\|bg-coral\|text-stone" dist/assets/*.css
```

Expected: one CSS file listed — confirms Tailwind processed the custom colors.

- [ ] **Step 3: Run dev server smoke test (optional if on CI)**

```bash
npm run dev &
sleep 3
curl -s http://localhost:5173/ | grep -c "Homie\|div"
kill %1 2>/dev/null || true
```

Expected: number > 0 (HTML contains page content).

- [ ] **Step 4: Push to main and verify CI build**

```bash
cd /home/ubuntu/src
git push
```

Expected: GitHub Actions CI (`build.yml`) triggers, builds ARM64 Docker image, pushes to ghcr.io. Check at: `https://github.com/kiukairor/homie/actions`

- [ ] **Step 5: Force ArgoCD sync and verify pods**

```bash
kubectl rollout status deployment/frontend -n homie-prod --timeout=120s
```

Expected: `successfully rolled out` after ArgoCD picks up the new image (≤3 min).

- [ ] **Step 6: Smoke test production**

```bash
curl -s -o /dev/null -w "%{http_code}" https://homie.kiukairor.com/
```

Expected: `200`

- [ ] **Step 7: Update CLAUDE.md**

Add to the Phase 1 section:
```
> **UI redesigned (2026-03-30):** Tailwind CSS + shadcn-style components, coral theme,
> Inter font, bottom nav (List/Checked tabs), card-based AddItemForm, EmptyState with icons.
```

```bash
cd /home/ubuntu/src
git add CLAUDE.md
git commit -m "docs: note UI redesign in CLAUDE.md"
git push
```
