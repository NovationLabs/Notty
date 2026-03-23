import Cocoa
import Carbon.HIToolbox

// --- NSPanel subclass ---
// By default, a borderless NSPanel cannot become key window,
// which prevents keyboard input in the textView.
// We override canBecomeKey to force it to true.
class NotePanel: NSPanel {
    override var canBecomeKey: Bool {
        return true
    }

    // Resize zone: only the 4 corners (12x12 pixels)
    let cornerSize: CGFloat = 12

    override func mouseDown(with event: NSEvent) {
        let loc = event.locationInWindow
        let f = frame
        // Check if the click is in one of the 4 corners
        let inBottomRight = loc.x > f.width - cornerSize && loc.y < cornerSize

        if inBottomRight {
            performResize(from: event)
        } else {
            super.mouseDown(with: event)
        }
    }

    // Manual resize since the panel is borderless (no native resize handle)
    func performResize(from startEvent: NSEvent) {
        let startFrame = frame
        let startLoc = NSEvent.mouseLocation

        // Drag loop for resize
        while true {
            guard let event = nextEvent(matching: [.leftMouseDragged, .leftMouseUp]) else { break }
            if event.type == .leftMouseUp { break }

            let currentLoc = NSEvent.mouseLocation
            let dx = currentLoc.x - startLoc.x
            let dy = currentLoc.y - startLoc.y

            var newWidth = startFrame.width + dx
            var newHeight = startFrame.height - dy
            // Minimum size
            newWidth = max(newWidth, 200)
            newHeight = max(newHeight, 200)

            let newOriginY = startFrame.origin.y + (startFrame.height - newHeight)
            setFrame(NSRect(x: startFrame.origin.x, y: newOriginY, width: newWidth, height: newHeight), display: true)
        }
    }
}

