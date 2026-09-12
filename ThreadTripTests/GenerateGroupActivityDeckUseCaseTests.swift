//
//  ArrangeTripItineraryUseCaseTests.swift
//  ThreadTrip
//
//  Created by Divy Patel on 12/9/2026.
//

import Foundation
import Testing
@testable import ThreadTrip

struct GenerateGroupActivityDeckUseCaseTests {

    @Test
    func sharedDeck_preservesTheSameOrderedActivitiesForAllTravellers() throws {
        let trip = JapanTripSample.japanTrip
        let deck = try makeUseCase().execute(for: trip)

        #expect(deck.candidates.count == 6)
        #expect(deck.votingRound.candidateIDs == deck.candidates.map(\.id))
        #expect(deck.votingRound.eligibleMemberIDs == trip.activeMembers.map(\.id))
        #expect(deck.votingRound.groupTripID == trip.id)
        #expect(deck.candidates.map(\.title) == (0..<6).map { "Tokyo activity \($0)" })
    }

    @Test
    func sharedDeck_removesDuplicatesAndLimitsTheDeckToTwelveActivities() throws {
        let activities = candidates(count: 15)
        let deck = try makeUseCase(
            activities + activities
        ).execute(for: JapanTripSample.japanTrip)

        #expect(deck.candidates.count == 12)
        #expect(Set(deck.votingRound.candidateIDs).count == 12)
    }

    @Test
    func sharedDeck_excludesInactiveTravellers() throws {
        var trip = JapanTripSample.japanTrip
        trip.members[0].isActive = false

        let deck = try makeUseCase().execute(for: trip)

        #expect(
            !deck.votingRound.eligibleMemberIDs.contains(
                trip.members[0].id
            )
        )

        #expect(
            deck.votingRound.eligibleMemberIDs.count
            == trip.activeMembers.count
        )
    }

    @Test
    func sharedDeck_rejectsInvalidTripPreferences() {
        let original = JapanTripSample.japanTrip
        var invalidTrips: [(GroupTrip, GenerateGroupActivityDeckError)] = []

        var trip = original
        trip.endDate = trip.startDate.addingTimeInterval(-1)
        invalidTrips.append((trip, .invalidTripDates))

        trip = original
        trip.destinationCities = []
        invalidTrips.append((trip, .noDestinationsSelected))

        trip = original
        trip.members = []
        invalidTrips.append((trip, .noActiveTripMembers))

        trip = original
        trip.tasteProfile.interests = []
        invalidTrips.append((trip, .preferencesIncomplete))

        trip = original
        trip.tasteProfile.maximumActivityCostPerTraveller = 0
        invalidTrips.append((trip, .invalidActivityBudget))

        for (trip, expectedError) in invalidTrips {
            #expect(throws: expectedError) {
                try makeUseCase().execute(for: trip)
            }
        }
    }

    @Test
    func sharedDeck_allowsASingleDayTrip() throws {
        var trip = JapanTripSample.japanTrip
        trip.endDate = trip.startDate

        #expect(
            try makeUseCase().execute(for: trip).candidates.count == 6
        )
    }

    @Test
    func sharedDeck_rejectsAnExistingRound() throws {
        let useCase = makeUseCase()

        let deck = try useCase.execute(
            for: JapanTripSample.japanTrip
        )

        #expect(
            throws: GenerateGroupActivityDeckError
                .activeVotingRoundAlreadyExists
        ) {
            try useCase.execute(
                for: JapanTripSample.japanTrip,
                existingVotingRound: deck.votingRound
            )
        }
    }

    @Test
    func sharedDeck_requiresAtLeastSixMatches() {
        #expect(
            throws: GenerateGroupActivityDeckError
                .insufficientMatchingActivities(
                    minimumRequired: 6
                )
        ) {
            try makeUseCase(
                candidates(count: 5)
            ).execute(
                for: JapanTripSample.japanTrip
            )
        }

        #expect(
            throws: GenerateGroupActivityDeckError
                .noMatchingActivities
        ) {
            try makeUseCase([]).execute(
                for: JapanTripSample.japanTrip
            )
        }
    }

    @Test
    func sharedDeck_explainsAnUnavailableCatalogue() {
        let useCase = GenerateGroupActivityDeckUseCase(
            activityCatalogue: CatalogueStub(
                activities: [],
                unavailable: true
            )
        )

        #expect(
            throws: GenerateGroupActivityDeckError
                .activityCatalogueUnavailable
        ) {
            try useCase.execute(
                for: JapanTripSample.japanTrip
            )
        }
    }

    @Test
    func bundledCatalogue_respectsTheGroupCitiesInterestsAndBudget() throws {
        let catalogue = LocalJSONTravelActivityCatalogue()

        var trip = JapanTripSample.japanTrip
        trip.destinationCities = ["Tokyo"]

        trip.tasteProfile.interests = [
            .food,
            .culture,
            .sightseeing
        ]

        trip.tasteProfile.maximumActivityCostPerTraveller = 45

        let matches = try catalogue.activityCandidates(
            for: trip,
            matching: trip.tasteProfile
        )

        #expect(!matches.isEmpty)

        #expect(
            matches.allSatisfy {
                $0.city == "Tokyo"
                && trip.tasteProfile.interests.contains($0.category)
                && $0.estimatedCostPerTraveller <= 45
            }
        )
    }

    @MainActor
    @Test
    func tripOverview_keepsPreferencesAndRoundLockedAfterGeneration() throws {
        let model = TripOverviewViewModel(
            trip: JapanTripSample.japanTrip,
            generateGroupActivityDeck: makeUseCase()
        )

        model.generateSharedDeck()

        let deck = try #require(model.generatedDeck)
        let trip = model.trip

        model.toggleInterest(.nightlife)
        model.updateActivityBudget(300)
        model.updateDecisionPolicy(.unanimous)
        model.generateSharedDeck()

        #expect(model.trip == trip)
        #expect(model.generatedDeck == deck)
        #expect(model.errorMessage != nil)
    }

    private func makeUseCase(
        _ activities: [ActivityCandidate]? = nil
    ) -> GenerateGroupActivityDeckUseCase {
        GenerateGroupActivityDeckUseCase(
            activityCatalogue: CatalogueStub(
                activities: activities ?? candidates(count: 6)
            )
        )
    }

    private func candidates(
        count: Int
    ) -> [ActivityCandidate] {
        (0..<count).reversed().map { index in
            ActivityCandidate(
                id: UUID(),
                title: "Tokyo activity \(index)",
                activityDescription: "A shared trip idea",
                city: "Tokyo",
                category: .sightseeing,
                estimatedCostPerTraveller: 25,
                currencyCode: "AUD",
                suggestedDurationMinutes: 90,
                symbolName: "mappin"
            )
        }
    }
}

private struct CatalogueStub: TravelActivityCatalogue {

    let activities: [ActivityCandidate]
    var unavailable = false

    func activityCandidates(
        for trip: GroupTrip,
        matching tasteProfile: TravelTasteProfile
    ) throws -> [ActivityCandidate] {
        if unavailable {
            throw LocalJSONTravelActivityCatalogueError.resourceMissing
        }

        return activities
    }
}
