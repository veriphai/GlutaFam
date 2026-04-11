package com.gluta.glutafam

import co.ab180.airbridge.flutter.AirbridgeFlutter
import android.app.Application
import android.util.Log

class MyApplication: Application() {
    override fun onCreate() {
        super.onCreate()
        
        // Initialize Airbridge SDK
        Log.i("MyApplication", "🚀 [Android] Initializing Airbridge SDK...")
        AirbridgeFlutter.initializeSDK(this, "superpadhai", "a3d282859f0240d5b82a00c9bc9c3a42")
        Log.i("MyApplication", "✅ [Android] Airbridge SDK initialized")
    }
}
