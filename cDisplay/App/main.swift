import AppKit
import CoreGraphics

// --- Crash recovery: restore resolution BEFORE any UI ---
DisplayModeService.restoreIfNeeded()

// --- Normal app startup ---
let app = NSApplication.shared
let appDelegate = AppDelegate()
app.delegate = appDelegate
app.setActivationPolicy(.regular)
app.run()
