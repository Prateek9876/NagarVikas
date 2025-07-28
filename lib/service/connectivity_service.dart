import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  bool _isConnected = true;
  final List<Function(bool)> _listeners = [];

  bool get isConnected => _isConnected;

  Future<void> initialize() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _isConnected = result.any((r) => r != ConnectivityResult.none);

      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        (results) {
          final hasConnection =
              results.any((result) => result != ConnectivityResult.none);
          if (_isConnected != hasConnection) {
            _isConnected = hasConnection;
            for (final listener in _listeners) {
              try {
                listener(hasConnection);
              } catch (_) {}
            }
          }
        },
      );
    } catch (_) {}
  }

  void addListener(Function(bool) listener) => _listeners.add(listener);
  void removeListener(Function(bool) listener) => _listeners.remove(listener);
  void dispose() => _connectivitySubscription?.cancel();
}

class ConnectivityOverlay extends StatefulWidget {
  final Widget child;
  const ConnectivityOverlay({super.key, required this.child});

  @override
  State<ConnectivityOverlay> createState() => _ConnectivityOverlayState();
}

class _ConnectivityOverlayState extends State<ConnectivityOverlay>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ConnectivityService().addListener(_onConnectivityChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!ConnectivityService().isConnected) {
        _showNoConnectionSnackBar();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ConnectivityService().removeListener(_onConnectivityChanged);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!ConnectivityService().isConnected && mounted) {
          _showNoConnectionSnackBar();
        }
      });
    }
  }

  void _onConnectivityChanged(bool isConnected) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();

    if (!isConnected) {
      _showNoConnectionSnackBar();
    } else {
      _showConnectionRestoredSnackBar();
    }
  }

  void _showNoConnectionSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.wifi_off, color: Colors.white, size: 20),
            SizedBox(width: 12),
            Text('No internet connection'),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        duration: const Duration(days: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: SnackBarAction(
          label: 'Cancel',
          textColor: Colors.white,
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
  }

  void _showConnectionRestoredSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.wifi, color: Colors.white, size: 20),
            SizedBox(width: 12),
            Text('Internet connection restored'),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
