# 페이지에서 window.Native로 부르는 메서드는 이름이 바뀌면 안 된다
-keepclassmembers class com.ohsang.util.thousandcranes.MainActivity$Bridge {
    @android.webkit.JavascriptInterface <methods>;
}
-keepattributes JavascriptInterface
