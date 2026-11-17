import Foundation
import UserNotifications

/// 매일 아침 9시 "오늘의 색종이가 도착했어요" 알림.
/// 반복 알림 대신 앞으로 7일치를 예약하고, 앱을 열 때마다 다시 예약한다 (오늘 이미 받았으면 오늘 것은 빼고).
final class Reminders: NSObject, UNUserNotificationCenterDelegate {
    static let shared = Reminders()

    private let askedKey = "reminders.asked"
    private let hour = 9
    private let days = 7
    private let prefix = "daily-paper-"

    func askOnce() {
        guard !UserDefaults.standard.bool(forKey: askedKey) else { return }
        UserDefaults.standard.set(true, forKey: askedKey)
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            if granted {
                DispatchQueue.main.async { self.reschedule(state: CraneState.load()) }
            }
        }
    }

    func reschedule(state: CraneState) {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional,
                  !state.wish.isEmpty else { return }
            let ids = (0..<self.days + 1).map { self.prefix + String($0) }
            center.removePendingNotificationRequests(withIdentifiers: ids)

            let cal = Calendar.current
            let now = Date()
            let gotToday = !state.paperWaiting
            let content = UNMutableNotificationContent()
            content.title = "천 마리 학"
            content.body = "오늘의 색종이 5장이 도착했어요. 소원 통에 학을 접어 넣어 볼까요?"
            content.sound = .default

            for i in 0...self.days {
                guard let day = cal.date(byAdding: .day, value: i, to: now),
                      var fire = cal.date(bySettingHour: self.hour, minute: 0, second: 0, of: day) else { continue }
                if i == 0 && (gotToday || fire <= now) { continue }
                if fire <= now { fire = now.addingTimeInterval(60) }
                let comps = cal.dateComponents([.year, .month, .day, .hour, .minute], from: fire)
                let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
                center.add(UNNotificationRequest(identifier: self.prefix + String(i), content: content, trigger: trigger))
            }
        }
    }

    // 앱을 보고 있을 때는 알림을 띄우지 않는다
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([])
    }
}
