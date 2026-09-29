# Country Flag Trivia Quiz App

A modern Flutter quiz game where players guess countries from their flags.

## Features

- **195+ countries** fetched from REST Countries API v3.1
- **Flag images** via FlagCDN (`flagcdn.com/{iso}.png`)
- **4-option multiple choice** with non-repeating questions
- **Attempt-based scoring**: 10 / 8 / 5 points (1st / 2nd / 3rd attempt)
- **Visual feedback**: green = correct, red = incorrect, disabled after selection
- **Score header**: current score, solved count, remaining attempts
- **Game completion** screen with final score and reset button
- **Loading spinner** and graceful error handling with retry

## Architecture

```
lib/
├── main.dart                      # Entry point, Provider + MaterialApp
├── models/
│   ├── country.dart               # Country entity (name, isoCode, flagUrl)
│   └── option_status.dart         # Public enum: idle/correct/wrong/disabled
├── services/
│   └── country_service.dart       # HTTP → REST Countries API v3.1
├── providers/
│   └── quiz_provider.dart         # ChangeNotifier — all game state & logic
├── screens/
│   ├── home_screen.dart           # Loading / Error / Ready states
│   ├── quiz_screen.dart           # Flag + options + next button
│   └── game_completed_screen.dart # Final score + reset
└── widgets/
    ├── score_header.dart          # Score / Solved / Attempts indicator
    └── option_button.dart         # Answer option with feedback states
```

## State Management

Uses `provider` + `ChangeNotifier` for lightweight, testable state management.

## Getting Started

```bash
flutter pub get
flutter run
```

## Testing

```bash
flutter analyze   # 0 issues
flutter test      # 14 tests passing
```

## Scoring System

| Attempt | Points |
|---------|--------|
| 1st     | 10     |
| 2nd     | 8      |
| 3rd     | 5      |
| Fail    | 0      |
