import 'dart:io';

// import 'package:fclash/screen/controller/theme_controller.dart';
import 'package:fclash/service/autostart_service.dart';
import 'package:fclash/service/clash_service.dart';
import 'package:fclash/service/notification_service.dart';
import 'package:kommon/kommon.dart';
import 'package:proxy_manager/proxy_manager.dart';

final proxyManager = ProxyManager();
final isDesktop = Platform.isLinux || Platform.isWindows || Platform.isMacOS;

String configName = "";
String configUrl = "";

Future<void> initFclashService({configFileUrl, configFileName}) async {
  await SpUtil.getInstance();
  await Get.putAsync(() => NotificationService().init());
  await Get.putAsync(() => ClashService().init());
  await Get.putAsync(() => DialogService().init());
  if (isDesktop) {
    await Get.putAsync(() => AutostartService().init());
  }
  configName = configFileName;
  configUrl = configFileUrl;
  Get.find<ClashService>().addProfile(configFileName, configFileUrl);
}
