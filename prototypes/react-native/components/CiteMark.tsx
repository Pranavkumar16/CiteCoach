import React from 'react';
import {Image} from 'react-native';
import logo from '../assets/citecoach-logo.json';

export function CiteMark({size=32,reversed=false}:{size?:number;reversed?:boolean}) {
  return <Image accessibilityIgnoresInvertColors accessible={false}
    source={{uri:'data:'+logo.mimeType+';base64,'+logo.base64}}
    resizeMode="contain"
    style={{width:size,height:size,borderRadius:Math.round(size*0.22),backgroundColor:'#FFFFFF'}} />;
}
