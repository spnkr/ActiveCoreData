import Foundation

// public protocol CoreDataLoggable {
//     func log(_ message: String)
// }

public class CoreDataLogger {
    static let shared = CoreDataLogger()
    var logHandler: (String) -> Void = { _ in }
    
    // var delegate: CoreDataLoggable?
    
    func log(_ message: String) {
        // delegate?.log(message)
        logHandler(message)
    }
    //
    // public static func configure(logDelegate: CoreDataLoggable? = nil) {
    //     shared.delegate = logDelegate
    // }
    
    public static func configure(logHandler: @escaping (String) -> Void) {
        shared.logHandler = logHandler
    }
    
}
