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
