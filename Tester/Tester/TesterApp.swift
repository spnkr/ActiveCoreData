import Foundation
import ActiveCoreData
import SwiftUI
import CoreData

@main
struct TesterApp: App {
	@UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
	
	private let viewContext = DataStore.shared.viewContext
	
    var body: some Scene {
        WindowGroup {
            ContentView()
				.environment(\.managedObjectContext, viewContext)
			
        }
    }
}



class AppDelegate: NSObject, UIApplicationDelegate {
	var window: UIWindow?
	
	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
		
		return true
	}
	func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
		Monitor.shared.doSomething()
		completionHandler(.newData)
	}
}
