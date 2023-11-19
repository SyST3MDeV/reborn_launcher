import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fvp/fvp.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rebornlauncher/autoupdate.dart';
import 'package:rebornlauncher/loadingpage.dart';
import 'package:video_player/video_player.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  registerWith();

  WindowOptions windowOptions = WindowOptions(
      size: Size(960 - 50, 540),
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
      title: "ReBorn Launcher");
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
  });
  windowManager.setMaximizable(false);
  windowManager.setSize(Size(960 - 50, 540));
  windowManager.setResizable(false);
  runApp(const ReBornLauncher());
}

class ReBornLauncher extends StatelessWidget {
  const ReBornLauncher({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ReBorn Launcher',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
      ),
      home: LoadingPage(),
    );
  }
}

enum Setting { filePath }

class SetupPage extends StatefulWidget {
  Setting setting;

  SetupPage(this.setting, {super.key});

  @override
  State<StatefulWidget> createState() => SetupPageState();
}

class SetupPageState extends State<SetupPage> {
  String? error = null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange,
      body: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        error != null
            ? Card(
                child: Padding(
                padding: EdgeInsets.all(5),
                child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error,
                        color: Colors.red,
                      ),
                      Padding(padding: EdgeInsets.only(left: 10)),
                      FittedBox(
                          fit: BoxFit.contain,
                          child: Text(
                            error!,
                            style: TextStyle(
                                color: Colors.red, fontWeight: FontWeight.bold),
                          )),
                      Padding(padding: EdgeInsets.only(right: 10)),
                    ]),
              ))
            : Container(),
        ElevatedButton(
            onPressed: selectBattlebornFolder,
            child: Text("Select your Battleborn directory"))
      ])),
    );
  }

  void selectBattlebornFolder() {
    FilePicker.platform
        .getDirectoryPath(
            dialogTitle:
                "Select the folder Battleborn is installed in (the folder with the PoplarGame and WillowGame folders in it)",
            lockParentWindow: true)
        .then((value) {
      if (value == null) {
        setState(() {
          error = "Please select a directory";
        });
      } else {
        if (File(value! + "\\Binaries\\Win64\\Battleborn.exe").existsSync()) {
          FlutterSecureStorage storage = FlutterSecureStorage();

          storage.write(key: "battlebornPath", value: value).then((value) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomePage()),
            );
          });
        } else {
          setState(() {
            error =
                "Failed to locate the Battleborn binary, please make sure you selected the folder with the WillowGame and PoplarGame folders in it.";
          });
        }
      }
    });
  }
}

class HomePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return HomePageState();
  }
}

enum CurrentHomePageState { Login, MainPage }

enum MainPageState { None, Settings, PvE }

class LauncherUpdateRequiredPage extends StatelessWidget {
  AutoUpdater autoUpdater;

  LauncherUpdateRequiredPage(this.autoUpdater);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange,
      body: Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Updating the ReBorn launcher...",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          CircularProgressIndicator(
            color: Colors.white,
          )
        ],
      )),
    );
  }
}

class HomePageState extends State<HomePage> with TickerProviderStateMixin {
  VideoPlayerController controller =
      VideoPlayerController.asset("assets/background.mp4");

  AudioPlayer player = AudioPlayer();

  CurrentHomePageState currentHomePageState = CurrentHomePageState.Login;
  MainPageState mainPageState = MainPageState.None;

  double MouseSensitivityXSliderVal = 50;
  double MouseSensitivityYSliderVal = 50;

  double FOV = 90;

  bool subtitles = false;
  bool menuMusic = true;

  AutoUpdater? autoUpdater;

  TextEditingController mouseSensitivityXController =
      TextEditingController(text: 50.toString());

  TextEditingController mouseSensitivityYController =
      TextEditingController(text: 50.toString());

  TextEditingController FOVController =
      TextEditingController(text: 90.toString());

  bool canPlayGame = false;

  String selectedMap = "PvE_Prologue_P";

  Map<String, String> maps = <String, String>{
    "PvE_Prologue_P": "Story Mission 0: Prologue",
    "Caverns_P": "Story Mission 1: The Algorithm",
    "Portal_P": "Story Mission 2: Void's Edge",
    "Captains_P": "Story Mission 3: The Renegade",
    "Evacuation_P": "Story Mission 4: The Archive",
    "Ruins_P": "Story Mission 5: The Sentinel",
    "Observatory_p": "Story Mission 6: The Experiment",
    "Refinery_P": "Story Mission 7: The Saboteur",
    "Cathedral_P": "Story Mission 8: The Heliophage",
    "Slums_P": "Operation 1: Attikus and the Thrall Rebellion",
    "Toby_Raid_P": "Operation 2: Toby's Friendship Raid",
    "CullingFacility_P": "Operation 3: Oscar Mike vs the Battleschool",
    "TallTales_P": "Operation 4: Montana and the Demon Bear",
    "Heart_Ekkunar_P": "Operation 5: Pheobe and the Heart of Ekkunar",
  };

