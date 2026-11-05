import React,{useEffect,useRef,useState} from 'react';
import {Image,Modal,Pressable,ScrollView,Text,TextInput,View,useWindowDimensions} from 'react-native';
import {SafeAreaView} from 'react-native-safe-area-context';
import type {LocalBook} from '../src/domain/documents';
import {nativeDocuments} from '../src/services/documents';
import {isImage} from '../src/services/documentFormats';
import {createTheme} from '../theme/tokens';
import {BrandBusyIndicator} from './BrandBusyIndicator';

export function FilePreview({book,initialPage,dark,onClose}:{book:LocalBook;initialPage?:number;dark:boolean;onClose:()=>void}){
  const {width}=useWindowDimensions();
  const format=book.format??'pdf';const visual=format==='pdf'||isImage(format);
  const [index,setIndex]=useState(()=>Math.max(0,book.pages.findIndex(page=>page.page===initialPage)));
  const [original,setOriginal]=useState(visual);
  const [uri,setUri]=useState('');const [ratio,setRatio]=useState(1.4);
  const [loading,setLoading]=useState(false);const [error,setError]=useState('');
  const [zoom,setZoom]=useState(1);const [jump,setJump]=useState('');const [retry,setRetry]=useState(0);
  const generation=useRef(0);const page=book.pages[index];const c=createTheme(dark);
  const text={fontFamily:'SourceSans3_400Regular',fontSize:17,lineHeight:25,color:c.text};
  const control=(label:string,onPress:()=>void,disabled=false)=><Pressable accessibilityRole="button" disabled={disabled} accessibilityState={{disabled}} onPress={onPress} style={{padding:12,minHeight:44,borderRadius:12,borderWidth:1,borderColor:c.border,backgroundColor:c.surface,opacity:disabled?.4:1}}><Text style={{color:c.primary,fontFamily:'SourceSans3_600SemiBold',fontSize:15}}>{label}</Text></Pressable>;
  useEffect(()=>{
    const id=++generation.current;let active=true;setUri('');setError('');setZoom(1);
    if(!original||!page){setLoading(false);return()=>{active=false;};}
    setLoading(true);
    if(format==='pdf'){
      void Promise.resolve().then(()=>nativeDocuments().renderPdfPage(book.uri,page.page)).then(result=>{if(active&&id===generation.current){setUri(result.uri);setRatio(result.height/result.width);}})
        .catch(()=>{if(active&&id===generation.current)setError('Could not display this page. Try again or use Text view.');})
        .finally(()=>{if(active&&id===generation.current)setLoading(false);});
    }else{
      setUri(book.uri);
      Image.getSize(book.uri,(w,h)=>{if(active&&id===generation.current){setRatio(h/w);setLoading(false);}},()=>{if(active){setError('Could not display this image. You can still use Text view.');setLoading(false);}});
    }
    return()=>{active=false;};
  },[book.id,page?.page,original,retry]);
  function move(next:number){setIndex(Math.max(0,Math.min(book.pages.length-1,next)));setJump('');}
  const imageWidth=Math.max(240,width-24)*zoom;
  const label=page?.label??(format==='pdf'?'Page '+page?.page:'Section '+page?.page);
  return <Modal visible presentationStyle="fullScreen" animationType="slide" onRequestClose={onClose}>
    <SafeAreaView style={{flex:1,backgroundColor:c.bg}} edges={['top','bottom']}>
      <View style={{padding:16,gap:12,borderBottomWidth:1,borderColor:c.border}}>
        <View style={{flexDirection:'row',gap:12,alignItems:'center'}}><Text numberOfLines={2} style={{...text,flex:1,fontFamily:'SourceSans3_600SemiBold'}}>{book.title}</Text>{control('Close',onClose)}</View>
        <View style={{flexDirection:'row',gap:8,alignItems:'center',flexWrap:'wrap'}}>
          {visual&&control(original?'Text view':'Original',()=>setOriginal(!original))}
          {original&&control('Zoom '+Math.round(zoom*100)+'%',()=>setZoom(value=>value>=3?1:value+.5))}
          <Text style={{...text,fontSize:14}}>{label}</Text>
        </View>
        {!visual&&<Text style={{...text,fontSize:14,color:c.muted}}>Text preview · original formatting may differ</Text>}
      </View>
      {loading?<View style={{flex:1,justifyContent:'center'}}><BrandBusyIndicator label="Opening file…" dark={dark}/></View>:error?<View style={{padding:24,gap:16,flex:1,justifyContent:'center'}}><Text style={text}>{error}</Text>{control('Try again',()=>setRetry(value=>value+1))}{control('Text view',()=>setOriginal(false))}</View>:original&&uri?
        <ScrollView horizontal style={{flex:1}} contentContainerStyle={{flexGrow:1}}><ScrollView nestedScrollEnabled style={{width:imageWidth}} contentContainerStyle={{paddingVertical:12,alignItems:'center'}}><Image accessibilityLabel={book.title+', '+label} source={{uri}} resizeMode="contain" onError={()=>setError('Could not display this page. Use Text view to read it.')} style={{width:imageWidth-16,height:(imageWidth-16)*ratio,backgroundColor:'#FFFFFF'}}/></ScrollView></ScrollView>:
        <ScrollView key={page?.page} contentContainerStyle={{padding:20,paddingBottom:40}}><Text selectable style={text}>{page?.text||'No text was detected on this page.'}</Text></ScrollView>}
      <View style={{padding:12,borderTopWidth:1,borderColor:c.border,gap:8}}>
        <View style={{flexDirection:'row',gap:8,justifyContent:'space-between',alignItems:'center'}}>{control('Previous',()=>move(index-1),index===0)}<Text style={{...text,fontSize:14}}>{index+1} / {book.pages.length}</Text>{control('Next',()=>move(index+1),index>=book.pages.length-1)}</View>
        {book.pages.length>4&&<View style={{flexDirection:'row',gap:8,alignItems:'center'}}><TextInput accessibilityLabel="Preview page number" value={jump} onChangeText={setJump} keyboardType="number-pad" placeholder="Go to page" placeholderTextColor={c.muted} style={{...text,flex:1,minHeight:44,padding:10,borderWidth:1,borderColor:c.border,borderRadius:10}}/>{control('Go',()=>{const number=Number(jump);if(Number.isInteger(number)&&number>=1&&number<=book.pages.length)move(number-1);},!jump||Number(jump)<1||Number(jump)>book.pages.length)}</View>}
      </View>
    </SafeAreaView>
  </Modal>;
}
