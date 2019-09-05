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

protocol GiphyCall: Call {}

extension GiphyCall {
    func start(completion: @escaping (Result<ResponseType.OutputType>)->()) {
        let client = GiphyClient()
        let session = Session(with: client)
        
        session.start(call: self, completion: completion)
    }
}

extension GiphyClient {
    struct RandomCall: GiphyCall {
        typealias ResponseType = RandomImage
        
        var tag: String
        
        var request: URLRequestEncodable {
            return Request(.get, "gifs/random", query: [ "tag": tag ]) //API-Key handled by client
        }
    }
}

GiphyClient.RandomCall(tag: "cat").start { result in
    result.onSuccess { value in
        let url = value.data.url
        print("image url: \(url)")
    }
    
    PlaygroundPage.current.finishExecution()
}
