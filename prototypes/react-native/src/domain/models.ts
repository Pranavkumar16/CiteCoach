export type Tab = 'Home' | 'Library' | 'Learn' | 'Ask' | 'Settings';
export type Book = {id:string;title:string;meta:string;sample:boolean};
export type Citation = {bookId:string;page:number;excerpt:string};
export type Chapter = {id:string;title:string;startPage:number;endPage:number};
export type GenerationProgress = {
  stage:'loading-model'|'retrieving'|'generating'|'complete';
  elapsedMs:number;
  completedItems?:number;
  totalItems?:number;
};
