import Foundation
import Darwin

/// Reads the app's own resident memory footprint. WKWebView has no equivalent
/// of Chrome's `performance.memory`, so this has to come from the native side.
enum MemoryMonitor {
    static func usedMegabytes() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(
            MemoryLayout<mach_task_basic_info>.size / MemoryLayout<integer_t>.size
        )

        let result = withUnsafeMutablePointer(to: &info) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: 1) { integerPointer in
                task_info(
                    mach_task_self_,
                    task_flavor_t(MACH_TASK_BASIC_INFO),
                    integerPointer,
                    &count
                )
            }
        }

        guard result == KERN_SUCCESS else { return -1 }
        return Double(info.resident_size) / 1024 / 1024
    }
}
