import SwiftUI
import WidgetKit
import UIKit

// 위젯 화면 (위젯 확장과, 디버그 빌드의 위젯 미리보기 그리기에서 같이 쓴다)

// MARK: - 색

extension Color {
    init(hex: UInt32) {
        self.init(red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255, blue: Double(hex & 0xFF) / 255)
    }
    static let paperBg = Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(red: 0.08, green: 0.08, blue: 0.12, alpha: 1) : UIColor(red: 0.93, green: 0.94, blue: 0.96, alpha: 1) })
    static let ink = Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(red: 0.91, green: 0.92, blue: 0.95, alpha: 1) : UIColor(red: 0.13, green: 0.15, blue: 0.23, alpha: 1) })
    static let muted = Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(red: 0.60, green: 0.62, blue: 0.72, alpha: 1) : UIColor(red: 0.42, green: 0.44, blue: 0.53, alpha: 1) })
    static let accent = Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(red: 0.55, green: 0.61, blue: 1, alpha: 1) : UIColor(red: 0.24, green: 0.33, blue: 0.77, alpha: 1) })
    static let label = Color(hex: 0xFBF7EC)
    static let labelInk = Color(hex: 0x3A3428)
    static let lid = Color(hex: 0xB8946A)
}

// MARK: - 유리통

struct JarView: View {
    let cranes: [String]
    var showLabel: String? = nil

    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let lidH = h * 0.09
            let body = CGRect(x: w * 0.04, y: lidH + h * 0.05, width: w * 0.92, height: h * 0.86 - lidH)
            let jar = Path(roundedRect: body, cornerRadius: w * 0.14)

            // 학: 통 바닥부터, 1000마리면 가득 차는 높이까지
            let fill = min(1, Double(cranes.count) / Double(Shared.goal))
            if !cranes.isEmpty {
                var inner = ctx
                inner.clip(to: jar)
                let cell = max(5, w * 0.105)
                let cols = Int(ceil(body.width / cell)) + 1
                let fillH = max(cell * 0.9, body.height * fill)
                let rows = Int(ceil(fillH / (cell * 0.62)))
                let total = cols * rows
                let step = max(1, Double(cranes.count) / Double(max(total, 1)))
                var n = 0
                for r in 0..<rows {
                    let y = body.maxY - CGFloat(r) * cell * 0.62 - cell * 0.35
                    for c in 0..<cols {
                        let idx = min(cranes.count - 1, Int(Double(n) * step))
                        n += 1
                        let key = cranes[cranes.count - 1 - idx]
                        let color = Color(hex: Shared.colors[key] ?? 0xDE4A3F)
                        let x = body.minX + CGFloat(c) * cell - (r % 2 == 0 ? 0 : cell / 2)
                        inner.fill(crane(at: CGPoint(x: x, y: y), size: cell, flip: (r + c) % 3 == 0), with: .color(color))
                        inner.stroke(crane(at: CGPoint(x: x, y: y), size: cell, flip: (r + c) % 3 == 0),
                                     with: .color(.black.opacity(0.18)), lineWidth: 0.5)
                    }
                }
            }
            // 유리
            ctx.fill(jar, with: .color(Color.white.opacity(0.10)))
            ctx.stroke(jar, with: .color(Color.muted.opacity(0.6)), lineWidth: 1.4)
            ctx.fill(Path(roundedRect: CGRect(x: body.minX + w * 0.07, y: body.minY + h * 0.08, width: w * 0.035, height: body.height * 0.55),
                          cornerRadius: 2), with: .color(.white.opacity(0.45)))
            // 뚜껑
            ctx.fill(Path(roundedRect: CGRect(x: w * 0.2, y: 0, width: w * 0.6, height: lidH + h * 0.06), cornerRadius: 3), with: .color(.lid))
        }
    }

    /// 아주 작은 종이학 (몸통 + 날개 두 장 + 목·꼬리)
    private func crane(at p: CGPoint, size s: CGFloat, flip: Bool) -> Path {
        let d: CGFloat = flip ? -1 : 1
        var path = Path()
        path.move(to: CGPoint(x: p.x - 0.5 * s * d, y: p.y))
        path.addLine(to: CGPoint(x: p.x - 0.62 * s * d, y: p.y - 0.42 * s))   // 목
        path.addLine(to: CGPoint(x: p.x - 0.30 * s * d, y: p.y - 0.06 * s))
        path.addLine(to: CGPoint(x: p.x + 0.05 * s * d, y: p.y - 0.55 * s))   // 날개
        path.addLine(to: CGPoint(x: p.x + 0.22 * s * d, y: p.y - 0.06 * s))
        path.addLine(to: CGPoint(x: p.x + 0.62 * s * d, y: p.y - 0.40 * s))   // 꼬리
        path.addLine(to: CGPoint(x: p.x + 0.42 * s * d, y: p.y))
        path.addLine(to: CGPoint(x: p.x, y: p.y + 0.16 * s))
        path.closeSubpath()
        return path
    }
}

