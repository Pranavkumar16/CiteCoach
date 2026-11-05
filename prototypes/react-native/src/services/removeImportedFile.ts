import type {LocalBook} from '../domain/documents';
export type RemovalStorage={
  clearPreviews:(uri:string)=>Promise<void>;
  removeFile:(uri:string)=>Promise<void>;
  getItem:(key:string)=>Promise<string|null>;
  removeItem:(key:string)=>Promise<void>;
  setItem:(key:string,value:string)=>Promise<void>;
};
export async function removeImportedFile(book:LocalBook,root:string,storage:RemovalStorage):Promise<void>{
  if(!/^book-[0-9]+$/.test(book.id)||!book.uri.startsWith(root+book.id+'.'))throw Error('Could not remove this file safely.');
  const ids:unknown=JSON.parse(await storage.getItem('citecoach-books-v1')??'[]');
  if(!Array.isArray(ids)||ids.some(id=>typeof id!=='string'))throw Error('Could not read the library. Reopen CiteCoach and retry.');
  await storage.clearPreviews(book.uri);
  await storage.removeFile(book.uri);
  await storage.removeFile(root+book.id+'.json');
  await storage.removeItem('study:'+book.id);
  await storage.setItem('citecoach-books-v1',JSON.stringify(ids.filter(id=>id!==book.id)));
}
