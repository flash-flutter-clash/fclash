import 'dart:io';
import 'package:fclash/service/clash_service.dart';
import 'package:fclash/utils/sp_util.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';

class FClashService {
  static FClashService _instance = FClashService._internal();
  factory FClashService() {
    return _instance;
  }

  FClashService._internal() {
    //此处进行初始化操作
  }

  final isDesktop = Platform.isLinux || Platform.isWindows || Platform.isMacOS;

  RxBool isSystemProxyObs = RxBool(false);

  late var proxyStatus = RxMap<String, int>();

  // log
  Stream<dynamic>? logStream;

  Future<void> initFclashService(String configFileUrl,
      {String configFileName = "configNew", String token = ''}) async {
    await SpUtil.getInstance();
    await Get.putAsync(() => ClashService().init());
    // 配置
    if (configFileUrl.isNotEmpty) {
      if (Platform.isIOS) {
        await Get.find<ClashService>()
            .addProfile(configFileName, configFileUrl, token);
      } else {
        addProfile(configFileName, configFileUrl, token);
      }
    }
  }

// 设置为系统代理：开启vpn
  Future<bool> startVPN() async {
    if (Platform.isIOS) {
      return await Get.find<ClashService>().setSystemProxy();
    } else {
      return false;
    }
  }

  // 关闭系统代理
  Future<void> closeVPN() async {
    await clearSystemProxy();
  }

// 关闭系统代理
  Future<void> clearSystemProxy({bool permanent = true}) async {
    mobileChannel.invokeMethod("StopProxy");
    await setIsSystemProxy(false);
  }

  Future<bool> addProfile(String name, String url, String token,
      {bool adblock = false, bool website = false}) async {
    final configName = '$name.yaml';
    Directory clashDirectory = await getApplicationSupportDirectory();
    final newProfilePath = join(clashDirectory.path, configName);
    File configFile = File(newProfilePath);
    deleteProfile(configFile);
    try {
      final String adblockString = adblock ? "true" : "false";
      final String websiteString = website ? "true" : "false";

      Map<String, dynamic> params = {
        "adblock": adblockString,
        "website": websiteString
      };
      final uri = Uri.tryParse(url);
      if (uri == null) {
        return false;
      }

      final finalUri = uri.replace(queryParameters: params); //USE THIS

      var dio = Dio(BaseOptions(
          headers: {
            'User-Agent': 'Fclash',
            'Authorization': token,
          },
          sendTimeout: const Duration(milliseconds: 15000),
          receiveTimeout: const Duration(milliseconds: 15000)));

      final resp = await dio.downloadUri(finalUri, newProfilePath,
          onReceiveProgress: (i, t) {
        Get.printInfo(info: "$i/$t");
      });
      return resp.statusCode == 200;
    } catch (e) {
      debugPrint(e as String?);
    } finally {
      final f = File(newProfilePath);
      if (f.existsSync()) {
        await SpUtil.setData('profile_$name', url);
        mobileChannel.invokeMethod(
            "addProfileForAndroid", {"proFilePath": newProfilePath});
        debugPrint('===============addProfile success');
        return true;
      }
      return false;
    }
  }

  Future<bool> deleteProfile(FileSystemEntity config) async {
    if (config.existsSync()) {
      config.deleteSync();
      await SpUtil.remove('profile_${basename(config.path)}');
      return true;
    } else {
      return false;
    }
  }

  bool isSystemProxy() {
    return SpUtil.getData('system_proxy', defValue: false);
  }

  Future<bool> setIsSystemProxy(bool proxy) {
    isSystemProxyObs.value = proxy;
    return SpUtil.setData('system_proxy', proxy);
  }

  Future<int> change_proxy(
    String selector_name,
    String proxy_name,
  ) async {
    if (Platform.isIOS) {
      var result = await mobileChannel.invokeMethod("change_proxy",
          {"selector_name": selector_name, "proxy_name": proxy_name}) as bool?;
      return result == true ? 0 : -1;
    } else {
      // TODO Android 待实现
      return 0;
    }
  }

  Future<void> testAllProxies(List<dynamic> allItem) async {
    if (Platform.isIOS) {
      await Get.find<ClashService>().testAllProxies(allItem);
      proxyStatus = Get.find<ClashService>().proxyStatus;
    } else {
      // TODO Android 待实现
      // proxyStatus  存储节点延迟的字典
    }
  }

  Future<void> reload2() async {
    if (Platform.isIOS) {
      Get.find<ClashService>().reload2();
    } else {
      // TODO Android 待实现
    }
  }

  Future<bool> changeConfigField(String field, dynamic value) async {
    if (Platform.isIOS) {
      return await Get.find<ClashService>().changeConfigField(field, value);
    } else {
      // TODO Android 待实现
      return false;
    }
  }

  void getCurrentClashConfig() {
    if (Platform.isIOS) {
      Get.find<ClashService>().getCurrentClashConfig();
    } else {
      // TODO Android 待实现
    }
  }

  Future<bool> changeProxy(String selectName, String proxyName) async {
    if (Platform.isIOS) {
      return await Get.find<ClashService>().changeProxy(selectName, proxyName);
    } else {
      // TODO Android 待实现

      return false;
    }
  }

  void startLogging() {
    if (Platform.isIOS) {
      logStream = Get.find<ClashService>().logStream;
      Get.find<ClashService>().startLogging();
    } else {
      // TODO Android 待实现
    }
  }

  String get_config() {
    if (Platform.isIOS) {
      return Get.find<ClashService>().get_config();
    } else {
      // TODO Android 待实现
      return "";
    }
  }

  Future<bool> setSystemProxy() async {
    if (Platform.isIOS) {
      return await Get.find<ClashService>().setSystemProxy();
    } else {
      // TODO Android 待实现
      return false;
    }
  }
}
