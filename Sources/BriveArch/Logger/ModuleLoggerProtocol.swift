public protocol ModuleLoggerProtocol: AnyObject {
    
    typealias Level = RootModule.LogLevel
    
    func log(_ message: String, level: Level, from module: String) -> Void
    
}
