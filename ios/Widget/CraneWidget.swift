import WidgetKit
import SwiftUI

// 홈 화면 위젯: 내가 접은 학이 그 색대로 쌓인 유리통, 소원, 남은 마릿수, 오늘의 색종이 도착 여부.

struct JarEntry: TimelineEntry {
    let date: Date
    let state: CraneState
}

struct JarProvider: TimelineProvider {
    func placeholder(in context: Context) -> JarEntry {
        var s = CraneState()
        s.wish = "우리 가족 모두 건강하게"
        s.cranes = (0..<240).map { _ in Shared.colors.keys.randomElement() ?? "red" }
        return JarEntry(date: Date(), state: s)
    }

    func getSnapshot(in context: Context, completion: @escaping (JarEntry) -> Void) {
        let s = CraneState.load()
        completion(s.wish.isEmpty && context.isPreview ? placeholder(in: context) : JarEntry(date: Date(), state: s))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<JarEntry>) -> Void) {
        // 자정에 "오늘의 색종이가 도착했어요"로 바뀌도록 다시 그린다
        let cal = Calendar.current
        let midnight = cal.startOfDay(for: cal.date(byAdding: .day, value: 1, to: Date()) ?? Date())
        let now = JarEntry(date: Date(), state: CraneState.load())
        let next = JarEntry(date: midnight, state: CraneState.load())
        completion(Timeline(entries: [now, next], policy: .after(midnight)))
    }
}

struct CraneWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: JarEntry
    var body: some View {
        switch family {
        case .accessoryCircular, .accessoryRectangular, .accessoryInline:
            CraneAccessoryView(state: entry.state, family: family).accessoryBackground()
        default:
            CraneWidgetView(state: entry.state, family: family)
        }
    }
}

@main
struct CraneWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "CraneJar", provider: JarProvider()) { entry in
            CraneWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("소원 유리통")
        .description("내가 접은 학이 쌓인 유리통과 남은 마릿수를 보여줘요.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

extension View {
    @ViewBuilder func accessoryBackground() -> some View {
        if #available(iOS 17.0, *) {
            containerBackground(for: .widget) { Color.clear }
        } else {
            self
        }
    }
}
