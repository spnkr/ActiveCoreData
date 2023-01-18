import Foundation

internal enum InternalError: Error, LocalizedError {
    case setupAlreadyCalled
    case setupNotCalled
    
    case noBackground
    case noForeground
    
    public var errorDescription: String? {
        switch self {
        case .noBackground:
            return "No background context specified. Use .setup with a backgroundContext: parameter."
        case .noForeground:
            return "No foreground context (view context) specified. Use .setup with a viewContext: parameter."
        default:
            return "\(self)"
        }
    }
}
