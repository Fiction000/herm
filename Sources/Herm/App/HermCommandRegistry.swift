import SwiftUI

struct HermCommand: Identifiable {
    enum ID: String, CaseIterable, Hashable {
        case settings
        case commandPalette
        case back
        case forward
    }

    enum Scope: Hashable {
        case application
        case workspace
    }

    enum Menu: String, CaseIterable, Identifiable {
        case file = "File"
        case view = "View"
        case go = "Go"

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
    ]

    var shortcut: KeyboardShortcut? { key.map { KeyboardShortcut($0, modifiers: modifiers) } }
}

@MainActor
struct HermCommandHandlers {
    let openSettings: () -> Void
    let openCommandPalette: () -> Void
    let goBack: () -> Void
    let goForward: () -> Void

    func perform(_ command: HermCommand.ID) {
        switch command {
        case .settings: openSettings()
        case .commandPalette: openCommandPalette()
        case .back: goBack()
        case .forward: goForward()
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

struct HermCommandPalette: View {
    let handlers: HermCommandHandlers
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        DockModal(title: "Command palette", subtitle: "Workspace commands", width: 420, contentPadding: 16) {
            VStack(spacing: 4) {
                ForEach(HermCommandRegistry.paletteCommands) { command in
                    Button {
                        handlers.perform(command.id)
                        dismiss()
                    } label: {
                        HStack {
                            Text(command.title).dockFont(.navigation, weight: .medium)
                            Spacer()
                            Text(command.keycap).dockFont(.metadata)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .dockPadding(.horizontal, 8)
                        .dockPadding(.vertical, 7)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.dockPress)
                }
            }
        }
    }
}
