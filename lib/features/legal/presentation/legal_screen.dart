import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Renders a bundled markdown legal document as plain selectable text.
class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key, required this.assetPath, required this.title});

  final String assetPath;
  final String title;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: rootBundle.loadString(assetPath),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return Scaffold(
          appBar: AppBar(title: Text(title)),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: SelectableText(snapshot.data!),
          ),
        );
      },
    );
  }
}
