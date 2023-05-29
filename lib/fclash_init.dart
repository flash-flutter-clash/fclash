import 'dart:io';

// import 'package:fclash/screen/controller/theme_controller.dart';
import 'package:fclash/service/autostart_service.dart';
import 'package:fclash/service/clash_service.dart';
import 'package:fclash/service/notification_service.dart';
import 'package:kommon/kommon.dart';
import 'package:proxy_manager/proxy_manager.dart';

final proxyManager = ProxyManager();
final isDesktop = Platform.isLinux || Platform.isWindows || Platform.isMacOS;

Future<void> initFclashService(String configFileUrl,
    {String configFileName = "configNew"}) async {
  await SpUtil.getInstance();
  await Get.putAsync(() => NotificationService().init());
  await Get.putAsync(() => ClashService().init());
  await Get.putAsync(() => DialogService().init());
  if (isDesktop) {
    await Get.putAsync(() => AutostartService().init());
  }
  // 配置
  await Get.find<ClashService>().addProfile(configFileName, configFileUrl);
}

// 设置为系统代理：开启vpn
Future<void> startVPN() async {
  await Get.find<ClashService>().setSystemProxy();
}

// 关闭系统代理
Future<void> closeVPN() async {
  await Get.find<ClashService>().clearSystemProxy();
}
