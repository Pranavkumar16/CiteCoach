import sharp from 'sharp';
const source='assets/brand-source.png';
// Asset crops preserve the supplied artwork; no regenerated logo or text.
const icon=await sharp(source).extract({left:88,top:236,width:342,height:344}).png().toBuffer();
await sharp(icon).resize(512,512,{fit:'contain',background:'#FFFFFF'}).png().toFile('assets/brand-icon.png');
await sharp(icon).resize(1024,1024,{fit:'contain',background:'#FFFFFF'}).png().toFile('assets/icon.png');
await sharp(source).extract({left:80,top:225,width:1380,height:365}).png().toFile('assets/brand-lockup.png');
