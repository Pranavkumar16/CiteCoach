import {requireOptionalNativeModule} from 'expo-modules-core';
import * as FS from 'expo-file-system/legacy';
import AsyncStorage from '@react-native-async-storage/async-storage';
import type {LocalBook,PageText,SavedStudy} from '../domain/documents';
export type ModelStatus={ready:boolean;path:string;bytes:number;total:number;status:number;reason:number};
export type ExtractionProgress={current:number;total:number;stage:'ocr'|'text'};
type Bridge={addListener:(event:string,listener:(progress:ExtractionProgress)=>void)=>{remove:()=>void};extractPdf:(uri:string)=>Promise<PageText[]>;startModelDownload:()=>Promise<number>;modelStatus:()=>Promise<ModelStatus>;cancelModelDownload:()=>Promise<void>};
const bridge=requireOptionalNativeModule<Bridge>('CiteCoachDocuments');
export function nativeDocuments():Bridge{if(!bridge)throw Error('PDF processing and model downloads require the Android app.');return bridge;}
const root=()=>{if(!FS.documentDirectory)throw Error('Device storage is unavailable.');return FS.documentDirectory+'citecoach/';};
export async function loadBooks():Promise<LocalBook[]>{
  const index=JSON.parse(await AsyncStorage.getItem('citecoach-books-v1')??'[]') as string[];
  const books:LocalBook[]=[];
  for(const id of index){try{books.push(JSON.parse(await FS.readAsStringAsync(root()+id+'.json')));}catch{/* A failed write must not prevent other books opening. */}}
  return books;
}
export async function importBook(uri:string,title:string):Promise<LocalBook>{
  await FS.makeDirectoryAsync(root(),{intermediates:true});
  const id='book-'+Date.now();const saved=root()+id+'.pdf';
  try{
    await FS.copyAsync({from:uri,to:saved});
    const pages=await nativeDocuments().extractPdf(saved);
    const book={id,title,uri:saved,pages,importedAt:Date.now()};
    await FS.writeAsStringAsync(root()+id+'.json',JSON.stringify(book));
    const ids=JSON.parse(await AsyncStorage.getItem('citecoach-books-v1')??'[]') as string[];
    await AsyncStorage.setItem('citecoach-books-v1',JSON.stringify([...ids,id]));
    return book;
  }catch(error){await FS.deleteAsync(saved,{idempotent:true});await FS.deleteAsync(root()+id+'.json',{idempotent:true});throw error;}
}
export async function saveStudy(study:SavedStudy){await AsyncStorage.setItem('study:'+study.bookId,JSON.stringify(study));}
export async function loadStudy(bookId:string):Promise<SavedStudy>{return JSON.parse(await AsyncStorage.getItem('study:'+bookId)??JSON.stringify({bookId,cards:[],quiz:[]}));}

export function observeExtraction(listener:(progress:ExtractionProgress)=>void){return nativeDocuments().addListener('onExtractionProgress',listener);}
