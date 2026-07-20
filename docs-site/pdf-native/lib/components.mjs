import { COLOR, CONTENT_WIDTH, PAGE, ROLE_BADGE } from './theme.mjs';

const noBorderLayout = (fillColor) => ({
  hLineWidth: () => 0,
  vLineWidth: () => 0,
  paddingLeft: () => 0,
  paddingRight: () => 0,
  paddingTop: () => 0,
  paddingBottom: () => 0,
  fillColor: () => fillColor || null,
});

const cardLayout = ({ fillColor = COLOR.white, borderColor = COLOR.border, pad = 14 } = {}) => ({
  hLineWidth: () => 0.75,
  vLineWidth: () => 0.75,
  hLineColor: () => borderColor,
  vLineColor: () => borderColor,
  paddingLeft: () => pad,
  paddingRight: () => pad,
  paddingTop: () => pad * 0.7,
  paddingBottom: () => pad * 0.7,
  fillColor: () => fillColor,
});

// --- Cover page -----------------------------------------------------------

export function coverPageBackground({ bgColor, eyebrow, title, subtitle, footerLeft, footerCenter, footerRight, logoPath }) {
  const w = PAGE.widthPt;
  const h = PAGE.heightPt;
  // Every node here MUST carry absolutePosition:{x:0,y:0} — pdfmake lays out
  // a background array top-to-bottom like normal content, so a full-page
  // rect (with implied box height == h) pushes everything after it off the
  // visible page unless each node is explicitly pulled out of that flow.
  const abs = { x: 0, y: 0 };
  return [
    { canvas: [{ type: 'rect', x: 0, y: 0, w, h, color: bgColor }], absolutePosition: abs },
    { canvas: [{ type: 'ellipse', x: w - 60, y: 40, r1: 190, r2: 190, color: 'rgba(255,255,255,0.06)' }], absolutePosition: abs },
    { canvas: [{ type: 'ellipse', x: 40, y: h - 30, r1: 150, r2: 150, color: 'rgba(0,0,0,0.10)' }], absolutePosition: abs },
    { canvas: [{ type: 'rect', x: 0, y: h - 140, w, h: 3, color: COLOR.accent }], absolutePosition: abs },
    { canvas: [{ type: 'rect', x: 0, y: h - 140, w, h: 1, color: 'rgba(255,255,255,0.15)' }], absolutePosition: abs },
    logoPath
      ? { image: logoPath, width: 62, height: 62, absolutePosition: { x: w / 2 - 31, y: 96 } }
      : null,
    { text: eyebrow, font: 'MontserratSemiBold', fontSize: 11, characterSpacing: 2.5, color: COLOR.accent, alignment: 'center', absolutePosition: { x: 0, y: 182 }, width: w },
    { text: title, font: 'MontserratExtraBold', fontSize: 42, color: COLOR.white, alignment: 'center', absolutePosition: { x: 60, y: 210 }, width: w - 120 },
    { text: subtitle, font: 'MontserratSemiBold', fontSize: 20, color: 'rgba(255,255,255,0.88)', alignment: 'center', absolutePosition: { x: 60, y: 262 }, width: w - 120 },
    { text: footerLeft, font: 'Montserrat', fontSize: 10, color: 'rgba(255,255,255,0.75)', absolutePosition: { x: 60, y: h - 108 } },
    { text: footerCenter, font: 'Montserrat', fontSize: 10, color: 'rgba(255,255,255,0.75)', alignment: 'center', absolutePosition: { x: 0, y: h - 108 }, width: w },
    { text: footerRight, font: 'Montserrat', fontSize: 10, color: 'rgba(255,255,255,0.75)', alignment: 'right', absolutePosition: { x: 0, y: h - 108 }, width: w - 60 },
  ].filter(Boolean);
}

// --- Chapter hero band ------------------------------------------------------

export function chapterHero({ eyebrow, title, description, bgColor = COLOR.surfaceMuted, titleColor = COLOR.inkSoft, eyebrowColor }) {
  return {
    table: {
      widths: [CONTENT_WIDTH],
      dontBreakRows: true,
      body: [[
        {
          stack: [
            { text: eyebrow.toUpperCase(), font: 'MontserratSemiBold', fontSize: 10.5, characterSpacing: 1.6, color: eyebrowColor || COLOR.primary },
            { text: title, font: 'MontserratExtraBold', fontSize: 26, color: titleColor, margin: [0, 6, 0, 6] },
            description ? { text: description, font: 'Montserrat', fontSize: 12, color: COLOR.textSecondary, lineHeight: 1.35 } : null,
          ].filter(Boolean),
        },
      ]],
    },
    layout: cardLayout({ fillColor: bgColor, borderColor: bgColor, pad: 22 }),
    margin: [0, 0, 0, 20],
  };
}

