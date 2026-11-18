import Foundation
import WebKit

/// Keyboard/mouse/lifecycle bridge into the GameMaker HTML5 runtime.
/// GameMaker's Emscripten runner listens on `document`/`window` and reads
/// `event.keyCode`, which is why the synthetic events define that property.
enum WebBridge {
    static func injectKey(_ webView: WKWebView, entry: TouchEntry, down: Bool) {
        let type = down ? "keydown" : "keyup"
        let js = """
        (function(){
          var c=document.getElementById('canvas');
          if (c && c.focus) { c.focus(); }
          var ev=new KeyboardEvent(\(q(type)),{
            key:\(q(entry.key)), code:\(q(entry.code)),
            bubbles:true, cancelable:true
          });
          try {
            Object.defineProperty(ev,'keyCode',{get:function(){return \(entry.keyCode)}});
            Object.defineProperty(ev,'which',{get:function(){return \(entry.keyCode)}});
          } catch (e) {}
          document.dispatchEvent(ev);
          window.dispatchEvent(ev);
        })();
        """
        webView.evaluateJavaScript(js, completionHandler: nil)
    }

    static func injectMouse(_ webView: WKWebView, type: String, x: Int, y: Int) {
        let buttons = type == "mouseup" ? 0 : 1
        let js = """
        (function(){
          var c=document.getElementById('canvas');
          if (!c) return;
          var ev=new MouseEvent(\(q(type)),{
            bubbles:true, cancelable:true,
            clientX:\(x), clientY:\(y),
            button:0, buttons:\(buttons), view:window
          });
          c.dispatchEvent(ev);
        })();
        """
        webView.evaluateJavaScript(js, completionHandler: nil)
    }

    /// Must be called from a real user gesture: unlocks WebAudio and focuses
    /// the canvas so subsequent synthetic keys land on the right element.
    static func start(_ webView: WKWebView) {
        let js = """
        (function(){
          var c=document.getElementById('canvas');
          if (c && c.focus) { c.focus(); }
          if (window.__fb3_unlockAudio) { window.__fb3_unlockAudio(); }
          if (window.__fb3_revealCanvas) { window.__fb3_revealCanvas(); }
        })();
        """
        webView.evaluateJavaScript(js, completionHandler: nil)
    }

    static func pause(_ webView: WKWebView) {
        webView.evaluateJavaScript(
            "if(typeof pause==='function'){pause();}else if(typeof GM_pause==='function'){GM_pause();}",
            completionHandler: nil
        )
    }

    static func resume(_ webView: WKWebView) {
        webView.evaluateJavaScript(
            "if(typeof resume==='function'){resume();}else if(typeof GM_unpause==='function'){GM_unpause();}",
            completionHandler: nil
        )
    }

    /// EXPERIMENTAL: there is no official speed API in the runner. This feeds
    /// GameMaker a scaled virtual clock via GM_tick, which changes its
    /// delta-time. Audio is disabled in this build by default, so drift is
    /// mostly limited to engine internals.
    static func speedScript(initialSpeed: Double) -> WKUserScript {
        let js = """
        (function(){
          var scale = \(initialSpeed);
          window.__fb3_setSpeed = function(s){ scale = s; return scale; };
          var realNow = performance.now.bind(performance);
          var virtual = realNow();
          var last = virtual;
          var original = null;
          function hooked(){
            var now = realNow();
            virtual += (now - last) * scale;
            last = now;
            return original ? original(virtual) : undefined;
          }
          var tries = 0;
          var timer = setInterval(function(){
            tries++;
            if (!original && typeof window.GM_tick === 'function') {
              original = window.GM_tick;
              window.GM_tick = hooked;
              clearInterval(timer);
            } else if (tries > 800) {
              clearInterval(timer);
            }
          }, 25);
        })();
        """
        return WKUserScript(source: js, injectionTime: .atDocumentStart, forMainFrameOnly: true)
    }

    static func setSpeed(_ webView: WKWebView, speed: Double) {
        webView.evaluateJavaScript(
            "if(window.__fb3_setSpeed){window.__fb3_setSpeed(\(speed));}",
            completionHandler: nil
        )
    }

    /// Reports the browser's rendered frame rate back to native every 500 ms.
    static func statsScript() -> WKUserScript {
        let js = """
        (function(){
          if (!window.webkit || !window.webkit.messageHandlers ||
              !window.webkit.messageHandlers.fb3stats) return;
          var frames = 0;
          var last = performance.now();
          function loop(now){
            frames++;
            var elapsed = now - last;
            if (elapsed >= 500) {
              var fps = Math.round(frames * 1000 / elapsed);
              try { window.webkit.messageHandlers.fb3stats.postMessage({fps: fps}); } catch(e){}
              frames = 0;
              last = now;
            }
            requestAnimationFrame(loop);
          }
          requestAnimationFrame(loop);
        })();
        """
        return WKUserScript(source: js, injectionTime: .atDocumentStart, forMainFrameOnly: true)
    }

    /// CSS-level zoom. getBoundingClientRect() reflects the transform, so the
    /// engine keeps mapping taps to the correct in-game coordinates.
    static func setZoom(_ webView: WKWebView, scale: CGFloat, tx: CGFloat, ty: CGFloat) {
        let js = """
        (function(){
          var c=document.getElementById('canvas');
          if(!c) return;
          var z=\(scale), x=\(tx), y=\(ty);
          var mw=c.offsetWidth*(z-1)/2, mh=c.offsetHeight*(z-1)/2;
          x=Math.max(-mw,Math.min(mw,x));
          y=Math.max(-mh,Math.min(mh,y));
          c.style.position='relative';
          c.style.zIndex='50';
          c.style.transformOrigin='center center';
          c.style.transform=(z===1)?'none':('translate('+x+'px,'+y+'px) scale('+z+')');
          window.__fb3_zoom=z;
        })();
        """
        webView.evaluateJavaScript(js, completionHandler: nil)
    }

    private static func q(_ value: String) -> String {
        let escaped = value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "'", with: "\\'")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")
        return "'\(escaped)'"
    }
}

struct TouchEntry: Codable {
    let keyCode: Int
    let key: String
    let code: String
}
