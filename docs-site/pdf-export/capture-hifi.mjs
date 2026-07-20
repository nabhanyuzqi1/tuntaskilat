import puppeteer from 'puppeteer-core';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import fs from 'node:fs';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

const CANVAS_PATH =
  '/Users/nabhan/Documents/Akademik dan Skripsi/Skripsi Nabhan/Progress 3 - Final Sidang Akhir/SKRIPSI TA 2026/03 Aset Visual dan Branding/Hi-Fi Tuntaskilat App/Canvas.dc.html';

const OUT_DIR = path.resolve(__dirname, '../manualbook/public/hifi');

const CHROME_CANDIDATES = ['/Applications/Google Chrome.app/Contents/MacOS/Google Chrome'];

// Phone screens (390x844 frame) — selector targets the [data-screen-label] div directly.
const PHONE_SCREENS = [
  'p2', 'p3', 'p5', 'p7', 'p8', 'p11', 'p12',
  'k1', 'k2', 'k3', 'k4',
];

// Admin (web, 1440x900ish) screens.
const ADMIN_SCREENS = ['a1', 'a2', 'a3', 'a4', 'a5', 'a6'];

async function main() {
  fs.mkdirSync(OUT_DIR, { recursive: true });

  let executablePath = null;
  for (const p of CHROME_CANDIDATES) {
    if (fs.existsSync(p)) {
      executablePath = p;
      break;
    }
  }
  if (!executablePath) throw new Error('Chrome not found');

  const browser = await puppeteer.launch({ executablePath, headless: true });
  const page = await browser.newPage();
  await page.setViewport({ width: 2200, height: 2200, deviceScaleFactor: 2 });

  const fileUrl = 'file://' + encodeURI(CANVAS_PATH).replace(/#/g, '%23');
  console.log('loading', fileUrl);
  await page.goto(fileUrl, { waitUntil: 'load', timeout: 60000 });
  await page.evaluate(() => document.fonts.ready).catch(() => {});
  await new Promise((r) => setTimeout(r, 500));

  const all = [...PHONE_SCREENS, ...ADMIN_SCREENS];
  for (const id of all) {
    const selector = `#${id} [data-screen-label]`;
    const el = await page.$(selector);
    if (!el) {
      console.warn(`  ✗ NOT FOUND: ${id} (${selector})`);
      continue;
    }
    const outFile = path.join(OUT_DIR, `${id}.png`);
    await el.screenshot({ path: outFile });
    console.log(`  ✓ ${id} → ${outFile}`);
  }

  await browser.close();
  console.log('\nDone. Output in', OUT_DIR);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
