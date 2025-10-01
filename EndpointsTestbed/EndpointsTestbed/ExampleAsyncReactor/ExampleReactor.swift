import AsyncReactor
import Endpoints
import Foundation
import Injection

class ExampleReactor: AsyncReactor {
    enum Action {
        case executeRequests
    }

    struct State {
        var text = ""
    }

    @Published
    private(set) var state = State()

    @Inject
    var postmanSession: Session<PostmanEchoClient>

    func action(_ action: Action) async {
        switch action {
        case .executeRequests:
            await executeRequest()
        }
    }

    private func executeRequest() async {
        do {
            let (body, response) = try await postmanSession.dataTask(
                for: PostmanEchoClient.ExampleGetCall()
            )

            guard response.statusCode == 200 else { return }
            state.text = body.url
        } catch {
            guard let error = error as? EndpointsError else { return }
            print(error.response?.statusCode ?? "")
        }
    }
}
