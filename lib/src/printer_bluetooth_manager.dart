/*
 * esc_pos_bluetooth
 * Created by Andrey Ushakov
 * 
 * Copyright (c) 2019-2020. All rights reserved.
 * See LICENSE for distribution and usage details.
 */

import 'dart:async';
import 'dart:io';
import 'package:rxdart/rxdart.dart';
import 'package:flutter_bluetooth_basic/flutter_bluetooth_basic.dart';
import './enums.dart';

/// Bluetooth printer
class PrinterBluetooth {
  PrinterBluetooth(this._device);
  final BluetoothDevice _device;

  int? get type => _device.type;
  String? get name => _device.name;
  String? get address => _device.address;
}

/// Printer Bluetooth Manager
class PrinterBluetoothManager {
  final BluetoothManager _bluetoothManager = BluetoothManager.instance;

  bool _isPrinting = false;

  PrinterBluetooth? _selectedPrinter;
  StreamSubscription? _isScanningSubscription;
  StreamSubscription? _scanResultsSubscription;

  final BehaviorSubject<bool> _isScanning = BehaviorSubject.seeded(false);
  Stream<bool> get isScanningStream => _isScanning.stream;

  final BehaviorSubject<List<PrinterBluetooth>> _scanResults =
      BehaviorSubject.seeded([]);
  Stream<List<PrinterBluetooth>> get scanResults => _scanResults.stream;

  Future<void> startScan(Duration timeout) async {
    _selectedPrinter = null;
    await stopScan();

    _scanResults.add(<PrinterBluetooth>[]);

    _bluetoothManager.startScan(timeout: timeout);

    _scanResultsSubscription = _bluetoothManager.scanResults.listen((devices) {
      _scanResults.add(devices.map((d) => PrinterBluetooth(d)).toList());
    });

    _isScanningSubscription =
        _bluetoothManager.isScanning.listen((isScanningCurrent) {
      // If isScanning value changed (scan just stopped)
      if (_isScanning.value! && !isScanningCurrent) {
        _isScanningSubscription!.cancel();
        _scanResultsSubscription!.cancel();
      }
      _isScanning.add(isScanningCurrent);
    });
  }

  Future<void> stopScan() async {
    await _bluetoothManager.stopScan();
    // await _bluetoothManager.disconnect();
  }

  Future<PosPrintResult> selectPrinter(PrinterBluetooth printer) async {
    try {
      if (_isPrinting) {
        return PosPrintResult.printInProgress;
      }
      _selectedPrinter = printer;

      await _bluetoothManager.startScan(timeout: Duration(seconds: 1));
      await _bluetoothManager.stopScan();

      await _bluetoothManager.connect(_selectedPrinter!._device);

      return PosPrintResult.connectSuccessful;
    } catch (error) {
      return PosPrintResult.connectFailure;
    }
  }

  bool get isPrinting => _isPrinting;

  PrinterBluetooth? get selectedPrinter => _selectedPrinter;

  BluetoothManager get bluetoothManager => _bluetoothManager;

  Future<PosPrintResult> writeData(
    List<int> bytes, {
    int chunkSizeBytes = 20,
    int queueSleepTimeMs = 20,
    dynamic Function(dynamic e)? catchErrorWhenWriteData,
  }) async {
    if (bytes.isEmpty) {
      return PosPrintResult.ticketEmpty;
    } else if (_selectedPrinter == null) {
      return PosPrintResult.printerNotSelected;
    } else if (_isScanning.value!) {
      return PosPrintResult.scanInProgress;
    } else if (_isPrinting) {
      return PosPrintResult.printInProgress;
    }

    _isPrinting = true;

    final len = bytes.length;
    List<List<int>> chunks = [];

    final handleError = catchErrorWhenWriteData == null
        ? (error) => null
        : catchErrorWhenWriteData;

    for (var i = 0; i < len; i += chunkSizeBytes) {
      var end = (i + chunkSizeBytes < len) ? i + chunkSizeBytes : len;
      chunks.add(bytes.sublist(i, end));
    }

    for (var i = 0; i < chunks.length; i += 1) {
      if (chunks[i].isEmpty) {
        continue;
      }
      await _bluetoothManager.writeData(chunks[i]).catchError(handleError);
      sleep(Duration(milliseconds: queueSleepTimeMs));
    }

    _isPrinting = false;
    return PosPrintResult.success;
  }

  StreamSubscription getBluetoothListener({
    int chunkSizeBytes = 20,
    required List<int> bytes,
    int queueSleepTimeMs = 20,
    required Future Function() onDisconnected,
    required Future Function(PosPrintResult) onCompleted,
    dynamic Function(dynamic e)? catchErrorWhenWriteData,
  }) {
    return _bluetoothManager.state.listen((event) async {
      switch (event) {
        case BluetoothManager.CONNECTED:
          final result = await writeData(
            bytes,
            chunkSizeBytes: chunkSizeBytes,
            queueSleepTimeMs: chunkSizeBytes,
            catchErrorWhenWriteData: catchErrorWhenWriteData,
          ).catchError((error) => PosPrintResult.error);
          await onCompleted(result);
          break;
        case BluetoothManager.DISCONNECTED:
          await onDisconnected();
          break;
        default:
      }
    });
  }
}
