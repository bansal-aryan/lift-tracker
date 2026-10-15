import Foundation

@main struct DomainTests {
    static func main() {
        var checks = 0
        func check(_ condition: Bool, _ name: String) {
            precondition(condition, "FAILED: \(name)"); checks += 1
        }
        let pounds = WeightParser.parse("135 lbs", defaultUnit: .kg)!
        check(pounds.unit == .lb && pounds.reps == nil, "explicit pounds override default")
        check(abs(pounds.kilograms - 61.23496995) < 0.0000001, "exact pound conversion")
        let kg = WeightParser.parse("45 kg for 8 reps", defaultUnit: .lb)!
        check(kg.load == 45 && kg.reps == 8 && kg.unit == .kg, "plain English set")
        check(WeightParser.parse("50kgx10", defaultUnit: .lb)?.reps == 10, "compact notes")
        check(WeightParser.parse("17.5 × 8", defaultUnit: .kg)?.unit == .kg, "decimal and default unit")
        check(WeightParser.parse(" 35 POUNDS X 12 ", defaultUnit: .kg)?.unit == .lb, "case insensitive aliases")
        check(WeightParser.parse("0 kg x 8", defaultUnit: .lb)?.load == 0, "zero added load")
        for invalid in ["-10 lb x 8", "45kgx0", "10 x 2.5", "12x PPP", "90x", "NaN kg", "45 stones", "10 x 9999999999999999999999999999", "45 lb trailing", ""] {
            check(WeightParser.parse(invalid, defaultUnit: .lb) == nil, "reject \(invalid)")
        }
        let ids = Catalog.all.map(\.id)
        check(Set(ids).count == ids.count, "unique catalog IDs")
        check(Catalog.starters.flatMap { $0.1 }.allSatisfy { ids.contains($0) }, "routine catalog integrity")
        check(Catalog.find("assisted-pull-up").assistance, "assistance semantics")
        check(Catalog.find("db-shoulder-press").perHand, "per dumbbell semantics")
        print("Passed \(checks) domain checks")
    }
}
