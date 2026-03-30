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
