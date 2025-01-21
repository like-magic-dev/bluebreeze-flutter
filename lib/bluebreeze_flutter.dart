
import 'bluebreeze_flutter_platform_interface.dart';

class BluebreezeFlutter {
  Future<String?> getPlatformVersion() {
    return BluebreezeFlutterPlatform.instance.getPlatformVersion();
  }
}
