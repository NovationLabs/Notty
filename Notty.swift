import Cocoa

// --- Sous-classe de NSPanel ---
// Par défaut, un NSPanel borderless ne peut PAS devenir "key window",
// ce qui empêche le clavier de fonctionner dans le textView.
// On override canBecomeKey pour forcer true.
class NotePanel: NSPanel {
    override var canBecomeKey: Bool {
        return true
    }

    // Zone de resize : uniquement les 4 coins (12x12 pixels)
    let cornerSize: CGFloat = 12

    override func mouseDown(with event: NSEvent) {
        let loc = event.locationInWindow
        let f = frame
        // Vérifier si le clic est dans un des 4 coins
        let inBottomLeft  = loc.x < cornerSize && loc.y < cornerSize
        let inBottomRight = loc.x > f.width - cornerSize && loc.y < cornerSize
        let inTopLeft     = loc.x < cornerSize && loc.y > f.height - cornerSize
        let inTopRight    = loc.x > f.width - cornerSize && loc.y > f.height - cornerSize

        if inBottomLeft || inBottomRight || inTopLeft || inTopRight {
            // Resize depuis le coin
            performResize(from: event)
        } else {
            super.mouseDown(with: event)
        }
    }

    // Resize manuel car le panel est borderless (pas de resize handle natif)
    func performResize(from startEvent: NSEvent) {
        let startFrame = frame
        let startLoc = NSEvent.mouseLocation

        // Boucle de drag pour le resize (coin bas-droit = standard)
        while true {
            guard let event = nextEvent(matching: [.leftMouseDragged, .leftMouseUp]) else { break }
            if event.type == .leftMouseUp { break }

            let currentLoc = NSEvent.mouseLocation
            let dx = currentLoc.x - startLoc.x
            let dy = currentLoc.y - startLoc.y

            // Resize depuis le coin bas-droit : largeur + dx, hauteur - dy, origin.y + dy
            var newWidth = startFrame.width + dx
            var newHeight = startFrame.height - dy
            // Taille minimum
            newWidth = max(newWidth, 200)
            newHeight = max(newHeight, 200)

            let newOriginY = startFrame.origin.y + (startFrame.height - newHeight)
            setFrame(NSRect(x: startFrame.origin.x, y: newOriginY, width: newWidth, height: newHeight), display: true)
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {

    // L'icône dans la barre des menus
    var statusItem: NSStatusItem!

    // Le panel qui s'ouvre quand on clique (NotePanel, pas NSPanel)
    var panel: NotePanel!

    // La zone de texte
    var textView: NSTextView!

    // Monitors pour détecter les clics en dehors du panel
    var globalClickMonitor: Any?     // clics dans les AUTRES apps
    var localClickMonitor: Any?      // clics dans NOTRE app (hors panel)

    // Fichier où on sauvegarde le texte
    let saveURL = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".notty.txt")

    func applicationDidFinishLaunching(_ notification: Notification) {

        // --- 1. Créer l'icône dans la barre des menus ---
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

        // --- 2. Créer le panel ---
        // IMPORTANT : PAS de .nonactivatingPanel !
        // .nonactivatingPanel empêche l'app de s'activer, ce qui bloque
        // l'ouverture du panel quand une autre app est au premier plan
        // ET empêche le clavier de fonctionner.
        panel = NotePanel(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 400),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        panel.level = .popUpMenu
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hidesOnDeactivate = false          // on gère la fermeture nous-mêmes
        panel.isReleasedWhenClosed = false        // évite un crash si on ré-ouvre
        panel.isFloatingPanel = true              // reste au-dessus des autres fenêtres
        panel.collectionBehavior = [
            .canJoinAllSpaces,                   // visible sur tous les Spaces/bureaux
            .fullScreenAuxiliary                 // visible même en fullscreen
        ]

        // --- 3. Container avec fond sombre et coins arrondis ---
        let container = NSView(frame: NSRect(x: 0, y: 0, width: 320, height: 400))
        container.wantsLayer = true
        container.layer?.backgroundColor = NSColor(white: 0.12, alpha: 0.95).cgColor
        container.layer?.cornerRadius = 12
        container.layer?.borderWidth = 1
        container.layer?.borderColor = NSColor(white: 1.0, alpha: 0.08).cgColor
        container.autoresizingMask = [.width, .height]   // s'adapte quand le panel est resizé

        // --- 4. Titre "Notty" en haut ---
        let title = NSTextField(labelWithString: "Notty")
        title.frame = NSRect(x: 16, y: 365, width: 200, height: 24)
        title.font = NSFont(name: "Space Mono", size: 14)
            ?? NSFont.monospacedSystemFont(ofSize: 14, weight: .bold)
        title.textColor = NSColor(white: 1.0, alpha: 0.5)
        title.autoresizingMask = [.minYMargin]           // reste collé en haut
        container.addSubview(title)

        // --- 5. Zone de texte avec scroll ---
        let scrollView = NSScrollView(frame: NSRect(x: 12, y: 12, width: 296, height: 345))
        scrollView.autoresizingMask = [.width, .height]  // s'adapte au resize
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
        panel.contentView = container

        // --- 6. Charger le texte sauvegardé ---
        if let saved = try? String(contentsOf: saveURL, encoding: .utf8) {
            textView.string = saved
        }

        // --- 7. Sauvegarder automatiquement à chaque modification ---
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(textDidChange),
            name: NSText.didChangeNotification,
            object: textView
        )
    }

    // --- Toggle : ouvrir ou fermer ---
    @objc func togglePanel() {
        if panel.isVisible {
            closePanel()
        } else {
            openPanel()
        }
    }

    // --- Ouvrir le panel ---
    func openPanel() {
        // Positionner le panel juste en-dessous de l'icône
        if let button = statusItem.button, let btnWindow = button.window {
            let buttonRect = btnWindow.convertToScreen(button.frame)
            let x = buttonRect.midX - panel.frame.width / 2
            let y = buttonRect.minY - panel.frame.height - 4
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        }

        // ORDRE IMPORTANT :
        // 1. Activer l'app d'abord (sinon le panel ne reçoit pas le focus)
        // 2. Afficher le panel
        // 3. Donner le focus au textView
        // Changer l'icône en "folder.fill" quand le panel est ouvert
        statusItem.button?.image = NSImage(
            systemSymbolName: "folder.fill",
            accessibilityDescription: "Notty"
        )

        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
        panel.makeFirstResponder(textView)

        // Écouter les clics en dehors pour fermer le panel

        // Global : clics dans les AUTRES applications
        globalClickMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown]
        ) { [weak self] _ in
            self?.closePanel()
        }

