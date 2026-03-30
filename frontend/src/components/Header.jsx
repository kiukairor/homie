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
