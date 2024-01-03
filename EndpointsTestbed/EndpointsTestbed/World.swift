import Endpoints
import Foundation

let world = World()
struct World {
    let postmanSession: AsyncSession<PostmanEchoClient>
    let httpBinSession: AsyncSession<HTTPBinClient>
    let manipulatedHttpBinSession: AsyncSession<ManipulatedHTTPBinClient>

    init() {
        let postmanClient = PostmanEchoClient()
        postmanSession = AsyncSession(with: postmanClient)

        let httpBinClient = HTTPBinClient()
        httpBinSession = AsyncSession(with: httpBinClient)

        let manipulatedHttpBinClient = ManipulatedHTTPBinClient()
        manipulatedHttpBinSession = AsyncSession(with: manipulatedHttpBinClient)
    }
}
