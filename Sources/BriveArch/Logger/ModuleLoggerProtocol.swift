public protocol ModuleLoggerProtocol: AnyObject {
    
    typealias LogLevel = RootModule.LogLevel
    
    func log(_ message: String, level: LogLevel, from module: String) -> Void
    
}
