import Endpoints
import Foundation

let world = World()
struct World {
	let postmanSession: Session<PostmanEchoClient>
	let httpBinSession: Session<HTTPBinClient>
	let manipulatedHttpBinSession: Session<ManipulatedHTTPBinClient>

	init() {
		let postmanClient = PostmanEchoClient()
		self.postmanSession = Session(with: postmanClient)

		let httpBinClient = HTTPBinClient()
		self.httpBinSession = Session(with: httpBinClient)

		let manipulatedHttpBinClient = ManipulatedHTTPBinClient()
		self.manipulatedHttpBinSession = Session(with: manipulatedHttpBinClient)
	}
}
