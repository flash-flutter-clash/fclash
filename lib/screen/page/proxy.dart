import 'package:fclash/service/clash_service.dart';
import 'package:flutter/material.dart';
import 'package:kommon/kommon.dart';
import 'package:tray_manager/tray_manager.dart';
// import 'package:y_tray_manager/tray_manager.dart';

class Proxy extends StatefulWidget {
  const Proxy({Key? key}) : super(key: key);

  @override
  State<Proxy> createState() => _ProxyState();
}

class _ProxyState extends State<Proxy> {
  ClashService get service => Get.find<ClashService>();

  var isOpen = SpUtil.getData("system_proxy", defValue: false);

  // 按钮标题颜色
  final btnTitleC = const Color.fromRGBO(51, 141, 245, 1);
  // 文本标题颜色
  final titleC = const Color.fromRGBO(85, 107, 134, 1);
  // 文本副标题颜色
  final subTitleC = const Color.fromRGBO(85, 107, 134, 0.8);

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Opacity(
            opacity: 0.4,
            child: Align(
              alignment: Alignment.bottomRight,
              child: Image.asset(
                "packages/fclash/assets/images/network.png",
                width: 300,
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                color: Colors.white10,
                padding: const EdgeInsets.all(10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Obx(() {
                      trayManager.setTitle(
                          " ↑${Get.find<ClashService>().downRate.value.toStringAsFixed(1)}KB/s\n ↓${Get.find<ClashService>().uploadRate.value.toStringAsFixed(1)}KB/s");
                      return Text(
                        "上传:${Get.find<ClashService>().downRate.value.toStringAsFixed(1)}KB/s  下载:${Get.find<ClashService>().uploadRate.value.toStringAsFixed(1)}KB/s",
                        style: TextStyle(
                            color: btnTitleC, fontWeight: FontWeight.w800),
                      );
                    }),
                    MaterialButton(
                      onPressed: () async {
                        isOpen = !isOpen;
                        if (isOpen) {
                          await Get.find<ClashService>().setSystemProxy();
                          await SpUtil.setData("system_proxy", true);
                        } else {
                          await Get.find<ClashService>().clearSystemProxy();
                          await SpUtil.setData("system_proxy", false);
                        }
                        setState(() {});
                      },
                      color: isOpen ? btnTitleC : Colors.grey,
                      child: Text(
                        !isOpen ? "开启" : "关闭",
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(child: buildTiles())
            ],
          ),
        ],
      ),
    );
  }