        // Local : clics dans NOTRE app mais en dehors du panel
        localClickMonitor = NSEvent.addLocalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown]
        ) { [weak self] event in
            guard let self = self else { return event }
            if event.window === self.panel { return event }  // clic dans le panel → on laisse passer
            self.closePanel()
            return event
        }
    }

    // --- Fermer le panel ---
    func closePanel() {
        // Remettre l'icône "folder" (fermé)
        statusItem.button?.image = NSImage(
            systemSymbolName: "folder",
            accessibilityDescription: "Notty"
        )

        panel.orderOut(nil)

        // Retirer les monitors
        if let monitor = globalClickMonitor {
            NSEvent.removeMonitor(monitor)
            globalClickMonitor = nil
        }
        if let monitor = localClickMonitor {
            NSEvent.removeMonitor(monitor)
            localClickMonitor = nil
        }
    }

    // --- Sauvegarde auto dans ~/.notty.txt ---
    @objc func textDidChange(_ notification: Notification) {
        try? textView.string.write(to: saveURL, atomically: true, encoding: .utf8)
    }
}

// --- Lancement ---
let app = NSApplication.shared
app.setActivationPolicy(.accessory)     // pas d'icône dans le Dock
let delegate = AppDelegate()
app.delegate = delegate
app.run()
