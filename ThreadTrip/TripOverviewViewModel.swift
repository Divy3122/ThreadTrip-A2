import Combine
import Foundation

@MainActor
final class TripOverviewViewModel: ObservableObject {
    @Published private(set) var trip: GroupTrip
    @Published private(set) var generatedDeck: GeneratedGroupActivityDeck?
    @Published private(set) var voting: GroupSwipeDeckViewModel?
    @Published private(set) var errorMessage: String?

    private let generateGroupActivityDeck: GenerateGroupActivityDeckUseCase

    init(
        trip: GroupTrip,
        generateGroupActivityDeck: GenerateGroupActivityDeckUseCase
    ) {
        self.trip = trip
        self.generateGroupActivityDeck = generateGroupActivityDeck
    }

    var selectedInterests: Set<TravelInterest> {
        trip.tasteProfile.interests
    }

    var activityBudget: Double {
        Double(trip.tasteProfile.maximumActivityCostPerTraveller)
    }

    var tripBudgetText: String {
        trip.tripBudgetPerTraveller.formatted(
            .currency(code: trip.tasteProfile.currencyCode)
                .precision(.fractionLength(0))
        )
    }

    var activityBudgetText: String {
        trip.tasteProfile.maximumActivityCostPerTraveller.formatted(
            .currency(code: trip.tasteProfile.currencyCode)
                .precision(.fractionLength(0))
        )
    }

    var tripDateText: String {
        let start = trip.startDate.formatted(
            .dateTime.day().month(.abbreviated)
        )
        let end = trip.endDate.formatted(
            .dateTime.day().month(.abbreviated).year()
        )
        return "\(start) – \(end)"
    }

    var canGenerateDeck: Bool {
        generatedDeck == nil
    }

    func toggleInterest(_ interest: TravelInterest) {
        guard generatedDeck == nil else {
            errorMessage = GenerateGroupActivityDeckError
                .activeVotingRoundAlreadyExists
                .localizedDescription
            return
        }

        if trip.tasteProfile.interests.contains(interest) {
            trip.tasteProfile.interests.remove(interest)
        } else {
            trip.tasteProfile.interests.insert(interest)
        }
        errorMessage = nil
    }

    func updateActivityBudget(_ newValue: Double) {
        guard generatedDeck == nil else { return }
        trip.tasteProfile.maximumActivityCostPerTraveller = Int(newValue)
        errorMessage = nil
    }

    func updateDecisionPolicy(_ policy: GroupDecisionPolicy) {
        guard generatedDeck == nil else { return }
        trip.decisionPolicy = policy
        errorMessage = nil
    }

    func generateSharedDeck() {
        errorMessage = nil

        do {
            generatedDeck = try generateGroupActivityDeck.execute(
                for: trip,
                existingVotingRound: generatedDeck?.votingRound
            )
            if let generatedDeck {
                voting = GroupSwipeDeckViewModel(deck: generatedDeck, members: trip.members)
            }
        } catch let error as GenerateGroupActivityDeckError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "The shared deck could not be prepared. Your trip details are unchanged, so please try again."
        }
    }
}
