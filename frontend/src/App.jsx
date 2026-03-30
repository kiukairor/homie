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
