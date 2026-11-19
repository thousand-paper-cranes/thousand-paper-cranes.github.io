import UIKit
import WebKit
import WidgetKit

/// 접기·유리통 화면(www/index.html)을 띄우고, 화면이 부르는 window.Native를 네이티브 기능에 잇는다.
///   Native.isDebug()        디버그 빌드면 화면 아래 테스트 도구가 보인다
///   Native.vibrate(ms)      햅틱
///   Native.showRewardedAd() 보상형 광고 → window.onAdResult('reward' | 'closed' | 'unavailable')
///   Native.saveState(json)  상태를 App Group에 복사 (위젯, 알림, 기록 백업)
final class WebViewController: UIViewController, WKNavigationDelegate, WKScriptMessageHandler {

    private var web: WKWebView!
    private let light = UIImpactFeedbackGenerator(style: .light)
    private let medium = UIImpactFeedbackGenerator(style: .medium)
    private var lastWidgetReload = Date.distantPast

    #if DEBUG
    private let isDebug = true
    #else
    private let isDebug = false
    #endif

    override func loadView() {
        let content = WKUserContentController()

        // localStorage가 비어 있으면(앱 재설치·기기 이전 등) App Group에 남은 기록으로 되살린다
        let backup = Shared.defaults.string(forKey: Shared.stateKey) ?? ""
        let backupLiteral = (try? String(data: JSONEncoder().encode(backup), encoding: .utf8)) ?? "\"\""
        let bridge = """
        (function(){
          var post = function(m){ try{ window.webkit.messageHandlers.native.postMessage(m); }catch(e){} };
          window.Native = {
            isDebug: function(){ return \(isDebug ? "true" : "false"); },
            vibrate: function(ms){ post({t:'vibrate', ms: ms|0}); },
            showRewardedAd: function(){ post({t:'ad'}); },
            saveState: function(json){ post({t:'state', json: String(json)}); }
          };
          try{
            var b = \(backupLiteral);
            if (b && !localStorage.getItem('\(Shared.stateKey)')) localStorage.setItem('\(Shared.stateKey)', b);
          }catch(e){}
        })();
        """
        content.addUserScript(WKUserScript(source: bridge, injectionTime: .atDocumentStart, forMainFrameOnly: true))
        content.add(WeakHandler(self), name: "native")

        let config = WKWebViewConfiguration()
        config.userContentController = content
        config.websiteDataStore = .default()
        config.allowsInlineMediaPlayback = true

        web = WKWebView(frame: .zero, configuration: config)
        web.isOpaque = false
        web.backgroundColor = .clear
        web.scrollView.backgroundColor = .clear
        web.scrollView.bounces = false
        web.scrollView.contentInsetAdjustmentBehavior = .never
        web.allowsLinkPreview = false
        web.navigationDelegate = self
        if #available(iOS 16.4, *) { web.isInspectable = isDebug }
        view = web
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if let dir = Bundle.main.url(forResource: "www", withExtension: nil) {
            web.loadFileURL(dir.appendingPathComponent("index.html"), allowingReadAccessTo: dir)
        }
        light.prepare()
        NotificationCenter.default.addObserver(self, selector: #selector(becameActive),
                                               name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    private var askedTracking = false

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // 앱이 화면에 뜨자마자 추적 허용을 먼저 묻고, 답을 받은 뒤에 광고 SDK를 시작한다.
        // (iOS는 앱이 활성 상태일 때만 이 창을 띄운다)
        guard !askedTracking else { return }
        askedTracking = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { Ads.shared.startAfterTrackingPrompt() }
    }

    @objc private func becameActive() {
        // 날짜가 바뀌었으면 화면이 visibilitychange에서 오늘의 색종이를 지급한다. 알림은 다시 예약
        Reminders.shared.reschedule(state: CraneState.load())
    }

    // MARK: 바깥 링크는 Safari로
    func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let url = action.request.url, url.scheme == "http" || url.scheme == "https" {
            UIApplication.shared.open(url)
            decisionHandler(.cancel)
            return
        }
        decisionHandler(.allow)
    }

    // 디버그 빌드 + CRANE_SELFTEST 환경 변수일 때만: 시뮬레이터에서 소원 적기 → 학 한 마리 접기 → 통에 넣기를 자동으로 해 본다
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        #if DEBUG
        guard ProcessInfo.processInfo.environment["CRANE_SELFTEST"] == "1" else { return }
        let js = """
        (async function(){
          const wait=ms=>new Promise(r=>setTimeout(r,ms));
          await wait(1000);
          const w=document.getElementById('wishIn');
          if(w){ w.value='시뮬레이터 소원 테스트'; w.dispatchEvent(new Event('input')); document.getElementById('startBtn').click(); }
          await wait(1200);
          openFold(0);
          await wait(800);
          while(F_ && !F_.done){ if(!F_.auto) finishStep(); await wait(850); }
          await wait(4000);
          putInJar();
        })();
        """
        webView.evaluateJavaScript(js, completionHandler: nil)
        #endif
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        webView.reload()
    }

    // MARK: 화면 → 네이티브
    func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let body = message.body as? [String: Any], let type = body["t"] as? String else { return }
        switch type {
        case "vibrate":
            let ms = (body["ms"] as? Int) ?? 12
            if ms >= 25 { medium.impactOccurred() } else { light.impactOccurred() }
        case "ad":
            Ads.shared.show(from: self) { [weak self] result in
                self?.web.evaluateJavaScript("window.onAdResult && window.onAdResult('\(result)')", completionHandler: nil)
            }
        case "state":
            guard let json = body["json"] as? String else { return }
            saveState(json)
        default:
            break
        }
    }

    private func saveState(_ json: String) {
        let previous = CraneState.load()
        Shared.defaults.set(json, forKey: Shared.stateKey)
        let state = CraneState.load()

        // 위젯은 너무 자주 새로 그리지 않는다
        if Date().timeIntervalSince(lastWidgetReload) > 1.5 || state.cranes.count != previous.cranes.count {
            lastWidgetReload = Date()
            WidgetCenter.shared.reloadAllTimelines()
        }
        // 첫 학을 통에 넣은 순간에 알림을 물어본다
        if previous.totalFolded == 0 && state.totalFolded >= 1 {
            Reminders.shared.askOnce()
        }
        Reminders.shared.reschedule(state: state)
    }
}

/// WKUserContentController가 컨트롤러를 붙잡지 않게
private final class WeakHandler: NSObject, WKScriptMessageHandler {
    weak var target: WKScriptMessageHandler?
    init(_ target: WKScriptMessageHandler) { self.target = target }
    func userContentController(_ c: WKUserContentController, didReceive m: WKScriptMessage) {
        target?.userContentController(c, didReceive: m)
    }
}
