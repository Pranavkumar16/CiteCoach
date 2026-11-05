import {test} from 'node:test';
import assert from 'node:assert/strict';
import {removeImportedFile,type RemovalStorage} from '../src/services/removeImportedFile';
const root='file:///private/citecoach/';
const book={id:'book-123',title:'Whiteboard.jpg',uri:root+'book-123.jpg',pages:[{page:1,text:'A requirement'}],importedAt:1};
function fixture(){
 const files=new Set([book.uri,root+'book-123.json',root+'book-456.pdf','file:///gallery/Whiteboard.jpg','file:///models/ai.gguf']);
 const values=new Map([['citecoach-books-v1','["book-123","book-456"]'],['study:book-123','cards'],['study:book-456','other cards']]);
 const previews:string[]=[];
 const storage:RemovalStorage={clearPreviews:async uri=>{previews.push(uri);},removeFile:async uri=>{files.delete(uri);},getItem:async key=>values.get(key)??null,removeItem:async key=>{values.delete(key);},setItem:async(key,value)=>{values.set(key,value);}};
 return {files,values,previews,storage};
}
test('deletion removes the private copy, extracted text and study set while preserving other files',async()=>{
 const f=fixture();await removeImportedFile(book,root,f.storage);
 assert.equal(f.files.has(book.uri),false);assert.equal(f.files.has(root+'book-123.json'),false);assert.equal(f.values.has('study:book-123'),false);
 assert.deepEqual(JSON.parse(f.values.get('citecoach-books-v1')!),['book-456']);
 assert.equal(f.files.has(root+'book-456.pdf'),true);assert.equal(f.values.get('study:book-456'),'other cards');
 assert.equal(f.files.has('file:///gallery/Whiteboard.jpg'),true);assert.equal(f.files.has('file:///models/ai.gguf'),true);assert.deepEqual(f.previews,[book.uri]);
});
test('a mismatched file path is rejected before anything is deleted',async()=>{
 const f=fixture();await assert.rejects(()=>removeImportedFile({...book,uri:root+'book-456.pdf'},root,f.storage));
 assert.equal(f.files.size,5);assert.deepEqual(f.previews,[]);
});
test('failed file removal keeps the library entry available for retry',async()=>{
 const f=fixture();f.storage.removeFile=async()=>{throw Error('storage unavailable');};
 await assert.rejects(()=>removeImportedFile(book,root,f.storage));
 assert.equal(f.values.get('citecoach-books-v1'),'["book-123","book-456"]');assert.equal(f.values.get('study:book-123'),'cards');
});
