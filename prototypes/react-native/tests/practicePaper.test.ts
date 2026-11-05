import {test} from 'node:test';
import assert from 'node:assert/strict';
import {completePaper,isCopiedQuestion,paperHtml,totalMarks,totalQuestions,validatePlan,validateQuestion,type PaperPlan,type PracticePaper} from '../src/services/practicePaper';
const plan:PaperPlan={title:'Machine Learning Practice',durationMinutes:90,numbering:'continuous',sections:[{title:'Section A',kind:'mcq',count:2,answerCount:2,marks:2,optionCount:5,instructions:''},{title:'Section B',kind:'short',count:3,answerCount:2,marks:5,instructions:'Show working.'}]};
const paper:PracticePaper={templateId:'book-1',topic:'ML',updatedAt:1,plan,questions:[{section:0,question:'Which measure is appropriate for imbalanced classification?',options:['Accuracy','F1 score','Mean squared error','R squared','Variance']},{section:0,question:'Which validation method repeatedly partitions a dataset?',options:['Cross-validation','Encoding','Normalization','Clustering','Sampling bias']},{section:1,question:'Explain the purpose of a separate test dataset.'},{section:1,question:'Compare regression with classification using original examples.'},{section:1,question:'Explain how regularization affects model generalization.'}]};
test('paper totals preserve optional-question marking rules',()=>{validatePlan(plan);assert.equal(totalQuestions(plan),5);assert.equal(totalMarks(plan),14);assert.equal(completePaper(paper),true);});
test('invalid answer counts and too-large papers are rejected before generation',()=>{
 assert.throws(()=>validatePlan({...plan,sections:[{...plan.sections[0],answerCount:3}]}));
 assert.throws(()=>validatePlan({...plan,sections:[{...plan.sections[0],count:61,answerCount:61}]}));
});
test('new questions cannot copy sample text or prior questions',()=>{
 assert.equal(isCopiedQuestion('What is supervised learning?','Question 1: What is supervised learning? (2 marks)',[]),true);
 assert.equal(isCopiedQuestion('Explain the purpose of a separate test dataset.','',paper.questions.map(q=>q.question)),true);
 assert.equal(isCopiedQuestion('How would you detect data leakage in a validation pipeline?','What is supervised learning?',[]),false);
});
test('MCQ choice counts follow the reviewed sample pattern',()=>{
 const value={question:'Which evaluation method detects overfitting?',options:['One','Two','Three','Four','Five']};
 assert.equal(validateQuestion(value,'mcq','unrelated source text',[],5).options?.length,5);
 assert.throws(()=>validateQuestion(value,'mcq','unrelated source text',[],4));
});
test('export preserves marks and instructions, escapes HTML and rejects incomplete papers',()=>{
 const html=paperHtml({...paper,plan:{...plan,title:'<script>alert(1)</script>'}});
 assert.ok(html.includes('14 marks'));assert.ok(html.includes('90 minutes'));assert.ok(html.includes('Answer any 2 of 3 questions.'));assert.ok(html.includes('Show working.'));
 assert.equal(html.includes('<script>'),false);assert.ok(html.includes('&lt;script&gt;'));
 assert.throws(()=>paperHtml({...paper,questions:paper.questions.slice(0,2)}));
});
