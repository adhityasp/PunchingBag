import SwiftUI

struct ContentView: View {
    @StateObject var viewModel = BarcodeScreenViewModel()

    var body: some View {
        VStack {
            Text(viewModel.barcodeResponse?.barcode ?? "")
            Toggle("Use PayPay Points", isOn: $viewModel.isUsingPayPayPoints)
        }
        .task { await viewModel.binding() }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct BarcodeResponse: Equatable {
    let barcode: String
}

protocol BarcodeRepository {
    func getBarcode() async throws -> BarcodeResponse
    func toggleUsingPayPayPoints(_ isUsingPayPayPoints: Bool) async throws
}

struct DefaultBarcodeRepository: BarcodeRepository {

    static var counter = 0
    func getBarcode() async throws -> BarcodeResponse {
        try await Task.sleep(nanoseconds: UInt64.random(in: 1_000_000_000...2_000_000_000))
        DefaultBarcodeRepository.counter += 1
        return BarcodeResponse(barcode: "Barcode \(DefaultBarcodeRepository.counter)")
    }

    func toggleUsingPayPayPoints(_ isUsingPayPayPoints: Bool) async throws {
        try await Task.sleep(nanoseconds: UInt64.random(in: 0...1_000_000_000))
    }
}

@MainActor
final class BarcodeScreenViewModel: ObservableObject {

    @Published private(set) var barcodeResponse: BarcodeResponse?
    @Published private(set) var isLoadingBarcode = false
    @Published var isUsingPayPayPoints = false

    private let barcodeRepository: BarcodeRepository

    init(barcodeRepository: BarcodeRepository = DefaultBarcodeRepository()) {
        self.barcodeRepository = barcodeRepository
    }

    private func getBarcode() async {
        isLoadingBarcode = true
        defer { isLoadingBarcode = false }
        do {
            barcodeResponse = try await barcodeRepository.getBarcode()
        } catch {
            // handle error
        }
    }

    private func toggleUsingPayPayPoints(_ isUsingPayPayPoints: Bool) async {
        do {
            try await barcodeRepository.toggleUsingPayPayPoints(isUsingPayPayPoints)
        } catch {
            // handle error
        }
        await getBarcode()
    }

    func binding() async {
        await withTaskGroup(of: Void.self) {
            $0.addTask {
                await self.getBarcode()
            }

            $0.addTask {
                let isUsingPayPayPoints = await self.$isUsingPayPayPoints
                    .dropFirst()
                    .removeDuplicates()
                    .values

                for await isUsingPayPayPoints in isUsingPayPayPoints {
                    await self.toggleUsingPayPayPoints(isUsingPayPayPoints)
                }
            }
        }
    }
}
