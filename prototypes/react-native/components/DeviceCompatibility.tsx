import React,{useState} from 'react';
import {Pressable,Text,View} from 'react-native';
import {assessDevice,type DeviceSnapshot} from '../src/services/deviceCompatibility';
import {createTheme} from '../theme/tokens';
type Props={device:DeviceSnapshot|null;checking:boolean;error:string;dark:boolean;onRefresh:()=>void;onManageStorage:()=>void};
export function DeviceCompatibility({device,checking,error,dark,onRefresh,onManageStorage}:Props){
  const [expanded,setExpanded]=useState(false);const c=createTheme(dark);const assessment=device?assessDevice(device):null;
  const body={fontFamily:'SourceSans3_400Regular',fontSize:15,lineHeight:21,color:c.text};
  const button=(label:string,onPress:()=>void)=><Pressable accessibilityRole="button" disabled={checking} onPress={onPress} style={{paddingVertical:11,paddingHorizontal:12,minHeight:44,borderRadius:12,borderWidth:1,borderColor:c.border,opacity:checking?0.5:1}}><Text style={{...body,fontFamily:'SourceSans3_600SemiBold',color:c.primary}}>{label}</Text></Pressable>;
  return <View testID="device-check" style={{padding:16,gap:12,borderWidth:1,borderColor:c.border,borderRadius:18,backgroundColor:c.surface}}>
    <Text style={{...body,fontFamily:'SourceSans3_600SemiBold',fontSize:18}}>Device check</Text>
    <Text accessibilityLiveRegion="polite" style={{...body,fontFamily:'SourceSans3_600SemiBold'}}>{checking?'Checking your device…':assessment?.title??'Check unavailable'}</Text>
    {error?<Text style={body}>{error}</Text>:device&&<Text style={{...body,color:c.muted}}>{device.deviceName}</Text>}
    {assessment&&<>
      {(expanded?assessment.checks:assessment.checks.filter(check=>check.state!=='pass')).map(check=><View key={check.key} style={{gap:4}}><Text style={{...body,fontFamily:'SourceSans3_600SemiBold'}}>{check.state==='pass'?'✓':check.state==='warn'?'!':'×'} {check.label} · {check.value}</Text><Text style={{...body,color:c.muted}}>{check.detail}</Text></View>)}
      <Pressable accessibilityRole="button" accessibilityState={{expanded}} onPress={()=>setExpanded(!expanded)} style={{paddingVertical:8}}><Text style={{...body,color:c.primary}}>{expanded?'Hide device details':'Show device details'}</Text></Pressable>
      <Text style={{...body,fontSize:13,color:c.muted}}>Memory guidance is an estimate. These checks do not predict response speed.</Text>
    </>}
    <View style={{flexDirection:'row',flexWrap:'wrap',gap:8}}>{button('Recheck',onRefresh)}{assessment?.checks.some(check=>check.key==='storage'&&check.state!=='pass')&&button('Manage storage',onManageStorage)}</View>
  </View>;
}
