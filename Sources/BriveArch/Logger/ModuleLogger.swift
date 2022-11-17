import Foundation

open class ModuleLogger {
    
    public enum LogLevel: Int {
        case debug, info, warning, error, fatal
    }
    
    /// Logs messages from modules.
    ///
    /// This method prints all logs to the console.
    ///
    ///     """
    ///     This method prints something like:
    ///
    ///     [ModuleLogger 10:06:32 PM] <debug> Main(Module): loaded into memory.
    ///     [ModuleLogger 10:06:32 PM] <debug> Main(Module): started working.
    ///     ...
    ///     [ModuleLogger 10:06:37 PM] <error> Main(Module): cannot stop the 'Messages' child module because there is no created child module with that name.
    ///
    ///     """
    ///
    open func log(_ message: String, level: LogLevel, from module: String) -> Void {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        let time = formatter.string(from: Date())
        print("[Logger \(time)] <\(level)> \(module)(Module): \(message).")
    }
    
}
