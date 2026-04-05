import SwiftUI

@main
struct ArrowPrecisionEvaluatorApp: App {
    @StateObject private var environment = AppEnvironment()

    var body: some Scene {
        WindowGroup {
            // RootView observes flowViewModel directly so NavigationStack reacts
            // immediately when the path changes from nested views.
            RootView(flowViewModel: environment.flowViewModel)
                .environmentObject(environment)
        }
    }
}
