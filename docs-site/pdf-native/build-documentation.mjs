import PdfPrinter from 'pdfmake';
import fs from 'node:fs';
import { FONTS, PAGE, COLOR } from './lib/theme.mjs';
import {
  coverPageBackground, chapterHero, subHeading, subHeading2, paragraph, rich, codeBlock,
  dataTable, fieldList, functionCard, bulletList, statsRow, timelinePhase, callout,
  tocEntry, pageFooter, keepTogether,
} from './lib/components.mjs';
import { CHAPTERS } from './content/documentation-content.mjs';

function renderBlock(b) {
  switch (b.type) {
    case 'paragraph': return paragraph(b.text);
    case 'rich': return rich(b.parts);
    case 'code': return codeBlock(b.code, b.title);
    case 'table': return dataTable(b.head, b.rows, b.widths);
    case 'fields': return fieldList(b.items);
    case 'functions': return { stack: b.items.map((fn) => functionCard(fn)) };
    case 'callout': return callout(b.text, b.kind);
    case 'subHeading': return subHeading(b.text);
    case 'subHeading2': return subHeading2(b.text);
    case 'list': return bulletList(b.items);
    case 'stats': return statsRow(b.items);
    case 'timeline': return { stack: b.items.map((p) => timelinePhase(p)) };
    default: return null;
  }
}

function renderBlocks(blocks) {
  const nodes = [];
  for (let i = 0; i < blocks.length; i++) {
    const b = blocks[i];
    if (b.type === 'subHeading' || b.type === 'subHeading2') {
      // Glue heading to the block right after it so it never gets orphaned
      // alone at the bottom of a page.
      const headingNode = renderBlock(b);
      const next = blocks[i + 1];
      if (next) {
        nodes.push(keepTogether([headingNode, renderBlock(next)]));
        i++;
        continue;
      }
      nodes.push(headingNode);
      continue;
    }
    const node = renderBlock(b);
    if (node) nodes.push(node);
  }
  return nodes;
}

function renderChapter(chapter, index) {
  return [
    { text: '', pageBreak: 'before' },
    chapterHero({ eyebrow: chapter.eyebrow, title: chapter.title, description: chapter.description, bgColor: COLOR.surfaceMuted, eyebrowColor: COLOR.admin }),
    ...renderBlocks(chapter.blocks),
  ];
}

// Short, TOC-specific blurbs — the full chapter descriptions are too long
// for a 3-column grid and were causing entries to overflow mid-sentence
// across a page break (columns don't paginate as reliably as tables).
const TOC_BLURBS = [
  'Stats, quick links, tech stack.',
  'Prerequisites, repo structure, local setup, running each app.',
  'System overview, client apps, shared package, backend, auth & roles, atomic locking.',
  'Every Firestore collection — fields, types, enums.',
  'All 22 server-side functions grouped by category.',
  'Access-control matrix and key invariants.',
  'Wage-split formula, commission config, cash-deposit ledger, voucher anti-abuse, capacity slots.',
  'Static gateway vs. Xendit dynamic, webhook flow.',
  'Multi-provider CS chat and business analyst.',
  'FCM push events and WhatsApp (Fonnte).',
  'Hosting targets, env vars, deploy commands, pre-deploy checklist.',
  'Development phases from MVP through the current feature set.',
];

function tocPage() {
  const rows = [];
  for (let i = 0; i < CHAPTERS.length; i += 3) {
    rows.push([0, 1, 2].map((offset) => {
      const idx = i + offset;
      if (idx >= CHAPTERS.length) return {};
      return {
        columns: [
          { width: 26, text: String(idx + 1).padStart(2, '0'), font: 'MontserratExtraBold', fontSize: 15, color: `${COLOR.admin}55` },
          {
            width: '*',
            stack: [
              { text: CHAPTERS[idx].title, font: 'MontserratSemiBold', fontSize: 10.5, color: COLOR.inkSoft },
              { text: TOC_BLURBS[idx], font: 'Montserrat', fontSize: 8, color: COLOR.textSecondary, lineHeight: 1.25, margin: [0, 2, 0, 0] },
            ],
          },
        ],
      };
    }));
  }
  return [
    { text: 'TABLE OF CONTENTS', font: 'MontserratSemiBold', fontSize: 11, characterSpacing: 2, color: COLOR.admin, margin: [0, 60, 0, 4] },
    { text: 'Contents', font: 'MontserratExtraBold', fontSize: 26, color: COLOR.inkSoft, margin: [0, 0, 0, 30] },
    {
      table: { widths: ['*', '*', '*'], dontBreakRows: true, body: rows },
      layout: { hLineWidth: () => 0, vLineWidth: () => 0, paddingLeft: () => 0, paddingRight: () => 16, paddingTop: () => 0, paddingBottom: () => 16 },
    },
  ];
}

const printer = new PdfPrinter(FONTS);

const docDefinition = {
  pageSize: PAGE.size,
  pageOrientation: PAGE.layout,
  pageMargins: [PAGE.margin.left, PAGE.margin.top, PAGE.margin.right, PAGE.margin.bottom],
  footer: pageFooter('Tuntaskilat — Developer Documentation', { skipPages: [1] }),
  background: (currentPage) => {
    if (currentPage === 1) {
      return coverPageBackground({
        bgColor: COLOR.admin,
        eyebrow: 'TECHNICAL REFERENCE',
        title: 'Developer Documentation',
        subtitle: 'Tuntaskilat',
        footerLeft: 'PT Tuntas Kilat Group',
        footerCenter: 'Internal Engineering Reference',
        footerRight: 'Juli 2026',
        logoPath: 'images/brandmark.png',
      });
    }
    return null;
  },
  content: [
    { text: '', pageBreak: 'after' }, // page 1: cover (rendered via background)
    ...tocPage(),
    ...CHAPTERS.flatMap((c, i) => renderChapter(c, i)),
  ],
  defaultStyle: { font: 'Montserrat', fontSize: 10.5 },
};

const doc = printer.createPdfKitDocument(docDefinition);
const chunks = [];
doc.on('data', (c) => chunks.push(c));
doc.on('end', () => {
  const outDir = '../../pdf-output';
  fs.mkdirSync(outDir, { recursive: true });
  fs.writeFileSync(`${outDir}/Tuntaskilat-Developer-Documentation.pdf`, Buffer.concat(chunks));
  console.log('done: Tuntaskilat-Developer-Documentation.pdf');
});
doc.end();
