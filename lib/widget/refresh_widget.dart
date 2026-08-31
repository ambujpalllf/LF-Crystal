import 'package:flutter/material.dart';

class RefreshIcon extends StatefulWidget {
  final bool isSyncing;
  final Color? icColor;
  const RefreshIcon({super.key, required this.isSyncing, this.icColor});

  @override
  RefreshIconState createState() => RefreshIconState();
}

class RefreshIconState extends State<RefreshIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
  }

  @override
  void didUpdateWidget(RefreshIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSyncing) {
      _controller.repeat();
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.isSyncing
        ? RotationTransition(
          turns: _controller,
          child: Icon(Icons.refresh, color: widget.icColor ?? Colors.black),
        )
        : Icon(Icons.refresh, color: widget.icColor ?? Colors.black);
  }
}
