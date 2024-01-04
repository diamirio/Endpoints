import AsyncReactor
import SwiftUI

@main
struct EndpointsTestbedApp: App {
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
