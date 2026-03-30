// frontend/src/components/ui/input.jsx
import { forwardRef } from 'react'
import { cn } from '../../lib/utils'

export const Input = forwardRef(({ className, ...props }, ref) => {
  return (
    <input
      ref={ref}
      className={cn(
        'flex h-9 w-full rounded-lg border border-stone-200 bg-white px-3 py-1 text-sm text-stone-900 placeholder:text-stone-400 focus:outline-none focus:ring-2 focus:ring-coral/30 focus:border-coral transition-colors disabled:opacity-50',
        className
      )}
      {...props}
    />
  )
})
Input.displayName = 'Input'