// MARK: - 위젯 화면

struct CraneWidgetView: View {
    let state: CraneState
    let family: WidgetFamily

    private var s: CraneState { state }
    private var count: Int { s.cranes.count }

    var body: some View {
        Group {
            if s.wish.isEmpty {
                VStack(spacing: 6) {
                    JarView(cranes: []).frame(width: 46, height: 60)
                    Text("소원을 적고\n첫 학을 접어요").font(.system(size: 13, weight: .semibold)).multilineTextAlignment(.center)
                        .foregroundStyle(Color.ink)
                }
            } else if family == .systemSmall {
                small
            } else {
                medium
            }
        }
        .widgetBackground(Color.paperBg)
    }

    private var small: some View {
        VStack(spacing: 4) {
            JarView(cranes: s.cranes).frame(maxWidth: .infinity).frame(height: 84)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("\(count)").font(.system(size: 20, weight: .bold, design: .serif)).monospacedDigit()
                Text("/ 1000").font(.system(size: 11)).foregroundStyle(Color.muted)
            }
            .foregroundStyle(Color.ink)
            Text(s.paperWaiting ? "오늘의 색종이 도착" : "색종이 \(s.papers.count)장")
                .font(.system(size: 11, weight: s.paperWaiting ? .semibold : .regular))
                .foregroundStyle(s.paperWaiting ? Color.accent : Color.muted)
        }
    }

    private var medium: some View {
        HStack(spacing: 14) {
            JarView(cranes: s.cranes).frame(width: 92)
            VStack(alignment: .leading, spacing: 6) {
                Text(s.wish)
                    .font(.system(size: 15, weight: .semibold, design: .serif))
                    .foregroundStyle(Color.labelInk)
                    .lineLimit(2)
                    .padding(.horizontal, 8).padding(.vertical, 5)
                    .background(RoundedRectangle(cornerRadius: 3).fill(Color.label))
                    .rotationEffect(.degrees(-1.5))
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text("\(count)").font(.system(size: 26, weight: .bold, design: .serif)).monospacedDigit()
                    Text("/ 1000마리").font(.system(size: 12)).foregroundStyle(Color.muted)
                }
                .foregroundStyle(Color.ink)
                ProgressView(value: Double(min(count, Shared.goal)), total: Double(Shared.goal)).tint(Color.accent)
                Text(s.paperWaiting ? "오늘의 색종이 5장이 도착했어요" : (count >= Shared.goal ? "소원이 이루어지길 바랍니다" : "천 마리까지 \(Shared.goal - count)마리 · 색종이 \(s.papers.count)장"))
                    .font(.system(size: 11, weight: s.paperWaiting ? .semibold : .regular))
                    .foregroundStyle(s.paperWaiting ? Color.accent : Color.muted)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

extension View {
    @ViewBuilder func widgetBackground(_ color: Color) -> some View {
        if #available(iOS 17.0, *) {
            containerBackground(for: .widget) { color }
        } else {
            padding().background(color)
        }
    }
}

