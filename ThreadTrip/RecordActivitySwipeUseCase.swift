import Foundation

enum RecordActivitySwipeError: LocalizedError, Equatable {
    case votingRoundAlreadyFinalised
    case travellerNotEligible
    case activityNotInSharedDeck
    case swipeAlreadyRecorded

    var errorDescription: String? {
        switch self {
        case .votingRoundAlreadyFinalised:
            "This voting round has finished, so it cannot accept more swipes. Return to the trip overview."
        case .travellerNotEligible:
            "This traveller is not an active member of the voting round. Select a traveller from this deck."
        case .activityNotInSharedDeck:
            "This activity is not part of the group's locked shared deck. Return to the shared activity deck."
        case .swipeAlreadyRecorded:
            "You have already responded to this activity. Continue to your next activity."
        }
    }
}

/// Validates and creates one yes-or-no response for a shared activity deck.
struct RecordActivitySwipeUseCase {
    func execute(
        choice: ActivitySwipeChoice,
        candidateID: UUID,
        memberID: UUID,
        in votingRound: TripVotingRound,
        existingSwipes: [ActivitySwipe]
    ) throws -> ActivitySwipe {
        guard votingRound.status == .open else {
            throw RecordActivitySwipeError.votingRoundAlreadyFinalised
        }
        guard votingRound.eligibleMemberIDs.contains(memberID) else {
            throw RecordActivitySwipeError.travellerNotEligible
        }
        guard votingRound.candidateIDs.contains(candidateID) else {
            throw RecordActivitySwipeError.activityNotInSharedDeck
        }

        let isDuplicate = existingSwipes.contains {
            $0.votingRoundID == votingRound.id
                && $0.memberID == memberID
                && $0.activityCandidateID == candidateID
        }
        guard !isDuplicate else {
            throw RecordActivitySwipeError.swipeAlreadyRecorded
        }

        return ActivitySwipe(
            id: UUID(),
            votingRoundID: votingRound.id,
            activityCandidateID: candidateID,
            memberID: memberID,
            choice: choice,
            recordedAt: Date()
        )
    }
}
