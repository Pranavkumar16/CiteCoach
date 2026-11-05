import type {PageText,SourceChunk} from '../domain/documents';
import {retrieve} from './retrieval';

export function isOverviewQuestion(query:string):boolean {
  return /\b(?:summari[sz]e|summary|overview|main (?:idea|points|topic))\b/i.test(query)
    || /\b(?:explain|describe|read)\s+(?:(?:this|the|my)\s+)?(?:image|screenshot|photo|picture|document|file|page|slide|whiteboard)\b/i.test(query)
    || /\bwhat\s+(?:is|does)\s+(?:(?:this|the|my)\s+)?(?:image|screenshot|photo|picture|document|file|page|slide|whiteboard)\b/i.test(query)
    || /^\s*(?:what(?:'s| is| does)\s+(?:this|it)\s+(?:about|mean|show)|explain\s+(?:this|it))[?.!\s]*$/i.test(query);
}

export function sourcesForQuestion(pages:PageText[],query:string,start=1,end=Infinity):SourceChunk[]{
  if(!isOverviewQuestion(query))return retrieve(pages,query,start,end);
  // Overview requests describe the source itself. Searching for literal words
  // such as "screenshot" would reject otherwise readable OCR text.
  const chunks:SourceChunk[]=[];
  for(const page of pages){
    if(page.page<start||page.page>end)continue;
    for(let offset=0;offset<page.text.length;offset+=950){
      const text=page.text.slice(offset,offset+950).trim();
      if(text)chunks.push({page:page.page,label:page.label,text,score:0});
    }
  }
  if(chunks.length<=3)return chunks;
  return [chunks[0],chunks[Math.floor((chunks.length-1)/2)],chunks[chunks.length-1]];
}
