import 'dart:async';
import 'dart:convert';
import 'dart:ffi' as ffi;
import 'dart:io';
import 'dart:isolate';
import 'package:dio/dio.dart';
import 'package:fclash/bean/clash_config_entity.dart';
import 'package:fclash/fclash_init.dart';
import 'package:fclash/generated_bindings.dart';
import 'package:fclash/request/request.dart';
import 'package:fclash/utils/sp_util.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:path/path.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:yaml/yaml.dart';
import 'package:yaml_writer/yaml_writer.dart';

late NativeLibrary clashFFI;
const mobileChannel = MethodChannel("FlashPlugin");

class ClashService extends GetxService {
  // 需要一起改端口
  static const clashBaseUrl = "http://127.0.0.1:$clashExtPort";
  static const clashExtPort = 22345;

  // 运行时
  late Directory _clashDirectory;
  RandomAccessFile? _clashLock;

  // 流量
  final uploadRate = 0.0.obs;
  final downRate = 0.0.obs;
  final yamlConfigs = RxSet<FileSystemEntity>();
  final currentYaml = 'config.yaml'.obs;
  final proxyStatus = RxMap<String, int>();

  // action
  static const ACTION_SET_SYSTEM_PROXY = "assr";
  static const ACTION_UNSET_SYSTEM_PROXY = "ausr";
  static const MAX_ENTRIES = 5;

  // default port
  static var initializedHttpPort = 0;
  static var initializedSockPort = 0;
  static var initializedMixedPort = 0;

  // config
  Rx<ClashConfigEntity?> configEntity = Rx(null);

  // log
  Stream<dynamic>? logStream;
  RxMap<String, dynamic> proxies = RxMap();
  RxBool isSystemProxyObs = RxBool(false);

  ClashService() {
    // load lib
    var fullPath = "";
    if (Platform.isWindows) {
      fullPath = "libclash.dll";
    } else if (Platform.isMacOS) {
      fullPath = "libclash.dylib";
    } else if (Platform.isIOS) {
      final lib = ffi.DynamicLibrary.executable();
      clashFFI = NativeLibrary(lib);
      clashFFI.init_native_api_bridge(ffi.NativeApi.initializeApiDLData);
      return;
    } else {
      fullPath = "libclashF.so";
    }
    final lib = ffi.DynamicLibrary.open(fullPath);
    clashFFI = NativeLibrary(lib);
    clashFFI.init_native_api_bridge(ffi.NativeApi.initializeApiDLData);
  }

  Future<ClashService> init() async {
    _clashDirectory = await getApplicationSupportDirectory();
    // init config yaml
    final _ = SpUtil.getData('yaml', defValue: currentYaml.value);
    initializedHttpPort = SpUtil.getData('http-port', defValue: 12346);
    initializedSockPort = SpUtil.getData('socks-port', defValue: 12347);
    initializedMixedPort = SpUtil.getData('mixed-port', defValue: 12348);
    currentYaml.value = _;
    Request.setBaseUrl(clashBaseUrl);
    // init clash
    // kill all other clash clients
    final clashConfigPath = p.join(_clashDirectory.path, "clash");
    _clashDirectory = Directory(clashConfigPath);
    print("flash work directory: ${_clashDirectory.path}");
    final clashConf = p.join(_clashDirectory.path, currentYaml.value);
    final countryMMdb = p.join(_clashDirectory.path, 'Country.mmdb');
    if (!await _clashDirectory.exists()) {
      await _clashDirectory.create(recursive: true);
    }
    // copy executable to directory
    final mmdb = await rootBundle.load('assets/tp/clash/Country.mmdb');
    // write to clash dir
    final mmdbF = File(countryMMdb);
    if (!mmdbF.existsSync()) {
      await mmdbF.writeAsBytes(mmdb.buffer.asInt8List());
    }
    final config = await rootBundle.load('assets/tp/clash/config.yaml');
    // write to clash dir
    final configF = File(clashConf);
    if (!configF.existsSync()) {
      await configF.writeAsBytes(config.buffer.asInt8List());
    }
    // create or detect lock file
    await _acquireLock(_clashDirectory);
    // ffi
    clashFFI.set_home_dir(_clashDirectory.path.toNativeUtf8().cast());
    clashFFI.clash_init(_clashDirectory.path);
    clashFFI.set_config(clashConf.toNativeUtf8().cast());
    clashFFI.set_ext_controller(clashExtPort);
    if (clashFFI.parse_options() == 0) {
      Get.printInfo(info: "parse ok");
    }
    Future.delayed(Duration.zero, () {
      initDaemon();
    });

    // wait getx initialize
    Future.delayed(const Duration(seconds: 3), () {
      if (!Platform.isWindows) {
        // Get.find<NotificationService>()
        //     .showNotification("OrcaVPN", "Is running".tr);
      }
    });
    return this;
  }

