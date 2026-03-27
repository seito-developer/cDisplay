import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusBarController: StatusBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let controller = StatusBarController()
        controller.setup()
        statusBarController = controller
    }

    func applicationWillTerminate(_ notification: Notification) {
        statusBarController?.restoreOnTerminate()
    }

    // MARK: - Dock icon click → toggle resolution

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        statusBarController?.toggle()
        return false
    }
}
