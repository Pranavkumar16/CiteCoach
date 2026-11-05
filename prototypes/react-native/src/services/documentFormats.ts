import {strFromU8,unzipSync} from 'fflate';
import type {PageText} from '../domain/documents';
export const supportedExtensions=['pdf','jpg','jpeg','png','webp','heic','heif','bmp','txt','md','csv','json','html','htm','xml','docx','pptx','xlsx','odt','ods','odp'];
export function extension(name:string){return name.toLowerCase().split('.').pop()??'';}
export function isImage(ext:string){return ['jpg','jpeg','png','webp','heic','heif','bmp'].includes(ext);}
const decode=(text:string)=>text.replace(/&#(x[0-9a-f]+|\d+);/gi,(_,code)=>{const value=code[0].toLowerCase()==='x'?parseInt(code.slice(1),16):Number(code);return value>=0&&value<=0x10ffff?String.fromCodePoint(value):'';}).replace(/&lt;/g,'<').replace(/&gt;/g,'>').replace(/&quot;/g,'"').replace(/&apos;/g,"'").replace(/&amp;/g,'&').replace(/&nbsp;/g,' ');
const clean=(xml:string)=>decode(xml.replace(/<script\b[^>]*>[\s\S]*?<\/script>/gi,'').replace(/<style\b[^>]*>[\s\S]*?<\/style>/gi,'').replace(/<[^>]+>/g,' ')).replace(/[ \t]+/g,' ').replace(/\n\s*\n+/g,'\n\n').trim();
export function textPages(text:string,label='Section'):PageText[]{
  const pages:PageText[]=[];let remaining=text.replace(/\r\n/g,'\n').trim();
  while(remaining){let cut=Math.min(5000,remaining.length);if(cut<remaining.length){const newline=remaining.lastIndexOf('\n',cut);if(newline>2000)cut=newline;}
    pages.push({page:pages.length+1,text:remaining.slice(0,cut).trim(),label:label+' '+(pages.length+1)});remaining=remaining.slice(cut).trim();
    if(pages.length>1500)throw Error('This document is too long. Split it into smaller files.');
  }
  return pages;
}
export function plainDocument(text:string,ext:string):PageText[]{
  if(ext==='html'||ext==='htm'||ext==='xml')text=clean(text.replace(/<\/(p|div|li|tr|h[1-6])>/gi,'\n').replace(/<br\s*\/?\s*>/gi,'\n'));
  return textPages(text);
}
const tags=(xml:string,tag:string)=>[...xml.matchAll(new RegExp('<'+tag+'(?:\\s[^>]*)?>([\\s\\S]*?)<\\/'+tag+'>','g'))].map(match=>clean(match[1]));
const attribute=(xml:string,key:string)=>decode(xml.match(new RegExp('\\b'+key+'=["\']([^"\']*)["\']'))?.[1]??'');
export function officeDocument(bytes:Uint8Array,ext:string):PageText[]{
  const keep=/^(word\/document\.xml|ppt\/slides\/slide\d+\.xml|xl\/(sharedStrings\.xml|workbook\.xml|_rels\/workbook\.xml\.rels|worksheets\/sheet\d+\.xml)|content\.xml)$/;
  let expected=0;
  const entries=unzipSync(bytes,{filter:entry=>{
    if(!keep.test(entry.name))return false;
    expected+=entry.originalSize;
    if(entry.originalSize>8_000_000||expected>16_000_000)throw Error('This document is too large to read safely. Split it into smaller files.');
    return true;
  }});
  const xml=(name:string)=>entries[name]?strFromU8(entries[name]):'';
  if(ext==='docx')return textPages([...xml('word/document.xml').matchAll(/<w:p(?:\s[^>]*)?>([\s\S]*?)<\/w:p>/g)].map(paragraph=>tags(paragraph[1],'w:t').join('')).join('\n'));
  if(ext==='pptx'){
    return Object.keys(entries).filter(name=>/^ppt\/slides\/slide\d+\.xml$/.test(name)).sort((a,b)=>Number(a.match(/slide(\d+)/)?.[1])-Number(b.match(/slide(\d+)/)?.[1])).map(name=>{
      const page=Number(name.match(/slide(\d+)/)?.[1]);return {page,text:tags(xml(name),'a:t').join('\n'),label:'Slide '+page};
    });
  }
  if(ext==='xlsx'){
    const strings=[...xml('xl/sharedStrings.xml').matchAll(/<si(?:\s[^>]*)?>([\s\S]*?)<\/si>/g)].map(match=>tags(match[1],'t').join(''));
    const relationships=new Map([...xml('xl/_rels/workbook.xml.rels').matchAll(/<Relationship\b[^>]*\/>/g)].map(match=>[attribute(match[0],'Id'),attribute(match[0],'Target')]));
    const sheets=[...xml('xl/workbook.xml').matchAll(/<sheet\b[^>]*\/>/g)];
    return sheets.map((match,index)=>{
      const name=attribute(match[0],'name')||'Sheet '+(index+1);const target=relationships.get(attribute(match[0],'r:id'))??'';
      const filename=target.startsWith('/')?target.slice(1):'xl/'+target.replace(/^\.\//,'');
      const rows=[...xml(filename).matchAll(/<row(?:\s[^>]*)?>([\s\S]*?)<\/row>/g)].map(row=>{
        const cells=[...row[1].matchAll(/<c\b([^>]*?)(?:\/>|>([\s\S]*?)<\/c>)/g)].map(cell=>{
          const type=attribute(cell[1],'t');const body=cell[2]??'';const value=tags(body,'v')[0]??'';
          return attribute(cell[1],'r')+': '+(type==='s'?(strings[Number(value)]??''):type==='inlineStr'?tags(body,'t').join(''):type==='b'?(value==='1'?'TRUE':'FALSE'):value);
        });return cells.join(' | ');
      });
      const text=rows.join('\n');
      if(text.length>200000)throw Error('This worksheet is too large. Split it into smaller files.');
      return {page:index+1,text,label:name};
    });
  }
  // OpenDocument text, presentation and spreadsheet files contain content.xml.
  return textPages(clean(xml('content.xml').replace(/<\/(text:p|text:h|table:table-row)>/g,'\n').replace(/<text:tab\s*\/>/g,'\t')));
}
