import React from 'react';
import Svg,{Rect,Path,G} from 'react-native-svg';

const drop='M7 9Q7 7 9 7H13Q15 7 15 9V13Q15 15 13 15H10C10 20 8 23 4 24L3 21C6 19 7 17 7 13Z';
export function CiteMark({size=32,reversed=false}:{size?:number;reversed?:boolean}) {
  return <Svg accessibilityElementsHidden importantForAccessibility="no-hide-descendants" width={size} height={size} viewBox="0 0 36 36">
    <Rect width="36" height="36" rx="10" fill={reversed?'#F6F4EE':'#1F4D3A'}/>
    <G transform="translate(1 2)"><Path d={drop} fill={reversed?'#1F4D3A':'#F6F4EE'}/>
      <G transform="translate(13 0)"><Path d={drop} fill={reversed?'#1F4D3A':'#8FCBAC'}/></G>
    </G>
  </Svg>;
}
