'use strict';
// Manual, per-sprite cleanup for the three fronts ripped with a Pokedex frame
// (header label + black frame border + solid interior field) that the generic
// keyer in clean_bg.js could not handle (the frame walls the field off from the
// image border). Writes results into v12/ (overwriting the boxed copies).
const fs = require('fs'), zlib = require('zlib'), path = require('path');
const SRC = path.join(__dirname, 'v11'), DST = path.join(__dirname, 'v12');

const CRC = (() => { const t = new Uint32Array(256); for (let n = 0; n < 256; n++) { let c = n; for (let k = 0; k < 8; k++) c = (c & 1) ? (0xEDB88320 ^ (c >>> 1)) : (c >>> 1); t[n] = c >>> 0; } return t; })();
function crc32(b){let c=0xFFFFFFFF;for(let i=0;i<b.length;i++)c=CRC[(c^b[i])&0xFF]^(c>>>8);return(c^0xFFFFFFFF)>>>0;}
function decode(file){const b=fs.readFileSync(file);let p=8,idat=[],w,h;while(p<b.length){const len=b.readUInt32BE(p);const t=b.toString('ascii',p+4,p+8);if(t==='IHDR'){w=b.readUInt32BE(p+8);h=b.readUInt32BE(p+12);}else if(t==='IDAT')idat.push(b.slice(p+8,p+8+len));else if(t==='IEND')break;p+=12+len;}const raw=zlib.inflateSync(Buffer.concat(idat));const bpp=4,stride=w*bpp+1,out=Buffer.alloc(w*h*bpp);let prev=Buffer.alloc(w*bpp);for(let y=0;y<h;y++){const ft=raw[y*stride];const line=raw.slice(y*stride+1,y*stride+1+w*bpp);const cur=Buffer.alloc(w*bpp);for(let i=0;i<w*bpp;i++){const a=i>=bpp?cur[i-bpp]:0;const bb=prev[i];const c=i>=bpp?prev[i-bpp]:0;let v=line[i];if(ft===1)v=(v+a)&255;else if(ft===2)v=(v+bb)&255;else if(ft===3)v=(v+((a+bb)>>1))&255;else if(ft===4){const pa=Math.abs(bb-c),pb=Math.abs(a-c),pc=Math.abs(a+bb-2*c);const pr=(pa<=pb&&pa<=pc)?a:(pb<=pc?bb:c);v=(v+pr)&255;}cur[i]=v;}cur.copy(out,y*w*bpp);prev=cur;}return{w,h,out};}
function chunk(type,data){const len=Buffer.alloc(4);len.writeUInt32BE(data.length,0);const t=Buffer.from(type,'ascii');const crc=Buffer.alloc(4);crc.writeUInt32BE(crc32(Buffer.concat([t,data])),0);return Buffer.concat([len,t,data,crc]);}
function encode(w,h,rgba){const sig=Buffer.from([137,80,78,71,13,10,26,10]);const ihdr=Buffer.alloc(13);ihdr.writeUInt32BE(w,0);ihdr.writeUInt32BE(h,4);ihdr[8]=8;ihdr[9]=6;const stride=w*4;const raw=Buffer.alloc((stride+1)*h);for(let y=0;y<h;y++){raw[y*(stride+1)]=0;rgba.copy(raw,y*(stride+1)+1,y*stride,y*stride+stride);}return Buffer.concat([sig,chunk('IHDR',ihdr),chunk('IDAT',zlib.deflateSync(raw,{level:9})),chunk('IEND',Buffer.alloc(0))]);}

function clearPx(out,i){out[i]=out[i+1]=out[i+2]=out[i+3]=0;}
function near(out,i,c,tol2){const dr=out[i]-c[0],dg=out[i+1]-c[1],db=out[i+2]-c[2];return dr*dr+dg*dg+db*db<=tol2;}

