const VARIANTS = {
  primary:   'bg-brand-600 hover:bg-brand-700 text-white',
  secondary: 'bg-slate-700 hover:bg-slate-600 text-slate-100 dark:bg-slate-700 dark:hover:bg-slate-600',
  ghost:     'bg-transparent hover:bg-slate-800/50 text-slate-300 hover:text-slate-100',
  danger:    'bg-red-600 hover:bg-red-700 text-white',
  success:   'bg-emerald-600 hover:bg-emerald-700 text-white',
}
const SIZES = {
  sm: 'px-3 py-1.5 text-sm',
  md: 'px-4 py-2 text-sm',
  lg: 'px-6 py-3 text-base',
}

export function Button({ children, variant = 'primary', size = 'md', className = '', ...props }) {
  return (
    <button
      className={`${VARIANTS[variant]} ${SIZES[size]} rounded-lg font-medium transition-colors disabled:opacity-50 disabled:cursor-not-allowed inline-flex items-center gap-2 ${className}`}
      {...props}
    >
      {children}
    </button>
  )
}
