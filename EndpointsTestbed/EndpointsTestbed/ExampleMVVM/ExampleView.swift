import SwiftUI

struct ExampleView: View {
    @StateObject var viewModel = ExampleViewModel()

    var body: some View {
        VStack {
            if viewModel.text.isEmpty {
                ProgressView()
            }
            else {
                Text(viewModel.text)
                    .font(.headline)
            }
        }
        .onAppear {
            viewModel.executeRequests()
        }
    }
}

struct ExampleView_Previews: PreviewProvider {
    static var previews: some View {
        ExampleView()
    }
}