  void getConfigs() {
    yamlConfigs.clear();
    final entities = _clashDirectory.listSync();
    for (final entity in entities) {
      if (entity.path.toLowerCase().endsWith('.yaml') &&
          !yamlConfigs.contains(entity)) {
        yamlConfigs.add(entity);
        Get.printInfo(info: 'detected: ${entity.path}');
      }
    }
  }

  String get_config() {
    return clashFFI.get_config().cast<Utf8>().toDartString();
  }

  Map<String, dynamic> getConnections() {
    String connections =
        clashFFI.get_all_connections().cast<Utf8>().toDartString();
    return json.decode(connections);
  }

  void closeAllConnections() {
    clashFFI.close_all_connections();
  }

  bool closeConnection(String connectionId) {
    final id = connectionId.toNativeUtf8().cast<ffi.Char>();
    return clashFFI.close_connection(id) == 1;
  }

  void getCurrentClashConfig() {
    configEntity.value = ClashConfigEntity.fromJson(
        json.decode(clashFFI.get_configs().cast<Utf8>().toDartString()));
  }

  Future<void> reload() async {
    // get configs
    getConfigs();
    getCurrentClashConfig();
    // proxies
    getProxies();
  }

  Future<void> reload2() async {
    getCurrentClashConfig();
    // proxies
    getProxies();
  }

  void initDaemon() async {
    printInfo(info: 'init clash service');
    await reload();
    checkPort();
  }

  @override
  void onClose() {
    closeClashDaemon();
    super.onClose();
  }

  Future<void> closeClashDaemon() async {
    Get.printInfo(info: 'fclash: closing daemon');
    if (isSystemProxy()) {
      await clearSystemProxy(permanent: false);
    }
    await _clashLock?.unlock();
  }

  void getProxies() {
    proxies.value =
        json.decode(clashFFI.get_proxies().cast<Utf8>().toDartString());
  }

  void startLogging() {
    final receiver = ReceivePort();
    logStream = receiver.asBroadcastStream();

    final nativePort = receiver.sendPort.nativePort;
    debugPrint("port: $nativePort");
    clashFFI.start_log(nativePort);
  }

  Future<bool> _changeConfig(FileSystemEntity config) async {
    // check if it has `rule-set`, and try to convert it
    final content = await convertConfig(await File(config.path).readAsString())
        .catchError((e) {
      printError(info: e);
    });
    if (content.isNotEmpty) {
      await File(config.path).writeAsString(content);
    }
    // judge valid
    if (clashFFI.is_config_valid(config.path.toNativeUtf8().cast()) == 0) {
      final resp = await Request.dioClient.put('/configs',
          queryParameters: {"force": false}, data: {"path": config.path});
      Get.printInfo(info: 'config changed ret: ${resp.statusCode}');
      currentYaml.value = basename(config.path);
      clashFFI.set_config(config.path.toNativeUtf8().cast());
      SpUtil.setData('yaml', currentYaml.value);
      return resp.statusCode == 204;
    } else {
      Future.delayed(Duration.zero, () {
        Get.defaultDialog(
            middleText: 'not a valid config file'.tr,
            onConfirm: () {
              Get.back();
            });
      });
      config.delete();
      return false;
    }
  }

  Future<bool> changeYaml(FileSystemEntity config) async {
    try {
      if (await config.exists()) {
        return await _changeConfig(config);
      } else {
        return false;
      }
    } finally {
      reload();
    }
  }

  Future<bool> changeProxy(String selectName, String proxyName) async {
    final ret = await clashFFI.change_proxy(selectName, proxyName);
    if (ret == 0) {
      reload();
    }
    return ret == 0;
  }

  Future<bool> changeConfigField(String field, dynamic value) async {
    try {
      var jsonString = json.encode(<String, dynamic>{field: value});
      int ret = await clashFFI.change_config_field(jsonString);
      return ret == 0;
    } finally {
      getCurrentClashConfig();
      if (field.endsWith("port") && isSystemProxy()) {
        await clearSystemProxy();
        Future.delayed(Duration(seconds: 1), () {
          setSystemProxy();
        });
      }
    }
  }

  bool isSystemProxy() {
    return SpUtil.getData('system_proxy', defValue: false);
  }

