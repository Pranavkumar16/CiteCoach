import {test} from 'node:test';
import assert from 'node:assert/strict';
import {insightSources,parseInsight,addSavedAnswer,insightKey,answersKey} from '../src/services/insights';
const book={id:'book-123',title:'Notes',uri:'file:///notes',importedAt:1,pages:[{page:1,text:'Supervised learning uses labelled examples.'}]};
const output={summary:'A supervised learning introduction.',points:['Uses labelled examples.','Learns a mapping.','Predicts new outcomes.'],questions:['What is supervised learning?','What are labels?','How are predictions made?']};
test('summaries preserve source pages and explicitly flag sampled long documents',()=>{
 const short=insightSources(book);assert.equal(short.sampled,false);assert.equal(short.chunks.length,1);
 const long=insightSources({...book,pages:Array.from({length:12},(_,i)=>({page:i+1,text:'Example text. '.repeat(200)}))});
 assert.equal(long.sampled,true);assert.equal(long.chunks.length,3);assert.equal(long.chunks[0].page,1);assert.equal(long.chunks[2].page,12);
 assert.equal(insightSources({...book,pages:[{page:1,text:''}]}).chunks.length,0);
});
test('validated summaries persist questions, points and actual source numbers',()=>{
 const result=parseInsight(JSON.stringify(output),book.id,insightSources(book).chunks,false);
 assert.equal(result.bookId,book.id);assert.deepEqual(result.pages,[1]);assert.equal(result.questions.length,3);assert.equal(result.summary,output.summary);
});
test('incomplete or malformed summaries are rejected rather than saved',()=>{
 for(const raw of ['bad json',JSON.stringify({...output,questions:[]}),JSON.stringify({...output,summary:''}),JSON.stringify({...output,points:[null,'A','B']})])assert.throws(()=>parseInsight(raw,book.id,[],false));
});
test('bookmarking keeps the original answer and sources, ignores duplicates, and uses per-document storage',()=>{
 const items=addSavedAnswer([],'What are labels?','Known outputs.',[2,2,4]);assert.deepEqual(items[0].pages,[2,4]);
 assert.equal(addSavedAnswer(items,'What are labels?','Known outputs.',[2]),items);
 assert.equal(addSavedAnswer(items,'Another question','Another answer',[]).length,2);
 assert.throws(()=>addSavedAnswer(items,'','',[]));assert.notEqual(insightKey('book-1'),insightKey('book-2'));assert.notEqual(answersKey('book-1'),answersKey('book-2'));
});
