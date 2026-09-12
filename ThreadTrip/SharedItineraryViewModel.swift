//
//  SharedItineraryViewModel.swift
//  ThreadTrip
//
//  Created by Divy Patel on 12/9/2026.
//

import Combine
import Foundation

@MainActor
final class SharedItineraryViewModel: ObservableObject {

    @Published private(set) var scheduledActivities: [ScheduledTripActivity] = []
    @Published var selectedDate: Date
    @Published var errorMessage: String?

    let trip: GroupTrip
    let acceptedActivities: [ActivityCandidate]

    private let arrangeItinerary = ArrangeTripItineraryUseCase()

    init(
        trip: GroupTrip,
        decisions: [GroupActivityDecision]
    ) {
        self.trip = trip

        self.acceptedActivities = decisions
            .filter { $0.isAccepted }
            .map { $0.activity }

        self.selectedDate = Calendar.current.startOfDay(
            for: trip.startDate
        )
    }

    // MARK: - Trip Dates

    var tripDates: [Date] {
        let calendar = Calendar.current

        var dates: [Date] = []
        var currentDate = calendar.startOfDay(for: trip.startDate)
        let finalDate = calendar.startOfDay(for: trip.endDate)

        while currentDate <= finalDate {
            dates.append(currentDate)

            guard let nextDate = calendar.date(
                byAdding: .day,
                value: 1,
                to: currentDate
            ) else {
                break
            }

            currentDate = nextDate
        }

        return dates
    }

    // MARK: - Activity Lists

    var unscheduledActivities: [ActivityCandidate] {
        let scheduledIDs = Set(
            scheduledActivities.map { $0.activity.id }
        )

        return acceptedActivities.filter {
            !scheduledIDs.contains($0.id)
        }
    }

    var scheduledActivityCount: Int {
        scheduledActivities.count
    }

    var totalAcceptedActivityCount: Int {
        acceptedActivities.count
    }

    func activities(on date: Date) -> [ScheduledTripActivity] {
        scheduledActivities
            .filter {
                Calendar.current.isDate(
                    $0.date,
                    inSameDayAs: date
                )
            }
            .sorted {
                $0.startMinutes < $1.startMinutes
            }
    }

    func activityCount(on date: Date) -> Int {
        activities(on: date).count
    }

    // MARK: - Scheduling

    func placeActivity(
        activityID: UUID,
        on date: Date,
        at startMinutes: Int
    ) {

        let startMinutes = snappedAndClampedStartTime(
            startMinutes,
            activityID: activityID
        )

        if let existingActivity = scheduledActivities.first(where: {
            $0.id == activityID
        }) {
            moveActivity(
                existingActivity,
                to: date,
                startMinutes: startMinutes
            )

            return
        }

        guard let activity = acceptedActivities.first(where: {
            $0.id == activityID
        }) else {
            return
        }

        do {
            let scheduledActivity = try arrangeItinerary.schedule(
                activity: activity,
                acceptedActivityIDs: Set(acceptedActivities.map(\.id)),
                date: date,
                startMinutes: startMinutes,
                trip: trip,
                existingActivities: scheduledActivities
            )

            scheduledActivities.append(scheduledActivity)
            errorMessage = nil

        } catch let error as ArrangeTripItineraryError {
            errorMessage = error.localizedDescription

        } catch {
            errorMessage = "The activity could not be added to the itinerary."
        }
    }

    func moveActivityByMinutes(
        activityID: UUID,
        minutes: Int
    ) {
        guard let activity = scheduledActivities.first(where: {
            $0.id == activityID
        }) else {
            return
        }

        let newStart = snappedAndClampedStartTime(
            activity.startMinutes + minutes,
            activityID: activityID
        )

        moveActivity(
            activity,
            to: activity.date,
            startMinutes: newStart
        )
    }

