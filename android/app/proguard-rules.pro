# kotlinx.serialization keeps generated serializers; keep our @Serializable models.
-keepclassmembers class com.tapasya.mood.data.** {
    *** Companion;
}
-keepclasseswithmembers class com.tapasya.mood.data.** {
    kotlinx.serialization.KSerializer serializer(...);
}
