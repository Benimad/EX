# MyEx Glass Premium: design critique and change plan

Target: `c:\Users\AdMin\Desktop\PLANNING\MyEx_Glass_Premium.html` (single file, 390×844 frame).
Status: read-only review. Another agent is fixing bugs in the file, so this plan points at **selectors, function names and screen keys (`SC[n]`)**, not line numbers.
Priorities: **P0** must · **P1** should · **P2** nice. 62 changes. They are ordered by impact inside each section, and the sections are in the order they should be applied (section 0 is the summary, 11 is the apply order).

Do **not** change: `CFG`, the state shape `S0()`, the purchase logic in `apply()` and `ACT`, the `why` side-panel text, and any existing ARIA attributes, unless a change below says otherwise.

---

## 0. Diagnosis in one paragraph

The prototype has the right flows and good business logic. It reads as AI-made because every surface gets the same treatment at full volume:
- Every title uses serif plus an italic, gradient-filled `<em>`.
- Every screen opens with an uppercase eyebrow.
- Every card has the same pink drop shadow.
- Every primary button is a gradient with a pink glow and a heart burst.
- Hearts float behind everything, blobs drift, and confetti falls.
- Crowns, gold pills and tags sit on almost every row.
- Home is a bento grid.
- Every screen staggers its children upward on entry.
- Navigation is a fade with a slide, not iOS push/pop, and the tab bar is re-rendered per page, so nothing can slide or morph.

Native iOS 26 apps feel calm because they hold back: system type, one tint, flat grouped lists, glass only on floating chrome, and physical springs on a few purposeful transitions.

**Brand signature to keep (2 things only):**
1. **Lumi, used rarely and with meaning.** Lumi appears on 4 emotional moments: Plan ready, SOS breathing, Welcome and Win-back.
2. **Instrument Serif as the "human voice".** It is used upright and never in italic or gradient, for one display headline per emotional screen (Plan ready, Paywall, Welcome, SOS, Win-back) and for hero numerals (streak, coin balance, trial days left). Every utility screen uses system type.

**Everything else goes:** gradient text, italic `<em>`, eyebrows, floating hearts, the heart burst, confetti, drifting blobs, crowns, gold, the bento grid, staggered fade-ups, coloured glow shadows, pink-to-orange gradients and two-line pill buttons.

---

## 1. Foundations: tokens, type and colour (apply first)

### F1 · P0 · Replace `:root` tokens
Selector `:root`. Replace the whole block:

```css
:root{
 /* surfaces */
 --bg:#FFF5F7;                 /* grouped background */
 --bg-elev:#FFFFFF;            /* cells, cards, bubbles */
 --page:radial-gradient(90% 40% at 100% 0%,rgba(255,120,160,.16),transparent 70%),
        radial-gradient(70% 35% at 0% 100%,rgba(255,170,195,.14),transparent 70%),#FFF5F7;
 /* labels (wine-tinted neutrals) */
 --ink:#3A0F22;                /* primary label */
 --ink-2:#86506A;              /* secondary label, 5.8:1 on --bg */
 --ink-3:rgba(58,15,34,.30);   /* tertiary: chevrons, placeholders, NON-text only */
 --sep:rgba(58,15,34,.12);     /* 0.5px hairlines */
 --fill:rgba(58,15,34,.06);    /* pressed cells, neutral fills */
 /* one accent */
 --accent:#D81B60;             /* fills, icons, text >=17px semibold */
 --accent-ink:#B0124F;         /* accent text <=15px, text on --accent-soft */
 --accent-soft:rgba(216,27,96,.10);
 /* semantic */
 --success:#0B7A55; --success-soft:rgba(11,122,85,.10);
 --danger:#D70015;
 --switch-on:#34C759;          /* system green, switches only */
 /* the ONLY gradient (Home streak hero + app icon) */
 --hero:radial-gradient(110% 80% at 90% 0%,rgba(255,150,180,.45),transparent 60%),linear-gradient(160deg,#B3134F 0%,#D81B60 100%);
 /* type */
 --sans:-apple-system,BlinkMacSystemFont,"SF Pro Text","Inter",system-ui,sans-serif;
 --serif:"Instrument Serif",ui-serif,Georgia,serif;
 /* radii (continuous-corner scale) */
 --r-xs:8px;--r-s:12px;--r-m:16px;--r-l:22px;--r-xl:28px;--r-sheet:38px;
 /* spacing (4/8 grid) */
 --s1:4px;--s2:8px;--s3:12px;--s4:16px;--s5:20px;--s6:24px;--s8:32px;
 /* motion: see section 5 */
 --ease-smooth:linear(0,.041 5%,.133 10%,.246 15%,.363 20%,.473 25%,.570 30%,.654 35%,.725 40%,.833 50%,.903 60%,.947 70%,.974 80%,.991 90%,1);
 --ease-snappy:linear(0,.062 5%,.202 10%,.367 15%,.526 20%,.664 25%,.776 30%,.861 35%,.922 40%,.990 50%,1.012 60%,1.015 70%,1.010 80%,1.006 90%,1);
 --ease-bouncy:linear(0,.099 5%,.320 10%,.571 15%,.796 20%,.965 25%,1.069 30%,1.118 35%,1.125 40%,1.106 45%,1.076 50%,1.018 60%,.989 70%,.985 80%,.992 90%,1);
 --ease-out:cubic-bezier(0,0,.58,1);   /* UIKit easeOut */
 --ease-in:cubic-bezier(.42,0,1,1);    /* UIKit easeIn (dismiss) */
 --d-smooth:.5s;--d-snappy:.45s;--d-bouncy:.65s;
}
@supports not (transition-timing-function:linear(0,1)){
 :root{--ease-smooth:cubic-bezier(.22,1,.36,1);--ease-snappy:cubic-bezier(.25,1.1,.4,1);--ease-bouncy:cubic-bezier(.3,1.5,.5,1)}
}
```
Then delete every use of `--grad`, `--grad2`, `--gold`, `--vt`, `--mt` and `--card`, and map them like this:
- `--v` → `--accent`
- `--vd` → `--accent-ink`
- `--m` → `--success`
- `--c` → `--danger`
- `--mut` → `--ink-2`
- `--line` → `--sep`

`body{background:#FBEDF1}` stays (it is the presentation canvas). `.phone` becomes `background:#0B0A10` (black shows behind a scaled page, see N4). The page background moves onto `.page` (see A6).

**Contrast check** (WCAG, computed):

| Pair | Ratio | Use |
|---|---|---|
| `--ink` #3A0F22 on #FFF5F7 | ≈15:1 | all body text |
| `--ink-2` #86506A on #FFFFFF / #FFF5F7 | 6.25 / 5.8 | secondary text |
| `--accent` #D81B60 on #FFF | 4.94 | icons, ≥17px semibold text |
| `--accent` on `--bg` | 4.6 | allowed, but prefer `--accent-ink` |
| `--accent-ink` #B0124F on #FFF | 6.9 | small accent text and links |
| `--accent-ink` on `--accent-soft` over white | 5.9 | tags, "Get" buttons |
| `--accent` on `--accent-soft` | 4.2 ✗ | **never** use this for text |
| #FFF on `--accent` (primary button) | 4.94 | ✓ |
| #FFF on #B3134F (hero top-left) | ≈7.0 | ✓ |
| `--success` #0B7A55 on #FFF | 5.4 | ✓ |
| `--danger` #D70015 on #FFF / `--bg` | 5.4 / 5.0 | ✓ |
| `--ink-3` | ≈2.3 | glyphs only, never text |

The old `--grad` ended in #FF7F50 coral, and white small text on it fails at about 3:1. The new `--hero` stays inside the pink hue and keeps its light highlight in the top-right corner, where no small text sits.

### F2 · P0 · Fonts
In `<head>`, replace the Google Fonts link with:
```html
<link href="https://fonts.googleapis.com/css2?family=Instrument+Serif&family=Inter:opsz,wght@14..32,400..700&display=swap" rel="stylesheet">
```
Remove the Instrument Serif italic and Plus Jakarta Sans. Jakarta's wide geometry and heavy weights (700/800 everywhere) are a strong "landing-page" tell. On iPhone, `-apple-system` resolves to real SF Pro with automatic optical tracking. On desktop, Inter with `font-optical-sizing:auto` is the closest public match.
Add `html{font-optical-sizing:auto;-webkit-text-size-adjust:100%}` and `body{font:400 17px/22px var(--sans);letter-spacing:normal}`.
**Rule:** do not hard-code `letter-spacing` on sans text. SF and Inter-opsz track themselves.

### F3 · P0 · Type roles
Under `/* type */`, replace `.h1`, `.h2`, `.h1 em,.h2 em`, `.sub`, `.cap`, `.eye` and `.big` with:

```css
/* iOS Dynamic Type "Large" metrics */
.lt h1,.t-large{font:700 34px/41px var(--sans);margin:0;color:var(--ink)}    /* Large Title */
.t1{font:700 28px/34px var(--sans);margin:0}                                  /* Title 1 */
.t2{font:700 22px/28px var(--sans);margin:0}                                  /* Title 2 */
.t3,.sec-h{font:600 20px/25px var(--sans);margin:0}                           /* Title 3 / prominent section header */
.hl{font:600 17px/22px var(--sans)}                                           /* Headline */
.body{font:400 17px/22px var(--sans)}
.callout{font:400 16px/21px var(--sans)}
.sub{font:400 15px/20px var(--sans);color:var(--ink-2);margin:0}             /* Subheadline */
.foot{font:400 13px/18px var(--sans);color:var(--ink-2);margin:0}            /* Footnote */
.cap{font:400 12px/16px var(--sans);color:var(--ink-2);margin:0}             /* Caption 1 */
/* brand voice: Instrument Serif, upright only */
.display{font:400 40px/44px var(--serif);letter-spacing:-.02em;margin:0;color:var(--ink);text-wrap:balance}
.num{font-family:var(--serif);font-weight:400;line-height:.9;letter-spacing:-.03em;font-variant-numeric:tabular-nums}
```
Weight rules: 400 body, 600 headlines and buttons, 700 titles only. **No 500 and no 800 anywhere** (search `font-weight:800`, `800 `, `font:800`, `font:700 1` and fix each one). Delete `.eye` entirely (see A2).

### F4 · P0 · Card and surface system (`.card`, `.tile`, `.plan`, `.pack`, `.dayr`, `.bub.ai`)
iOS lists and cards are flat white on the grouped background. Shadows belong only to floating things (glass chrome, sheets, toasts).

```css
.card{background:var(--bg-elev);border:0;border-radius:var(--r-l);padding:var(--s4);box-shadow:none}
```
Remove `box-shadow` from `.plan`, `.pack`, `.dayr`, `.tile` and `.bub.ai`, and remove `border:1px solid rgba(255,255,255,.95)` from `.card`.

### F5 · P0 · Grouped inset list component (new; replaces `.li` and most `.card` stacks)
```css
.list{background:var(--bg-elev);border-radius:var(--r-l);overflow:hidden}
.row-i{position:relative;display:flex;align-items:center;gap:var(--s3);width:100%;min-height:44px;padding:11px var(--s4);border:0;background:transparent;text-align:left;font:400 17px/22px var(--sans);color:var(--ink);cursor:pointer;transition:background .3s var(--ease-out)}
.row-i:active{background:var(--fill);transition:none}
.row-i+.row-i::before{content:"";position:absolute;top:0;right:0;left:var(--s4);height:.5px;background:var(--sep)}
.row-i.has-ico+.row-i.has-ico::before{left:58px}
.row-i .grow{display:flex;flex-direction:column;min-width:0}
.row-i .rs{font:400 13px/18px var(--sans);color:var(--ink-2)}
.row-i .val{margin-left:auto;color:var(--ink-2);white-space:nowrap;font-variant-numeric:tabular-nums}
.row-i .chev{color:var(--ink-3);display:flex}.row-i .chev svg{width:14px;height:14px;stroke-width:2.6}
.ico-sq{width:30px;height:30px;border-radius:var(--r-xs);display:grid;place-items:center;flex:none;background:var(--accent);color:#fff}
.ico-sq svg.i{width:18px;height:18px}
.ico-sq.ok{background:var(--success)}.ico-sq.neu{background:#8E7280}.ico-sq.dg{background:var(--danger)}
.sec-h{margin:var(--s2) var(--s4) var(--s2)}   /* used as <h2 class="sec-h"> above a .list */
.sec-f{margin:var(--s2) var(--s4) 0}            /* footnote under a list: add class foot */
```
JS helper (add next to `nav()`):
```js
function row(o){return '<button class="row-i'+(o.icon?' has-ico':'')+'" '+(o.attr||'')+'>'+
 (o.icon?'<span class="ico-sq '+(o.tone||'')+'">'+o.icon+'</span>':'')+
 '<span class="grow"><span>'+o.t+'</span>'+(o.st?'<span class="rs">'+o.st+'</span>':'')+'</span>'+
 (o.val!==undefined?'<span class="val">'+o.val+'</span>':'')+(o.chev===false?'':'<span class="chev">'+I.chev+'</span>')+'</button>';}
```
Delete `.li` once every screen has migrated (Plan ready, Coins and Subscription use it today).

