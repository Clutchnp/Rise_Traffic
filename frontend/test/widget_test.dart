import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/app.dart';

void main() {
  testWidgets('RISE Traffic app smoke and dashboard render test', (WidgetTester tester) async {
    // Set a desktop surface size for the test
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    // Build our app and trigger a frame.
    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();

    // Verify key titles and metrics are rendered
    expect(find.text('RISE TRAFFIC'), findsOneWidget);
    expect(find.text('TRAFFIC STATUS'), findsOneWidget);
    expect(find.text('ACTIVE INCIDENTS'), findsOneWidget);
    expect(find.text('CONGESTION HOTSPOTS'), findsOneWidget);
    expect(find.text('Congestion Trend'), findsOneWidget);
  });

  testWidgets('Sidebar navigation works across all screens', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();

    // Navigate to Live Traffic
    await tester.tap(find.text('Live Traffic'));
    await tester.pumpAndSettle();
    expect(find.text('Live Traffic Feeds'), findsOneWidget);

    // Navigate to Incidents
    await tester.tap(find.text('Incidents'));
    await tester.pumpAndSettle();
    expect(find.text('Incident Management'), findsOneWidget);

    // Navigate to Hotspots
    await tester.tap(find.text('Hotspots'));
    await tester.pumpAndSettle();
    expect(find.text('Congestion Hotspots & Bottlenecks'), findsOneWidget);

    // Navigate to Analytics
    await tester.tap(find.text('Analytics'));
    await tester.pumpAndSettle();
    expect(find.text('Traffic Intelligence & Analytics'), findsOneWidget);
  });

  testWidgets('Mobile viewport renders cleanly without overflow exceptions', (WidgetTester tester) async {
    // Set a mobile screen size (390 x 844 - iPhone 14 size)
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();

    // Verify dashboard loaded properly on compact screen
    expect(find.text('TRAFFIC STATUS'), findsOneWidget);
    expect(find.text('ACTIVE INCIDENTS'), findsOneWidget);
  });

  testWidgets('Live Traffic camera selection and filter switches work', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();

    // Navigate to Live Traffic
    await tester.tap(find.text('Live Traffic'));
    await tester.pumpAndSettle();

    // Tap on CAM-002 (Marathahalli Bridge)
    final cam2Finder = find.text('CAM-002');
    expect(cam2Finder, findsWidgets);
    await tester.tap(cam2Finder.first);
    await tester.pumpAndSettle();

    // Verify selected camera card updated
    expect(find.text('CAM-002 · Marathahalli Bridge'), findsOneWidget);
  });

  testWidgets('Incident dialog opens on tap', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();

    // Tap on an incident item in dashboard
    final incidentFinder = find.text('Major Congestion Bottleneck');
    expect(incidentFinder, findsOneWidget);
    await tester.tap(incidentFinder);
    await tester.pumpAndSettle();

    // Verify dialog opened
    expect(find.text('Incident ID'), findsOneWidget);
    expect(find.text('Dispatch Unit'), findsOneWidget);

    // Close dialog
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.text('Incident ID'), findsNothing);
  });
}
