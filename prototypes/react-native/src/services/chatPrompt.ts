// Qwen3's non-thinking chat template pre-fills an empty thinking block.
// This leaves the generation budget for the answer or constrained study JSON.
export function chatPrompt(system:string,user:string):string {
  return '<|im_start|>system\n'+system+'<|im_end|>\n<|im_start|>user\n'+user+'<|im_end|>\n<|im_start|>assistant\n<think>\n\n</think>\n\n';
}
