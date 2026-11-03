/* Ten Shadows Technique: battle summon definitions and effects. */
(() => {
 const roster = [
  {id:"toad",name:"TOAD",cost:0,desc:"A fast binding summon that disrupts the Knight.",effect:"disrupt"},
  {id:"nue",name:"NUE",cost:20,desc:"Nue strikes from above and builds pressure.",damage:24,effect:"tp",gain:5},
  {id:"divine_dog",name:"DIVINE DOG",cost:25,desc:"Divine Dog tears into the Knight and exposes its guard.",damage:31,effect:"expose",turns:1},
  {id:"great_serpent",name:"GREAT SERPENT",cost:30,desc:"The Great Serpent constricts the Knight, slowing its next attack.",damage:27,effect:"disrupt"},
  {id:"max_elephant",name:"MAX ELEPHANT",cost:35,desc:"Max Elephant crashes down with overwhelming force.",damage:42,effect:"damage"},
  {id:"rabbit_escape",name:"RABBIT ESCAPE",cost:18,desc:"A swarm of rabbits creates an opening and steadies the party.",effect:"support",heal:8,tp:8},
  {id:"round_deer",name:"ROUND DEER",cost:32,desc:"Round Deer restores the party's strength.",effect:"heal",heal:18},
  {id:"piercing_ox",name:"PIERCING OX",cost:40,desc:"Piercing Ox builds momentum into a devastating charge.",damage:50,effect:"expose",turns:2},
  {id:"tiger_funeral",name:"TIGER FUNERAL",cost:55,desc:"Tiger Funeral unleashes a fierce strike.",damage:64,effect:"chill",chill:1},
  {id:"mahoraga",name:"MAHORAGA",cost:100,desc:"Mahoraga appears. The adaptation wheel turns.",damage:95,effect:"adapt"}
 ];
 function list(){return roster.map(s=>({...s}));}
 function use(id,ctx){
  const s=roster.find(x=>x.id===id);
  if(!s)throw new Error("Unknown shadow: "+id);
  let damage=0,text=s.desc;
  if(s.damage){const phaseText=ctx.damageBoss(Math.round(s.damage*(ctx.damageMultiplier||1)));damage=ctx.getDamage();text+=phaseText||"";}
  if(s.effect==="disrupt")ctx.disrupt();
  if(s.effect==="expose")ctx.expose(s.turns||1);
  if(s.effect==="tp")ctx.gainTP(s.gain);
  if(s.effect==="support"){ctx.party.filter(p=>p.hp>0).forEach(p=>p.hp=Math.min(p.max,p.hp+s.heal));ctx.gainTP(s.tp);}
  if(s.effect==="heal"){const targets=ctx.party.filter(p=>p.hp>0);targets.forEach(p=>p.hp=Math.min(p.max,p.hp+s.heal));}
  if(s.effect==="chill")ctx.setChill(s.chill);
  if(s.effect==="adapt"){ctx.expose(2);ctx.disrupt();}
  return {text,damage};
 }
 window.ShadowSystem={list,use};
})();