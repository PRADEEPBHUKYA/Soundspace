package com.example.soundspace

import android.content.Context
import android.content.pm.PackageManager

object ShizukuHelper {
    private const val PKG = "moe.shizuku.privileged.api"

    fun isInstalled(ctx: Context) = try { ctx.packageManager.getPackageInfo(PKG, 0); true } catch (_: Exception) { false }

    fun isRunning() = try {
        Class.forName("rikka.shizuku.Shizuku").getMethod("pingBinder").invoke(null) as? Boolean ?: false
    } catch (_: Exception) { false }

    fun checkPermission(code: Int) = try {
        val C = Class.forName("rikka.shizuku.Shizuku")
        if (C.getMethod("isPreV11").invoke(null) as? Boolean == true) return false
        if (C.getMethod("checkSelfPermission").invoke(null) as? Int == PackageManager.PERMISSION_GRANTED) true
        else { C.getMethod("requestPermission", Int::class.java).invoke(null, code); false }
    } catch (_: Exception) { false }
}
