import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import './styles.css'
import Aplicacion from './App.tsx'

createRoot(document.getElementById('aplicacion')!).render(
  <StrictMode>
    <Aplicacion />
  </StrictMode>,
)
