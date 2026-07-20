const TANGGAL = new Date().toLocaleDateString('id-ID', {
  month: 'long',
  year: 'numeric',
})

export default function CoverPage() {
  return (
    <section className="print-cover relative flex h-[194mm] w-[285mm] flex-col overflow-hidden bg-primary-dark text-white print:h-[194mm] print:w-[285mm]">
      {/* Corporate geometric accent — flat shapes, no blur (print-safe) */}
      <div className="absolute inset-0">
        <div className="absolute -right-24 -top-32 h-[420px] w-[420px] rounded-full bg-primary/40" />
        <div className="absolute -bottom-40 -left-16 h-[360px] w-[360px] rounded-full bg-black/15" />
        <div className="absolute bottom-0 left-0 right-0 h-2 bg-accent" />
      </div>

      <div className="relative flex flex-1 flex-col items-center justify-center px-24 text-center">
        <img
          src="/brand/brandmark.webp"
          alt=""
          className="h-24 w-24 rounded-3xl bg-white/95 p-4 shadow-2xl"
        />
        <p className="mt-10 text-[13px] font-bold uppercase tracking-[0.35em] text-accent">
          Dokumen Resmi
        </p>
        <h1 className="mt-4 text-[64px] font-extrabold leading-[1.05] tracking-tight">
          Buku Panduan
        </h1>
        <h2 className="mt-1 text-[34px] font-bold tracking-tight text-white/85">
          Tuntaskilat
        </h2>
        <p className="mt-8 max-w-2xl text-[16px] leading-relaxed text-white/70">
          Panduan Lengkap Penggunaan Platform Jasa Kebersihan On-Demand — untuk
          Pelanggan, Kru, dan Admin
        </p>
      </div>

      <div className="relative flex items-center justify-between border-t border-white/15 px-16 py-8 text-[12px] font-medium text-white/60">
        <span>PT Tuntas Kilat Group</span>
        <span>Sampit, Kalimantan Tengah</span>
        <span>Diterbitkan {TANGGAL}</span>
      </div>
    </section>
  )
}
