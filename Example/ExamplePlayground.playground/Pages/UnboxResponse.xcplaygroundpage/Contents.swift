import UIKit
import PlaygroundSupport
import Endpoints
import ExampleCore
PlaygroundPage.current.needsIndefiniteExecution = true

struct RandomImage: DecodableParser, Response {
    struct Data: Decodable {
        let url: URL

        private enum CodingKeys: String, CodingKey {
            case url = "image_url"
        }
    }

    let data: Data
}

struct RandomCall: Call {
    typealias ResponseType = RandomImage
    
    var tag: String
    
    var request: URLRequestEncodable {
        return Request(.get, "gifs/random", query: [ "tag": tag ]) //API-Key handled by client
    }
}

let client = GiphyClient()
client.apiKey = "dc6zaTOxFJmzC"

let call = RandomCall(tag: "cat")
let session = Session(with: client)

session.start(call: call) { result in
    result.onSuccess { value in
        let url = value.data.url
        print("image url: \(url)")
    }
    
    PlaygroundPage.current.finishExecution()
}
