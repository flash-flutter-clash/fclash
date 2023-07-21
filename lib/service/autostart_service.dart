import 'package:fclash/fclash_init.dart';
import 'package:get/get.dart';

class AutostartService extends GetxService {
  var isEnabled = false.obs;

  Future<AutostartService> init() async {
    // setup
    if (isDesktop) {}
    return this;
  }

  Future<bool> enableAutostart() async {
    if (!isDesktop) {
      return false;
    }
    return isEnabled.value;
  }

  Future<bool> disableAutostart() async {
    if (!isDesktop) {
      return false;
    }
    return isEnabled.value;
  }
}
