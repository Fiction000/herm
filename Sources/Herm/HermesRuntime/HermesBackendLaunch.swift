import Foundation

enum HermesBackendLaunch {
    static let serveCommand = ["/usr/bin/env", "hermes", "serve", "--host", "127.0.0.1", "--port", "0"]

    static func process(command: [String] = serveCommand) -> Process {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: command[0])
        process.arguments = Array(command.dropFirst())
        return process
    }
}
