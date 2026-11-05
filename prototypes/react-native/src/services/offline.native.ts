import {initLlama,type LlamaContext} from 'llama.rn';
let context:LlamaContext|null=null;
let loading:Promise<LlamaContext>|null=null;
let running=false;
let cancellation=0;
export async function generate(path:string,prompt:string,tokens:number,onToken:(text:string)=>void):Promise<string>{
  if(running)throw Error('An answer is already running. Cancel it before starting another.');
  running=true;
  const version=cancellation;
  let timer:ReturnType<typeof setTimeout>|undefined;
  try{
    if(!context){
      if(!loading){
        loading=initLlama({model:path,n_ctx:2048,n_batch:256,n_threads:4,n_gpu_layers:0,use_mlock:false});
        void loading.then(value=>{context=value;loading=null;},()=>{loading=null;});
      }
      let loadTimer:ReturnType<typeof setTimeout>|undefined;
      try{context=await Promise.race([loading,new Promise<never>((_,reject)=>{loadTimer=setTimeout(()=>reject(Error('Model loading exceeded 90 seconds. Close other apps and retry.')),90000);})]);}
      finally{if(loadTimer)clearTimeout(loadTimer);}
    }
    if(version!==cancellation)throw Error('Generation cancelled.');
    let text='';let timedOut=false;
    timer=setTimeout(()=>{timedOut=true;void context?.stopCompletion();},120000);
    const result=await context.completion({prompt,n_predict:tokens,temperature:0.15,top_p:0.9,stop:['<|im_end|>','<|endoftext|>']},data=>{text+=data.token;onToken(text);});
    if(timedOut)throw Error('Generation reached the two-minute limit. Try a shorter question or narrower topic.');
    if(!result.text.trim())throw Error('The model returned no answer. Try a shorter question.');
    return result.text.trim();
  }finally{if(timer)clearTimeout(timer);running=false;}
}
export async function stopGeneration(){cancellation++;await context?.stopCompletion();}