// --- Section heading ---------------------------------------------------------

export function sectionHeading(title, { color = COLOR.primary } = {}) {
  return {
    columns: [
      { width: 4, canvas: [{ type: 'rect', x: 0, y: 2, w: 4, h: 16, color, r: 2 }] },
      { width: 10, text: '' },
      { width: '*', text: title, font: 'MontserratExtraBold', fontSize: 15, color: COLOR.inkSoft },
    ],
    margin: [0, 0, 0, 10],
  };
}

// --- Body paragraph -------------------------------------------------------

export function paragraph(text, opts = {}) {
  return { text, font: 'Montserrat', fontSize: 10.5, color: COLOR.textSecondary, lineHeight: 1.4, margin: [0, 0, 0, 10], ...opts };
}

// --- Numbered steps ---------------------------------------------------------

function numberBadge(n, color) {
  return {
    svg: `<svg width="22" height="22" xmlns="http://www.w3.org/2000/svg"><circle cx="11" cy="11" r="11" fill="${color}"/><text x="11" y="14.5" font-size="10" font-family="Helvetica-Bold" fill="#ffffff" text-anchor="middle">${n}</text></svg>`,
    width: 22,
  };
}

export function steps(items, { accent = COLOR.primary } = {}) {
  return {
    table: {
      widths: ['*'],
      dontBreakRows: true,
      body: items.map((item, i) => [
        {
          columns: [
            { width: 22, stack: [numberBadge(i + 1, accent)] },
            { width: 10, text: '' },
            {
              width: '*',
              stack: [
                { text: item.title, font: 'MontserratSemiBold', fontSize: 10.5, color: COLOR.inkSoft },
                { text: item.desc, font: 'Montserrat', fontSize: 9.5, color: COLOR.textSecondary, lineHeight: 1.3, margin: [0, 2, 0, 0] },
              ],
            },
          ],
        },
      ]),
    },
    layout: {
      hLineWidth: () => 0.75,
      vLineWidth: () => 0,
      hLineColor: () => COLOR.border,
      paddingLeft: () => 12,
      paddingRight: () => 12,
      paddingTop: () => 9,
      paddingBottom: () => 9,
    },
    margin: [0, 0, 0, 12],
  };
}

// --- Feature grid (2-column cards) ------------------------------------------

export function featureGrid(items) {
  const rows = [];
  for (let i = 0; i < items.length; i += 2) {
    rows.push([items[i], items[i + 1] ?? null]);
  }
  return {
    table: {
      widths: ['*', '*'],
      dontBreakRows: true,
      body: rows.map((pair) =>
        pair.map((item) =>
          item
            ? {
                stack: [
                  { text: item.title, font: 'MontserratSemiBold', fontSize: 10.5, color: COLOR.inkSoft },
                  { text: item.desc, font: 'Montserrat', fontSize: 9.5, color: COLOR.textSecondary, lineHeight: 1.3, margin: [0, 3, 0, 0] },
                ],
              }
            : {}
        )
      ),
    },
    layout: {
      hLineWidth: () => 0.75,
      vLineWidth: () => 0.75,
      hLineColor: () => COLOR.border,
      vLineColor: () => COLOR.border,
      paddingLeft: () => 12,
      paddingRight: () => 12,
      paddingTop: () => 9,
      paddingBottom: () => 9,
    },
    margin: [0, 0, 0, 12],
  };
}

// --- Callout -----------------------------------------------------------------

const CALLOUT_STYLE = {
  info: { bg: COLOR.infoBg, border: COLOR.infoBorder, text: COLOR.infoText, label: 'INFO' },
  tip: { bg: '#EAF6EE', border: '#BFE3C9', text: COLOR.primaryDark, label: 'TIPS' },
  warning: { bg: COLOR.warnBg, border: COLOR.warnBorder, text: COLOR.warnText, label: 'PERHATIAN' },
};

export function callout(text, type = 'info') {
  const s = CALLOUT_STYLE[type] ?? CALLOUT_STYLE.info;
  return {
    table: {
      widths: [CONTENT_WIDTH - 28],
      dontBreakRows: true,
      body: [[
        {
          stack: [
            { text: s.label, font: 'MontserratSemiBold', fontSize: 8.5, characterSpacing: 1, color: s.text, margin: [0, 0, 0, 3] },
            { text, font: 'Montserrat', fontSize: 9.75, color: s.text, lineHeight: 1.35 },
          ],
        },
      ]],
    },
    layout: cardLayout({ fillColor: s.bg, borderColor: s.border, pad: 12 }),
    margin: [0, 0, 0, 12],
  };
}