// --- Resize grip: 3 diagonal lines (macOS style) ---
class ResizeGripView: NSView {
    override func draw(_ dirtyRect: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        let color = NSColor(white: 1.0, alpha: 0.35).cgColor
        ctx.setStrokeColor(color)
        ctx.setLineWidth(1.0)
        ctx.setLineCap(.round)

        let s = bounds.width
        // 3 diagonal lines from bottom-left to top-right
        for i in 0..<3 {
            let offset = CGFloat(i) * 4
            ctx.move(to: CGPoint(x: s - 2 - offset, y: 1))
            ctx.addLine(to: CGPoint(x: s - 1, y: 2 + offset))
            ctx.strokePath()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {

    // Menu bar icon
    var statusItem: NSStatusItem!

    // Floating panel (NotePanel, not NSPanel)
    var panel: NotePanel!

    // Text editor
    var textView: NSTextView!

    // Event monitors to detect clicks outside the panel
    var globalClickMonitor: Any?     // clicks in OTHER apps
    var localClickMonitor: Any?      // clicks in OUR app (outside panel)

    // Timestamp of last close — prevents the global monitor from closing
    // the panel right before togglePanel reopens it
    var lastCloseTime: Date = .distantPast

    // File where notes are saved
    let saveURL = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".notty.txt")

    // Pinned mode: panel stays open even when clicking outside
    var isPinned: Bool = false
    var titleButton: NSButton!

    var hotKeyRef: EventHotKeyRef?

    func applicationDidFinishLaunching(_ notification: Notification) {

        // --- 1. Create menu bar icon ---
        statusItem = NSStatusBar.system.statusItem(
            withLength: NSStatusItem.squareLength
        )

        if let button = statusItem.button {
            button.image = NSImage(
                systemSymbolName: "folder",
                accessibilityDescription: "Notty"
            )
            button.action = #selector(togglePanel)
            button.target = self
        }

        // --- 2. Create the panel ---
        // IMPORTANT: no .nonactivatingPanel!
        // It prevents app activation, which blocks the panel from opening
        // when another app is in the foreground AND prevents keyboard input.
        panel = NotePanel(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 400),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        panel.level = .popUpMenu
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hidesOnDeactivate = false          // we handle closing ourselves
        panel.isReleasedWhenClosed = false        // prevents crash on reopen
        panel.isFloatingPanel = true              // stays above other windows
        panel.collectionBehavior = [
            .canJoinAllSpaces,                   // visible on all Spaces/desktops
            .fullScreenAuxiliary                 // visible even in fullscreen
        ]

        // --- 3. Dark container with rounded corners ---
        let container = NSView(frame: NSRect(x: 0, y: 0, width: 320, height: 400))
        container.wantsLayer = true
        container.layer?.backgroundColor = NSColor(white: 0.12, alpha: 0.95).cgColor
        container.layer?.cornerRadius = 12
        container.layer?.borderWidth = 1
        container.layer?.borderColor = NSColor(white: 1.0, alpha: 0.08).cgColor
        container.autoresizingMask = [.width, .height]   // adapts when panel is resized

        // --- 4. Title "Notty" ---
        let title = NSTextField(labelWithString: "Notty")
        title.frame = NSRect(x: 16, y: 365, width: 200, height: 24)
        title.font = NSFont(name: "Space Mono", size: 14)
            ?? NSFont.monospacedSystemFont(ofSize: 14, weight: .bold)
        title.textColor = NSColor(white: 1.0, alpha: 0.5)
        title.autoresizingMask = [.minYMargin]
        container.addSubview(title)

        // --- 4b. Pin button (top-right) ---
        titleButton = NSButton(frame: NSRect(x: 288, y: 364, width: 22, height: 22))
        titleButton.bezelStyle = .inline
        titleButton.isBordered = false
        titleButton.image = NSImage(systemSymbolName: "pin", accessibilityDescription: "Pin")
        titleButton.contentTintColor = NSColor(white: 1.0, alpha: 0.2)
        titleButton.autoresizingMask = [.minXMargin, .minYMargin]
        titleButton.target = self
        titleButton.action = #selector(togglePinned)
        container.addSubview(titleButton)

        // --- 5. Text editor with scroll ---
        let scrollView = NSScrollView(frame: NSRect(x: 12, y: 12, width: 296, height: 345))
        scrollView.autoresizingMask = [.width, .height]  // adapts on resize
        scrollView.hasVerticalScroller = true
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false

        textView = NSTextView(frame: scrollView.bounds)
        textView.isEditable = true
        textView.isRichText = false
        textView.allowsUndo = true
        textView.drawsBackground = false
        textView.insertionPointColor = .white
        textView.textColor = NSColor(white: 1.0, alpha: 0.9)
        textView.font = NSFont(name: "Space Mono", size: 13)
            ?? NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        textView.textContainerInset = NSSize(width: 4, height: 4)
        textView.autoresizingMask = [.width]
        textView.textContainer?.widthTracksTextView = true

        scrollView.documentView = textView
        container.addSubview(scrollView)

        // --- 6. Resize grip indicator (bottom-right corner) ---
        let grip = ResizeGripView(frame: NSRect(x: 320 - 20, y: 4, width: 14, height: 14))
        grip.autoresizingMask = [.minXMargin, .maxYMargin]
        container.addSubview(grip)

        panel.contentView = container

        // --- 6. Load saved text ---
        if let saved = try? String(contentsOf: saveURL, encoding: .utf8) {
            textView.string = saved
        }

        // --- 7. Global hotkey: ⌘+Control+N to toggle panel ---
        registerHotKey()

        // --- 8. Auto-save on every text change ---
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(textDidChange),
            name: NSText.didChangeNotification,
            object: textView
        )
    }

    // --- Global hotkey: ⌘+Control+N ---
    func registerHotKey() {
        var hotKeyID = EventHotKeyID()
        // 4-char signature to identify the hotkey
        hotKeyID.signature = OSType(0x6E6F7479)  // 'noty'
        hotKeyID.id = 1

        // kVK_ANSI_N = 45, cmdKey | controlKey = 256 | 4096
        RegisterEventHotKey(45, UInt32(cmdKey | controlKey), hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)

        // Install Carbon event handler for hotkey press
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, _, userData -> OSStatus in
            let delegate = Unmanaged<AppDelegate>.fromOpaque(userData!).takeUnretainedValue()
            delegate.togglePanel()
            return noErr
        }, 1, &eventType, Unmanaged.passUnretained(self).toOpaque(), nil)
    }

    // --- Toggle pinned mode ---
    @objc func togglePinned() {
        isPinned.toggle()
        let icon = isPinned ? "pin.fill" : "pin"
        titleButton.image = NSImage(systemSymbolName: icon, accessibilityDescription: "Pin")
        titleButton.contentTintColor = isPinned
            ? NSColor(white: 1.0, alpha: 0.8)
            : NSColor(white: 1.0, alpha: 0.2)
    }

    // --- Toggle: open or close ---
    @objc func togglePanel() {
        if panel.isVisible {
            closePanel(force: true)
        } else {
            // If the panel was just closed by the global monitor (clicking the icon
            // counts as a global click), don't reopen it immediately
            if Date().timeIntervalSince(lastCloseTime) < 0.3 { return }
            openPanel()
        }
    }

    // --- Open the panel ---
    func openPanel() {
        // Reload notes from file (in case they were added via CLI)
        if let saved = try? String(contentsOf: saveURL, encoding: .utf8) {
            textView.string = saved
        }

        // Position the panel just below the menu bar icon
        if let button = statusItem.button, let btnWindow = button.window {
            let buttonRect = btnWindow.convertToScreen(button.frame)
            let x = buttonRect.midX - panel.frame.width / 2
            let y = buttonRect.minY - panel.frame.height - 4
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        }

        // IMPORTANT ORDER:
        // 1. Activate app first (otherwise panel won't receive focus)
        // 2. Show the panel
        // 3. Give focus to textView

        // Switch icon to "folder.fill" when panel is open
        statusItem.button?.image = NSImage(
            systemSymbolName: "folder.fill",
            accessibilityDescription: "Notty"
        )

        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
        panel.makeFirstResponder(textView)

        // Listen for clicks outside to close the panel

        // Global: clicks in OTHER applications
        globalClickMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown]
        ) { [weak self] _ in
            self?.closePanel()
        }

        // Local: clicks in OUR app but outside the panel
        localClickMonitor = NSEvent.addLocalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown]
        ) { [weak self] event in
            guard let self = self else { return event }
            if event.window === self.panel { return event }  // click inside panel — let it through
            self.closePanel()
            return event
        }
    }

    // --- Close the panel (force: bypasses pinned mode, used by icon toggle) ---
    func closePanel(force: Bool = false) {
        if isPinned && !force { return }
        // Switch icon back to "folder" (closed)
        statusItem.button?.image = NSImage(
            systemSymbolName: "folder",
            accessibilityDescription: "Notty"
        )

        panel.orderOut(nil)
        lastCloseTime = Date()

        // Remove event monitors
        if let monitor = globalClickMonitor {
            NSEvent.removeMonitor(monitor)
            globalClickMonitor = nil
        }
        if let monitor = localClickMonitor {
            NSEvent.removeMonitor(monitor)
            localClickMonitor = nil
        }
    }

    // --- Auto-save to ~/.notty.txt ---
    @objc func textDidChange(_ notification: Notification) {
        try? textView.string.write(to: saveURL, atomically: true, encoding: .utf8)
    }
}

