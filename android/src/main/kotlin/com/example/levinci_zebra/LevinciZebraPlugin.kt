package com.example.levinci_zebra

import androidx.annotation.NonNull
import android.content.Context

import com.zebra.sdk.printer.discovery.DiscoveredPrinter
import com.zebra.sdk.printer.discovery.DiscoveredPrinterNetwork
import com.zebra.sdk.printer.discovery.DiscoveryException
import com.zebra.sdk.printer.discovery.DiscoveryHandler
import com.zebra.sdk.printer.discovery.NetworkDiscoverer
import com.zebra.sdk.printer.discovery.UsbDiscoverer
import com.zebra.sdk.printer.discovery.DiscoveredPrinterUsb
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.util.concurrent.Executors

/** LevinciZebraPlugin */
class LevinciZebraPlugin : FlutterPlugin, MethodCallHandler {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel: MethodChannel
  private lateinit var applicationContext: Context

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "levinci_zebra")
    channel.setMethodCallHandler(this)
    applicationContext = flutterPluginBinding.applicationContext
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
      "getPlatformVersion" -> {
        result.success("Android ${android.os.Build.VERSION.RELEASE}")
      }

      "get_by_lan", "discover_by_lan", "discover_by_broadcast", "discover_by_hops" -> {
        val executor = Executors.newSingleThreadExecutor()
        executor.execute {
          val printers = mutableListOf<Map<String, Any>>()
          val handler = object : DiscoveryHandler {
            override fun foundPrinter(printer: DiscoveredPrinter) {
              val info = mutableMapOf<String, Any>()
              println("Found printer: ${printer.address} ${printer.discoveryDataMap}")

              val port = printer.discoveryDataMap["port"]
              if (port != null) {
                info["port"] = port.toInt()
              }
              info["dnsName"] = printer.discoveryDataMap["DNS_NAME"] ?: "Unknown"
              info["address"] = printer.address
              printers.add(info)
            }

            override fun discoveryFinished() {
              android.os.Handler(android.os.Looper.getMainLooper()).post {
                result.success(printers)
              }
            }

            override fun discoveryError(message: String) {
              android.os.Handler(android.os.Looper.getMainLooper()).post {
                result.error("DISCOVERY_ERROR", message, null)
              }
            }
          }
          try {
            when (call.method) {
              "get_by_lan" -> NetworkDiscoverer.findPrinters(handler)
              "discover_by_lan" -> NetworkDiscoverer.localBroadcast(handler)
              "discover_by_broadcast" -> NetworkDiscoverer.directedBroadcast(
                handler,
                "255.255.255.255"
              )

              "discover_by_hops" -> {
                val hops = call.argument<Int>("hops") ?: 1
                NetworkDiscoverer.multicast(handler, hops)
              }
            }
          } catch (e: DiscoveryException) {
            android.os.Handler(android.os.Looper.getMainLooper()).post {
              result.error("DISCOVERY_EXCEPTION", e.message, null)
            }
          }
        }
      }

      "discover_by_usb" -> {
        val executor = Executors.newSingleThreadExecutor()
        executor.execute {
          val printers = mutableListOf<Map<String, Any>>()
          val handler = object : DiscoveryHandler {
            override fun foundPrinter(printer: DiscoveredPrinter) {
              if (printer is DiscoveredPrinterUsb) {
                val info = mutableMapOf<String, Any>()
                val device = printer.device

                info["address"] = printer.address
                info["vendorId"] = device.vendorId
                info["productId"] = device.productId
                info["deviceName"] = device.deviceName
                info["serialNumber"] = device.serialNumber ?: ""
                info["manufacturerName"] = device.manufacturerName ?: ""
                info["deviceId"] = device.deviceId ?: 0
                info["deviceClass"] = device.deviceClass
                info["deviceProtocol"] = device.deviceProtocol
                info["deviceSubclass"] = device.deviceSubclass
                info["interfaceCount"] = device.interfaceCount
                info["dnsName"] = printer.discoveryDataMap["DNS_NAME"] ?: "Unknown"

                printers.add(info)
              }
            }

            override fun discoveryFinished() {
              android.os.Handler(android.os.Looper.getMainLooper()).post {
                result.success(printers)
              }
            }

            override fun discoveryError(message: String) {
              android.os.Handler(android.os.Looper.getMainLooper()).post {
                result.error("DISCOVERY_ERROR", message, null)
              }
            }
          }

          try {
            UsbDiscoverer.findPrinters(applicationContext, handler)
          } catch (e: Exception) {
            android.os.Handler(android.os.Looper.getMainLooper()).post {
              result.error("DISCOVERY_EXCEPTION", e.message, null)
            }
          }
        }
      }

      "send_command" -> {
        val ipAddress = call.argument<String>("ipAddress")
        val port = call.argument<Int>("port") ?: 9100
        val command = call.argument<String>("command")

        if (ipAddress == null || command == null) {
          result.error("INVALID_ARGUMENT", "IP address and command are required", null)
          return
        }

        val executor = Executors.newSingleThreadExecutor()
        executor.execute {
          try {
            val connection = com.zebra.sdk.comm.TcpConnection(ipAddress, port)
            try {
              connection.open()
              connection.write(command.toByteArray())
              android.os.Handler(android.os.Looper.getMainLooper()).post {
                result.success(null)
              }
            } catch (e: Exception) {
              android.os.Handler(android.os.Looper.getMainLooper()).post {
                result.error("CONNECTION_ERROR", "Error writing to printer: ${e.message}", null)
              }
            } finally {
              try {
                connection.close()
              } catch (e: Exception) {
                // Ignore close errors
              }
            }
          } catch (e: Exception) {
            android.os.Handler(android.os.Looper.getMainLooper()).post {
              result.error("CONNECTION_ERROR", "Error connecting to printer: ${e.message}", null)
            }
          }
        }
      }

      "send_command_usb" -> {
        val deviceAddress = call.argument<String>("deviceAddress")
        val command = call.argument<String>("command")

        if (deviceAddress == null || command == null) {
          result.error("INVALID_ARGUMENT", "Thiếu thông tin: deviceAddress và command là bắt buộc", null)
          return
        }

        val executor = Executors.newSingleThreadExecutor()
        executor.execute {
          try {
            // Tìm máy in USB trước
            val usbPrinters = mutableListOf<DiscoveredPrinterUsb>()
            val discoveryHandler = object : DiscoveryHandler {
              override fun foundPrinter(printer: DiscoveredPrinter) {
                if (printer is DiscoveredPrinterUsb) {
                  if (printer.address == deviceAddress) {
                    usbPrinters.add(printer)
                  }
                }
              }

              override fun discoveryFinished() {
                // Xử lý sau khi tìm kiếm hoàn tất
                if (usbPrinters.isEmpty()) {
                  android.os.Handler(android.os.Looper.getMainLooper()).post {
                    result.error("PRINTER_NOT_FOUND", "Không tìm thấy máy in với địa chỉ $deviceAddress", null)
                  }
                  return
                }

                // Lấy máy in đầu tiên tìm thấy
                val printer = usbPrinters.first()
                try {
                  // Tạo kết nối và gửi lệnh
                  val connection = printer.getConnection()
                  try {
                    connection.open()
                    connection.write(command.toByteArray())
                    android.os.Handler(android.os.Looper.getMainLooper()).post {
                      result.success(null)
                    }
                  } catch (e: Exception) {
                    android.os.Handler(android.os.Looper.getMainLooper()).post {
                      result.error("CONNECTION_ERROR", "Lỗi khi gửi lệnh đến máy in: ${e.message}", null)
                    }
                  } finally {
                    try {
                      connection.close()
                    } catch (e: Exception) {
                      // Bỏ qua lỗi đóng kết nối
                    }
                  }
                } catch (e: Exception) {
                  android.os.Handler(android.os.Looper.getMainLooper()).post {
                    result.error("CONNECTION_ERROR", "Lỗi khi kết nối với máy in: ${e.message}", null)
                  }
                }
              }

              override fun discoveryError(message: String) {
                android.os.Handler(android.os.Looper.getMainLooper()).post {
                  result.error("DISCOVERY_ERROR", message, null)
                }
              }
            }

            // Tìm kiếm máy in USB
            UsbDiscoverer.findPrinters(applicationContext, discoveryHandler)
          } catch (e: Exception) {
            android.os.Handler(android.os.Looper.getMainLooper()).post {
              result.error("UNEXPECTED_ERROR", "Lỗi không xác định: ${e.message}", null)
            }
          }
        }
      }

      else -> {
        result.notImplemented()
      }
    }
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }
}
