import 'package:flutter/material.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterDisplayMode.setHighRefreshRate();
  runApp(const SpecsApp());
}

class SpecsApp extends StatelessWidget {
  const SpecsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        ColorScheme lightColorScheme;
        ColorScheme darkColorScheme;

        if (lightDynamic != null && darkDynamic != null) {
          // Use dynamic colors if available
          lightColorScheme = lightDynamic.harmonized();
          darkColorScheme = darkDynamic.harmonized();
        } else {
          // Fallback to default color schemes
          lightColorScheme = ColorScheme.fromSeed(seedColor: Colors.deepPurple);
          darkColorScheme = ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.dark,
          );
        }

        return MaterialApp(
          title: 'Specs',
          theme: ThemeData(
            colorScheme: lightColorScheme,
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: <TargetPlatform, PageTransitionsBuilder>{
                TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
              },
            ),
          ),
          darkTheme: ThemeData(
            colorScheme: darkColorScheme,
          ),
          themeMode: ThemeMode.system,
          home: const HomePage(title: 'Specs'),
        );
      },
    );
  }
}

class InfoItem extends StatelessWidget {
  final String title;
  final String value;
  final String? clipboardText;
  final EdgeInsets padding;

  const InfoItem({
    super.key,
    required this.title,
    required this.value,
    this.clipboardText,
    this.padding = const EdgeInsets.symmetric(vertical: 10.0),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: GestureDetector(
        onLongPress: () {
          Clipboard.setData(ClipboardData(text: clipboardText ?? "$title: $value"));
          HapticFeedback.lightImpact();
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              value,
              style: TextStyle(color: Theme.of(context).colorScheme.secondary),
            ),
          ],
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});
  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<AndroidDeviceInfo> _androidDeviceInfo;
  final Battery _battery = Battery();
  final NetworkInfo _networkInfo = NetworkInfo();
  int? _batteryLevel;
  BatteryState? _batteryState;
  bool? _isInBatterySaveMode;
  String? _wifiIP;
  String? _wifiIPv6;
  String? _wifiBSSID;
  String? _wifiSubmask;
  String? _wifiBroadcast;
  String? _wifiGateway;
  String? _packageName;
  String? _appVersion;
  double? _displayWidth;
  double? _displayHeight;
  double? _displayDensity;

  @override
  void initState() {
    super.initState();
    _androidDeviceInfo = DeviceInfoPlugin().androidInfo;
    _initBattery();
    _initBatterySaveMode();
    _initExtraInfo();
  }

  Future<void> _initExtraInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();

    // Get WiFi information using network_info_plus
    final wifiIP = await _networkInfo.getWifiIP();
    final wifiBSSID = await _networkInfo.getWifiBSSID();
    final wifiGateway = await _networkInfo.getWifiGatewayIP();
    final wifiIPv6 = await _networkInfo.getWifiIPv6();
    final wifiSubmask = await _networkInfo.getWifiSubmask();
    final wifiBroadcast = await _networkInfo.getWifiBroadcast();

