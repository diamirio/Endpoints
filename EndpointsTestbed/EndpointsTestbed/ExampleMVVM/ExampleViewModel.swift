import Endpoints
import Foundation

@MainActor
class ExampleViewModel: ObservableObject {
    @Published var text: String = ""

    func executeRequests() {
        Task {
            let (body, response) = try await world.postmanSession.start(call: PostmanEchoClient.ExampleGetCall())
            guard response.statusCode == 200 else { return }
            self.text = body.url
        }

        Task {
            let (_, response) = try await world.manipulatedHttpBinSession.start(call: ManipulatedHTTPBinClient.GetStatusCode(deliveredStatusCode: 220))
            guard response.statusCode == 200 else { return }
            print("Success")
        }
    }
}
