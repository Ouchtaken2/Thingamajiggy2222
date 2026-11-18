import Foundation
import WebKit

/// Serves the bundled GameMaker HTML5 build from the app bundle through a
/// custom `fb3://` scheme. Using a custom scheme (instead of `file://`) avoids
/// WKWebView's local-file fetch/CORS/WebAssembly restrictions.
final class GameURLSchemeHandler: NSObject, WKURLSchemeHandler {
    private let fileManager = FileManager.default

    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        guard let url = urlSchemeTask.request.url else {
            urlSchemeTask.didFailWithError(URLError(.badURL))
            return
        }

        let rawPath = url.path.removingPercentEncoding ?? url.path
        let relative = rawPath.hasPrefix("/") ? String(rawPath.dropFirst()) : rawPath

        guard let file = resolve(relative), fileManager.fileExists(atPath: file.path) else {
            let response = HTTPURLResponse(
                url: url,
                statusCode: 404,
                httpVersion: "HTTP/1.1",
                headerFields: ["Content-Type": "text/plain; charset=utf-8"]
            )!
            urlSchemeTask.didReceive(response)
            urlSchemeTask.didReceive(Data("Not found: \(relative)".utf8))
            urlSchemeTask.didFinish()
            return
        }

        let data = try? Data(contentsOf: file)
        var headers = mimeHeaders(for: file.pathExtension)
        headers["Cache-Control"] = "no-store"
        headers["Access-Control-Allow-Origin"] = "*"

        let response = HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: "HTTP/1.1",
            headerFields: headers
        )!
        urlSchemeTask.didReceive(response)
        if let data { urlSchemeTask.didReceive(data) }
        urlSchemeTask.didFinish()
    }

    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
        // Nothing to cancel: files are read synchronously from the bundle.
    }

    private func resolve(_ relative: String) -> URL? {
        guard !relative.isEmpty else { return nil }

        let candidates = [
            Bundle.main.resourceURL?
                .appendingPathComponent("Game", isDirectory: true)
                .appendingPathComponent(relative),
            Bundle.main.resourceURL?.appendingPathComponent(relative),
            Bundle.main.bundleURL
                .appendingPathComponent("Game", isDirectory: true)
                .appendingPathComponent(relative),
            Bundle.main.bundleURL.appendingPathComponent(relative)
        ]

        return candidates.first { fileManager.fileExists(atPath: $0.path) }
    }

    private func mimeHeaders(for fileExtension: String) -> [String: String] {
        switch fileExtension.lowercased() {
        case "html", "htm":            return ["Content-Type": "text/html; charset=utf-8"]
        case "js":                     return ["Content-Type": "text/javascript; charset=utf-8"]
        case "wasm":                   return ["Content-Type": "application/wasm"]
        case "json", "webmanifest":    return ["Content-Type": "application/json; charset=utf-8"]
        case "css":                    return ["Content-Type": "text/css; charset=utf-8"]
        case "png":                    return ["Content-Type": "image/png"]
        case "jpg", "jpeg":            return ["Content-Type": "image/jpeg"]
        case "svg":                    return ["Content-Type": "image/svg+xml"]
        case "ogg":                    return ["Content-Type": "audio/ogg"]
        case "mp3":                    return ["Content-Type": "audio/mpeg"]
        case "wav":                    return ["Content-Type": "audio/wav"]
        default:                       return ["Content-Type": "application/octet-stream"]
        }
    }
}
