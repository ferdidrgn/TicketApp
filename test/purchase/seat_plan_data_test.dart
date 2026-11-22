import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ticketapp/features/seat/data/datasources/seat_remote_data_source_and_impl.dart';
import 'package:ticketapp/features/seat/domain/entities/seat_plan_meta.dart';

void main() {
  late FakeFirebaseFirestore db;
  late SeatRemoteDataSourceImpl source;

  setUp(() {
    db = FakeFirebaseFirestore();
    source = SeatRemoteDataSourceImpl(firestore: db);
  });

  test('reads a legacy document by stageId and excludes metadata rows',
      () async {
    await db.collection('Seats').doc('random').set({
      'stageId': 'stage',
      'A': ['A1', 'A2', 'A1', '', null],
      'closedSeatsId': ['A2'],
      'createdBy': ['not-a-seat'],
      '_createdAt': '2025-01-01',
    });
    expect(await source.getSeatsByStage('stage'), {
      'A': ['A1', 'A2'],
    });
    expect((await source.getSeatPlanMeta('stage')).createdAt, '2025-01-01');
  });

  test('canonical document and new flat array take precedence', () async {
    await db.collection('Seats').doc('stage').set({
      'seatIds': ['B1', 'B2'],
      'seatsId': ['old-seat'],
      'closedSeatIds': ['B2'],
    });
    await db.collection('Seats').doc('random').set({
      'stageId': 'stage',
      'A': ['A1'],
    });
    expect(await source.getSeatsByStage('stage'), {
      'seatsId': ['B1', 'B2'],
    });
  });

  test('legacy flat array remains supported', () async {
    await db.collection('Seats').doc('stage').set({
      'seatsId': ['A1', 'BA1'],
      'closedSeatsId': ['BA1'],
    });
    expect(await source.getSeatsByStage('stage'), {
      'seatsId': ['A1', 'BA1'],
    });
  });

  test('metadata reads both timestamp field conventions', () async {
    final created = DateTime.utc(2026, 11, 19);
    await db.collection('Seats').doc('stage').set({
      'createdAt': Timestamp.fromDate(created),
      '_createdAt': 'outdated',
      'updatedAt': '2026-11-20T00:00:00.000Z',
    });
    final meta = await source.getSeatPlanMeta('stage');
    expect(meta.stageId, 'stage');
    expect(DateTime.parse(meta.createdAt).toUtc(), created);
    expect(meta.updatedAt, '2026-11-20T00:00:00.000Z');
  });

  test('missing stage returns empty metadata and a layout error', () async {
    expect(await source.getSeatPlanMeta('missing'), SeatPlanMeta.empty);
    await expectLater(source.getSeatsByStage('missing'), throwsException);
  });

  test('an empty flat layout reports a missing plan', () async {
    await db.collection('Seats').doc('stage').set({'seatIds': <String>[]});
    await expectLater(source.getSeatsByStage('stage'), throwsException);
  });
}
