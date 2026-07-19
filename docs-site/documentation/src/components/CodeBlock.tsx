import { useState } from 'react'
import { Highlight, themes, type Language } from 'prism-react-renderer'
import { Check, Copy } from 'lucide-react'

export default function CodeBlock({
  code,
  language = 'typescript',
  title,
}: {
  code: string
  language?: Language
  title?: string
}) {
  const [copied, setCopied] = useState(false)

  const onCopy = async () => {
    await navigator.clipboard.writeText(code.trim())
    setCopied(true)
    setTimeout(() => setCopied(false), 1600)
  }

  return (
    <div className="overflow-hidden rounded-xl border border-[color:var(--border)] bg-[color:var(--bg-code)]">
      {title && (
        <div className="flex items-center justify-between border-b border-[color:var(--border)] px-4 py-2">
          <span className="font-mono text-[11px] text-[color:var(--fg-muted)]">{title}</span>
        </div>
      )}
      <div className="relative">
        <button
          onClick={onCopy}
          className="absolute right-3 top-3 z-10 flex h-7 w-7 items-center justify-center rounded-md border border-white/10 bg-white/5 text-white/60 transition-colors hover:bg-white/10 hover:text-white print:hidden"
          aria-label="Salin kode"
        >
          {copied ? <Check size={13} /> : <Copy size={13} />}
        </button>
        <Highlight theme={themes.nightOwl} code={code.trim()} language={language}>
          {({ className, style, tokens, getLineProps, getTokenProps }) => (
            <pre
              className={`${className} overflow-x-auto p-4 text-[12.5px] leading-relaxed`}
              style={{ ...style, background: 'transparent' }}
            >
              {tokens.map((line, i) => (
                <div key={i} {...getLineProps({ line })}>
                  {line.map((token, key) => (
                    <span key={key} {...getTokenProps({ token })} />
                  ))}
                </div>
              ))}
            </pre>
          )}
        </Highlight>
      </div>
    </div>
  )
}
