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
  await page.goto('http://127.0.0.1:4173');await page.getByText('Start with one PDF',{exact:true}).waitFor();
  assert.equal(await page.getByText(/Sample book/).count(),0);
  await page.screenshot({path:`screenshots/home-${viewport.width}.png`});
  await page.getByTestId('nav-Library').click();await page.getByText('Your library is empty.',{exact:true}).waitFor();
  await page.getByTestId('nav-Ask').click();assert.equal(await page.getByTestId('answer-offline').getAttribute('aria-disabled'),'true');
  await page.getByTestId('nav-Learn').click();assert.equal(await page.getByTestId('generate-study').getAttribute('aria-disabled'),'true');
  await page.getByRole('button',{name:'Settings',exact:true}).click();await page.getByTestId('download-model').waitFor();
  await page.getByRole('switch',{name:'Dark appearance'}).click();await page.screenshot({path:`screenshots/settings-${viewport.width}.png`});
  assert.deepEqual(errors,[]);await page.close();
 }
}finally{await browser.close();server.close();}
console.log('Passed: real empty library, model setup, generation guards, dark appearance, portrait and landscape layouts.');
