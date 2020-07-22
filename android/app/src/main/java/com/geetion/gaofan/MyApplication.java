package com.geetion.gaofan;

import io.flutter.app.FlutterApplication;
import com.tencent.bugly.crashreport.CrashReport;

public class MyApplication extends FlutterApplication {
    @Override
    public void onCreate() {
        super.onCreate();
        CrashReport.initCrashReport(getApplicationContext(), "aacc8396b2", true);
    }
}
