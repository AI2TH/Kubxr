package com.ai2th.kubxr

import android.app.Application
import android.util.Log

class KubxrApp : Application() {
    lateinit var vmManager: VmManager
        private set

    override fun onCreate() {
        super.onCreate()
        Log.d("KubxrApp", "Initializing Kubxr Node Application")
        vmManager = VmManager(this)
    }
}
