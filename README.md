# DramaBox Free

An open-source Flutter application for streaming short dramas from Dramabox.

## Overview

DramaBox Free is a mobile app that allows users to browse and watch a curated selection of short dramas from Dramabox.

## Key Features

- **Premium UI/UX**: Custom-designed interface with dark mode aesthetics, glassmorphism, and smooth transitions.
- **Advanced Video Player**:
  - Intuitive gesture controls (long-press for 1.5x speed, double-tap to seek).
  - Intelligent auto-play next episode.
  - Seamless playback progress saving and resuming.
- **Modern Performance**:
  - Image loading with premium shimmer placeholders using `cached_network_image`.
  - Local data persistence with `hive` for offline caching.
  - Optimized network layer using `dio` and custom interceptors.

## Architecture

The project follows a standard Clean Architecture directory structure:

- `lib/core`: Core utilities, network clients, and DI configuration.
- `lib/data`: Models, DataSources, and Repository implementations.
- `lib/domain`: Business logic entities and Repository interfaces.
- `lib/presentation`: UI widgets, pages, and BLoC components.

## API Credit

This project uses the API services provided by **[Sansekai DramaBox API](https://dramabox.sansekai.my.id)**. Shoutout to the Sansekai for supplying the drama metadata and streaming endpoints.

## Getting Started

1. **Clone the repository**:
   ```bash
   git clone https://github.com/fahmih6/dramabox_free.git
   ```
2. **Install dependencies**:
   ```bash
   flutter pub get
   ```
3. **Configure Shorebird** (Optional):
   Follow the [Shorebird documentation](https://docs.shorebird.dev) to set up your account and `shorebird.yaml`.
4. **Run the app**:
   ```bash
   flutter run
   ```
