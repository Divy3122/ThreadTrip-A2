//
//  ArrangeTripItineraryUseCaseTests.swift
//  ThreadTrip
//
//  Created by Divy Patel on 12/9/2026.
//

import Foundation
import Testing
@testable import ThreadTrip

struct RecordActivitySwipeUseCaseTests {
    private let memberID = UUID(uuidString: "40000000-0000-0000-0000-000000000001")!
    private let candidateID = UUID(uuidString: "50000000-0000-0000-0000-000000000001")!

    @Test
    func recordSwipe_createsResponseForEligibleMemberAndSharedCandidate() throws {
        let round = makeVotingRound()

        let result = try RecordActivitySwipeUseCase().execute(
            choice: .yes,
            candidateID: candidateID,
            memberID: memberID,
            in: round,
            existingSwipes: []
        )

        #expect(result.votingRoundID == round.id)
        #expect(result.memberID == memberID)
        #expect(result.activityCandidateID == candidateID)
        #expect(result.choice == .yes)
    }

    @Test
    func recordSwipe_rejectsDuplicateResponse() throws {
        let round = makeVotingRound()
        let useCase = RecordActivitySwipeUseCase()
        let existing = try useCase.execute(
            choice: .yes,
            candidateID: candidateID,
            memberID: memberID,
            in: round,
            existingSwipes: []
        )

        #expect(throws: RecordActivitySwipeError.swipeAlreadyRecorded) {
            try useCase.execute(
                choice: .no,
                candidateID: candidateID,
                memberID: memberID,
                in: round,
                existingSwipes: [existing]
            )
        }
    }

    @Test
    func recordSwipe_rejectsTravellerOutsideTheRound() {
        #expect(throws: RecordActivitySwipeError.travellerNotEligible) {
            try RecordActivitySwipeUseCase().execute(
                choice: .yes,
                candidateID: candidateID,
                memberID: UUID(),
                in: makeVotingRound(),
                existingSwipes: []
            )
        }
    }

    @Test
    func recordSwipe_rejectsActivityOutsideTheLockedDeck() {
        #expect(throws: RecordActivitySwipeError.activityNotInSharedDeck) {
            try RecordActivitySwipeUseCase().execute(
                choice: .yes,
                candidateID: UUID(),
                memberID: memberID,
                in: makeVotingRound(),
                existingSwipes: []
            )
        }
    }

    @Test
    func recordSwipe_rejectsResponseAfterRoundIsFinalised() {
        var round = makeVotingRound()
        round.status = .finalised

        #expect(throws: RecordActivitySwipeError.votingRoundAlreadyFinalised) {
            try RecordActivitySwipeUseCase().execute(
                choice: .yes,
                candidateID: candidateID,
                memberID: memberID,
                in: round,
                existingSwipes: []
            )
        }
    }

    @Test func recordSwipe_doesNotTreatAnotherRoundsVoteAsADuplicate() throws {
        let round = makeVotingRound()
        let anotherRound = TripVotingRound(id: UUID(), groupTripID: round.groupTripID, candidateIDs: round.candidateIDs, eligibleMemberIDs: round.eligibleMemberIDs, generatedAt: Date(), status: .open)
        let useCase = RecordActivitySwipeUseCase()
        let previous = try useCase.execute(choice: .yes, candidateID: candidateID, memberID: memberID, in: anotherRound, existingSwipes: [])
        let current = try useCase.execute(choice: .no, candidateID: candidateID, memberID: memberID, in: round, existingSwipes: [previous])
        #expect(current.votingRoundID == round.id)
        #expect(current.choice == .no)
    }

    @MainActor @Test func everyTraveller_receivesTheEntireLockedDeckInTheSameOrder() throws {
        let trip = JapanTripSample.japanTrip
        let deck = try GenerateGroupActivityDeckUseCase(activityCatalogue: LocalJSONTravelActivityCatalogue()).execute(for: trip)
        let voting = GroupSwipeDeckViewModel(deck: deck, members: trip.members)

        for member in trip.activeMembers {
            voting.selectedMemberID = member.id
            for candidateID in deck.votingRound.candidateIDs {
                #expect(voting.currentCandidate?.id == candidateID)
                voting.recordSwipe(.yes)
            }
            #expect(voting.currentCandidate == nil)
            #expect(voting.memberSwipes.count == deck.candidates.count)
        }
        #expect(voting.completedTravellerCount == trip.activeMembers.count)
        #expect(voting.swipes.count == trip.activeMembers.count * deck.candidates.count)
        #expect(voting.swipes.allSatisfy { $0.votingRoundID == deck.votingRound.id })
        voting.recordSwipe(.no)
        #expect(voting.swipes.count == trip.activeMembers.count * deck.candidates.count)
    }

    @MainActor @Test func switchingTravellers_resumesEachPersonsNextUnansweredActivity() throws {
        let trip = JapanTripSample.japanTrip
        let deck = try GenerateGroupActivityDeckUseCase(activityCatalogue: LocalJSONTravelActivityCatalogue()).execute(for: trip)
        let voting = GroupSwipeDeckViewModel(deck: deck, members: trip.members)
        voting.recordSwipe(.no)
        voting.selectedMemberID = trip.members[1].id
        #expect(voting.currentCandidate?.id == deck.candidates[0].id)
        voting.recordSwipe(.yes)
        voting.selectedMemberID = trip.members[0].id
        #expect(voting.currentCandidate?.id == deck.candidates[1].id)
        #expect(voting.memberSwipes.map(\.choice) == [.no])
        #expect(voting.swipes.count == 2)
    }

    @MainActor @Test func tripOverview_retainsVotingStateWhenTheScreenIsReopened() throws {
        let overview = TripOverviewViewModel(trip: JapanTripSample.japanTrip, generateGroupActivityDeck: GenerateGroupActivityDeckUseCase(activityCatalogue: LocalJSONTravelActivityCatalogue()))
        overview.generateSharedDeck()
        let firstVisit = try #require(overview.voting)
        firstVisit.recordSwipe(.yes)
        let secondVisit = try #require(overview.voting)
        #expect(firstVisit === secondVisit)
        #expect(secondVisit.memberSwipes.count == 1)
        overview.generateSharedDeck()
        #expect(overview.voting === firstVisit)
        #expect(overview.voting?.swipes.count == 1)
    }

    @MainActor @Test func rejectedTraveller_doesNotAdvanceTheDeckOrSaveAVote() throws {
        let trip = JapanTripSample.japanTrip
        let deck = try GenerateGroupActivityDeckUseCase(activityCatalogue: LocalJSONTravelActivityCatalogue()).execute(for: trip)
        let voting = GroupSwipeDeckViewModel(deck: deck, members: trip.members)
        voting.selectedMemberID = UUID()
        voting.recordSwipe(.yes)
        #expect(voting.swipes.isEmpty)
        #expect(voting.currentCandidate?.id == deck.candidates.first?.id)
        #expect(voting.errorMessage == RecordActivitySwipeError.travellerNotEligible.localizedDescription)
    }

    private func makeVotingRound() -> TripVotingRound {
        TripVotingRound(
            id: UUID(uuidString: "60000000-0000-0000-0000-000000000001")!,
            groupTripID: UUID(),
            candidateIDs: [candidateID],
            eligibleMemberIDs: [memberID],
            generatedAt: Date(),
            status: .open
        )
    }
}
