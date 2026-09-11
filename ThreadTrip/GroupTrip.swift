import Foundation

/// Represents a trip being planned collaboratively by a fixed group of travellers.
///
/// Business Rules:
/// - The end date cannot occur before the start date.
/// - A shared activity deck requires at least one destination and active member.
/// - One group taste profile and decision policy govern a voting round.
/// - Only active members are captured as eligible voters when the round begins.
struct GroupTrip: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var destinationCountry: String
    var destinationCities: [String]
    var startDate: Date
    var endDate: Date
    var members: [TripMember]
    var tripBudgetPerTraveller: Int
    var tasteProfile: TravelTasteProfile
    var decisionPolicy: GroupDecisionPolicy

    var activeMembers: [TripMember] {
        members.filter(\.isActive)
    }

    var durationInDays: Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: startDate)
        let end = calendar.startOfDay(for: endDate)
        let difference = calendar.dateComponents([.day], from: start, to: end).day ?? 0
        return max(difference + 1, 0)
    }
}

/// Represents a traveller who actively participates in a group trip.
///
/// Business Rules:
/// - Only active trip members are included in a new voting round.
/// - Every eligible member must receive the same activity candidates.
/// - Every eligible member must vote before the round can be finalised.
struct TripMember: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    let displayName: String
    let initials: String
    var isActive: Bool
}

/// A travel interest used to shape the group's shared activity deck.
enum TravelInterest: String, Codable, CaseIterable, Identifiable {
    case food
    case culture
    case sightseeing
    case nature
    case shopping
    case nightlife
    case entertainment

    var id: String { rawValue }

    var title: String {
        rawValue.capitalized
    }

    var symbolName: String {
        switch self {
        case .food: "fork.knife"
        case .culture: "building.columns.fill"
        case .sightseeing: "binoculars.fill"
        case .nature: "leaf.fill"
        case .shopping: "bag.fill"
        case .nightlife: "moon.stars.fill"
        case .entertainment: "ticket.fill"
        }
    }
}

/// Represents the group's shared interests and activity-level spending limit.
///
/// Business Rules:
/// - At least one interest must be selected before a deck can be generated.
/// - The maximum activity cost must be greater than zero.
/// - The profile filters one group deck; it does not create personalised decks.
struct TravelTasteProfile: Codable, Equatable {
    var interests: Set<TravelInterest>
    var maximumActivityCostPerTraveller: Int
    let currencyCode: String
}

/// The threshold a travel group chooses for accepting an activity.
enum GroupDecisionPolicy: String, Codable, CaseIterable, Identifiable {
    case simpleMajority
    case seventyFivePercent
    case unanimous

    var id: String { rawValue }

    var title: String {
        switch self {
        case .simpleMajority: "Majority"
        case .seventyFivePercent: "75% yes"
        case .unanimous: "Everyone"
        }
    }

    var explanation: String {
        switch self {
        case .simpleMajority:
            "More than half of active travellers must swipe yes."
        case .seventyFivePercent:
            "At least three quarters of active travellers must swipe yes."
        case .unanimous:
            "Every active traveller must swipe yes."
        }
    }
}

/// Defines how a group evaluates whether an activity has enough support.
protocol GroupDecisionEvaluating {
    func acceptsActivity(
        yesVoteCount: Int,
        eligibleMemberCount: Int
    ) -> Bool
}

extension GroupDecisionPolicy: GroupDecisionEvaluating {
    func acceptsActivity(
        yesVoteCount: Int,
        eligibleMemberCount: Int
    ) -> Bool {
        guard eligibleMemberCount > 0 else { return false }

        switch self {
        case .simpleMajority:
            return yesVoteCount > eligibleMemberCount / 2
        case .seventyFivePercent:
            return Double(yesVoteCount) / Double(eligibleMemberCount) >= 0.75
        case .unanimous:
            return yesVoteCount == eligibleMemberCount
        }
    }
}


/// Local six-traveller Japan trip used by the prototype.
enum JapanTripSample {
    static let japanTrip = GroupTrip(
        id: UUID(uuidString: "10000000-0000-0000-0000-000000000001")!,
        title: "Japan 2026",
        destinationCountry: "Japan",
        destinationCities: ["Tokyo", "Kyoto", "Osaka"],
        startDate: makeDate(year: 2026, month: 12, day: 5),
        endDate: makeDate(year: 2026, month: 12, day: 22),
        members: [
            TripMember(id: UUID(), displayName: "You", initials: "DP", isActive: true),
            TripMember(id: UUID(), displayName: "Alex", initials: "AL", isActive: true),
            TripMember(id: UUID(), displayName: "Maya", initials: "MY", isActive: true),
            TripMember(id: UUID(), displayName: "Sam", initials: "SM", isActive: true),
            TripMember(id: UUID(), displayName: "Noah", initials: "NO", isActive: true),
            TripMember(id: UUID(), displayName: "Leah", initials: "LE", isActive: true)
        ],
        tripBudgetPerTraveller: 4_000,
        tasteProfile: TravelTasteProfile(
            interests: [.food, .culture, .sightseeing, .nature, .shopping],
            maximumActivityCostPerTraveller: 150,
            currencyCode: "AUD"
        ),
        decisionPolicy: .seventyFivePercent
    )

    private static func makeDate(
        year: Int,
        month: Int,
        day: Int
    ) -> Date {
        Calendar(identifier: .gregorian).date(
            from: DateComponents(year: year, month: month, day: day)
        ) ?? Date()
    }
}
