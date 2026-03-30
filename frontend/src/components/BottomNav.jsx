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
