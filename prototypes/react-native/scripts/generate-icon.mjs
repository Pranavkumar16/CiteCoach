import sharp from 'sharp';
import {readFile} from 'node:fs/promises';
const logo=JSON.parse(await readFile('assets/citecoach-logo.json','utf8'));
await sharp(Buffer.from(logo.base64,'base64')).resize(1024,1024,{fit:'contain',background:'#FFFFFF'}).png().toFile('assets/icon.png');
