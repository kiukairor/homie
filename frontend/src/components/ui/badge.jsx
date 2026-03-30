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
