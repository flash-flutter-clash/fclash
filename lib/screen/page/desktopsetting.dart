import 'package:fclash/screen/controller/theme_controller.dart';
import 'package:fclash/screen/page/widgets/OPTContainer.dart';
import 'package:fclash/service/autostart_service.dart';
import 'package:fclash/service/clash_service.dart';
import 'package:flutter/material.dart';
import 'package:kommon/kommon.dart';

class DeskTopSetting extends StatefulWidget {
  const DeskTopSetting({Key? key}) : super(key: key);

  @override
  State<DeskTopSetting> createState() => _DeskTopSettingState();
}

class _DeskTopSettingState extends State<DeskTopSetting> {
  InputDecoration inputDecoration = const InputDecoration(
      border: OutlineInputBorder(borderSide: BorderSide.none),
      contentPadding: EdgeInsets.all(0));

  @override
  Widget build(BuildContext context) {
    const nomalColor = Colors.white;
    const selectedColor = Color.fromRGBO(92, 191, 249, 1);
    const selectedStyle = TextStyle(color: Colors.white, fontSize: 12);
    const nomalStyle = TextStyle(color: Colors.grey, fontSize: 12);

    var ipv6Switch = false.obs;
    var wanSwitch = false.obs;

    final config = Get.find<ClashService>().configEntity;
    TextEditingController httpController = TextEditingController(
      text: config.value!.port.toString(),
    );

    TextEditingController socks5Controller = TextEditingController(
      text: config.value!.socksPort.toString(),
    );

    TextEditingController redirController = TextEditingController(
      text: config.value!.redirPort.toString(),
    );

    TextEditingController mixedController = TextEditingController(
      text: config.value!.mixedPort.toString(),
    );

    SpUtil.getData('lan') == "zh_CN";

    return Obx(() {
      final mode =
          Get.find<ClashService>().configEntity.value?.mode ?? "Direct";

      return Container(
        padding: EdgeInsets.all(15),
        child: Column(children: [
          const SizedBox(
            height: 10,
          ),
          Card(
              child: Container(
            padding: EdgeInsets.all(15),
            child: Column(children: [
              Flex(
                direction: Axis.horizontal,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    flex: 1,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TitleText(text: "Proxy".tr),
                        // // Switch
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  Get.find<ClashService>()
                                      .changeConfigField('mode', 'Rule');
                                },
                                child: OPTContainer(
                                  text: "rule",
                                  position: "left",
                                  selected: mode == "rule",
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Get.find<ClashService>()
                                      .changeConfigField('mode', 'Global');
                                },
                                child: OPTContainer(
                                  text: "global",
                                  position: "middle",
                                  selected: mode == "global",
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Get.find<ClashService>()
                                      .changeConfigField('mode', 'Direct');
                                },
                                child: OPTContainer(
                                  text: "direct",
                                  position: "right",
                                  selected: mode == "direct",
                                ),
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    width: 50,
                  ),
                  Expanded(
                    flex: 1,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TitleText(text: "Socks5 proxy port".tr),
                        InputContainer(
                          child: TextField(
                            textAlign: TextAlign.center,
                            decoration: inputDecoration,
                            controller: socks5Controller,
                            onChanged: (value) {
                              socks5Controller.text = value;
                              setState(() {});
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Flex(
                direction: Axis.horizontal,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    flex: 1,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TitleText(text: "HTTP proxy port".tr),
                        InputContainer(
                          child: TextField(
                            textAlign: TextAlign.center,
                            decoration: inputDecoration,
                            controller: httpController,
                            onChanged: (value) {
                              httpController.text = value;
                              setState(() {});
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    width: 50,
                  ),
                  Expanded(
                    flex: 1,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TitleText(
                          text: "Redir proxy port".tr,
                        ),
                        InputContainer(
                          child: TextField(
                            textAlign: TextAlign.center,
                            decoration: inputDecoration,
                            controller: redirController,
                            onChanged: (value) {
                              redirController.text = value;
                              setState(() {});
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Flex(
                direction: Axis.horizontal,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    flex: 1,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TitleText(
                          text: "Mixed proxy port".tr,
                        ),
                        InputContainer(
                          child: TextField(
                            textAlign: TextAlign.center,
                            decoration: inputDecoration,
                            controller: mixedController,
                            onChanged: (value) {
                              mixedController.text = value;
                              setState(() {});
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    width: 50,
                  ),
                  Expanded(
                    flex: 1,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TitleText(text: "Enable IPv6".tr),
                        Switch(
                          value: ipv6Switch.value,
                          onChanged: (value) {
                            ipv6Switch.value = value;
                          },
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ]),
          )),
          const SizedBox(
            height: 10,
          ),
          Card(
            child: Container(
              padding: const EdgeInsets.all(15),
              child: Column(children: [
                Flex(
                  direction: Axis.horizontal,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      flex: 1,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TitleText(text: "Start with system".tr),
                          Switch(
                            value: Get.find<AutostartService>().isEnabled.value,
                            onChanged: (value) {
                              if (value) {
                                Get.find<AutostartService>().enableAutostart();
                              } else {
                                Get.find<AutostartService>().disableAutostart();
                              }
                            },
                          )
                        ],
                      ),
                    ),
                    const SizedBox(
                      width: 50,
                    ),
                    Expanded(
                      flex: 1,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TitleText(text: 'Language'),
                          MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    Get.updateLocale(const Locale('zh', 'CN'));
                                    SpUtil.setData('lan', 'zh_CN');
                                  },
                                  child: OPTContainer(
                                    text: "中文",
                                    position: "left",
                                    selected: SpUtil.getData('lan') == "zh_CN",
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Get.updateLocale(const Locale('en', 'US'));
                                    SpUtil.setData('lan', 'en_US');
                                  },
                                  child: OPTContainer(
                                    text: "English",
                                    position: "right",
                                    selected: SpUtil.getData('lan') == "en_US",
                                  ),
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Flex(
                  direction: Axis.horizontal,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      flex: 1,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TitleText(text: 'Dark Theme'.tr),
                          Switch(
                            value:
                                SpUtil.getData("dark_theme", defValue: false),
                            onChanged: (value) async {
                              if (value) {
                                await SpUtil.setData("dark_theme", true);
                              } else {
                                await SpUtil.setData("dark_theme", false);
                              }
                              Get.find<ThemeController>().changeTheme(
                                  value ? ThemeType.dark : ThemeType.light);
                              setState(() {});
                            },
                          )
                        ],
                      ),
                    ),
                    const SizedBox(
                      width: 50,
                    ),
                    Expanded(
                      flex: 1,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TitleText(text: "Set as system proxy".tr),
                          Switch(
                            value:
                                SpUtil.getData("system_proxy", defValue: false),
                            onChanged: (value) async {
                              if (value) {
                                await Get.find<ClashService>().setSystemProxy();
                                await SpUtil.setData("system_proxy", true);
                              } else {
                                await Get.find<ClashService>()
                                    .clearSystemProxy();
                                await SpUtil.setData("system_proxy", false);
                              }
                              setState(() {});
                            },
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ]),
            ),
          ),
        ]),
      );
    });
  }
}

class TitleText extends StatelessWidget {
  String text;
  TitleText({Key? key, required this.text}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
    );
  }
}

class InputContainer extends StatelessWidget {
  Widget child;
  InputContainer({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 40,
      decoration: BoxDecoration(
        border: Border.all(
          width: 1,
          color: Colors.grey.shade300,
        ),
        borderRadius: BorderRadius.circular(5),
      ),
      alignment: Alignment.center,
      child: child,
    );
  }
}

class MyFlex extends StatelessWidget {
  Widget children;
  MyFlex({
    Key? key,
    required this.children,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
