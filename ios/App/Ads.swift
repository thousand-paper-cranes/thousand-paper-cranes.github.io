import UIKit
import GoogleMobileAds
import AppTrackingTransparency

/// "광고 보고 색종이 5장 더 받기"용 보상형 광고.
/// 광고 단위 ID는 Info.plist의 AdmobRewardedID (빌드 때 Variables로 넣고, 없으면 Google 테스트 광고).
final class Ads: NSObject, FullScreenContentDelegate {
    static let shared = Ads()

    private var ad: RewardedAd?
    private var loading = false
    private var waiting: ((String) -> Void)?
    private weak var presenter: UIViewController?
    private var finish: ((String) -> Void)?
    private var earned = false

    private var unitID: String {
        (Bundle.main.object(forInfoDictionaryKey: "AdmobRewardedID") as? String)
            .flatMap { $0.isEmpty ? nil : $0 } ?? "ca-app-pub-3940256099942544/1712485313"
    }

    func preload() { load() }

    func show(from vc: UIViewController, done: @escaping (String) -> Void) {
        askTrackingIfNeeded { [weak self] in
            guard let self else { return }
            if let ad = self.ad {
                self.present(ad, from: vc, done: done)
            } else {
                self.waiting = done
                self.presenter = vc
                self.load()
            }
        }
    }

    /// 광고 버튼을 처음 누를 때만 묻는다. 거부해도 보상은 똑같다
    private func askTrackingIfNeeded(_ next: @escaping () -> Void) {
        if ATTrackingManager.trackingAuthorizationStatus == .notDetermined {
            ATTrackingManager.requestTrackingAuthorization { _ in
                DispatchQueue.main.async { next() }
            }
        } else {
            next()
        }
    }

    private func load() {
        guard ad == nil, !loading else { return }
        loading = true
        RewardedAd.load(with: unitID, request: Request()) { [weak self] loaded, _ in
            DispatchQueue.main.async {
                guard let self else { return }
                self.loading = false
                if let loaded {
                    self.ad = loaded
                    if let done = self.waiting, let vc = self.presenter {
                        self.waiting = nil
                        self.present(loaded, from: vc, done: done)
                    }
                } else if let done = self.waiting {
                    self.waiting = nil
                    done("unavailable")
                }
            }
        }
    }

    private func present(_ ad: RewardedAd, from vc: UIViewController, done: @escaping (String) -> Void) {
        self.ad = nil
        earned = false
        finish = done
        ad.fullScreenContentDelegate = self
        ad.present(from: vc) { [weak self] in self?.earned = true }
    }

    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        finish?(earned ? "reward" : "closed")
        finish = nil
        load()
    }

    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        finish?("unavailable")
        finish = nil
        load()
    }
}
