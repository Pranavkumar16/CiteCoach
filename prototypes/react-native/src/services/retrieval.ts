import type {PageText,SourceChunk} from '../domain/documents';
const stop=new Set('what is are the a an of to and or in on for with from explain how does do me this it learning'.split(' '));
export function terms(text:string):string[]{return text.toLowerCase().match(/[\p{L}\p{N}]+/gu)?.filter(t=>t.length>1&&!stop.has(t))??[];}
export function retrieve(pages:PageText[],query:string,start=1,end=Infinity):SourceChunk[]{
  const tokens=[...new Set(terms(query))];
  const chunks:SourceChunk[]=[];
  for(const page of pages){
    if(page.page<start||page.page>end)continue;
    // Overlap avoids dropping a definition at a chunk boundary.
    for(let offset=0;offset<page.text.length;offset+=650){
      const text=page.text.slice(offset,offset+950);if(text.trim().length<30)continue;
      const words=terms(text);const counts=new Map<string,number>();for(const w of words)counts.set(w,(counts.get(w)??0)+1);
      const score=tokens.reduce((s,t)=>s+(counts.has(t)?1+Math.log(1+counts.get(t)!):0),0);
      chunks.push({page:page.page,text,score,label:page.label});
    }
  }
  const sorted=chunks.sort((a,b)=>b.score-a.score||a.page-b.page);
  if(tokens.length&&(!sorted.length||sorted[0].score===0))return [];
  const selected:SourceChunk[]=[];
  for(const chunk of sorted){if(!selected.some(c=>c.page===chunk.page&&c.text.includes(chunk.text.slice(0,100))))selected.push(chunk);if(selected.length===3)break;}
  return selected;
}
export function parseStudyJSON(text:string,allowedPages:number[]):unknown{
  const cleaned=text.replace(/<think>[\s\S]*?<\/think>/g,'').replace(/```(?:json)?/g,'').trim();
  const first=cleaned.indexOf('['),last=cleaned.lastIndexOf(']');
  if(first<0||last<first)throw Error('The model did not return a complete study set. Try a narrower topic.');
  const value:unknown=JSON.parse(cleaned.slice(first,last+1));
  if(!Array.isArray(value)||value.length===0)throw Error('The model returned an empty study set.');
  for(const item of value){if(!item||typeof item.q!=='string'||!item.q.trim()||!allowedPages.includes(item.page))throw Error('The generated study set has invalid source references. Please retry.');}
  return value;
}
