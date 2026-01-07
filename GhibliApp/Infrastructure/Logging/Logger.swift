import os

struct Logger {
    private let logger = os.Logger(subsystem: "dev.ghibli.app", category: "app")

    func log(_ message: String) {
        logger.log("\(message, privacy: .public)")
    }

    func error(_ message: String) {
        logger.error("\(message, privacy: .public)")
    }
}