    setState(() {
      _wifiIP = wifiIP;
      _wifiIPv6 = wifiIPv6;
      _wifiBSSID = wifiBSSID;
      _wifiSubmask = wifiSubmask;
      _wifiBroadcast = wifiBroadcast;
      _wifiGateway = wifiGateway;
      _packageName = packageInfo.packageName;
      _appVersion = packageInfo.version;
    });
  }

  void _initBattery() async {
    _batteryLevel = await _battery.batteryLevel;
    _battery.onBatteryStateChanged.listen((state) {
      setState(() {
        _batteryState = state;
      });
    });
    setState(() {});
  }

  void _initBatterySaveMode() async {
    _isInBatterySaveMode = await _battery.isInBatterySaveMode;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // Get the display size using MediaQuery
    final mediaQuery = MediaQuery.of(context);
    _displayWidth = mediaQuery.size.width;
    _displayHeight = mediaQuery.size.height;
    _displayDensity = mediaQuery.devicePixelRatio;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            backgroundColor: Theme.of(context).colorScheme.surface,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 25, bottom: 20), // Align title to the left
              title: Text(
                "Specs",
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate(
              [
                Align(
                  alignment: Alignment.center,
                  child: FutureBuilder<AndroidDeviceInfo>(
                    future: _androidDeviceInfo,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return Card.filled(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          child: SizedBox(
                            width: 360.0,
                            height: 150.0,
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Text(
                                snapshot.connectionState == ConnectionState.waiting
                                    ? "Loading..."
                                    : "Failed to get device info",
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                          ),
                        );
                      }
                      final info = snapshot.data!;
                      return Card.filled(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        child: SizedBox(
                          width: 360.0,
                          height: 150.0,
                          child: Padding(
                            padding: const EdgeInsets.all(15.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      info.name,
                                      style: Theme.of(context).textTheme.titleLarge,
                                    ),
                                    Text(
                                      "Android ${info.version.release}",
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                    Expanded(
                                      child: Align(
                                        alignment: Alignment.bottomLeft,
                                        child: Text(
                                          "SDK ${info.version.sdkInt}",
                                          style: Theme.of(context).textTheme.labelLarge,
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(right: 40),
                                  child: Icon(
                                  Icons.android,
                                  size: 50,
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(30),
                  child: FutureBuilder<AndroidDeviceInfo>(
                    future: _androidDeviceInfo,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Android",
                            style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: Theme.of(context).colorScheme.primary)
                            ),
                            const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ],
                        );
                      } else if (snapshot.hasError) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Android",
                            style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: Theme.of(context).colorScheme.primary)
                            ),
                            const Text("Failed to get device info"),
                          ],
                        );
                      } else if (snapshot.hasData) {
                        final info = snapshot.data!;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Android",
                            style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: Theme.of(context).colorScheme.primary)
                            ),
                            // Android Section
                            InfoItem(
                              title: "Base OS",
                              value: info.version.baseOS?.isEmpty ?? true ? 'Unknown' : info.version.baseOS!,
                              clipboardText: "Base OS: ${info.version.baseOS?.isEmpty ?? true ? 'Unknown' : info.version.baseOS}",
                            ),
                            InfoItem(
                              title: "Version",
                              value: info.version.release,
                              clipboardText: "Version: ${info.version.release}",
                            ),
                            InfoItem(
                              title: "Codename",
                              value: info.version.codename,
                              clipboardText: "Codename: ${info.version.codename}",
                            ),
                            InfoItem(
                              title: "SDK",
                              value: "${info.version.sdkInt}",
                              clipboardText: "SDK: ${info.version.sdkInt}",
                            ),
                            InfoItem(
                              title: "Security Patch",
                              value: "${info.version.securityPatch}",
                              clipboardText: "Security Patch: ${info.version.securityPatch}",
                            ),

                            // Display Section
                            Padding(
                              padding: const EdgeInsets.only(top: 40),
                              child: Text(
                                "Display",
                                style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: Theme.of(context).colorScheme.primary)
                                ),
                            ),
                            InfoItem(
                              title: "Display Width",
                              value: "${((_displayWidth ?? 0) * (_displayDensity ?? 0)).toStringAsFixed(0)}px",
                              clipboardText: "Display Width: ${((_displayWidth ?? 0) * (_displayDensity ?? 0)).toStringAsFixed(0)}px",
                            ),
                            InfoItem(
                              title: "Display Height",
                              value: "${((_displayHeight ?? 0) * (_displayDensity ?? 0)).toStringAsFixed(0)}px",
                              clipboardText: "Display Height: ${((_displayHeight ?? 0) * (_displayDensity ?? 0)).toStringAsFixed(0)}px",
                            ),

                            // Battery Section
                            Padding(
                              padding: const EdgeInsets.only(top: 40),
                              child: Text("Battery",
                              style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: Theme.of(context).colorScheme.primary)
                              ),
                            ),
                            InfoItem(
                              title: "Battery Level",
                              value: "${_batteryLevel ?? '...'}%",
                              clipboardText: "Battery Level: ${_batteryLevel ?? '...'}%",
                            ),
                            InfoItem(
                              title: "Battery State",
                              value: _batteryState?.toString().split('.').last ?? 'Unknown',
                              clipboardText: "Battery State: ${_batteryState?.toString().split('.').last ?? 'Unknown'}",
                            ),
                            InfoItem(
                              title: "Battery Saver",
                              value: _isInBatterySaveMode == null ? 'Unknown' : _isInBatterySaveMode! ? 'On' : 'Off',
                              clipboardText: "Battery Saver: ${_isInBatterySaveMode == null ? 'Unknown' : _isInBatterySaveMode! ? 'On' : 'Off'}",
                            ),

                            // Device Section
                            Padding(
                              padding: const EdgeInsets.only(top: 40),
                              child: Text(
                                "Device",
                                style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: Theme.of(context).colorScheme.primary)
                              ),
                            ),
                            InfoItem(
                              title: "Brand",
                              value: info.brand,
                              clipboardText: "Brand: ${info.brand}",
                            ),
                            InfoItem(
                              title: "Device",
                              value: info.device,
                              clipboardText: "Device: ${info.device}",
                            ),
                            InfoItem(
                              title: "Model",
                              value: info.model,
                              clipboardText: "Model: ${info.model}",
                            ),
                            InfoItem(
                              title: "Manufacturer",
                              value: info.manufacturer,
                              clipboardText: "Manufacturer: ${info.manufacturer}",
                            ),
                            InfoItem(
                              title: "Product",
                              value: info.product,
                              clipboardText: "Product: ${info.product}",
                            ),
                            InfoItem(
                              title: "Board",
                              value: info.board,
                              clipboardText: "Board: ${info.board}",
                            ),
                            InfoItem(
                              title: "Hardware",
                              value: info.hardware,
                              clipboardText: "Hardware: ${info.hardware}",
                            ),
                            InfoItem(
                              title: "ID",
                              value: info.id,
                              clipboardText: "ID: ${info.id}",
                            ),
                            InfoItem(
                              title: "Host",
                              value: info.host,
                              clipboardText: "Host: ${info.host}",
                            ),
                            InfoItem(
                              title: "Bootloader",
                              value: info.bootloader,
                              clipboardText: "Bootloader: ${info.bootloader}",
                            ),
                            InfoItem(
                              title: "Type",
                              value: info.type,
                              clipboardText: "Type: ${info.type}",
                            ),
                            InfoItem(
                              title: "Tags",
                              value: info.tags,
                              clipboardText: "Tags: ${info.tags}",
                            ),
                            InfoItem(
                              title: "Serial Number",
                              value: info.serialNumber,
                              clipboardText: "Serial Number: ${info.serialNumber}",
                            ),
                            InfoItem(
                              title: "Fingerprint",
                              value: info.fingerprint,
                              clipboardText: "Fingerprint: ${info.fingerprint}",
                            ),

                            // WiFi Section
                            Padding(
                              padding: const EdgeInsets.only(top: 40),
                              child: Text(
                                "WiFi",
                                style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: Theme.of(context).colorScheme.primary)
                              ),
                            ),
                            InfoItem(
                              title: "WiFi Gateway",
                              value: _wifiGateway ?? 'Unknown',
                              clipboardText: "WiFi Gateway: ${_wifiGateway ?? 'Unknown'}",
                            ),
                            InfoItem(
                              title: "WiFi Broadcast",
                              value: _wifiBroadcast ?? 'Unknown',
                              clipboardText: "WiFi Broadcast: ${_wifiBroadcast ?? 'Unknown'}",
                            ),
                            InfoItem(
                              title: "WiFi IP (IPv4)",
                              value: _wifiIP ?? 'Unknown',
                              clipboardText: "WiFi IP (IPv4): ${_wifiIP ?? 'Unknown'}",
                            ),
                            InfoItem(
                              title: "WiFi IP (IPv6)",
                              value: _wifiIPv6 ?? 'Unknown',
                              clipboardText: "WiFi IP (IPv6): ${_wifiIPv6 ?? 'Unknown'}",
                            ),
                            InfoItem(
                              title: "WiFi Submask",
                              value: _wifiSubmask ?? 'Unknown',
                              clipboardText: "WiFi Submask: ${_wifiSubmask ?? 'Unknown'}",
                            ),
                            InfoItem(
                              title: "WiFi BSSID",
                              value: _wifiBSSID ?? 'Unknown',
                              clipboardText: "WiFi BSSID: ${_wifiBSSID ?? 'Unknown'}",
                            ),

                            // RAM Section
                            Padding(
                              padding: const EdgeInsets.only(top: 40),
                              child: Text(
                                "RAM",
                                style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: Theme.of(context).colorScheme.primary)
                                ),
                            ),
                            InfoItem(
                              title: "Available RAM",
                              value: "${info.availableRamSize}",
                              clipboardText: "Available RAM: ${info.availableRamSize}",
                            ),
                            InfoItem(
                              title: "Physical RAM Size",
                              value: "${info.physicalRamSize}",
                              clipboardText: "Physical RAM Size: ${info.physicalRamSize}",
                            ),
                            InfoItem(
                              title: "Low RAM Device",
                              value: "${info.isLowRamDevice}",
                              clipboardText: "Low RAM Device: ${info.isLowRamDevice}",
                            ),

                            // App Section
                            Padding(
                              padding: const EdgeInsets.only(top: 40),
                              child: Text(
                                "App",
                                style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: Theme.of(context).colorScheme.primary)
                              ),
                            ),
                            InfoItem(
                              title: "App Package",
                              value: _packageName ?? 'Unknown',
                              clipboardText: "App Package: ${_packageName ?? 'Unknown'}",
                            ),
                            InfoItem(
                              title: "App Version",
                              value: _appVersion ?? 'Unknown',
                              clipboardText: "App Version: ${_appVersion ?? 'Unknown'}",
                            ),
                          ],
                        );
                      } else {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Android", style: Theme.of(context).textTheme.headlineMedium),
                            const Text("No device info"),
                          ],
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
