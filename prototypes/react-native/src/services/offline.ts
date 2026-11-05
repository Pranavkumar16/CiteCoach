export async function generate(_path:string,_prompt:string,_tokens:number,_onToken:(text:string)=>void,_schema?:object):Promise<string>{throw Error('Offline inference requires the installed Android app.');}
export async function stopGeneration():Promise<void>{}
