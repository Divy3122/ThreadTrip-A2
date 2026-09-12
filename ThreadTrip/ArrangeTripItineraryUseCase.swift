//
//  ArrangeTripItineraryUseCase.swift
//  ThreadTrip
//
//  Created by Divy Patel on 12/9/2026.
//

import Foundation

enum ArrangeTripItineraryError: LocalizedError, Equatable {

    case activityWasNotAccepted
    case activityAlreadyScheduled
    case dateOutsideTrip
    case timeOutsidePlanningDay
    case invalidTimeBlock
    case overlappingActivity

    var errorDescription: String? {
        switch self {

        case .activityWasNotAccepted:
            return """
            Only activities that made the cut can be added to the itinerary. \
            Choose an accepted activity from the group results.
            """

        case .activityAlreadyScheduled:
            return """
            This activity is already in the itinerary. \
            Move or remove the existing activity before placing it again.
            """

        case .dateOutsideTrip:
            return """
            Activities can only be scheduled on a trip date. \
            Choose one of the dates shown in the itinerary.
            """

        case .timeOutsidePlanningDay:
            return """
            Activities must fit between 6:00 am and 11:00 pm. \
            Choose an earlier time or shorten the activity.
            """

        case .invalidTimeBlock:
            return """
            The itinerary uses 30-minute time blocks. \
            Choose a time and duration that falls on a 30-minute interval.
            """

        case .overlappingActivity:
            return """
            That time overlaps with another activity. \
            Choose another time or move the activity already scheduled there.
            """
        }
    }
}

/// Arranges accepted activities inside the group's shared trip itinerary.
///
/// Business Rules:
/// - Rejected activities cannot enter the itinerary.
/// - Each accepted activity can be scheduled once.
/// - Activities must remain inside the trip's date range.
/// - Activities use 30-minute scheduling blocks.
/// - Activities on the same day cannot overlap.
struct ArrangeTripItineraryUseCase {

    func schedule(
        activity: ActivityCandidate,
        acceptedActivityIDs: Set<UUID>,
        date: Date,
        startMinutes: Int,
        trip: GroupTrip,
        existingActivities: [ScheduledTripActivity]
    ) throws -> ScheduledTripActivity {

        guard acceptedActivityIDs.contains(activity.id) else {
            throw ArrangeTripItineraryError.activityWasNotAccepted
        }

        guard !existingActivities.contains(where: {
            $0.activity.id == activity.id
        }) else {
            throw ArrangeTripItineraryError.activityAlreadyScheduled
        }

        let scheduledActivity = ScheduledTripActivity(
            activity: activity,
            date: Calendar.current.startOfDay(for: date),
            startMinutes: startMinutes,
            durationMinutes: activity.suggestedDurationMinutes
        )

        try validate(
            scheduledActivity,
            trip: trip,
            existingActivities: existingActivities
        )

        return scheduledActivity
    }

    func move(
        activity: ScheduledTripActivity,
        to date: Date,
        startMinutes: Int,
        trip: GroupTrip,
        existingActivities: [ScheduledTripActivity]
    ) throws -> ScheduledTripActivity {

        var updatedActivity = activity

        updatedActivity.date = Calendar.current.startOfDay(for: date)
        updatedActivity.startMinutes = startMinutes

        try validate(
            updatedActivity,
            trip: trip,
            existingActivities: existingActivities
        )

        return updatedActivity
    }

    func resize(
        activity: ScheduledTripActivity,
        durationMinutes: Int,
        trip: GroupTrip,
        existingActivities: [ScheduledTripActivity]
    ) throws -> ScheduledTripActivity {

        var updatedActivity = activity
        updatedActivity.durationMinutes = durationMinutes

        try validate(
            updatedActivity,
            trip: trip,
            existingActivities: existingActivities
        )

        return updatedActivity
    }

    private func validate(
        _ activity: ScheduledTripActivity,
        trip: GroupTrip,
        existingActivities: [ScheduledTripActivity]
    ) throws {

        let calendar = Calendar.current

        let activityDate = calendar.startOfDay(for: activity.date)
        let tripStart = calendar.startOfDay(for: trip.startDate)
        let tripEnd = calendar.startOfDay(for: trip.endDate)

        guard activityDate >= tripStart && activityDate <= tripEnd else {
            throw ArrangeTripItineraryError.dateOutsideTrip
        }

        guard
            activity.startMinutes % TripItineraryRules.timeBlockMinutes == 0,
            activity.durationMinutes % TripItineraryRules.timeBlockMinutes == 0,
            activity.durationMinutes >= TripItineraryRules.minimumDurationMinutes
        else {
            throw ArrangeTripItineraryError.invalidTimeBlock
        }

        guard
            activity.startMinutes >= TripItineraryRules.dayStartMinutes,
            activity.endMinutes <= TripItineraryRules.dayEndMinutes
        else {
            throw ArrangeTripItineraryError.timeOutsidePlanningDay
        }

        let activitiesOnSameDay = existingActivities.filter {
            $0.id != activity.id &&
            calendar.isDate($0.date, inSameDayAs: activity.date)
        }

        let overlaps = activitiesOnSameDay.contains { existing in
            activity.startMinutes < existing.endMinutes &&
            activity.endMinutes > existing.startMinutes
        }

        guard !overlaps else {
            throw ArrangeTripItineraryError.overlappingActivity
        }
    }
}
