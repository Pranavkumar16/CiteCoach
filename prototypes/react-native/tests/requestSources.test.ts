import {test} from 'node:test';
import assert from 'node:assert/strict';
import {sourcesForQuestion} from '../src/services/requestSources';
const image=[{page:1,text:'Purchase approval workflow. Manager reviews the request, finance checks the budget, then procurement creates the order.',label:'Image'}];
test('a generic screenshot question uses OCR text without requiring the word screenshot',()=>{
  const sources=sourcesForQuestion(image,'What is the screenshot about?');
  assert.equal(sources.length,1);assert.match(sources[0].text,/Purchase approval/);assert.equal(sources[0].label,'Image');
});
test('image explanation shortcuts and short readable captions are accepted',()=>{
  assert.equal(sourcesForQuestion(image,'Explain this image').length,1);
  assert.equal(sourcesForQuestion([{page:1,text:'Budget review'}],'What is this image about?')[0].text,'Budget review');
});
test('overview requests respect the selected source range and remain bounded',()=>{
  const pages=Array.from({length:10},(_,i)=>({page:i+1,text:('Source '+(i+1)+' ').repeat(200)}));
  const sources=sourcesForQuestion(pages,'Summarize this document',3,8);
  assert.equal(sources.length,3);assert.ok(sources.every(s=>s.page>=3&&s.page<=8&&s.text.length<=950));
  assert.equal(sources[0].page,3);assert.equal(sources[2].page,8);
});
test('unrelated specific questions still require matching evidence',()=>{
  assert.deepEqual(sourcesForQuestion(image,'Volcanoes and magma'),[]);
  assert.deepEqual(sourcesForQuestion([{page:1,text:''}],'What is this screenshot about?'),[]);
});
