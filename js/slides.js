let currentSlide=0;function changeSlide(e,l,t){const c=e.querySelectorAll(".slides .slide"),r=e.querySelectorAll(".controls .control");c[t].classList.remove("active"),c[l].classList.add("active"),r[t].classList.remove("active"),r[l].classList.add("active")}function autoPlay(e){const l=e.querySelectorAll(".controls .control");currentSlide+1<l.length?(changeSlide(e,currentSlide+1,currentSlide),currentSlide++):(changeSlide(e,0,currentSlide),currentSlide=0)}const slideshows=document.querySelectorAll(".slideshow");slideshows.forEach(e=>{const l=e.querySelectorAll(".slides .slide"),t=e.querySelectorAll(".controls .control");l[currentSlide].classList.contains("active")||autoPlay(e);let c=setInterval(()=>{autoPlay(e)},5e3);t.forEach((l,t)=>{l.addEventListener("click",()=>{changeSlide(e,t,currentSlide),currentSlide=t,clearInterval(c),c=setInterval(()=>{autoPlay(e)},5e3)})})});
