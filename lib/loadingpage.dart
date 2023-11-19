import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:rebornlauncher/main.dart';

class LoadingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    initSettings(context);

    return Scaffold(
      backgroundColor: Colors.orange,
      body: Center(
          child: CircularProgressIndicator(
        color: Colors.white,
      )),
    );
  }

  void initSettings(BuildContext context) async {
    FlutterSecureStorage storage = FlutterSecureStorage();

    if (await storage.containsKey(key: "battlebornPath")) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => SetupPage(Setting.filePath)),
      );
    }
  }
}
