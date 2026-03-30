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
