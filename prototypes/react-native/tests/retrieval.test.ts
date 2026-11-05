import {test} from 'node:test';
import assert from 'node:assert/strict';
import {retrieve,parseStudyJSON} from '../src/services/retrieval';
const pages=[{page:1,text:'Supervised learning uses labelled training examples. Classification predicts a category such as spam.'},{page:2,text:'Regression predicts a continuous numerical value such as the price of a house.'},{page:3,text:'Clustering finds groups in unlabelled examples without target categories.'}];
test('retrieval ranks relevant pages and respects selected scope',()=>{
  assert.equal(retrieve(pages,'What is supervised learning?')[0].page,1);
  assert.equal(retrieve(pages,'Regression house prices')[0].page,2);
  assert.deepEqual(retrieve(pages,'supervised',2,3),[]);
});
test('unrelated questions do not fabricate evidence',()=>assert.deepEqual(retrieve(pages,'volcanoes magma'),[]));
test('study output requires existing page references and nonempty content',()=>{
  assert.throws(()=>parseStudyJSON('[{"q":"Question","page":99}]',[1,2]));
  assert.throws(()=>parseStudyJSON('[]',[1]));
  assert.throws(()=>parseStudyJSON('not json',[1]));
  assert.deepEqual(parseStudyJSON('```json\n[{"q":"What?","page":1}]\n```',[1]),[{q:'What?',page:1}]);
});
