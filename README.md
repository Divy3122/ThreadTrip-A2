# ThreadTrip — Assignment 2

A SwiftUI app for six friends planning Tokyo, Kyoto and Osaka. It turns scattered social-media ideas into one shared activity deck, group votes and a trip plan.

This repository is a fresh, simplified rebuild of the earlier ThreadTrip prototype. The commits record the rebuild as it happens; the original repository remains available.

## Planned workflow

1. Trip overview: choose shared interests and budget, then lock one activity deck.
2. Activity voting: every traveller responds Yes or No to the same deck in the same order.
3. Group decision dashboard: every activity with counts from its own voting round.
4. Shared itinerary: schedule accepted activities.

## Setup

Open `ThreadTrip.xcodeproj` in Xcode 16 or newer, choose the ThreadTrip scheme and an iPhone simulator with iOS 17 or newer. Command-R runs the app; Command-U runs the tests. No external dependencies.

## Structure and architecture

Use a flat app folder. Related domain types share a file, each screen has a View and ViewModel, and each business operation has a Use Case with domain errors. The flow is View → ViewModel → Use Case → domain models/catalogue.

## Development history

- Project setup: runnable app shell and assignment requirements.
- `feature/trip-overview`: Screen 1, catalogue, locked deck generation and tests.
- `feature/activity-voting`: Screen 2, individual responses and tests.

`main` holds tested milestones. Feature branches start from `develop`. Commits use Conventional Commits. The dashboard and planner remain future work.
