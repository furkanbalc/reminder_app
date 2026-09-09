import 'package:flutter/foundation.dart';

/// Geliştirici araçları: debug derlemede ya da `--dart-define=DEV=true` ile açık.
/// Release derlemelerde (mağaza/telefon kurulumu) kapalıdır.
const bool kDevTools = kDebugMode || bool.fromEnvironment('DEV');
