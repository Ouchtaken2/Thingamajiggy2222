import UIKit

/// Translucent on-screen gamepad. Only the buttons intercept touches; all
/// other touches fall through to the WKWebView underneath.
final class TouchControlOverlay: UIView {

    var onKey: ((_ entry: TouchEntry, _ down: Bool) -> Void)?
    var onMouseModeChanged: ((_ enabled: Bool) -> Void)?
    var onPauseToggle: (() -> Void)?
    var onSettings: (() -> Void)?
    var onZoomToggle: (() -> Void)?

    private var actionButtons: [ActionButton] = []
    private var mouseEnabled = false
    private var mouseButton: UIButton!
    private var zoomButton: UIButton!

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = true
        backgroundColor = .clear
        buildControls()

        TouchMappingStore.shared.onChange = { [weak self] in
            self?.refreshTitles()
        }
    }

    /// Called by GameViewController when app config changes (it owns the
    /// single AppConfigStore.onChange closure).
    func refreshConfig() {
        zoomButton.isHidden = !AppConfigStore.shared.showZoomButton
    }

    func setZoomLabel(_ text: String) {
        zoomButton.setTitle(text, for: .normal)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func buildControls() {
        // D-pad (left side)
        place(button(.up,    glyph: "▲", x: -0.060, y: -0.085))
        place(button(.down,  glyph: "▼", x: -0.060, y:  0.085))
        place(button(.left,  glyph: "◀", x: -0.115, y:  0.000))
        place(button(.right, glyph: "▶", x: -0.005, y:  0.000))

        // Action cluster (right side)
        place(button(.x,  glyph: "X", x:  0.005, y: -0.085))
        place(button(.y,  glyph: "Y", x: -0.060, y:  0.000))
        place(button(.a,  glyph: "A", x:  0.060, y:  0.000))
        place(button(.b,  glyph: "B", x:  0.005, y:  0.085))
        place(button(.l1, glyph: "L", x:  0.060, y: -0.085))
        place(button(.r1, glyph: "R", x:  0.115, y:  0.000))

        // Utilities
        place(utilityButton("II") { [weak self] in self?.onPauseToggle?() },
              x: -0.44, y: -0.45, size: 38)

        place(utilityButton("⚙") { [weak self] in self?.onSettings?() },
              x: 0.0, y: -0.45, size: 38)

        zoomButton = utilityButton("🔍 1×") { [weak self] in self?.onZoomToggle?() }
        place(zoomButton, x: 0.22, y: -0.45, size: 58)

        mouseButton = utilityButton("MOUSE: OFF") { [weak self] in
            guard let self else { return }
            self.mouseEnabled.toggle()
            self.mouseButton.setTitle(self.mouseEnabled ? "MOUSE: ON" : "MOUSE: OFF", for: .normal)
            self.mouseButton.tintColor = self.mouseEnabled ? .systemGreen : .white
            self.onMouseModeChanged?(self.mouseEnabled)
        }
        place(mouseButton, x: 0.44, y: -0.45, size: 104)

        refreshTitles()
        refreshConfig()
    }

    private func button(_ action: TouchAction, glyph: String, x: CGFloat, y: CGFloat) -> ActionButton {
        let button = ActionButton(action: action, glyph: glyph)
        button.addTarget(self, action: #selector(keyDown(_:)), for: .touchDown)
        button.addTarget(
            self,
            action: #selector(keyUp(_:)),
            for: [.touchUpInside, .touchUpOutside, .touchCancel]
        )
        actionButtons.append(button)
        return button
    }

    private func utilityButton(_ title: String, action: @escaping () -> Void) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 12)
        button.tintColor = .white
        button.backgroundColor = UIColor.black.withAlphaComponent(0.42)
        button.layer.cornerRadius = 8
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.white.withAlphaComponent(0.25).cgColor
        button.addClosure(action)
        return button
    }

    private func place(_ button: UIButton, x: CGFloat, y: CGFloat, size: CGFloat = 54) {
        button.translatesAutoresizingMaskIntoConstraints = false
        addSubview(button)
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: size),
            button.heightAnchor.constraint(equalToConstant: size),
            button.centerXAnchor.constraint(
                equalTo: centerXAnchor,
                constant: x * UIScreen.main.bounds.width
            ),
            button.centerYAnchor.constraint(
                equalTo: centerYAnchor,
                constant: y * UIScreen.main.bounds.height
            )
        ])
    }

    private func refreshTitles() {
        for button in actionButtons {
            let label = TouchMappingStore.shared.label(for: button.action)
            let attributed = NSMutableAttributedString()
            attributed.append(NSAttributedString(
                string: button.glyph + "\n",
                attributes: [.font: UIFont.boldSystemFont(ofSize: 18), .foregroundColor: UIColor.white]
            ))
            attributed.append(NSAttributedString(
                string: label,
                attributes: [.font: UIFont.systemFont(ofSize: 9), .foregroundColor: UIColor(white: 0.78, alpha: 1)]
            ))
            button.setAttributedTitle(attributed, for: .normal)
        }
    }

    @objc private func keyDown(_ sender: ActionButton) {
        fire(sender, down: true)
    }

    @objc private func keyUp(_ sender: ActionButton) {
        fire(sender, down: false)
    }

    private func fire(_ sender: ActionButton, down: Bool) {
        let entry = TouchMappingStore.shared.entry(for: sender.action)
        onKey?(entry, down)
    }
}

// MARK: - Buttons

final class ActionButton: UIButton {
    let action: TouchAction
    let glyph: String

    init(action: TouchAction, glyph: String) {
        self.action = action
        self.glyph = glyph
        super.init(frame: .zero)
        titleLabel?.numberOfLines = 2
        titleLabel?.textAlignment = .center
        tintColor = .white
        backgroundColor = UIColor.black.withAlphaComponent(0.42)
        layer.cornerRadius = 10
        layer.borderWidth = 1
        layer.borderColor = UIColor.white.withAlphaComponent(0.32).cgColor
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

private extension UIButton {
    private struct AssociatedKey { static var closure: UInt8 = 0 }

    func addClosure(_ closure: @escaping () -> Void) {
        objc_setAssociatedObject(self, &AssociatedKey.closure, closure, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        addTarget(self, action: #selector(runClosure), for: .touchUpInside)
    }

    @objc private func runClosure() {
        guard let closure = objc_getAssociatedObject(self, &AssociatedKey.closure) as? () -> Void else { return }
        closure()
    }
}

/// Captures taps in empty game areas and turns them into synthetic mouse
/// events, needed for doors / monitor tabs in the office.
final class MouseCaptureView: UIView {
    var onEvent: ((_ type: String, _ x: Int, _ y: Int) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isUserInteractionEnabled = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        send(touches, "mousedown")
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        send(touches, "mousemove")
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        send(touches, "mouseup")
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        send(touches, "mouseup")
    }

    private func send(_ touches: Set<UITouch>, _ type: String) {
        guard let point = touches.first?.location(in: self) else { return }
        onEvent?(type, Int(point.x), Int(point.y))
    }
}
