import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Optional wrapper around the whole app (above the router). Null in real
/// builds; demo mode overrides it to add the "Demo" pill.
final appOverlayProvider = Provider<TransitionBuilder?>((ref) => null);
