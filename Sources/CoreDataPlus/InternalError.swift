import Foundation

internal enum InternalError: Error, LocalizedError {
    case setupAlreadyCalled
    case setupNotCalled
    
    case noBackground
    
    public var errorDescription: String? {
        switch self {
        case .noBackground:
            return "No background context specified. Use .setup with a backgroundContext: parameter."
        default:
            return "\(self)"
        }
    }
}
