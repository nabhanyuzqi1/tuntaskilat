import { Routes, Route } from 'react-router-dom'
import Layout from './components/Layout'
import Home from './pages/Home'
import Pelanggan from './pages/Pelanggan'
import Kru from './pages/Kru'
import Admin from './pages/Admin'
import Faq from './pages/Faq'

function App() {
  return (
    <Layout>
      <Routes>
        <Route path="/" element={<Home />} />
        <Route path="/pelanggan" element={<Pelanggan />} />
        <Route path="/kru" element={<Kru />} />
        <Route path="/admin" element={<Admin />} />
        <Route path="/faq" element={<Faq />} />
      </Routes>
    </Layout>
  )
}

export default App
