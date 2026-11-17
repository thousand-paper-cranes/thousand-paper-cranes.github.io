import Foundation

/// 앱(WebView 화면)과 위젯이 같이 읽는 소원 통 상태.
/// 화면 쪽 localStorage의 상태 JSON을 그대로 App Group UserDefaults에 복사해 둔다.
enum Shared {
    static let appGroup = "group.com.ohsang.util.thousandcranes"
    static let stateKey = "cranejar.v1"
    static let goal = 1000

    static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroup) ?? .standard
    }

    /// 색종이 색 이름 → 색 (화면의 COLORS와 같은 값)
    static let colors: [String: UInt32] = [
        "red": 0xDE4A3F, "orange": 0xEF8B2E, "yellow": 0xF2C531, "lime": 0x9ACB4C,
        "green": 0x2F9A60, "sky": 0x5DB6E4, "blue": 0x2F6ED4, "navy": 0x2F3F8E,
        "purple": 0x7B56C1, "pink": 0xEC79AE, "blush": 0xF4B8CD, "mint": 0x6AD0BD,
        "gold": 0xD3A73A, "silver": 0xB9BEC8,
    ]
}

struct CraneState: Decodable {
    var wish: String = ""
    var cranes: [String] = []
    var papers: [String] = []
    var lastGrant: String = ""
    var totalFolded: Int = 0
    var dayOffset: Int = 0

    enum CodingKeys: String, CodingKey { case wish, cranes, papers, lastGrant, totalFolded, dayOffset }

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        wish = (try? c.decode(String.self, forKey: .wish)) ?? ""
        cranes = (try? c.decode([String].self, forKey: .cranes)) ?? []
        papers = (try? c.decode([String].self, forKey: .papers)) ?? []
        lastGrant = (try? c.decode(String.self, forKey: .lastGrant)) ?? ""
        totalFolded = (try? c.decode(Int.self, forKey: .totalFolded)) ?? 0
        dayOffset = (try? c.decode(Int.self, forKey: .dayOffset)) ?? 0
    }

    static func load() -> CraneState {
        guard let raw = Shared.defaults.string(forKey: Shared.stateKey),
              let data = raw.data(using: .utf8),
              let s = try? JSONDecoder().decode(CraneState.self, from: data) else { return CraneState() }
        return s
    }

    /// 화면과 같은 방식의 오늘 날짜 (yyyy-MM-dd, 현지 시간)
    static func today(offset: Int = 0) -> String {
        let d = Calendar.current.date(byAdding: .day, value: offset, to: Date()) ?? Date()
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: d)
    }

    /// 오늘 아직 색종이를 받지 않았는지 (앱을 열면 받는다)
    var paperWaiting: Bool { !wish.isEmpty && lastGrant != CraneState.today(offset: dayOffset) }
}
