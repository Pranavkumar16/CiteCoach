import {chromium} from '@playwright/test';
import {mkdir,readFile} from 'node:fs/promises';
import assert from 'node:assert/strict';
import {paperHtml,type PracticePaper} from '../src/services/practicePaper';
const paper:PracticePaper={templateId:'fixture',topic:'ML',updatedAt:1,plan:{title:'Practice Paper Export Check',durationMinutes:90,numbering:'continuous',sections:[{title:'Section A',kind:'short',count:16,answerCount:12,marks:5,instructions:'Use clear reasoning and original examples.'}]},questions:Array.from({length:16},(_,i)=>({section:0,question:'Question '+(i+1)+': Explain how training, validation and test datasets contribute to a reliable machine learning experiment. Discuss the risks of leakage and justify an evaluation strategy using an original example. Include relevant assumptions and limitations in your explanation.'}))};
await mkdir('screenshots',{recursive:true});
const browser=await chromium.launch();
try{
 const page=await browser.newPage({viewport:{width:794,height:1123}});
 await page.setContent(paperHtml(paper));await page.emulateMedia({media:'print'});
 assert.equal(await page.locator('.question').count(),16);
 assert.match(await page.locator('body').innerText(),/Answer any 12 of 16/);
 await page.screenshot({path:'screenshots/practice-paper-export.png'});
 await page.pdf({path:'screenshots/practice-paper-export.pdf',format:'A4',printBackground:true,preferCSSPageSize:true});
 const bytes=await readFile('screenshots/practice-paper-export.pdf');
 const pages=bytes.toString('latin1').match(/\/Type\s*\/Page(?:\s|\/|>)/g)?.length??0;
 assert.ok(pages>1,'Long papers must paginate across multiple PDF pages.');
 console.log('Passed: question counts, optional-answer instructions, and multi-page PDF export layout.');
}finally{await browser.close();}