// --- CLI or GUI mode ---
// If arguments are passed -> terminal mode (no GUI)
// Otherwise -> launch the menu bar app

let saveURL = FileManager.default.homeDirectoryForCurrentUser
    .appendingPathComponent(".notty.txt")

let args = CommandLine.arguments

// First argument is always the binary path, we look from the 2nd one
if args.count > 1 {
    let command = args[1]

    switch command {

    // nt list — display all notes
    case "list", "ls":
        if let content = try? String(contentsOf: saveURL, encoding: .utf8) {
            print(content.isEmpty ? "(empty)" : content)
        } else {
            print("(no notes)")
        }

    // nt clear — clear all notes (with confirmation)
    case "clear":
        print("Are you sure? (yes/no) ", terminator: "")
        if let answer = readLine()?.lowercased(), answer == "yes" || answer == "y" {
            try? "".write(to: saveURL, atomically: true, encoding: .utf8)
            print("Notes cleared.")
        } else {
            print("Cancelled.")
        }

    // nt help
    case "help", "--help", "-h":
        print("""
        nt — Notty CLI

        Usage:
          nt / notty            Launch the menu bar app
          nt <text>             Add a note
          nt list               Display all notes
          nt clear              Clear all notes
          nt help               Show this help
        """)

    // nt <anything else> — add a note
    default:
        let note = args.dropFirst().joined(separator: " ")
        var current = (try? String(contentsOf: saveURL, encoding: .utf8)) ?? ""
        if !current.isEmpty && !current.hasSuffix("\n") {
            current += "\n"
        }
        current += note + "\n"
        try? current.write(to: saveURL, atomically: true, encoding: .utf8)
        print("+ \(note)")
    }

} else {
    // No arguments -> launch the GUI app
    let app = NSApplication.shared
    app.setActivationPolicy(.accessory)
    let delegate = AppDelegate()
    app.delegate = delegate
    app.run()
}
