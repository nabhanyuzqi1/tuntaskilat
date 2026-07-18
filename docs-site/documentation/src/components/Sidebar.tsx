import { NavLink } from 'react-router-dom'
import { NAV } from '../nav'

export default function Sidebar({ onNavigate }: { onNavigate?: () => void }) {
  return (
    <nav className="flex h-full flex-col gap-6 overflow-y-auto px-4 py-6">
      {NAV.map((group) => (
        <div key={group.title}>
          <p className="mb-2 px-2 text-[11px] font-bold uppercase tracking-wider text-white/35">
            {group.title}
          </p>
          <ul className="space-y-0.5">
            {group.items.map((item) => (
              <li key={item.to}>
                <NavLink
                  to={item.to}
                  end={item.to === '/'}
                  onClick={onNavigate}
                  className={({ isActive }) =>
                    `block rounded-lg px-2.5 py-1.5 text-[13px] font-medium transition-colors ${
                      isActive
                        ? 'bg-primary/20 text-white'
                        : 'text-white/60 hover:bg-white/5 hover:text-white/90'
                    }`
                  }
                >
                  {item.label}
                </NavLink>
              </li>
            ))}
          </ul>
        </div>
      ))}
    </nav>
  )
}
