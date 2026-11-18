import 'package:flutter/widgets.dart';

/// Fires [onShown] once, after the first frame (screen-view events).
class TrackOnce extends StatefulWidget {
  const TrackOnce({super.key, required this.onShown, required this.child});
  final VoidCallback onShown;
  final Widget child;

  @override
  State<TrackOnce> createState() => _TrackOnceState();
}

class _TrackOnceState extends State<TrackOnce> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onShown();
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
