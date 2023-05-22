import 'dart:io';

import 'package:fclash/screen/controller/theme_controller.dart';
import 'package:fclash/service/autostart_service.dart';
import 'package:fclash/service/clash_service.dart';
import 'package:fclash/service/notification_service.dart';
import 'package:ffigen/ffigen.dart';
import 'package:kommon/kommon.dart';
import 'package:proxy_manager/proxy_manager.dart';
import 'package:tray_manager/tray_manager.dart';

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
  Get.put(ThemeController());
  configName = configFileName;
  configUrl = configFileUrl;
  Get.find<ClashService>().addProfile(configFileName, configFileUrl);
}

Future<void> initAppTray(
    {List<MenuItem>? details, bool isUpdate = false}) async {
  await trayManager.setIcon(Platform.isWindows
      ? 'packages/fclash/assets/images/app_tray.ico'
      : 'packages/fclash/assets/images/app_tray.png');

  List<MenuItem> items = [
    MenuItem(
      key: 'show',
      label: 'Show Fclash'.tr,
    ),
    MenuItem.separator(),
    MenuItem(
      key: 'exit',
      label: 'Exit Fclash'.tr,
    ),
  ];
  if (details != null) {
    items.insertAll(0, details);
  }
  await trayManager.setContextMenu(Menu(items: items));
}
