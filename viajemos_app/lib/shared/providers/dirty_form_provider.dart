import 'package:flutter_riverpod/flutter_riverpod.dart';

/// True when a form screen has unsaved user data.
/// Set to true by form screens when the user starts entering data.
/// Set back to false on publish, discard, or dispose.
final dirtyFormProvider = StateProvider<bool>((ref) => false);
