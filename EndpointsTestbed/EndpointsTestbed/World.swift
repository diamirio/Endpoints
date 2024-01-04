import Endpoints
import Foundation

let world = World()
struct World {
	let postmanSession: AsyncSession<PostmanEchoClient>
	let httpBinSession: AsyncSession<HTTPBinClient>
	let manipulatedHttpBinSession: AsyncSession<ManipulatedHTTPBinClient>

	init() {
		let postmanClient = PostmanEchoClient()
		self.postmanSession = AsyncSession(with: postmanClient)

		let httpBinClient = HTTPBinClient()
		self.httpBinSession = AsyncSession(with: httpBinClient)

		let manipulatedHttpBinClient = ManipulatedHTTPBinClient()
		self.manipulatedHttpBinSession = AsyncSession(with: manipulatedHttpBinClient)
	}
}
