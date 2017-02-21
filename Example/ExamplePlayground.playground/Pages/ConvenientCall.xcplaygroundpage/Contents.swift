import UIKit
import PlaygroundSupport
import Endpoints
import ExampleCore
import Unbox
PlaygroundPage.current.needsIndefiniteExecution = true

struct RandomImage: UnboxableParser {
    var url: URL
    
    init(unboxer: Unboxer) throws {
        url = try unboxer.unbox(keyPath: "data.image_url")
    }
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
        let url = value.url
        print("image url: \(url)")
    }
    
    PlaygroundPage.current.finishExecution()
}
