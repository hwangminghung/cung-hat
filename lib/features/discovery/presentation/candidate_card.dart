import 'package:flutter/material.dart';
import '../domain/candidate.dart';

class CandidateCard extends StatelessWidget {
  const CandidateCard({super.key, required this.candidate});
  final Candidate candidate;

  @override
  Widget build(BuildContext context) {
    final name = candidate.displayName ?? '';
    final monogram = name.isEmpty ? '?' : name.characters.first.toUpperCase();
    final title = candidate.age == null ? name : '$name, ${candidate.age}';
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              color: Theme.of(context).colorScheme.primaryContainer,
              alignment: Alignment.center,
              child: Text(monogram, style: const TextStyle(fontSize: 96)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                    child: Text(title,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge),
                  ),
                  if (candidate.verified) const Icon(Icons.verified, size: 18),
                ]),
                Text('Cách ${candidate.distanceBand ?? '?'} km · cùng ${candidate.sharedBaitu.length} bài tủ'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
