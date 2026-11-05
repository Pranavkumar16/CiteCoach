import {requireOptionalNativeModule} from 'expo-modules-core';
import * as FS from 'expo-file-system/legacy';
import AsyncStorage from '@react-native-async-storage/async-storage';
import {toByteArray} from 'base64-js';
import {extension,isImage,supportedExtensions,plainDocument,officeDocument} from './documentFormats';
import type {LocalBook,PageText,SavedStudy} from '../domain/documents';
export type ModelStatus={ready:boolean;path:string;bytes:number;total:number;status:number;reason:number};
export type ExtractionProgress={current:number;total:number;stage:'ocr'|'text'};
type Bridge={renderPdfPage:(uri:string,page:number)=>Promise<{uri:string;width:number;height:number}>;addListener:(event:string,listener:(progress:ExtractionProgress)=>void)=>{remove:()=>void};extractPdf:(uri:string)=>Promise<PageText[]>;readImage:(uri:string)=>Promise<PageText[]>;startModelDownload:()=>Promise<number>;modelStatus:()=>Promise<ModelStatus>;cancelModelDownload:()=>Promise<void>};
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
  const ext=extension(title);
  if(!supportedExtensions.includes(ext))throw Error('Unsupported file type. Use PDF, an image, DOCX, PPTX, XLSX, OpenDocument, or a text file.');
  const id='book-'+Date.now();const saved=root()+id+'.'+ext;
  try{
    await FS.copyAsync({from:uri,to:saved});
    const info=await FS.getInfoAsync(saved);
    if(!info.exists)throw Error('Could not save this file. Please retry.');
    if(ext!=='pdf'&&info.size>25_000_000)throw Error('Please use a file smaller than 25 MB, or split it into smaller documents.');
    let pages:PageText[];
    if(ext==='pdf')pages=await nativeDocuments().extractPdf(saved);
    else if(isImage(ext))pages=await nativeDocuments().readImage(saved);
    else if(['docx','pptx','xlsx','odt','ods','odp'].includes(ext)){
      const bytes=toByteArray(await FS.readAsStringAsync(saved,{encoding:FS.EncodingType.Base64}));
      try{pages=officeDocument(bytes,ext);}catch(error){
        if(error instanceof Error&&/too large/.test(error.message))throw error;
        throw Error('Could not read this document. Try an unlocked copy or export it as PDF.');
      }
    }else pages=plainDocument(await FS.readAsStringAsync(saved),ext);
    if(!isImage(ext)&&!pages.some(page=>page.text.trim()))throw Error('No readable text found. If this document contains only pictures, export it as PDF or import the images.');
    const book={id,title,uri:saved,pages,importedAt:Date.now(),format:ext};
    await FS.writeAsStringAsync(root()+id+'.json',JSON.stringify(book));
    const ids=JSON.parse(await AsyncStorage.getItem('citecoach-books-v1')??'[]') as string[];
    await AsyncStorage.setItem('citecoach-books-v1',JSON.stringify([...ids,id]));
    return book;
  }catch(error){await FS.deleteAsync(saved,{idempotent:true});await FS.deleteAsync(root()+id+'.json',{idempotent:true});throw error;}
}
export async function saveStudy(study:SavedStudy){await AsyncStorage.setItem('study:'+study.bookId,JSON.stringify(study));}
export async function loadStudy(bookId:string):Promise<SavedStudy>{return JSON.parse(await AsyncStorage.getItem('study:'+bookId)??JSON.stringify({bookId,cards:[],quiz:[]}));}

export function observeExtraction(listener:(progress:ExtractionProgress)=>void){return nativeDocuments().addListener('onExtractionProgress',listener);}
