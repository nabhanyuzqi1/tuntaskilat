import puppeteer from 'puppeteer-core';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { execFileSync } from 'node:child_process';
import { PDFDocument, StandardFonts, rgb } from 'pdf-lib';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const OUT_DIR = path.resolve(__dirname, '../../pdf-output');

const CHROME_CANDIDATES = [
  '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
];

const JOBS = [
  {
    url: 'https://tuntaskilat-manualbook.web.app/cetak',
    outFile: path.join(OUT_DIR, 'Buku-Panduan-Tuntaskilat.pdf'),
    footerLabel: 'Buku Panduan Tuntaskilat',
  },
  {
    url: 'https://tuntaskilat-documentation.web.app/print',
    outFile: path.join(OUT_DIR, 'Tuntaskilat-Developer-Documentation.pdf'),
    footerLabel: 'Tuntaskilat — Developer Documentation',
  },
];

// Chromium's print-to-PDF pagination has a known rounding quirk: when a
// forced `break-before: page` lands very close to a page-height multiple,
// it can insert one genuinely empty page. This is independent of margins,
// deviceScaleFactor, preferCSSPageSize, and the footer template — verified
// by testing each in isolation. Rather than chase which chapter's content
// height happens to trigger it (a moving target as content changes), we
// render without Chromium's own footer, detect pages with zero extracted
// text (a real content page always has something, even just a heading),
// strip them, then stamp our own correctly-numbered footer afterward.
async function renderPdf(browser, job) {
  const page = await browser.newPage();
  await page.setViewport({ width: 1280, height: 900, deviceScaleFactor: 2 });
  await page.emulateMediaType('print');

  console.log(`→ loading ${job.url}`);
  await page.goto(job.url, { waitUntil: 'networkidle0', timeout: 60000 });

  await page.evaluate(() => document.fonts.ready);
  await page.evaluate(() =>
    Promise.all(
      Array.from(document.images)
        .filter((img) => !img.complete)
        .map((img) => new Promise((resolve) => {
          img.addEventListener('load', resolve);
          img.addEventListener('error', resolve);
        }))
    )
  );
  await new Promise((r) => setTimeout(r, 400));

  const buffer = await page.pdf({
    format: 'A4',
    landscape: true,
    printBackground: true,
    preferCSSPageSize: true,
    displayHeaderFooter: false,
    margin: { top: '6mm', bottom: '10mm', left: '6mm', right: '6mm' },
  });

  await page.close();
  return buffer;
}

function findBlankPageIndices(pdfPath, pageCount) {
  const text = execFileSync('pdftotext', [pdfPath, '-'], { maxBuffer: 1024 * 1024 * 64 }).toString('utf8');
  const perPage = text.split('\f');
  const blanks = [];
  for (let i = 0; i < pageCount; i++) {
    if ((perPage[i] ?? '').trim().length === 0) blanks.push(i);
  }
  return blanks;
}

async function stripBlankPagesAndStampFooter(rawBuffer, footerLabel) {
  const fs = await import('node:fs');
  const tmpPath = path.join(OUT_DIR, `.tmp-${Date.now()}.pdf`);
  fs.writeFileSync(tmpPath, rawBuffer);

  const srcDoc = await PDFDocument.load(rawBuffer);
  const originalCount = srcDoc.getPageCount();
  const blankIndices = new Set(findBlankPageIndices(tmpPath, originalCount));
  fs.unlinkSync(tmpPath);

  if (blankIndices.size > 0) {
    console.log(`  stripping ${blankIndices.size} blank page(s) at index ${[...blankIndices].join(', ')}`);
  }

  // Build a fresh document containing only the pages we want to keep, in
  // order — more robust than in-place removePage(), which left a stale
  // page reference behind (getPages().length didn't match the saved page
  // count, producing an off-by-one "Page 51 of 50" footer).
  const keepIndices = Array.from({ length: originalCount }, (_, i) => i).filter((i) => !blankIndices.has(i));
  const doc = await PDFDocument.create();
  const copiedPages = await doc.copyPages(srcDoc, keepIndices);
  copiedPages.forEach((page) => doc.addPage(page));

  const font = await doc.embedFont(StandardFonts.Helvetica);
  const pages = doc.getPages();
  const total = pages.length;
  const gray = rgb(0.541, 0.580, 0.560);
  const fontSize = 8;

  pages.forEach((page, i) => {
    const { width } = page.getSize();
    const marginPt = 14 * 2.8346; // 14mm in points
    const y = 14; // ~5mm from the bottom edge, inside the 10mm bottom margin

    page.drawText(footerLabel, {
      x: marginPt,
      y,
      size: fontSize,
      font,
      color: gray,
    });

    const pageLabel = `Page ${i + 1} of ${total}`;
    const labelWidth = font.widthOfTextAtSize(pageLabel, fontSize);
    page.drawText(pageLabel, {
      x: width - marginPt - labelWidth,
      y,
      size: fontSize,
      font,
      color: gray,
    });
  });

  return doc.save();
}

async function exportOne(browser, job) {
  const rawBuffer = await renderPdf(browser, job);
  const finalBuffer = await stripBlankPagesAndStampFooter(rawBuffer, job.footerLabel);
  const fs = await import('node:fs');
  fs.writeFileSync(job.outFile, finalBuffer);
  console.log(`  ✓ done → ${job.outFile}`);
}

async function main() {
  const fs = await import('node:fs');
  fs.mkdirSync(OUT_DIR, { recursive: true });

  let executablePath = null;
  for (const p of CHROME_CANDIDATES) {
    if (fs.existsSync(p)) {
      executablePath = p;
      break;
    }
  }
  if (!executablePath) {
    throw new Error('Google Chrome not found at expected path.');
  }

  const browser = await puppeteer.launch({
    executablePath,
    headless: true,
  });

  try {
    for (const job of JOBS) {
      await exportOne(browser, job);
    }
  } finally {
    await browser.close();
  }

  console.log(`\nAll PDFs exported to ${OUT_DIR}`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
