"""Run pinned GGUF candidates sequentially with llama-server, CPU only.
Usage: python run.py --server /path/llama-server --models /path/models --output results.json
Model directory contains gemma270m.gguf/qwen05b.gguf/qwen3.gguf and matching JSON manifests.
Scores require a separate human review of raw answers against cases.json.
"""
import argparse,json,time,subprocess,urllib.request,urllib.error,statistics,platform
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--server',required=True);p.add_argument('--models',required=True);p.add_argument('--output',required=True);p.add_argument('--only',default='gemma270m,qwen05b,qwen3');args=p.parse_args()
dataset=json.loads(Path(__file__).with_name('cases.json').read_text())
def prompt(name,question):
 instruction='You are CiteCoach. Answer briefly using ONLY the document excerpts. Cite every claim using [Page X]. If the excerpts do not answer the question, say "I could not find this information in the document."'
 text=f'{instruction}\n--- DOCUMENT EXCERPTS ---\n{dataset["context"]}\n--- END EXCERPTS ---\nQuestion: {question}\nGive a short answer with [Page X] citations.'
 if name=='gemma270m':return '<start_of_turn>user\n'+text+'\n<end_of_turn>\n<start_of_turn>model\n'
 if name.startswith('qwen3'):return '<|im_start|>user\n'+text+'\n/no_think<|im_end|>\n<|im_start|>assistant\n<think>\n\n</think>\n\n'
 return '<|im_start|>user\n'+text+'<|im_end|>\n<|im_start|>assistant\n'
results={'created_utc':time.strftime('%Y-%m-%dT%H:%M:%SZ',time.gmtime()),'platform':platform.platform(),'threads':4,'context':2048,'temperature':0.3,'top_p':0.9,'max_tokens':192,'seed':42,'models':[]}
def save():Path(args.output).write_text(json.dumps(results,indent=2))
for name in args.only.split(','):
 log=open(str(Path(args.output).with_name(name+'-server.log')),'w')
 start=time.perf_counter()
 proc=subprocess.Popen([args.server,'-m',str(Path(args.models)/(name+'.gguf')),'--host','127.0.0.1','--port','8097','-c','2048','-t','4','-tb','4','-b','256','-ub','256','-ngl','0','--parallel','1','--no-warmup'],stdout=log,stderr=log)
 try:
  while True:
   if proc.poll() is not None:raise RuntimeError(name+' server failed; see log')
   try:
    urllib.request.urlopen('http://127.0.0.1:8097/health',timeout=1).close();break
   except (urllib.error.URLError,TimeoutError):time.sleep(.2)
  record={'name':name,'manifest':json.loads((Path(args.models)/(name+'.json')).read_text()),'startup_seconds':time.perf_counter()-start,'answers':[]};results['models'].append(record);save()
  # One pass across 20 questions, then repeat 5 direct questions for timing variation.
  for i,case in enumerate(dataset['cases']+dataset['cases'][:5]):
   body={'prompt':prompt(name,case['question']),'n_predict':192,'temperature':.3,'top_p':.9,'top_k':40,'repeat_penalty':1.1,'seed':42,'stream':True,'cache_prompt':False}
   req=urllib.request.Request('http://127.0.0.1:8097/completion',data=json.dumps(body).encode(),headers={'Content-Type':'application/json'})
   start=time.perf_counter();first=None;answer='';last={}
   with urllib.request.urlopen(req,timeout=180) as response:
    for line in response:
     if line.startswith(b'data: '):
      data=json.loads(line[6:]);text=data.get('content','')
      if text and first is None:first=time.perf_counter()-start
      answer+=text
      if data.get('stop'):last=data
   result={'id':case['id'],'repeat':i>=20,'question':case['question'],'answer':answer,'first_text_seconds':first,'total_seconds':time.perf_counter()-start,'timings':last.get('timings',{}),'stop_type':last.get('stop_type'),'truncated':last.get('truncated')}
   record['answers'].append(result);save();print(name,case['id'],round(result['total_seconds'],2),repr(answer[:150]),flush=True)
 finally:
  proc.terminate()
  try:proc.wait(timeout=15)
  except subprocess.TimeoutExpired:proc.kill();proc.wait()
  log.close()
