// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;

import 'package:flutter/widgets.dart';

import 'presentation_capture_test.dart'
    show buildPresentationFixture, presentationFixtureTitles;

const _maxRootReadinessFrames = 300;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final requested = int.tryParse(Uri.base.queryParameters['state'] ?? '');
  final number = presentationFixtureTitles.containsKey(requested)
      ? requested!
      : 1;

  final title = presentationFixtureTitles[number]!;
  final fixture = await buildPresentationFixture(number);
  runApp(fixture);

  final documentRoot = html.document.documentElement!;
  documentRoot
    ..removeAttribute('data-gallery-state')
    ..removeAttribute('data-gallery-error')
    ..setAttribute('data-gallery-expected', title)
    ..setAttribute('data-gallery-status', 'waiting');
  _waitForCanonicalRoot(
    expectedRoot: Key(title),
    expectedTitle: title,
    documentRoot: documentRoot,
  );
}

void _waitForCanonicalRoot({
  required Key expectedRoot,
  required String expectedTitle,
  required html.Element documentRoot,
  int frame = 0,
}) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final root = WidgetsBinding.instance.rootElement;
    if (root != null && _containsCanonicalRoot(root, expectedRoot)) {
      html.document.title = expectedTitle;
      documentRoot
        ..setAttribute('data-gallery-state', expectedTitle)
        ..setAttribute('data-gallery-status', 'ready')
        ..removeAttribute('data-gallery-error');
      return;
    }

    if (frame + 1 >= _maxRootReadinessFrames) {
      documentRoot
        ..removeAttribute('data-gallery-state')
        ..setAttribute('data-gallery-status', 'timeout')
        ..setAttribute('data-gallery-error', 'expected-root-missing');
      return;
    }

    _waitForCanonicalRoot(
      expectedRoot: expectedRoot,
      expectedTitle: expectedTitle,
      documentRoot: documentRoot,
      frame: frame + 1,
    );
  });
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
