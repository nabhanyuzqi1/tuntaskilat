import PdfPrinter from 'pdfmake';
import fs from 'node:fs';
import { FONTS, PAGE, COLOR, ROLE_COLOR, CONTENT_WIDTH } from './lib/theme.mjs';
import {
  coverPageBackground, chapterHero, sectionHeading, paragraph, steps, featureGrid,
  callout, dataTable, withScreen, screenFigure, tocEntry, pageFooter, faqGrid, contactBlock, keepTogether,
} from './lib/components.mjs';
import { PELANGGAN, KRU, ADMIN } from './content/manualbook-content.mjs';
import { FAQS } from './content/faqs.mjs';

function renderBlocks(blocks, accent) {
  return blocks.map((b) => {
    switch (b.type) {
      case 'paragraph': return paragraph(b.text);
      case 'steps': return steps(b.items, { accent });
      case 'featureGrid': return featureGrid(b.items);
      case 'callout': return callout(b.text, b.kind);
      case 'table': return dataTable(b.head, b.rows, b.widths);
      default: return null;
    }
  }).filter(Boolean);
}

function renderSection(section, accent) {
  const heading = sectionHeading(section.title, { color: accent });
  if (section.image) {
    // Only a short leading slice of blocks pairs with the screenshot (kept
    // under the image's own height so dontBreakRows never has to fight a
    // too-tall row); any remaining blocks flow full-width below it.
    const pairCount = section.pairCount ?? section.blocks.length;
    const paired = renderBlocks(section.blocks.slice(0, pairCount), accent);
    const rest = renderBlocks(section.blocks.slice(pairCount), accent);
    const screenRow = withScreen(paired, section.image.src, section.image.caption, section.image.variant);
    return [keepTogether([heading, screenRow]), ...rest];
  }
  const body = renderBlocks(section.blocks, accent);
  const [first, ...remaining] = body;
  return [keepTogether([heading, first]), ...remaining, { text: '', margin: [0, 0, 0, 4] }];
}

function renderChapter(chapter, roleKey) {
  const accent = ROLE_COLOR[roleKey];
  const content = [
    { text: '', pageBreak: 'before' },
    chapterHero({ eyebrow: chapter.eyebrow, title: chapter.title, description: chapter.description, eyebrowColor: accent }),
  ];
  chapter.sections.forEach((section) => {
    content.push(...renderSection(section, accent));
  });
  return content;
}

function tocPage() {
  return [
    { text: 'DAFTAR ISI', font: 'MontserratSemiBold', fontSize: 11, characterSpacing: 2, color: COLOR.primary, margin: [0, 60, 0, 4] },
    { text: 'Isi Buku Panduan', font: 'MontserratExtraBold', fontSize: 26, color: COLOR.inkSoft, margin: [0, 0, 0, 36] },
    {
      columns: [
        { width: '*', stack: [
          tocEntry('01', 'Panduan Pelanggan', 'Memulai, menjelajahi layanan, membuat pesanan, pembayaran, melacak pesanan, riwayat & ulasan, voucher & referal, chat & asisten AI, notifikasi, profil & akun.', ROLE_COLOR.pelanggan),
          tocEntry('03', 'Panduan Admin', 'Masuk & keamanan, dashboard, kelola pesanan/layanan/kru/voucher, setoran tunai, kelola klien, pantau operasional, pengaturan.', ROLE_COLOR.admin),
        ] },
        { width: '*', stack: [
          tocEntry('02', 'Panduan Kru', 'Memulai, daftar tugas, navigasi & detail tugas, laporan kerja, setoran tunai, rekening pencairan, riwayat & rating, chat dengan pelanggan.', ROLE_COLOR.kru),
          tocEntry('04', 'Pertanyaan Umum (FAQ)', 'Jawaban cepat untuk pertanyaan yang paling sering diajukan Pelanggan, Kru, dan Admin.', COLOR.primary),
        ] },
      ],
      columnGap: 40,
    },
  ];
}

function faqPage() {
  const content = [
    { text: '', pageBreak: 'before' },
    chapterHero({ eyebrow: 'Bab 04', title: 'Pertanyaan Umum (FAQ)', description: 'Jawaban cepat untuk pertanyaan yang paling sering diajukan Pelanggan, Kru, dan Admin.' }),
    faqGrid(FAQS),
    { text: 'Butuh Bantuan Lebih Lanjut?', font: 'MontserratSemiBold', fontSize: 11, color: COLOR.inkSoft, margin: [0, 8, 0, 0] },
    contactBlock(['WhatsApp CS: +62 817-7490-0001', 'Chat & Asisten AI di aplikasi', 'cs@tuntaskilat.com']),
  ];
  return content;
}

const printer = new PdfPrinter(FONTS);

const docDefinition = {
  pageSize: PAGE.size,
  pageOrientation: PAGE.layout,
  pageMargins: [PAGE.margin.left, PAGE.margin.top, PAGE.margin.right, PAGE.margin.bottom],
  footer: pageFooter('Buku Panduan Tuntaskilat', { skipPages: [1] }),
  background: (currentPage) => {
    if (currentPage === 1) {
      return coverPageBackground({
        bgColor: COLOR.primaryDark,
        eyebrow: 'DOKUMEN RESMI',
        title: 'Buku Panduan',
        subtitle: 'Tuntaskilat',
        footerLeft: 'PT Tuntas Kilat Group',
        footerCenter: 'Sampit, Kalimantan Tengah',
        footerRight: 'Juli 2026',
        logoPath: 'images/brandmark.png',
      });
    }
    return null;
  },
  content: [
    { text: '', pageBreak: 'after' }, // page 1: cover (rendered via background)
    ...tocPage(),
    ...renderChapter(PELANGGAN, 'pelanggan'),
    ...renderChapter(KRU, 'kru'),
    ...renderChapter(ADMIN, 'admin'),
    ...faqPage(),
  ],
  defaultStyle: { font: 'Montserrat', fontSize: 10.5 },
};

const doc = printer.createPdfKitDocument(docDefinition);
const chunks = [];
doc.on('data', (c) => chunks.push(c));
doc.on('end', () => {
  const outDir = '../../pdf-output';
  fs.mkdirSync(outDir, { recursive: true });
  fs.writeFileSync(`${outDir}/Buku-Panduan-Tuntaskilat.pdf`, Buffer.concat(chunks));
  console.log('done: Buku-Panduan-Tuntaskilat.pdf');
});
doc.end();
