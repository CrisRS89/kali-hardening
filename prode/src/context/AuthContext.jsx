import { createContext, useContext, useState } from 'react'

const AuthContext = createContext(null)

const DEMO_USERS = [
  { id: 1, name: 'Cristian Sosa', email: 'admin@prode.com', password: 'admin123', role: 'admin' },
  { id: 2, name: 'Juan Pérez', email: 'juan@prode.com', password: '123456', role: 'participante' },
  { id: 3, name: 'María García', email: 'maria@prode.com', password: '123456', role: 'participante' },
]

export function AuthProvider({ children }) {
  const [user, setUser] = useState(() => {
    const saved = localStorage.getItem('prode-user')
    return saved ? JSON.parse(saved) : null
  })

  function login(email, password) {
    const found = DEMO_USERS.find(u => u.email === email && u.password === password)
    if (!found) return { error: 'Email o contraseña incorrectos' }
    const { password: _, ...safeUser } = found
    setUser(safeUser)
    localStorage.setItem('prode-user', JSON.stringify(safeUser))
    return { user: safeUser }
  }

  function register(name, email, password) {
    if (DEMO_USERS.find(u => u.email === email)) {
      return { error: 'El email ya está registrado' }
    }
    const newUser = { id: Date.now(), name, email, role: 'participante' }
    setUser(newUser)
    localStorage.setItem('prode-user', JSON.stringify(newUser))
    return { user: newUser }
  }

  function logout() {
    setUser(null)
    localStorage.removeItem('prode-user')
  }

  return (
    <AuthContext.Provider value={{ user, login, register, logout }}>
      {children}
    </AuthContext.Provider>
  )
}

export const useAuth = () => useContext(AuthContext)