// --- Table (head + rows) -----------------------------------------------------

export function dataTable(head, rows, widths) {
  return {
    table: {
      headerRows: 1,
      widths: widths || head.map(() => '*'),
      dontBreakRows: true,
      body: [
        head.map((h) => ({ text: h, font: 'MontserratSemiBold', fontSize: 9.25, color: COLOR.inkSoft, fillColor: COLOR.surfaceMuted, margin: [0, 3, 0, 3] })),
        ...rows.map((row) => row.map((cell) => (typeof cell === 'string' ? { text: cell, font: 'Montserrat', fontSize: 9, color: COLOR.textSecondary, margin: [0, 3, 0, 3] } : cell))),
      ],
    },
    layout: {
      hLineWidth: () => 0.75,
      vLineWidth: () => 0.75,
      hLineColor: () => COLOR.border,
      vLineColor: () => COLOR.border,
      paddingLeft: () => 8,
      paddingRight: () => 8,
      paddingTop: () => 5,
      paddingBottom: () => 5,
    },
    margin: [0, 0, 0, 12],
  };
}

// --- Screen figure (phone/admin screenshot + caption) -------------------

export function screenFigure(imagePath, caption, variant = 'phone') {
  const width = variant === 'phone' ? 118 : 230;
  const height = variant === 'phone' ? width / (780 / 1688) : width / (2880 / 1800);
  return {
    table: {
      widths: ['*'],
      dontBreakRows: true,
      body: [[
        {
          stack: [
            { image: imagePath, width, height, alignment: 'center' },
            { text: caption, font: 'MontserratSemiBold', fontSize: 7.5, characterSpacing: 0.6, color: COLOR.textMuted, alignment: 'center', margin: [0, 6, 0, 0] },
          ],
        },
      ]],
    },
    layout: cardLayout({ fillColor: COLOR.surfaceMuted, borderColor: COLOR.border, pad: 10 }),
  };
}

// --- Section with body content + screenshot side-by-side ----------------
// Uses a table (not `columns`) — pdfmake's TableProcessor is purpose-built
// to paginate rows across pages correctly; `columns` historically doesn't
// reflow reliably, which is exactly the class of bug we're avoiding here.

export function withScreen(bodyStack, imagePath, caption, variant = 'phone') {
  const imgColWidth = variant === 'phone' ? 150 : 262;
  return {
    table: {
      widths: ['*', imgColWidth],
      // dontBreakRows keeps the image from being physically cut mid-row —
      // without it, a tall left-column paired with an image invites
      // pdfmake to split the row (and the image inside it) across pages.
      dontBreakRows: true,
      body: [[
        { stack: bodyStack },
        { stack: [screenFigure(imagePath, caption, variant)], margin: [12, 0, 0, 0] },
      ]],
    },
    layout: noBorderLayout(),
    margin: [0, 0, 0, 14],
  };
}

// --- TOC entry ----------------------------------------------------------

export function tocEntry(no, title, desc, color = COLOR.primary) {
  return {
    columns: [
      { width: 30, text: no, font: 'MontserratExtraBold', fontSize: 17, color: `${color}55` },
      {
        width: '*',
        stack: [
          { text: title, font: 'MontserratSemiBold', fontSize: 11.5, color: COLOR.inkSoft },
          { text: desc, font: 'Montserrat', fontSize: 8.75, color: COLOR.textSecondary, lineHeight: 1.3, margin: [0, 2, 0, 0] },
        ],
      },
    ],
    margin: [0, 0, 0, 16],
  };
}

// --- FAQ card (2-column grid, role badge + Q&A) --------------------------

const ROLE_LABEL = { pelanggan: 'Pelanggan', kru: 'Kru', admin: 'Admin', semua: 'Semua' };

