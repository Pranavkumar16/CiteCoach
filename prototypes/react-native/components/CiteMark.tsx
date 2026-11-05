import React from 'react';
import {Image} from 'react-native';
export function CiteMark({size=32,reversed=false}:{size?:number;reversed?:boolean}) {
  return <Image accessibilityIgnoresInvertColors accessible={false}
    source={require('../assets/brand-icon.png')} resizeMode="contain"
    style={{width:size,height:size,borderRadius:Math.round(size*0.22)}} />;
}
