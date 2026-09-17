const S=[...document.querySelectorAll('section')];let i=0;
const cur=document.getElementById('cur'),tot=document.getElementById('tot'),bar=document.getElementById('bar');
tot.textContent=S.length;
function go(n){i=Math.max(0,Math.min(S.length-1,n));S.forEach((s,k)=>s.classList.toggle('on',k===i));
  cur.textContent=i+1;bar.style.width=((i+1)/S.length*100)+'%';location.hash=i+1;}
addEventListener('keydown',e=>{
  if(['ArrowRight','PageDown',' ','Enter'].includes(e.key)){e.preventDefault();go(i+1)}
  if(['ArrowLeft','PageUp','Backspace'].includes(e.key)){e.preventDefault();go(i-1)}
  if(e.key==='Home')go(0); if(e.key==='End')go(S.length-1);
});
addEventListener('click',e=>{if(e.target.closest('a'))return;go(i+(e.clientX<innerWidth*.25?-1:1))});
go(Math.max(0,(parseInt(location.hash.slice(1))||1)-1));