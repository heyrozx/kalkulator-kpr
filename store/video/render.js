// Render stage.html frame demi frame → MP4 (tanpa audio) + events.json untuk SFX.
// node render.js <v|h> <out.mp4> [fps] [cuesJSON]
// node render.js <v|h> snap <outdir> t1,t2,...
const { chromium } = require('playwright');
const { spawn } = require('child_process');
const path = require('path');
const fs = require('fs');

const [ori, mode, a3, a4] = process.argv.slice(2);
const W = ori === 'h' ? 1920 : 1080, H = ori === 'h' ? 1080 : 1920;
const cuesFile = path.join(__dirname, 'cues.json');
const cues = fs.existsSync(cuesFile) ? fs.readFileSync(cuesFile, 'utf8') : '{}';
const url = 'file://' + path.join(__dirname, 'stage.html') + `?o=${ori}&cues=${encodeURIComponent(cues)}`;

(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: W, height: H }, deviceScaleFactor: 1 });
  await page.goto(url);
  await page.evaluate(() => window.READY);
  await page.waitForTimeout(300);
  if (mode === 'snap') {
    fs.mkdirSync(a3, { recursive: true });
    for (const t of a4.split(',').map(Number)) {
      await page.evaluate((t) => window.render(t), t);
      await page.screenshot({ path: path.join(a3, `${ori}_${t.toFixed(2)}.jpg`), type: 'jpeg', quality: 80 });
    }
  } else {
    const fps = Number(a3 || 30);
    const dur = await page.evaluate(() => window.DURATION);
    const events = await page.evaluate(() => window.EVENTS);
    fs.writeFileSync(path.join(__dirname, 'out', `events_${ori}.json`), JSON.stringify({ duration: dur, events }, null, 1));
    const ff = spawn('ffmpeg', ['-y', '-v', 'error', '-f', 'image2pipe', '-framerate', String(fps), '-c:v', 'mjpeg', '-i', '-',
      '-c:v', 'libx264', '-preset', 'medium', '-crf', '18', '-pix_fmt', 'yuv420p', '-r', String(fps), mode], { stdio: ['pipe', 'inherit', 'inherit'] });
    const n = Math.round(dur * fps);
    const t0 = Date.now();
    for (let i = 0; i < n; i++) {
      await page.evaluate((t) => window.render(t), i / fps);
      const buf = await page.screenshot({ type: 'jpeg', quality: 92 });
      if (!ff.stdin.write(buf)) await new Promise(r => ff.stdin.once('drain', r));
      if (i % 150 === 0) console.log(`${ori} frame ${i}/${n} (${((Date.now() - t0) / 1000).toFixed(0)}s)`);
    }
    ff.stdin.end();
    await new Promise(r => ff.on('close', r));
  }
  await browser.close();
})();
