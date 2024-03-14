import Endpoints
import Foundation

@MainActor
class ExampleViewModel: ObservableObject {
    @Published
    var text: String = ""

    func executeRequests() {
        Task {
            let (body, response) = try await world.postmanSession.dataTask(
                for: PostmanEchoClient.ExampleGetCall()
            )
            guard response.statusCode == 200 else { return }

            await MainActor.run {
                self.text = body.url
            }
        }

        Task {
            let (_, response) = try await world.manipulatedHttpBinSession.dataTask(
                for: ManipulatedHTTPBinClient.GetStatusCode(deliveredStatusCode: 220)
            )
            guard response.statusCode == 200 else { return }
            print("Success")
        }
    }
}
