import AsyncReactor
import SwiftUI

struct ExampleReactorView: View {
    @EnvironmentObject var reactor: ExampleReactor

    var body: some View {
        VStack {
            if reactor.state.text.isEmpty {
                ProgressView()
            } else {
                Text(reactor.state.text)
                    .font(.headline)
            }
        }
        .onAppear {
            reactor.send(.executeRequests)
        }
    }
}

#Preview {
    ReactorView(ExampleReactor()) {
        ExampleReactorView()
    }
}
