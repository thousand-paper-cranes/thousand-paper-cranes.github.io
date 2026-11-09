import asyncio, base64
from playwright.async_api import async_playwright
APP='file:///home/claude/thousand-paper-cranes.github.io/android/app/src/main/assets/www/index.html'
FONTS='/home/claude/thousand-paper-cranes.github.io/android/app/src/main/assets/www/fonts/'
SIDE=[[[[209.78248907876946, 51.662394979505294], [150, 96.21698988940173], [137.46152107200606, 76.05665699091657]], 0.05897131364726037], [[[209.78248907876946, 51.662394979505294], [195.77419838087624, 91.60746058273467], [150, 96.21698988940173]], 0.08697131364726043], [[[126.24046908253253, 89.88080681939435], [137.46152107200606, 76.05665699091657], [150, 96.21698988940173], [150, 96.21698988940173]], 0.0709713136472604], [[[132.67837525204288, 125.75571145517841], [126.24046908253253, 89.88080681939435], [150, 96.21698988940173], [150, 96.21698988940173], [150, 126.01652244797272]], 0.15884806863198994], [[[113.84298667656782, 49.19599565873989], [132.67837525204288, 125.75571145517841], [150, 126.01652244797272], [118.9073227512811, 52.71088040107948]], 0.15884806863198989], [[[113.84298667656782, 49.19599565873989], [118.9073227512811, 52.71088040107948], [97.95471515434707, 54.80458233790896]], 0.15884806863199016], [[[157.84030843395988, 90.6547081281937], [135.5070831249884, 92.35202408441769], [150, 86.31207176352228]], 0.17207102254995443], [[[150, 126.01652244797272], [150, 96.21698988940173], [150, 96.21698988940173], [173.75953091746746, 102.5531729594091], [167.32162474795712, 134.9943606401536]], 0.33999999999999997], [[[126.24046908253253, 89.88080681939435], [104.22580161912374, 99.63563193693454], [150, 96.21698988940173], [150, 96.21698988940173]], 0.07734084972827804], [[[164.4929168750116, 100.08195569438575], [157.84030843395988, 90.6547081281937], [150, 86.31207176352228]], 0.2643612428865775], [[[150, 96.21698988940173], [150, 96.21698988940173], [195.77419838087624, 91.60746058273467], [173.75953091746746, 102.5531729594091]], 0.33999999999999997], [[[135.5070831249884, 92.35202408441769], [142.15969156604012, 101.77927165060973], [150, 86.31207176352228]], 0.01148117292704304], [[[142.15969156604012, 101.77927165060973], [164.4929168750116, 100.08195569438575], [150, 86.31207176352228]], 0.1037713932636661], [[[150, 126.01652244797272], [167.32162474795712, 134.9943606401536], [191.09252920851034, 51.05181366134739]], 0.18684806863198988], [[[150, 96.21698988940173], [150, 96.21698988940173], [162.53847892799394, 115.18643552875264], [173.75953091746746, 102.5531729594091]], 0.33999999999999997], [[[90.21751092123056, 136.4873866092052], [150, 96.21698988940173], [104.22580161912374, 99.63563193693454]], 0.06534084972827807], [[[90.21751092123056, 136.4873866092052], [162.53847892799394, 115.18643552875264], [150, 96.21698988940173]], 0.09334084972827808]]
def crane_svg(hexc='#DE4A3F'):
    r,g,b=int(hexc[1:3],16),int(hexc[3:5],16),int(hexc[5:7],16)
    ps=''
    for pts,s in SIDE:
        k=1-s; ps+=f'<path d="M{"L".join(f"{x},{y}" for x,y in pts)}Z" fill="rgb({int(r*k)},{int(g*k)},{int(b*k)})" stroke="rgba({int(r*.45)},{int(g*.45)},{int(b*.45)},.35)" stroke-width="1" stroke-linejoin="round"/>'
    return f'<svg viewBox="86 45 128 95" xmlns="http://www.w3.org/2000/svg">{ps}</svg>'
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
