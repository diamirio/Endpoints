import UIKit
import PlaygroundSupport
import Endpoints
import ExampleCore
import Unbox
PlaygroundPage.current.needsIndefiniteExecution = true

struct RandomImage: Unboxable, ResponseDecodable {
    var url: URL
    
    init(unboxer: Unboxer) throws {
        url = try unboxer.unbox(keyPath: "data.image_url")
    }
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
        let url = value.url
        print("image url: \(url)")
    }
    
    PlaygroundPage.current.finishExecution()
}
