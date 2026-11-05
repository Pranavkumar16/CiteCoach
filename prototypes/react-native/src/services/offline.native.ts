import {initLlama,type LlamaContext} from 'llama.rn';
let context:LlamaContext|null=null;
let loading:Promise<LlamaContext>|null=null;
let running=false;
export async function generate(path:string,prompt:string,tokens:number,onToken:(text:string)=>void):Promise<string>{
  if(running)throw Error('An answer is already running. Cancel it before starting another.');
  running=true;
  let timer:ReturnType<typeof setTimeout>|undefined;
  try{
    if(!context){
      loading??=initLlama({model:path,n_ctx:2048,n_batch:256,n_threads:4,n_gpu_layers:0,use_mlock:false});
      try{context=await loading;}finally{loading=null;}
    }
    let text='';let timedOut=false;
    timer=setTimeout(()=>{timedOut=true;void context?.stopCompletion();},120000);
    const result=await context.completion({prompt,n_predict:tokens,temperature:0.15,top_p:0.9,stop:['<|im_end|>','<|endoftext|>']},data=>{text+=data.token;onToken(text);});
    if(timedOut)throw Error('Generation reached the two-minute limit. Try a shorter question or narrower topic.');
    if(!result.text.trim())throw Error('The model returned no answer. Try a shorter question.');
    return result.text.trim();
  }finally{if(timer)clearTimeout(timer);running=false;}
}
export async function stopGeneration(){await context?.stopCompletion();}
