"""design/prototype.html → android/app/src/main/assets/www/index.html
웹 프로토타입을 앱 화면으로 바꾼다: 글꼴 로컬화, 네이티브 브리지(광고·진동·뒤로 가기),
테스트 도구는 디버그 빌드에서만.  사용: python3 tools/build_app_page.py
"""
import pathlib, re
root = pathlib.Path(__file__).resolve().parent.parent
s = (root / 'design/prototype.html').read_text()

def R(a, b, count=1):
    global s
    assert s.count(a) == count, f'not found once: {a[:70]!r}'
    s = s.replace(a, b)

s = s[s.index('<style>'):]
R('<style>\n', '''<style>
@font-face{font-family:"Gowun Batang";src:url(fonts/GowunBatang-Bold.woff2) format("woff2");font-weight:400 700;font-display:swap}
@font-face{font-family:"Gowun Dodum";src:url(fonts/GowunDodum-Regular.woff2) format("woff2");font-display:swap}
@font-face{font-family:"Nanum Pen Script";src:url(fonts/NanumPenScript-Regular.woff2) format("woff2");font-display:swap}
''')
R('-webkit-tap-highlight-color:transparent}', '-webkit-tap-highlight-color:transparent;-webkit-user-select:none;user-select:none;overscroll-behavior:none}\ntextarea{-webkit-user-select:text;user-select:text}')
R('/* ---------- data ---------- */', '''/* ---------- native bridge ---------- */
const NATIVE = window.Native || null;
const IS_DEBUG = !NATIVE || (NATIVE.isDebug && NATIVE.isDebug());
function haptic(ms){ try{ if(NATIVE) NATIVE.vibrate(ms); else if(navigator.vibrate) navigator.vibrate(ms); }catch(e){} }

/* ---------- data ---------- */''')
# 테스트 도구: 디버그 빌드에서만
a = s.index('    <details class="test"'); b = s.index('</details>', a) + len('</details>')
s = s[:a] + '    ${IS_DEBUG?`' + s[a:b] + '`:\'\'}' + s[b:]
R('테스트 도구 (프로토타입 전용)', '테스트 도구 (디버그 빌드 전용)')
R("  root.querySelectorAll('.modepick button')", "  if(IS_DEBUG){\n  root.querySelectorAll('.modepick button')")
R("$('#tReset').textContent='한 번 더 누르면 모두 지워져요'; } };", "$('#tReset').textContent='한 번 더 누르면 모두 지워져요'; } };\n  }")
R("let testMode=null; try{", "let testMode=null; if(IS_DEBUG) try{")
R("if(navigator.vibrate) try{navigator.vibrate(12);}catch(e){}", "haptic(12);")
R("  S.papers.splice(idx,1); S.cranes.push(key);", "  haptic(30);\n  S.papers.splice(idx,1); S.cranes.push(key);")
# 광고
a = s.index('function showAd(){'); b = s.index('function strip(')
s = s[:a] + '''function grantAd(){ S.adDate=today(); for(let i=0;i<AD_BONUS;i++) S.papers.push(randColor()); save(); renderHome(); toast(`색종이 ${AD_BONUS}장을 더 받았어요`); }
let adBusy=false;
window.onAdResult=function(ok){
  adBusy=false; const b=$('#adBtn'); if(b){ b.disabled=false; b.textContent=`광고 보고 색종이 ${AD_BONUS}장 더 받기`; }
  if(ok==='reward') grantAd();
  else if(ok==='unavailable') toast('광고를 불러오지 못했어요. 잠시 후 다시 눌러주세요');
  else if(ok==='closed') toast('광고를 끝까지 보면 색종이를 받을 수 있어요');
};
function showAd(){
  if(S.adDate===today()||adBusy) return;
  if(NATIVE){ adBusy=true; const b=$('#adBtn'); if(b){ b.disabled=true; b.textContent='광고를 불러오는 중이에요'; } NATIVE.showRewardedAd(); return; }
  const a=document.createElement('div'); a.className='ad'; a.innerHTML=`<b>광고 영역</b><span>미리보기라 실제 광고 대신 3초 기다려요</span><span id="adc">3</span>`;
  document.body.appendChild(a); let c=3;
  const iv=setInterval(()=>{ c--; const el=$('#adc'); if(el) el.textContent=c; if(c<=0){ clearInterval(iv); a.remove(); grantAd(); } },1000);
}
''' + s[b:]
R('/* ---------- boot ---------- */', '''/* ---------- back button (called by the app) ---------- */
window.onBackPressed=function(){
  const m=document.querySelector('.modal'); if(m){ m.remove(); return true; }
  if($('#fold')){ closeFold(); return true; }
  return false;
};

/* ---------- boot ---------- */''')
R('<div id="root"></div>', '</head>\n<body>\n<div id="root"></div>')
s = '''<!doctype html>
<html lang="ko">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no, viewport-fit=cover">
<title>천 마리 학</title>
''' + s + '\n</body>\n</html>\n'
assert 'fonts.googleapis' not in s
(root / 'android/app/src/main/assets/www/index.html').write_text(s)
print('ok', len(s))
