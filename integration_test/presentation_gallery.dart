// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;

import 'package:flutter/widgets.dart';

import 'presentation_capture_test.dart'
    show buildPresentationFixture, presentationFixtureTitles;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final requested = int.tryParse(Uri.base.queryParameters['state'] ?? '');
  final number = presentationFixtureTitles.containsKey(requested)
      ? requested!
      : 1;

  final title = presentationFixtureTitles[number]!;
  final fixture = await buildPresentationFixture(number);
  WidgetsBinding.instance.addPostFrameCallback((_) {
    html.document.title = title;
    html.document.documentElement!.setAttribute('data-gallery-state', title);
  });
  runApp(fixture);
}
