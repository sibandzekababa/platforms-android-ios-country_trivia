# Country Flag Trivia Quiz — Master Plan

## 1. Project Overview

A Flutter-based mobile quiz game where users guess countries from their flags. The app fetches country data from a REST API, presents multiple-choice questions with attempt-based scoring, and tracks progress until all countries are exhausted.

---

## 2. Architecture

### 2.1 High-Level Diagram

```
┌─────────────────────────────────────────────────────┐
│                    UI Layer (Screens)                │
│  HomeScreen → QuizScreen → GameCompletedScreen      │
│  Widgets: ScoreHeader, OptionButton                 │
└──────────────────────┬──────────────────────────────┘
                       │ Consumer / context.watch
┌──────────────────────▼──────────────────────────────┐
│              State Management (Provider)             │
│                  QuizProvider                        │
│  - QuizStatus enum (loading/error/ready/playing/done) │
│  - Country pool, solved set, score, attempts        │
└──────────────────────┬──────────────────────────────┘
                       │ calls
┌──────────────────────▼──────────────────────────────┐
│              Service Layer                           │
│              CountryService                          │
│  - HTTP GET → restcountries.com/v3.1/all           │
│  - JSON → List<Country>                             │
└──────────────────────┬──────────────────────────────┘
                       │ uses
┌──────────────────────▼──────────────────────────────┐
│              Model Layer                             │
│              Country                                 │
│  - name, isoCode, flagUrl (computed)                │
└─────────────────────────────────────────────────────┘
```

### 2.2 State Management: Provider + ChangeNotifier

| Component | Responsibility |
|-----------|---------------|
| `QuizProvider` | Single source of truth for all quiz state |
| `QuizStatus` enum | Finite state machine: `loading → error → ready → playing → completed` |
| `Consumer<QuizProvider>` | Rebuilds UI reactively on state changes |
| `context.read<QuizProvider>()` | One-shot access for event handlers |

### 2.3 Data Flow

```
API Fetch → CountryService → List<Country> → QuizProvider._allCountries
                                                      ↓
                                            _generateQuestion()
                                            ├── Pick 1 correct from unsolved pool
                                            ├── Pick 3 distractors from remaining pool
                                            └── Shuffle → _options
                                                      ↓
                                            User taps OptionButton
                                            → selectOption(isoCode)
                                            → Update score / attempts / solved set
                                            → notifyListeners()
                                            → UI rebuilds with color feedback
                                                      ↓
                                            nextQuestion()
                                            ├── Pool exhausted? → status = completed
                                            └── Otherwise → _generateQuestion()
```

---

## 3. File Structure

```
lib/
├── main.dart                      # App entry, ChangeNotifierProvider setup
├── models/
│   └── country.dart               # Country model (name, isoCode, flagUrl)
├── services/
│   └── country_service.dart       # HTTP client, API call, error handling
├── providers/
│   └── quiz_provider.dart         # All game logic & state
├── screens/
│   ├── home_screen.dart           # Loading / Error / Ready states
│   ├── quiz_screen.dart           # Main gameplay screen
│   └── game_completed_screen.dart # Final score + reset
└── widgets/
    ├── score_header.dart          # Score, progress, attempts indicator
    └── option_button.dart         # Answer option with color feedback
```

---

## 4. Game Logic Specification

### 4.1 Question Generation

1. Pool = all countries minus solved (tracked by ISO code in a `Set<String>`)
2. Correct answer = random pick from pool
3. Distractors = 3 random picks from pool excluding correct answer
4. Options = [correct, ...distractors] shuffled

### 4.2 Scoring

| Attempt | Points |
|---------|--------|
| 1st     | 10     |
| 2nd     | 8      |
| 3rd     | 5      |
| Fail    | 0      |

### 4.3 Lifecycle

```
App Launch → loadGame() → [API Call]
  ├── Success → status = ready → Start Game → status = playing
  │     ├── Correct answer → mark solved → nextQuestion()
  │     ├── Wrong (attempts left) → disable option, retry
  │     └── Wrong (no attempts) → reveal answer → nextQuestion()
  │           └── Pool empty? → status = completed → GameCompletedScreen
  └── Failure → status = error → Retry button → loadGame()
```

### 4.4 Non-Repeating Guarantee

