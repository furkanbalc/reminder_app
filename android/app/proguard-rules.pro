# flutter_local_notifications: zamanlanmış bildirimler GSON ile serileştirilir, sınıflar korunmalı.
-keep class com.dexterous.** { *; }
-keep class com.google.gson.** { *; }
-keepattributes Signature, *Annotation*, EnclosingMethod, InnerClasses
# Uygulama içi widget sağlayıcısı ve alarm alıcıları manifestten yansımayla yüklenir.
-keep class com.furkanbalci.su_hatirlatici.** { *; }
-keep class es.antonborri.home_widget.** { *; }
