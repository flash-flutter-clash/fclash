import 'dart:io';

import 'package:fclash/service/clash_service.dart';
import 'package:fclash/utils/sp_util.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';

final isDesktop = Platform.isLinux || Platform.isWindows || Platform.isMacOS;

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
  if (Platform.isIOS) {
    await Get.find<ClashService>().clearSystemProxy();
  } else {
    return;
  }
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