// remove everything except the largest 4-connected opaque component
function keepLargest(w,h,out){
  const lab=new Int32Array(w*h).fill(-1);let best=-1,bestSz=0,cur=0;
  for(let s=0;s<w*h;s++){if(lab[s]!==-1||out[s*4+3]<=40)continue;const id=cur++;let sz=0;const st=[s];lab[s]=id;while(st.length){const pi=st.pop();sz++;const x=pi%w,y=(pi/w)|0;const nb=[[x+1,y],[x-1,y],[x,y+1],[x,y-1]];for(const[nx,ny]of nb){if(nx<0||ny<0||nx>=w||ny>=h)continue;const np=ny*w+nx;if(lab[np]!==-1||out[np*4+3]<=40)continue;lab[np]=id;st.push(np);}}if(sz>bestSz){bestSz=sz;best=id;}}
  for(let pi=0;pi<w*h;pi++)if(lab[pi]!==best)clearPx(out,pi*4);
  return bestSz;
}

// flood-clear bg color from the image border via connectivity (protects interior
// same-color detail). Used where the border itself is the bg field (kadabra).
function floodFromBorder(w,h,out,colors,tol2){
  const vis=new Uint8Array(w*h);const st=[];
  const isBg=pi=>{const i=pi*4;if(out[i+3]<8)return true;return colors.some(c=>near(out,i,c,tol2));};
  const seed=(x,y)=>{const pi=y*w+x;if(!vis[pi]){vis[pi]=1;if(isBg(pi))st.push(pi);}};
  for(let x=0;x<w;x++){seed(x,0);seed(x,h-1);}for(let y=0;y<h;y++){seed(0,y);seed(w-1,y);}
  while(st.length){const pi=st.pop();clearPx(out,pi*4);const x=pi%w,y=(pi/w)|0;const nb=[[x+1,y],[x-1,y],[x,y+1],[x,y-1]];for(const[nx,ny]of nb){if(nx<0||ny<0||nx>=w||ny>=h)continue;const np=ny*w+nx;if(vis[np])continue;vis[np]=1;if(isBg(np))st.push(np);}}
}

const JOBS = {
  // green field; Pokemon has no green -> pure color key. crop header + frame edges, drop residue via largest-component.
  blastoise_front: { bg: [[136,200,160]], tol: 78, cropTop: 7, cropBottom: 1, mode: 'colorkey' },
  charizard_front: { bg: [[120,208,152]], tol: 78, cropTop: 7, cropBottom: 1, cropLeft: 4, mode: 'colorkey' },
  // light-gray field touches the image border; whites/spoon are near-gray -> connectivity from border.
  kadabra_front:   { bg: [[240,240,240],[224,224,224]], tol: 42, cropTop: 0, mode: 'flood' },
  // backs of these two carry the same green field + frame (player sees backs). kadabra_back already cleaned.
  blastoise_back:  { bg: [[136,200,160]], tol: 78, cropTop: 3, cropLeft: 1, cropRight: 1, mode: 'colorkey' },
  charizard_back:  { bg: [[120,208,152]], tol: 78, cropLeft: 4, cropRight: 1, mode: 'colorkey' }
};

for (const [nm, cfg] of Object.entries(JOBS)) {
  const { w, h, out } = decode(path.join(SRC, nm + '.png'));
  if (cfg.cropTop)    for (let y = 0; y < cfg.cropTop; y++)        for (let x = 0; x < w; x++) clearPx(out, (y * w + x) * 4);
  if (cfg.cropBottom) for (let y = h - cfg.cropBottom; y < h; y++) for (let x = 0; x < w; x++) clearPx(out, (y * w + x) * 4);
  if (cfg.cropLeft)   for (let x = 0; x < cfg.cropLeft; x++)       for (let y = 0; y < h; y++) clearPx(out, (y * w + x) * 4);
  if (cfg.cropRight)  for (let x = w - cfg.cropRight; x < w; x++)  for (let y = 0; y < h; y++) clearPx(out, (y * w + x) * 4);
  const tol2 = cfg.tol * cfg.tol;
  if (cfg.mode === 'colorkey') {
    for (let i = 0; i < out.length; i += 4) if (out[i + 3] > 8 && cfg.bg.some(c => near(out, i, c, tol2))) clearPx(out, i);
  } else {
    floodFromBorder(w, h, out, cfg.bg, tol2);
  }
  const sz = keepLargest(w, h, out);
  let op = 0; for (let i = 3; i < out.length; i += 4) if (out[i] > 10) op++;
  fs.writeFileSync(path.join(DST, nm + '.png'), encode(w, h, out));
  console.log(nm.padEnd(18), 'kept component', sz, 'px; opaque after', Math.round(op / (w * h) * 100) + '%');
}