### F6 · P0 · Buttons (`.btn`, `.btn.pri`, `.btn.gl`, `.btn.txt`, `.btn.sm`, `.btn .s2`)
```css
.btn{border:0;border-radius:999px;min-height:52px;width:100%;padding:0 var(--s5);display:flex;align-items:center;justify-content:center;gap:var(--s2);font:600 17px/22px var(--sans);cursor:pointer;
 transition:transform .35s var(--ease-snappy),filter .2s}
.btn:active{transform:scale(.97);filter:brightness(.94);transition:transform .08s var(--ease-out),filter .08s}
.btn.pri{background:var(--accent);color:#fff;box-shadow:none}
.btn.gl{color:var(--ink)}
.btn.txt{background:transparent;color:var(--accent-ink);font-weight:400;min-height:44px}
.btn.sm{min-height:44px;font-size:15px;width:auto;padding:0 var(--s4)}
```
Delete `.btn .s2` and remove two-line labels from buttons (see copy). Labels use **Title Case** (iOS convention): "Start Free Trial", "Not Now".

### F7 · P0 · Liquid Glass recipe (`.gl`, `.gl::after`)
The current glass is too heavy: a pink inner glow, a 26px blur and a diagonal sheen. iOS 26 glass is thin, clear and lit from the edges.
```css
.gl{position:relative;background:rgba(255,255,255,.55);-webkit-backdrop-filter:blur(14px) saturate(180%);backdrop-filter:blur(14px) saturate(180%);border:0;
 box-shadow:inset 0 0 0 .5px rgba(255,255,255,.75),inset 0 1px 0 rgba(255,255,255,.9),inset 0 -.5px 0 rgba(58,15,34,.08),0 8px 24px rgba(58,15,34,.10),0 1px 2px rgba(58,15,34,.06)}
.gl::after{content:"";position:absolute;inset:0;border-radius:inherit;pointer-events:none;background:radial-gradient(120% 70% at 25% 0%,rgba(255,255,255,.5),transparent 55%);opacity:.7}
```
Glass is allowed **only** on these elements:
- `.gbtn` nav buttons
- tab bar and SOS accessory
- coin chip
- composer and meter
- sheets
- secondary `.btn.gl`
- the lock-screen notification

Remove `gl` from:
- `.pack` (the Popular pack)
- the cancel-sheet chips
- the `class="chip pri gl"` Premium chip on Home (that chip is deleted anyway)

---

## 2. Remove the AI tells

### A1 · P0 · Gradient-text italic `<em>` on every title
Delete the `.h1 em,.h2 em` rule, then remove `<em>…</em>` from every string. Exact title replacements are in section 7. Occurrences are in these screens and functions:
- Plan ready, Paywall, Welcome, Plan, SOS and Win-back
- `exitOffer`, `limitSheet`, `lockDaySheet`, `cancelSheet` and `crisisSheet`

Also delete `.side h1 i{color:var(--v)}` styling only if you touch the side panel (P2).

### A2 · P0 · Uppercase eyebrows
Delete `.eye`, `.tile .lbl` uppercase, `.cmp .hd` uppercase, `.ctl .lab`/`.steps .g` (side panel, P2), and the inline `letter-spacing:1.4px` "PREMIUM" label in the Subscription screen. Remove every `<p class="eye">` in:
- Plan ready ("Made for you…")
- Paywall ("your plan for")
- Welcome
- Coins ("What coins unlock" becomes a `.sec-h`)
- Trial status ("What you did…" becomes a `.sec-h`)
- Win-back ("It's been 14 days")
- `exitOffer` ("Before you go")

In Trial status, change `'TALKS WITH MIRA','TEXTS NOT SENT','DAYS DONE'` to sentence case (see copy).

### A3 · P0 · Floating hearts
Delete the IIFE that inserts `.hrt` spans (`/* heart */` loop after `phone.insertAdjacentHTML`), the `.hrt` rule and `@keyframes rise`.

### A4 · P0 · Heart burst on primary buttons
Delete the second `document.addEventListener('click', … '.btn.pri' …, true)` listener, plus `.burst` and `@keyframes bu`. Feedback for presses comes from F6 and M3.

### A5 · P0 · Confetti
Delete `confetti()`, its call in `apply()`, `.conf` and `@keyframes cf`, and the `confetti` key in `XT`. Remove `'confetti'` from every `lumi({x:[…]})` call (Plan ready and Welcome). The replacement is the Welcome success sequence (M5).

### A6 · P0 · Over-busy background
Delete `.blobs`, `@keyframes drift` and the `<div class="blobs"></div>` in `#phone`. Each page now carries a calm, static background: `.page{position:absolute;inset:0;background:var(--page)}`. The two faint glows give the glass something to refract without moving.

### A7 · P0 · Staggered fade-up on every screen
Delete `.page.fwd .scr>*,.page.tab .scr>*{animation:up…}`, the five `nth-child … animation-delay` rules, and `@keyframes up`. iOS screens arrive whole. The only entrance choreography left is on Welcome (M5).

### A8 · P0 · Crowns and gold
- Remove `I.crown` from: the Home header chip, the Plan lock tags, the paywall timeline dot (use `I.check` for the last step), the Subscription "PREMIUM" label, `lumi` extras `x:['crown']`, and `cancelSheet` "better".
- Delete `XT.crown`, `.tag.gold` and `--gold`.
- The coin SVG keeps its gold, because it is the object's real colour.

### A9 · P0 · Too many pills, tags and badges
Pills that may remain: the coin chip, the chat meter and the tab capsule. Remove these tags:

| Where | Current tag | Replace with |
|---|---|---|
| Analysis nav | "1 of 3" / "Full" | nothing (status is in the content) |
| Analysis patterns | numbered `.tag` 1/2/3 | `<span class="pn">1</span>` with `.pn{font:600 15px/20px var(--sans);color:var(--accent-ink);width:20px}` |
| Analysis open state | 4 trait chips | two `.row-i` rows: "Worked: shared humour, honesty early on" and "Hard: slow replies, avoided hard talks" (no chevron) |
| Coach header | "Private" tag | remove |
| SOS top | "Always free · no limits" | footnote at bottom: "SOS is always free." |
| Plan rows | "Unlock" crown tag | nothing (the leading lock glyph is enough) |
| Home trial tile | "See what you did" | row subtitle |
| Paywall annual | gold "7 days free · Save 68%" badge | inline green `.save` text (P3) |
| Coins packs | "Popular" + "Best value" floating pills | one inline caption "Best value" in `--accent-ink` on the 200 pack only |
| Win-back | gold "Welcome-back offer" | `.foot` label |
| `lockDaySheet` | `tag g` "Day N" | `.foot` "Day 4 · 5 min · Self-worth" |

### A10 · P0 · Bento grid on Home
Delete `.bento`, `.tile*` and `.prog`. Home is rebuilt in H1.

### A11 · P1 · Everything centered
In-app screens (Home, Plan, Coach, Analysis, Coins, Trial status, Me) are **left-aligned** with large titles. Centering is reserved for Plan ready, Paywall head, Welcome, SOS and Win-back (emotional, single-message screens). Remove `ctr` from the Coins balance card. Inside lists, everything is left-aligned.

### A12 · P1 · Wine-gradient SOS tile and other decorative gradients
Delete `.tile.sos`, `.tile.up`, `.lock-scr`'s coral stop (see N7), the `background:linear-gradient(150deg,#FFF7E0,#FFE3EC)` on the Coins balance card, the `linear-gradient(150deg,#FFF0F5,#FFE1EA)` on the Subscription free card, the `--grad` avatar, the `--grad` premium card, the `.bar i` gradient, `.bub.me`, `.send`, `.meter button`, `.pack .price`, `.tl .st:first-child .dot` and `.dayr.today .n`. **All of these become a solid `--accent`, white or `--fill`.** After this pass, `--hero` appears only on the Home streak card and the app icon.

### A13 · P1 · Coloured glow shadows
Remove every `box-shadow` containing `rgba(216,27,96,…)` or `rgba(122,18,56,…)`, for example on `.chip.on`, `.plan.on`, `.dayr.today`, `.tile.hero`, `.why` and `.phone`. The only shadows left are the `.gl` neutral shadow and the sheet shadow `0 -1px 0 rgba(255,255,255,.6) inset, 0 20px 60px rgba(20,4,12,.25)`.

---

## 3. Native iOS 26 fidelity

### N1 · P0 · Persistent floating tab bar with a sliding selection capsule
Today `tabs()` is re-rendered inside every page, so the selection cannot animate and the bar slides away with the page on a push. Make it persistent inside `#view`, so it scales with the page under sheets.

The JS changes are:
1. Change `tabs()` to return `''`.
2. Delete every `c:()=>tabs('X')` and add `tab:'Home'|'Plan'|'Coach'|'Me'` to the screen object. For Coins use `tab:'*'` (keep the current tab, because it is pushed from Home or Me). Coach keeps `c:` for the composer only.
3. Create the bar once, after the `phone.insertAdjacentHTML(...)` overlay block:
```js
const TABS=[['Home','home','Home'],['Plan','list','Plan'],['Coach','chat','Coach'],['Me','user','Subscription']];
view.insertAdjacentHTML('beforeend','<nav class="tabbar gl" id="tabbar" aria-label="Main"><span class="tcap" aria-hidden="true"></span>'+
 TABS.map(t=>'<button data-tab="'+t[2]+'" aria-current="false">'+I[t[1]]+'<span>'+t[0]+'</span></button>').join('')+
 '</nav><button class="sosb gl" id="sosb" data-to="SOS" aria-label="SOS, always free">'+I.heart+'<span>SOS</span></button>');
let curTab='Home';
function syncTabs(a){const tb=document.getElementById('tabbar'),sb=document.getElementById('sosb'),i=TABS.findIndex(t=>t[0]===a);
 tb.classList.toggle('hidden',i<0);sb.classList.toggle('hidden',i<0);if(i<0)return;
 const prev=+tb.style.getPropertyValue('--i');if(prev!==i&&tb.style.getPropertyValue('--i')!==''){const c=tb.querySelector('.tcap');c.classList.remove('moving');void c.offsetWidth;c.classList.add('moving');}
 tb.style.setProperty('--i',i);tb.querySelectorAll('button').forEach((b,k)=>{b.classList.toggle('on',k===i);b.setAttribute('aria-current',k===i?'page':'false');});}
```
CSS (replaces `.tabbar…` and `.sosb…`):
```css
.tabbar{position:absolute;left:20px;right:92px;bottom:20px;height:62px;border-radius:31px;padding:4px;display:grid;grid-template-columns:repeat(4,1fr);z-index:10;
 transition:transform var(--d-smooth) var(--ease-smooth),opacity .2s}
.tabbar.hidden,.sosb.hidden{transform:translateY(calc(100% + 28px));opacity:0;pointer-events:none}
.tcap{position:absolute;top:4px;bottom:4px;left:4px;width:calc((100% - 8px)/4);border-radius:27px;background:rgba(58,15,34,.08);
 transform:translateX(calc(var(--i,0)*100%));transition:transform var(--d-snappy) var(--ease-snappy)}
.tabbar button{position:relative;z-index:1;border:0;background:transparent;border-radius:27px;display:flex;flex-direction:column;align-items:center;justify-content:center;gap:2px;
 font:600 10px/12px var(--sans);color:var(--ink);cursor:pointer;transition:transform .35s var(--ease-snappy)}
.tabbar button svg.i{width:24px;height:24px;stroke-width:1.8}
.tabbar button.on{color:var(--accent)}
.tabbar button:active{transform:scale(.92);transition-duration:.08s}
.sosb{position:absolute;right:20px;bottom:20px;width:62px;height:62px;border-radius:50%;z-index:10;border:0;display:flex;flex-direction:column;align-items:center;justify-content:center;gap:1px;
 color:var(--danger);font:600 10px/12px var(--sans);cursor:pointer;transition:transform .35s var(--ease-snappy),opacity .2s}
.sosb:active{transform:scale(1.06);transition-duration:.1s}
```
Unselected items use `--ink` (primary label), not muted pink. That is what iOS 26 does, and it reads as more native. In `render()`, set `if(sc.tab!=='*')curTab=sc.tab||null; syncTabs(curTab);`. Keep `.scr` bottom padding at 120px on tab screens.

### N2 · P0 · Large title that collapses into an inline nav title, with the iOS 26 scroll-edge effect
New helpers (replace `nav()`):
```js
function bar(title,o){o=o||{};const lead=o.back||o.close?'<button class="gbtn gl" data-act="back" aria-label="'+(o.close?'Close':'Back')+'">'+(o.close?I.x:I.back)+'</button>':'<span class="nb-sp"></span>';
 return '<header class="nb">'+lead+'<span class="nb-t'+(o.large?' inl':'')+'">'+title+'</span><span class="nb-r">'+(o.right||'')+'</span></header>';}
function largeTitle(t,sub){return '<div class="lt"><h1>'+t+'</h1>'+(sub?'<p class="sub">'+sub+'</p>':'')+'</div>';}
function wireScroll(pg){const sc=pg.querySelector('.scr');if(!sc)return;const f=()=>pg.classList.toggle('scrolled',sc.scrollTop>36);sc.addEventListener('scroll',f,{passive:true});f();}
```
`bar()` is rendered **outside** `.scr` (it goes in `c:` or is prepended in `render`). Simplest: add a screen property `nb:()=>bar(...)`, and in `render` build `(sc.nb?sc.nb():'')+'<div class="scr '+…+(sc.nb?' has-nb':'')+'">'`.
```css
.nb{position:absolute;top:54px;left:0;right:0;height:52px;padding:0 var(--s4);display:flex;align-items:center;gap:var(--s2);z-index:5}
.nb::before{content:"";position:absolute;left:0;right:0;top:-54px;bottom:-20px;z-index:-1;background:linear-gradient(var(--bg) 50%,rgba(255,245,247,0));
 -webkit-backdrop-filter:blur(8px);backdrop-filter:blur(8px);-webkit-mask:linear-gradient(#000 55%,transparent);mask:linear-gradient(#000 55%,transparent);opacity:0;transition:opacity .2s}
.scrolled .nb::before{opacity:1}
.nb-sp,.nb-r{min-width:44px;display:flex;justify-content:flex-end}.nb-sp{justify-content:flex-start}
.nb-t{flex:1;text-align:center;font:600 17px/22px var(--sans);white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.nb-t.inl{opacity:0;transform:translateY(6px);transition:opacity .18s,transform .25s var(--ease-smooth)}
.scrolled .nb-t.inl{opacity:1;transform:none}
.lt{padding:0 0 var(--s2)}
.scr{padding:60px var(--s4) 120px;gap:var(--s6)}   /* was 20px sides, 16 gap */
.scr.has-nb{padding-top:106px}                     /* 54 status + 52 bar */
```
Which screens get which bar:

