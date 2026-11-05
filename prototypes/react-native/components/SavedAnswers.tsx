import React,{useEffect,useRef,useState} from 'react';
import {Pressable,Text,View} from 'react-native';
import AsyncStorage from '@react-native-async-storage/async-storage';
import {addSavedAnswer,answersKey,type SavedAnswer} from '../src/services/insights';
import {createTheme} from '../theme/tokens';
type Props={bookId:string;question:string;answer:string;pages:number[];blocked:boolean;dark:boolean;onPreview:(page:number)=>void};
export function SavedAnswers({bookId,question,answer,pages,blocked,dark,onPreview}:Props){
 const [items,setItems]=useState<SavedAnswer[]>([]),[loaded,setLoaded]=useState(false),[error,setError]=useState(''),[saving,setSaving]=useState(false),[expanded,setExpanded]=useState(false);const mounted=useRef(true);const c=createTheme(dark);
 useEffect(()=>{mounted.current=true;void AsyncStorage.getItem(answersKey(bookId)).then(raw=>{if(mounted.current){const data=JSON.parse(raw??'[]');if(!Array.isArray(data))throw Error('Invalid saved answers');setItems(data);setLoaded(true);}}).catch(()=>{if(mounted.current)setError('Could not load saved answers. Reopen this document to retry.');});return()=>{mounted.current=false;};},[bookId]);
 async function write(next:SavedAnswer[]){if(saving||!loaded)return;setSaving(true);setError('');try{await AsyncStorage.setItem(answersKey(bookId),JSON.stringify(next));if(mounted.current)setItems(next);}catch{if(mounted.current)setError('Could not save the change. Please retry.');}finally{if(mounted.current)setSaving(false);}}
 const text={fontFamily:'SourceSans3_400Regular',fontSize:16,lineHeight:23,color:c.text};
 const button=(label:string,action:()=>void,disabled=false)=><Pressable accessibilityRole="button" disabled={disabled} onPress={action} style={{padding:12,minHeight:44,borderRadius:12,borderWidth:1,borderColor:c.border,opacity:disabled?0.45:1}}><Text style={{...text,color:c.primary}}>{label}</Text></Pressable>;
 const saved=items.some(item=>item.question===question.trim()&&item.answer===answer.trim());
 return <View testID="saved-answers" style={{padding:16,gap:12,borderRadius:18,borderWidth:1,borderColor:c.border,backgroundColor:c.surface}}>
  {!!answer&&button(saved?'Answer saved':'Save answer',()=>void write(addSavedAnswer(items,question,answer,pages)),!loaded||saving||blocked||saved||!question.trim())}
  {button('Saved answers ('+items.length+') '+(expanded?'−':'+'),()=>setExpanded(!expanded))}
  {!!error&&<Text accessibilityRole="alert" style={text}>{error}</Text>}
  {expanded&&(items.length?items.map(item=><View key={item.id} style={{gap:10,paddingVertical:12,borderTopWidth:1,borderColor:c.border}}><Text style={{...text,fontFamily:'SourceSans3_600SemiBold'}}>{item.question}</Text><Text selectable style={text}>{item.answer}</Text><View style={{flexDirection:'row',flexWrap:'wrap',gap:8}}>{item.pages.map(page=><React.Fragment key={page}>{button('Source '+page,()=>onPreview(page))}</React.Fragment>)}{button('Remove saved answer',()=>void write(items.filter(value=>value.id!==item.id)),saving||!loaded)}</View></View>):<Text style={text}>Save useful answers here to revisit them offline.</Text>)}
 </View>;
}
