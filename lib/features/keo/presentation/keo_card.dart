import 'package:flutter/material.dart';
import '../domain/keo.dart';

class KeoCard extends StatelessWidget {
  const KeoCard({super.key, required this.keo, this.onTap});
  final Keo keo;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        title: Text(keo.title),
        subtitle: Text('${keo.slotsFilled}/${keo.sizeTarget} người · cách ${keo.distanceBand} km'
            '${keo.hostName != null ? ' · chủ kèo ${keo.hostName}' : ''}'),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
