# ThreadTrip — Assignment 2

ThreadTrip is a collaborative group-trip planning app that helps friends turn scattered travel ideas into one shared itinerary.

The prototype focuses on a Japan trip across Tokyo, Kyoto and Osaka. It demonstrates the full planning flow from choosing group preferences, to voting on activities, reviewing the group result, and finally scheduling accepted activities into a shared itinerary.

The current demo uses three active travellers: You, Alex and Maya.

## Current progress

| Screen | What it does | Status |
| --- | --- | --- |
| 1. Trip Overview | Set shared preferences, activity budget and decision rule; generate one locked activity deck | Implemented |
| 2. Activity Voting | Each traveller votes Yes or No on the same ordered activity deck | Implemented |
| 3. Group Decision Dashboard | Show complete group results and determine which activities made the cut | Implemented |
| 4. Shared Itinerary | Schedule accepted activities across the trip dates and times | Implemented |

The prototype uses a bundled `japan_activities.json` catalogue rather than a live travel or social-media API.

Trip, voting and itinerary state are currently stored in memory for the prototype.

## Open and run

1. Clone the repository.
2. Open `ThreadTrip.xcodeproj` in Xcode.
3. Select the **ThreadTrip** scheme.
4. Choose an iPhone simulator.
5. Use **Command-R** to run the application.
6. Use **Command-U** to run the test suite.

There are no external package dependencies.

---

## Screen 1 — Trip Overview

Screen 1 creates the shared planning context used by the rest of the application.

The overview displays:

- Japan trip dates
- Tokyo, Kyoto and Osaka
- the trip budget
- active travellers
- shared travel interests
- activity spending limit
- group decision rule

The group chooses its shared interests and maximum activity cost before generating an activity deck.

The available decision policies are:

- Majority
- 75% Yes
- Everyone

When **Generate shared activity deck** is selected, the app loads suitable activities from the local JSON catalogue.

A `TripVotingRound` then locks:

- the selected activity IDs,
- the exact activity order,
- and the eligible traveller IDs.

This ensures every traveller votes on the same activity set rather than receiving personalised decks.

Once the deck exists, the group preferences become part of that voting round and the user can continue to Screen 2.

**Code path:**

`TripOverviewView`  
→ `TripOverviewViewModel`  
→ `GenerateGroupActivityDeckUseCase`  
→ `TravelActivityCatalogue`  
→ `GeneratedGroupActivityDeck`

---

## Screen 2 — Activity Voting

Screen 2 lets every eligible traveller vote on the locked activity deck.

The local traveller selector is used to demonstrate multiple group members voting on one device.

Each activity displays information such as:

- activity title
- city
- category
- description
- expected cost
- suggested duration

A traveller can:

- swipe right or tap **Yes**
- swipe left or tap **No**

Each valid response is stored as an `ActivitySwipe`.

Every response includes:

- voting round ID
- activity ID
- traveller ID
- Yes or No choice

The recording Use Case prevents invalid voting behaviour such as:

- duplicate responses,
- voting by an ineligible traveller,
- voting for an activity outside the locked deck,
- or adding responses to the wrong voting round.

Each traveller continues from their own unanswered activity while still seeing the exact same deck as every other traveller.

Screen 3 becomes available only after the required group voting is complete.

**Code path:**

`GroupSwipeDeckView`  
→ `GroupSwipeDeckViewModel`  
→ `RecordActivitySwipeUseCase`  
→ `ActivitySwipe`

---

## Screen 3 — Group Decision Dashboard

Screen 3 converts the completed voting round into one group result.

The dashboard uses the exact locked voting round from Screens 1 and 2.

Every activity is shown in the original shared deck order.

For each activity, the dashboard displays:

- Yes vote count
- No vote count
- eligible traveller count
- group support percentage
- whether the activity made the cut

The selected `GroupDecisionPolicy` determines whether an activity is accepted.

For example:

### Majority

More than half of eligible travellers must vote Yes.

### 75% Yes

At least 75% of eligible travellers must vote Yes.

### Everyone

Every eligible traveller must vote Yes.

The dashboard also displays a group summary showing how many activities were accepted and rejected.

The result builder protects the voting process by ensuring:

- only responses from the correct voting round are counted,
- every eligible traveller has voted,
- every locked activity is included,
- duplicate traveller responses are rejected,
- missing responses are not treated as No votes,
- the original activity order is preserved.

Accepted activities become the input for Screen 4.

**Code path:**

`GroupDecisionDashboardView`  
→ `GroupDecisionDashboardViewModel`  
→ `BuildGroupDecisionDashboardUseCase`  
→ `GroupActivityDecision`

---

## Screen 4 — Shared Itinerary

Screen 4 turns the activities that made the cut into a usable trip schedule.

Only activities accepted by the Group Decision Dashboard are available for planning.