    func moveActivityToDate(
        activityID: UUID,
        date: Date
    ) {
        guard let activity = scheduledActivities.first(where: {
            $0.id == activityID
        }) else {
            return
        }

        moveActivity(
            activity,
            to: date,
            startMinutes: activity.startMinutes
        )
    }

    private func moveActivity(
        _ activity: ScheduledTripActivity,
        to date: Date,
        startMinutes: Int
    ) {

        do {
            let updatedActivity = try arrangeItinerary.move(
                activity: activity,
                to: date,
                startMinutes: startMinutes,
                trip: trip,
                existingActivities: scheduledActivities
            )

            replaceActivity(updatedActivity)
            errorMessage = nil

        } catch let error as ArrangeTripItineraryError {
            errorMessage = error.localizedDescription

        } catch {
            errorMessage = "The activity could not be moved."
        }
    }

    // MARK: - Duration

    func resizeActivity(
        activityID: UUID,
        durationMinutes: Int
    ) {
        guard let activity = scheduledActivities.first(where: {
            $0.id == activityID
        }) else {
            return
        }

        let newDuration = snapDuration(
            durationMinutes,
            for: activity
        )

        do {
            let updatedActivity = try arrangeItinerary.resize(
                activity: activity,
                durationMinutes: newDuration,
                trip: trip,
                existingActivities: scheduledActivities
            )

            replaceActivity(updatedActivity)
            errorMessage = nil

        } catch let error as ArrangeTripItineraryError {
            errorMessage = error.localizedDescription

        } catch {
            errorMessage = "The activity duration could not be changed."
        }
    }

    func removeActivity(_ activityID: UUID) {
        scheduledActivities.removeAll {
            $0.id == activityID
        }

        errorMessage = nil
    }

    // MARK: - Helpers

    private func replaceActivity(
        _ updatedActivity: ScheduledTripActivity
    ) {
        guard let index = scheduledActivities.firstIndex(where: {
            $0.id == updatedActivity.id
        }) else {
            return
        }

        scheduledActivities[index] = updatedActivity
    }

    private func snappedAndClampedStartTime(
        _ minutes: Int,
        activityID: UUID
    ) -> Int {

        let activity = scheduledActivities.first(where: {
            $0.id == activityID
        })?.activity
        ?? acceptedActivities.first(where: {
            $0.id == activityID
        })

        let duration = scheduledActivities.first(where: {
            $0.id == activityID
        })?.durationMinutes
        ?? activity?.suggestedDurationMinutes
        ?? 60

        let block = TripItineraryRules.timeBlockMinutes

        let snapped = Int(
            round(Double(minutes) / Double(block))
        ) * block

        let latestStart =
            TripItineraryRules.dayEndMinutes - duration

        return min(
            max(
                snapped,
                TripItineraryRules.dayStartMinutes
            ),
            latestStart
        )
    }

    private func snapDuration(
        _ duration: Int,
        for activity: ScheduledTripActivity
    ) -> Int {

        let block = TripItineraryRules.timeBlockMinutes

        let snapped = Int(
            round(Double(duration) / Double(block))
        ) * block

        let maximumDuration =
            TripItineraryRules.dayEndMinutes
            - activity.startMinutes

        return min(
            max(
                snapped,
                TripItineraryRules.minimumDurationMinutes
            ),
            maximumDuration
        )
    }

    func timeText(for minutes: Int) -> String {
        let hour = minutes / 60
        let minute = minutes % 60

        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"

        var components = DateComponents()
        components.hour = hour
        components.minute = minute

        let date = Calendar.current.date(
            from: components
        ) ?? Date()

        return formatter.string(from: date)
    }

    func durationText(_ minutes: Int) -> String {
        let hours = minutes / 60
        let remainingMinutes = minutes % 60

        if hours == 0 {
            return "\(remainingMinutes) min"
        }

        if remainingMinutes == 0 {
            return "\(hours) hr"
        }

        return "\(hours) hr \(remainingMinutes) min"
    }
}
