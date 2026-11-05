import {test} from 'node:test';
import assert from 'node:assert/strict';
import {chatPrompt} from '../src/services/chatPrompt';
test('direct answers start after the closed thinking block',()=>{
  const prompt=chatPrompt('Use the supplied evidence.','Explain supervised learning.');
  assert.ok(prompt.endsWith('<|im_start|>assistant\n<think>\n\n</think>\n\n'));
  assert.ok(prompt.includes('<|im_start|>user\nExplain supervised learning.<|im_end|>'));
  assert.ok(prompt.includes('<|im_start|>system\nUse the supplied evidence.<|im_end|>'));
});
