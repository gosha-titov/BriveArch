import Foundation

open class ConsoleModuleLogger: ModuleLoggerProtocol {
    
    public var lowLogLevel: LogLevel = .debug
    
    /// Logs messages from modules.
    ///
    /// This method prints all logs to the console.
    ///
    ///     """
    ///     This method prints something like:
    ///
    ///     [ModuleLogger 10:06:32 PM] <debug> Main: loaded into memory.
    ///     [ModuleLogger 10:06:32 PM] <debug> Main: started working.
    ///     [ModuleLogger 10:06:37 PM] <error> Main: has no builder to create a child module.
    ///     """
    ///
    public final func log(_ message: String, level: LogLevel, from module: String) -> Void {
        guard level.rawValue >= lowLogLevel.rawValue else { return }
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        let time = formatter.string(from: Date())
        print("[ModuleLogger \(time)] <\(level)> \(module): \(message).")
    }
    
    public init() {}
    
}