export function faqGrid(items) {
  const rows = [];
  for (let i = 0; i < items.length; i += 2) rows.push([items[i], items[i + 1] ?? null]);
  return {
    table: {
      widths: ['*', '*'],
      // dontBreakRows: a FAQ card that splits mid-row leaves an orphaned
      // question with no answer on one page and a dangling answer on the
      // next — force the whole row (both cards) onto the same page.
      dontBreakRows: true,
      body: rows.map((pair) =>
        pair.map((item) => {
          if (!item) return {};
          const badge = ROLE_BADGE[item.role];
          return {
            stack: [
              item.role !== 'semua'
                ? {
                    // Fixed width (not 'auto') — pdfmake's auto-sizing for a
                    // table nested in a stack has a bug where SHORT text
                    // ("Kru") wraps to two lines while longer text doesn't.
                    table: { widths: [62], body: [[{ text: ROLE_LABEL[item.role], font: 'MontserratSemiBold', fontSize: 7.5, color: badge.text, alignment: 'center', margin: [0, 2, 0, 2] }]] },
                    layout: cardLayout({ fillColor: badge.bg, borderColor: badge.border, pad: 0 }),
                    margin: [0, 0, 0, 5],
                  }
                : null,
              { text: item.q, font: 'MontserratSemiBold', fontSize: 10, color: COLOR.inkSoft, margin: [0, 0, 0, 3] },
              { text: item.a, font: 'Montserrat', fontSize: 8.75, color: COLOR.textSecondary, lineHeight: 1.3 },
            ].filter(Boolean),
          };
        })
      ),
    },
    layout: {
      hLineWidth: () => 0.75,
      vLineWidth: () => 0.75,
      hLineColor: () => COLOR.border,
      vLineColor: () => COLOR.border,
      paddingLeft: () => 12,
      paddingRight: () => 12,
      paddingTop: () => 10,
      paddingBottom: () => 10,
    },
    margin: [0, 0, 0, 12],
  };
}

// --- Keep a group of nodes together, never splitting across a page break --

export function keepTogether(nodes) {
  return {
    table: { widths: ['*'], dontBreakRows: true, body: [[{ stack: nodes }]] },
    layout: noBorderLayout(),
  };
}

export function contactBlock(items) {
  return {
    table: {
      widths: items.map(() => '*'),
      dontBreakRows: true,
      body: [items.map((item) => ({ text: item, font: 'MontserratMedium', fontSize: 9.5, color: COLOR.inkSoft }))],
    },
    layout: cardLayout({ fillColor: COLOR.surfaceMuted, borderColor: COLOR.border, pad: 14 }),
    margin: [0, 6, 0, 0],
  };
}

// --- Sub-heading (h2/h3 style, no colored bar) ---------------------------

export function subHeading(title, { fontSize = 13 } = {}) {
  return { text: title, font: 'MontserratExtraBold', fontSize, color: COLOR.inkSoft, margin: [0, 4, 0, 8] };
}

export function subHeading2(title) {
  return { text: title, font: 'MontserratSemiBold', fontSize: 10.5, color: COLOR.inkSoft, margin: [0, 2, 0, 5] };
}

export function bulletList(items) {
  return {
    ul: items.map((t) => ({ text: t, font: 'Montserrat', fontSize: 9.5, color: COLOR.textSecondary, lineHeight: 1.3 })),
    margin: [0, 0, 0, 10],
  };
}

export function statsRow(items) {
  return {
    table: {
      widths: items.map(() => '*'),
      dontBreakRows: true,
      body: [items.map((it) => ({
        stack: [
          { text: it.n, font: 'MontserratExtraBold', fontSize: 20, color: COLOR.primary },
          { text: it.label, font: 'Montserrat', fontSize: 8.5, color: COLOR.textSecondary, margin: [0, 2, 0, 0] },
        ],
      }))],
    },
    layout: cardLayout({ fillColor: COLOR.surfaceMuted, borderColor: COLOR.border, pad: 12 }),
    margin: [0, 0, 0, 14],
  };
}

export function timelinePhase(phase) {
  // Wrapped in a dontBreakRows table (like keepTogether) so a phase's
  // header never gets orphaned from its own bullet list at a page break.
  return {
    table: {
      widths: ['*'],
      dontBreakRows: true,
      body: [[{
        stack: [
          {
            columns: [
              { width: 10, svg: `<svg width="10" height="10"><circle cx="5" cy="5" r="4" fill="none" stroke="${COLOR.primary}" stroke-width="1.5"/></svg>` },
              { width: 8, text: '' },
              { width: '*', text: phase.phase, font: 'MontserratSemiBold', fontSize: 8.5, characterSpacing: 1.2, color: COLOR.primary },
            ],
          },
          { text: phase.title, font: 'MontserratExtraBold', fontSize: 12.5, color: COLOR.inkSoft, margin: [18, 4, 0, 4] },
          { ul: phase.items.map((t) => ({ text: t, font: 'Montserrat', fontSize: 9, color: COLOR.textSecondary, lineHeight: 1.25 })), margin: [18, 0, 0, 0] },
        ],
      }]],
    },
    layout: noBorderLayout(),
    margin: [0, 0, 0, 14],
  };
}

// --- Inline mixed text: plain strings + {code:'...'} runs -----------------

