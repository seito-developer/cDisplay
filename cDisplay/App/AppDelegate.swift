import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {

    // Temporary Hello World window — will be replaced by StatusBarController in Phase 7.
    private var helloWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        showHelloWorld()
    }

    func applicationWillTerminate(_ notification: Notification) {
    }

    // MARK: - Temporary Hello World

    private func showHelloWorld() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 160),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "cDisplay"
        window.center()

        let label = NSTextField(labelWithString: "Hello, World!")
        label.font = .systemFont(ofSize: 28, weight: .medium)
        label.alignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false

        let contentView = window.contentView!
        contentView.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        ])

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        helloWindow = window
    }
}
