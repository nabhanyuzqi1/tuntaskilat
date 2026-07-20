import { Routes, Route, Outlet } from 'react-router-dom'
import Layout from './components/Layout'
import Home from './pages/Home'
import Pelanggan from './pages/Pelanggan'
import Kru from './pages/Kru'
import Admin from './pages/Admin'
import Faq from './pages/Faq'
import Cetak from './pages/Cetak'

function SiteLayout() {
  return (
    <Layout>
      <Outlet />
    </Layout>
  )
}

function App() {
  return (
    <Routes>
      <Route element={<SiteLayout />}>
        <Route path="/" element={<Home />} />
        <Route path="/pelanggan" element={<Pelanggan />} />
        <Route path="/kru" element={<Kru />} />
        <Route path="/admin" element={<Admin />} />
        <Route path="/faq" element={<Faq />} />
      </Route>
      {/* /cetak is a standalone print-optimized document — no site chrome */}
      <Route path="/cetak" element={<Cetak />} />
    </Routes>
  )
}

export default App
