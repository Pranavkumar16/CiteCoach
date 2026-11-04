import { chromium } from '@playwright/test';
import assert from 'node:assert/strict';
import http from 'node:http';
import { readFile, mkdir } from 'node:fs/promises';
import path from 'node:path';
const root = path.resolve('dist');
const mime = {'.html':'text/html','.js':'application/javascript','.css':'text/css','.json':'application/json','.png':'image/png','.ttf':'font/ttf','.woff':'font/woff','.woff2':'font/woff2','.svg':'image/svg+xml'};
const server = http.createServer(async (req, res) => {
  let file = path.resolve(root, '.' + decodeURIComponent(new URL(req.url, 'http://localhost').pathname));
  if (!file.startsWith(root + path.sep) && file !== root) { res.writeHead(403); res.end(); return; }
  if (file === root) file = path.join(root, 'index.html');
  try { const data = await readFile(file); res.setHeader('Content-Type', mime[path.extname(file)] ?? 'application/octet-stream'); res.end(data); }
  catch { res.setHeader('Content-Type','text/html'); res.end(await readFile(path.join(root,'index.html'))); }
});
await new Promise(resolve => server.listen(4173, '127.0.0.1', resolve));
await mkdir('screenshots', {recursive: true});
const browser = await chromium.launch();
try {
  for (const viewport of [{width:390,height:844},{width:320,height:568}]) {
    const page = await browser.newPage({viewport, deviceScaleFactor:1});
    const errors = [];
    page.on('pageerror', e => errors.push(e.message));
    await page.goto('http://127.0.0.1:4173');
    await page.getByTestId('nav-Home').waitFor();
    await page.screenshot({path:'screenshots/home-' + viewport.width + '.png'});
    await page.getByTestId('nav-Library').click();
    await page.getByTestId('library-search').fill('Foundations');
    assert.equal(await page.getByTestId('book-ds').count(), 1);
    assert.equal(await page.getByTestId('book-ml').count(), 0);
    await page.getByTestId('library-search').fill('');
    await page.screenshot({path:'screenshots/library-' + viewport.width + '.png'});
    await page.getByTestId('nav-Learn').click();
    await page.screenshot({path:'screenshots/learn-' + viewport.width + '.png'});
    await page.getByTestId('start-session').click();
    for (const answer of [0,1,2]) {
      await page.getByTestId('answer-' + answer).click();
      await page.getByTestId('quiz-action').click();
      assert.match(await page.getByTestId('answer-feedback').innerText(), /You got it/);
      if (answer === 0) await page.screenshot({path:'screenshots/quiz-' + viewport.width + '.png'});
      await page.getByTestId('quiz-action').click();
    }
    assert.match(await page.getByTestId('quiz-score').innerText(), /3\s*\/\s*3/);
    await page.getByTestId('nav-Settings').click();
    await page.getByTestId('palette-Indigo').click();
    await page.screenshot({path:'screenshots/settings-' + viewport.width + '.png'});
    assert.deepEqual(errors, []);
    await page.close();
  }
} finally {
  await browser.close();
  server.close();
}
console.log('Passed: library search, quiz feedback and score, palettes, and layouts at 320 and 390 widths.');
