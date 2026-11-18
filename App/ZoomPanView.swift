import UIKit

/// While zoomed in, a short tap still clicks the game; a drag pans the canvas.
final class ZoomPanView: UIView {
    var onTap: ((_ x: Int, _ y: Int) -> Void)?
    var onPan: ((_ dx: CGFloat, _ dy: CGFloat) -> Void)?

    private var startPoint: CGPoint?
    private var lastPoint: CGPoint?
    private var didPan = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isUserInteractionEnabled = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = touches.first?.location(in: self) else { return }
        startPoint = point
        lastPoint = point
        didPan = false
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = touches.first?.location(in: self),
              let last = lastPoint,
              let start = startPoint else { return }

        if !didPan && hypot(point.x - start.x, point.y - start.y) > 6 {
            didPan = true
        }
        if didPan {
            onPan?(point.x - last.x, point.y - last.y)
        }
        lastPoint = point
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = touches.first?.location(in: self) else { return }
        if !didPan {
            onTap?(Int(point.x), Int(point.y))
        }
        startPoint = nil
        lastPoint = nil
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        startPoint = nil
        lastPoint = nil
    }
}
