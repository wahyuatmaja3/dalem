import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final whatsAppBridgeProvider = Provider<WhatsAppBridgeService>((ref) {
  return WhatsAppBridgeService();
});

class WhatsAppBridgeService {
  static const platform = MethodChannel('com.dalem.voicenotes/whatsapp');
  final _audioPathController = StreamController<String>.broadcast();

  WhatsAppBridgeService() {
    platform.setMethodCallHandler(_handleMethodCall);
  }

  Stream<String> get completedCallAudioPaths => _audioPathController.stream;

  Future<void> initialize() async {
    try {
      await platform.invokeMethod('initialize');
    } on MissingPluginException {
      debugPrint('WhatsApp bridge: native handler not registered yet');
    } on PlatformException catch (e) {
      debugPrint('WhatsApp bridge initialization failed: ${e.message}');
    }
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    if (call.method == 'onWhatsAppCallFinished') {
      final audioPath = call.arguments as String;
      _audioPathController.add(audioPath);
    }
  }

  void dispose() {
    _audioPathController.close();
  }
}
