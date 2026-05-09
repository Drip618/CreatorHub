import AppKit
import CoreGraphics
import AVFoundation

class PermissionManager {
    static let shared = PermissionManager()
    
    func checkAndRequestPermissions() {
        requestAccessibility()
        requestScreenRecording()
    }
    
    private func requestAccessibility() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String : true]
        let accessEnabled = AXIsProcessTrustedWithOptions(options)
        if !accessEnabled {
            print("Accessibility permission not granted. System should prompt.")
        }
    }
    
    private func requestScreenRecording() {
        if #available(macOS 10.15, *) {
            // A simple way to trigger the screen recording prompt is to try to capture the screen
            guard CGWindowListCreateImage(.null, .optionOnScreenOnly, kCGNullWindowID, []) != nil else {
                print("Screen recording permission not granted. System should prompt.")
                return
            }
        }
    }
}