- `_solvedIsoCodes: Set<String>` stores ISO codes of all correctly answered countries
- `_generateQuestion()` filters: `pool = all.where((c) => !solved.contains(c.isoCode))`
- Even failed questions are added to solved set (country is "completed" once revealed)

---

## 5. API & Data Sources

| Resource | URL | Purpose |
|----------|-----|---------|
| Country data | `https://restcountries.com/v3.1/all?fields=name,cca2` | Fetch country names + ISO codes |
| Flag images | `https://flagcdn.com/{iso}.png` | Display flag by lowercase ISO code |

### API Response Format (relevant fields)

```json
[
  {
    "name": { "common": "Germany", "official": "..." },
    "cca2": "DE"
  }
]
```

---

## 6. UI/UX Specification

### 6.1 Screens

| Screen | States | Key Elements |
|--------|--------|-------------|
| HomeScreen | Loading | CircularProgressIndicator + "Loading countries…" |
| HomeScreen | Error | Error icon, message, Retry button |
| HomeScreen | Ready | Game title, rules summary, Start button |
| QuizScreen | Playing | Flag card, 4 options, score header |
| QuizScreen | Answered | Green/red highlight, Next button |
| GameCompleted | — | Trophy icon, final score, Reset button |

### 6.2 Visual Feedback

| State | Background | Border | Icon |
|-------|-----------|--------|------|
| Idle | surface | grey | — |
| Correct | green.shade50 | green | check_circle |
| Wrong | red.shade50 | red | cancel |
| Disabled | grey.shade100 | grey | — |

### 6.3 Score Header

Three stats displayed in a card:
- **Score** (star icon, amber)
- **Solved** (flag icon, blue) — format: `15 / 195`
- **Attempts** (heart icon, green/red) — remaining attempts for current flag

---

## 7. Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| `http` | ^1.2.2 | REST API calls |
| `provider` | ^6.1.2 | State management |

---

## 8. Execution Plan

### Phase 1: Foundation ✅
- [x] Define `Country` model with JSON parsing
- [x] Implement `CountryService` with HTTP + error handling
- [x] Set up `pubspec.yaml` dependencies

### Phase 2: State Management ✅
- [x] Implement `QuizProvider` with full game logic
- [x] Question generation (1 correct + 3 distractors, shuffled)
- [x] Attempt-based scoring (10/8/5)
- [x] Non-repeating pool via solved set
- [x] Game completion detection

### Phase 3: UI Layer ✅
- [x] HomeScreen with loading/error/ready states
- [x] QuizScreen with flag display and option buttons
- [x] ScoreHeader widget (score, progress, attempts)
- [x] OptionButton with 4 visual states
- [x] GameCompletedScreen with final score + reset

### Phase 4: Polish & Testing
- [ ] Add widget tests for QuizProvider logic
- [ ] Add golden tests for UI screens
- [ ] Test edge cases: empty API response, network timeout, duplicate countries
- [ ] Verify flag CDN loads for all ISO codes
- [ ] Add pull-to-refresh or manual refresh on error

### Phase 5: Enhancements (Future)
- [ ] Difficulty levels (more distractors, time limits)
- [ ] Streak bonuses
- [ ] Leaderboard / high score persistence (SharedPreferences)
- [ ] Sound effects and haptic feedback
- [ ] Flag animation transitions between questions
- [ ] Category filters (by continent, region)

---

## 9. Testing Strategy

### Unit Tests (QuizProvider)
- Question generation produces exactly 4 unique options
- Correct answer is always in the options list
- Scoring: 1st=10, 2nd=8, 3rd=5, fail=0
- Solved countries never reappear in future questions
- Game completes when pool is exhausted
- Reset clears all state

### Widget Tests
- Loading spinner shown during API call
- Error view shown on network failure
- Option buttons disable after selection
- Correct/wrong colors applied appropriately
- Next button only appears after answering

### Integration Tests
- Full game flow: load → play → complete → reset
- API mock with http testing client

---

## 10. Risk Mitigation

| Risk | Mitigation |
|------|-----------|
| API downtime | Error screen with retry button |
| Slow network | 15-second timeout on HTTP request |
| Flag CDN failure | errorBuilder shows placeholder icon |
| Duplicate country names | Options keyed by ISO code, not name |
| Memory (large country list) | Only fetch `name,cca2` fields; ~250 items |
