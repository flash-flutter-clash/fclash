import 'dart:io';

import 'package:fclash/main.dart';
import 'package:fclash/screen/component/speed.dart';
import 'package:fclash/screen/controller/theme_controller.dart';
import 'package:fclash/screen/page/about.dart';
import 'package:fclash/screen/page/clash_log.dart';
import 'package:fclash/screen/page/connection.dart';
import 'package:fclash/screen/page/profile.dart';
import 'package:fclash/screen/page/proxy.dart';
import 'package:fclash/screen/page/setting.dart';
import 'package:fclash/screen/page/desktopsetting.dart';
import 'package:fclash/service/clash_service.dart';
import 'package:flutter/material.dart' hide MenuItem;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:kommon/kommon.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:window_manager/window_manager.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with WindowListener, TrayListener {
  var index = 0.obs;

  final pages = const [
    Proxy(),
    Profile(),
    DeskTopSetting(),
    Connections(),
    ClashLog(),
    AboutPage()
  ];

  final mobilePages = const [
    Proxy(),
    Setting(),
  ];

  @override
  void onWindowClose() {
    super.onWindowClose();
    if (Platform.isMacOS) {
      windowManager.minimize();
    } else {
      windowManager.hide();
    }
  }

  @override
  void onTrayIconMouseDown() {
    // windowManager.focus();
    windowManager.show();
  }

  @override
  void onTrayIconRightMouseDown() {
    super.onTrayIconRightMouseDown();
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    switch (menuItem.key) {
      case 'exit':
        windowManager.close().then((value) async {
          await Get.find<ClashService>().closeClashDaemon();
          exit(0);
        });
        break;
      case 'show':
        windowManager.focus();
        windowManager.show();
    }
  }

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    trayManager.addListener(this);
    changeTheme();
    // ignore
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    trayManager.removeListener(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return isDesktop ? _buildDesktop() : _buildMobile();
  }

  _buildMobile() {
    // 设置配置文件
    Get.find<ClashService>()
        .addProfile("myConfig", "https://defi.icu/foo.yaml");
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Clash"),
          actions: [
            IconButton(
              onPressed: () {
                Get.find<DialogService>().inputDialog(
                  title: "Input a valid subscription link url".tr,
                  onText: (txt) async {
                    Future.delayed(
                      Duration.zero,
                      () {
                        Get.find<DialogService>().inputDialog(
                            title: "What is your config name".tr,
                            onText: (name) async {
                              if (name == "config") {
                                BrnToast.show(
                                    "Cannot use this special name".tr, context);
                              }
                              Future.delayed(Duration.zero, () async {
                                try {
                                  BrnLoadingDialog.show(Get.context!,
                                      content: '', barrierDismissible: false);
                                  await Get.find<ClashService>()
                                      .addProfile(name, txt);
                                } finally {
                                  BrnLoadingDialog.dismiss(Get.context!);
                                }
                              });
                            });
                      },
                    );
                  },
                );
              },
              icon: Icon(Icons.add),
            ),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Setting',
            ),
          ],
          currentIndex: index.value,
          selectedItemColor: Colors.amber[800],
          onTap: (value) {
            setState(() {
              index.value = value;
            });
          },
        ),
        body: mobilePages[index.value],
      ),
    );
  }

  _buildDesktop() {
    return DragToResizeArea(
      child: Scaffold(
          body: Column(
        children: [
          buildDesktopOptions(),
          Expanded(
              child: Row(
            children: [
              Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildOptions(
                            0,
                            'Proxy'.tr,
                            iconAddress:
                                "packages/fclash/assets/images/代理管理工具.svg",
                          ),
                          _buildOptions(
                            1,
                            'Profile'.tr,
                            iconAddress: "packages/fclash/assets/images/文件.svg",
                          ),
                          _buildOptions(
                            2,
                            'Setting'.tr,
                            iconAddress: "packages/fclash/assets/images/设置.svg",
                          ),
                          _buildOptions(
                            3,
                            'Connections'.tr,
                            iconAddress: "packages/fclash/assets/images/连接.svg",
                          ),
                          _buildOptions(
                            4,
                            'Log'.tr,
                            iconAddress: "packages/fclash/assets/images/日志.svg",
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(child: buildFrame()),
            ],
          ))
        ],
      )),
    );
  }

  Widget buildDesktopOptions() {
    final nonSelectedColor = Colors.grey.shade400;
    const selectedColor = Colors.blueAccent;
    const style = TextStyle(color: Colors.white);
    return Obx(
      () {
        final mode =
            Get.find<ClashService>().configEntity.value?.mode ?? "Direct";
        debugPrint("current mode: $mode");
        return GestureDetector(
          onPanStart: (_) {
            windowManager.startDragging();
          },
          child: SizedBox(
            height: 75,
            child: Row(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.center,
              textBaseline: TextBaseline.alphabetic,
              children: [
                const AppIcon().marginOnly(top: Platform.isMacOS ? 12.0 : 0.0),
                // Switch
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [],
                  ),
                ),
                Expanded(
                  child: Container(
                      alignment: Alignment.center,
                      decoration:
                          const BoxDecoration(color: Colors.transparent),
                      child: const SpeedWidget()),
                ),
                const WindowPanel()
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildMobileOptions() {
    final cs = Get.find<ClashService>();
    final pages = [Proxy(), Setting()];
    return BottomNavigationBar(
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          label: 'Business',
        ),
      ],
      currentIndex: 0,
      selectedItemColor: Colors.amber[800],
      onTap: (value) {
        print(value);
      },
    );
  }

  Widget _buildOptions(int index, String title, {String? iconAddress}) {
    return Obx(
      () {
        final selected = index == this.index.value;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          width: 140.0,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.0),
            gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: selected
                    ? [
                        Color.fromARGB(255, 85, 183, 248),
                        Color.fromARGB(255, 56, 146, 245),
                      ]
                    : [
                        Color.fromARGB(0, 85, 183, 248),
                        Color.fromARGB(0, 56, 146, 245),
                      ]),
          ),
          child: InkWell(
            onTap: () {
              this.index.value = index;
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(width: 12),
                Padding(
                  padding: const EdgeInsets.all(5),
                  child: SvgPicture.asset(
                    iconAddress ?? "",
                    width: 20.0,
                    fit: BoxFit.contain,
                    color: selected ? Colors.white : Colors.grey,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    color: selected ? Colors.white : Colors.grey,
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildFrame() {
    return Obx(
      () => pages[index.value],
    );
  }

  void changeTheme() {
    Future.delayed(Duration.zero, () {
      final isDark = SpUtil.getData<bool>('dark_theme', defValue: false);
      Get.find<ThemeController>()
          .changeTheme(isDark ? ThemeType.dark : ThemeType.light);
    });
  }
}

class WindowPanel extends StatelessWidget {
  const WindowPanel({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Ink(
            child: InkWell(
                onTap: () {
                  windowManager.minimize();
                },
                child: const Icon(Icons.minimize).paddingAll(8.0))),
        Ink(
            child: InkWell(
                onTap: () async {
                  if (await windowManager.isMaximized()) {
                    windowManager.unmaximize();
                  } else {
                    windowManager.maximize();
                  }
                },
                child: const Icon(Icons.rectangle_outlined).paddingAll(8.0))),
        Ink(
            child: InkWell(
                onTap: () {
                  windowManager.close();
                },
                child: const Icon(Icons.close).paddingAll(8.0))),
      ],
    );
  }
}

class AppIcon extends StatelessWidget {
  const AppIcon({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12.0),
      child: const CircleAvatar(
        foregroundImage:
            AssetImage("packages/fclash/assets/images/app_tray.png"),
        radius: 20,
      ),
    );
  }
}
