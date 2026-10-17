/* Pup Trail shared data: breeds, worlds, items, avatar pieces, questions */
window.PT = (function(){
const BREEDS = {
  bear:   {name:'Golden Retriever', rare:-1, skill:'Cheer', skillText:'One scared pup per trail gets a second chance.', bark:[320,0.18]},
  lip:    {name:'Lab-Hound Mix', rare:-1, skill:'Sniff', skillText:'+5 bonus coins on every right answer.', bark:[200,0.25]},
  golden: {name:'Golden Retriever', rare:0, skill:'Cheer', skillText:'One scared pup per trail gets a second chance.', bark:[320,0.18], names:['Sunny','Biscuit','Honey','Waffles'], persona:['loves everybody and wags at squirrels','carries a stick everywhere, no reason','falls asleep in puddles']},
  labhound:{name:'Lab-Hound Mix', rare:0, skill:'Sniff', skillText:'+5 bonus coins on every right answer.', bark:[200,0.25], names:['Bruno','Pepper','Maple','Scout'], persona:['nose to the ground, always on a scent','howls at the mail truck','steals socks and hides them']},
  beagle: {name:'Beagle', rare:0, skill:'Tracker', skillText:'Finds one extra pup spot on every trail.', bark:[420,0.14], names:['Copper','Daisy','Rocket','Olive'], persona:['follows every smell off the path','bays like a trumpet when happy','snores louder than Dad']},
  boxer:  {name:'Boxer', rare:0, skill:'Bounce', skillText:'+10 coins when you beat the boss.', bark:[260,0.2], names:['Rocky','Lola','Tank','Zoey'], persona:['wiggles his whole body when happy','jumps like a kangaroo','drools on everything']},
  chihuahua:{name:'Chihuahua', rare:0, skill:'Sass', skillText:'Boss gets one fewer question.', bark:[700,0.08], names:['Taco','Bella','Peanut','Coco'], persona:['tiny dog, giant attitude','shivers even when it is warm','bosses the big dogs around']},
  germanshepherd:{name:'German Shepherd', rare:0, skill:'Guard', skillText:'Pups never run off for good; they always come back once.', bark:[230,0.22], names:['Max','Luna','Rex','Sadie'], persona:['watches the door all night','knows every trick in the book','loyal to the end']},
  collie: {name:'Border Collie', rare:1, skill:'Hint', skillText:'Can remove one wrong answer, once per trail.', bark:[380,0.15], names:['Pixel','Juno','Ziggy','Nova'], persona:['tries to herd the whole crew','stares at you until you throw the ball','too smart for her own good']},
  heeler: {name:'Blue Heeler', rare:1, skill:'Herd', skillText:'Pups come back 1 stop sooner after running off.', bark:[340,0.16], names:['Dusty','Blue','Sky','Ringo'], persona:['nips at heels to keep everyone moving','never ever gets tired','counts the crew twice']},
  corgi:  {name:'Corgi', rare:1, skill:'Crowd Favorite', skillText:'+15 coins when you finish a trail.', bark:[450,0.13], names:['Nugget','Pancake','Momo','Churro'], persona:['short legs, big attitude','sploots on cold floors','demands belly rubs from strangers']},
  pitbull:{name:'Pit Bull', rare:1, skill:'Big Heart', skillText:'Every dog in the shelter gets +10 happiness after a trail.', bark:[240,0.22], names:['Blue','Roxy','Diesel','Nala'], persona:['smiles with her whole face','thinks she is a lap dog','gives the best hugs']},
  toller: {name:'Duck Tolling Retriever', rare:1, skill:'Fetch', skillText:'Finds a bonus coin bag on every trail (+20).', bark:[400,0.15], names:['Ember','Rusty','Finn','Ginger'], persona:['screams with excitement, literally','will swim in anything','never drops the ball']},
  dachshund:{name:'Long-haired Wiener Dog', rare:1, skill:'Burrow', skillText:'Reveals which stops have hidden pups.', bark:[520,0.12], names:['Frank','Slinky','Noodle','Hazel'], persona:['tunnels under every blanket','long dog, longer naps','barks at her own tail']},
  husky:  {name:'Husky', rare:2, skill:'Trailblazer', skillText:'Double coins on the Iceland trail.', bark:[280,0.3], names:['Luna','Blizzard','Koda','Echo'], persona:['talks back when you say no','digs holes for fun','would rather pull than walk']},
  bernese:{name:'Bernese Mountain Dog', rare:2, skill:'Steady', skillText:'Wrong answers on normal stops cost nothing, ever.', bark:[180,0.3], names:['Moose','Bella','Teddy','Willow'], persona:['gentle giant who leans on you','loves snow more than anything','thinks he is a puppy still']},
  greatdane:{name:'Great Dane', rare:2, skill:'Tall', skillText:'See two stops ahead on the trail map.', bark:[150,0.3], names:['Duke','Athena','Goliath','Pearl'], persona:['taller than you when he stands up','scared of the vacuum','takes up the whole couch']},
  saintbernard:{name:'Saint Bernard', rare:2, skill:'Rescue', skillText:'One wrong boss answer is forgiven.', bark:[160,0.32], names:['Beethoven','Heidi','Bruno','Clara'], persona:['carries snacks in a barrel','drools when happy, which is always','the softest pillow in the shelter']},
  cat:    {name:'Royal Cat', rare:3, skill:'Nine Lives', skillText:'All crew skills work twice per trail.', bark:[600,0.2], names:['Queen Whiskers','Sir Pounce','Duchess','Mochi'], persona:['acts like she owns the shelter','ignores everyone, then sits on you','knocks things off tables on purpose']},
};
const RARE_LABEL = {'-1':'Family', 0:'Common', 1:'Uncommon', 2:'Rare', 3:'Super Rare'};
const WORLDS = {
  forest:    {name:'Forest', emoji:'🌲', boss:'raccoons', bossName:'the Raccoon Gang', minLevel:1},
  desert:    {name:'Desert', emoji:'🌵', boss:'coyote', bossName:'Sly Coyote', minLevel:13},
  rainforest:{name:'Rainforest', emoji:'🌴', boss:'monkeys', bossName:'the Monkey Troop', minLevel:26},
  iceland:   {name:'Iceland', emoji:'❄️', boss:'polarbear', bossName:'Grumpy Polar Bear', minLevel:39},
};
const SHELTERS = {beach:'Beach', farm:'Farm', forest:'Forest', metro:'Metro City', rural:'Countryside'};
const ITEMS = [
  {id:'kibble', name:'Bag of Kibble', emoji:'🥣', price:15, care:true, text:'Feeds a dog. +40 happiness.'},
  {id:'treats', name:'Dog Treats', emoji:'🦴', price:10, care:true, text:'A snack. +40 happiness.'},
  {id:'ball',   name:'Tennis Ball', emoji:'🎾', price:20, care:true, text:'Play fetch. +40 happiness.'},
  {id:'rope',   name:'Rope Toy', emoji:'🪢', price:25, care:true, text:'Tug of war. +40 happiness.'},
  {id:'squeaky',name:'Squeaky Duck', emoji:'🦆', price:30, care:true, text:'Squeak squeak. +40 happiness.'},
  {id:'bowl',   name:'Fancy Dog Bowl', emoji:'🍲', price:60, text:'Shows up in your shelter.'},
  {id:'leash',  name:'Sparkle Leash', emoji:'🐕‍🦺', price:50, text:'Shows up in your shelter.'},
  {id:'bed',    name:'Cozy Dog Bed', emoji:'🛏️', price:120, text:'Shows up in your shelter.'},
];
const AVATAR = {
  skin:  [{id:'s1',name:'Light',c:'#f6d3b3'},{id:'s2',name:'Tan',c:'#e3b08a'},{id:'s3',name:'Olive',c:'#c6946a'},{id:'s4',name:'Brown',c:'#9b6a46'},{id:'s5',name:'Deep',c:'#5e3b26'}],
  hairColor: [{id:'h1',name:'Blonde',c:'#f1d27a'},{id:'h2',name:'Brown',c:'#6b4423'},{id:'h3',name:'Black',c:'#1e1a1a'},{id:'h4',name:'Red',c:'#c8552b'},{id:'h5',name:'Pink',c:'#ff7fcf'},{id:'h6',name:'Blue',c:'#5aa9ff'}],
  hair:  [{id:'ponytail',name:'Ponytail'},{id:'braids',name:'Braids'},{id:'curly',name:'Curly'},{id:'buns',name:'Buns'}],
  top:   [{id:'hoodie',name:'Hoodie'},{id:'cheer',name:'Cheer Uniform'},{id:'crop',name:'Crop Top'},{id:'jacket',name:'Oversized Jacket'},{id:'sweater',name:'Oversized Sweater'},{id:'pajamas',name:'Pajamas'},{id:'dress',name:'Dress'}],
  bottom:[{id:'jeans',name:'Baggy Jeans'},{id:'pjpants',name:'Pajama Pants'},{id:'skirt',name:'Cheer Skirt'},{id:'none',name:'(dress)'}],
  shoes: [{id:'sneakers',name:'Sneakers'},{id:'converse',name:'Converse'},{id:'crocs',name:'Crocs'},{id:'heels',name:'High Heels'},{id:'cowgirl',name:'Cowgirl Boots'}],
  acc:   [{id:'none',name:'None'},{id:'cheerbow',name:'Cheer Bow'},{id:'glasses',name:'Glasses'},{id:'skihat',name:'Ski Hat'},{id:'cowgirlhat',name:'Cowgirl Hat'}],
};
const DEFAULT_AVATAR = {skin:'s2', hairColor:'h2', hair:'ponytail', top:'hoodie', bottom:'jeans', shoes:'sneakers', acc:'none'};

/* ---------- questions ---------- */
const R=(a,b)=>a+Math.floor(Math.random()*(b-a+1));
const pick=a=>a[Math.floor(Math.random()*a.length)];
function shuffle(a){for(let i=a.length-1;i>0;i--){const j=Math.floor(Math.random()*(i+1));[a[i],a[j]]=[a[j],a[i]]}return a}
function mc(answer,wrongs){
  const set=new Set([String(answer)]);wrongs.forEach(w=>{if(set.size<4&&String(w)!==String(answer))set.add(String(w))});
  let k=1;while(set.size<4){const w=typeof answer==='number'?answer+pick([-1,1])*k:answer+'?';if(String(w)!==String(answer)&&(typeof answer!=='number'||w>=0))set.add(String(w));k++}
  return shuffle([...set]);
}
function nearNums(n){return [n+1,n-1,n+10,n-10,n+2,n*2].filter(x=>x>=0&&x!==n)}
const W = {
  forest:{place:'the creek',thing:'pine cones',snack:'trail mix',spot:'the old bridge',animal:'squirrel'},
  desert:{place:'the oasis',thing:'smooth desert stones',snack:'dried fruit',spot:'the dried-up well',animal:'lizard'},
  rainforest:{place:'the waterfall',snack:'bananas',thing:'bright feathers',spot:'the rope bridge',animal:'parrot'},
  iceland:{place:'the frozen lake',thing:'ice crystals',snack:'hot cocoa packets',spot:'the snow cave',animal:'puffin'},
};
function mathQ(g, world){
  const w=W[world]||W.forest; const t=R(1,5);
  if(g<=2){
    if(t<=2){const a=R(10,60),b=R(5,39);return {s:'Math',t:'Collecting',q:`Your crew found ${a} ${w.thing} near ${w.place} and ${b} more on the path. How many in all?`,a:a+b}}
    if(t===3){const a=R(30,99),b=R(5,29);return {s:'Math',t:'Snack time',q:`You packed ${a} dog treats. The crew ate ${b}. How many treats are left?`,a:a-b}}
    if(t===4){const a=R(2,5);return {s:'Math',t:'Paw prints',q:`${a} dogs walked through the mud. Each dog has 4 paws. How many paw prints?`,a:a*4}}
    const a=R(3,9);return {s:'Math',t:'Trail markers',q:`Trail markers are every 10 steps. You passed ${a} markers. How many steps did you walk?`,a:a*10};
  }
  if(g===3){
    if(t===1){const a=R(100,600),b=R(100,399);return {s:'Math',t:'Long walk',q:`The map says ${a} steps to ${w.place}, then ${b} more to camp. How many steps total?`,a:a+b}}
    if(t===2){const a=R(3,9),b=R(3,9);return {s:'Math',t:'Treat bags',q:`You have ${a} bags of treats with ${b} treats in each bag. How many treats?`,a:a*b}}
    if(t===3){const b=R(2,6),a=b*R(3,9);return {s:'Math',t:'Fair share',q:`${a} treats get split evenly between ${b} dogs. How many does each dog get?`,a:a/b}}
    if(t===4){const x=[R(40,90),R(40,90),R(40,90)];return {s:'Math',t:w.spot,q:`${w.spot[0].toUpperCase()+w.spot.slice(1)} holds 200 pounds. Your dogs weigh ${x[0]}, ${x[1]}, and ${x[2]} pounds. How much do they weigh all together?`,a:x[0]+x[1]+x[2]}}
    const a=R(500,999),b=R(100,499);return {s:'Math',t:'Water bottles',q:`You started with ${a} mL of water and the crew drank ${b} mL. How much is left?`,a:a-b};
  }
  if(g===4){
    if(t===1){const a=R(12,49),b=R(3,9);return {s:'Math',t:'Rations',q:`Each dog needs ${b} cups of food for the trip. There are ${a} dogs at the shelter. How many cups do you need?`,a:a*b}}
    if(t===2){const b=R(3,9),a=b*R(4,12)+R(1,b-1);return {s:'Math',t:'Leftover treats',q:`${a} treats shared by ${b} dogs. How many treats are left over?`,a:a%b}}
    if(t===3){const a=R(11,25),b=R(11,25);return {s:'Math',t:'Campsite',q:`The campsite is ${a} feet by ${b} feet. What is its area in square feet?`,a:a*b}}
    if(t===4){const n=R(1,5),d=R(6,10),n2=R(1,5);if(n===n2)return mathQ(g,world);const big=n>n2?`${n}/${d}`:`${n2}/${d}`;return {s:'Math',t:'Water left',q:`One bottle is ${n}/${d} full. Another is ${n2}/${d} full. Which bottle has more water?`,a:big,wrongs:[n>n2?`${n2}/${d}`:`${n}/${d}`,'They are equal','Cannot tell']}}
    const a=R(2,9),b=R(2,9),c=R(2,9);return {s:'Math',t:'Trail math',q:`A ${w.animal} hid ${w.thing} in ${a} spots, ${b} in each, then took back ${c}. How many are left?`,a:a*b-c};
  }
  if(t===1){const a=(R(10,60)/10).toFixed(1),b=(R(10,60)/10).toFixed(1);return {s:'Math',t:'Hike distance',q:`Morning hike: ${a} miles. Afternoon hike: ${b} miles. Total miles?`,a:(+a+ +b).toFixed(1),wrongs:[(+a+ +b+1).toFixed(1),(+a+ +b-0.5).toFixed(1),(+a* +b).toFixed(1)]}}
  if(t===2){const a=R(12,30),b=R(12,30);return {s:'Math',t:'Supply run',q:`${a} boxes of dog food, ${b} cans in each box. How many cans?`,a:a*b}}
  if(t===3){const d=pick([4,6,8,10]),n1=R(1,d-2),n2=R(1,d-n1-1);return {s:'Math',t:'Snack share',q:`You ate ${n1}/${d} of the ${w.snack} and your dog ate ${n2}/${d}. How much is gone?`,a:`${n1+n2}/${d}`,wrongs:[`${n1+n2}/${d*2}`,`${n1*n2}/${d}`,`${n1+n2+1}/${d}`]}}
  if(t===4){const a=R(2,9),b=R(2,9),c=R(2,9);return {s:'Math',t:'Order of operations',q:`Solve: ${a} + ${b} × ${c}`,a:a+b*c,wrongs:[(a+b)*c,a*b+c,a+b+c]}}
  const m=R(60,240);return {s:'Math',t:'Time check',q:`The trail takes ${m} minutes. How many hours and minutes is that?`,a:`${Math.floor(m/60)} hr ${m%60} min`,wrongs:[`${Math.floor(m/60)+1} hr ${m%60} min`,`${Math.floor(m/60)} hr ${(m%60+10)%60} min`,`${Math.floor(m/100)} hr ${m%100} min`]};
}
const OTHER = {
 lo:{
  all:[
   {s:'Science',t:'Thirsty crew',q:'The dogs are panting after a long walk. What do they need most?',a:'Water',w:['A nap in the sun','More running','A treat']},
   {s:'Spelling',t:'Trail sign',q:'The old sign says "BRI_GE AHEAD". Which letter is missing?',a:'D',w:['G','J','T']},
   {s:'Map reading',t:'Compass',q:'The sun is setting in front of you. Which direction are you facing?',a:'West',w:['East','North','South']},
   {s:'Spelling',t:'Trail sign',q:'Which word is spelled correctly?',a:'forest',w:['forrest','forist','foresst']},
   {s:'Science',t:'Animal tracks',q:'You see a track with a hoof print, like two halves of a heart. What made it?',a:'A deer',w:['A dog','A bird','A raccoon']},
   {s:'Reading',t:'Trail note',p:'"Dear hikers, the north path is washed out. Please take the east path to the campsite. Thank you! - Ranger Kim"',q:'Which path should you take?',a:'The east path',w:['The north path','The west path','Any path']},
  ],
  forest:[
   {s:'Reading',t:'Lost pup',p:'Milo the puppy ran past the big oak tree. He splashed through the creek and stopped at the tall rock to rest.',q:'Where did Milo stop to rest?',a:'At the tall rock',w:['At the oak tree','In the creek','At the shelter']},
   {s:'Science',t:'Mystery berries',q:'You find berries you have never seen before. What should you do?',a:'Leave them alone',w:['Eat one to test it','Feed one to a dog','Pick them all']},
   {s:'Science',t:'Bear in the bushes',q:'A bear is eating berries up ahead. What is the safest thing to do?',a:'Back away slowly and stay calm',w:['Run as fast as you can','Throw a stick at it','Go pet it']},
  ],
  desert:[
   {s:'Science',t:'Sandstorm',q:'A sandstorm is coming. What should you cover first?',a:'Your eyes, nose and mouth',w:['Your feet','Your backpack','Nothing']},
   {s:'Science',t:'Desert heat',q:'When is the best time to hike in the desert?',a:'Early morning',w:['Noon','Mid afternoon','It does not matter']},
   {s:'Reading',t:'Rattle',p:'Scout heard a dry rattle near the rocks. She froze, then backed away slowly while the snake slid under a shady rock.',q:'What did Scout do when she heard the rattle?',a:'Froze, then backed away slowly',w:['Ran toward it','Barked at it','Dug a hole']},
  ],
  rainforest:[
   {s:'Science',t:'Downpour',q:'It rains almost every day in the rainforest. Which of these needs that rain the most?',a:'The giant plants and trees',w:['The rocks','The clouds','The sand']},
   {s:'Reading',t:'Snack thief',p:'A monkey grabbed the snack bag and climbed the tallest tree. It dropped the bananas but kept the crackers.',q:'What did the monkey keep?',a:'The crackers',w:['The bananas','The bag only','Nothing']},
   {s:'Science',t:'Rope bridge',q:'How many kids should cross the wobbly rope bridge at a time?',a:'One at a time',w:['All at once','As many as fit','Three']},
  ],
  iceland:[
   {s:'Science',t:'Thin ice',q:'Ice on a pond is usually thinnest where?',a:'Near the edges and moving water',w:['In the middle','Where it is snowy','Everywhere the same']},
   {s:'Science',t:'Northern lights',q:'The northern lights are also called what?',a:'Aurora',w:['Rainbow','Lightning','Moonbeam']},
   {s:'Reading',t:'Snow cave',p:'The crew found a snow cave. Inside it was quiet and warmer than outside. Luna curled up right away.',q:'Why did Luna curl up?',a:'It was warmer and quiet',w:['She was scared','It was snowing inside','She found food']},
  ]
 },
 hi:{
  all:[
   {s:'Spelling',t:'Trail sign',q:'Which word is spelled correctly?',a:'separate',w:['seperate','separete','seperete']},
   {s:'Map reading',t:'Compass',q:'You are facing north. The campsite is to your right. Which direction is the campsite?',a:'East',w:['West','South','North']},
   {s:'Math',t:'Scale',q:'On the map, 1 inch equals 2 miles. The trail is 3.5 inches long. How many miles is it?',a:'7 miles',w:['3.5 miles','5.5 miles','14 miles']},
   {s:'Science',t:'Water safety',q:'Which stream water is safest to drink on the trail?',a:'Water you have filtered or boiled',w:['Fast, clear water','Water from a still pond','Water that looks clean']},
   {s:'Science',t:'Weather',q:'Dark clouds are piling up and the wind picks up suddenly. What is most likely coming?',a:'A thunderstorm',w:['A sunny afternoon','Snow','Fog']},
   {s:'Reading',t:'Ranger note',p:'"Storm expected after 4 pm. Hikers should reach camp before then. The creek rises fast when it rains, so do not cross it after the storm starts."',q:'What is the main warning in the note?',a:'Do not cross the creek after the storm starts',w:['Bring an umbrella','Hike faster than 4 mph','Camp near the creek']},
  ],
  forest:[
   {s:'Reading',t:'Lost pup',p:'Pepper the hound caught a scent and bolted. She circled the fallen log twice, crossed the shallow stream, and finally curled up under the bridge where it was dry.',q:'Why did Pepper stop under the bridge?',a:'It was dry there',w:['She was hungry','She found the squirrel','She was lost']},
   {s:'Science',t:'Animal tracks',q:'A track shows five long toes with claw marks, almost like a tiny hand. What made it?',a:'A raccoon',w:['A deer','A rabbit','A dog']},
   {s:'Science',t:'Bear in the bushes',q:'Why should you keep food sealed and away from your tent in bear country?',a:'Bears follow food smells',w:['Food gets cold','Ants will eat it','It is a rule for no reason']},
  ],
  desert:[
   {s:'Math',t:'Dried-up well',q:'Each dog drinks 2 liters a day. You have 4 dogs and 3 days to the next water. How many liters do you need?',a:'24 liters',w:['12 liters','18 liters','8 liters']},
   {s:'Science',t:'Cactus',q:'Why do cacti have spines instead of leaves?',a:'To save water and stay safe from animals',w:['To look scary','To catch rain','They are broken leaves']},
   {s:'Science',t:'Rattlesnake',q:'You hear a rattlesnake on the path. What should you do?',a:'Stop, locate it, and walk around it widely',w:['Jump over it','Poke it with a stick','Let a dog chase it']},
  ],
  rainforest:[
   {s:'Science',t:'Layers',q:'The top layer of the rainforest where the tallest trees poke through is called the?',a:'Emergent layer',w:['Forest floor','Understory','Basement']},
   {s:'Reading',t:'Snack thief',p:'The monkeys worked as a team: one distracted the dogs, one grabbed the bag, and the third carried it up the vine. By the time anyone noticed, only banana peels were left.',q:'How did the monkeys get the bag?',a:'They worked together with different jobs',w:['One monkey did it all','The dogs gave it to them','They found it on the ground']},
   {s:'Science',t:'Downpour',q:'The river is rising fast after a downpour. Where should you move?',a:'To higher ground',w:['Closer to the river','Under the rope bridge','Into the water']},
  ],
  iceland:[
   {s:'Science',t:'Thin ice',q:'Ice on a lake must be at least how thick to walk on safely?',a:'About 4 inches',w:['Half an inch','1 inch','Any ice is safe']},
   {s:'Science',t:'Northern lights',q:'What causes the northern lights?',a:'Particles from the sun hitting Earth\'s atmosphere',w:['Reflections off the snow','City lights','Lightning in the clouds']},
   {s:'Math',t:'Snow cave',q:'The temperature is -8°C outside and 4°C inside the snow cave. How much warmer is it inside?',a:'12 degrees',w:['4 degrees','8 degrees','-4 degrees']},
  ]
 }
};
function makeQ(grade, world, used){
  for(let tries=0;tries<12;tries++){
    let out;
    if(Math.random()<0.5){const m=mathQ(grade,world);out={...m,choices:mc(m.a,m.wrongs||nearNums(+m.a))}}
    else{const bank=grade<=3?OTHER.lo:OTHER.hi;const o=pick(Math.random()<0.55?(bank[world]||bank.forest):bank.all);out={...o,choices:shuffle([o.a,...o.w])}}
    if(!used.has(out.q)||tries===11){used.add(out.q);return out}
  }
}
function rollBreed(){
  const r=Math.random();
  const want=r<0.03?3:r<0.12?2:r<0.4?1:0;
  const pool=Object.keys(BREEDS).filter(id=>BREEDS[id].rare===want);
  return pick(pool);
}
function worldForLevel(l){return l>=39?'iceland':l>=26?'rainforest':l>=13?'desert':'forest'}
return {BREEDS,RARE_LABEL,WORLDS,SHELTERS,ITEMS,AVATAR,DEFAULT_AVATAR,makeQ,rollBreed,worldForLevel,R,pick,shuffle};
})();
