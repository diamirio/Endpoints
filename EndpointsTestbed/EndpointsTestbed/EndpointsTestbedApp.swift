import AsyncReactor
import SwiftUI

@main
struct EndpointsTestbedApp: App {
    init() {
        DI.register()
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                List {
                    Section {
                        NavigationLink("MVVM", destination: ExampleView())
                        NavigationLink("AsyncReactor", destination: ReactorView(ExampleReactor()) {
                            ExampleReactorView()
                        })
                    }
                }
            }
        }
    }
}