| Screen | Bar setup |
|---|---|
| Home | `bar('Today',{large:1,right:coinChip()})`, `largeTitle('Today', greeting+', '+CFG.name)` |
| Plan | `bar('Your 30 Days',{large:1,right:coinChip()})`, `largeTitle('Your 30 Days','Day '+(s.done+1)+' of 30')` |
| Me | `bar('Me',{large:1})`, `largeTitle('Me')` |
| Analysis, Coins, Trial status | `bar('Analysis'|'Coins'|'Your Trial',{back:1})`, inline title only, no large title |
| Coach | custom center header (N11) |
| Paywall, SOS | `bar('',{close:1,right:…})` (modal, N5) |

`.gbtn` icons: `I.back` stroke-width 2.4 at 22px (it matches SF chevron.left semibold).

### N3 · P0 · Real push/pop: 30% parallax plus dimming of the underlying page
`render()` currently replaces `view.innerHTML`, so the outgoing page never animates. Rewrite the page-swap part of `render`:
```js
const RM=matchMedia('(prefers-reduced-motion: reduce)');
function render(anim,fromCoins){const sc=SC[s.i],old=view.querySelector('.page:not(.leaving)'),tb=document.getElementById('tabbar');
 const keep=!anim&&old?old.querySelector('.scr').scrollTop:0;
 const pg=document.createElement('div');pg.className='page';
 pg.innerHTML=(sc.nb?sc.nb():'')+'<div class="scr '+(sc.pad||'')+(sc.nb?' has-nb':'')+'">'+sc.h()+'</div>'+(sc.c?sc.c():'');
 const d=RM.matches&&anim?'fade':dir;
 if(anim&&old){old.classList.add('leaving','out-'+d);old.inert=true;old.querySelectorAll('[id]').forEach(e=>e.removeAttribute('id'));
  pg.classList.add('in-'+d);view.insertBefore(pg,tb);
  const kill=()=>old.isConnected&&old.remove();old.addEventListener('animationend',e=>{if(e.target===old)kill();});setTimeout(kill,700);
  pg.addEventListener('animationend',e=>{if(e.target===pg)pg.classList.remove('in-'+d);});
 }else{if(old)old.remove();view.insertBefore(pg,tb);pg.querySelector('.scr').scrollTop=keep;}
 wireScroll(pg);if(sc.tab!=='*')curTab=sc.tab||null;syncTabs(curTab);
 /* …keep: steps highlight, why, seg buttons. Coach autoscroll must use pg.querySelector('.scr') … */
 if(sc.n==='Paywall')placeHl(pg,true);
 countUp(anim,fromCoins);tick();dir='fwd';}
```
Two side effects matter here. Preserving `scrollTop` on `render(false)` fixes the jump to top on every toggle, coin spend and day completion. Stripping ids from the leaving page keeps `getElementById('msg')` correct.

CSS (replaces `.page.fwd/.bck/.tab` and their keyframes):
```css
.page{position:absolute;inset:0;background:var(--page);overflow:hidden}
.page.in-fwd{animation:pushIn var(--d-smooth) var(--ease-smooth) both;box-shadow:-10px 0 30px rgba(58,15,34,.10)}
.page.out-fwd{animation:pushOut var(--d-smooth) var(--ease-smooth) both}
.page.in-bck{animation:popIn var(--d-smooth) var(--ease-smooth) both}
.page.out-bck{z-index:2;animation:popOut var(--d-smooth) var(--ease-smooth) both;box-shadow:-10px 0 30px rgba(58,15,34,.10)}
.page.out-fwd::after,.page.in-bck::after{content:"";position:absolute;inset:0;background:#14040C;pointer-events:none;z-index:9}
.page.out-fwd::after{animation:dimIn var(--d-smooth) var(--ease-smooth) both}
.page.in-bck::after{animation:dimOut var(--d-smooth) var(--ease-smooth) both}
@keyframes pushIn{from{transform:translateX(100%)}}
@keyframes pushOut{to{transform:translateX(-30%)}}
@keyframes popIn{from{transform:translateX(-30%)}}
@keyframes popOut{to{transform:translateX(100%)}}
@keyframes dimIn{from{opacity:0}to{opacity:.12}}
@keyframes dimOut{from{opacity:.12}to{opacity:0}}
/* tab switch: quick crossfade, no scale, no slide */
.page.in-tab{animation:fadeIn .18s var(--ease-out) both}
.page.out-tab{animation:fadeOut .18s var(--ease-out) both}
.page.in-fade{animation:fadeIn .2s linear both}.page.out-fade{animation:fadeOut .2s linear both}
@keyframes fadeIn{from{opacity:0}}@keyframes fadeOut{to{opacity:0}}
```

### N4 · P0 · Sheets: the page behind scales to 0.94 with rounded corners, the sheet dismisses with animation, and in-place updates don't re-slide
Replace `openOv`, `closeOv` and `sheet`:
```js
let ovTok=0;
function openOv(html,o){o=o||{};ovTok++;const ov=document.getElementById('ov');ov.classList.remove('closing');
 ov.innerHTML='<div id="ovbg"></div>'+html;ov.classList.add('open');phone.classList.toggle('presenting',!o.noScale);
 const f=ov.querySelector('button');if(f)f.focus({preventScroll:true});}
function closeOv(instant){const ov=document.getElementById('ov');if(!ov.classList.contains('open'))return;const t=++ovTok;
 phone.classList.remove('presenting');const h=phone.querySelector('.sidehint');if(h)h.remove();
 if(instant||RM.matches){ov.classList.remove('open');ov.innerHTML='';return;}
 ov.classList.add('closing');setTimeout(()=>{if(t!==ovTok)return;ov.classList.remove('open','closing');ov.innerHTML='';},300);}
function sheet(inner,label){const ex=document.querySelector('#ov.open:not(.closing) .sheet[aria-label="'+esc(label||'Sheet')+'"]');
 if(ex){ex.innerHTML='<span class="grab"></span>'+inner;return;}   /* cancelSheet reason taps: update in place */
 openOv('<div class="sheet gl" role="dialog" aria-modal="true" aria-label="'+esc(label||'Sheet')+'"><span class="grab"></span>'+inner+'</div>');}
```
CSS:
```css
#view{position:absolute;inset:0;z-index:1;transform-origin:50% 0;overflow:hidden;border-radius:54px;
 transition:transform var(--d-smooth) var(--ease-smooth),border-radius var(--d-smooth) var(--ease-smooth)}
.phone.presenting #view{transform:translateY(14px) scale(.94);border-radius:38px}
.phone.presenting .sbar{color:#fff}                /* status bar turns white over black, as on iOS */
#ovbg{position:absolute;inset:0;background:rgba(20,4,12,.22);animation:fadeIn .35s var(--ease-out)}
.sheet{position:absolute;left:8px;right:8px;bottom:8px;border-radius:var(--r-sheet);padding:var(--s2) var(--s5) var(--s6);display:flex;flex-direction:column;gap:var(--s4);
 max-height:88%;overflow:auto;background:rgba(255,250,251,.86);-webkit-backdrop-filter:blur(30px) saturate(180%);backdrop-filter:blur(30px) saturate(180%);
 animation:sheetIn var(--d-smooth) var(--ease-smooth) both}
@keyframes sheetIn{from{transform:translateY(calc(100% + 16px))}}
#ov.closing .sheet,#ov.closing .sk{animation:sheetOut .3s var(--ease-in) forwards}
#ov.closing #ovbg{animation:fadeOut .3s var(--ease-in) forwards}
@keyframes sheetOut{to{transform:translateY(calc(100% + 16px))}}
.grab{width:36px;height:5px;border-radius:3px;background:var(--ink-3);align-self:center;margin-bottom:var(--s1)}
```
`store()` must call `openOv(…,{noScale:true})`. The StoreKit sheet is a system overlay, so iOS only dims the app behind it and does not scale it.
Change the status-bar SVGs in the `.sbar` markup from `fill="#3A0F22"`/`stroke="#3A0F22"` to `currentColor`.

### N5 · P1 · Paywall and SOS present modally (slide up, dismiss down)
Both screens use a close X. iOS presents them as full-screen covers, not pushes.
- Add `modal:1` to `SC` Paywall and SOS.
- In `go()`: `dir = SC[k].modal ? 'up' : 'fwd'` (when not a tab).
- In `back()`: `dir = SC[s.i].modal ? 'down' : 'bck'` (read before popping).
```css
.page.in-up{animation:upIn var(--d-smooth) var(--ease-smooth) both;z-index:3}
.page.out-up::after{content:"";position:absolute;inset:0;background:#14040C;animation:dimIn var(--d-smooth) both}
.page.out-down{z-index:3;animation:downOut .4s var(--ease-smooth) both}
.page.in-down::after{content:"";position:absolute;inset:0;background:#14040C;animation:dimOut .4s both}
@keyframes upIn{from{transform:translateY(100%)}}@keyframes downOut{to{transform:translateY(100%)}}
```
Also hide the tab bar on modal screens (they have no `tab`).

### N6 · P1 · StoreKit 2 purchase sheet, iOS 26 layout (`store()`, `.sk*`)
The current sheet is close, but the "App Store" title, "Cancel" text button and blue filled CTA belong to the older design. Here is an approximation of the current system sheet:
```js
function store(k){const p=product(k);
 openOv('<div class="sk" role="dialog" aria-modal="true" aria-label="App Store purchase">'+
  '<div class="sk-top"><span class="sk-ic">'+appIcon(60)+'</span><div class="grow"><b class="sk-t">'+esc(p.t)+'</b><div class="sk-m">MyEx: Breakup Recovery</div><div class="sk-m">'+esc(p.kind)+'</div></div>'+
  '<button class="sk-x" data-act="closeOv" aria-label="Cancel">'+I.x+'</button></div>'+
  '<div class="sk-box"><b class="sk-big">'+esc(p.pr)+'</b><span class="sk-m">'+esc(p.sub)+'</span>'+(p.fine?'<span class="sk-fine">'+esc(p.fine)+'</span>':'')+'</div>'+
  '<div class="sk-box sk-acct"><span>Account</span><span>s•••••@icloud.com</span></div>'+
  '<button class="sk-cta" id="skc" data-act="confirmBuy" data-k="'+k+'">'+I.faceid.replace(/64/g,'40')+'<span>Confirm with Side Button</span></button></div>',{noScale:true});
 phone.insertAdjacentHTML('beforeend','<div class="sidehint" aria-hidden="true"><span>Double Click<br>to Pay</span><i></i></div>');}
```
In `product()`, add `kind` ("Subscription" or "In-App Purchase") and `fine`. For annual, `fine` is "Plan automatically renews for $49.99/year until canceled.". Set annual `pr` to "7-day free trial" and `sub` to "Starting "+dateIn(7)+": $49.99/year".
```css
.sk{position:absolute;left:0;right:0;bottom:0;background:#F2F2F7;border-radius:var(--r-sheet) var(--r-sheet) 0 0;padding:var(--s5) var(--s4) 34px;
 font-family:-apple-system,"SF Pro Text","Inter",sans-serif;color:#000;display:flex;flex-direction:column;gap:var(--s3);animation:sheetIn .45s var(--ease-smooth) both}
.sk-top{display:flex;gap:var(--s3);align-items:flex-start}
.sk-t{font:600 17px/22px inherit}.sk-m{font:400 13px/18px inherit;color:#6C6C70}
.sk-x{width:30px;height:30px;border-radius:50%;border:0;background:rgba(120,120,128,.16);color:#6C6C70;display:grid;place-items:center;cursor:pointer;position:relative}
.sk-x::before{content:"";position:absolute;inset:-7px}  /* 44pt hit area */
.sk-x svg.i{width:14px;height:14px;stroke-width:2.6}
.sk-box{background:#fff;border-radius:var(--r-m);padding:var(--s4);display:flex;flex-direction:column;gap:2px}
.sk-big{font:700 22px/28px inherit}
.sk-fine{font:400 13px/18px inherit;color:#6C6C70;margin-top:var(--s2)}
.sk-acct{flex-direction:row;justify-content:space-between;font:400 15px/20px inherit}.sk-acct span:first-child{color:#6C6C70}
.sk-cta{border:0;background:transparent;display:flex;flex-direction:column;align-items:center;gap:var(--s2);padding:var(--s3) 0 0;font:400 15px/20px inherit;color:#000;cursor:pointer;min-height:44px}
.sidehint{animation:sh 1.6s ease-in-out infinite}.sidehint span{font:600 12px/15px -apple-system,"Inter",sans-serif;text-align:right}
.sidehint i{width:5px;height:64px;border-radius:3px 0 0 3px;background:#007AFF}
```
`confirmBuy` changes: replace `.spin` with the iOS activity indicator. Draw 8 bars rotating with `steps(8)`:
```css
.spin{width:28px;height:28px;border:0;background:conic-gradient(from 0deg,#8E8E93 0 12.5%,transparent 0);-webkit-mask:radial-gradient(circle,transparent 7px,#000 7.5px);mask:radial-gradient(circle,transparent 7px,#000 7.5px);animation:rot .8s steps(8) infinite}
```
(A cheaper alternative is to keep the ring but use `#8E8E93`.) Replace the `.okc` green pop with a system-blue circle and a check that draws in:
```css
.okc{width:56px;height:56px;border-radius:50%;border:3px solid #007AFF;color:#007AFF;display:grid;place-items:center;animation:pop var(--d-bouncy) var(--ease-bouncy) both;background:none}
.okc svg{width:28px;height:28px;stroke-width:3;stroke-dasharray:24;stroke-dashoffset:24;animation:draw .35s .15s var(--ease-out) forwards}
@keyframes pop{from{transform:scale(.6);opacity:0}}@keyframes draw{to{stroke-dashoffset:0}}
```
Change "Processing…" to no text (iOS shows only the spinner) and keep "Done" in 17/600. Call `haptic(2)` when "Done" appears (M3).
App icon helper, used in StoreKit and the notification:
```js
function appIcon(sz){return '<span class="appi" style="width:'+sz+'px;height:'+sz+'px;border-radius:'+Math.round(sz*.225)+'px">'+lumi({e:['happy'],m:'smile',light:1},Math.round(sz*.78))+'</span>';}
```
```css
.appi{display:grid;place-items:center;background:var(--hero);box-shadow:inset 0 0 0 .5px rgba(0,0,0,.08);flex:none}
```

