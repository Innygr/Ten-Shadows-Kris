/* Pixel-accurate sprite-sheet helper.
 * Define frame rectangles in source-image pixels (not scaled display pixels).
 * Render scale is integer-only and image smoothing is always disabled.
 */
class PixelSpriteSheet {
 constructor({image,scale=2,smoothing=false,frames={},animations={}}={}){
  this.src=image;this.scale=Math.max(1,Math.floor(scale));this.smoothing=!!smoothing;
  this.frames=frames;this.animations=animations;this.image=new Image();
  this.ready=false;this.failed=false;this.startedAt=performance.now();
  this.image.onload=()=>{this.ready=true;};
  this.image.onerror=()=>{this.failed=true;console.warn("Sprite sheet failed to load:",this.src);};
 }
 load(){this.image.src=this.src;return this;}
 hasAnimation(name){return !!this.animations[name]&&this.animations[name].frames.length>0;}
 defineFrame(name,rect){this.frames[name]={x:rect.x,y:rect.y,w:rect.w,h:rect.h};return this;}
 defineAnimation(name,frames,fps=8,loop=true){this.animations[name]={frames:[...frames],fps,loop};return this;}
 frameAt(name,time=performance.now()){
  const anim=this.animations[name];if(!anim||!anim.frames.length)return null;
  const step=Math.floor((time-this.startedAt)*anim.fps/1000);
  const index=anim.loop?step%anim.frames.length:Math.min(step,anim.frames.length-1);
  return this.frames[anim.frames[index]]||null;
 }
 draw(ctx,name,x,y,time=performance.now()){
  if(!this.ready)return false;
  const rect=this.frameAt(name,time);if(!rect)return false;
  ctx.save();ctx.imageSmoothingEnabled=this.smoothing;
  ctx.drawImage(this.image,rect.x,rect.y,rect.w,rect.h,x,y,rect.w*this.scale,rect.h*this.scale);
  ctx.restore();return true;
 }
}
window.PixelSpriteSheet=PixelSpriteSheet;