  String selectedCharacter = "ModernSoldier";

  Map<String, String> characters = <String, String>{
    "WaterMonk": "Alani",
    "SunPriestess": "Ambra",
    "SoulCollector": "Attikus",
    "PlagueBringer": "Beatrix",
    "RocketHawk": "Benedict",
    "DwarvenWarrior": "Boldur",
    "AssaultJump": "Caldarius",
    "DarkAssassin": "Deande",
    "LeapingLuchador": "El Dragon",
    "Bombirdier": "Ernest",
    "Blackguard": "Galilea",
    "PapaShotgun": "Ghalt",
    "SpiritMech": "ISIC",
    "IceGolem": "Kelvin",
    "SideKick": "Kid Ultra",
    "TacticalBuilder": "Kleese",
    "GentSniper": "Marquis",
    "MutantFist": "Mellka",
    "TribalHealer": "Miko",
    "MachineGunner": "Montana",
    "ChaosMage": "Orendi",
    "ModernSoldier": "Oscar Mike",
    "CornerSneaker": "Pendles",
    "MageBlade": "Phoebe",
    "DeathBlade": "Rath",
    "RogueCommander": "Reyna",
    "BoyAndDjinn": "Shayne & Aurox",
    "DarkElf": "Thorn",
    "PenguinMech": "Toby",
    "RogueSoldier": "Whiskey Foxtrot"
  };

