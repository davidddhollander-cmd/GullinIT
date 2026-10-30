import fs from 'node:fs/promises';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {createRequire} from 'node:module';
const require=createRequire(import.meta.url);
const sharp=require('C:/Users/david/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/sharp');
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const {data,info}=await sharp(path.join(root,'source/star-source.png')).ensureAlpha().raw().toBuffer({resolveWithObject:true});
let x0=info.width,y0=info.height,x1=-1,y1=-1;
for(let y=0;y<info.height;y++)for(let x=0;x<info.width;x++){
 const p=(y*info.width+x)*4;
 if(data[p+3]>=192){data[p+3]=255;x0=Math.min(x0,x);y0=Math.min(y0,y);x1=Math.max(x1,x);y1=Math.max(y1,y);}
 else data.fill(0,p,p+4);
}
if(x1<0)throw Error('Empty star source');
const report={source_size:[info.width,info.height],source_bounds:{x:x0,y:y0,width:x1-x0+1,height:y1-y0+1},outputs:[]};
for(const size of [16,32,64]){
 const padding=size/16;
 const icon=await sharp(data,{raw:{width:info.width,height:info.height,channels:4}}).extract({left:x0,top:y0,width:x1-x0+1,height:y1-y0+1}).resize(size-padding*2,size-padding*2,{kernel:'nearest',fit:'contain',background:{r:0,g:0,b:0,alpha:0}}).extend({left:padding,right:padding,top:padding,bottom:padding,background:{r:0,g:0,b:0,alpha:0}}).png().toBuffer();
 const name='score-star-retro-'+size+'.png';await fs.writeFile(path.join(root,name),icon);
 const check=await sharp(icon).ensureAlpha().raw().toBuffer();let pixels=0;
 for(let p=3;p<check.length;p+=4){if(check[p]!==0&&check[p]!==255)throw Error('Soft alpha');if(check[p])pixels++;}
 if(!pixels||check[3]!==0)throw Error('Invalid icon');
 report.outputs.push({file:name,width:size,height:size,opaque_pixels:pixels,hard_alpha:true});
}
await fs.writeFile(path.join(root,'validation.json'),JSON.stringify(report,null,2)+'\n');
console.log(JSON.stringify(report));
