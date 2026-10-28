// Render setiap HTML ke PNG dengan ukuran persis yang diminta Google Play.
const { chromium } = require('playwright');
const path = require('path');
const fs = require('fs');

const dir = __dirname;
const out = process.argv[2];
const jobs = [];
for (const f of fs.readdirSync(dir).filter((f) => /^slide_\d+\.html$/.test(f)).sort()) {
  jobs.push({ html: f, png: `phone_${f.match(/\d+/)[0]}.png`, w: 1080, h: 1920 });
}
jobs.push({ html: 'feature_graphic.html', png: 'feature_graphic_1024x500.png', w: 1024, h: 500 });

(async () => {
  const browser = await chromium.launch();
  for (const job of jobs) {
    const page = await browser.newPage({ viewport: { width: job.w, height: job.h }, deviceScaleFactor: 1 });
    await page.goto('file://' + path.join(dir, job.html));
    await page.evaluate(() => document.fonts.ready);
    await page.waitForTimeout(150);
    await page.screenshot({ path: path.join(out, job.png), omitBackground: false });
    await page.close();
    console.log(job.png);
  }
  await browser.close();
})();
