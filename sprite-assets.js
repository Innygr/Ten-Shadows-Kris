/* Optional sprite asset loader. Missing files safely fall back to procedural sprites. */
(() => {
 const cache=new Map();let manifest=null,loading=null;
 async function loadManifest(url="assets/sprites/manifest.json"){
  if(manifest)return manifest;
  if(!loading)loading=fetch(url).then(r=>{if(!r.ok)throw new Error("Sprite manifest unavailable");return r.json();}).then(data=>(manifest=data)).catch(err=>{console.warn(err.message);return null;});
  return loading;
 }
 function resolve(path){
  if(!path)return null;
  if(!cache.has(path)){const image=new Image();image.decoding="async";const entry={image,ready:false,failed:false};image.onload=()=>entry.ready=true;image.onerror=()=>entry.failed=true;image.src="assets/sprites/"+path;cache.set(path,entry);}
  return cache.get(path);
 }
 function draw(ctx,key,x,y,w,h){
  if(!manifest)return false;let node=manifest;
  for(const part of key.split("."))node=node&&node[part];
  if(typeof node!=="string")return false;
  const entry=resolve(node);if(!entry||!entry.ready)return false;
  ctx.save();ctx.imageSmoothingEnabled=false;ctx.drawImage(entry.image,x,y,w,h);ctx.restore();return true;
 }
 window.SpriteAssets={loadManifest,draw,status:()=>({manifest:!!manifest,files:cache.size,loaded:[...cache.values()].filter(x=>x.ready).length})};
 loadManifest();
})();
