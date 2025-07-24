import 'levinci_zebra_platform_interface.dart';

class LevinciZebra {
  Future<String?> getPlatformVersion() {
    return LevinciZebraPlatform.instance.getPlatformVersion();
  }

  Future<dynamic> discoverLanDevices({int? hops}) {
    return LevinciZebraPlatform.instance.discoverLanDevices(hops: hops);
  }

  Future<dynamic> discoverByLan() {
    return LevinciZebraPlatform.instance.discoverByLan();
  }

  Future<dynamic> discoverByBroadcast() {
    return LevinciZebraPlatform.instance.discoverByBroadcast();
  }

  Future<dynamic> discoverByHops({required int hops}) {
    return LevinciZebraPlatform.instance.discoverByHops(hops: hops);
  }

  Future<void> sendCommand(
      {required String ipAddress, required int port, required String command}) {
    return LevinciZebraPlatform.instance
        .sendCommand(ipAddress: ipAddress, port: port, command: command);
  }
}
