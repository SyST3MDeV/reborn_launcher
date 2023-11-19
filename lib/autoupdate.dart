import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

enum AutoUpdaterState {
  CheckingForUpdates,
  FailedToCheckForUpdates,
  LauncherUpdateRequired,
  UpdateInProgress,
  Done
}

class AutoUpdater {
  int launcherVersion = 2;

  String domain = "https://bereborn.dev/";
  FlutterSecureStorage storage = FlutterSecureStorage();
  AutoUpdaterState state = AutoUpdaterState.CheckingForUpdates;
  Function? onStateChangedCallback = null;

  AutoUpdater(Function this.onStateChangedCallback) {
    checkForUpdates();
  }

  Future<bool> canPlayGame() async {
    /*
    Directory appSupportPath = await getApplicationSupportDirectory();

    return File(appSupportPath.path + "\\reborn_cli.exe").existsSync() &&
        File(appSupportPath.path + "\\ReBorn.dll").existsSync();
        */
    return true;
  }

  Future<void> updateLauncher() async {
    Directory savedir = await getApplicationSupportDirectory();

    http.Response DLLRequest =
        await http.get(Uri.parse("${domain}ReBornInstaller.exe"));

    if (File(savedir.path + "\\ReBornInstaller.exe").existsSync()) {
      File(savedir.path + "\\ReBornInstaller.exe").deleteSync();
    }

    File(savedir.path + "\\ReBornInstaller.exe").createSync();

    await File(savedir.path + "\\ReBornInstaller.exe")
        .writeAsBytes(DLLRequest.bodyBytes);

    await Process.start(savedir.path + "\\ReBornInstaller.exe", []);

    exit(0);
  }

  Future<void> checkForUpdates() async {
    http.Response versionRequest =
        await http.get(Uri.parse("${domain}versions.json"));

    if (versionRequest.statusCode != 200) {
      state = AutoUpdaterState.FailedToCheckForUpdates;
      if (onStateChangedCallback != null) {
        onStateChangedCallback!(state);
      }
      return;
    }

    dynamic versionJSON = jsonDecode(versionRequest.body);

    if (versionJSON["launcher"] > launcherVersion) {
      state = AutoUpdaterState.LauncherUpdateRequired;
      if (onStateChangedCallback != null) {
        onStateChangedCallback!(state);
      }
      await updateLauncher();
      return;
    }

    int installedCLIVersion = 0;

    String? storageCLIVersion = await storage.read(key: "installedCLIVersion");

    if (storageCLIVersion != null) {
      installedCLIVersion = int.tryParse(storageCLIVersion)!;
    }

    bool CLIRequiresUpdate = versionJSON["CLI"]! > installedCLIVersion;

    int installedDLLVersion = 0;

    String? storageDLLVersion = await storage.read(key: "installedDLLVersion");

    if (storageDLLVersion != null) {
      installedDLLVersion = int.tryParse(storageDLLVersion)!;
    }

    bool DLLRequiresUpdate = versionJSON["DLL"]! > installedDLLVersion;

    if (DLLRequiresUpdate || CLIRequiresUpdate) {
      state = AutoUpdaterState.UpdateInProgress;
      if (onStateChangedCallback != null) {
        onStateChangedCallback!(state);
      }
    }

    if (DLLRequiresUpdate) {
      Directory savedir = await getApplicationSupportDirectory();

      http.Response DLLRequest =
          await http.get(Uri.parse("${domain}ReBorn.dll"));

      if (File(savedir.path + "\\ReBorn.dll").existsSync()) {
        File(savedir.path + "\\ReBorn.dll").deleteSync();
      }

      File(savedir.path + "\\ReBorn.dll").createSync();

      await File(savedir.path + "\\ReBorn.dll")
          .writeAsBytes(DLLRequest.bodyBytes);

      await storage.write(
          key: "installedDLLVersion", value: versionJSON["DLL"].toString());
    }

    if (CLIRequiresUpdate) {
      Directory savedir = await getApplicationSupportDirectory();

      http.Response DLLRequest =
          await http.get(Uri.parse("${domain}reborn_cli.exe"));

      if (File(savedir.path + "\\reborn_cli.exe").existsSync()) {
        File(savedir.path + "\\reborn_cli.exe").deleteSync();
      }

      File(savedir.path + "\\reborn_cli.exe").createSync();

      await File(savedir.path + "\\reborn_cli.exe")
          .writeAsBytes(DLLRequest.bodyBytes);

      await storage.write(
          key: "installedCLIVersion", value: versionJSON["CLI"].toString());
    }

    state = AutoUpdaterState.Done;
    if (onStateChangedCallback != null) {
      onStateChangedCallback!(state);
    }
  }
}
