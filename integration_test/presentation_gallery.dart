// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;

import 'package:flutter/widgets.dart';

import 'presentation_capture_test.dart'
    show buildPresentationFixture, presentationFixtureTitles;

const _rootReadinessTimeout = Duration(seconds: 5);
const _rootReadinessPollInterval = Duration(milliseconds: 16);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final requested = int.tryParse(Uri.base.queryParameters['state'] ?? '');
  final number = presentationFixtureTitles.containsKey(requested)
      ? requested!
      : 1;

  final title = presentationFixtureTitles[number]!;
  final fixture = await buildPresentationFixture(number);
  runApp(fixture);

  final expectedTitle = Uri.base.queryParameters['probe'] == 'missing-root'
      ? 'screen_missing_probe'
      : title;
  final documentRoot = html.document.documentElement!;
  documentRoot
    ..removeAttribute('data-gallery-state')
    ..removeAttribute('data-gallery-error')
    ..setAttribute('data-gallery-expected', expectedTitle)
    ..setAttribute('data-gallery-status', 'waiting');
  _waitForCanonicalRoot(
    expectedRoot: Key(expectedTitle),
    expectedTitle: expectedTitle,
    documentRoot: documentRoot,
  );
}

void _waitForCanonicalRoot({
  required Key expectedRoot,
  required String expectedTitle,
  required html.Element documentRoot,
}) {
  final elapsed = Stopwatch()..start();
  Timer? timer;
  var finished = false;

  void probe() {
    final root = WidgetsBinding.instance.rootElement;
    if (root != null && _containsCanonicalRoot(root, expectedRoot)) {
      finished = true;
      timer?.cancel();
      html.document.title = expectedTitle;
      documentRoot
        ..setAttribute('data-gallery-state', expectedTitle)
        ..setAttribute('data-gallery-status', 'ready')
        ..removeAttribute('data-gallery-error');
      return;
    }

    if (elapsed.elapsed >= _rootReadinessTimeout) {
      finished = true;
      timer?.cancel();
      documentRoot
        ..removeAttribute('data-gallery-state')
        ..setAttribute('data-gallery-status', 'timeout')
        ..setAttribute('data-gallery-error', 'expected-root-missing');
      return;
    }
  }

  probe();
  if (!finished) {
    timer = Timer.periodic(_rootReadinessPollInterval, (_) => probe());
  }
}

bool _containsCanonicalRoot(Element element, Key expectedRoot) {
  if (element.widget.key == expectedRoot) return true;

  var found = false;
  element.visitChildElements((child) {
    if (!found && _containsCanonicalRoot(child, expectedRoot)) {
      found = true;
    }
  });
  return found;
}