  Future<bool> setIsSystemProxy(bool proxy) {
    isSystemProxyObs.value = proxy;
    return SpUtil.setData('system_proxy', proxy);
  }

  Future<bool> setSystemProxy() async {
    if (isDesktop) {
      return false;
    } else {
      if (configEntity.value != null) {
        final entity = configEntity.value!;
        if (entity.mixedPort != 0) {
          await mobileChannel
              .invokeMethod("SetHttpPort", {"port": entity.mixedPort});
        }
        bool permission = await mobileChannel.invokeMethod("StartProxy");
        print('permission:$permission');
        if (permission) {
          await setIsSystemProxy(true);
          return true;
        } else {
          await setIsSystemProxy(false);
          return false;
        }
      }
      return false;
    }
  }

  Future<void> clearSystemProxy({bool permanent = true}) async {
    if (isDesktop) {
    } else {
      mobileChannel.invokeMethod("StopProxy");
      await setIsSystemProxy(false);
    }
  }

  Future<bool> addProfile(String name, String url, String token,
      {bool adblock = false, bool website = false}) async {
    final configName = '$name.yaml';
    final newProfilePath = join(_clashDirectory.path, configName);
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

      // dio.httpClientAdapter = IOHttpClientAdapter(
      //   createHttpClient: () {
      //     final client = HttpClient();
      //     client.findProxy = (finalUri) {
      //       return 'PROXY 192.168.2.77:8888';
      //     };
      //     return client;
      //   },
      // );
      final resp = await dio.downloadUri(finalUri, newProfilePath,
          onReceiveProgress: (i, t) {
        Get.printInfo(info: "$i/$t");
      });
      return resp.statusCode == 200;
    } catch (e) {
      print(e);
      // BrnToast.show("Error: ${e}", Get.context!);
    } finally {
      final f = File(newProfilePath);
      if (f.existsSync() && await changeYaml(f)) {
        // set subscription
        await SpUtil.setData('profile_$name', url);
        mobileChannel.invokeMethod(
            "addProfileForAndroid", {"proFilePath": newProfilePath});
        // Get.bus.fire("ClashProvileUpdate");
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
      reload();
      return true;
    } else {
      return false;
    }
  }

  void checkPort() {
    if (configEntity.value != null) {
      if (configEntity.value!.port == 0) {
        changeConfigField('port', initializedHttpPort);
      }
      if (configEntity.value!.mixedPort == 0) {
        changeConfigField('mixed-port', initializedMixedPort);
      }
      if (configEntity.value!.socksPort == 0) {
        changeConfigField('socks-port', initializedSockPort);
      }
    }
  }

  Future<int> delay(String proxyName,
      {int timeout = 5000, String url = "https://www.google.com"}) async {
    try {
      final completer = Completer<int>();
      final receiver = ReceivePort();
      clashFFI.async_test_delay(proxyName.toNativeUtf8().cast(),
          url.toNativeUtf8().cast(), timeout, receiver.sendPort.nativePort);
      final subs = receiver.listen((message) {
        if (!completer.isCompleted) {
          completer.complete(json.decode(message)['delay']);
        }
      });
      // 5s timeout, we add 1s
      Future.delayed(const Duration(seconds: 6), () {
        if (!completer.isCompleted) {
          completer.complete(-1);
        }
        subs.cancel();
      });
      return completer.future;
    } catch (e) {
      return -1;
    }
  }

  /// yaml: test
  String getSubscriptionLinkByYaml(String yaml) {
    final url = SpUtil.getData('profile_$yaml', defValue: "");
    Get.printInfo(info: 'subs link for $yaml: $url');
    return url;
  }

  /// stop clash by ps -A
  /// ps -A | grep '[^f]clash' | awk '{print $1}' | xargs
  ///
  /// notice: is a double check in client mode
  // void stopClashSubP() {
  //   final res = Process.runSync("ps", [
  //     "-A",
  //     "|",
  //     "grep",
  //     "'[^f]clash'",
  //     "|",
  //     "awk",
  //     "'print \$1'",
  //     "|",
  //     "xrgs",
  //   ]);
  //   final clashPids = res.stdout.toString().split(" ");
  //   for (final pid in clashPids) {
  //     final pidInt = int.tryParse(pid);
  //     if (pidInt != null) {
  //       Process.killPid(int.parse(pid));
  //     }
  //   }
  // }

