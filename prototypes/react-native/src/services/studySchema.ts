export function studySchema(kind:'cards'|'quiz',pages:number[],count=3):object {
  const properties:Record<string,object>={
    q:{type:'string',minLength:1,maxLength:140},
    page:{type:'integer',enum:[...new Set(pages)]},
  };
  if(kind==='cards')properties.a={type:'string',minLength:1,maxLength:220};
  else {
    properties.options={type:'array',minItems:4,maxItems:4,items:{type:'string',minLength:1,maxLength:80}};
    properties.answer={type:'integer',minimum:0,maximum:3};
    properties.explanation={type:'string',minLength:1,maxLength:200};
  }
  return {type:'array',minItems:count,maxItems:count,items:{type:'object',properties,required:Object.keys(properties),additionalProperties:false}};
}
