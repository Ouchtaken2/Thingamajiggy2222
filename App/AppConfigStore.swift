import Foundation

/// Small persisted preferences used by the in-app Settings screen.
final class AppConfigStore {
    static let shared = AppConfigStore()

    private let defaults: UserDefaults
    private let speedKey = "frickbears3.gamespeed.v1"
    private let fpsKey = "frickbears3.showfps.v1"
    private let ramKey = "frickbears3.showram.v1"
    private let zoomKey = "frickbears3.showzoom.v1"

    var onChange: (() -> Void)?

    var gameSpeed: Double {
        didSet { defaults.set(gameSpeed, forKey: speedKey); onChange?() }
    }
    var showFPS: Bool {
        didSet { defaults.set(showFPS, forKey: fpsKey); onChange?() }
    }
    var showRAM: Bool {
        didSet { defaults.set(showRAM, forKey: ramKey); onChange?() }
    }
    var showZoomButton: Bool {
        didSet { defaults.set(showZoomButton, forKey: zoomKey); onChange?() }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let savedSpeed = defaults.double(forKey: speedKey)
        self.gameSpeed = savedSpeed > 0 ? savedSpeed : 1.0
        self.showFPS = defaults.bool(forKey: fpsKey)
        self.showRAM = defaults.bool(forKey: ramKey)
        self.showZoomButton = defaults.object(forKey: zoomKey) == nil
            ? true
            : defaults.bool(forKey: zoomKey)
    }

    static let speedOptions: [Double] = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 2.0]

    func resetToDefaults() {
        gameSpeed = 1.0
        showFPS = false
        showRAM = false
        showZoomButton = true
    }
}
