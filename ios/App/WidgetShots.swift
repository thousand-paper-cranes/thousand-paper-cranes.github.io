#if DEBUG
import SwiftUI
import UIKit
import WidgetKit

/// 디버그 빌드 + CRANE_WIDGETSHOT=1 일 때만: 위젯 화면을 PNG로 그려 Documents/widget-*.png 에 저장한다.
/// (시뮬레이터 홈 화면에 위젯을 직접 올릴 수 없어서, 같은 SwiftUI 화면을 그대로 그려 확인용으로 쓴다)
enum WidgetShots {
    @MainActor
    static func renderIfRequested() {
        guard ProcessInfo.processInfo.environment["CRANE_WIDGETSHOT"] == "1" else { return }
        let keys = ["red","orange","yellow","lime","green","sky","blue","navy","purple","pink","blush","mint","gold","silver"]
        var rng = SystemRandomNumberGenerator()
        var full = CraneState()
        full.wish = "우리 가족 모두 건강하게"
        full.cranes = (0..<327).map { _ in keys.randomElement(using: &rng)! }
        full.papers = ["red","sky","gold"]
        full.lastGrant = CraneState.today()
        var waiting = full
        waiting.lastGrant = "2000-01-01"
        let empty = CraneState()

        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let small = CGSize(width: 170, height: 170), medium = CGSize(width: 364, height: 170)
        let jobs: [(String, CraneState, WidgetFamily, CGSize, ColorScheme)] = [
            ("small-light", full, .systemSmall, small, .light),
            ("medium-light", waiting, .systemMedium, medium, .light),
            ("small-dark", waiting, .systemSmall, small, .dark),
            ("medium-dark", full, .systemMedium, medium, .dark),
            ("medium-empty", empty, .systemMedium, medium, .light),
        ]
        // 잠금 화면 모양으로 원형·가로형을 같이 그린다
        for (name, state) in [("lock-327", full), ("lock-waiting", waiting), ("lock-empty", empty)] {
            let lock = VStack(spacing: 6) {
                Text("11월 17일 화요일").font(.system(size: 17, weight: .semibold))
                Text("9:41").font(.system(size: 92, weight: .bold, design: .rounded))
                HStack(spacing: 14) {
                    CraneAccessoryView(state: state, family: .accessoryCircular).frame(width: 72, height: 72)
                    CraneAccessoryView(state: state, family: .accessoryRectangular).frame(width: 170, height: 72)
                }
                .padding(.top, 2)
            }
            .foregroundStyle(.white)
            .frame(width: 390, height: 300)
            .background(LinearGradient(colors: [Color(hex: 0x2B3A67), Color(hex: 0x6B4E8A), Color(hex: 0xC97B84)], startPoint: .top, endPoint: .bottom))
            .environment(\.colorScheme, .dark)
            let r = ImageRenderer(content: lock)
            r.scale = 3
            if let img = r.uiImage, let png = img.pngData() {
                try? png.write(to: docs.appendingPathComponent("widget-\(name).png"))
            }
        }
        for (name, state, family, size, scheme) in jobs {
            let view = CraneWidgetView(state: state, family: family)
                .padding(16)
                .frame(width: size.width, height: size.height)
                .background(Color.paperBg)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .environment(\.colorScheme, scheme)
            let r = ImageRenderer(content: view)
            r.scale = 3
            r.isOpaque = false
            if let img = r.uiImage, let png = img.pngData() {
                try? png.write(to: docs.appendingPathComponent("widget-\(name).png"))
            }
        }
    }
}
#endif