  Future<bool> updateSubscription(String name) async {
    final configName = '$name.yaml';
    final newProfilePath = join(_clashDirectory.path, configName);
    final url = SpUtil.getData('profile_$name');
    try {
      final uri = Uri.tryParse(url);
      if (uri == null) {
        return false;
      }
      // delete exists
      final f = File(newProfilePath);
      final tmpF = File('$newProfilePath.tmp');

      final resp = await Dio(BaseOptions(
              headers: {'User-Agent': 'Fclash'},
              sendTimeout: const Duration(milliseconds: 15000),
              receiveTimeout: const Duration(milliseconds: 15000)))
          .downloadUri(uri, tmpF.path, onReceiveProgress: (i, t) {
        Get.printInfo(info: "$i/$t");
      }).catchError((e) {
        if (tmpF.existsSync()) {
          tmpF.deleteSync();
        }
      });
      if (resp.statusCode == 200) {
        if (f.existsSync()) {
          f.deleteSync();
        }
        tmpF.renameSync(f.path);
      }
      // set subscription
      await SpUtil.setData('profile_$name', url);
      return resp.statusCode == 200;
    } finally {
      final f = File(newProfilePath);
      if (f.existsSync()) {
        await changeYaml(f);
      }
    }
  }

  bool isHideWindowWhenStart() {
    return SpUtil.getData('boot_window_hide', defValue: false);
  }

  Future<bool> setHideWindowWhenStart(bool hide) {
    return SpUtil.setData('boot_window_hide', hide);
  }

  void handleSignal() {
    StreamSubscription? subTerm;
    subTerm = ProcessSignal.sigterm.watch().listen((event) {
      subTerm?.cancel();
      // _clashProcess?.kill();
    });
  }

  Future<void> testAllProxies(List<dynamic> allItem) async {
    await Future.wait(allItem.map((proxyName) async {
      final delayInMs = await delay(proxyName);
      proxyStatus[proxyName] = delayInMs;
    }));
  }

  Future<void> _acquireLock(Directory clashDirectory) async {
    final path = p.join(clashDirectory.path, "fclash.lock");
    final lockFile = File(path);
    if (!lockFile.existsSync()) {
      lockFile.createSync(recursive: true);
    }
    try {
      _clashLock = await lockFile.open(mode: FileMode.write);
      await _clashLock?.lock();
    } catch (e) {
      if (!Platform.isWindows) {
        // await Get.find<NotificationService>()
        //     .showNotification("Fclash", "Already running, Now exit.".tr);
      }
      exit(0);
    }
  }

  void stopLog() {
    logStream = null;
    clashFFI.stop_log();
  }
}

Future<String> convertConfig(String content) async {
  try {
    final yamlWriter = YAMLWriter();
    final payloadMap = <String, List>{};
    Map doc = json.decode(json.encode(loadYaml(content, recover: true)));
    // 下载rule-provider对应的payload文件
    if (doc.containsKey('rule-providers')) {
      Map providers = doc['rule-providers'];
      final total = providers.keys.length;
      final index = 0.obs;

      // 开始转换rules
      var rules = doc['rules'];
      var newRules = [];
      for (var i = 0; i < rules.length; i++) {
        String rule = rules[i];
        final tuple = rule.split(",");
        assert(tuple.length == 3);
        // RULE-SET,其它影音站点,其它影音站点
        if (tuple[0] == 'RULE-SET') {
          final provider = tuple[1];
          final proxyTo = tuple[2];
          if (payloadMap[provider] != null) {
            for (final payload in payloadMap[provider]!) {
              var payloadArr = payload.toString().split(',');
              if (payloadArr.isEmpty) {
                continue;
              }
              // IP加上IP-CIDR
              if (int.tryParse(payloadArr.first.substring(0, 1)) != null) {
                payloadArr.insert(0, 'IP-CIDR');
              }
              // https://github.com/Dreamacro/clash/wiki/configuration#no-resolve
              if (payload.endsWith('no-resolve')) {
                payloadArr.insert(payloadArr.length - 1, proxyTo);
              } else {
                payloadArr.add(proxyTo);
              }
              newRules.add(payloadArr.join(','));
            }
          }
        } else {
          if (tuple.where((element) => element.isEmpty).isEmpty) {
            newRules.add(rule);
          }
        }
      }
      // doc.remove('rule-providers');
      doc['rules'] = newRules;
      final outputString = yamlWriter.write(doc);
      return outputString;
    } else {
      // no need to update
      return "";
    }
  } catch (e) {
    debugPrint("$e");
    // ignore
    return "";
  } finally {
    // BrnLoadingDialog.dismiss(Get.overlayContext!);
  }
}
