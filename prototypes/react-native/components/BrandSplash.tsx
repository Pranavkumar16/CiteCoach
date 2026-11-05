import React from 'react';
import {Image,View,useWindowDimensions} from 'react-native';
export function BrandSplash(){
  const {width}=useWindowDimensions();
  const imageWidth=Math.min(500,Math.max(200,width-40));
  return <View testID="brand-splash" style={{flex:1,backgroundColor:'#FFFFFF',justifyContent:'center',alignItems:'center',padding:20}}>
    <Image source={require('../assets/brand-lockup.png')} accessibilityLabel="CiteCoach. Your documents, answered. Never uploaded."
      resizeMode="contain" style={{width:imageWidth,height:imageWidth*365/1380}}/>
  </View>;
}
