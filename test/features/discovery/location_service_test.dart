import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cung_hat/features/discovery/data/discovery_repository.dart';
import 'package:cung_hat/features/discovery/application/location_service.dart';

class _MockRepo extends Mock implements DiscoveryRepository {}

void main() {
  test('pushPosition forwards lat/lng/area to the repo', () async {
    final repo = _MockRepo();
    when(() => repo.updateMyLocation(any(), any(), area: any(named: 'area')))
        .thenAnswer((_) async {});
    await LocationService(repo).pushPosition(10.77, 106.70, area: 'Q1');
    verify(() => repo.updateMyLocation(10.77, 106.70, area: 'Q1')).called(1);
  });
}
