// Language switch for cobalagi.ardeman.com. Indonesian is written in the HTML;
// English lives in data-en (text and HTML), data-en-alt and data-en-src.
// Priority: ?lang=id|en, then the saved choice, then the browser language.
(function () {
  var KEY = 'cobalagi-lang';
  function load() { try { return localStorage.getItem(KEY); } catch (e) { return null; } }
  function save(v) { try { localStorage.setItem(KEY, v); } catch (e) {} }

  var texts = document.querySelectorAll('[data-en]');
  var alts = document.querySelectorAll('[data-en-alt]');
  var srcs = document.querySelectorAll('[data-en-src]');
  var links = document.querySelectorAll('a[data-keep-lang]');
  texts.forEach(function (n) { n.dataset.id = n.innerHTML; });
  alts.forEach(function (n) { n.dataset.idAlt = n.alt; });
  srcs.forEach(function (n) { n.dataset.idSrc = n.getAttribute('src'); });
  links.forEach(function (n) { n.dataset.href = n.getAttribute('href'); });

  var button = document.getElementById('lang');
  function apply(lang) {
    var en = lang === 'en';
    document.documentElement.lang = lang;
    texts.forEach(function (n) { n.innerHTML = en ? n.dataset.en : n.dataset.id; });
    alts.forEach(function (n) { n.alt = en ? n.dataset.enAlt : n.dataset.idAlt; });
    srcs.forEach(function (n) { n.src = en ? n.dataset.enSrc : n.dataset.idSrc; });
    // Links between pages keep the chosen language even without storage.
    links.forEach(function (n) {
      var url = n.dataset.href.split('#');
      n.href = url[0] + '?lang=' + lang + (url[1] ? '#' + url[1] : '');
    });
    if (button) {
      button.textContent = en ? 'ID' : 'EN';
      button.setAttribute('aria-label', en ? 'Ganti ke Bahasa Indonesia' : 'Switch to English');
    }
  }

  var preferred = (navigator.languages || [navigator.language || '']).some(function (l) {
    return /^id(-|$)/i.test(l);
  }) ? 'id' : 'en';
  var asked = new URLSearchParams(location.search).get('lang');
  var current = asked === 'id' || asked === 'en' ? asked : load() || preferred;
  apply(current);
  if (button) {
    button.addEventListener('click', function () {
      current = current === 'en' ? 'id' : 'en';
      save(current);
      apply(current);
    });
  }
})();
