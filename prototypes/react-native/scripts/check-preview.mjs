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
      assert.match(await page.getByTestId('answer-feedback').innerText(), /Correct\./);
      if (answer === 0) await page.screenshot({path:'screenshots/quiz-' + viewport.width + '.png'});
      await page.getByTestId('quiz-action').click();
    }
    assert.match(await page.getByTestId('quiz-score').innerText(), /3\s*\/\s*3/);
    await page.getByTestId('nav-Ask').click();
    await page.getByTestId('ask-input').fill('What is the difference between supervised and unsupervised learning?');
    await page.getByTestId('send-ask').click();
    await page.getByTestId('citation-12').click();
    await page.getByTestId('close-modal').click();
    await page.getByTestId('save-answer-card').click();
    assert.match(await page.getByTestId('save-answer-card').innerText(), /Added to sample flashcards/);
    await page.screenshot({path:'screenshots/ask-' + viewport.width + '.png'});
    await page.getByTestId('nav-Learn').click();
    await page.getByTestId('start-session').click();
    await page.getByTestId('answer-1').click();
    await page.getByTestId('quiz-action').click();
    assert.match(await page.getByTestId('answer-feedback').innerText(), /Not quite/);
    await page.getByTestId('citation-12').click();
    await page.getByTestId('close-modal').click();
    await page.screenshot({path:'screenshots/quiz-wrong-' + viewport.width + '.png'});
    await page.getByTestId('nav-Home').click();
    assert.match(await page.getByTestId('home-review').innerText(), /1 cards in review/);
    await page.getByTestId('open-settings').click();
    assert.equal(await page.getByTestId('nav-Settings').count(), 0);
    await page.screenshot({path:'screenshots/settings-' + viewport.width + '.png'});
    await page.getByRole('switch',{name:'Dark appearance'}).click();
    await page.getByLabel('Back to Home').click();
    await page.screenshot({path:'screenshots/home-dark-' + viewport.width + '.png'});
    await page.getByTestId('open-settings').click();
    await page.getByTestId('empty-library-preview').click();
    await page.getByTestId('try-sample-book').waitFor();
    assert.equal(await page.getByTestId('nav-Home').count(), 0);
    await page.screenshot({path:'screenshots/empty-' + viewport.width + '.png'});
    await page.getByTestId('try-sample-book').click();
    await page.getByTestId('nav-Home').waitFor();
    assert.deepEqual(errors, []);
    await page.close();
  }
} finally {
  await browser.close();
  server.close();
}
console.log('Passed: search, quiz scoring, correct/wrong feedback, citations, Ask-to-flashcard, review, avatar Settings, dark and empty states at 320 and 390 widths.');