### N7 · P1 · Lock screen and notification (`SC` "Trial reminder")
```js
h:()=>{if(s.trial)s.tday=Math.max(s.tday,5);const d=new Date();
 return '<div class="lock-scr"></div><div class="ls">'+
  '<div class="ls-date">'+d.toLocaleDateString('en-US',{weekday:'long',month:'long',day:'numeric'})+'</div>'+
  '<div class="ls-time">'+d.getHours()+':'+String(d.getMinutes()).padStart(2,'0')+'</div></div>'+
  '<button class="notif gl" data-to="Trial status">'+appIcon(38)+'<span class="grow"><span class="n-top"><b>Your trial ends in 2 days</b><time>now</time></span>'+
  '<span class="n-body">'+(s.sent+11)+' talks with Mira and '+s.drafts+' unsent texts so far. If it’s not for you, cancel anytime in Settings.</span></span></button>'+
  '<div class="ls-acts"><span class="gl">'+I.flash+'</span><span class="gl">'+I.camera+'</span></div>';}
```
```css
.lock-scr{position:absolute;inset:0;background:linear-gradient(180deg,#C2185B 0%,#E54C7E 55%,#F59AB4 100%)}   /* wallpaper: pink only, no coral */
.ls{position:relative;text-align:center;color:#fff;margin-top:var(--s4)}
.ls-date{font:600 20px/25px var(--sans);opacity:.92}
.ls-time{font:700 96px/1 -apple-system,"SF Pro Rounded","Inter",sans-serif;letter-spacing:-.03em;text-shadow:0 1px 20px rgba(120,0,40,.15)}
.notif{position:relative;margin-top:auto;margin-bottom:96px;border-radius:24px;padding:14px;display:flex;gap:var(--s3);align-items:flex-start;text-align:left;cursor:pointer;color:var(--ink)}
.n-top{display:flex;justify-content:space-between;gap:var(--s2);font:600 15px/20px var(--sans)}.n-top time{font:400 13px/18px var(--sans);color:var(--ink-2)}
.n-body{display:block;font:400 15px/20px var(--sans)}
.ls-acts{position:absolute;left:46px;right:46px;bottom:44px;display:flex;justify-content:space-between}
.ls-acts span{width:50px;height:50px;border-radius:50%;display:grid;place-items:center;color:#fff;background:rgba(255,255,255,.18)}
```
Add the icons `flash:ic('<path d="M8 3h8l-1 6H9zM9 9v11h6V9"/>')` and `camera:ic('<rect x="3" y="7" width="18" height="13" rx="3"/><path d="M8 7l1.5-3h5L16 7"/><circle cx="12" cy="13.5" r="3.5"/>')`. Also add `phone.classList.toggle('dark-sb',sc.n==='Trial reminder')` in `render` and the CSS `.phone.dark-sb .sbar{color:#fff}`. The lock screen has no app status chrome, so it also needs `.phone.dark-sb .hind{background:rgba(255,255,255,.7)}`.

### N8 · P1 · iOS switch (`.sw`)
```css
.sw{width:51px;height:31px;border-radius:16px;background:rgba(120,120,128,.16);position:relative;border:0;flex:none;cursor:pointer;transition:background .25s var(--ease-out)}
.sw::before{content:"";position:absolute;inset:-7px -4px}   /* 44pt hit */
.sw::after{content:"";position:absolute;top:2px;left:2px;width:27px;height:27px;border-radius:14px;background:#fff;box-shadow:0 3px 8px rgba(0,0,0,.15),0 1px 1px rgba(0,0,0,.16);
 transition:left var(--d-snappy) var(--ease-snappy),width .2s var(--ease-out)}
.sw:active::after{width:33px}                    /* knob stretches while pressed, like UISwitch */
.sw.on{background:var(--switch-on)}.sw.on::after{left:22px}.sw.on:active::after{left:16px}
```
`ACT.remind`: toggle the class and `aria-checked` in place, do not call `render(false)`, then call `haptic()`.

### N9 · P1 · Hit targets ≥ 44pt
- `.dockbar .links button`: `min-height:44px`
- `.meter button`: keep the 28px visual and add `position:relative` plus `::before{content:"";position:absolute;inset:-8px -4px}`
- `.chip`: `min-height:44px`
- `.seg button` is side panel, so ignore it
- `.sk-x`: covered in N6
- `.plan .rad`: the whole row is the target, which is fine

### N10 · P2 · Continuous corners (progressive)
```css
@supports (corner-shape:squircle){.card,.list,.plan,.plans,.sheet,.sk-box,.appi,.ico-sq,.notif,.hero,.inp{corner-shape:superellipse(1.4)}}
```
Tune it by eye in Chrome 139+. Everywhere else the `border-radius` scale stays (8/12/16/22/28/38/capsule). Audit the odd values `14px`, `18px`, `20px`, `24px`, `26px` and `40px` in `.dayr .n`, `.note`, `.lockwrap`, `.bub`, `.card`, `.tile`, `.sheet` and `.inp`, and snap each to the scale.

### N11 · P2 · Dynamic Island and home indicator sizes
`.phone::before`: `width:126px;height:37px;margin-left:-63px;border-radius:19px;top:11px`. `.hind`: `width:139px;margin-left:-69.5px;background:rgba(58,15,34,.85)` (iOS uses near-black on light content).

---

## 4. Screen-by-screen rebuilds

### H1 · P0 · Home (`SC` "Home"): replace the bento with a hero plus a grouped list
```js
nb:()=>bar('Today',{large:1,right:coinChip()}),tab:'Home',
h:()=>{const hr=new Date().getHours(),g=hr<5?'Still up':hr<12?'Good morning':hr<18?'Good afternoon':'Good evening',open=s.premium||s.analysis;
 return largeTitle('Today',g+', '+CFG.name)+
 '<button class="hero" data-tab="Plan"><span class="hero-k">'+I.flame+'No contact</span>'+
  '<span class="hero-n"><span class="num" style="font-size:88px">12</span><span class="hero-u">days</span></span>'+
  '<span class="hero-p"><i style="width:86%"></i></span><span class="hero-f">2 more days to two weeks</span></button>'+
 '<div class="list">'+
  row({icon:I.plan,t:'Three things you don’t miss',st:'Day 3 · 5 min',attr:'data-tab="Plan"'})+
  row({icon:I.chat,tone:'neu',t:'Talk to Mira',st:s.premium?'Anytime, no limit':s.left+' free message'+(s.left===1?'':'s')+' left tonight',attr:'data-tab="Coach"'})+
  row({icon:I.scan,tone:'neu',t:'Your analysis',st:open?'3 insights ready':'1 of 3 insights unlocked',attr:'data-to="Analysis"'})+
 '</div>'+
 '<div class="list">'+row({icon:I.heart,tone:'dg',t:'About to text them?',st:'Pause first. SOS is always free.',attr:'data-to="SOS"'})+'</div>'+
 (s.trial?'<div class="list">'+row({icon:I.clock,t:'Free trial: '+trialLeft()+' days left',st:'See your progress',attr:'data-to="Trial status"'})+'</div>'
 :!s.premium?'<div class="list">'+row({icon:I.lock,tone:'neu',t:'Day 4 is part of Premium',val:'Try free',attr:'data-to="Paywall"'})+'</div>':'');}
```
```css
.hero{border:0;text-align:left;color:#fff;border-radius:var(--r-xl);padding:var(--s5);display:flex;flex-direction:column;gap:var(--s1);background:var(--hero);cursor:pointer;
 transition:transform .35s var(--ease-snappy)}.hero:active{transform:scale(.98);transition-duration:.08s}
.hero-k{display:flex;align-items:center;gap:6px;font:600 15px/20px var(--sans)}.hero-k svg.i{width:18px;height:18px}
.hero-n{display:flex;align-items:baseline;gap:var(--s2);margin-top:var(--s1)}.hero-u{font:600 20px/25px var(--sans)}
.hero-p{display:block;height:4px;border-radius:2px;background:rgba(255,255,255,.3);margin-top:var(--s3)}.hero-p i{display:block;height:100%;border-radius:2px;background:#fff}
.hero-f{font:400 15px/20px var(--sans);color:#fff}   /* solid white; any opacity drops it below 4.5:1 */
```
Removed from Home: the Premium crown chip, the peeking Lumi, the Mira quote, the wine SOS tile and the `data-count` roll on "12" (M2).

### P1 · P0 · Paywall layout (`SC` "Paywall"): calm, honest, one hierarchy
Benchmarks:
- **Calm and Headspace:** one headline, 3 benefits, two plan rows, the full price shown plainly, quiet legal text.
- **Finch:** warmth comes from tone, not decoration.
- **Duolingo:** a clear trial timeline.
- **Bumble:** "best value" marked once.

None of them use gradient headlines, a mascot with a crown, or per-week pricing as the largest number.

Structure, top to bottom:
1. `bar('',{close:1,right:'<button class="btn txt" data-act="restore" style="min-height:44px;font-size:17px">Restore</button>'})`, with the close handler `data-act="closePaywall"` (keep it). Because `bar()` uses `data-act="back"`, pass a custom leading button for Paywall.
2. Head, centered: `<h1 class="display">30 days to feel like you again.</h1><p class="sub" style="font-size:17px;line-height:22px">All 30 days of your plan, and Mira whenever it gets hard.</p>`
3. **Plan strip** (meaningful visual, replaces the Lumi crown): 30 small capsules in a 15×2 grid, days 1–2 filled `--success`, day 3 `--accent`, days 4–30 `--fill`. Caption `.foot` "You’re on Day 3. Premium opens the rest."
```css
.strip{display:grid;grid-template-columns:repeat(15,1fr);gap:4px;padding:0 var(--s2)}.strip i{height:8px;border-radius:4px;background:var(--fill)}
.strip i.d{background:var(--success)}.strip i.t{background:var(--accent)}
```
4. Benefits list (3 rows, no tinted icon squares, glyph in `--accent`):
```html
<ul class="ben"><li>{I.chat}<span><b>Talk to Mira anytime</b><small>No nightly message limit</small></span></li>
<li>{I.plan}<span><b>All 30 days of your plan</b><small>Free stops after Day 3</small></span></li>
<li>{I.scan}<span><b>Your full analysis</b><small>All three patterns, not just one</small></span></li></ul>
```
```css
.ben{list-style:none;margin:0;padding:0;display:flex;flex-direction:column;gap:var(--s4)}
.ben li{display:flex;gap:var(--s3);align-items:flex-start}.ben li svg.i{color:var(--accent);width:24px;height:24px;margin-top:-1px}
.ben b{display:block;font:600 17px/22px var(--sans)}.ben small{display:block;font:400 15px/20px var(--sans);color:var(--ink-2)}
```
The "50 bonus coins" bullet moves to the fine print.
5. Plan picker: one container with a sliding highlight (P3).
6. Variant A: a trust timeline inside `.tl-wrap` (collapses for Monthly), with the reminder switch **inside step 2** (delete the separate `rem` card). Variant B: the compare table (P5).
7. Footnote `.foot` centered: `I.lock` + "Your conversations stay private."
8. Dock (`c:`): see P2.

Delete the `.note` "Cancel in 2 taps…" pill (it duplicates the fine print).

