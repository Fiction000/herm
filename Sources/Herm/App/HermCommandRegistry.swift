import SwiftUI

struct HermCommand: Identifiable {
    enum ID: String, CaseIterable, Hashable {
        case settings
        case commandPalette
        case back
        case forward
        case newChat
        case stopGeneration
    }

    enum Scope: Hashable {
        case application
        case workspace
    }

    enum Menu: String, CaseIterable, Identifiable {
        case file = "File"
        case view = "View"
        case go = "Go"
        case session = "Session"

        var id: String { rawValue }
    }

    let id: ID
    let title: String
    let key: KeyEquivalent?
    let modifiers: EventModifiers
    let scope: Scope
    let menu: Menu

    static let all: [HermCommand] = [
        HermCommand(id: .settings, title: "Settings…", key: ",", modifiers: .command, scope: .application, menu: .file),
        HermCommand(
            id: .commandPalette, title: "Command palette", key: "k", modifiers: .command, scope: .workspace, menu: .view
        ),
        HermCommand(id: .back, title: "Back", key: "[", modifiers: .command, scope: .workspace, menu: .go),
        HermCommand(id: .forward, title: "Forward", key: "]", modifiers: .command, scope: .workspace, menu: .go),
        HermCommand(id: .newChat, title: "New chat", key: "n", modifiers: .command, scope: .workspace, menu: .file),
        HermCommand(
            id: .stopGeneration, title: "Stop generation", key: ".", modifiers: .command, scope: .workspace,
            menu: .session),
    ]

    var shortcut: KeyboardShortcut? { key.map { KeyboardShortcut($0, modifiers: modifiers) } }
}

@MainActor
final class DockActionPalettePresentation: ObservableObject {
    @Published private(set) var isPresented = false
    var actionHandler: ((DockAction) -> Void)?
    var pendingAction: DockAction?

    func present() { isPresented = true }

    func dismiss() { isPresented = false }

    func installActionHandler(_ handler: @escaping (DockAction) -> Void) {
        actionHandler = handler
        guard let pendingAction else { return }
        self.pendingAction = nil
        handler(pendingAction)
    }
}

@MainActor
struct HermCommandHandlers {
    let openSettings: () -> Void
    let openCommandPalette: () -> Void
    let goBack: () -> Void
    let goForward: () -> Void
    let newChat: () -> Void
    let stopGeneration: () -> Void

    func perform(_ command: HermCommand.ID) {
        switch command {
        case .settings: openSettings()
        case .commandPalette: openCommandPalette()
        case .back: goBack()
        case .forward: goForward()
        case .newChat: newChat()
        case .stopGeneration: stopGeneration()
        }
    }
}

private struct HermCommandHandlersKey: FocusedValueKey {
    typealias Value = HermCommandHandlers
}

extension FocusedValues {
    var hermCommandHandlers: HermCommandHandlers? {
        get { self[HermCommandHandlersKey.self] }
        set { self[HermCommandHandlersKey.self] = newValue }
    }
}

enum HermCommandRegistry {
    static func commands(in menu: HermCommand.Menu) -> [HermCommand] {
        HermCommand.all.filter { $0.menu == menu }
    }

    static var paletteCommands: [HermCommand] { HermCommand.all }

    static func command(_ id: HermCommand.ID) -> HermCommand {
        guard let command = HermCommand.all.first(where: { $0.id == id }) else {
            preconditionFailure("Missing Herm command: \(id.rawValue)")
        }
        return command
    }
}

struct HermCommandMenus: Commands {
    @FocusedValue(\.hermCommandHandlers) private var handlers
    let openSettings: () -> Void

    var body: some Commands {
        CommandMenu(HermCommand.Menu.file.rawValue) {
            commandButtons(in: .file)
        }
        CommandMenu(HermCommand.Menu.view.rawValue) {
            commandButtons(in: .view)
        }
        CommandMenu(HermCommand.Menu.go.rawValue) {
            commandButtons(in: .go)
        }
        CommandMenu(HermCommand.Menu.session.rawValue) {
            commandButtons(in: .session)
        }
    }

    @ViewBuilder
    private func commandButtons(in menu: HermCommand.Menu) -> some View {
        ForEach(HermCommandRegistry.commands(in: menu)) { command in
            commandButton(command) {
                if command.id == .settings { openSettings() } else { handlers?.perform(command.id) }
            }
        }
    }

    @ViewBuilder
    private func commandButton(_ command: HermCommand, action: @escaping () -> Void) -> some View {
        if let shortcut = command.shortcut {
            Button(command.title, action: action).keyboardShortcut(shortcut)
        } else {
            Button(command.title, action: action)
        }
    }
}

extension HermCommand {
    var keycap: String {
        var symbols = ""
        if modifiers.contains(.command) { symbols += "⌘" }
        if modifiers.contains(.shift) { symbols += "⇧" }
        if modifiers.contains(.option) { symbols += "⌥" }
        if modifiers.contains(.control) { symbols += "⌃" }
        let keyText = key.map { $0 == "," ? "," : String($0.character).uppercased() } ?? ""
        return symbols + keyText
    }
}