  Widget buildTiles() {
    final c = Get.find<ClashService>().proxies;

    if (c.value == null) {
      return BrnAbnormalStateWidget(
        title: 'No Proxies'.tr,
        content: 'Select a profile to show proxies.',
      );
    }
    Map<String, dynamic> maps = c.value['proxies'] ?? {};
    printInfo(info: 'proxies: ${maps.toString()}');

    return Obx(
      () {
        var selectors = maps.keys.where((proxy) {
          return maps[proxy]['type'] == 'URLTest';
        }).toList(growable: false);
        final mode =
            Get.find<ClashService>().configEntity.value?.mode ?? "direct";
        if (mode == "direct") {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(
                  "packages/fclash/assets/images/rocket.png",
                  width: 100.0,
                  fit: BoxFit.cover,
                ),
                Text(
                  "direct".tr,
                  style: const TextStyle(
                      fontSize: 18.0, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          );
        } else if (mode == "global") {
          selectors = selectors
              .where((sel) => maps[sel]['name'].toLowerCase().contain("proxy"))
              .toList();
        }

        return ListView.builder(
          itemBuilder: (context, index) {
            final selectorName = selectors[index];
            return buildSelector(maps[selectorName]);
          },
          itemCount: selectors.length,
        );
      },
    );
  }

  Widget buildSelector(Map<String, dynamic> selector) {
    final proxyName = selector['name'];
    final isExpanded = false.obs;
    final headStyle =
        TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold, color: titleC);
    final body = Column(
      children: [
        Row(
          children: [
            Expanded(child: buildSelectItem(selector)),
          ],
        ).paddingSymmetric(horizontal: 4.0),
      ],
    );
    return Stack(
      children: [
        Obx(
          () => Container(
            margin: const EdgeInsets.all(8.0),
            decoration:
                BoxDecoration(borderRadius: BorderRadius.circular(12.0)),
            child: ExpansionPanelList(
              elevation: 0,
              key: ValueKey(proxyName),
              expansionCallback: (index, expand) {
                isExpanded.value = !expand;
              },
              children: [
                ExpansionPanel(
                  backgroundColor: const Color.fromRGBO(245, 245, 245, 0.6),
                  canTapOnHeader: true,
                  isExpanded: isExpanded.value,
                  headerBuilder: (context, isExpanded) => Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    proxyName ?? "",
                                    style: headStyle,
                                  ).marginOnly(bottom: 4.0),
                                ),
                              ],
                            ),
                            Text(
                              selector['now'],
                              style: TextStyle(color: subTitleC),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          List<dynamic> allItem = selector['all'];
                          Future.delayed(Duration.zero, () {
                            BrnToast.show(
                                'Start test, please wait.'.tr, context);
                          });
                          await Get.find<ClashService>()
                              .testAllProxies(allItem);
                          Future.delayed(Duration.zero, () {
                            BrnToast.show('Test complete.'.tr, context);
                          });
                        },
                        child: Text(
                          "Test Delay".tr,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ],
                  ).paddingAll(8.0),
                  body: body,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget buildSelectItem(Map<String, dynamic> selector) {
    final c = Get.find<ClashService>().proxies;
    Map<String, dynamic> maps = c.value['proxies'] ?? {};
    final selectName = selector['name'];
    final now = selector['now'];
    List<dynamic> allItems = selector['all'];
    return Obx(
      () {
        var index = 0;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: allItems.map((itemName) {
            final delayInMs = service.proxyStatus[itemName.toString()] ?? 0;
            final txtColor = delayInMs < 0
                ? Colors.red
                : delayInMs == 0
                    ? Colors.grey
                    : delayInMs <= 100
                        ? Colors.green
                        : delayInMs <= 500
                            ? Colors.lightBlue
                            : delayInMs <= 1000
                                ? Colors.blue
                                : Colors.orange;
            // 上下间隔
            const spaceH = SizedBox(height: 8);
            return SizedBox(
              // width: 250,
              height: 90,
              child: Card(
                child: InkWell(
                  onTap: () {},
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Tooltip(
                          message: itemName.toString(),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  color: txtColor,
                                  padding: const EdgeInsets.all(8),
                                  child: Text(
                                    maps[itemName]['type'],
                                    textAlign: TextAlign.start,
                                    style: const TextStyle(
                                        fontSize: 16.0,
                                        fontWeight: FontWeight.w400),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              itemName == now
                                  ? Row(
                                      children: [
                                        Icon(Icons.check, color: btnTitleC),
                                        Text(
                                          itemName,
                                          textAlign: TextAlign.start,
                                          style: TextStyle(
                                              color: btnTitleC,
                                              fontSize: 16.0,
                                              fontWeight: FontWeight.w400),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    )
                                  : Text(
                                      itemName,
                                      textAlign: TextAlign.start,
                                      style: TextStyle(
                                        fontSize: 16.0,
                                        fontWeight: FontWeight.w400,
                                        color: subTitleC,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                            ],
                          ).paddingAll(9),
                        ),
                      ),
                      // ping
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Text(
                            "延迟",
                            style: TextStyle(
                              color: subTitleC,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            delayInMs <= 0 ? '不可用' : '${delayInMs}ms',
                            style: TextStyle(
                              color: txtColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ).paddingAll(9),
                    ],
                  ),
                ),
              ),
            );
          }).toList(growable: false),
        );
      },
    );
  }
}
