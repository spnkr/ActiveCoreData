import Foundation
import CoreData

public class ActiveCoreDataLogger {
    static let shared = ActiveCoreDataLogger()
    var logHandler: (String) -> Void = { _ in }
    
    func log(_ message: String) {
        logHandler(message)
    }
    
    public static func configure(logHandler: @escaping (String) -> Void) {
        shared.logHandler = logHandler
    }
    
}
