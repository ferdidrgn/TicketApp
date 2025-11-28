// lib/core/providers/animations_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

final animationsReadyProvider = StateProvider<bool>((ref) => false);
