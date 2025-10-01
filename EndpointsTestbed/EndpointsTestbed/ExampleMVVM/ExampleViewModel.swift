import Endpoints
import Foundation
import Injection

@MainActor
class ExampleViewModel: ObservableObject {
    @Published
    var text: String = ""

    @Inject
    var postmanSession: Session<PostmanEchoClient>

    @Inject
    var manipulatedHttpBinSession: Session<ManipulatedHTTPBinClient>

    func executeRequests() {
        Task {
            let (body, response) = try await postmanSession.dataTask(
                for: PostmanEchoClient.ExampleGetCall()
            )
            guard response.statusCode == 200 else { return }

            await MainActor.run {
                self.text = body.url
            }
        }

        Task {
            let (_, response) = try await manipulatedHttpBinSession.dataTask(
                for: ManipulatedHTTPBinClient.GetStatusCode(deliveredStatusCode: 220)
            )
            guard response.statusCode == 200 else { return }
            print("Success")
        }
    }
}
