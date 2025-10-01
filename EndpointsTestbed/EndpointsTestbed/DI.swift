import Endpoints
import Foundation
import Injection

@MainActor
enum DI {
    static func register() {
        let postmanSession = Session(with: PostmanEchoClient())
        DependencyInjector.register(postmanSession)

        let httpBinSession = Session(with: HTTPBinClient())
        DependencyInjector.register(httpBinSession)

        let manipulatedHttpBinSession = Session(with: ManipulatedHTTPBinClient())
        DependencyInjector.register(manipulatedHttpBinSession)
    }
}
