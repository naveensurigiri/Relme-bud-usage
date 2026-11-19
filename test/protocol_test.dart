import 'package:flutter_test/flutter_test.dart';
import 'package:realme_buds_tracker/protocol.dart';

List<int> hex(String s) =>
    List.generate(s.length ~/ 2, (i) => int.parse(s.substring(i * 2, i * 2 + 2), radix: 16));

void main() {
  test('builds the same queries Realme Link sends', () {
    expect(buildFrame(cmdBatteryQuery, 3, const []), hex('aa0700000601030000'));
    expect(buildFrame(cmdModeQuery, 6, const [1, 1]), hex('aa0900000c010602000101'));
  });

  test('parses a battery reply', () {
    final frames = FrameReader().add(hex('aa0f000006810308000003016402640300'));
    final b = parseBattery(frames.single)!;
    expect(b.left, 100);
    expect(b.right, 100);
    expect(b.caseLevel, isNull);
  });

  test('parses mode reply and notification', () {
    final reply = FrameReader().add(hex('aa0b00000c8106040000010101')).single;
    expect(parseMode(reply), modeTransparency);
    final note = FrameReader().add(hex('aa0b0000040216040003010108')).single;
    expect(parseMode(note), modeNormal);
    final anc = FrameReader().add(hex('aa0b000004021b040003010102')).single;
    expect(modeName(parseMode(anc)), 'ANC');
  });

  test('rebuilds a frame split across two chunks', () {
    final r = FrameReader();
    expect(r.add(hex('aa0f0000068103')), isEmpty);
    expect(r.add(hex('08000003016402640300')).length, 1);
  });

  test('ignores noise before a frame', () {
    final frames = FrameReader().add(hex('0102aa0f000006810308000003016402640300'));
    expect(frames.length, 1);
  });
}
