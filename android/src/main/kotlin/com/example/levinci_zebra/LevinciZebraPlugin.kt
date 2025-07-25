package com.example.levinci_zebra

import androidx.annotation.NonNull

import com.zebra.sdk.printer.discovery.DiscoveredPrinter
import com.zebra.sdk.printer.discovery.DiscoveryException
import com.zebra.sdk.printer.discovery.DiscoveryHandler
import com.zebra.sdk.printer.discovery.NetworkDiscoverer
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

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "levinci_zebra")
    channel.setMethodCallHandler(this)
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
              info["dnsName"] = printer.discoveryDataMap["dnsName"] ?: "Unknown"
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

      "send_command" -> {
        val ipAddress = call.argument<String>("ipAddress")
        val port = call.argument<Int>("port") ?: 9100
        val command = call.argument<String>("command")
        val executor = Executors.newSingleThreadExecutor()
        executor.execute {
          try {
            val connection = com.zebra.sdk.comm.TcpConnection(ipAddress, port)
            try {
              connection.open()
              connection.write(command?.toByteArray() ?: ByteArray(0))
              android.os.Handler(android.os.Looper.getMainLooper()).post {
                result.success(null)
              }
            } catch (e: com.zebra.sdk.comm.ConnectionException) {
              android.os.Handler(android.os.Looper.getMainLooper()).post {
                result.error("CONNECTION_ERROR", e.message, null)
              }
            } finally {
              try {
                connection.close()
              } catch (_: Exception) {
              }
            }
          } catch (e: Exception) {
            android.os.Handler(android.os.Looper.getMainLooper()).post {
              result.error("SEND_COMMAND_ERROR", e.message, null)
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
