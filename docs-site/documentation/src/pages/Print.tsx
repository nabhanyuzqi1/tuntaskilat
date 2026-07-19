import CoverPage from '../components/print/CoverPage'
import PrintToc from '../components/print/PrintToc'
import Home from './Home'
import GettingStarted from './GettingStarted'
import Architecture from './Architecture'
import DataModel from './DataModel'
import Functions from './Functions'
import SecurityRules from './SecurityRules'
import BusinessLogic from './BusinessLogic'
import Payments from './Payments'
import Ai from './Ai'
import Notifications from './Notifications'
import Deployment from './Deployment'
import Changelog from './Changelog'

const CHAPTERS = [
  Home,
  GettingStarted,
  Architecture,
  DataModel,
  Functions,
  SecurityRules,
  BusinessLogic,
  Payments,
  Ai,
  Notifications,
  Deployment,
  Changelog,
]

/**
 * Standalone print/PDF document — cover, table of contents, then every
 * reference chapter concatenated in reading order. Rendered without site
 * chrome (header/sidebar) and exported via headless Chrome (see docs-site
 * tooling / export-pdf.mjs).
 */
export default function Print() {
  return (
    <div className="bg-white text-[color:var(--fg)]" data-theme="light">
      <CoverPage />
      <PrintToc />
      {CHAPTERS.map((Chapter, i) => (
        <div key={i} className="print-chapter px-16 py-10">
          <Chapter />
        </div>
      ))}
    </div>
  )
}
