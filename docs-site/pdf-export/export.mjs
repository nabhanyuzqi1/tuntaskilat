import puppeteer from 'puppeteer-core';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

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

async function exportOne(browser, job) {
  const page = await browser.newPage();
  await page.setViewport({ width: 1280, height: 900, deviceScaleFactor: 2 });
  await page.emulateMediaType('print');

  console.log(`→ loading ${job.url}`);
  await page.goto(job.url, { waitUntil: 'networkidle0', timeout: 60000 });

  // Wait for web fonts (Montserrat/JetBrains Mono) to finish loading so
  // text doesn't fall back to system fonts in the render.
  await page.evaluate(() => document.fonts.ready);

  // Wait for every <img> (screenshots, brand assets) to finish loading —
  // Puppeteer never scrolls the page, so anything relying on viewport-based
  // lazy-loading would otherwise render as a blank box.
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

  console.log(`  rendering PDF → ${job.outFile}`);
  await page.pdf({
    path: job.outFile,
    format: 'A4',
    landscape: true,
    printBackground: true,
    preferCSSPageSize: true,
    displayHeaderFooter: true,
    headerTemplate: '<span></span>',
    footerTemplate: `
      <div style="width:100%; font-size:8px; font-family:Helvetica,Arial,sans-serif; color:#8a948e; padding:0 14mm; display:flex; justify-content:space-between;">
        <span>${job.footerLabel}</span>
        <span>Page <span class="pageNumber"></span> of <span class="totalPages"></span></span>
      </div>`,
    margin: { top: '6mm', bottom: '10mm', left: '6mm', right: '6mm' },
  });

  await page.close();
  console.log(`  ✓ done`);
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
