import Foundation

public class CoreDataLogger {
    static let shared = CoreDataLogger()
    var logHandler: (String) -> Void = { _ in }
    
    func log(_ message: String) {
        logHandler(message)
    }
    
    public static func configure(logHandler: @escaping (String) -> Void) {
        shared.logHandler = logHandler
    }
    
}
