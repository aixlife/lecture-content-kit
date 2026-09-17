// 렌더 검사용: 폰트 로드 상태와 넘침을 body[data-check]에 기록 (화면에는 영향 없음)
document.fonts.ready.then(() => {
  const faces = [];
  document.fonts.forEach(f => faces.push(f.family.replace(/"/g, "") + ":" + f.weight + ":" + f.status));
  const used = new Set();
  document.querySelectorAll("body *").forEach(el => {
    if (el.childNodes.length && [...el.childNodes].some(n => n.nodeType === 3 && n.textContent.trim())) {
      used.add(getComputedStyle(el).fontWeight);
    }
  });
  const problems = [];
  const panel = document.querySelector(".panel");
  const pr = panel ? panel.getBoundingClientRect() : null;
  document.querySelectorAll("body *").forEach(el => {
    if (el.tagName === "SCRIPT" || el.closest("svg") && el.tagName !== "svg") return;
    const r = el.getBoundingClientRect();
    if (r.width === 0 || el.classList.contains("card")) return;
    const name = (el.className && el.className.baseVal === undefined ? el.className : el.tagName) + " '" + (el.textContent || "").trim().slice(0, 14) + "'";
    if (r.left < 60 || r.right > 1020 || r.top < 40 || r.bottom > 1310) problems.push("edge " + name + " " + [r.left, r.top, r.right, r.bottom].map(Math.round));
    if (el.scrollWidth > el.clientWidth + 1 && getComputedStyle(el).overflow !== "hidden" && el.clientWidth > 0) problems.push("overflow " + name + " " + el.scrollWidth + ">" + el.clientWidth);
    if (pr && !panel.contains(el) && el !== panel && !el.contains(panel) && el.className !== "card" && r.top < pr.bottom && r.bottom > pr.top) problems.push("overlap-panel " + name);
  });
  document.body.dataset.check = JSON.stringify({ faces, weights: [...used], problems });
});
