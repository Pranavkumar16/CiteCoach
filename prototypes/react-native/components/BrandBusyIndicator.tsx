import React,{useEffect,useRef,useState} from 'react';
import {AccessibilityInfo,Animated,Easing,Pressable,Text,View} from 'react-native';
import {CiteMark} from './CiteMark';

type Props={label?:string;dark?:boolean;progress?:number;onCancel?:()=>void};
export function BrandBusyIndicator({label='Opening CiteCoach…',dark=false,progress,onCancel}:Props) {
  const rotation=useRef(new Animated.Value(0)).current;
  const [reduceMotion,setReduceMotion]=useState(true);
  const [elapsed,setElapsed]=useState(0);
  useEffect(()=>{
    let active=true;
    AccessibilityInfo.isReduceMotionEnabled().then(value=>{if(active)setReduceMotion(value);});
    const subscription=AccessibilityInfo.addEventListener('reduceMotionChanged',setReduceMotion);
    const started=Date.now();
    const timer=setInterval(()=>setElapsed(Math.floor((Date.now()-started)/1000)),1000);
    return()=>{active=false;subscription.remove();clearInterval(timer);};
  },[]);
  useEffect(()=>{
    if(reduceMotion){rotation.setValue(0);return;}
    const animation=Animated.loop(Animated.timing(rotation,{toValue:1,duration:1800,easing:Easing.linear,useNativeDriver:true}));
    animation.start();
    return()=>animation.stop();
  },[reduceMotion,rotation]);
  const value=progress===undefined?undefined:Math.round(Math.max(0,Math.min(1,progress))*100);
  const ink=dark?'#F6F4EE':'#1F4D3A';
  return <View testID="brand-busy" style={{alignItems:'center',gap:16,padding:24}}>
    <View accessible accessibilityRole="progressbar" accessibilityLabel={label}
      accessibilityValue={value===undefined?{text:'In progress'}:{min:0,max:100,now:value}}
      style={{width:96,height:96,alignItems:'center',justifyContent:'center'}}>
      <Animated.View style={{position:'absolute',width:96,height:96,borderRadius:48,borderWidth:3,
        borderColor:dark?'#254337':'#D7EEE1',borderTopColor:'#F2C56A',
        transform:[{rotate:rotation.interpolate({inputRange:[0,1],outputRange:['0deg','360deg']})}]}}/>
      <CiteMark size={64}/>
    </View>
    <Text accessibilityLiveRegion="polite" style={{color:ink,fontSize:18,fontWeight:'600',textAlign:'center'}}>{label}</Text>
    <Text style={{color:dark?'#B9C9BF':'#5B6B63',fontSize:14}}>
      {value===undefined?'Working…':value+'%'} · {elapsed}s elapsed
    </Text>
    {onCancel&&<Pressable accessibilityRole="button" onPress={onCancel} style={{minHeight:44,padding:12}}>
      <Text style={{color:ink,fontWeight:'600'}}>Cancel</Text>
    </Pressable>}
  </View>;
}
