import Foundation

open class ConsoleModuleLogger: ModuleLoggerProtocol {
    
    /// Logs messages from modules.
    ///
    /// This method prints all logs to the console.
    ///
    ///     """
    ///     This method prints something like:
    ///
    ///     [ModuleLogger 10:06:32 PM] <info> Main: loaded into memory.
    ///     [ModuleLogger 10:06:32 PM] <warning> Main: has no builder to create a child module.
    ///     """
    ///
    public final func log(_ message: String, level: Level, from module: String) -> Void {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        let time = formatter.string(from: Date())
        print("[ModuleLogger \(time)] <\(level)> \(module): \(message).")
    }
    
    public init() {}
    
}
