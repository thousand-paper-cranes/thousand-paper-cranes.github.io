import asyncio, base64
from playwright.async_api import async_playwright
APP='file:///home/claude/thousand-paper-cranes.github.io/android/app/src/main/assets/www/index.html'
FONTS='/home/claude/thousand-paper-cranes.github.io/android/app/src/main/assets/www/fonts/'
SIDE=[([[104,192],[196,192],[214,72]],.2),([[104,192],[150,192],[150,220]],.04),([[150,192],[196,192],[150,220]],.13),([[196,192],[179.9,201.8],[266,92]],.12),([[104,192],[120.1,201.8],[54,84]],.07),([[54,84],[59,93],[30,99]],0),([[104,192],[144,58],[128,192]],.09),([[128,192],[144,58],[196,192]],0)]
def crane_svg(hexc='#DE4A3F'):
    r,g,b=int(hexc[1:3],16),int(hexc[3:5],16),int(hexc[5:7],16)
    ps=''
    for pts,s in SIDE:
        k=1-s; ps+=f'<path d="M{"L".join(f"{x},{y}" for x,y in pts)}Z" fill="rgb({int(r*k)},{int(g*k)},{int(b*k)})" stroke="rgba({int(r*.45)},{int(g*.45)},{int(b*.45)},.35)" stroke-width="1" stroke-linejoin="round"/>'
    return f'<svg viewBox="24 50 250 176" xmlns="http://www.w3.org/2000/svg">{ps}</svg>'
f64=lambda n: base64.b64encode(open(FONTS+n+'.woff2','rb').read()).decode()
NATIVE="window.Native={isDebug:()=>false,vibrate:()=>{},showRewardedAd:()=>setTimeout(()=>window.onAdResult('reward'),200)};"
async def shot(pg,name):
    await pg.evaluate("document.activeElement&&document.activeElement.blur(); window.scrollTo(0,0)")
    await pg.evaluate("document.getElementById('toast').classList.remove('show')")
    await pg.wait_for_timeout(450)
    await pg.screenshot(path=name)
async def main():
    async with async_playwright() as p:
        b=await p.chromium.launch(executable_path='/usr/bin/google-chrome')
        # ---- icon
        pg=await b.new_page(viewport={'width':512,'height':512})
        await pg.set_content(f'<body style="margin:0;width:512px;height:512px;background:#F3EEE2;display:flex;align-items:center;justify-content:center"><div style="width:400px;margin-top:-14px">{crane_svg()}</div></body>')
        await pg.screenshot(path='icon-512.png'); await pg.close()
        # ---- screenshots (1080x1920)
        ctx=await b.new_context(viewport={'width':360,'height':640},device_scale_factor=3)
        await ctx.add_init_script(NATIVE)
        pg=await ctx.new_page()
        await pg.goto(APP); await pg.wait_for_timeout(600)
        await pg.fill('#wishIn','우리 가족 모두 건강하게'); await pg.evaluate("document.activeElement.blur()")
        await pg.evaluate("document.getElementById('startBtn').disabled=false")
        await shot(pg,'shot-1-wish.png')
        await pg.click('#startBtn'); await pg.wait_for_timeout(700)
        await pg.evaluate("S.papers=['red','sky','yellow','gold','mint']; selected=0; renderHome()")
        await shot(pg,'shot-2-papers.png')
        # fold: guided step 4 mid-drag
        await pg.click('#foldBtn'); await pg.wait_for_timeout(600)
        for _ in range(3):
            await pg.focus('#stage'); await pg.keyboard.press('Enter'); await pg.wait_for_timeout(800)
        await pg.evaluate("F_.t=0.42; drawPaper()")
        await pg.wait_for_timeout(700)
        await shot(pg,'shot-3-fold.png')
        for _ in range(8):
            await pg.focus('#stage'); await pg.keyboard.press('Enter'); await pg.wait_for_timeout(800)
        await pg.wait_for_timeout(500)
        await shot(pg,'shot-4-crane.png')
        await pg.click('#putBtn'); await pg.wait_for_timeout(300)
        await pg.evaluate("for(let i=0;i<326;i++) S.cranes.push(randColor()); S.totalFolded=327; S.papers=['blue','pink','gold','lime','orange','purple','navy']; save(); renderHome()")
        await pg.wait_for_timeout(800)
        await shot(pg,'shot-5-jar.png')
        await pg.evaluate("for(let i=S.cranes.length;i<1000;i++) S.cranes.push(randColor()); save(); renderHome(); showFinale()")
        await pg.wait_for_timeout(800)
        await shot(pg,'shot-6-finale.png')
        # jar crop for feature graphic, 600-crane jar
        await pg.evaluate("document.querySelector('.finale').remove(); S.cranes=S.cranes.slice(0,520); layout=[]; renderHome()")
        await pg.wait_for_timeout(800)
        await pg.evaluate("document.documentElement.style.background='transparent';document.body.style.background='transparent';window.scrollTo(0,0)")
        jar=await pg.locator('.jarwrap').screenshot(omit_background=True)
        open('jar.png','wb').write(jar)
        await ctx.close()
        # ---- feature graphic
        pg=await b.new_page(viewport={'width':1024,'height':500})
        jb=base64.b64encode(jar).decode()
        html=f'''<style>
@font-face{{font-family:B;src:url(data:font/woff2;base64,{f64('GowunBatang-Bold')})}}
@font-face{{font-family:D;src:url(data:font/woff2;base64,{f64('GowunDodum-Regular')})}}
@font-face{{font-family:H;src:url(data:font/woff2;base64,{f64('NanumPenScript-Regular')})}}
body{{margin:0;width:1024px;height:500px;overflow:hidden;background:radial-gradient(circle at 26% 55%,#FFFFFF 0,#EEF0F4 46%,#E2E6EF 100%);position:relative;font-family:D}}
.jar{{position:absolute;left:96px;top:26px;height:452px}}
.txt{{position:absolute;left:470px;top:0;bottom:0;display:flex;flex-direction:column;justify-content:center;gap:18px;color:#22253A}}
h1{{font-family:B;font-size:78px;margin:0;letter-spacing:.01em;line-height:1}}
p{{margin:0;font-size:30px;color:#4B4F68}}
.tag{{font-family:H;font-size:40px;color:#3A3428;background:#FBF7EC;padding:6px 18px;border-radius:3px;transform:rotate(-2deg);align-self:flex-start;box-shadow:0 4px 14px rgba(0,0,0,.10);margin-top:6px}}
.c{{position:absolute;width:150px;right:58px;top:46px;transform:rotate(-6deg)}}
</style>
<img class="jar" src="data:image/png;base64,{jb}">
<div class="c">{crane_svg('#2F6ED4')}</div>
<div class="txt"><h1>천 마리 학</h1><p>소원을 적고, 종이학을 접어요</p><span class="tag">매일 색종이 5장</span></div>'''
        await pg.set_content(html); await pg.wait_for_timeout(600)
        await pg.screenshot(path='feature-1024x500.png')
        await b.close()
asyncio.run(main())