The screen displays:

- the full trip date range,
- accepted activities that have not yet been scheduled,
- the currently selected trip day,
- a daily timetable,
- and itinerary progress.

### Placing an activity

The user first selects an accepted activity from the **Made the Cut** section.

The activity becomes highlighted and ready to place.

The user then taps an empty time in the calendar.

The activity is inserted into the selected day using its suggested duration.

### Moving an activity

Once an activity is scheduled, the activity block can be dragged vertically through the calendar.

Movement snaps to 30-minute scheduling blocks.

The interaction follows the calendar directly while dragging and smoothly settles into the new time when released.

### Resizing an activity

A resize handle appears at the bottom of each scheduled activity.

Dragging the handle changes the activity duration.

Durations also snap to 30-minute blocks.

### Removing an activity

A scheduled activity can be returned to the unscheduled activity list and placed again later.

### Trip dates

The date selector represents the full Japan trip from the start date through to the end date.

Each day shows how many activities have already been planned.

The daily timetable runs from:

- **6:00 am**
- through to **11:00 pm**

### Itinerary business rules

`ArrangeTripItineraryUseCase` protects the itinerary rules.

The planner prevents:

- rejected activities from entering the itinerary,
- the same activity being scheduled more than once,
- scheduling outside the trip date range,
- activities outside the allowed planning day,
- times or durations that do not use 30-minute blocks,
- activities overlapping on the same day.

These rules stay outside the SwiftUI interface so the View only handles the interaction and presentation.

**Code path:**

`SharedItineraryView`  
→ `SharedItineraryViewModel`  
→ `ArrangeTripItineraryUseCase`  
→ `ScheduledTripActivity`

---

## Domain-centred architecture

ThreadTrip uses domain names throughout the application instead of generic technical names.

Important domain types include:

- `GroupTrip`
- `TripMember`
- `TravelTasteProfile`
- `ActivityCandidate`
- `GeneratedGroupActivityDeck`
- `TripVotingRound`
- `ActivitySwipe`
- `GroupActivityDecision`
- `ScheduledTripActivity`
- `GroupDecisionPolicy`

These types represent real concepts from collaborative group-trip planning.

### Views

Views are responsible for presenting information and receiving interaction.

The four main views are:

- `TripOverviewView`
- `GroupSwipeDeckView`
- `GroupDecisionDashboardView`
- `SharedItineraryView`

### ViewModels

Each main screen has a ViewModel that owns its presentation state.

- `TripOverviewViewModel`
- `GroupSwipeDeckViewModel`
- `GroupDecisionDashboardViewModel`
- `SharedItineraryViewModel`

### Use Cases

Business operations are kept outside the SwiftUI views.

- `GenerateGroupActivityDeckUseCase`
- `RecordActivitySwipeUseCase`
- `BuildGroupDecisionDashboardUseCase`
- `ArrangeTripItineraryUseCase`

This separation means the interface does not directly control important business rules such as voting eligibility, decision thresholds or itinerary overlap detection.

---

## Important business rules

The application keeps several rules consistent across all four screens.

### Shared deck

Every traveller receives the same locked activity candidates in the same order.

### Voting

Each eligible traveller can vote once on each activity.

Votes must belong to the current voting round.

### Group decisions

Every required response must exist before the group result can be created.

Missing responses are never silently counted as No.

### Itinerary

Only activities that made the cut can be scheduled.

An accepted activity can appear only once.

Activities must:

- stay inside the trip dates,
- use 30-minute blocks,
- remain between 6:00 am and 11:00 pm,
- and not overlap another activity on the same day.

---

## Project structure

```text
ThreadTrip-A2/
├── README.md
├── ASSIGNMENT_REQUIREMENTS.md
├── ThreadTrip.xcodeproj/
│
├── ThreadTrip/
│   ├── ThreadTripApp.swift
│
│   ├── GroupTrip.swift
│   ├── ActivityCandidate.swift
│   ├── TripVotingRound.swift
│   ├── TripItinerary.swift
│   ├── TravelActivityCatalogue.swift
│
│   ├── GenerateGroupActivityDeckUseCase.swift
│   ├── RecordActivitySwipeUseCase.swift
│   ├── BuildGroupDecisionDashboardUseCase.swift
│   ├── ArrangeTripItineraryUseCase.swift
│
│   ├── TripOverviewViewModel.swift
│   ├── GroupSwipeDeckViewModel.swift
│   ├── GroupDecisionDashboardViewModel.swift
│   ├── SharedItineraryViewModel.swift
│
│   ├── TripOverviewView.swift
│   ├── GroupSwipeDeckView.swift
│   ├── GroupDecisionDashboardView.swift
│   ├── SharedItineraryView.swift
│
│   ├── japan_activities.json
│   └── Assets.xcassets/
│
└── ThreadTripTests/
