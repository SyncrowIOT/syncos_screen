import 'package:flutter/material.dart';

/// Gates [child] behind a startup authentication check. Shows a loading
/// indicator while [ensureAuthenticated] is pending, [child] once it
/// resolves true, or a minimal retry screen if it resolves false.
class AuthGate extends StatefulWidget {
  const AuthGate({
    required this.ensureAuthenticated,
    required this.child,
    super.key,
  });

  final Future<bool> Function() ensureAuthenticated;
  final Widget child;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late Future<bool> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.ensureAuthenticated();
  }

  void _retry() {
    setState(() {
      _future = widget.ensureAuthenticated();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.data == true) {
          return widget.child;
        }
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Unable to sign in'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _retry,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
