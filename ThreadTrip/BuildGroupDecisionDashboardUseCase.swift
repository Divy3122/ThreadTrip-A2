//
//  BuildGroupDecisionDashboardUseCase.swift
//  ThreadTrip
//
//  Created by Divy Patel on 12/9/2026.
//

import Foundation

enum BuildGroupDecisionDashboardError: LocalizedError, Equatable {
    case lockedDeckChanged
    case responseOutsideLockedRound
    case duplicateTravellerResponse
    case votingStillInProgress(
        recordedResponses: Int,
        requiredResponses: Int
    )

    var errorDescription: String? {
        switch self {

        case .lockedDeckChanged:
            return """
            The shared activity deck no longer matches this voting round. \
            Return to Activity Voting and reopen the same deck.
            """

        case .responseOutsideLockedRound:
            return """
            A saved response does not belong to a traveller or activity in this shared deck. \
            Return to Activity Voting and finish this round before reviewing results.
            """

        case .duplicateTravellerResponse:
            return """
            A traveller has more than one response saved for the same activity. \
            Return to Activity Voting before reviewing the group result.
            """

        case .votingStillInProgress(
            let recordedResponses,
            let requiredResponses
        ):
            return """
            The group result is not ready yet. \
            \(recordedResponses) of \(requiredResponses) activity responses are complete. \
            Finish voting for every traveller first.
            """
        }
    }
}

/// Builds the Group Decision Dashboard for one locked travel voting round.
///
/// Business Rules:
/// - Results must preserve the original shared deck order.
/// - Only responses belonging to this voting round are counted.
/// - Every eligible traveller must vote on every activity.
/// - Missing responses are never treated as No votes.
/// - Each traveller can contribute only one response per activity.
/// - The group's chosen decision policy determines whether an activity is accepted.
struct BuildGroupDecisionDashboardUseCase {

    func execute(
        deck: GeneratedGroupActivityDeck,
        swipes: [ActivitySwipe],
        decisionPolicy: GroupDecisionPolicy
    ) throws -> [GroupActivityDecision] {

        let round = deck.votingRound

        var candidateByID: [UUID: ActivityCandidate] = [:]

        for candidate in deck.candidates {
            guard candidateByID[candidate.id] == nil else {
                throw BuildGroupDecisionDashboardError.lockedDeckChanged
            }

            candidateByID[candidate.id] = candidate
        }

        // The dashboard must use exactly the activities
        // captured by this locked voting round.
        guard
            Set(round.candidateIDs).count == round.candidateIDs.count,
            deck.candidates.count == round.candidateIDs.count,
            Set(deck.candidates.map(\.id)) == Set(round.candidateIDs),
            round.candidateIDs.allSatisfy({
                candidateByID[$0] != nil
            })
        else {
            throw BuildGroupDecisionDashboardError.lockedDeckChanged
        }

        // IMPORTANT:
        // Ignore votes from any previous or different voting round.
        let roundSwipes = swipes.filter {
            $0.votingRoundID == round.id
        }

        let eligibleMemberIDs = Set(round.eligibleMemberIDs)
        let lockedCandidateIDs = Set(round.candidateIDs)

        // Every vote in this round must belong to an eligible
        // traveller and one of the locked activities.
        guard roundSwipes.allSatisfy({
            eligibleMemberIDs.contains($0.memberID)
            && lockedCandidateIDs.contains($0.activityCandidateID)
        }) else {
            throw BuildGroupDecisionDashboardError
                .responseOutsideLockedRound
        }

        let responseKeys = roundSwipes.map {
            SwipeResponseKey(
                activityCandidateID: $0.activityCandidateID,
                memberID: $0.memberID
            )
        }

        // One traveller = one response per activity.
        guard Set(responseKeys).count == responseKeys.count else {
            throw BuildGroupDecisionDashboardError
                .duplicateTravellerResponse
        }

        let requiredResponses =
            round.candidateIDs.count
            * round.eligibleMemberIDs.count

        // Do not turn missing votes into No votes.
        guard roundSwipes.count == requiredResponses else {
            throw BuildGroupDecisionDashboardError
                .votingStillInProgress(
                    recordedResponses: roundSwipes.count,
                    requiredResponses: requiredResponses
                )
        }

        // candidateIDs are used here rather than deck.candidates
        // so Screen 3 preserves the exact locked deck order.
        return try round.candidateIDs.map { candidateID in

            guard let candidate = candidateByID[candidateID] else {
                throw BuildGroupDecisionDashboardError.lockedDeckChanged
            }

            let activitySwipes = roundSwipes.filter {
                $0.activityCandidateID == candidateID
            }

            let yesVoteCount = activitySwipes.filter {
                $0.choice == .yes
            }.count

            let noVoteCount = activitySwipes.filter {
                $0.choice == .no
            }.count

            let isAccepted = decisionPolicy.acceptsActivity(
                yesVoteCount: yesVoteCount,
                eligibleMemberCount: round.eligibleMemberIDs.count
            )

            return GroupActivityDecision(
                activity: candidate,
                yesVoteCount: yesVoteCount,
                noVoteCount: noVoteCount,
                eligibleTravellerCount: round.eligibleMemberIDs.count,
                isAccepted: isAccepted
            )
        }
    }
}

private struct SwipeResponseKey: Hashable {
    let activityCandidateID: UUID
    let memberID: UUID
}
