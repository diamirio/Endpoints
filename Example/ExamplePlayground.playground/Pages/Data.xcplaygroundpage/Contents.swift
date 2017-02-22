import UIKit
import PlaygroundSupport
import Endpoints
import ExampleCore
import Unbox
PlaygroundPage.current.needsIndefiniteExecution = true


let client = AnyClient(baseURL: URL(string: "https://api.giphy.com/v1/")!)
let call = AnyCall<Data>(Request(.get, "gifs/random", query: [ "tag": "cat", "api_key": "dc6zaTOxFJmzC" ]))
let session = Session(with: client)

session.debug = true

session.start(call: call) { result in
    PlaygroundPage.current.finishExecution()
}
