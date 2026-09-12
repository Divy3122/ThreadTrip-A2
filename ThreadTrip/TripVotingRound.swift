import Foundation

enum VotingRoundStatus: String, Codable {
    case open
    case finalised
}

/// Represents one locked group-voting session.
///
/// Business Rules:
/// - Candidate identifiers and their order are fixed when the round is generated.
/// - Every eligible member receives the same candidate identifiers.
/// - Each eligible member may record one yes-or-no swipe per candidate.
/// - The round cannot accept new swipes after finalisation.
struct TripVotingRound: Identifiable, Codable, Equatable {
    let id: UUID
    let groupTripID: UUID
    let candidateIDs: [UUID]
    let eligibleMemberIDs: [UUID]
    let generatedAt: Date
    var status: VotingRoundStatus
}

/// The complete result of generating a locked activity deck for a group.
struct GeneratedGroupActivityDeck: Equatable {
    let votingRound: TripVotingRound
    let candidates: [ActivityCandidate]
}

enum ActivitySwipeChoice: String, Codable, Equatable {
    case yes
    case no
}

/// One traveller's response to one activity in a shared voting round.
///
/// Business Rules:
/// - The traveller must be eligible for the voting round.
/// - The activity must belong to the round's locked shared deck.
/// - A traveller can respond only once to each activity.
/// - Responses cannot be added after the round is finalised.
struct ActivitySwipe: Identifiable, Codable, Equatable {
    let id: UUID
    let votingRoundID: UUID
    let activityCandidateID: UUID
    let memberID: UUID
    let choice: ActivitySwipeChoice
    let recordedAt: Date
}


/// Represents the group's complete decision for one activity in a locked voting round.
///
/// Business Rules:
/// - The result belongs to exactly one activity from the round's locked deck.
/// - Yes and No counts include only eligible travellers from that voting round.
/// - A result is created only after every eligible traveller has responded.
/// - Acceptance is evaluated using the group's decision policy.
struct GroupActivityDecision: Identifiable, Equatable {
    let activity: ActivityCandidate
    let yesVoteCount: Int
    let noVoteCount: Int
    let eligibleTravellerCount: Int
    let isAccepted: Bool

    var id: UUID { activity.id }

    var yesSupportFraction: Double {
        guard eligibleTravellerCount > 0 else { return 0 }

        return Double(yesVoteCount) / Double(eligibleTravellerCount)
    }
}
