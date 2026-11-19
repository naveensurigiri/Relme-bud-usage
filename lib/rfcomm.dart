import 'dart:typed_data';

import 'package:flutter/services.dart';

class BondedDevice {
  final String name;
  final String address;
  const BondedDevice(this.name, this.address);
}

/// Thin wrapper over the Android classic-Bluetooth bridge in MainActivity.kt.
class Rfcomm {
  static const MethodChannel _ch = MethodChannel('realme_buds/rfcomm');

  void listen(void Function(Uint8List) onData, void Function() onClosed) {
    _ch.setMethodCallHandler((call) async {
      if (call.method == 'data') {
        onData(call.arguments as Uint8List);
      } else if (call.method == 'closed') {
        onClosed();
      }
    });
  }

  Future<List<BondedDevice>> bonded() async {
    final list = await _ch.invokeListMethod<Map>('bonded') ?? <Map>[];
    return [
      for (final m in list)
        BondedDevice((m['name'] as String?) ?? '', m['address'] as String),
    ];
  }

  Future<void> connect(String address) => _ch.invokeMethod('connect', {'address': address});

  Future<void> send(Uint8List bytes) => _ch.invokeMethod('send', bytes);

  Future<void> disconnect() => _ch.invokeMethod('disconnect');
}
