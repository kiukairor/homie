// frontend/src/components/AddItemForm.jsx
import { useState } from 'react'
import { Plus } from 'lucide-react'
import { Card, CardContent } from './ui/card'
import { Button } from './ui/button'
import { Input } from './ui/input'

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
