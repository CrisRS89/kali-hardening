export function Card({ children, className = '', ...props }) {
  return (
    <div
      className={`bg-slate-800 dark:bg-slate-800 border border-slate-700 rounded-xl p-4 shadow-lg ${className}`}
      {...props}
    >
      {children}
    </div>
  )
}
