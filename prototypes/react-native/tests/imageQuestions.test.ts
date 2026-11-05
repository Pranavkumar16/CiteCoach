import {test} from 'node:test';
import assert from 'node:assert/strict';
import {imageQuestionContext,imageAnswerRules,emptyImageReply} from '../src/services/imageQuestions';
test('dietary questions use the ingredient context despite no matching query keywords',()=>{
 const result=imageQuestionContext([{page:1,text:'Ingredients: potato, palm oil, salt, milk powder.'}],'Is it veg?');
 assert.equal(result.reply,null);assert.match(result.chunks[0].text,/milk powder/);
});
test('empty OCR and nutrition-only OCR return an explicit uncertain answer',()=>{
 for(const text of ['', 'Nutrition information: protein 5g. Made in Malaysia.']){
  const result=imageQuestionContext([{page:1,text}],'Is it veg or not?');assert.match(result.reply!,/can’t confirm/);assert.match(result.reply!,/ingredients/);
 }
});
test('image questions honor source range and do not borrow another page ingredients',()=>{
 const result=imageQuestionContext([{page:1,text:'Ingredients: chicken.'},{page:2,text:'Nutrition: 100 kcal.'}],'Is it veg?',2,2);
 assert.match(result.reply!,/can’t confirm/);assert.equal(result.chunks[0].page,2);
});
test('generic image questions receive context without literal keyword overlap',()=>{
 const result=imageQuestionContext([{page:1,text:'Manager reviews budget approval.'}],'Who reviews it?');assert.equal(result.reply,null);assert.equal(result.chunks.length,1);
});
test('dietary prompts allow interpretation but prevent unsupported certifications',()=>{
 const rules=imageAnswerRules('Is it vegan?');assert.match(rules,/general knowledge/);assert.match(rules,/Milk is vegetarian but not vegan/);assert.match(rules,/Halal does not establish/);assert.match(rules,/Missing meat words do NOT prove/);
 assert.match(emptyImageReply('Is it veg?'),/couldn’t reliably determine/);
});
