import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:zalo_mobile_app/common/constants/api_constants.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;

  SocketService._internal();

  IO.Socket? socket;

  void connect(String userId) {
    socket = IO.io(
      ApiConstants.socketUrl, // ví dụ: http://192.168.1.10:3000
      IO.OptionBuilder()
          .setTransports(['websocket']) // bắt buộc
          .disableAutoConnect()
          .build(),
    );

    socket!.connect();

    // 🔥 Khi connect thành công
    socket!.onConnect((_) {
      print("Connected: ${socket!.id}");

      // 👉 join room user
      socket!.emit("join", userId);
    });

    socket!.onDisconnect((_) {
      print("Disconnected");
    });
  }

  void emit(String event, dynamic data) {
    print("--- Debug Socket Emit ---");
    print("Event: $event");
    print("Data: $data");

    if (socket == null) {
      print("❌ LỖI: Socket instance đang là NULL. Bạn đã gọi connect() chưa?");
      return;
    }

    if (!socket!.connected) {
      print("⚠️ CẢNH BÁO: Socket đã khởi tạo nhưng ĐANG MẤT KẾT NỐI.");
      // Bạn có thể thử gọi socket!.connect() lại ở đây nếu cần
    }

    print("🚀 Đang thực hiện emit...");
    socket?.emit(event, data);
  }

  // Lắng nghe dữ liệu về
  void on(String event, Function(dynamic) callback) {
    socket?.on(event, callback);
  }

  void off(String event) {
    if (socket == null) return;

    print("🧹 Remove listener: $event");
    socket!.off(event);
  }
}