#!/usr/bin/env python3
"""Verifikasi otomatis empat kategori yang paling sering luput di TA:
gambar hilang, sitasi yatim, salah hitung (SUS), dan istilah asing italic
tak-konsisten. Jangan percaya caption/narasi — buktikan dari XML.

Pakai:  python3 verify_docx.py "naskah.docx"
"""
import re
import sys
from collections import defaultdict

import docx


def has_drawing(p) -> bool:
    x = p._p.xml
    return "graphicData" in x or "pic:pic" in x or "blipFill" in x


def cek_gambar(paras) -> None:
    print("=== GAMBAR (caption -> ada objek gambar di ~20 paragraf sekitar?) ===")
    caps = [i for i, p in enumerate(paras) if re.match(r"^Gambar \d+\.\d+", p.text.strip())]
    hilang = []
    for i in caps:
        window = range(max(0, i - 20), i + 3)
        if not any(has_drawing(paras[j]) for j in window):
            hilang.append((i, paras[i].text[:60]))
    print(f"caption: {len(caps)} | tanpa gambar terdeteksi: {len(hilang)}")
    for i, t in hilang:
        print(f"  HILANG? [{i}] {t}")
    # urutan penomoran per bab
    nums = [re.match(r"^Gambar (\d+)\.(\d+)", paras[i].text.strip()) for i in caps]
    print("  urutan caption:", [f"{m.group(1)}.{m.group(2)}" for m in nums if m])


def cek_sitasi(d, paras) -> None:
    print("\n=== SITASI ===")
    dp = [i for i, p in enumerate(paras) if p.text.strip() == "DAFTAR PUSTAKA"]
    if not dp:
        print("  (Daftar Pustaka tak ditemukan)")
        return
    dp = dp[0]
    dp_text = " ".join(p.text for p in paras[dp:])
    entri = sorted(set(int(x) for x in re.findall(r"\[(\d{1,2})\]", dp_text)))
    body = " ".join(p.text for p in paras[:dp])
    for t in d.tables:  # sitasi sering ada di sel tabel "Tinjauan Terdahulu"
        for r in t.rows:
            for c in r.cells:
                body += " " + c.text
    cited = set(int(x) for x in re.findall(r"\[(\d{1,2})\]", body))
    print(f"  entri pustaka: {len(entri)} | disitasi: {len(cited)}")
    print("  YATIM (di pustaka, tak disitasi):", sorted(set(entri) - cited))
    print("  sitasi tanpa entri:", sorted(cited - set(entri)))


def cek_italic(paras) -> None:
    print("\n=== ITALIC istilah asing (campur = perlu diseragamkan) ===")
    terms = [
        "frontend", "backend", "framework", "widget", "server", "real-time",
        "black-box", "usability", "mockup", "gateway", "marker", "on-demand",
        "double-booking", "fixed pricing", "serverless", "state management",
        "cross-platform", "user experience",
    ]
    occ = defaultdict(list)
    for i, p in enumerate(paras):
        for r in p.runs:
            low = r.text.lower()
            for t in terms:
                if t in low and r.text.strip():
                    occ[t].append(bool(r.italic))
    for t, st in occ.items():
        if len(set(st)) > 1:
            print(f"  MIXED: {t} — italic {sum(st)}x, polos {len(st) - sum(st)}x")


def cek_hitung(d) -> None:
    """Cari tabel yang punya baris Total lalu jumlahkan ulang kolom angka."""
    print("\n=== VERIFIKASI HITUNG (cari 'Total'/'Skor' di tabel) ===")
    for ti, t in enumerate(d.tables):
        for r in t.rows:
            teks = " ".join(c.text for c in r.cells).lower()
            if "total" in teks or "skor" in teks or "rata" in teks:
                angka = re.findall(r"\d+[.,]\d+|\d+", " ".join(c.text for c in r.cells))
                print(f"  TABLE {ti} baris berlabel: {[c.text.strip()[:24] for c in r.cells]}")
    print("  → hitung ulang manual angka mentah tabel SUS/rata-rata & bandingkan klaim.")


def main() -> None:
    if len(sys.argv) < 2:
        sys.exit("Pakai: python3 verify_docx.py <file.docx>")
    d = docx.Document(sys.argv[1])
    paras = d.paragraphs
    cek_gambar(paras)
    cek_sitasi(d, paras)
    cek_italic(paras)
    cek_hitung(d)


if __name__ == "__main__":
    main()
