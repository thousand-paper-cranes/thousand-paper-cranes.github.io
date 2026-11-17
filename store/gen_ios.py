import asyncio, base64
from playwright.async_api import async_playwright
APP='file:///home/claude/thousand-paper-cranes.github.io/android/app/src/main/assets/www/index.html'
SH='/home/claude/out/shots/'
FONTS='/home/claude/thousand-paper-cranes.github.io/android/app/src/main/assets/www/fonts/'
f64=lambda p: base64.b64encode(open(p,'rb').read()).decode()
NATIVE="window.Native={isDebug:()=>false,vibrate:()=>{},showRewardedAd:()=>{}};"
# iPhone 세로: 393x852pt @3x = 1179x2556, 위 59pt(다이내믹 아일랜드)·아래 34pt는 앱처럼 비워 둔다
SAFE="document.documentElement.style.setProperty('--sat','59px');"
CSS="html,body{height:auto} body{padding-top:59px!important;padding-bottom:34px!important;box-sizing:border-box;min-height:852px} .onboard{min-height:759px!important} .overlay{padding-top:71px!important;padding-bottom:50px!important}"
async def shot(pg,name):
    await pg.evaluate("document.activeElement&&document.activeElement.blur(); window.scrollTo(0,0); document.getElementById('toast').classList.remove('show')")
    await pg.wait_for_timeout(450)
    await pg.screenshot(path=name)
async def main():
    async with async_playwright() as p:
        b=await p.chromium.launch(executable_path='/usr/bin/google-chrome')
        ctx=await b.new_context(viewport={'width':393,'height':852},device_scale_factor=3)
        await ctx.add_init_script(NATIVE)
        pg=await ctx.new_page()
        await pg.goto(APP); await pg.add_style_tag(content=CSS); await pg.wait_for_timeout(600)
        await pg.fill('#wishIn','우리 가족 모두 건강하게')
        await pg.evaluate("document.getElementById('startBtn').disabled=false")
        await shot(pg,'ios-1-wish.png')
        await pg.click('#startBtn'); await pg.wait_for_timeout(700)
        await pg.evaluate("S.papers=['red','sky','yellow','gold','mint']; selected=0; renderHome()")
        await shot(pg,'ios-2-papers.png')
        await pg.click('#foldBtn'); await pg.wait_for_timeout(600)
        for _ in range(3):
            await pg.evaluate("finishStep()"); await pg.wait_for_timeout(800)
        await pg.evaluate("F_.t=0.42; drawPaper()"); await pg.wait_for_timeout(700)
        await shot(pg,'ios-3-fold.png')
        while await pg.evaluate("!F_.done"):
            await pg.evaluate("if(!F_.auto) finishStep()"); await pg.wait_for_timeout(800)
        await pg.wait_for_timeout(600)
        await shot(pg,'ios-4-crane.png')
        await pg.click('#putBtn'); await pg.wait_for_timeout(300)
        await pg.evaluate("for(let i=0;i<326;i++) S.cranes.push(randColor()); S.totalFolded=327; S.papers=['blue','pink','gold','lime','orange','purple','navy']; save(); renderHome()")
        await pg.wait_for_timeout(900)
        await shot(pg,'ios-5-jar.png')
        await pg.evaluate("for(let i=S.cranes.length;i<1000;i++) S.cranes.push(randColor()); save(); renderHome(); showFinale()")
        await pg.wait_for_timeout(900)
        await shot(pg,'ios-7-finale.png')
        await ctx.close()
        # 위젯 화면
        pg=await b.new_page(viewport={'width':393,'height':852},device_scale_factor=3)
        html=f'''<style>
@font-face{{font-family:B;src:url(data:font/woff2;base64,{f64(FONTS+'GowunBatang-Bold.woff2')})}}
@font-face{{font-family:D;src:url(data:font/woff2;base64,{f64(FONTS+'GowunDodum-Regular.woff2')})}}
body{{margin:0;width:393px;height:852px;overflow:hidden;font-family:D;color:#fff;
 background:linear-gradient(180deg,#2B3A67 0%,#6B4E8A 55%,#C97B84 100%);display:flex;flex-direction:column;align-items:center}}
h1{{font-family:B;font-size:30px;margin:92px 0 6px;letter-spacing:.01em}}
p{{margin:0 0 26px;font-size:16px;opacity:.85}}
.lock{{width:361px;display:block;margin-bottom:18px;border-radius:28px;box-shadow:0 10px 30px rgba(0,0,0,.3)}}
.row{{display:flex;gap:14px;width:361px;justify-content:space-between;align-items:flex-start}}
.s{{width:150px;border-radius:24px;box-shadow:0 8px 24px rgba(0,0,0,.25)}}
.m{{width:361px;border-radius:24px;box-shadow:0 8px 24px rgba(0,0,0,.25);margin-top:14px}}
</style>
<h1>위젯으로 매일 확인해요</h1><p>잠금 화면과 홈 화면에 소원 유리통을</p>
<img class="lock" src="data:image/png;base64,{f64(SH+'widget-lock-327.png')}">
<div class="row"><img class="s" src="data:image/png;base64,{f64(SH+'widget-small-light.png')}"><img class="s" src="data:image/png;base64,{f64(SH+'widget-small-dark.png')}"></div>
<img class="m" src="data:image/png;base64,{f64(SH+'widget-medium-light.png')}">'''
        await pg.set_content(html); await pg.wait_for_timeout(600)
        await pg.screenshot(path='ios-6-widgets.png')
        await b.close()
asyncio.run(main())
