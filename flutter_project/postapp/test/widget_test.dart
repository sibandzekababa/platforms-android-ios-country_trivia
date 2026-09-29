import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:postapp/main.dart';

void main() {
  testWidgets('App boots without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const FlagTriviaApp());
    await tester.pump();

    // The app should show either loading, error, or ready state.
    final hasLoading = find.byType(CircularProgressIndicator).evaluate().isNotEmpty;
    final hasError = find.textContaining('Oops').evaluate().isNotEmpty;
    final hasReady = find.textContaining('Country Flag Trivia').evaluate().isNotEmpty;

    expect(hasLoading || hasError || hasReady, true);
  });
}
