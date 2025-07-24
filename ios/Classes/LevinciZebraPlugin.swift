import Flutter
import UIKit

public class LevinciZebraPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "levinci_zebra", binaryMessenger: registrar.messenger())
    let instance = LevinciZebraPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  // MARK: - Discover Methods
  // Helper để serialize DiscoveredPrinterNetwork thành dictionary
  func serializePrinter(_ printer: DiscoveredPrinterNetwork) -> [String: Any] {
    return [
      "address": printer.address,
      "dnsName": printer.dnsName,
      "port": printer.port,
    ]
  }

  func discoverPrintersByLan() -> [[String: Any]] {
    print("[DEBUG] discoverPrintersByLan called")
    var error: NSError?
    let printers =
      NetworkDiscovererWrapper.discoverByLanWithError(&error) as? [DiscoveredPrinterNetwork] ?? []
    if let err = error {
      print("[DEBUG] Error in discoverPrintersByLan: \(err.localizedDescription)")
      return []
    }
    let result = printers.map { serializePrinter($0) }
    print("[DEBUG] Printers by LAN: \(result)")
    return result
  }

  func discoverPrintersByBroadcast() -> [[String: Any]] {
    print("[DEBUG] discoverPrintersByBroadcast called")
    var error: NSError?
    let printers =
      NetworkDiscovererWrapper.discoverByBroadcastWithError(&error) as? [DiscoveredPrinterNetwork]
      ?? []
    if let err = error {
      print("[DEBUG] Error in discoverPrintersByBroadcast: \(err.localizedDescription)")
      return []
    }
    let result = printers.map { serializePrinter($0) }
    print("[DEBUG] Printers by Broadcast: \(result)")
    return result
  }

  func discoverPrintersByHops(hops: Int) -> [[String: Any]] {
    print("[DEBUG] discoverPrintersByHops called with hops = \(hops)")
    var error: NSError?
    let printers =
      NetworkDiscovererWrapper.discover(byHops: NSNumber(value: hops), error: &error)
      as? [DiscoveredPrinterNetwork] ?? []
    if let err = error {
      print("[DEBUG] Error in discoverPrintersByHops: \(err.localizedDescription)")
      return []
    }
    let result = printers.map { serializePrinter($0) }
    print("[DEBUG] Printers by Hops: \(result)")
    return result
  }

  func sendCommand(
    ipAddress: String,
    port: Int,
    command: String,
    result: @escaping FlutterResult
  ) {
    guard let connection = TcpPrinterConnection(address: ipAddress, andWithPort: port) else {
      result(
        FlutterError(
          code: "FAILED_TO_CREATE_CONNECTION",
          message: "Could not create connection to Zebra printer",
          details: nil
        )
      )
      return
    }
    var error: NSError?

    let opened = connection.open()
    if !opened {
      result(
        FlutterError(
          code: "FAILED_TO_OPEN_CONNECTION",
          message: "Could not open connection to Zebra printer",
          details: nil
        )
      )
      return
    }

    do {
      guard let printer = try ZebraPrinterFactory.getInstance(connection) as? ZebraPrinter else {
        result(
          FlutterError(
            code: "FAILED_TO_GET_PRINTER",
            message: "Unknown error",
            details: nil
          )
        )
        connection.close()
        return
      }
      let _ = printer.getControlLanguage()
      let data = command.data(using: .utf8)!
      connection.write(data, error: &error)

      if let err = error {
        result(
          FlutterError(
            code: "FAILED_TO_SEND_COMMAND",
            message: err.localizedDescription,
            details: nil
          )
        )
        connection.close()
        return
      }

      connection.close()
      result(true)
    } catch {
      result(
        FlutterError(
          code: "FAILED_TO_GET_PRINTER",
          message: error.localizedDescription,
          details: nil
        )
      )
      connection.close()
      return
    }
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    print(
      "[DEBUG] handle called with method: \(call.method), arguments: \(String(describing: call.arguments))"
    )
    switch call.method {
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)
      break
    case "get_by_lan":
      guard let args = call.arguments as? [String: Any] else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Expected arguments", details: nil))
        return
      }

      let hops = args["hops"] as? Int
      var error: NSError?

      let printers: [[String: Any]]

      if let hops = hops {
        printers =
          NetworkDiscovererWrapper.discover(withHops: NSNumber(value: hops), error: &error)
          as? [[String: Any]] ?? []
      } else {
        printers =
          NetworkDiscovererWrapper.localBroadcastWithError(&error) as? [[String: Any]] ?? []
      }

      if let err = error {
        print("Error: \(err.localizedDescription)")
        result(
          FlutterError(code: "DISCOVERY_ERROR", message: err.localizedDescription, details: nil))
      } else {
        print("Printers: \(printers)")
        result(printers)
      }

      break
    case "discover_by_lan":
      let printers = discoverPrintersByLan()
      print("[DEBUG] Result discover_by_lan: \(printers)")
      result(printers)
    case "discover_by_broadcast":
      let printers = discoverPrintersByBroadcast()
      print("[DEBUG] Result discover_by_broadcast: \(printers)")
      result(printers)
    case "discover_by_hops":
      guard let args = call.arguments as? [String: Any],
        let hops = args["hops"] as? Int
      else {
        result(
          FlutterError(code: "INVALID_ARGUMENTS", message: "Expected hops argument", details: nil))
        return
      }
      let printers = discoverPrintersByHops(hops: hops)
      print("[DEBUG] Result discover_by_hops: \(printers)")
      result(printers)
    case "send_command":
      guard let args = call.arguments as? [String: Any],
        let ipAddress = args["ipAddress"] as? String,
        let port = args["port"] as? Int,
        let command = args["command"] as? String
      else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Expected arguments", details: nil))
        return
      }
      sendCommand(ipAddress: ipAddress, port: port, command: command, result: result)
      break
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
