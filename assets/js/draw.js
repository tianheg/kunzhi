/* 项目页「抽一条」——池子里的条目由 Hugo 全部渲染进 DOM，
   这里只负责把抽到的那条露出来、其余藏起来。
   无 JS 时页面显示第一条，按钮也不出现（按钮的 hidden 在这里才解除）。 */
(() => {
  const list = document.getElementById('draw-list');
  const btn = document.getElementById('draw-btn');
  if (!list || !btn) return;

  const items = Array.from(list.children);
  if (items.length < 2) return;

  let last = 0;               // 首屏显示的是第一条
  btn.hidden = false;

  btn.addEventListener('click', () => {
    let n = last;
    while (n === last) n = Math.floor(Math.random() * items.length);
    items[last].hidden = true;
    items[n].hidden = false;
    last = n;
  });
})();
