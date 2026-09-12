//
//  SharedItineraryView.swift
//  ThreadTrip
//
//  Created by Divy Patel on 12/9/2026.
//

import SwiftUI

struct SharedItineraryView: View {

    @StateObject private var viewModel: SharedItineraryViewModel

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var selectedActivity: ActivityCandidate?
    @State private var isEditingScheduledActivity = false

    private let coral = Color(red: 0.88, green: 0.25, blue: 0.22)
    private let indigo = Color(red: 0.27, green: 0.24, blue: 0.57)

    private let hourHeight: CGFloat = 72

    private var cardColor: Color {
        Color(uiColor: .secondarySystemGroupedBackground)
    }

    private var canvas: Color {
        if colorScheme == .dark {
            return Color(uiColor: .systemGroupedBackground)
        }

        return Color(red: 0.97, green: 0.96, blue: 0.94)
    }

    init(
        trip: GroupTrip,
        decisions: [GroupActivityDecision]
    ) {
        _viewModel = StateObject(
            wrappedValue: SharedItineraryViewModel(
                trip: trip,
                decisions: decisions
            )
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                header
                progressCard

                if let message = viewModel.errorMessage {
                    errorCard(message)
                }

                if horizontalSizeClass == .regular {

                    HStack(alignment: .top, spacing: 16) {

                        activityTray
                            .frame(width: 220)

                        dayPlanner
                    }

                } else {

                    VStack(alignment: .leading, spacing: 18) {
                        mobileActivityTray
                        dayPlanner
                    }
                }
            }
            .padding(20)
            .frame(maxWidth: 900)
            .frame(maxWidth: .infinity)
        }
        .scrollDisabled(isEditingScheduledActivity)
        .background(canvas.ignoresSafeArea())
        .navigationTitle("Shared itinerary")
        .navigationBarTitleDisplayMode(.inline)
        .tint(coral)
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {

            HStack {

                Text("BUILD THE PLAN")
                    .font(.caption2.bold())
                    .tracking(1.1)
                    .foregroundStyle(coral)

                Spacer()

                Text("4 of 4")
                    .font(.caption.bold())
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(
                        coral.opacity(0.10),
                        in: Capsule()
                    )
            }

            Text("Turn the winners into a real trip.")
                .font(.title2.bold())

            Text(
                "Choose an activity, place it into the calendar, then adjust the time and duration."
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
    }

    // MARK: - Progress

    private var progressCard: some View {
        HStack(spacing: 18) {

            VStack(alignment: .leading, spacing: 5) {

                Text("ITINERARY PROGRESS")
                    .font(.caption2.bold())
                    .tracking(0.8)
                    .foregroundStyle(.white.opacity(0.8))

                Text(
                    "\(viewModel.scheduledActivityCount) of \(viewModel.totalAcceptedActivityCount) planned"
                )
                .font(.title3.bold())
                .foregroundStyle(.white)
            }

            Spacer()

            Image(systemName: "calendar.badge.checkmark")
                .font(.title2)
                .foregroundStyle(.white)
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [
                    indigo,
                    Color(
                        red: 0.49,
                        green: 0.28,
                        blue: 0.53
                    )
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 22)
        )
    }

    // MARK: - Activity Tray

    private var activityTray: some View {
        VStack(alignment: .leading, spacing: 14) {

            trayHeader

            if viewModel.unscheduledActivities.isEmpty {

                allActivitiesPlannedCard

            } else {

                ForEach(viewModel.unscheduledActivities) { activity in
                    activityCard(activity)
                }
            }
        }
        .padding(16)
        .background(
            cardColor,
            in: RoundedRectangle(cornerRadius: 22)
        )
    }

    private var mobileActivityTray: some View {
        VStack(alignment: .leading, spacing: 12) {

            trayHeader

            if viewModel.unscheduledActivities.isEmpty {

                allActivitiesPlannedCard

            } else {

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {

                        ForEach(viewModel.unscheduledActivities) { activity in
                            activityCard(activity)
                                .frame(width: 180)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(
            cardColor,
            in: RoundedRectangle(cornerRadius: 22)
        )
    }

    private var trayHeader: some View {
        VStack(alignment: .leading, spacing: 4) {

            Text("MADE THE CUT")
                .font(.caption2.bold())
                .tracking(0.8)
                .foregroundStyle(coral)

            Text("Choose an activity")
                .font(.headline)

            Text(
                "\(viewModel.unscheduledActivities.count) left to place"
            )
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }

    private func activityCard(
        _ activity: ActivityCandidate
    ) -> some View {

        let isSelected =
            selectedActivity?.id == activity.id

        return Button {
            selectActivity(activity)
        } label: {

            VStack(alignment: .leading, spacing: 10) {

                HStack {

                    Image(systemName: activity.symbolName)
                        .foregroundStyle(
                            isSelected ? .white : coral
                        )

                    Spacer()

                    Image(
                        systemName:
                            isSelected
                            ? "checkmark.circle.fill"
                            : "plus.circle"
                    )
                    .font(.title3)
                }

                Text(activity.title)
                    .font(.subheadline.bold())
                    .lineLimit(2)

                Text(activity.city)
                    .font(.caption)

                Label(
                    viewModel.durationText(
                        activity.suggestedDurationMinutes
                    ),
                    systemImage: "clock"
                )
                .font(.caption)
            }
            .foregroundStyle(
                isSelected
                ? Color.white
                : Color.primary
            )
            .padding(14)
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
            .background(
                isSelected
                ? indigo
                : Color(
                    uiColor:
                        .tertiarySystemGroupedBackground
                ),
                in: RoundedRectangle(
                    cornerRadius: 16
                )
            )
        }
        .buttonStyle(.plain)
    }

    private func selectActivity(
        _ activity: ActivityCandidate
    ) {
        viewModel.errorMessage = nil

        if selectedActivity?.id == activity.id {
            selectedActivity = nil
        } else {
            selectedActivity = activity
        }
    }

    private var allActivitiesPlannedCard: some View {
        Label(
            "Everything has been placed",
            systemImage: "checkmark.circle.fill"
        )
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(indigo)
        .padding(14)
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .background(
            indigo.opacity(0.08),
            in: RoundedRectangle(cornerRadius: 14)
        )
    }

    // MARK: - Selected Activity Banner

    @ViewBuilder
    private var placementBanner: some View {

        if let selectedActivity {

            HStack(spacing: 12) {

                Image(
                    systemName:
                        selectedActivity.symbolName
                )
                .font(.title3)

                VStack(
                    alignment: .leading,
                    spacing: 2
                ) {

                    Text("READY TO PLACE")
                        .font(.caption2.bold())
                        .tracking(0.6)
                        .foregroundStyle(
                            .white.opacity(0.8)
                        )

                    Text(selectedActivity.title)
                        .font(.subheadline.bold())
                }

                Spacer()

                Button {
                    self.selectedActivity = nil
                } label: {

                    Image(
                        systemName: "xmark.circle.fill"
                    )
                    .font(.title3)
                }
            }
            .foregroundStyle(.white)
            .padding(14)
            .background(
                indigo,
                in: RoundedRectangle(
                    cornerRadius: 16
                )
            )
        }
    }

    // MARK: - Day Planner

    private var dayPlanner: some View {
        VStack(alignment: .leading, spacing: 14) {

            Text("TRIP CALENDAR")
                .font(.caption2.bold())
                .tracking(0.8)
                .foregroundStyle(.secondary)

            dateStrip

            placementBanner

            HStack {

                VStack(
                    alignment: .leading,
                    spacing: 3
                ) {

                    Text(
                        viewModel.selectedDate.formatted(
                            .dateTime
                                .weekday(.wide)
                                .month(.wide)
                                .day()
                        )
                    )
                    .font(.headline)

                    if selectedActivity != nil {

                        Text(
                            "Tap an empty time to place the activity"
                        )
                        .font(.caption)
                        .foregroundStyle(coral)

                    } else {

                        Text(
                            "Choose an activity above to start planning"
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Text(
                    "\(viewModel.activityCount(on: viewModel.selectedDate)) planned"
                )
                .font(.caption.bold())
                .foregroundStyle(indigo)
            }

            timeline
        }
        .padding(16)
        .background(
            cardColor,
            in: RoundedRectangle(cornerRadius: 22)
        )
    }

    // MARK: - Dates

    private var dateStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {

            HStack(spacing: 9) {

                ForEach(
                    viewModel.tripDates,
                    id: \.self
                ) { date in

                    dateButton(date)
                }
            }
        }
    }

    private func dateButton(
        _ date: Date
    ) -> some View {

        let selected =
            Calendar.current.isDate(
                date,
                inSameDayAs:
                    viewModel.selectedDate
            )

        let count =
            viewModel.activityCount(on: date)

        return Button {

            viewModel.selectedDate = date

        } label: {

            VStack(spacing: 4) {

                Text(
                    date.formatted(
                        .dateTime
                            .weekday(.abbreviated)
                    )
                )
                .font(.caption2.bold())

                Text(
                    date.formatted(
                        .dateTime.day()
                    )
                )
                .font(.headline)

                if count > 0 {

                    Text("\(count)")
                        .font(.caption2.bold())
                        .foregroundStyle(
                            selected
                            ? .white
                            : indigo
                        )

                } else {

                    Circle()
                        .fill(.clear)
                        .frame(
                            width: 10,
                            height: 10
                        )
                }
            }
            .frame(
                width: 50,
                height: 66
            )
            .foregroundStyle(
                selected
                ? Color.white
                : Color.primary
            )
            .background(
                selected
                ? indigo
                : Color(
                    uiColor:
                        .tertiarySystemGroupedBackground
                ),
                in: RoundedRectangle(
                    cornerRadius: 14
                )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Timeline

    private var timeline: some View {
        HStack(
            alignment: .top,
            spacing: 8
        ) {

            timeLabels
            timelineCanvas
        }
    }

    private var timeLabels: some View {
        VStack(spacing: 0) {

            ForEach(
                TripItineraryRules.dayStartMinutes / 60
                ..< TripItineraryRules.dayEndMinutes / 60,
                id: \.self
            ) { hour in

                Text(hourText(hour))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(
                        width: 46,
                        height: hourHeight,
                        alignment: .topTrailing
                    )
            }
        }
    }

    private var timelineCanvas: some View {

        let totalHours =
            (
                TripItineraryRules.dayEndMinutes
                - TripItineraryRules.dayStartMinutes
            ) / 60

        let timelineHeight =
            CGFloat(totalHours) * hourHeight

        return ZStack(
            alignment: .topLeading
        ) {

            timelineGrid
                .contentShape(Rectangle())
                .gesture(
                    placementGesture
                )

            ForEach(
                viewModel.activities(
                    on: viewModel.selectedDate
                )
            ) { activity in

                ScheduledActivityBlock(
                    activity: activity,
                    hourHeight: hourHeight,
                    indigo: indigo,
                    timeText: viewModel.timeText,
                    durationText: viewModel.durationText,
                    onInteractionChanged: { isEditing in
                        isEditingScheduledActivity = isEditing
                    },
                    onMove: { minutes in

                        viewModel.moveActivityByMinutes(
                            activityID: activity.id,
                            minutes: minutes
                        )
                    },
                    onResize: { duration in

                        viewModel.resizeActivity(
                            activityID: activity.id,
                            durationMinutes: duration
                        )
                    },
                    onRemove: {

                        viewModel.removeActivity(
                            activity.id
                        )
                    }
                )
                .padding(.horizontal, 8)
                .offset(
                    y: yPosition(
                        for: activity.startMinutes
                    )
                )
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: timelineHeight)
        .background(
            Color(
                uiColor:
                    .tertiarySystemGroupedBackground
            ),
            in: RoundedRectangle(
                cornerRadius: 16
            )
        )
        .overlay {

            if selectedActivity != nil {

                RoundedRectangle(
                    cornerRadius: 16
                )
                .stroke(
                    coral.opacity(0.45),
                    style: StrokeStyle(
                        lineWidth: 2,
                        dash: [8]
                    )
                )
                .allowsHitTesting(false)
            }
        }
    }

    private var timelineGrid: some View {
        VStack(spacing: 0) {

            ForEach(
                TripItineraryRules.dayStartMinutes / 60
                ..< TripItineraryRules.dayEndMinutes / 60,
                id: \.self
            ) { _ in

                Rectangle()
                    .fill(
                        Color.secondary.opacity(0.16)
                    )
                    .frame(height: 1)

                Spacer()
                    .frame(
                        height: hourHeight - 1
                    )
            }
        }
    }

    // MARK: - Place Activity

    private var placementGesture: some Gesture {

        DragGesture(minimumDistance: 0)
            .onEnded { value in

                guard
                    abs(value.translation.width) < 10,
                    abs(value.translation.height) < 10
                else {
                    return
                }

                guard let activity = selectedActivity else {
                    return
                }

                let startMinutes =
                    minutesFromTimelinePosition(
                        value.location.y
                    )

                withAnimation(
                    .spring(
                        response: 0.30,
                        dampingFraction: 0.85
                    )
                ) {

                    viewModel.placeActivity(
                        activityID: activity.id,
                        on: viewModel.selectedDate,
                        at: startMinutes
                    )
                }

                if viewModel.errorMessage == nil {
                    selectedActivity = nil
                }
            }
    }

    // MARK: - Timeline Maths

    private func yPosition(
        for startMinutes: Int
    ) -> CGFloat {

        let minutesAfterStart =
            startMinutes
            - TripItineraryRules.dayStartMinutes

        return CGFloat(minutesAfterStart)
        / 60
        * hourHeight
    }

    private func minutesFromTimelinePosition(
        _ yPosition: CGFloat
    ) -> Int {

        let minutesFromStart =
            Int(
                (
                    yPosition
                    / hourHeight
                )
                * 60
            )

        let rawMinutes =
            TripItineraryRules.dayStartMinutes
            + minutesFromStart

        let block =
            TripItineraryRules.timeBlockMinutes

        return Int(
            round(
                Double(rawMinutes)
                / Double(block)
            )
        ) * block
    }

    private func hourText(
        _ hour: Int
    ) -> String {

        let formatter = DateFormatter()
        formatter.dateFormat = "ha"

        var components = DateComponents()
        components.hour = hour

        let date =
            Calendar.current.date(
                from: components
            ) ?? Date()

        return formatter
            .string(from: date)
            .lowercased()
    }

    // MARK: - Error

    private func errorCard(
        _ message: String
    ) -> some View {

        Label(
            message,
            systemImage:
                "exclamationmark.triangle.fill"
        )
        .font(.subheadline)
        .foregroundStyle(coral)
        .padding(16)
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .background(
            cardColor,
            in: RoundedRectangle(
                cornerRadius: 16
            )
        )
    }
}


// MARK: - Scheduled Activity Block



private struct ScheduledActivityBlock: View {

    let activity: ScheduledTripActivity

    let hourHeight: CGFloat
    let indigo: Color

    let timeText: (Int) -> String
    let durationText: (Int) -> String

    let onInteractionChanged: (Bool) -> Void
    let onMove: (Int) -> Void
    let onResize: (Int) -> Void
    let onRemove: () -> Void

    @GestureState private var dragTranslation: CGFloat = 0
    @GestureState private var resizeTranslation: CGFloat = 0

    private var baseHeight: CGFloat {
        max(
            CGFloat(activity.durationMinutes) / 60 * hourHeight,
            80
        )
    }

    private var displayedHeight: CGFloat {
        max(
            baseHeight + resizeTranslation,
            80
        )
    }

    var body: some View {
        VStack(spacing: 0) {

            activityContent
                .frame(maxHeight: .infinity)
                .contentShape(Rectangle())
                .highPriorityGesture(moveGesture)

            resizeHandle
        }
        .frame(height: displayedHeight)
        .background(
            LinearGradient(
                colors: [
                    indigo,
                    indigo.opacity(0.82)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 15)
        )
        .shadow(
            color: indigo.opacity(0.16),
            radius: dragTranslation == 0 ? 8 : 14,
            y: dragTranslation == 0 ? 4 : 8
        )
        .scaleEffect(
            dragTranslation == 0 ? 1 : 1.015
        )
        .offset(y: dragTranslation)
        .zIndex(
            dragTranslation == 0 ? 0 : 10
        )
        .contextMenu {

            Button(
                "Return to activity list",
                systemImage: "arrow.uturn.backward"
            ) {
                onRemove()
            }
        }
    }

    // MARK: - Activity Content

    private var activityContent: some View {
        VStack(
            alignment: .leading,
            spacing: 6
        ) {

            HStack(alignment: .top) {

                Image(
                    systemName: activity.activity.symbolName
                )

                Text(activity.activity.title)
                    .font(.subheadline.bold())
                    .lineLimit(2)

                Spacer()

                Image(systemName: "hand.draw.fill")
                    .foregroundStyle(
                        .white.opacity(0.8)
                    )
            }

            Text(
                "\(timeText(activity.startMinutes)) – \(timeText(activity.endMinutes))"
            )
            .font(.caption.bold())

            Label(
                durationText(
                    activity.durationMinutes
                ),
                systemImage: "clock"
            )
            .font(.caption)

            if displayedHeight > 120 {
                Text(activity.activity.city)
                    .font(.caption)
                    .foregroundStyle(
                        .white.opacity(0.80)
                    )
            }
        }
        .foregroundStyle(.white)
        .padding(12)
    }

    // MARK: - Resize Handle

    private var resizeHandle: some View {
        VStack(spacing: 4) {

            Capsule()
                .fill(
                    .white.opacity(0.9)
                )
                .frame(
                    width: 34,
                    height: 4
                )

            Text("Drag to resize")
                .font(.caption2)
                .foregroundStyle(
                    .white.opacity(0.75)
                )
        }
        .frame(height: 28)
        .frame(maxWidth: .infinity)
        .background(
            .black.opacity(0.08)
        )
        .contentShape(Rectangle())
        .highPriorityGesture(resizeGesture)
    }

    // MARK: - Move Gesture

    private var moveGesture: some Gesture {
        DragGesture(minimumDistance: 1)

            .updating(
                $dragTranslation
            ) { value, state, _ in

                state = value.translation.height
            }

            .onChanged { _ in
                onInteractionChanged(true)
            }

            .onEnded { value in

                let minuteChange =
                    minutesFromTranslation(
                        value.translation.height
                    )

                onInteractionChanged(false)

                withAnimation(
                    .smooth(duration: 0.18)
                ) {
                    onMove(minuteChange)
                }
            }
    }

    // MARK: - Resize Gesture

    private var resizeGesture: some Gesture {
        DragGesture(minimumDistance: 1)

            .updating(
                $resizeTranslation
            ) { value, state, _ in

                state = value.translation.height
            }

            .onChanged { _ in
                onInteractionChanged(true)
            }

            .onEnded { value in

                let minuteChange =
                    minutesFromTranslation(
                        value.translation.height
                    )

                let newDuration =
                    activity.durationMinutes
                    + minuteChange

                onInteractionChanged(false)

                withAnimation(
                    .smooth(duration: 0.18)
                ) {
                    onResize(newDuration)
                }
            }
    }

    // MARK: - Time Conversion

    private func minutesFromTranslation(
        _ height: CGFloat
    ) -> Int {

        let rawMinutes =
            Double(height / hourHeight) * 60

        let block =
            TripItineraryRules.timeBlockMinutes

        return Int(
            round(
                rawMinutes
                / Double(block)
            )
        ) * block
    }
}
