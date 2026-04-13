import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:zalo_mobile_app/common/constants/api_constants.dart';
import 'package:zalo_mobile_app/services/local_notification_service.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;

  final StreamController<Map<String, dynamic>> _eventController =
  StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get eventsStream => _eventController.stream;

  void connect(String userId) {
    if (_socket != null && _socket!.connected) return;

    _socket = IO.io(
      ApiConstants.socketUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .enableReconnection()
          .build(),
    );

    _socket!.connect();

    _socket!.onConnect((_) {
      _socket!.emit("join", userId);
      print("Connected: ${_socket!.id}");
    });
  }
  void emit(String event, dynamic data) {
    if (_socket == null) {
      print("❌ Socket null, chưa connect");
      return;
    }

    if (!_socket!.connected) {
      print("⚠️ Socket chưa connect, đang reconnect...");
      _socket!.connect();
      return;
    }

    print("🚀 Emit: $event | data: $data");
    _socket!.emit(event, data);
  }

  void listenEvent(String event) {
    if (_socket == null) return;

    _socket!.off(event);

    _socket!.on(event, (data) async {
      print("📩 Event: $event | data: $data");

      _eventController.add({
        "event": event,
        "data": data,
      });

      if (event == "notification:new") {
        try {
          final map = Map<String, dynamic>.from(data as Map);

          final title = map["title"]?.toString() ?? "Thông báo mới";
          final body = map["content"]?.toString() ?? "";

          await LocalNotificationService().showNotification(
            title: title,
            body: body,
          );
        } catch (e) {
          print("❌ show local notification error: $e");
        }
      }
    });
  }
}