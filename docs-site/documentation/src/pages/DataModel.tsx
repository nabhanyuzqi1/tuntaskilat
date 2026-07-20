import { DocHeader, DocPage, H2, H3, P, FieldList, Code, PrevNext } from '../components/Kit'
import { COLLECTIONS } from '../data/collections'

const TOC = COLLECTIONS.map((c) => ({ id: c.id, label: c.path.split('/')[0] }))

export default function DataModel() {
  return (
    <DocPage toc={TOC}>
      <DocHeader
        eyebrow="API Reference"
        title="Data Model"
        description="Every Firestore collection Tuntaskilat writes to — field names, types, and enum values, sourced directly from packages/tk_core/lib/models/."
      />
      <P>
        Model source files live in <Code>packages/tk_core/lib/models/</Code>{' '}
        — one Dart class per collection, each with typed{' '}
        <Code>fromMap()</Code>/<Code>toMap()</Code> so every read/write goes
        through the same shape.
      </P>

      {COLLECTIONS.map((c) => (
        <div key={c.id}>
          <H2 id={c.id}>{c.path}</H2>
          <p className="mb-1 font-mono text-[12px] text-primary">{c.model}</p>
          <P>{c.desc}</P>
          <FieldList items={c.fields} />
          {c.enums && c.enums.length > 0 && (
            <>
              <H3 id={`${c.id}-enums`}>Enums</H3>
              <FieldList items={c.enums.map((e) => ({ name: e.name, type: 'enum', desc: e.values }))} />
            </>
          )}
          {c.note && <P>{c.note}</P>}
        </div>
      ))}

      <PrevNext
        prev={{ to: '/architecture', label: 'Architecture' }}
        next={{ to: '/functions', label: 'Cloud Functions' }}
      />
    </DocPage>
  )
}
