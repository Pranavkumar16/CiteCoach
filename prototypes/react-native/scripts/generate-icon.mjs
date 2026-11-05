import sharp from 'sharp';
await sharp('assets/citecoach-mark.svg').resize(1024,1024).png().toFile('assets/icon.png');
