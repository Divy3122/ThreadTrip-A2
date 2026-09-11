import Foundation

enum GenerateGroupActivityDeckError: LocalizedError, Equatable {
    case invalidTripDates
    case noDestinationsSelected
    case noActiveTripMembers
    case preferencesIncomplete
    case invalidActivityBudget
    case activeVotingRoundAlreadyExists
    case noMatchingActivities
    case insufficientMatchingActivities(minimumRequired: Int)
    case activityCatalogueUnavailable

    var errorDescription: String? {
        switch self {
        case .invalidTripDates:
            "Check the trip dates. The return date must be on or after the departure date."
        case .noDestinationsSelected:
            "Choose at least one destination city before building the shared deck."
        case .noActiveTripMembers:
            "Add at least one active traveller before building the shared deck."
        case .preferencesIncomplete:
            "Choose at least one group interest so ThreadTrip can find relevant activities."
        case .invalidActivityBudget:
            "Set an activity budget above $0 before building the shared deck."
        case .activeVotingRoundAlreadyExists:
            "Your group already has a shared deck. Finish that voting round before creating another."
        case .noMatchingActivities:
            "No activities match the current cities, interests and budget. Broaden the group preferences and try again."
        case .insufficientMatchingActivities(let minimumRequired):
            "ThreadTrip found fewer than \(minimumRequired) matching activities. Select another interest or increase the activity budget."
        case .activityCatalogueUnavailable:
            "The Japan activity catalogue could not be loaded. Your trip details are unchanged, so please try again."
        }
    }
}

/// Generates one ordered and locked activity deck for an entire travel group.
///
/// The Use Case validates the trip, requests matching candidates from the
/// catalogue, removes duplicates, and captures the same candidate/member IDs
/// in one `TripVotingRound`. It never generates a separate deck per traveller.
struct GenerateGroupActivityDeckUseCase {
    private let activityCatalogue: any TravelActivityCatalogue
    private let deckSize = 12
    private let minimumDeckSize = 6

    init(
        activityCatalogue: any TravelActivityCatalogue
    ) {
        self.activityCatalogue = activityCatalogue
    }

    func execute(
        for trip: GroupTrip,
        existingVotingRound: TripVotingRound? = nil
    ) throws -> GeneratedGroupActivityDeck {
        guard trip.endDate >= trip.startDate else {
            throw GenerateGroupActivityDeckError.invalidTripDates
        }
        guard !trip.destinationCities.isEmpty else {
            throw GenerateGroupActivityDeckError.noDestinationsSelected
        }
        guard !trip.activeMembers.isEmpty else {
            throw GenerateGroupActivityDeckError.noActiveTripMembers
        }
        guard !trip.tasteProfile.interests.isEmpty else {
            throw GenerateGroupActivityDeckError.preferencesIncomplete
        }
        guard trip.tasteProfile.maximumActivityCostPerTraveller > 0 else {
            throw GenerateGroupActivityDeckError.invalidActivityBudget
        }
        guard existingVotingRound == nil else {
            throw GenerateGroupActivityDeckError.activeVotingRoundAlreadyExists
        }

        let matches: [ActivityCandidate]
        do {
            matches = try activityCatalogue.activityCandidates(
                for: trip,
                matching: trip.tasteProfile
            )
        } catch {
            throw GenerateGroupActivityDeckError.activityCatalogueUnavailable
        }

        var seenCandidateIDs = Set<UUID>()
        let uniqueMatches = matches
            .filter { seenCandidateIDs.insert($0.id).inserted }
            .sorted {
                if $0.city == $1.city {
                    return $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
                }
                return $0.city.localizedCaseInsensitiveCompare($1.city) == .orderedAscending
            }

        guard !uniqueMatches.isEmpty else {
            throw GenerateGroupActivityDeckError.noMatchingActivities
        }
        guard uniqueMatches.count >= minimumDeckSize else {
            throw GenerateGroupActivityDeckError.insufficientMatchingActivities(
                minimumRequired: minimumDeckSize
            )
        }

        let selectedCandidates = Array(uniqueMatches.prefix(deckSize))
        let round = TripVotingRound(
            id: UUID(),
            groupTripID: trip.id,
            candidateIDs: selectedCandidates.map(\.id),
            eligibleMemberIDs: trip.activeMembers.map(\.id),
            generatedAt: Date(),
            status: .open
        )

        return GeneratedGroupActivityDeck(
            votingRound: round,
            candidates: selectedCandidates
        )
    }
}
