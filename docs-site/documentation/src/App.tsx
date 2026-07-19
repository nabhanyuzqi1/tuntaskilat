import { Routes, Route, Outlet } from 'react-router-dom'
import DocLayout from './components/DocLayout'
import Home from './pages/Home'
import GettingStarted from './pages/GettingStarted'
import Architecture from './pages/Architecture'
import DataModel from './pages/DataModel'
import Functions from './pages/Functions'
import SecurityRules from './pages/SecurityRules'
import BusinessLogic from './pages/BusinessLogic'
import Payments from './pages/Payments'
import Ai from './pages/Ai'
import Notifications from './pages/Notifications'
import Deployment from './pages/Deployment'
import Changelog from './pages/Changelog'
import Print from './pages/Print'

function SiteLayout() {
  return (
    <DocLayout>
      <Outlet />
    </DocLayout>
  )
}

function App() {
  return (
    <Routes>
      <Route element={<SiteLayout />}>
        <Route path="/" element={<Home />} />
        <Route path="/getting-started" element={<GettingStarted />} />
        <Route path="/architecture" element={<Architecture />} />
        <Route path="/data-model" element={<DataModel />} />
        <Route path="/functions" element={<Functions />} />
        <Route path="/security-rules" element={<SecurityRules />} />
        <Route path="/business-logic" element={<BusinessLogic />} />
        <Route path="/payments" element={<Payments />} />
        <Route path="/ai" element={<Ai />} />
        <Route path="/notifications" element={<Notifications />} />
        <Route path="/deployment" element={<Deployment />} />
        <Route path="/changelog" element={<Changelog />} />
      </Route>
      {/* /print is a standalone print-optimized document — no site chrome */}
      <Route path="/print" element={<Print />} />
    </Routes>
  )
}

export default App