### P2 · P0 · Price display (App Store 3.1.2 and trust) — coordinator-confirmed
- The billed amount ($49.99/year) must be at least as prominent as any per-period breakdown. Today `.plan .pr` shows $0.96/week larger than the annual price. Fix: `.pr` shows the billed price; the per-month equivalent moves to the 13pt subtitle.
- Headline: replace "healed in 30 days" (a health claim) with "30 days to feel like you again."
- Cancel survey: remove the unmeasured "Most people who turn it on use MyEx 3× more."
- QA: the dock showed content through it behind the fine print and links. Make `.dockbar` solid `--bg` under its text (gradient only on its top 24px) and set `.scr.dock{padding-bottom:204px}`.

The billed amount must be the most prominent price. Today `$0.96 per week` is larger than `$49.99 per year`, which is a review risk and the classic growth-hack tell. Do this:
- Plan rows: the right column primary is the billed price (`$49.99` with "per year" under it, `$12.99` with "per month" under it). Under "Yearly" on the left: "7 days free · $4.17/month" and a green "Save 68%".
- Add `const MONTHLY_EQ=CFG.annual.price/12;`. Delete `WEEKLY` usage everywhere: paywall, Trial status, `exitOffer` "That’s $0.48 a week" and the `why` text, if you are allowed to touch it.
- Dock:
```js
c:()=>{const a=s.pick==='annual';return '<div class="dockbar"><button class="btn pri" data-act="buy" data-k="'+s.pick+'"><span class="swap">'+(a?'Start Free Trial':'Subscribe')+'</span></button>'+
 '<p class="fine swap">'+(a?CFG.annual.trial+' days free, then '+$$(CFG.annual.price)+'/year. Cancel anytime in Settings.':$$(CFG.monthly.price)+'/month. Cancel anytime in Settings.')+'</p>'+
 '<div class="links"><button data-act="legal">Terms of Use</button><span aria-hidden="true">·</span><button data-act="legal">Privacy Policy</button></div></div>';}
```
```css
.dockbar{padding:var(--s6) var(--s4) 30px;background:linear-gradient(to top,var(--bg) 70%,rgba(255,245,247,0));gap:var(--s2)}
.dockbar .fine{font:400 13px/18px var(--sans);color:var(--ink-2);text-align:center;margin:0}
.dockbar .links{display:flex;justify-content:center;align-items:center;gap:var(--s2);color:var(--ink-3)}
.dockbar .links button{border:0;background:none;font:400 13px/18px var(--sans);color:var(--ink-2);text-decoration:none;min-height:44px;cursor:pointer}
```

### P3 · P0 · Plan-selection morph (in place, no re-render)
Markup in the Paywall `h`:
```js
const plans='<div class="plans" role="radiogroup" aria-label="Choose a plan"><span class="plan-hl" aria-hidden="true"></span>'+
 '<button class="plan'+(s.pick==='annual'?' on':'')+'" role="radio" aria-checked="'+(s.pick==='annual')+'" data-act="pick" data-k="annual"><span class="rad">'+I.check+'</span>'+
  '<span class="grow"><span class="pt">Yearly <span class="save">Save '+SAVE+'%</span></span><span class="ps">'+CFG.annual.trial+' days free · '+$$(MONTHLY_EQ)+'/month</span></span>'+
  '<span class="pr">'+$$(CFG.annual.price)+'<small>per year</small></span></button>'+
 '<button class="plan'+(s.pick==='monthly'?' on':'')+'" role="radio" aria-checked="'+(s.pick==='monthly')+'" data-act="pick" data-k="monthly"><span class="rad">'+I.check+'</span>'+
  '<span class="grow"><span class="pt">Monthly</span><span class="ps">No free trial</span></span><span class="pr">'+$$(CFG.monthly.price)+'<small>per month</small></span></button></div>';
```
CSS (replaces `.plan*`):
```css
.plans{position:relative;background:var(--bg-elev);border-radius:var(--r-l);padding:4px;display:flex;flex-direction:column}
.plan-hl{position:absolute;left:4px;right:4px;top:0;height:var(--h,72px);transform:translateY(var(--y,4px));border-radius:18px;background:var(--accent-soft);box-shadow:inset 0 0 0 2px var(--accent);
 transition:transform var(--d-snappy) var(--ease-snappy),height var(--d-snappy) var(--ease-snappy)}
.plan-hl.no-t{transition:none}
.plan{position:relative;z-index:1;border:0;background:transparent;border-radius:18px;padding:14px var(--s4);min-height:72px;display:flex;align-items:center;gap:var(--s3);text-align:left;font:inherit;color:var(--ink);cursor:pointer;transition:transform .35s var(--ease-snappy)}
.plan:active{transform:scale(.98);transition-duration:.08s}
.plan .rad{width:22px;height:22px;border-radius:50%;box-shadow:inset 0 0 0 1.5px var(--ink-3);display:grid;place-items:center;flex:none;transition:background .2s,box-shadow .2s}
.plan.on .rad{background:var(--accent);box-shadow:none}
.plan .rad svg{width:12px;height:12px;stroke:#fff;stroke-width:3.2;transform:scale(0);transition:transform .15s var(--ease-in)}
.plan.on .rad svg{transform:scale(1);transition:transform var(--d-bouncy) var(--ease-bouncy)}
.plan .pt{font:600 17px/22px var(--sans)}.plan .ps{font:400 13px/18px var(--sans);color:var(--ink-2)}
.plan .save{font:600 13px/18px var(--sans);color:var(--success);margin-left:6px}
.plan .pr{margin-left:auto;text-align:right;font:600 17px/22px var(--sans);font-variant-numeric:tabular-nums}.plan .pr small{display:block;font:400 13px/18px var(--sans);color:var(--ink-2)}
.tl-wrap{display:grid;grid-template-rows:0fr;opacity:0;transition:grid-template-rows var(--d-smooth) var(--ease-smooth),opacity .2s}
.tl-wrap.open{grid-template-rows:1fr;opacity:1}.tl-wrap>*{min-height:0;overflow:hidden}
.swap{transition:opacity .12s}.swap.out{opacity:0}
```
JS:
```js
function placeHl(pg,instant){const on=pg.querySelector('.plan.on'),hl=pg.querySelector('.plan-hl');if(!on||!hl)return;
 if(instant)hl.classList.add('no-t');hl.style.setProperty('--y',on.offsetTop+'px');hl.style.setProperty('--h',on.offsetHeight+'px');
 if(instant)requestAnimationFrame(()=>hl.classList.remove('no-t'));}
ACT.pick=b=>{const k=b.dataset.k;if(s.pick===k)return;s.pick=k;const pg=b.closest('.page'),a=k==='annual';
 pg.querySelectorAll('.plan').forEach(p=>{const on=p.dataset.k===k;p.classList.toggle('on',on);p.setAttribute('aria-checked',on);});
 placeHl(pg);const tw=pg.querySelector('.tl-wrap');if(tw)tw.classList.toggle('open',a);
 const cta=pg.querySelector('.dockbar [data-act="buy"]');cta.dataset.k=k;
 swapText(cta.querySelector('.swap'),a?'Start Free Trial':'Subscribe');
 swapText(pg.querySelector('.dockbar .fine'),a?CFG.annual.trial+' days free, then '+$$(CFG.annual.price)+'/year. Cancel anytime in Settings.':$$(CFG.monthly.price)+'/month. Cancel anytime in Settings.');haptic();};
function swapText(el,t){if(!el||el.textContent===t)return;el.classList.add('out');setTimeout(()=>{el.textContent=t;el.classList.remove('out');},120);}
```
Always render the timeline wrapper (Variant A) as `<div class="tl-wrap'+(s.pick==='annual'?' open':'')+'"><div>…timeline…</div></div>`. Remove `data-set="pick:…"`.

Timeline restyle: `.tl` sits in a white `.card`. Dots are 28px, `--accent-soft` with an `--accent` glyph, and step 1 is solid `--accent` (no `--grad2`). The connector is `background:var(--sep)` (no gradient). Step 2 gets the switch on the right: `<div class="st"><span class="dot">'+I.bell+'</span><div class="grow"><b>'+dateIn(5)+'</b><span>We’ll send you a reminder.</span></div><button class="sw …" data-act="remind" …></button></div>`. Step 3 uses `I.check`.

### P4 · P1 · Exit offer (`exitOffer`)
```js
sheet('<div class="col ctr" style="gap:8px;padding-top:8px"><h2 class="display" style="font-size:34px;line-height:40px">Your first year, half price.</h2>'+
 '<p class="sub" style="font-size:17px;line-height:22px">'+$$(CFG.offer.price)+' for your first year, then '+$$(CFG.annual.price)+'/year. Cancel anytime.</p></div>'+
 '<button class="btn pri" data-act="buy" data-k="offer">Try a Year for '+$$(CFG.offer.price)+'</button>'+
 '<button class="btn txt" data-act="goFree">Not Now</button>','Special offer');
```
Removed: the flower Lumi, the eyebrow, the italic and "We only show this once." (false urgency; it erodes trust and looks like a dark pattern to App Review).

### P5 · P1 · Variant B compare table (`.cmp`)
Headers are sentence case `600 13px/18px var(--sans)` in `--ink-2`, and the Premium header is `--accent-ink`. Cells are `15px/20px`, 400. Free "—" uses `--ink-3`. Premium ✓ is an `--accent` check icon at 18px. Remove the uppercase and letter-spacing. `.cmp .p{background:var(--accent-soft)}` stays as the single column highlight, and the last Premium cell gets `border-radius:0 0 12px 12px`. Change row labels "Draft Jail" to "Unsent drafts (Draft Jail)" and "Analysis" to "Relationship analysis".

### S1 · P1 · Plan ready (`SC` "Plan ready")
```js
h:()=>stage(lumi({e:['happy'],m:'big',wave:1},170),200,180)+
 '<div class="col ctr" style="gap:8px"><h1 class="display">Your plan is ready.</h1><p class="sub" style="font-size:17px;line-height:22px">Built from your answers. It starts small, tonight.</p></div>'+
 '<div class="list">'+[['What happened','They ended it'],['Attachment style','Anxious'],['Focus','No contact, self-worth'],['First step','Tonight · 4 min']]
  .map(r=>row({t:r[0],val:r[1],chev:false})).join('')+'</div>'+
 '<p class="foot" style="text-align:center">Grounded in CBT and attachment research. Private by default.</p>',
c:()=>'<div class="dockbar"><button class="btn pri" data-to="Paywall">Continue</button></div>'
```
The `.row-i` rows here are `<button>` elements. Pass `attr:'tabindex="-1" disabled'`, or use a `<div>` variant (`.row-i` also works on `div`) so they are not focusable.

### S2 · P1 · Plan (`SC` "Plan")
- Use the large title (N2).
- Replace the bar with an iOS progress bar: `.pbar{height:4px;border-radius:2px;background:var(--fill)}.pbar i{display:block;height:100%;border-radius:2px;background:var(--accent)}` plus the `.foot` "2 of 30 days · 7%" on the right.
- Show two sections, `<h2 class="sec-h">This week</h2>` for days 1–7 and `<h2 class="sec-h">Next week</h2>` for day 8, each a `.list`.
- Each day uses `row()` with a 28px leading circle `.dn`:
  - done: `--success-soft` background with a `--success` check
  - today: solid `--accent` with a white number
  - open: `--fill` with an `--ink` number
  - locked: `--fill` with an `--ink-3` lock
- Title = day name (17/400). Subtitle = "Day 1 · Done", "Day 3 · Today · 5 min", "Day 5 · Opens in 2 days", or "Day 4 · Premium" (or "Unlocked with coins").
- Show a chevron only on today. Delete `.dayr*`.
```css
.dn{width:28px;height:28px;border-radius:50%;display:grid;place-items:center;flex:none;font:600 13px/1 var(--sans);background:var(--fill);color:var(--ink)}
.dn svg.i{width:14px;height:14px;stroke-width:2.6}.dn.done{background:var(--success-soft);color:var(--success)}.dn.today{background:var(--accent);color:#fff}.dn.lock{color:var(--ink-3)}
```

### S3 · P1 · Coach (`SC` "Coach")
- **Header** (iMessage pattern): `nb:()=>'<header class="nb chat-nb"><span class="nb-sp"></span><span class="chat-id">'+mira(36)+'<span>Mira</span></span><span class="nb-r"></span></header>'`.
```css
.chat-id{flex:1;display:flex;flex-direction:column;align-items:center;gap:2px;font:400 11px/13px var(--sans);color:var(--ink)}
.chat-nb::before{opacity:1}   /* always show the edge effect in chat */
.scr.chat.has-nb{padding-top:118px}
```
- **Bubbles:**
```css
.bub{max-width:78%;padding:7px 12px;border-radius:18px;font:400 17px/22px var(--sans)}
.bub.ai{background:var(--bg-elev);color:var(--ink);box-shadow:none;align-self:flex-start}
.bub.me{background:var(--accent);color:#fff;align-self:flex-end;font-weight:400}
.bub.cont{margin-top:-8px}   /* consecutive same sender: 2px visual gap with container gap 10px */
```
  Add `cont` in the `s.chat` map when `m[0]===prev[0]`. The typing bubble keeps three dots in `--ink-3`, bouncing at 1.2s (it is a native pattern, so it stays).
