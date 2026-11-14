import Testing

@testable import Herm

struct HermCommandRegistryTests {
    @Test func noCommandsShareAKeyEquivalentWithinAScope() {
        let assignments = HermCommand.all.map { command in
            guard let key = command.key else { return "missing:\(command.id)" }
            return "\(command.scope):\(key.character):\(command.modifiers)"
        }
        #expect(Set(assignments).count == assignments.count)
    }

    @Test func everyCommandAppearsInAMenuAndThePalette() {
        let menuIDs = HermCommand.Menu.allCases.flatMap { HermCommandRegistry.commands(in: $0).map(\.id) }
        let paletteIDs = HermCommandRegistry.paletteCommands.map(\.id)
        let commandIDs = HermCommand.all.map(\.id)
        #expect(menuIDs.count == commandIDs.count)
        #expect(Set(menuIDs) == Set(commandIDs))
        #expect(paletteIDs == commandIDs)
        #expect(HermCommand.Menu.allCases.map(\.rawValue) == ["File", "View", "Session", "Go"])
    }

    @Test func paletteLabelsUseTheRegisteredKeyEquivalents() {
        #expect(HermCommandRegistry.paletteCommands.map(\.keycap) == ["⌘,", "⌘K", "⌘[", "⌘]"])
    }
}
