import AsyncReactor
import Endpoints
import Foundation

class ExampleReactor: AsyncReactor {
    enum Action {
        case executeRequests
    }

    struct State {
        var text = ""
    }

    @Published
    private(set) var state = State()

    func action(_ action: Action) async {
        switch action {
        case .executeRequests:
            await executeRequest()
        }
    }

    private func executeRequest() async {
        do {
            let (body, response) = try await world.postmanSession.dataTask(
                for: PostmanEchoClient.ExampleGetCall()
            )

            guard response.statusCode == 200 else { return }

            await MainActor.run {
                state.text = body.url
            }
        }
        catch {
            guard let error = error as? EndpointsError else { return }
            print(error.response?.statusCode ?? "")
        }
    }
}