  void autoUpdaterStateChanged(AutoUpdaterState state) {
    setState(() {});
    if (state == AutoUpdaterState.LauncherUpdateRequired) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => LauncherUpdateRequiredPage(autoUpdater!)),
      );
    }
    autoUpdater!.canPlayGame().then((value) => setState(() {
          canPlayGame = value;
        }));
  }

  @override
  void initState() {
    super.initState();

    autoUpdater = AutoUpdater(autoUpdaterStateChanged);

    controller.initialize().then((value) {
      controller.setLooping(true);
      controller.setVolume(0);
      controller.play();
    });

    if (menuMusic) {
      player.setVolume(.075);
    } else {
      player.setVolume(0);
    }

    player.setReleaseMode(ReleaseMode.loop);
    player.play(AssetSource("menu.mp3"));

    FlutterSecureStorage storage = FlutterSecureStorage();

    storage.read(key: "mouseSensitivityX").then((value) {
      if (value != null) {
        setState(() {
          mouseSensitivityXController.text = value;
          MouseSensitivityXSliderVal = double.parse(value);
        });
      } else {
        setState(() {
          mouseSensitivityXController.text = 50.toString();
          MouseSensitivityXSliderVal = 50;

          storage.write(key: "mouseSensitivityX", value: "50.0");
        });
      }
    });

    storage.read(key: "mouseSensitivityY").then((value) {
      if (value != null) {
        setState(() {
          mouseSensitivityYController.text = value;
          MouseSensitivityYSliderVal = double.parse(value);
        });
      } else {
        setState(() {
          mouseSensitivityYController.text = 50.toString();
          MouseSensitivityYSliderVal = 50;

          storage.write(key: "mouseSensitivityY", value: "50.0");
        });
      }
    });

    storage.read(key: "FOV").then((value) {
      if (value != null) {
        setState(() {
          FOVController.text = value;
          FOV = double.parse(value);
        });
      } else {
        setState(() {
          FOVController.text = 90.toString();
          FOV = 90;

          storage.write(key: "FOV", value: "90");
        });
      }
    });

    storage.read(key: "subtitles").then((value) {
      if (value != null) {
        setState(() {
          subtitles = bool.parse(value);
        });
      } else {
        setState(() {
          subtitles = false;

          storage.write(key: "subtitles", value: false.toString());
        });
      }
    });

    storage.read(key: "menuMusic").then((value) {
      if (value != null) {
        setState(() {
          menuMusic = bool.parse(value);

          if (menuMusic) {
            player.setVolume(.075);
          } else {
            player.setVolume(0);
          }
        });
      } else {
        setState(() {
          subtitles = false;

          storage.write(key: "menuMusic", value: true.toString());
        });
      }
    });
  }

  Icon getCurrentDownloadIcon() {
    switch (autoUpdater?.state) {
      case AutoUpdaterState.CheckingForUpdates:
        return Icon(
          Icons.update,
          color: Colors.white,
        );
      case null:
        return Icon(
          Icons.update_disabled,
          color: Colors.red,
        );
      case AutoUpdaterState.FailedToCheckForUpdates:
        return Icon(
          Icons.update_disabled,
          color: Colors.red,
        );
      case AutoUpdaterState.UpdateInProgress:
        return Icon(
          Icons.download,
          color: Colors.white,
        );
      case AutoUpdaterState.Done:
        return Icon(
          Icons.check,
          color: Colors.green,
        );
      case AutoUpdaterState.LauncherUpdateRequired:
        return Icon(
          Icons.update_disabled,
          color: Colors.red,
        );
    }
  }

  Widget getCurrentHomePageWidget() {
    switch (currentHomePageState) {
      case CurrentHomePageState.Login:
        return Align(
            alignment: Alignment.centerLeft,
            key: Key("login"),
            child: FractionallySizedBox(
              widthFactor: .33,
              heightFactor: 1,
              child: Material(
                  color: Colors.black.withOpacity(.25),
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Stack(
                      children: [
                        Align(
                            alignment: Alignment.topCenter,
                            child: Column(children: [
                              SizedBox(
                                child:
                                    Image(image: AssetImage("assets/logo.png")),
                                width: 150,
                                height: 150,
                              ),
                              Text(
                                "ReBorn",
                                style: TextStyle(
                                    color: Colors.yellow,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 25),
                              )
                            ])),
                        Align(
                            alignment: Alignment.center,
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  currentHomePageState =
                                      CurrentHomePageState.MainPage;
                                });
                              },
                              child: Text(
                                "PLAY",
                                style: TextStyle(fontWeight: FontWeight.w900),
                              ),
                            )),
                        Align(
                            alignment: Alignment.bottomCenter,
                            child: Text(
                              "Developed by @gwog :3\nIcon by @koz\nMuch <3 to all!",
                              style: TextStyle(color: Colors.white),
                            ))
                      ],
                    ),
                  )),
            ));
      case CurrentHomePageState.MainPage:
        return Align(
          key: Key("main"),
          alignment: Alignment.centerLeft,
          heightFactor: double.infinity,
          widthFactor: double.infinity,
          child: SizedBox.expand(
              child: Stack(children: [
            AnimatedFractionallySizedBox(
                duration: Duration(milliseconds: 250),
                alignment: Alignment.topCenter,
                heightFactor: mainPageState == MainPageState.None ? .15 : 1,
                widthFactor: 1,
                child: Material(
                    color: Colors.black.withOpacity(.25),
                    child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Stack(children: [
                          Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(children: [
                                  SizedBox(
                                    width: 50,
                                    height: 50,
                                    child: Image(
                                        image: AssetImage("assets/logo.png")),
                                  ),
                                  Padding(padding: EdgeInsets.only(left: 5)),
                                  getCurrentDownloadIcon()
                                ]),
                                Row(
                                  children: [
                                    OutlinedButton(
                                      onPressed: () {
                                        setState(() {
                                          mainPageState = MainPageState.None;
                                        });
                                      },
                                      style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.white),
                                      child: Text(
                                        "Home",
                                        style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white),
                                      ),
                                    ),
                                    Padding(padding: EdgeInsets.only(left: 20)),
                                    OutlinedButton(
                                      onPressed: () {
                                        setState(() {
                                          mainPageState =
                                              MainPageState.Settings;
                                        });
                                      },
                                      style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.white),
                                      child: Text(
                                        "Settings",
                                        style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white),
                                      ),
                                    ),
                                    Padding(padding: EdgeInsets.only(left: 20)),
                                    ElevatedButton(
                                      onPressed: () {
                                        setState(() {
                                          mainPageState = MainPageState.PvE;
                                        });
                                      },
                                      child: Text(
                                        "PLAY PvE",
                                        style: TextStyle(
                                            fontWeight: FontWeight.w900),
                                      ),
                                    )
                                  ],
                                ),
                              ]),
                        ])))),
            AnimatedSwitcher(
                duration: Duration(milliseconds: 250),
                child: getMainPageContent())
          ])),
        );
    }
  }

  Widget getMainPageContent() {
    switch (mainPageState) {
      case MainPageState.None:
        return Container();
      case MainPageState.Settings:
        return SizedBox.expand(
            key: Key("Settings"),
            child: Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: EdgeInsets.only(
                      left: 20,
                      right: 20,
                      top: (MediaQuery.of(context).size.height * .15),
                      bottom: 20),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        getSliderForVal(
                            MouseSensitivityXSliderVal,
                            mouseSensitivityXController,
                            "Mouse Sensitivity X",
                            1,
                            100, (val) {
                          MouseSensitivityXSliderVal = val;
                          FlutterSecureStorage storage = FlutterSecureStorage();
                          storage.write(
                              key: "mouseSensitivityX", value: val.toString());
                        }),
                        getSliderForVal(
                            MouseSensitivityYSliderVal,
                            mouseSensitivityYController,
                            "Mouse Sensitivity Y",
                            1,
                            100, (val) {
                          MouseSensitivityYSliderVal = val;
                          FlutterSecureStorage storage = FlutterSecureStorage();
                          storage.write(
                              key: "mouseSensitivityY", value: val.toString());
                        }),
                        getSliderForVal(
                            FOV, FOVController, "Field of View (FoV)", 60, 110,
                            (val) {
                          FOV = val;
                          FlutterSecureStorage storage = FlutterSecureStorage();
                          storage.write(key: "FOV", value: val.toString());
                        }),
                        getToggleForVal(subtitles, "Subtitles", (val) {
                          subtitles = val;
                          FlutterSecureStorage storage = FlutterSecureStorage();
                          storage.write(
                              key: "subtitles", value: val.toString());
                        }),
                        getToggleForVal(menuMusic, "Menu Music", (val) {
                          menuMusic = val;

                          if (menuMusic) {
                            player.setVolume(.075);
                          } else {
                            player.setVolume(0);
                          }

                          FlutterSecureStorage storage = FlutterSecureStorage();
                          storage.write(
                              key: "menuMusic", value: val.toString());
                        })
                      ]),
                )));
      case MainPageState.PvE:
        return SizedBox.expand(
            key: Key("PvE"),
            child: Align(
                alignment: Alignment.topLeft,
                child: Padding(
                    padding: EdgeInsets.only(
                      top: (MediaQuery.of(context).size.height * .15),
                      left: 20,
                      right: 20,
                      bottom: 20,
                    ),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Selected PvE Mission: " + maps[selectedMap]!,
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 20),
                          ),
                          ScrollConfiguration(
                              behavior: ScrollConfiguration.of(context)
                                  .copyWith(dragDevices: {
                                PointerDeviceKind.touch,
                                PointerDeviceKind.mouse,
                              }),
                              child: SizedBox(
                                  height: 192,
                                  child: GridView.builder(
                                      scrollDirection: Axis.horizontal,
                                      gridDelegate:
                                          SliverGridDelegateWithFixedCrossAxisCount(
                                              crossAxisCount: 1),
                                      itemBuilder:
                                          (BuildContext context, int number) {
                                        if (number > maps.keys.length - 1) {
                                          return null;
                                        }

                                        return Material(
                                            color: Colors.transparent,
                                            child: Ink.image(
                                              width: 92,
                                              height: 192,
                                              image: AssetImage(
                                                  "${"assets/mapIcons/" + maps.keys.toList()[number]}.png"),
                                              child: InkWell(
                                                onTap: () {
                                                  setState(() {
                                                    selectedMap = maps.keys
                                                        .toList()[number];
                                                  });
                                                },
                                              ),
                                            ));
                                      }))),
                          Text(
                            "Selected Character: " +
                                characters[selectedCharacter]!,
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 20),
                          ),
                          ScrollConfiguration(
                              behavior: ScrollConfiguration.of(context)
                                  .copyWith(dragDevices: {
                                PointerDeviceKind.touch,
                                PointerDeviceKind.mouse,
                              }),
                              child: SizedBox(
                                  height: 88,
                                  child: GridView.builder(
                                      scrollDirection: Axis.horizontal,
                                      gridDelegate:
                                          SliverGridDelegateWithFixedCrossAxisCount(
                                              crossAxisCount: 1),
                                      itemBuilder:
                                          (BuildContext context, int number) {
                                        if (number >
                                            characters.keys.length - 1) {
                                          return null;
                                        }

                                        return Material(
                                            color: Colors.transparent,
                                            child: Ink.image(
                                              width: 80,
                                              height: 88,
                                              image: AssetImage(
                                                  "${"assets/characterIcons/CharSelIcon_${characters.keys.toList()[number]}"}.png"),
                                              child: InkWell(
                                                onTap: () {
                                                  setState(() {
                                                    selectedCharacter =
                                                        characters.keys
                                                            .toList()[number];
                                                  });
                                                },
                                              ),
                                            ));
                                      }))),
                          Padding(padding: EdgeInsets.only(top: 10)),
                          SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange),
                                  onPressed: () {
                                    launchGame();
                                  },
                                  child: Text(
                                    "Launch PvE!",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                  )))
                        ]))));
    }
  }

  Future<void> writeConfiguration() async {
    FlutterSecureStorage storage = FlutterSecureStorage();

    String battlebornPath = (await storage.read(key: "battlebornPath"))!;

    if (await File(battlebornPath + "\\Binaries\\Win64\\config.json")
        .exists()) {
      await File(battlebornPath + "\\Binaries\\Win64\\config.json").delete();
    }

    File configFile = File(battlebornPath + "\\Binaries\\Win64\\config.json");

    await configFile.create();

    Map<String, dynamic> jsonObject = <String, dynamic>{
      "FOV": (await storage.read(key: "FOV")) != null
          ? await storage.read(key: "FOV")
          : "90.0",
      "MouseSensitivityX":
          (await storage.read(key: "mouseSensitivityX")) != null
              ? await storage.read(key: "mouseSensitivityX")
              : "50.0",
      "MouseSensitivityY":
          (await storage.read(key: "mouseSensitivityY")) != null
              ? await storage.read(key: "mouseSensitivityY")
              : "50.0",
      "subtitles": (await storage.read(key: "subtitles")) != null
          ? await storage.read(key: "subtitles")
          : "false",
      "mapToLoad": selectedMap,
      "characterToLoad": selectedCharacter
    };

    await configFile.writeAsString(jsonEncode(jsonObject));
  }

  Future<void> launchGame() async {
    await writeConfiguration();

    Directory appSupportDir = await getApplicationSupportDirectory();

    print(appSupportDir.path);

    FlutterSecureStorage storage = FlutterSecureStorage();

    String battlebornPath = (await storage.read(key: "battlebornPath"))!;

    Process.start(appSupportDir.path + "\\reborn_cli.exe", [
      battlebornPath + "\\Binaries\\Win64\\Battleborn.exe",
      appSupportDir.path + "\\ReBorn.dll"
    ]);

    player.stop();

    player.dispose();
  }

  Widget getToggleForVal(
      bool theval, String label, Function updateValFunction) {
    return Padding(
        padding: EdgeInsets.only(left: 20, top: 20),
        child: SizedBox(
            width: 250,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  textAlign: TextAlign.left,
                  style: TextStyle(
                      fontWeight: FontWeight.w900, color: Colors.white),
                ),
                Switch(
                    value: theval,
                    onChanged: (val) {
                      setState(() {
                        updateValFunction(val);
                      });
                    })
              ],
            )));
  }

  Widget getSliderForVal(double theval, TextEditingController thecontroller,
      String label, double min, double max, Function updateValFunction) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
          padding: EdgeInsets.only(left: 20),
          child: Text(
            label,
            textAlign: TextAlign.left,
            style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white),
          )),
      Row(mainAxisSize: MainAxisSize.max, children: [
        Slider(
            label: label,
            min: min,
            max: max,
            value: theval,
            activeColor: Colors.orange,
            onChanged: (val) {
              setState(() {
                updateValFunction(val);
                thecontroller.text = theval.round().toString();
              });
            }),
        SizedBox(
            width: 75,
            child: TextField(
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              controller: thecontroller,
              onChanged: (value) {
                if (double.tryParse(value) != null &&
                    double.tryParse(value)! < max &&
                    double.tryParse(value)! > min) {
                  setState(() {
                    updateValFunction(double.tryParse(value)!);
                  });
                }
              },
              onEditingComplete: () {
                if (double.tryParse(thecontroller.text) == null ||
                    double.tryParse(thecontroller.text)! > max ||
                    double.tryParse(thecontroller.text)! < min) {
                  setState(() {
                    thecontroller.text = theval.round().toString();
                  });
                }
              },
              decoration: InputDecoration(
                enabledBorder: OutlineInputBorder(
                    borderSide:
                        BorderSide(color: Colors.orange.withOpacity(.5))),
                focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.orange)),
                border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.orange)),
              ),
            ))
      ])
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children: [
        SizedBox.expand(child: VideoPlayer(controller)),
        AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return SlideTransition(
                position: Tween(
                  begin: Offset(-1, 0),
                  end: Offset(0, 0),
                ).animate(animation),
                child: child,
              );
            },
            child: getCurrentHomePageWidget())
      ]),
    );
  }
}
