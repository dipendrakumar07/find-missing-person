import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:find_missing_person/models/missing_person.dart';
import 'package:find_missing_person/screens/admin/admin_edit_report_screen.dart';
import 'package:find_missing_person/screens/person_detail_screen.dart';
import 'package:find_missing_person/screens/login_screen.dart';
import 'package:find_missing_person/services/missing_person_repository.dart';
import 'package:find_missing_person/widgets/verified_badge.dart';
import 'package:find_missing_person/main.dart';

void main() {
  testWidgets('App launch & Login screen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const FindMissingPersonApp());

    // Verify app title and login elements
    expect(find.text('FindMissingPerson'), findsOneWidget);
    expect(find.text('Log In'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Create new account'), findsOneWidget);
  });

  testWidgets('Verified Badge widgets test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              VerifiedBadge(),
              VerificationStatusBadge(status: 'Verified'),
              VerificationStatusBadge(status: 'Pending'),
              VerificationStatusBadge(status: 'Approved'),
              VerificationStatusBadge(status: 'Rejected'),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Verified'), findsNWidgets(2));
    expect(find.text('Pending Review'), findsOneWidget);
    expect(find.text('Approved'), findsOneWidget);
    expect(find.text('Rejected'), findsOneWidget);
  });

  testWidgets('Admin Edit Report Screen UI test', (WidgetTester tester) async {
    final testPerson = MissingPerson(
      id: 'admin_edit_123',
      fullName: 'Aarav Sharma',
      age: 28,
      gender: 'Male',
      missingDate: DateTime(2026, 3, 1),
      lastSeenLocation: 'Connaught Place, New Delhi',
      description: 'Last seen near metro station.',
      contactNumber: '+91 9999988888',
      reportDate: DateTime(2026, 3, 2),
      verificationStatus: 'Pending',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: AdminEditReportScreen(report: testPerson),
      ),
    );

    expect(find.text('Edit Report (Admin)'), findsOneWidget);
    expect(find.text('Administrative Status'), findsOneWidget);
    expect(find.text('Person Information'), findsOneWidget);
    expect(find.text('Save Report Changes'), findsOneWidget);
    expect(find.text('Aarav Sharma'), findsOneWidget);
  });

  testWidgets('Person Detail Screen with Verified Status test', (WidgetTester tester) async {
    final verifiedPerson = MissingPerson(
      id: 'person_verified_888',
      fullName: 'Vikram Singh',
      age: 35,
      gender: 'Male',
      missingDate: DateTime(2026, 3, 1),
      lastSeenLocation: 'Sector 18, Noida',
      description: 'Wearing blue jacket.',
      contactNumber: '+91 9876543210',
      reportDate: DateTime(2026, 3, 2),
      reportStatus: 'Missing',
      verificationStatus: 'Verified',
    );

    MissingPersonRepository().addReport(verifiedPerson);

    await tester.pumpWidget(
      const MaterialApp(
        home: PersonDetailScreen(personId: 'person_verified_888'),
      ),
    );

    expect(find.text('Person Details'), findsOneWidget);
    expect(find.text('Vikram Singh'), findsOneWidget);
    expect(find.text('Official Verified Case • Confirmed by authorities'), findsOneWidget);
    expect(find.text('Contact Reporter'), findsOneWidget);
    expect(find.text('Report Sighting / Found'), findsOneWidget);
  });
}
