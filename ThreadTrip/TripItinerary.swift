//
//  TripItinerary.swift
//  ThreadTrip
//
//  Created by Divy Patel on 12/9/2026.
//

import Foundation

/// Represents one accepted group activity placed into the shared trip itinerary.
///
/// Business Rules:
/// - Only activities accepted by the group's voting round can be scheduled.
/// - An activity can only appear once in the itinerary.
/// - The scheduled date must fall within the trip dates.
/// - Start times and durations use 30-minute blocks.
/// - Activities cannot overlap on the same day.
struct ScheduledTripActivity: Identifiable, Equatable {

    let activity: ActivityCandidate
    var date: Date
    var startMinutes: Int
    var durationMinutes: Int

    var id: UUID {
        activity.id
    }

    var endMinutes: Int {
        startMinutes + durationMinutes
    }
}

/// Defines the shared scheduling rules used by the group itinerary.
///
/// Business Rules:
/// - Activities can be planned between 6:00 am and 11:00 pm.
/// - Activity start times and durations use 30-minute blocks.
/// - Every scheduled activity must last at least 30 minutes.
enum TripItineraryRules {

    static let dayStartMinutes = 6 * 60
    static let dayEndMinutes = 23 * 60

    static let minimumDurationMinutes = 30
    static let timeBlockMinutes = 30
}
