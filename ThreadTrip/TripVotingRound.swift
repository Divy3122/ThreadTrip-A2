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

