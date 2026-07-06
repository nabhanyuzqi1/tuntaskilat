#!/usr/bin/env python3
"""Helper edit .docx yang AMAN — merangkum gotcha python-docx yang sudah mahal.

Impor dari skrip perbaikanmu, JANGAN edit langsung pakai index kaku:

    import docx
    from edit_helpers import cari, rebuild_p, split_italicize, sisip_setelah

    d = docx.Document(SRC)
    # ... edit berbasis pencarian teks ...
    d.save(DST)   # SELALU nama baru (naikkan nomor revisi), jangan timpa asli

Prinsip:
- Edit berbasis PENCARIAN TEKS, bukan index tetap — index bergeser sesudah
  insert/delete paragraf.
- Lakukan semua edit non-struktural DULU, insert/delete paragraf PALING AKHIR.
- Sel tabel yang di-merge = objek Python yang SAMA (edit sekali kena semua).
- Italic sebagian kata = pecah run (deepcopy) — `run.italic=True` mengitalic
  seluruh run.
- Setelah simpan, VERIFIKASI: re-extract + grep string lama (harus 0) & string
  baru (harus ada). "Script jalan tanpa error" != "hasil benar".
"""
from copy import deepcopy
import re

from docx.text.run import Run

NS = "{http://schemas.openxmlformats.org/wordprocessingml/2006/main}"


def cari(paras, anchor, mulai=0):
    """Index paragraf pertama yang MEMUAT anchor (mulai dari `mulai`)."""
    for i in range(mulai, len(paras)):
        if anchor in paras[i].text:
            return i
    raise ValueError(f"ANCHOR TIDAK KETEMU: {anchor!r}")


def rebuild_p(p, teks_baru):
    """Ganti seluruh teks paragraf, pertahankan format run pertama."""
    for r in list(p.runs)[1:]:
        r._r.getparent().remove(r._r)
    if p.runs:
        p.runs[0].text = teks_baru
    else:
        p.add_run(teks_baru)


def split_italicize(run, word) -> bool:
    """Italic HANYA `word` di tengah run panjang: pecah run jadi tiga."""
    m = re.search(re.escape(word), run.text, re.IGNORECASE)
    if not m:
        return False
    before, matched, after = (
        run.text[: m.start()],
        run.text[m.start(): m.end()],
        run.text[m.end():],
    )
    r = run._r
    run.text = before
    r_mid, r_aft = deepcopy(r), deepcopy(r)
    r.addnext(r_aft)
    r.addnext(r_mid)
    for rel, txt in ((r_mid, matched), (r_aft, after)):
        ts = rel.findall(NS + "t")
        for t in ts:
            t.text = ""
        if ts:
            ts[0].text = txt
            ts[0].set("{http://www.w3.org/XML/1998/namespace}space", "preserve")
    Run(r_mid, run.part).italic = True
    return True


def sisip_setelah(paras, anchor, teks, contoh_style_paragraf=None):
    """Sisip paragraf baru SESUDAH paragraf ber-anchor. Lakukan paling akhir."""
    i = cari(paras, anchor)
    target = paras[i + 1] if i + 1 < len(paras) else paras[i]
    baru = target.insert_paragraph_before(teks)
    ref = contoh_style_paragraf or paras[i]
    baru.style = ref.style
    baru.alignment = ref.alignment
    if ref.runs and baru.runs:
        baru.runs[0].font.name = ref.runs[0].font.name
        baru.runs[0].font.size = ref.runs[0].font.size
    return baru
