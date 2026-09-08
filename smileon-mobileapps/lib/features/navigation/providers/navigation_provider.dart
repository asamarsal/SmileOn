import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

/// Provider to manage the state of the Bottom Navigation Bar index
final navigationIndexProvider = StateProvider<int>((ref) => 0);
