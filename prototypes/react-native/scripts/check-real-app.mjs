import {chromium} from '@playwright/test';
import assert from 'node:assert/strict';
import http from 'node:http';
import {readFile,mkdir} from 'node:fs/promises';
import path from 'node:path';
const root=path.resolve('dist');
const mime={'.html':'text/html','.js':'application/javascript','.css':'text/css','.json':'application/json','.png':'image/png','.ttf':'font/ttf','.woff':'font/woff','.woff2':'font/woff2'};
const server=http.createServer(async(req,res)=>{
 let file=path.resolve(root,'.'+decodeURIComponent(new URL(req.url,'http://localhost').pathname));
 if(!file.startsWith(root+path.sep)&&file!==root){res.writeHead(403);res.end();return;}
 if(file===root)file=path.join(root,'index.html');
 try{const bytes=await readFile(file);res.setHeader('Content-Type',mime[path.extname(file)]??'application/octet-stream');res.end(bytes);}
 catch{res.setHeader('Content-Type','text/html');res.end(await readFile(path.join(root,'index.html')));}
});
await new Promise(resolve=>server.listen(4173,'127.0.0.1',resolve));await mkdir('screenshots',{recursive:true});
const browser=await chromium.launch();
try{
 for(const viewport of [{width:390,height:844},{width:320,height:568},{width:844,height:390}]){
  const page=await browser.newPage({viewport});const errors=[];page.on('pageerror',error=>errors.push(error.message));
  await page.goto('http://127.0.0.1:4173');await page.getByTestId('setup-title').waitFor();
  await page.getByTestId('download-model').waitFor();
  await page.getByTestId('device-check').waitFor();
  assert.equal(await page.getByTestId('download-model').getAttribute('aria-disabled'),'true');
  await page.getByRole('button',{name:'Recheck',exact:true}).click();
  await page.getByText('Device checks are available in the Android app.').waitFor();
  assert.equal(await page.getByTestId('nav-Library').count(),0);
  assert.equal(await page.getByTestId('nav-Ask').count(),0);
  assert.equal(await page.getByText(/Qwen|CPU|GGUF|Gemma/).count(),0);
  await page.screenshot({path:`screenshots/setup-${viewport.width}.png`});
  assert.deepEqual(errors,[]);await page.close();
 }
}finally{await browser.close();server.close();}
console.log('Passed: one-time setup is the first screen, library and Ask are gated until AI is ready, clean branded copy, portrait and landscape layouts.');
