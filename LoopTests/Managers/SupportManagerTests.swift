//
//  SupportManagerTests.swift
//  LoopTests
//
//  Created by Rick Pasetto on 9/10/21.
//  Copyright © 2021 LoopKit Authors. All rights reserved.
//

import XCTest
import LoopKit
import LoopKitUI
import SwiftUI
@testable import Loop

class SupportManagerTests: XCTestCase {
    enum MockError: Error { case nothing }

    class Mixin {
        func supportMenuItem(supportInfoProvider: SupportInfoProvider, urlHandler: @escaping (URL) -> Void) -> AnyView? {
            nil
        }
        func softwareUpdateView(bundleIdentifier: String, currentVersion: String, guidanceColors: GuidanceColors, openAppStore: (() -> Void)?) -> AnyView? {
            nil
        }
        var mockResult: Result<VersionUpdate?, Error> = .success(.default)
        func checkVersion(bundleIdentifier: String, currentVersion: String) async -> VersionUpdate? {
            switch mockResult {
            case .success(let update):
                return update
            case .failure:
                return nil
            }
        }
        weak var delegate: SupportUIDelegate?
    }
    class MockSupport: Mixin, SupportUI {
        func configurationMenuItems() -> [AnyView] { return [] }
        static var supportIdentifier: String { "SupportManagerTestsMockSupport" }
        override init() { super.init() }
        required init?(rawState: RawStateValue) { super.init() }
        var rawState: RawStateValue = [:]
        
        var loopNeedsReset: Bool = false
        var studyProductSelection: String? = nil
        func getScenarios(from scenarioURLs: [URL]) -> [LoopScenario] { [] }
        func resetLoop() {}
    }
    class AnotherMockSupport: Mixin, SupportUI {
        func configurationMenuItems() -> [AnyView] { return [] }
        static var supportIdentifier: String { "SupportManagerTestsAnotherMockSupport" }
        override init() { super.init() }
        required init?(rawState: RawStateValue) { super.init() }
        var rawState: RawStateValue = [:]
        
        var loopNeedsReset: Bool = false
        var studyProductSelection: String? = nil
        func getScenarios(from scenarioURLs: [URL]) -> [LoopScenario] { [] }
        func resetLoop() {}
    }
    
    class MockAlertIssuer: AlertIssuer {
        func issueAlert(_ alert: LoopKit.Alert) {
        }
        
        func retractAlert(identifier: LoopKit.Alert.Identifier) {
        }
    }
    
    var supportManager: SupportManager!
    var mockSupport: SupportManagerTests.MockSupport!
    var mockAlertIssuer: MockAlertIssuer!

    override func setUp() {
        mockAlertIssuer = MockAlertIssuer()
        supportManager = SupportManager(staticSupportTypes: [], alertIssuer: mockAlertIssuer)
        mockSupport = SupportManagerTests.MockSupport()
        supportManager.addSupport(mockSupport)
    }
    
    func testVersionCheckOneService() async throws {
        let result = await supportManager.checkVersion()
        XCTAssertEqual(VersionUpdate.noUpdateNeeded, result)
        mockSupport.mockResult = .success(.required)

        let result2 = await supportManager.checkVersion()
        XCTAssertEqual(.required, result2)
    }
    
    func testVersionCheckOneServiceError() async throws {
        // Error doesn't really do anything but log
        mockSupport.mockResult = .failure(MockError.nothing)
        let result = await supportManager.checkVersion()
        XCTAssertEqual(VersionUpdate.noUpdateNeeded, result)
    }
    
    func testVersionCheckMultipleServices() async throws {
        let anotherSupport = AnotherMockSupport()
        supportManager.addSupport(anotherSupport)
        let result = await supportManager.checkVersion()
        XCTAssertEqual(VersionUpdate.noUpdateNeeded, result)

        anotherSupport.mockResult = .success(.required)
        let result2 = await supportManager.checkVersion()
        XCTAssertEqual(.required, result2)

        let result3 = await supportManager.checkVersion()
        mockSupport.mockResult = .success(.recommended)
        XCTAssertEqual(.required, result3)
    }
    
}
