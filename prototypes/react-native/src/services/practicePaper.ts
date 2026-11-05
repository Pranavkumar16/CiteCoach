export type QuestionKind='mcq'|'short'|'long';
export type PaperSection={title:string;kind:QuestionKind;count:number;answerCount:number;marks:number;instructions:string;optionCount?:number};
export type PaperPlan={title:string;durationMinutes:number;numbering:'continuous'|'section';sections:PaperSection[]};
export type PaperQuestion={section:number;question:string;options?:string[]};
export type PracticePaper={templateId:string;referenceId?:string;topic:string;plan:PaperPlan;questions:PaperQuestion[];updatedAt:number};
export const totalQuestions=(plan:PaperPlan)=>plan.sections.reduce((sum,s)=>sum+s.count,0);
export const totalMarks=(plan:PaperPlan)=>plan.sections.reduce((sum,s)=>sum+s.answerCount*s.marks,0);
export function validatePlan(value:unknown,allowLarge=false):asserts value is PaperPlan {
  const p=value as PaperPlan;
  if(!p||typeof p.title!=='string'||!p.title.trim()||!Number.isInteger(p.durationMinutes)||p.durationMinutes<0||p.durationMinutes>600||!['continuous','section'].includes(p.numbering)||!Array.isArray(p.sections)||!p.sections.length||p.sections.length>8)throw Error('Add a title and at least one section. Check the time and numbering.');
  for(const s of p.sections){if(!s||typeof s.title!=='string'||!s.title.trim()||!['mcq','short','long'].includes(s.kind)||!Number.isInteger(s.count)||s.count<1||s.count>120||!Number.isInteger(s.answerCount)||s.answerCount<1||s.answerCount>s.count||!Number.isInteger(s.marks)||s.marks<1||s.marks>100||typeof s.instructions!=='string')throw Error('Check each section: question count, answer count and marks must be valid whole numbers.');}
  if(p.sections.some(s=>s.kind==='mcq'&&(!Number.isInteger(s.optionCount??4)||(s.optionCount??4)<2||(s.optionCount??4)>6)))throw Error('Multiple-choice sections need between 2 and 6 choices per question.');
  if(!allowLarge&&totalQuestions(p)>60)throw Error('Create up to 60 questions per paper. Reduce the section counts to continue.');
}
export const patternSchema={type:'object',properties:{title:{type:'string'},durationMinutes:{type:'integer',minimum:0,maximum:600},numbering:{type:'string',enum:['continuous','section']},sections:{type:'array',maxItems:8,items:{type:'object',properties:{title:{type:'string'},kind:{type:'string',enum:['mcq','short','long']},count:{type:'integer',minimum:1,maximum:120},answerCount:{type:'integer',minimum:1,maximum:120},marks:{type:'integer',minimum:1,maximum:100},instructions:{type:'string'},optionCount:{type:'integer',minimum:0,maximum:6}},required:['title','kind','count','answerCount','marks','instructions','optionCount'],additionalProperties:false}}},required:['title','durationMinutes','numbering','sections'],additionalProperties:false};
export function parseObject(text:string):Record<string,unknown>{
  const first=text.indexOf('{'),last=text.lastIndexOf('}');if(first<0||last<first)throw Error('Could not finish the response. Please retry.');
  const value:unknown=JSON.parse(text.slice(first,last+1));if(!value||typeof value!=='object'||Array.isArray(value))throw Error('Could not read the response. Please retry.');return value as Record<string,unknown>;
}
export function questionSchema(kind:QuestionKind,choices=4):object {
  return {type:'object',properties:{question:{type:'string',minLength:10,maxLength:900},...(kind==='mcq'?{options:{type:'array',minItems:choices,maxItems:choices,items:{type:'string',minLength:1,maxLength:160}}}:{})},required:kind==='mcq'?['question','options']:['question'],additionalProperties:false};
}
const normalized=(s:string)=>s.toLowerCase().replace(/[^\p{L}\p{N}]+/gu,' ').trim();
export function isCopiedQuestion(question:string,source:string,previous:string[]):boolean {
  const q=normalized(question);if(!q)return true;
  const texts=[normalized(source),...previous.map(normalized)];
  if(texts.some(text=>text.includes(q)))return true;
  const words=q.split(' ');if(words.length<7)return false;
  const triples=words.slice(0,-2).map((_,i)=>words.slice(i,i+3).join(' '));
  return texts.some(text=>triples.filter(phrase=>text.includes(phrase)).length/triples.length>.85);
}
export function validateQuestion(value:Record<string,unknown>,kind:QuestionKind,source:string,previous:string[],choices=4):PaperQuestion {
  if(typeof value.question!=='string'||value.question.trim().length<10)throw Error('The question was incomplete. Try continuing the paper.');
  if(isCopiedQuestion(value.question,source,previous))throw Error('The question was too similar to an existing one. Please retry.');
  if(kind==='mcq'&&(!Array.isArray(value.options)||value.options.length!==choices||value.options.some(o=>typeof o!=='string'||!o.trim())||new Set(value.options.map(o=>String(o).trim().toLowerCase())).size!==choices))throw Error('The multiple-choice options were incomplete. Please retry.');
  return {section:0,question:value.question.trim(),...(kind==='mcq'?{options:value.options as string[]}:{})};
}
export function completePaper(paper:PracticePaper):boolean {
  try{validatePlan(paper.plan);}catch{return false;}
  return paper.questions.length===totalQuestions(paper.plan)&&paper.plan.sections.every((s,i)=>paper.questions.filter(q=>q.section===i).length===s.count);
}
export function patternExcerpt(pages:{page:number;text:string}[]):string {
  const header=pages[0]?.text.slice(0,900)??'';
  const lines=pages.flatMap(p=>p.text.split('\n').filter(line=>/section|part\s+[a-z0-9]|marks|duration|minutes|hours|answer|attempt|choose|questions|^\s*\d+[.)]/i.test(line)).map(line=>'[p.'+p.page+'] '+line));
  return (header+'\n'+lines.join('\n')).slice(0,3500);
}
const escapeHtml=(s:string)=>s.replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;').replace(/'/g,'&#39;');
export function paperHtml(paper:PracticePaper):string {
  if(!completePaper(paper))throw Error('Finish generating all questions before exporting the paper.');
  let number=0;
  const sections=paper.plan.sections.map((section,index)=>{
    if(paper.plan.numbering==='section')number=0;
    const instruction=section.answerCount===section.count?'Answer all '+section.count+' questions.':'Answer any '+section.answerCount+' of '+section.count+' questions.';
    const questions=paper.questions.filter(q=>q.section===index).map(q=>{number++;return '<div class="question"><p><strong>'+number+'.</strong> '+escapeHtml(q.question)+' <span class="marks">['+section.marks+' '+(section.marks===1?'mark':'marks')+']</span></p>'+(q.options?'<ol class="options" type="A">'+q.options.map(option=>'<li>'+escapeHtml(option)+'</li>').join('')+'</ol>':'')+'</div>';}).join('');
    return '<section><h2>'+escapeHtml(section.title)+'</h2><p class="instructions">'+instruction+' '+(section.instructions?escapeHtml(section.instructions):'')+'</p>'+questions+'</section>';
  }).join('');
  return '<!doctype html><html><head><meta charset="utf-8"><style>@page{size:A4;margin:16mm}body{font-family:Arial,sans-serif;color:#14201B;font-size:11pt;line-height:1.5;margin:0}header{border-bottom:2px solid #1F4D3A;padding-bottom:14px;margin-bottom:20px}.brand{color:#1F4D3A;letter-spacing:2px;font-size:9pt}h1{font-size:22pt;line-height:1.2;margin:8px 0}h2{font-size:14pt;color:#1F4D3A;margin:22px 0 6px}section{break-inside:auto}.question{break-inside:avoid;margin:16px 0}.marks{white-space:nowrap;font-weight:bold}.instructions{font-size:10pt;color:#52645A}.options li{padding:3px 0}p{white-space:pre-wrap}footer{font-size:9pt;color:#5B6B63;margin-top:30px}</style></head><body><header><div class="brand">CITECOACH · PRACTICE PAPER</div><h1>'+escapeHtml(paper.plan.title)+'</h1><p>'+totalMarks(paper.plan)+' marks'+(paper.plan.durationMinutes?' · '+paper.plan.durationMinutes+' minutes':'')+'</p><p>Name: __________________________  Date: ______________</p></header>'+sections+'<footer>Generated practice questions. Review before use. This paper does not include an answer key.</footer></body></html>';
}