export function rich(parts, opts = {}) {
  return {
    text: parts.map((p) =>
      typeof p === 'string'
        ? { text: p, font: 'Montserrat' }
        : { text: p.code, font: 'JetBrainsMonoMedium', fontSize: 9, color: COLOR.primaryDark }
    ),
    fontSize: 10.5,
    color: COLOR.textSecondary,
    lineHeight: 1.4,
    margin: [0, 0, 0, 10],
    ...opts,
  };
}

// --- Code block (monospace, dark background) ------------------------------

export function codeBlock(code, title) {
  const lines = code.split('\n').map((line) => ({ text: line || ' ', font: 'JetBrainsMono', fontSize: 8.75, color: '#D4E8DE', lineHeight: 1.5 }));
  return {
    table: {
      widths: ['*'],
      dontBreakRows: true,
      body: [[
        {
          stack: [
            title ? { text: title, font: 'JetBrainsMono', fontSize: 8, color: '#7FA895', margin: [0, 0, 0, 6] } : null,
            ...lines,
          ].filter(Boolean),
        },
      ]],
    },
    layout: cardLayout({ fillColor: COLOR.bgCode, borderColor: COLOR.bgCode, pad: 12 }),
    margin: [0, 0, 0, 12],
  };
}

// --- Field list (name / type / description rows, code-styled name+type) --

export function fieldList(fields) {
  return {
    table: {
      widths: ['auto', 'auto', '*'],
      dontBreakRows: true,
      body: fields.map((f) => [
        { text: f.name, font: 'JetBrainsMonoMedium', fontSize: 8.75, color: COLOR.primaryDark, margin: [0, 4, 0, 4] },
        { text: f.type, font: 'JetBrainsMono', fontSize: 8, color: COLOR.textMuted, margin: [0, 4, 0, 4] },
        { text: f.desc || '', font: 'Montserrat', fontSize: 8.75, color: COLOR.textSecondary, margin: [0, 4, 0, 4] },
      ]),
    },
    layout: {
      hLineWidth: () => 0.75,
      vLineWidth: () => 0,
      hLineColor: () => COLOR.border,
      paddingLeft: () => 8,
      paddingRight: () => 8,
      paddingTop: () => 0,
      paddingBottom: () => 0,
    },
    margin: [0, 0, 0, 10],
  };
}

// --- Function reference card ----------------------------------------------

const TRIGGER_COLOR = {
  onCall: '#3B82F6', onRequest: '#A855F7', onSchedule: '#D97706',
  onDocumentCreated: COLOR.primary, onDocumentUpdated: '#0D9488', onDocumentWritten: '#DB2777',
};

export function functionCard(fn) {
  const trigColor = TRIGGER_COLOR[fn.trigger] ?? COLOR.textMuted;
  return {
    table: {
      widths: [CONTENT_WIDTH - 28],
      dontBreakRows: true,
      body: [[
        {
          stack: [
            {
              columns: [
                { width: 'auto', text: fn.name, font: 'JetBrainsMonoMedium', fontSize: 9.5, color: COLOR.primaryDark },
                { width: 8, text: '' },
                { width: 'auto', text: fn.trigger, font: 'JetBrainsMono', fontSize: 7.5, color: trigColor, margin: [0, 1, 0, 0] },
                { width: 8, text: '' },
                { width: '*', text: fn.path || '', font: 'JetBrainsMono', fontSize: 7.5, color: COLOR.textMuted, margin: [0, 1, 0, 0] },
              ],
            },
            { text: fn.desc, font: 'Montserrat', fontSize: 9, color: COLOR.textSecondary, lineHeight: 1.3, margin: [0, 5, 0, 0] },
            fn.note ? { text: fn.note, font: 'Montserrat', fontSize: 8.25, color: COLOR.textMuted, italics: true, margin: [8, 4, 0, 0] } : null,
          ].filter(Boolean),
        },
      ]],
    },
    layout: cardLayout({ fillColor: COLOR.white, borderColor: COLOR.border, pad: 10 }),
    margin: [0, 0, 0, 8],
  };
}

export function pageFooter(label, { skipPages = [] } = {}) {
  return function footer(currentPage, pageCount) {
    if (skipPages.includes(currentPage)) return null;
    return {
      columns: [
        { width: '*', text: label, font: 'Montserrat', fontSize: 8, color: COLOR.textMuted },
        { width: '*', text: `Halaman ${currentPage} dari ${pageCount}`, font: 'Montserrat', fontSize: 8, color: COLOR.textMuted, alignment: 'right' },
      ],
      margin: [PAGE.margin.left, 0, PAGE.margin.right, 0],
    };
  };
}
