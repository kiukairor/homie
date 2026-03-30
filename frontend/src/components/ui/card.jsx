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
