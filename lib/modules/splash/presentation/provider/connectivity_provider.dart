// import 'dart:async';
// import 'dart:io';
// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';

// final connectivityProvider =
//     StateNotifierProvider<ConnectivityNotifier, bool>((ref) {
//   return ConnectivityNotifier(ref);
// });

// class ConnectivityNotifier extends StateNotifier<bool> {
//   final Connectivity _connectivity = Connectivity();
//   StreamSubscription? _subscription;
//   final Ref ref;

//   ConnectivityNotifier(this.ref) : super(true) {
//     _monitorConnectivity();
//   }

//   void _monitorConnectivity() {
//     _subscription = _connectivity.onConnectivityChanged.listen(
//       (results) async {
//         try {
//           if (kDebugMode) {
//             print('Connectivity Results: $results (${results.runtimeType})');
//           }
//           final hasInternet = await _hasInternetConnection(results);
//           state = hasInternet;
//           if (kDebugMode) {
//             print('Internet connectivity status: $hasInternet');
//           }
//         } catch (e) {
//           if (kDebugMode) {
//             print('Error monitoring connectivity: $e');
//           }
//           state = false; // Assume no internet on error
//         }
//       },
//     );
//   }

//   Future<bool> _hasInternetConnection(ConnectivityResult result) async {
//     if (result == ConnectivityResult.none) {
//       return false;
//     }
//     try {
//       final lookupResult = await InternetAddress.lookup('google.com');
//       return lookupResult.isNotEmpty && lookupResult[0].rawAddress.isNotEmpty;
//     } catch (_) {
//       return false;
//     }
//   }

//   @override
//   void dispose() {
//     _subscription?.cancel();
//     super.dispose();
//   }
// }
