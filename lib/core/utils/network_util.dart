import 'dart:io';
// ignore: depend_on_referenced_packages
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class NetworkUtil {
  /// Checks both network connectivity and actual internet access
  static Future<bool> checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3)); // DNS lookup timeout
      if (result.isEmpty || result[0].rawAddress.isEmpty) {
        return false;
      }

      final httpClient = HttpClient();
      final request = await httpClient
          .getUrl(Uri.parse('https://speed.cloudflare.com/__down?bytes=200000'))
          .timeout(const Duration(seconds: 3)); // URL connection timeout
      request.followRedirects = false;

      final response =
          await request.close().timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final bytes = await consolidateHttpClientResponseBytes(
          response,
          autoUncompress: true,
          onBytesReceived: (cumulative, total) {
            if (cumulative > 200 * 1024) {
              httpClient.close(force: true);
            }
          },
        ).timeout(const Duration(seconds: 6)); // Total download timeout

        return bytes.length > 100 * 1024;
      }

      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Internet check failed: $e');
      }
      return false;
    }
  }

  /// Stream to monitor connectivity changes
  static Stream<bool> onConnectivityChanged() {
    return Connectivity().onConnectivityChanged.asyncMap((result) async {
      if (kDebugMode) {
        print('Connectivity changed: ${result.name}');
      }

      if (result == ConnectivityResult.none) {
        return false;
      }

      // Add a longer delay before checking internet access to allow network to stabilize
      await Future.delayed(const Duration(seconds: 2));

      // Verify actual internet access
      return await checkInternetConnection();
    });
  }

  /// Get the current connection type as a string
  static Future<String> getConnectionType() async {
    try {
      final result = await Connectivity().checkConnectivity();
      switch (result) {
        case ConnectivityResult.wifi:
          return 'WiFi';
        case ConnectivityResult.mobile:
          return 'Mobile Data';
        case ConnectivityResult.ethernet:
          return 'Ethernet';
        case ConnectivityResult.vpn:
          return 'VPN';
        case ConnectivityResult.bluetooth:
          return 'Bluetooth';
        case ConnectivityResult.other:
          return 'Other';
        case ConnectivityResult.none:
          return 'No Connection';
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting connection type: $e');
      }
      return 'Unknown';
    }
  }
}