- **Composer** (iOS 26 Messages): `.inp{border-radius:22px;min-height:44px;padding:4px 4px 4px 16px}`. The send button is a 32px `--accent` circle with an up arrow, hidden until there is text:
```css
.send{width:32px;height:32px;border-radius:50%;background:var(--accent);transform:scale(0);opacity:0;transition:transform .3s var(--ease-snappy),opacity .15s}
.inp.has-text .send{transform:scale(1);opacity:1}
.send::before{content:"";position:absolute;inset:-6px}
```
  Change the icon to `send:ic('<path d="M12 19V5M6 11l6-6 6 6"/>')` with stroke-width 2.6. Add a delegated listener: `document.addEventListener('input',e=>{if(e.target.id==='msg')e.target.closest('.inp').classList.toggle('has-text',!!e.target.value.trim());});`.
- **Meter:** `font:600 13px/18px`, dots 6px. The button label is "Get More". SOS state reads "SOS mode · no limits" in `--success`.
- Remove the "Private" tag, the serif 26px "Mira" and the "● Here for you" status line.

### S4 · P1 · Analysis (`SC` "Analysis")
- `nb:()=>bar('Analysis',{back:1})`.
- Card 1: `.hl` "Who reached out first". The bar is 8px tall with radius 4px, filled `--accent` 68% and `rgba(58,15,34,.14)` 32% (drop the peach #FFB38A, which is outside the palette). Below it: `.foot` "You 68% · Them 32%".
- Card 2: `.hl` "Patterns", numbered rows (A9), and the lockwrap overlay text "2 more patterns" with `I.lock`, in `600 15px` `--accent-ink`.
- Mira line: plain `.foot` row with a `mira(20)` orb. Locked: "Two more patterns are ready when you are." Open: "You gave a lot. Next time, look for someone who meets you halfway."
- Dock (locked): `btn pri` "Try Premium Free" and `btn gl` "Unlock for 30 Coins" (with the coin icon). Open: "Talk It Through with Mira".

### S5 · P1 · Coins (`SC` "Coins")
- `nb:()=>bar('Coins',{back:1})`, `tab:'*'`.
- Balance block, left-aligned, no card: `coinSvg(32)` and `<span class="num" data-count="…" style="font-size:72px">20</span>`, then `.foot` "coins".
- `<h2 class="sec-h">Get coins</h2>` followed by a `.list` of 3 rows:
  - leading `coinSvg(30)`
  - title "30 coins"
  - subtitle: "+10 bonus" in `--success`. On the 200 pack: "Best value · +40 bonus" (`.rs` in `--accent-ink`).
  - trailing price capsule (App Store "Get" style):
```css
.get{min-width:76px;height:30px;padding:0 14px;border-radius:15px;background:var(--accent-soft);color:var(--accent-ink);font:600 15px/30px var(--sans);text-align:center;font-variant-numeric:tabular-nums}
```
- `<h2 class="sec-h">What you can unlock</h2>` and a `.list` with values "10", "15" and "30" (coin icon, `chev:false`).
- Premium cross-sell: a `.list` row with `I.gift`, "Premium includes 50 coins a month" and a chevron. Delete `.pack*` and the `.note` button.

### S6 · P1 · Me / Subscription (`SC` "Subscription"): Settings-style
- Use `largeTitle('Me')`.
- Profile row: a 56px solid `--accent` avatar (white "S", `600 22px`), then the name as `.t3` with `.foot` "Day 12 · "+premiumState() under it.
- **Free:** a white `.card`: `.t3` "Try Premium free for 7 days", `.sub` "All 30 days, unlimited Mira, full analysis.", then `btn pri sm` "Try Free" (left-aligned, auto width).
- **Premium:** `<h2 class="sec-h">Subscription</h2>` and a `.list` with these rows:
  - "Plan" with value "Yearly · Free trial", "Yearly" or "Monthly"
  - "Renews", or "Ends" if cancelled, with the date value
  - monthly users only: "Switch to Yearly" with `--success` value "Save 68%"
  - "Manage Subscription" (chevron, toast "Opens Settings › Subscriptions")
  - "Cancel Subscription" with label colour `--danger` and no chevron
- Then `<h2 class="sec-h">Account</h2>` and a `.list` with "Coins" (value count), "Restore Purchases", and for premium users "Your Trial Progress".
- Delete the gradient premium card and the stand-alone `btn txt` cancel.

### S7 · P1 · Trial status (`SC` "Trial status")
- `nb:()=>bar('Your Trial',{back:1})`.
- Ring card: the stroke is solid `--accent` with track `--fill`, stroke-width 8. The center number is `.num` at 40px; caption "days left". To the right: `.hl` "Free until Nov 24" and `.sub` "Then $49.99/year. Cancel anytime before."
- `<h2 class="sec-h">So far</h2>`, then one white card with 3 columns separated by 0.5px `--sep`. Numbers are `700 28px/34px var(--sans)` in `--ink`, tabular (not serif, not accent). Labels are `.foot`: "Talks with Mira", "Texts not sent", "Days done".
- "Next up" card: no Lumi. `.hl` "Next up: Rebuild" and `.sub` "Days 8–30 rebuild self-worth and routines. This is where most people feel the shift."
- Dock: `btn pri data-tab="Home"` "Back to Today" and `btn txt data-to="Subscription"` "Manage Subscription". `ACT.keep` becomes unused, so remove it from the markup.

### S8 · P1 · Welcome (`SC` "Welcome")
- Hero: `stage(lumi({e:['happy'],m:'big',wave:1},170),200,180)` wrapped in `<div class="win">` (M5). No glow, crown or confetti.
- Title: `.display` "You’re all set, Selin." Sub, trial: "Everything’s open. We’ll remind you on Nov 22, two days before your trial ends." Paid: "Everything’s open. Take it one day at a time."
- `.list` with 4 rows (`chev:false`). The icon is a bare `--success` check (not a filled square): "All 30 days", "Unlimited Mira", "Full relationship analysis", "+50 coins added".
- Remove the bell `.note` (now in the sub).
- Dock: "Start Day 3" and `.fine` "Manage anytime in Me › Subscription".

### S9 · P1 · SOS (`SC` "SOS")
- Modal (N5) with `bar('',{close:1})`. Title `.display` centered, 44px: "Pause. Breathe."
- Stage: delete `.ring` and its pulses, and keep `.breath` (8s) on Lumi with eyes closed. Add a synced cue under it:
```html
<p class="cue" aria-hidden="true"><span>Breathe in</span><span>Breathe out</span></p>
```
```css
.cue{position:relative;height:22px;margin:0;font:600 17px/22px var(--sans);color:var(--ink-2);text-align:center}
.cue span{position:absolute;inset:0;animation:cue 8s ease-in-out infinite}.cue span+span{animation-delay:-4s}
@keyframes cue{0%,45%{opacity:1}50%,95%{opacity:0}100%{opacity:1}}
```
- Body (17/22, `--ink`, centered): "You’ve gone 12 days without reaching out. Let’s get through the next ten minutes together."
- Buttons: `btn pri` "Talk to Mira", `btn gl` "Write It in Draft Jail" (with `I.pen`), `btn txt` in `--danger` "I Need Urgent Help". Footnote: "SOS is always free."

### S10 · P1 · Sheets copy and structure
- **`limitSheet`:** header row with `mira(44)`, then `.t2` "Mira’s still here." and `.sub` "You’ve used tonight’s 3 free messages."
  - `btn pri` "Keep Talking with Premium", with `.foot` centered under it: "Includes a 7-day free trial."
  - `btn gl` "20 More Messages for 10 Coins" (if `can`), otherwise "Get Coins".
  - `btn txt` "Wait Until 9 AM".
  - Last line is a plain footnote link button: "Struggling right now? SOS is always free." (`--accent-ink`, `min-height:44px`, no `.note` pill).
- **`lockDaySheet`:** `.foot` "Day "+d+" · 5 min · Self-worth", then `.t2` "Let go of the photos, without losing the memories.", then `.sub` "Free covers Days 1–3. Premium opens all 30, plus the Rebuild stage."
  - `btn pri` "Unlock All 30 Days" with a `.foot` "7 days free" under it.
  - `btn gl` "Unlock Day "+d+" for 15 Coins".
- **`cancelSheet`:** `.t2` "Mind sharing why?" and `.sub` "It helps us improve MyEx." Replace the chips with a `.list` of 4 radio rows. Each row has a trailing `I.check` in `--accent` when selected, `role="radio"` and `aria-checked`. The row labels are in the copy table (section 7). Answers render below (restyle to plain `.card`; the "better" answer has no Lumi crown). Last button: `btn txt` in `--danger` "Continue to Cancel". This relies on the in-place `sheet()` update (N4), so the sheet no longer re-slides on each tap.
- **`crisisSheet`:** `.t2` "You don’t have to handle this alone.", `.sub` "If you might hurt yourself, please reach a real person now.", `btn pri` with `--danger` background "Call Emergency Services", `btn gl` "Call a Helpline", `btn txt` "Cancel".

### S11 · P1 · Win-back (`SC` "Win-back")
- `stage(lumi({e:['open'],m:'smile',x:['sprout']},160),190,170)` (no wave). Then `.display` "Lumi kept your place." and `.sub` "Your 21-day streak, 14 journal entries and your plan are all still here."
- Offer `.card` (no accent border) with three lines:
  - `.foot` in `--accent-ink`: "Returning member offer"
  - price `700 34px/41px var(--sans)` tabular
  - `.sub` "for 3 months, then $12.99/month"
- Dock: `btn pri` "Continue My Plan", `.fine` "$9.99 for 3 months, then $12.99/month. Cancel anytime.", `btn txt` "Stay on Free".

---

## 5. Motion spec

### M0 · P0 · Tokens and how they map to iOS
| Token | iOS reference | Use |
|---|---|---|
| `--ease-smooth`, 500ms | SwiftUI `.smooth` (response 0.5, damping 1.0); also used by UIKit push | push/pop, modal, sheet in, background scale, tab-bar hide, timeline collapse |
| `--ease-snappy`, 450ms | `.snappy` (response 0.4, damping 0.8, about 1.5% overshoot) | tab capsule, plan highlight, switch knob, button release, toast, number roll |
| `--ease-bouncy`, 650ms | `.bouncy` (response 0.45, damping 0.55, about 12% overshoot) | success moments only: radio check, purchase check, Welcome Lumi |
| `--ease-out`, 80ms | touch-down | press-in, cell highlight |
| `--ease-in`, 300ms | dismiss | sheet out, modal dismiss |

The `linear()` stops in F1 were sampled from the analytic damped-spring solution. Delete `--spring` (`cubic-bezier(.34,1.56,.64,1)`) and `--ease`, and replace every use:
- `.btn`, `.gbtn`, `.plan`, `.pack`, `.tile`, `.tabbar button`: snappy
- `.sw::after`: snappy
- `.toast`: snappy
- `.okc` pop: bouncy

### M1 · P0 · Press feedback, fast in and slower out
The pattern is the one in F6: touch-down uses `transition: transform .08s var(--ease-out)` and release uses `.35s var(--ease-snappy)`.
- Filled buttons, rows and the hero scale to **0.97** (rows don't scale; they highlight with `--fill`).
- **Glass controls swell instead of shrinking** (iOS 26 interactive glass): `.gbtn:active,.chip.gl:active,.sosb:active{transform:scale(1.06)}`, and add `.gl:active::after{opacity:1}` to brighten the specular edge.
- Remove the current `.gbtn:active{scale(.9)}` and `.tile:active{scale(.96)}`.

### M2 · P1 · Number roll for coins (only when the value changes)
Delete the count-up from 0 on every page entry (`countUp` with `anim`). The streak "12" and the trial stats are static. Use a digit roll only when the coin balance changes (purchase or spend), on `[data-count]` inside the coin chip and on the Coins balance:
```js
function roll(el,from,to){if(RM.matches||from===to){el.textContent=to;return;}const t=String(to),f=String(from).padStart(t.length,'0').slice(-t.length);
 el.setAttribute('aria-label',t);el.innerHTML=[...t].map((d,i)=>'<span class="dg" aria-hidden="true"><span class="dgs" style="--d:'+f[i]+';--k:'+(t.length-1-i)+'">'+'0123456789'.split('').map(n=>'<span>'+n+'</span>').join('')+'</span></span>').join('');
 requestAnimationFrame(()=>requestAnimationFrame(()=>el.querySelectorAll('.dgs').forEach((x,i)=>x.style.setProperty('--d',t[i]))));}
function countUp(anim,from){if(from===undefined)return;view.querySelectorAll('.page:not(.leaving) [data-count]').forEach(el=>roll(el,from,+el.dataset.count));}
```
```css
.dg{display:inline-block;height:1em;line-height:1;overflow:hidden;vertical-align:-.1em}
.dgs{display:flex;flex-direction:column;transform:translateY(calc(var(--d)*-1em));transition:transform .6s var(--ease-snappy);transition-delay:calc(var(--k)*40ms)}
.dgs span{height:1em;display:block}
```
Spending coins needs `from` too. Pass it: in `spend()`, capture `const was=s.coins` and call `render(false,was)` from `ok()`, or call `roll()` directly.

### M3 · P1 · Haptic helper (real haptics on iOS 18+ Safari) and the success pattern
```js
const hapEl=(()=>{const l=document.createElement('label');l.setAttribute('aria-hidden','true');l.style.cssText='position:fixed;width:1px;height:1px;opacity:0;pointer-events:none;overflow:hidden';
 l.innerHTML='<input type="checkbox" switch tabindex="-1">';document.body.appendChild(l);return l;})();
function haptic(n){n=n||1;for(let k=0;k<n;k++)setTimeout(()=>{try{hapEl.click();}catch(e){}},k*90);if(navigator.vibrate)navigator.vibrate(n>1?[10,60,10]:8);}
```
Toggling a native `switch` checkbox makes iOS 18+ Safari fire a selection haptic. Call it on: tab change (in `syncTabs` when the index changes), `ACT.pick`, `ACT.remind`, cancel-reason select, and purchase "Done" with `haptic(2)` (the success pattern). Never call it on scroll or page load.

### M4 · P1 · Toast as a Dynamic Island HUD (`.toast`, `toast()`)
```css
.toast{position:absolute;top:11px;left:50%;transform:translateX(-50%);z-index:50;height:37px;min-width:126px;padding:0 18px;border-radius:19px;background:#0B0A10;color:#fff;
 font:600 15px/20px var(--sans);display:flex;gap:var(--s2);align-items:center;justify-content:center;white-space:nowrap;pointer-events:none;
 clip-path:inset(0 calc(50% - 63px) round 19px);opacity:0;transition:clip-path var(--d-snappy) var(--ease-snappy),opacity .12s}
.toast.show{clip-path:inset(0 0 round 19px);opacity:1}
.toast svg{color:#34C759;width:18px;height:18px}
```
Remove the `gl` class from `#toast`. It grows out of the island and shrinks back into it. In the mobile layout (island hidden) it still reads well.

### M5 · P1 · Welcome success sequence (replaces the confetti)
```css
.win{animation:winIn var(--d-bouncy) var(--ease-bouncy) both}
@keyframes winIn{from{transform:scale(.7);opacity:0}}
.win::before{content:"";position:absolute;inset:-10%;border-radius:50%;background:radial-gradient(closest-side,rgba(255,140,175,.45),transparent);animation:glow 1.1s var(--ease-out) both}
@keyframes glow{0%{opacity:0;transform:scale(.6)}40%{opacity:1}100%{opacity:0;transform:scale(1.2)}}
.page.in-fwd .welcome-list .row-i{animation:fadeIn .3s var(--ease-out) both}
.welcome-list .row-i:nth-child(2){animation-delay:.06s}.welcome-list .row-i:nth-child(3){animation-delay:.12s}.welcome-list .row-i:nth-child(4){animation-delay:.18s}
```
Make `.win` `position:relative`. In `apply()`, after `go('Welcome')`, call `haptic(2)`. This is the **only** staggered entrance in the app.

### M6 · P1 · Remove the gimmicky loops
| Element | Action |
|---|---|
| `.float` bob on every `stage()` | delete the class from `stage()` (Lumi holds still; see L3 for the blink) |
| `.ring` pulses on SOS | delete |
| `.blobs` drift | deleted in A6 |
| `.sidehint` slide | keep (system behaviour), slow it to 1.6s |
| `.typing` dots | keep |
| `.breath` | keep (functional) |
| `@keyframes tIn` scale .985 | deleted in N3 |

### M7 · P0 · Reduced motion: replace the global kill switch with intent
Replace the current `@media (prefers-reduced-motion:reduce){*,*::before,*::after{…}}` with:
```css
@media (prefers-reduced-motion:reduce){
 .page[class*="in-"],.page[class*="out-"]{animation:fadeIn .2s linear both!important;transform:none!important}
 .page[class*="out-"]{animation-name:fadeOut!important}
 .page[class*="-"]::after{display:none}
 .sheet,.sk{animation:fadeIn .2s linear both}
 .phone.presenting #view{transform:none;border-radius:54px}
 .tcap,.plan-hl,.sw::after,.toast,.dgs,.tabbar,.sosb{transition-duration:0s!important}
 .btn:active,.plan:active,.hero:active{transform:none}
 .win,.win::before,.okc,.plan.on .rad svg{animation:none!important;transition:none!important}
 .breath{animation:none}.cue span{animation:none}.cue span+span{display:none}
 .typing i{animation:none;opacity:.6}
 .sidehint{animation:none}
}
```
Push/pop becomes a crossfade (as iOS does under Reduce Motion), and crossfades and colour changes are kept. In `render`, `d='fade'` already handles the JS side (N3).

### M8 · P2 · Extras
- **Tab capsule squish:** `.tcap.moving{animation:squish .45s var(--ease-smooth)}` with `@keyframes squish{40%{scale:1.12 .94}}`. It uses the individual `scale` property, so it composes with the `transform` translate.
- **Sheet drag to dismiss:** handle `pointerdown`/`move`/`up` on `.sheet`'s top 40px. Translate with the finger (with 0.5 rubber-band upward). Dismiss when dy > 120 or velocity > 0.8 px/ms; otherwise snap back with `--ease-snappy`.
- **Selected tab icon filled:** `.tabbar button.on svg.i{fill:currentColor;fill-opacity:.18}`.

---

## 6. Mascot: Lumi and Mira

### L1 · P0 · Lumi usage map
| Screen | Lumi | Why |
|---|---|---|
| Plan ready | ✓ happy, waving, 170px, no extras | first warm hello |
| SOS | ✓ eyes closed, breathing, 180px | the most meaningful use: Lumi breathes with you |
| Welcome | ✓ waving, bouncy entrance, no confetti or crown | the celebration |
| Win-back | ✓ with sprout | growth and continuity ("kept your place") |
| App icon (StoreKit, notification) | ✓ white variant on `--hero` | it is the app icon |
| Paywall | ✗ remove (crown Lumi) | selling with the mascot feels manipulative; the plan strip carries meaning |
| Home hero | ✗ remove peeking Lumi | the number is the hero |
| Trial status | ✗ remove sprout Lumi | utility screen |
| Exit offer | ✗ remove flower Lumi | no emotional leverage on a discount |
| Cancel "better" | ✗ remove crown Lumi | plain warm copy is enough |

Delete `XT.crown`, `XT.confetti` and `XT.flower` (no longer used). Remove the `glow` option usage, or keep the function but stop passing `glow:1`.

### L2 · P1 · Mira becomes a faceless orb
Two faces compete with each other. Mira should read as presence (a Siri-like light), not a second character. In `mira()`, delete the `<g … stroke="#fff">` face paths. Refine the gradient: `#FFE3EC` at 0, `#F06A95` at .5, `#B3134F` at 1. Add a soft inner rim with `<circle r="93" fill="none" stroke="rgba(255,255,255,.35)" stroke-width="2"/>`. Mira appears only in: the Coach header, the `limitSheet` header and the Analysis footnote. Remove it from Home (it now uses `I.chat` in a square).
Optional P2: while `s.typing`, add a class to the Coach header orb, `.mira-think{animation:think 1.6s ease-in-out infinite}@keyframes think{50%{filter:brightness(1.12) saturate(1.1)}}` (disable under reduced motion).

### L3 · P2 · Lumi blink instead of the bob
In `eye()`, add `class="lb"` to the open-eye ellipse and the highlight circle:
```css
.lb{transform-box:fill-box;transform-origin:center;animation:blink 5.5s infinite}
@keyframes blink{0%,94%,100%{transform:scaleY(1)}96%{transform:scaleY(.1)}}
```
Turn this off under reduced motion.

---

## 7. Microcopy: exact replacements

| Screen / function | Before | After |
|---|---|---|
| Plan ready eyebrow | Made for you, Selin | *(remove)* |
| Plan ready title | Your plan is *ready.* | Your plan is ready. |
| Plan ready sub | *(none)* | Built from your answers. It starts small, tonight. |
| Plan ready rows | Breakup type / Attachment style / Focus / First win · "Day 1 · 4 minutes" | What happened: They ended it / Attachment style: Anxious / Focus: No contact, self-worth / First step: Tonight · 4 min |
| Plan ready note | Built on CBT and attachment research. Private by default. | Grounded in CBT and attachment research. Private by default. |
| Plan ready CTA | See my 30-day plan | Continue |
| Paywall title | “They left me”, healed in 30 days. | 30 days to feel like you again. *(no health claim; balanced 2-line wrap)* |
| Paywall sub | *(none)* | Your full plan, and Mira whenever it gets hard. |
| Paywall benefit 1 | Mira, every night / Unlimited talks, even at 2am | Talk to Mira anytime / No nightly message limit |
| Paywall benefit 2 | All 30 days + Rebuild stage / Free plan stops at Day 3 | All 30 days of your plan / Free stops after Day 3 |
| Paywall benefit 3 | Full relationship analysis / See the patterns you missed | Your full analysis / All three patterns, not just one |
| Paywall plan 1 | Annual / $49.99 per year / $0.96 per week | Yearly · Save 68% / 7 days free · $4.17/month / **$49.99** per year |
| Paywall plan 2 | Monthly / No free trial / $12.99 per month | Monthly / No free trial / **$12.99** per month |
| Timeline 1 | Today: Everything unlocks. You pay nothing. | Today: Full access. No charge. |
| Timeline 2 | Nov 22: We remind you 2 days before it ends. | Nov 22: We’ll send you a reminder. *(switch inline)* |
| Timeline 3 | Nov 24: Trial ends. $49.99/year, unless you cancel before. | Nov 24: Your plan starts at $49.99/year. Cancel before then and you won’t be charged. |
| Paywall reminder card | Remind me before my trial ends | *(merged into Timeline 2)* |
| Paywall note | Cancel in 2 taps in Settings. Your story never leaves your phone without your OK. | Your conversations stay private. |
| Paywall CTA | Start my 7 free days / Subscribe for $12.99/month | Start Free Trial / Subscribe |
| Paywall fine | Free for 7 days, then $49.99/year. Cancel anytime. | 7 days free, then $49.99/year. Cancel anytime in Settings. |
| Paywall links | Restore · Terms · Privacy (underlined) | Terms of Use · Privacy Policy (Restore lives top-right) |
| Exit offer | Before you go / Your first year, *half price.* / …That’s $0.48 a week. We only show this once. / Claim 50% off / Continue with the free plan | Your first year, half price. / $24.99 for your first year, then $49.99/year. Cancel anytime. / Try a Year for $24.99 / Not Now |
| Welcome eyebrow | Free trial started / Premium unlocked | *(remove)* |
| Welcome title | Welcome in, *Selin.* | You’re all set, Selin. |
| Welcome sub | Everything is open. Lumi is proud of you for choosing yourself. | Everything’s open. We’ll remind you on Nov 22, two days before your trial ends. *(paid: “Everything’s open. Take it one day at a time.”)* |
| Welcome list | All 30 days + Rebuild stage / Unlimited talks with Mira / Full relationship analysis / 50 bonus coins added | All 30 days / Unlimited Mira / Full relationship analysis / +50 coins added |
| Welcome fine | Manage anytime in Me → Subscription | Manage anytime in Me › Subscription |
| Home header | Good evening / Selin + Premium chip | Large title “Today”, subtitle “Good evening, Selin” |
| Home hero | No-contact streak / 12 days / 2 days to your next badge | No contact / 12 days / 2 more days to two weeks |
| Home rows | Today · 5 min / 3 things you don’t miss · Mira quote · 1 of 3 insights free / 2 locked | Three things you don’t miss (Day 3 · 5 min) · Talk to Mira (2 free messages left tonight) · Your analysis (1 of 3 insights unlocked) |
| Home SOS | SOS · Always free / I want to text my ex / Pause first | About to text them? / Pause first. SOS is always free. |
| Home upsell | Day 4 unlocks with Premium / Keep your plan going / 7 days free | Day 4 is part of Premium · Try free |
| Home trial | Free trial / 5 days left / See what you did | Free trial: 5 days left / See your progress |
| Plan title | Your *30 days* | Your 30 Days (large title), subtitle “Day 3 of 30” |
| Plan rows | Day 3 · 3 things… / Today · 5 min / Premium + Unlock tag | Three things you don’t miss / Day 3 · Today · 5 min / Day 4 · Premium |
| Coach header | Mira / ● Here for you / Private | Mira *(centered avatar)* |
| Coach meter | 2 free messages left tonight · Unlimited | 2 free messages left tonight · Get More |
| Coach SOS meter | SOS mode · free, no limits | SOS mode · no limits |
| Coach placeholder | Message Mira… | Message Mira |
| Limit sheet | Mira is still *here.* / …Pick what works for you: / Talk without limits + Premium · 7 days free / 20 more messages · 10 coins / I’ll wait until tomorrow, 9:00 / Struggling right now? SOS and helplines are always free. | Mira’s still here. / You’ve used tonight’s 3 free messages. / Keep Talking with Premium *(foot: Includes a 7-day free trial.)* / 20 More Messages for 10 Coins / Wait Until 9 AM / Struggling right now? SOS is always free. |
| Lock-day sheet | This day helps you *let go* of the photos, without deleting the memories. / Unlock all 30 days + 7 days free / Unlock Day 4 only · 15 | Let go of the photos, without losing the memories. / Unlock All 30 Days *(foot: 7 days free)* / Unlock Day 4 for 15 Coins |
| SOS | Always free · no limits / Pause. *Breathe.* / You’ve been strong for 12 days… / Talk to Mira now / Write it in Draft Jail instead / I need urgent help | *(footnote)* SOS is always free. / Pause. Breathe. / You’ve gone 12 days without reaching out. Let’s get through the next ten minutes together. / Talk to Mira / Write It in Draft Jail / I Need Urgent Help |
| Crisis sheet | You matter. *Help is here.* / Call emergency services / Helpline · [LOCAL NUMBER] / Back | You don’t have to handle this alone. / Call Emergency Services / Call a Helpline / Cancel |
| Analysis | Your analysis + 1 of 3 tag / Communication balance / Patterns we noticed / 2 insights + flags hidden / The pattern behind insight 2 is the one most people say “changed everything”. / Unlock everything · 7 days free / Unlock this analysis · 30 | Analysis / Who reached out first / Patterns / 2 more patterns / Two more patterns are ready when you are. / Try Premium Free / Unlock for 30 Coins |
| Coins | Your balance / Popular / Best value / What coins unlock / 20 more messages with Mira / Premium members get 50 free coins every month. | coins / *(remove Popular)* / Best value · +40 bonus / What you can unlock / 20 more messages with Mira / Premium includes 50 coins a month |
| Notification | MyEx / Your free trial ends in 2 days / You had 13 talks with Mira and kept 2 texts from being sent. Keep going, or cancel anytime. No surprises. | *(icon only)* / Your trial ends in 2 days / 13 talks with Mira and 2 unsent texts so far. If it’s not for you, cancel anytime in Settings. |
| Trial status | Your trial / Then $49.99/year, just $0.96 a week. / What you did with Premium / TALKS WITH MIRA… / Next up: Rebuild stage / Keep my plan | Your Trial / Then $49.99/year. Cancel anytime before. / So far / Talks with Mira · Texts not sent · Days done / Next up: Rebuild / Back to Today |
| Me | Get Premium / 7 days free / All 30 days, unlimited Mira, full analysis. / PREMIUM / Annual · free trial / Cancel subscription | Try Premium free for 7 days / All 30 days, unlimited Mira, full analysis. / Try Free · *(premium list)* Plan: Yearly · Free trial / Manage Subscription / Cancel Subscription |
| Cancel sheet | Before you go, *what’s the reason?* / Too expensive / I feel better now / I’m not using it / Something else / Continue to cancel | Mind sharing why? / It’s too expensive / I’m feeling better / I’m not using it / Something else / Continue to Cancel |
| Cancel answers | Stay for $24.99 for the next year / Keep Premium for less · That’s the whole point. … · Want a gentle nightly check-in? … Most people who turn it on use MyEx 3× more. | Stay for $24.99 for a year / Keep Premium for Less · That’s the whole point. Your streak, journal and SOS stay free. Come back anytime. · Want a short check-in each night? One message from Mira at 10 PM. / Turn On Check-ins *(drop the unverified “3× more” claim)* |
| Win-back | It’s been 14 days / Lumi kept your *place.* / Welcome-back offer / Come back to my plan / Continue with the free plan | *(remove)* / Lumi kept your place. / Returning member offer / Continue My Plan / Stay on Free |
| Toasts | Day 3 done. Proud of you. / You’re all set. Lumi is happy. / Locked in Draft Jail for 24 hours / Not enough coins yet / 20 more messages with Mira | Day 3 complete / *(remove)* / Saved. It stays unsent for 24 hours. / You need a few more coins / 20 messages added |
| StoreKit | App Store / Cancel / MyEx · Health & Fitness / Confirm with Side Button / Prototype: tap to simulate… / Double-click to pay / Processing… | *(no title)* glass ✕ / MyEx: Breakup Recovery · Subscription / Confirm with Side Button / *(remove prototype line; keep tap)* / Double Click to Pay / *(spinner only)* |

Style rules: use curly apostrophes (’) everywhere, Title Case on buttons, sentence case everywhere else, no exclamation marks, no "just", "magic", "journey" or "healed", and no claims about outcomes or other users' behaviour.

---

## 8. Small but visible fixes

| ID | Pri | Target | Change |
|---|---|---|---|
| X1 | P0 | `.scr` | side padding 20 → 16, section gap 16 → 24 (F-grid); `.col` gap 10 → 8 or 12 |
| X2 | P0 | `coinChip()` | `.chip.gl.coin`: `min-height:36px` visual with a 44 hit (`::before inset:-4px`), `font:600 15px/20px`, tabular numerals, coin icon 18 |
| X3 | P1 | `.note`, `.note.m` | delete as a component. Replace remaining uses with `.foot` text (plus an optional 16px glyph). Coloured info pills are a tell. |
| X4 | P1 | `.bar` | height 8 → 4, radius 2, solid accent |
| X5 | P1 | `.lockwrap .ov` | background `linear-gradient(180deg,rgba(255,255,255,0),rgba(255,255,255,.85))`, text `600 15px` `--accent-ink`, blur 6 → 5px |
| X6 | P1 | `.sbar b` | `font:600 17px/22px -apple-system,"SF Pro Text","Inter"`; padding to `14px 32px 0 48px` so the time centers in the left ear |
| X7 | P1 | Coach `pad:'chat'` | `.composer{bottom:96px}` stays above the persistent tab bar; check it after N1 |
| X8 | P2 | side panel `.side h1` | "Turn care into *conversion.*" becomes "MyEx monetization flow", plain serif, no italic (presentation chrome only) |
| X9 | P2 | `meta theme-color` | `#FFF5F7` |

---

## 9. Implementation notes and pitfalls

1. **`render(false)` callers** (remind, pick, task, spend*, reason) should update in place where specified (pick, remind, reason). Everything else uses the new scroll-preserving `render(false)` (N3).
2. With two `.page` elements alive during a transition, all `view.querySelector(...)` calls in `render`, `countUp` and the Coach autoscroll must target the new page (`pg`, or `.page:not(.leaving)`).
3. The click delegate calls `closeOv()` before every `data-to`/`data-tab`. With the animated close, this is safe because of the `ovTok` guard and the "not open, return" guard. `ACT.buy` calls `closeOv()` then `store()` immediately, and `openOv` bumps `ovTok`, which cancels the pending cleanup.
4. Keep the mobile layout (`@media(max-width:500px)`). Add `.page .nb{top:env(safe-area-inset-top)}` and `.scr.has-nb{padding-top:calc(52px + env(safe-area-inset-top))}` there.
5. `prefers-reduced-transparency`: extend the existing rule to `.sheet,.tabbar,.sosb,.notif,.inp,.meter{background:#fff;backdrop-filter:none}`.

---

## 10. Top-10 by impact

1. **AI-tell purge** (A1–A8): gradient italic `<em>`, eyebrows, floating hearts, heart burst, confetti, drifting blobs, stagger, crowns and gold.
2. **Token reset** (F1, F3, F4, F6): one accent, wine neutrals, flat white cards, solid buttons, a type scale with weights 400/600/700, and the 4/8 grid.
3. **Persistent iOS 26 tab bar with a sliding glass capsule** (N1).
4. **Real push/pop with 30% parallax and dimming**, plus scroll position preserved (N3).
5. **Sheets that scale the app to 0.94**, dismiss with animation and update in place (N4).
6. **Paywall rebuild** (P1–P3): honest price hierarchy (no per-week anchor), 3 benefits, plan strip instead of a crowned mascot, and a sliding plan highlight that morphs in place.
7. **Large titles that collapse into inline titles** with the scroll-edge effect, and grouped inset lists (N2, F5).
8. **Home without the bento**: one gradient hero numeral plus a grouped list (H1).
9. **Native system surfaces**: StoreKit sheet, lock-screen notification, UISwitch and the Dynamic Island toast (N6–N8, M4).
10. **Copy and mascot discipline**: the section 7 table, Lumi on 4 screens only, Mira as a faceless orb (L1, L2).

## 11. Apply order (one pass)
1. Tokens and fonts: F1–F3.
2. Purge: A1–A13.
3. Surfaces: F4–F7.
4. Navigation and render: N3, then N1, N2, N4 and N5.
5. Screens: H1, P1–P5, S1–S11.
6. System surfaces: N6–N9.
7. Motion: M1–M7.
8. Mascot: L1–L3.
9. Copy: section 7.
10. Small fixes: section 8.
11. P2 extras: N10, N11, M8, L3.

---

## 12. Applied (status)
Applied to `MyEx_Glass_Premium.html` on 2026-11-17, keeping QA's fixes (overflow:clip, `periodLeft()`, `DAYS`, Coach input preservation, in-place cancel sheet). Playwright suite `scratchpad/qa/test.js`: 136 PASS, 0 FAIL, 0 console errors. Selectors updated for the headline, pick, coin roll, Me screen and no-confetti checks. Deviations from the plan: the sheet drag-to-dismiss (M8) and `corner-shape` (N10) were not implemented.

## 13. Final design tokens (for Flutter `lib/core/design/`)

### Color
| Token | Value | Use |
|---|---|---|
| bg | #FFF5F7 | grouped page background |
| bgElev | #FFFFFF | cells, cards, bubbles |
| pageGlow | radial 90%×45% at top-right, rgba(255,120,160,.16) → transparent, over bg | page background |
| ink | #3A0F22 | primary label (≈15:1) |
| ink2 | #86506A | secondary label (5.8:1 on bg) |
| ink3 | rgba(58,15,34,.30) | chevrons, placeholders (never text) |
| sep | rgba(58,15,34,.12) | 0.5pt hairlines |
| fill | rgba(58,15,34,.06) | pressed cells, tracks |
| accent | #D81B60 | fills, icons, ≥17pt semibold text (4.94:1 on white) |
| accentInk | #B0124F | small accent text, links (6.9:1) |
| accentSoft | rgba(216,27,96,.10) | tinted fills (text on it uses accentInk) |
| success | #0B7A55 | (5.4:1) ; successSoft rgba(11,122,85,.10) |
| danger | #D70015 | (5.4:1) |
| switchOn | #34C759 | switches only |
| hero gradient | linear 160° #B3134F → #D81B60 + radial highlight rgba(255,150,180,.45) at 90%/0% | Home streak card + app icon ONLY |
| glass | rgba(255,255,255,.55), blur 14, saturate 180%, 0.5pt white rim, shadow 0 8 24 rgba(58,15,34,.10) | floating chrome only |
| scrim | rgba(20,4,12,.22) sheet backdrop; push dim #14040C @ 12% | |

### Type (iOS Dynamic Type “Large”; SF Pro on device, Inter opsz fallback; letter-spacing normal)
| Role | Size/Line | Weight |
|---|---|---|
| largeTitle | 34/41 | 700 |
| title1 | 28/34 | 700 |
| title2 | 22/28 | 700 |
| title3 / section header | 20/25 | 600 |
| headline | 17/22 | 600 |
| body | 17/22 | 400 |
| callout | 16/21 | 400 |
| subheadline | 15/20 | 400 |
| footnote | 13/18 | 400 |
| caption1 | 12/16 | 400 |
| caption2 (tab labels) | 10/12 | 600 |
| display (Instrument Serif, upright) | 40/44, tracking −0.02em | 400; one per emotional screen |
| numeral (Instrument Serif) | 40–96, line 0.9, tracking −0.03em, tabular | 400 |
Buttons: 17/22 w600, Title Case. Max weight 700, no 500/800.

### Radii
xs 8 (icon squares) · s 12 · m 16 (StoreKit boxes) · l 22 (lists, cards, plan picker) · xl 28 (hero) · sheet 38 · capsule 999. Plan row inner 18, tab capsule 27, notification 24, app icon = 22.5% of size.

### Spacing (4/8 grid)
4 · 8 · 12 · 16 · 20 · 24 · 32. Screen margin 16; section gap 24; title→content 8; card padding 16; row padding 11v/16h, min height 44; separator inset 16 (58 with leading icon); hit targets ≥44.
Chrome: status bar 54; nav bar 52 (content starts at 106); tab bar 62 tall, insets 20 (left/bottom), right edge 92 to leave a 62pt SOS circle; primary button 52; dock bottom padding 30.

### Motion
| Name | Spring (SwiftUI equivalent) | CSS | Duration | Use |
|---|---|---|---|---|
| smooth | response 0.5, damping 1.0 (`.smooth`) | linear(0,.041 5%,.133 10%,.246 15%,.363 20%,.473 25%,.570 30%,.654 35%,.725 40%,.833 50%,.903 60%,.947 70%,.974 80%,.991 90%,1) | 500ms | push/pop, modal, sheet in, background scale, tab-bar hide, timeline collapse |
| snappy | response 0.4, damping 0.8 (`.snappy`, about 1.5% overshoot) | linear(0,.062 5%,.202 10%,.367 15%,.526 20%,.664 25%,.776 30%,.861 35%,.922 40%,.990 50%,1.012 60%,1.015 70%,1.010 80%,1.006 90%,1) | 450ms | tab capsule, plan highlight, switch knob, button release, island toast, digit roll (600ms) |
| bouncy | response 0.45, damping 0.55 (about 12% overshoot) | linear(0,.099 5%,.320 10%,.571 15%,.796 20%,.965 25%,1.069 30%,1.118 35%,1.125 40%,1.106 45%,1.076 50%,1.018 60%,.989 70%,.985 80%,.992 90%,1) | 650ms | success only: radio check, purchase check, Welcome Lumi |
| pressIn | easeOut (0,0,.58,1) | | 80ms | scale 0.97 (filled), 1.06 (glass), cell highlight |
| dismiss | easeIn (.42,0,1,1) | | 300ms | sheet out |
| tabFade | easeOut | | 180ms | tab crossfade |
Patterns:
- Push: incoming page x 100%→0; outgoing page x 0→−30% with a 12% dim.
- Pop: the reverse.
- Modal: y 100%→0.
- Sheet: the page behind goes to scale 0.94, y +14, radius 38, and the status bar turns white. The StoreKit sheet dims only.
- Haptics: selection on tab, plan and switch changes; double tap on purchase success.
- Reduced motion: slides become a 200ms crossfade, with no bounce, no roll and no loops.
