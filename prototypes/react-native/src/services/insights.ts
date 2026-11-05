import type {LocalBook,SourceChunk} from '../domain/documents';
import {sourcesForQuestion} from './requestSources';
export type Insight={version:1;bookId:string;summary:string;points:string[];questions:string[];pages:number[];sampled:boolean;createdAt:number};
export type SavedAnswer={id:string;question:string;answer:string;pages:number[];createdAt:number};
export const insightKey=(id:string)=>'insight:'+id;
export const answersKey=(id:string)=>'answers:'+id;
export function insightSources(book:LocalBook):{chunks:SourceChunk[];sampled:boolean}{
 const chunks=sourcesForQuestion(book.pages,'Summarize this document');
 return {chunks,sampled:book.pages.reduce((sum,page)=>sum+page.text.trim().length,0)>chunks.reduce((sum,chunk)=>sum+chunk.text.length,0)};
}
export const insightSchema=JSON.stringify({type:'object',properties:{summary:{type:'string'},points:{type:'array',items:{type:'string'},minItems:3,maxItems:5},questions:{type:'array',items:{type:'string'},minItems:3,maxItems:3}},required:['summary','points','questions'],additionalProperties:false});
export function parseInsight(raw:string,bookId:string,chunks:SourceChunk[],sampled:boolean):Insight{
 const clean=raw.trim().replace(/^```(?:json)?\s*/i,'').replace(/\s*```$/,'');
 const value=JSON.parse(clean);
 const strings=(items:unknown,min:number,max:number)=>Array.isArray(items)&&items.length>=min&&items.length<=max&&items.every(item=>typeof item==='string'&&item.trim().length>0&&item.length<=500);
 if(typeof value.summary!=='string'||!value.summary.trim()||value.summary.length>1500||!strings(value.points,3,5)||!strings(value.questions,3,3))throw Error('The summary was incomplete. Please retry.');
 return {version:1,bookId,summary:value.summary.trim(),points:value.points.map((s:string)=>s.trim()),questions:value.questions.map((s:string)=>s.trim()),pages:[...new Set(chunks.map(c=>c.page))],sampled,createdAt:Date.now()};
}
export function addSavedAnswer(items:SavedAnswer[],question:string,answer:string,pages:number[]):SavedAnswer[]{
 if(!question.trim()||!answer.trim())throw Error('Ask a question before saving an answer.');
 if(items.some(item=>item.question===question.trim()&&item.answer===answer.trim()))return items;
 return [{id:'answer-'+Date.now()+'-'+Math.random().toString(36).slice(2,8),question:question.trim(),answer:answer.trim(),pages:[...new Set(pages)],createdAt:Date.now()},...items];
}
