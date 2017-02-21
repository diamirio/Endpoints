import UIKit
import PlaygroundSupport
import Endpoints
import ExampleCore
PlaygroundPage.current.needsIndefiniteExecution = true


let client = AnyClient(baseURL: URL(string: "https://api.giphy.com/v1/")!)
let call = AnyCall<[String: Any]>(Request(.get, "gifs/random", query: [ "tag": "cat", "api_key": "dc6zaTOxFJmzC" ]))
let session = Session(with: client)

session.start(call: call) { result in
    result.onSuccess { dict in
        print(dict)
        if let data = dict["data"] as? [String : Any], let url = data["image_url"] as? String {
            print("image url: \(url)")
        }
    }
    
    PlaygroundPage.current.finishExecution()
}