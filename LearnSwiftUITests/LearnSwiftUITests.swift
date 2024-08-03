// Created by Tama Adhitya on 2024/08/02

import XCTest
import Combine
import ConcurrencyExtras

@testable import LearnSwiftUI

final class LearnSwiftUITests: XCTestCase {

    @MainActor
    func testBinding_shouldGetBarcodeResponse() async {
        await withMainSerialExecutor {
            let mockBarcodeRepository = MockBarcodeRepository()
            let response = BarcodeResponse(barcode: "barcode")
            mockBarcodeRepository.result = .success(response)

            let sut = BarcodeScreenViewModel(barcodeRepository: mockBarcodeRepository)

            Task { await sut.binding() }
            await Task.megaYield()
            sut.isUsingPayPayPoints = true
            await Task.megaYield()

            XCTAssertEqual(sut.barcodeResponse, BarcodeResponse(barcode: "barcode"))
            XCTAssertEqual(mockBarcodeRepository.getBarcodeCallCount, 2)
            XCTAssertEqual(mockBarcodeRepository.toggle, 1)
        }
    }

    @MainActor
    func testBinding_shouldChangeLoadingBarcodeState() async {
        let mockBarcodeRepository = MockBarcodeRepository()
        let response = BarcodeResponse(barcode: "barcode")
        mockBarcodeRepository.result = .success(response)
        let sut = BarcodeScreenViewModel(barcodeRepository: mockBarcodeRepository)

        let task = Task { await sut.binding() }

        await Task.yield()
        await Task.yield()
        await Task.yield()
        await Task.yield()
        await Task.yield()
        await Task.yield()
        XCTAssertTrue(sut.isLoadingBarcode)

        await task.value
        XCTAssertFalse(sut.isLoadingBarcode)
    }

    @MainActor
    func testBinding_whenIsUsingPayPayPointsChanged_shouldGetBarcode() async {
        let mockBarcodeRepository = MockBarcodeRepository()
        let response = BarcodeResponse(barcode: "barcode")
        mockBarcodeRepository.result = .success(response)

        let sut = BarcodeScreenViewModel(barcodeRepository: mockBarcodeRepository)

        await sut.binding()
        XCTAssertFalse(sut.isUsingPayPayPoints)
        XCTAssertEqual(mockBarcodeRepository.getBarcodeCallCount, 1)

        sut.isUsingPayPayPoints = true
        XCTAssertEqual(mockBarcodeRepository.getBarcodeCallCount, 2)

        sut.isUsingPayPayPoints = false
        XCTAssertEqual(mockBarcodeRepository.getBarcodeCallCount, 3)
    }
}

class MockBarcodeRepository: BarcodeRepository {
    var result: Result<BarcodeResponse, Error> = .failure(ErrorInTest.dummy)
    var getBarcodeCompletion: (() -> BarcodeResponse)?
    private(set) var getBarcodeCallCount = 0

    private(set) var toggle = 0

    func getBarcode() async throws -> BarcodeResponse {
        getBarcodeCallCount += 1

        getBarcodeCompletion?()
        switch result {
        case .success(let success):
            return success
        case .failure(let failure):
            throw failure
        }
    }

    func toggleUsingPayPayPoints(_ isUsingPayPayPoints: Bool) async throws {
        toggle += 1
    }
}

enum ErrorInTest: Error {
    case dummy
}
