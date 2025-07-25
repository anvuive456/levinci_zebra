// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class DiscoveredPrinter {
  final String address;
  final String? dnsName;
  final int? port;

  DiscoveredPrinter({required this.address, this.dnsName, this.port});

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'address': address,
      'dnsName': dnsName,
      'port': port,
    };
  }

  factory DiscoveredPrinter.fromMap(Map<String, dynamic> map) {
    return DiscoveredPrinter(
      address: map['address'] ?? '',
      dnsName: map['dnsName'] as String?,
      port: map['port'] as int?,
    );
  }

  String toJson() => json.encode(toMap());

  factory DiscoveredPrinter.fromJson(String source) =>
      DiscoveredPrinter.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'DiscoveredPrinter(address: $address, dnsName: $dnsName, port: $port)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DiscoveredPrinter && other.address == address;
  }

  @override
  int get hashCode => address.hashCode;
}

class DiscoveredPrinterUsb extends DiscoveredPrinter {
  final String deviceAddress;

  DiscoveredPrinterUsb({
    required this.deviceAddress,
    required super.address,
    super.dnsName,
  });

  factory DiscoveredPrinterUsb.fromMap(Map<String, dynamic> map) {
    return DiscoveredPrinterUsb(
      deviceAddress: map['address'] ?? '',
      address: map['address'] ?? '',
      dnsName: map['dnsName'] as String?,
    );
  }
}
