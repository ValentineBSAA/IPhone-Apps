import XCTest
@testable import CrispCompanion

final class KitchenModelsTests: XCTestCase {
    func testElevenPresetPlanningChoices() {
        XCTAssertEqual(FryerPreset.allCases.count, 11)
        XCTAssertEqual(FryerPreset.airFry.name, "Air Fry")
        XCTAssertTrue(FryerPreset.allCases.allSatisfy { (175...400).contains($0.suggestedFahrenheit) })
        XCTAssertTrue(FryerPreset.allCases.allSatisfy { (1...60).contains($0.suggestedMinutes) })
    }

    func testRecipeValidation() {
        XCTAssertTrue(SavedRecipe(title: "Potatoes", temperatureF: 380, minutes: 14).isValid)
        XCTAssertFalse(SavedRecipe(title: "", temperatureF: 380, minutes: 14).isValid)
        XCTAssertFalse(SavedRecipe(title: "Test", temperatureF: 600, minutes: 14).isValid)
        XCTAssertFalse(SavedRecipe(title: "Test", temperatureF: 380, minutes: 0).isValid)
    }

    func testReadOnlyBridgeResponseDecodes() throws {
        let data = Data("""
            {"connected":true,"cooking":false,"temperature_f":null,"minutes_remaining":null,"preset":null,"message":"Standby","updated_at":"2026-11-22T00:00:00Z"}
            """.utf8)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let result = try decoder.decode(LiveFryerStatus.self, from: data)
        XCTAssertTrue(result.connected)
        XCTAssertFalse(result.cooking)
        XCTAssertNil(result.temperatureF)
    }
}
