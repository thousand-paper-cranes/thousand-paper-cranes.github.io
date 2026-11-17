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
            let body = CGRect(x: w * 0.04, y: lidH + h * 0.14, width: w * 0.92, height: h * 0.84 - lidH)
            let jar = jarPath(w: w, h: h, lidH: lidH, body: body)

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
            ctx.fill(Path(roundedRect: CGRect(x: w * 0.2, y: 0, width: w * 0.6, height: lidH + h * 0.04), cornerRadius: 3), with: .color(.lid))
        }
    }

    /// 앱의 유리병과 같은 모양: 좁은 입구 → 둥근 어깨 → 몸통
    private func jarPath(w: CGFloat, h: CGFloat, lidH: CGFloat, body: CGRect) -> Path {
        let neckL = w * 0.24, neckR = w * 0.76, top = lidH + h * 0.02
        let r = min(w * 0.14, body.height * 0.2)
        var p = Path()
        p.move(to: CGPoint(x: neckL, y: top))
        p.addLine(to: CGPoint(x: neckR, y: top))
        p.addCurve(to: CGPoint(x: body.maxX, y: body.minY + r * 0.6),
                   control1: CGPoint(x: neckR + w * 0.02, y: body.minY - h * 0.02),
                   control2: CGPoint(x: body.maxX, y: body.minY - h * 0.01))
        p.addLine(to: CGPoint(x: body.maxX, y: body.maxY - r))
        p.addQuadCurve(to: CGPoint(x: body.maxX - r, y: body.maxY), control: CGPoint(x: body.maxX, y: body.maxY))
        p.addLine(to: CGPoint(x: body.minX + r, y: body.maxY))
        p.addQuadCurve(to: CGPoint(x: body.minX, y: body.maxY - r), control: CGPoint(x: body.minX, y: body.maxY))
        p.addLine(to: CGPoint(x: body.minX, y: body.minY + r * 0.6))
        p.addCurve(to: CGPoint(x: neckL, y: top),
                   control1: CGPoint(x: body.minX, y: body.minY - h * 0.01),
                   control2: CGPoint(x: neckL - w * 0.02, y: body.minY - h * 0.02))
        p.closeSubpath()
        return p
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
                    JarView(cranes: []).frame(width: 48, height: 60)
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
            JarView(cranes: s.cranes).frame(width: 70, height: 88)
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
            JarView(cranes: s.cranes).frame(width: 96, height: 124)
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
                GeometryReader { g in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.muted.opacity(0.25))
                        Capsule().fill(Color.accent).frame(width: max(4, g.size.width * CGFloat(min(count, Shared.goal)) / CGFloat(Shared.goal)))
                    }
                }
                .frame(height: 4)
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



// MARK: - 잠금 화면 위젯

/// 잠금 화면용 작은 종이학 모양
struct CraneGlyph: Shape {
    // 옆에서 본 종이학 실루엣 (날개 위로, 목·머리 왼쪽, 꼬리 오른쪽). 0~1 좌표
    private static let polys: [[(CGFloat, CGFloat)]] = [
        [(0.314, 0.827), (0.703, 0.827), (0.780, 0.086)],
        [(0.314, 0.827), (0.508, 0.827), (0.508, 1.000)],
        [(0.508, 0.827), (0.703, 0.827), (0.508, 1.000)],
        [(0.703, 0.827), (0.635, 0.888), (1.000, 0.210)],
        [(0.314, 0.827), (0.382, 0.888), (0.102, 0.160)],
        [(0.102, 0.160), (0.123, 0.216), (0.000, 0.253)],
        [(0.314, 0.827), (0.483, 0.000), (0.415, 0.827)],
        [(0.415, 0.827), (0.483, 0.000), (0.703, 0.827)]
    ]
    func path(in r: CGRect) -> Path {
        var p = Path()
        for poly in Self.polys {
            p.move(to: CGPoint(x: r.minX + poly[0].0 * r.width, y: r.minY + poly[0].1 * r.height))
            for q in poly.dropFirst() { p.addLine(to: CGPoint(x: r.minX + q.0 * r.width, y: r.minY + q.1 * r.height)) }
            p.closeSubpath()
        }
        return p
    }
}

struct CraneAccessoryView: View {
    let state: CraneState
    let family: WidgetFamily

    private var count: Int { state.cranes.count }
    private var frac: CGFloat { CGFloat(min(count, Shared.goal)) / CGFloat(Shared.goal) }

    var body: some View {
        switch family {
        case .accessoryCircular: circular
        case .accessoryRectangular: rectangular
        default: inline
        }
    }

    /// 원형: 천 마리까지 진행 링 + 학 + 마릿수
    private var circular: some View {
        ZStack {
            Circle().fill(Color.white.opacity(0.14))
            Circle().stroke(Color.white.opacity(0.25), lineWidth: 4).padding(3)
            Circle().trim(from: 0, to: max(0.012, frac))
                .stroke(style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90)).padding(3)
            VStack(spacing: 1) {
                CraneGlyph().frame(width: 24, height: 17)
                Text(state.wish.isEmpty ? "소원" : "\(count)")
                    .font(.system(size: count >= 100 ? 13 : 15, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .minimumScaleFactor(0.6)
            }
            .padding(.top, 2)
        }
    }

    /// 가로형: 소원 + 마릿수 + 진행 막대
    private var rectangular: some View {
        HStack(spacing: 8) {
            CraneGlyph().frame(width: 30, height: 21)
            VStack(alignment: .leading, spacing: 2) {
                Text(state.wish.isEmpty ? "천 마리 학" : state.wish)
                    .font(.system(size: 14, weight: .semibold)).lineLimit(1)
                Text(state.wish.isEmpty ? "소원을 적고 첫 학을 접어요" : (state.paperWaiting ? "\(count) / 1000 · 색종이 도착" : "\(count) / 1000마리"))
                    .font(.system(size: 12)).monospacedDigit().lineLimit(1).opacity(0.85)
                GeometryReader { g in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.25))
                        Capsule().frame(width: max(3, g.size.width * frac))
                    }
                }
                .frame(height: 3)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// 한 줄 (시계 위)
    private var inline: some View {
        Text(state.wish.isEmpty ? "천 마리 학" : "학 \(count) / 1000")
    }
}
