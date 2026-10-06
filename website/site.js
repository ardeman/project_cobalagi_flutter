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
  var labels = document.querySelectorAll('[data-en-label]');
  var links = document.querySelectorAll('a[data-keep-lang]');
  texts.forEach(function (n) { n.dataset.id = n.innerHTML; });
  alts.forEach(function (n) { n.dataset.idAlt = n.alt; });
  srcs.forEach(function (n) { n.dataset.idSrc = n.getAttribute('src'); });
  labels.forEach(function (n) { n.dataset.idLabel = n.getAttribute('aria-label'); });
  links.forEach(function (n) { n.dataset.href = n.getAttribute('href'); });

  var button = document.getElementById('lang');
  function apply(lang) {
    var en = lang === 'en';
    document.documentElement.lang = lang;
    texts.forEach(function (n) { n.innerHTML = en ? n.dataset.en : n.dataset.id; });
    alts.forEach(function (n) { n.alt = en ? n.dataset.enAlt : n.dataset.idAlt; });
    srcs.forEach(function (n) { n.src = en ? n.dataset.enSrc : n.dataset.idSrc; });
    labels.forEach(function (n) {
      n.setAttribute('aria-label', en ? n.dataset.enLabel : n.dataset.idLabel);
    });
    document.dispatchEvent(new CustomEvent('langchange', { detail: lang }));
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

// Slideshows. Without JavaScript they are rows to swipe or scroll; this adds
// arrows, dots or tabs, keyboard keys and, where asked, gentle autoplay that
// stops for good once the visitor takes over (and never runs for visitors
// who prefer reduced motion).
(function () {
  document.documentElement.classList.add('js');
  var still = matchMedia('(prefers-reduced-motion: reduce)');

  document.querySelectorAll('[data-carousel]').forEach(function (show) {
    var track = show.querySelector('.track');
    var slides = Array.prototype.slice.call(track.children);
    var count = slides.length;
    var buttons = Array.prototype.slice.call(show.querySelectorAll('[data-slide]'));
    var dots = show.querySelector('.dots');
    if (dots) {
      slides.forEach(function (_, i) {
        var dot = document.createElement('button');
        dot.type = 'button';
        dot.dataset.slide = i;
        dot.setAttribute('aria-label', (i + 1) + ' / ' + count);
        dots.appendChild(dot);
        buttons.push(dot);
      });
    }
    var current = 0;

    function go(i, user) {
      if (user) stop();
      current = (i + count) % count;
      track.scrollTo({
        left: current * track.clientWidth,
        behavior: still.matches ? 'auto' : 'smooth'
      });
      mark();
    }
    function mark() {
      buttons.forEach(function (b) {
        var on = Number(b.dataset.slide) === current;
        b.setAttribute('aria-current', on ? 'true' : 'false');
      });
      slides.forEach(function (slide, i) {
        slide.setAttribute('aria-hidden', i === current ? 'false' : 'true');
      });
    }

    buttons.forEach(function (b) {
      b.addEventListener('click', function () { go(Number(b.dataset.slide), true); });
    });
    var prev = show.querySelector('.prev');
    var next = show.querySelector('.next');
    if (prev) prev.addEventListener('click', function () { go(current - 1, true); });
    if (next) next.addEventListener('click', function () { go(current + 1, true); });
    track.addEventListener('keydown', function (e) {
      if (e.key === 'ArrowRight') { e.preventDefault(); go(current + 1, true); }
      if (e.key === 'ArrowLeft') { e.preventDefault(); go(current - 1, true); }
    });

    // A swipe or scroll lands on a slide: follow it.
    var settle;
    track.addEventListener('scroll', function () {
      clearTimeout(settle);
      settle = setTimeout(function () {
        var i = Math.round(track.scrollLeft / track.clientWidth);
        if (i !== current) { current = i; mark(); }
      }, 80);
    }, { passive: true });
    track.addEventListener('touchstart', function () { stop(); }, { passive: true });
    track.addEventListener('wheel', function (e) {
      if (Math.abs(e.deltaX) > Math.abs(e.deltaY)) stop();
    }, { passive: true });
    addEventListener('resize', function () {
      track.scrollTo({ left: current * track.clientWidth });
    });

    var timer = null;
    var stopped = false;
    function stop() { stopped = true; pause(); }
    function pause() { clearInterval(timer); timer = null; }
    function play() {
      if (stopped || timer || still.matches || !show.dataset.autoplay) return;
      timer = setInterval(function () { go(current + 1); }, Number(show.dataset.autoplay));
    }
    show.addEventListener('mouseenter', pause);
    show.addEventListener('mouseleave', play);
    show.addEventListener('focusin', pause);
    document.addEventListener('visibilitychange', function () {
      if (document.hidden) pause(); else play();
    });
    // Only move while on screen.
    if ('IntersectionObserver' in window) {
      new IntersectionObserver(function (entries) {
        if (entries[0].isIntersecting) play(); else pause();
      }, { threshold: 0.4 }).observe(show);
    } else {
      play();
    }
    mark();
  });
})();

// The menu: marks the current page, and on phones opens from the ☰ button.
(function () {
  var nav = document.getElementById('nav');
  var toggle = document.getElementById('menu-toggle');
  if (!nav || !toggle) return;
  var page = location.pathname.split('/').pop() || 'index.html';
  nav.querySelectorAll('.links a').forEach(function (a) {
    var target = (a.getAttribute('href') || '').split(/[?#]/)[0];
    if (target === page && page !== 'index.html') a.setAttribute('aria-current', 'page');
  });
  // On the home page, the link of the section on screen is marked as well.
  var sectionLinks = Array.prototype.filter.call(
    nav.querySelectorAll('.links a'),
    function (a) { return (a.getAttribute('href') || '').charAt(0) === '#'; }
  );
  var sections = sectionLinks.map(function (a) {
    return document.querySelector(a.getAttribute('href'));
  });
  var header = document.querySelector('header');
  var queued = false;
  function spy() {
    queued = false;
    // The section whose top has passed a line a third of the way down.
    var line = header.getBoundingClientRect().bottom + innerHeight / 3;
    var current = -1;
    sections.forEach(function (section, i) {
      if (section && section.getBoundingClientRect().top <= line) current = i;
    });
    // At the very bottom, the last section counts even if it is short.
    if (innerHeight + scrollY >= document.documentElement.scrollHeight - 2) {
      current = sections.length - 1;
    }
    sectionLinks.forEach(function (a, i) {
      if (i === current) a.setAttribute('aria-current', 'location');
      else a.removeAttribute('aria-current');
    });
  }
  if (sectionLinks.length) {
    addEventListener('scroll', function () {
      if (!queued) { queued = true; requestAnimationFrame(spy); }
    }, { passive: true });
    addEventListener('resize', spy);
    spy();
  }

  function set(open) {
    nav.classList.toggle('open', open);
    toggle.setAttribute('aria-expanded', open ? 'true' : 'false');
  }
  toggle.addEventListener('click', function (e) {
    e.stopPropagation();
    set(!nav.classList.contains('open'));
  });
  nav.querySelectorAll('.links a').forEach(function (a) {
    a.addEventListener('click', function () { set(false); });
  });
  document.addEventListener('click', function (e) {
    if (!nav.contains(e.target)) set(false);
  });
  document.addEventListener('keydown', function (e) {
    if (e.key === 'Escape' && nav.classList.contains('open')) { set(false); toggle.focus(); }
  });
})();
