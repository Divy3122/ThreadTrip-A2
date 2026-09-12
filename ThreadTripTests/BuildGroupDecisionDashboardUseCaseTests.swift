//
//  BuildGroupDecisionDashboardUseCaseTests.swift
//  ThreadTrip
//
//  Created by Divy Patel on 12/9/2026.
//

import Foundation
import Testing
@testable import ThreadTrip

struct BuildGroupDecisionDashboardUseCaseTests {

    @Test
    func dashboard_buildsGroupResultFromCompletedVoting() throws {
        let setup = makeSetup()

        let swipes = [
            makeSwipe(
                roundID: setup.round.id,
                candidateID: setup.activities[0].id,
                memberID: setup.memberIDs[0],
                choice: .yes
            ),
            makeSwipe(
                roundID: setup.round.id,
                candidateID: setup.activities[0].id,
                memberID: setup.memberIDs[1],
                choice: .yes
            ),
            makeSwipe(
                roundID: setup.round.id,
                candidateID: setup.activities[0].id,
                memberID: setup.memberIDs[2],
                choice: .no
            ),

            makeSwipe(
                roundID: setup.round.id,
                candidateID: setup.activities[1].id,
                memberID: setup.memberIDs[0],
                choice: .yes
            ),
            makeSwipe(
                roundID: setup.round.id,
                candidateID: setup.activities[1].id,
                memberID: setup.memberIDs[1],
                choice: .no
            ),
            makeSwipe(
                roundID: setup.round.id,
                candidateID: setup.activities[1].id,
                memberID: setup.memberIDs[2],
                choice: .no
            )
        ]

        let decisions = try BuildGroupDecisionDashboardUseCase().execute(
            deck: setup.deck,
            swipes: swipes,
            decisionPolicy: .simpleMajority
        )

        #expect(decisions.count == 2)

        #expect(decisions[0].yesVoteCount == 2)
        #expect(decisions[0].noVoteCount == 1)
        #expect(decisions[0].isAccepted)

        #expect(decisions[1].yesVoteCount == 1)
        #expect(decisions[1].noVoteCount == 2)
        #expect(!decisions[1].isAccepted)
    }

    @Test
    func dashboard_rejectsIncompleteVoting() {
        let setup = makeSetup()

        let swipes = [
            makeSwipe(
                roundID: setup.round.id,
                candidateID: setup.activities[0].id,
                memberID: setup.memberIDs[0],
                choice: .yes
            )
        ]

        #expect(
            throws: BuildGroupDecisionDashboardError
                .votingStillInProgress(
                    recordedResponses: 1,
                    requiredResponses: 6
                )
        ) {
            try BuildGroupDecisionDashboardUseCase().execute(
                deck: setup.deck,
                swipes: swipes,
                decisionPolicy: .simpleMajority
            )
        }
    }

    @Test
    func dashboard_ignoresVotesFromAnotherRound() throws {
        let setup = makeSetup()

        var swipes: [ActivitySwipe] = []

        for activity in setup.activities {
            for memberID in setup.memberIDs {
                swipes.append(
                    makeSwipe(
                        roundID: setup.round.id,
                        candidateID: activity.id,
                        memberID: memberID,
                        choice: .yes
                    )
                )
            }
        }

        swipes.append(
            makeSwipe(
                roundID: UUID(),
                candidateID: setup.activities[0].id,
                memberID: setup.memberIDs[0],
                choice: .no
            )
        )

        let decisions = try BuildGroupDecisionDashboardUseCase().execute(
            deck: setup.deck,
            swipes: swipes,
            decisionPolicy: .simpleMajority
        )

        #expect(decisions.allSatisfy { $0.yesVoteCount == 3 })
        #expect(decisions.allSatisfy { $0.isAccepted })
    }

    private func makeSetup() -> (
        activities: [ActivityCandidate],
        memberIDs: [UUID],
        round: TripVotingRound,
        deck: GeneratedGroupActivityDeck
    ) {
        let activities = [
            makeActivity(title: "Tokyo Food Tour"),
            makeActivity(title: "Kyoto Temple Visit")
        ]

        let memberIDs = [
            UUID(),
            UUID(),
            UUID()
        ]

        let round = TripVotingRound(
            id: UUID(),
            groupTripID: UUID(),
            candidateIDs: activities.map(\.id),
            eligibleMemberIDs: memberIDs,
            generatedAt: Date(),
            status: .open
        )

        let deck = GeneratedGroupActivityDeck(
            votingRound: round,
            candidates: activities
        )

        return (
            activities,
            memberIDs,
            round,
            deck
        )
    }

    private func makeActivity(
        title: String
    ) -> ActivityCandidate {
        ActivityCandidate(
            id: UUID(),
            title: title,
            activityDescription: "Group travel activity",
            city: "Tokyo",
            category: .sightseeing,
            estimatedCostPerTraveller: 40,
            currencyCode: "AUD",
            suggestedDurationMinutes: 90,
            symbolName: "mappin"
        )
    }

    private func makeSwipe(
        roundID: UUID,
        candidateID: UUID,
        memberID: UUID,
        choice: ActivitySwipeChoice
    ) -> ActivitySwipe {
        ActivitySwipe(
            id: UUID(),
            votingRoundID: roundID,
            activityCandidateID: candidateID,
            memberID: memberID,
            choice: choice,
            recordedAt: Date()
        )
    }
}
