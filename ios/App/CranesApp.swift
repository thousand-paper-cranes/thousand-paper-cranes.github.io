import SwiftUI
import UIKit
import GoogleMobileAds
import UserNotifications

@main
struct CranesApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var delegate

    var body: some Scene {
        WindowGroup {
            WebContainer()
                .background(Color("PaperBg").ignoresSafeArea())
        }
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = Reminders.shared
        // 광고 SDK는 추적 허용 질문이 끝난 뒤에 시작한다 (Ads.startAfterTrackingPrompt)
        #if DEBUG
        DispatchQueue.main.async { WidgetShots.renderIfRequested() }
        #endif
        return true
    }
}

/// 상태 표시줄·홈 인디케이터 영역은 비워 두고 그 안쪽에 화면을 띄운다 (Android와 같은 방식)
struct WebContainer: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> WebViewController { WebViewController() }
    func updateUIViewController(_ vc: WebViewController, context: Context) {}
}
