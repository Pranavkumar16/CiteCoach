// CiteCoach Brand & UX System v1, supplied 5 November 2026.
// One semantic palette across screens. Sample UI content remains explicitly labeled.
export const font = {
  display: 'BricolageGrotesque_800ExtraBold',
  title: 'BricolageGrotesque_700Bold',
  heading: 'BricolageGrotesque_600SemiBold',
  body: 'SourceSans3_400Regular',
  strong: 'SourceSans3_600SemiBold',
  label: 'SourceSans3_700Bold',
  quote: 'SourceSerif4_400Regular_Italic',
} as const;
export const space = {1:4,2:8,3:12,4:16,5:20,6:24,8:32,10:40} as const;
export const radius = {chip:10,control:14,card:18,hero:24,pill:32} as const;
export const motion = {press:120,reveal:240,push:280} as const;
export const typography = {
  display:{fontFamily:font.display,fontSize:32,lineHeight:36,letterSpacing:-.8},
  title:{fontFamily:font.title,fontSize:24,lineHeight:28,letterSpacing:-.4},
  heading:{fontFamily:font.heading,fontSize:20,lineHeight:26},
  body:{fontFamily:font.body,fontSize:17,lineHeight:24},
  small:{fontFamily:font.body,fontSize:15,lineHeight:20},
  label:{fontFamily:font.label,fontSize:14,lineHeight:18},
  eyebrow:{fontFamily:font.label,fontSize:12,lineHeight:16,letterSpacing:1.4},
  quote:{fontFamily:font.quote,fontSize:17,lineHeight:26},
} as const;
export function createTheme(dark: boolean) {
  return {
    bg:dark?'#0F1713':'#F6F4EE',
    surface:dark?'#17251D':'#FFFFFF',
    text:dark?'#EDF4EF':'#14201B',
    muted:dark?'#B8C7BD':'#5B6B63',
    placeholder:dark?'#91A69A':'#8A978F',
    border:dark?'#33483A':'#E5E7E0',
    primary:dark?'#8FCBAC':'#1F4D3A',
    pressed:dark?'#B3DEC6':'#173D2E',
    hero:dark?'#24563F':'#1F4D3A',
    nav:'#0F1F18',
    pale:dark?'#21382C':'#D7EEE1',
    ink:dark?'#C4E8D3':'#14201B',
    practice:dark?'#302A3D':'#E6DFF6',
    amber:dark?'#44391E':'#F2C56A',
    amberText:dark?'#F2C56A':'#654914',
    danger:dark?'#EDB095':'#B9532E',
    dangerBg:dark?'#3E291F':'#F8E5DC',
    buttonInk:dark?'#0F1F18':'#FFFFFF',
    onHero:'#FFFFFF',
    accent:'#8FCBAC',
  };
}
