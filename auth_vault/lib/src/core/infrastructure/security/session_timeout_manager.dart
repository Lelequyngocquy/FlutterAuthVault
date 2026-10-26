import 'dart:async';
import 'package:flutter/material.dart';

class SessionTimeoutManager extends StatefulWidget {
  final Widget child;
  final Duration timeoutDuration;
  final VoidCallback onTimeout;
  const SessionTimeoutManager({
    super.key,
    required this.child,
    this.timeoutDuration = const Duration(seconds: 120),
    required this.onTimeout,
  });
  @override
  State<SessionTimeoutManager> createState() => _SessionTimeoutManagerState();
}

class _SessionTimeoutManagerState extends State<SessionTimeoutManager> {
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    _startTimer();
  }
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer(widget.timeoutDuration, widget.onTimeout);
  }
  void _onUserInteraction([_]) {
    _startTimer();
  }
  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _onUserInteraction,
      onPointerMove: _onUserInteraction,
      child: widget.child,
    );
  }
}
