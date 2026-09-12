import Foundation

/// Represents a Japan activity that may be shown in a group's shared swipe deck.
///
/// Business Rules:
/// - The activity must match one of the trip's destination cities.
/// - Its category must match a selected group interest.
/// - Its estimated per-traveller cost must not exceed the group's activity limit.
/// - The same activity can appear only once within a voting round.
struct ActivityCandidate: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    let title: String
    let activityDescription: String
    let city: String
    let category: TravelInterest
    let estimatedCostPerTraveller: Int
    let currencyCode: String
    let suggestedDurationMinutes: Int
    let symbolName: String
}
