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
