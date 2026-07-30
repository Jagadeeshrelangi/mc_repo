import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mecha_connect/bottom_bar/chatboard.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Enable real network loopback requests during Flutter widget testing
class TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    HttpOverrides.global = null;
    final client = HttpClient();
    HttpOverrides.global = this;
    return client;
  }
}

void main() {
  setUpAll(() {
    HttpOverrides.global = TestHttpOverrides();
  });

  testWidgets('ChatBot Screen UI Live Verification Flow', (WidgetTester tester) async {
    // 1. Configure the local test environment URL
    dotenv.testLoad(fileInput: 'BACKEND_URL=http://127.0.0.1:8000/api/v1');

    print("\n--- 1. Rendering ChatBot Widget ---");
    // Run the widget mount and session creation and wait via runAsync
    await tester.runAsync(() async {
      await tester.pumpWidget(const MaterialApp(
        home: ChatBot(),
      ));
      await Future.delayed(const Duration(seconds: 4));
    });
    await tester.pump();

    // Confirm that the progress bar has hidden, indicating session created
    expect(find.byType(LinearProgressIndicator), findsNothing);
    print("SUCCESS: AI Session established successfully in widget state.");

    // 2. Locate message text inputs
    final textFieldFinder = find.byType(TextField);
    expect(textFieldFinder, findsOneWidget);

    print("--- 2. Simulating User Query Input ---");
    // Type our test question into the text field
    await tester.enterText(textFieldFinder, "What does OBD code P0115 mean?");
    await tester.pump();

    print("--- 3. Submitting Form via onSubmitted Callback ---");
    final TextField textFieldWidget = tester.widget(textFieldFinder);
    
    // Execute onSubmitted inside runAsync to let the HTTP POST request complete on the real loop
    await tester.runAsync(() async {
      textFieldWidget.onSubmitted!("What does OBD code P0115 mean?");
      // Wait for network response
      await Future.delayed(const Duration(seconds: 25));
    });
    
    // Pump frames to render the final response bubbles
    await tester.pump();

    print("--- Debug: Rendered Text Widgets ---");
    for (final element in find.byType(Text).evaluate()) {
      final widget = element.widget as Text;
      print(" - Text: '${widget.data}'");
    }

    // Verify user query and backend response bubbles are displayed in list
    expect(find.text("What does OBD code P0115 mean?"), findsOneWidget);
    
    // Find text widget containing coolant/temperature diagnostic details returned by Gemini
    final responseTextFinder = find.byWidgetPredicate((widget) {
      if (widget is Text && widget.data != null) {
        final text = widget.data!.toLowerCase();
        return text.contains("coolant") || text.contains("sensor") || text.contains("temperature") || text.contains("malfunction");
      }
      return false;
    });
    
    expect(responseTextFinder, findsOneWidget);
    print("SUCCESS: Live Gemini response rendered inside chatbot bubbles.");
    print("--- ALL WIDGET TEST ASSERTIONS PASSED ---");
  });
}
