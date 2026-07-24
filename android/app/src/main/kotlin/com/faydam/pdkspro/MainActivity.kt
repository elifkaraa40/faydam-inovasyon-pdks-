package com.faydam.pdkspro

import android.Manifest
import android.app.Activity
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.ContentValues
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Environment
import android.provider.MediaStore
import android.provider.Settings
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val channelName = "com.faydam.pdkspro/files"
    private val storagePermissionRequest = 4107
    private var pendingSave: Pair<MethodCall, MethodChannel.Result>? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "faydam_updates",
                "Faydam PDKS bildirimleri",
                NotificationManager.IMPORTANCE_HIGH,
            ).apply {
                description = "İzin, puantaj, çalışma konumu ve hesap bildirimleri"
                enableVibration(true)
            }
            getSystemService(NotificationManager::class.java)
                .createNotificationChannel(channel)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "saveFile" -> saveFile(call, result)
                "openFile" -> openFile(call, result)
                "openNotificationSettings" -> openNotificationSettings(result)
                else -> result.notImplemented()
            }
        }
    }

    private fun openNotificationSettings(result: MethodChannel.Result) {
        try {
            val intent = Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).apply {
                putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
            }
            startActivity(intent)
            result.success(null)
        } catch (exception: Exception) {
            result.error("SETTINGS_OPEN_FAILED", "Bildirim ayarları açılamadı.", null)
        }
    }

    private fun saveFile(call: MethodCall, result: MethodChannel.Result) {
        if (
            Build.VERSION.SDK_INT < Build.VERSION_CODES.Q &&
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.M &&
            checkSelfPermission(Manifest.permission.WRITE_EXTERNAL_STORAGE) !=
            PackageManager.PERMISSION_GRANTED
        ) {
            pendingSave = call to result
            requestPermissions(
                arrayOf(Manifest.permission.WRITE_EXTERNAL_STORAGE),
                storagePermissionRequest,
            )
            return
        }
        saveFileWithPermission(call, result)
    }

    private fun saveFileWithPermission(
        call: MethodCall,
        result: MethodChannel.Result,
    ) {
        val bytes = call.argument<ByteArray>("bytes")
        val requestedFileName = call.argument<String>("fileName")
        val mimeType = call.argument<String>("mimeType")
        val subdirectory = sanitizeDirectory(
            call.argument<String>("subdirectory") ?: "Puantaj",
        )
        if (bytes == null || requestedFileName.isNullOrBlank() || mimeType.isNullOrBlank()) {
            result.error("INVALID_ARGUMENTS", "Dosya bilgileri eksik.", null)
            return
        }
        val fileName = sanitizeFileName(requestedFileName)

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                saveToMediaStore(bytes, fileName, mimeType, subdirectory, result)
            } else {
                saveToLegacyDownloads(bytes, fileName, mimeType, subdirectory, result)
            }
        } catch (error: Exception) {
            result.error("SAVE_FAILED", error.message ?: "Dosya kaydedilemedi.", null)
        }
    }

    private fun saveToMediaStore(
        bytes: ByteArray,
        fileName: String,
        mimeType: String,
        subdirectory: String,
        result: MethodChannel.Result,
    ) {
        val values = ContentValues().apply {
            put(MediaStore.Downloads.DISPLAY_NAME, fileName)
            put(MediaStore.Downloads.MIME_TYPE, mimeType)
            put(
                MediaStore.Downloads.RELATIVE_PATH,
                "${Environment.DIRECTORY_DOWNLOADS}/$subdirectory",
            )
            put(MediaStore.Downloads.IS_PENDING, 1)
        }
        val uri = contentResolver.insert(
            MediaStore.Downloads.EXTERNAL_CONTENT_URI,
            values,
        ) ?: throw IllegalStateException("Dosya için güvenli kayıt adresi oluşturulamadı.")

        try {
            contentResolver.openOutputStream(uri)?.use { stream ->
                stream.write(bytes)
                stream.flush()
            } ?: throw IllegalStateException("Dosya yazılamadı.")
            values.clear()
            values.put(MediaStore.Downloads.IS_PENDING, 0)
            contentResolver.update(uri, values, null, null)
            result.success(
                mapOf(
                    "fileName" to fileName,
                    "displayLocation" to "Downloads/$subdirectory",
                    "uri" to uri.toString(),
                ),
            )
        } catch (error: Exception) {
            contentResolver.delete(uri, null, null)
            throw error
        }
    }

    @Suppress("DEPRECATION")
    private fun saveToLegacyDownloads(
        bytes: ByteArray,
        fileName: String,
        mimeType: String,
        subdirectory: String,
        result: MethodChannel.Result,
    ) {
        val downloads = Environment.getExternalStoragePublicDirectory(
            Environment.DIRECTORY_DOWNLOADS,
        )
        val directory = File(downloads, subdirectory)
        if (!directory.exists() && !directory.mkdirs()) {
            throw IllegalStateException("Downloads/$subdirectory klasörü oluşturulamadı.")
        }
        val file = uniqueFile(directory, fileName)
        file.outputStream().use { stream ->
            stream.write(bytes)
            stream.flush()
        }
        val uri = FileProvider.getUriForFile(
            this,
            "$packageName.fileProvider",
            file,
        )
        result.success(
            mapOf(
                "fileName" to file.name,
                "displayLocation" to "Downloads/$subdirectory",
                "path" to file.absolutePath,
                "uri" to uri.toString(),
                "mimeType" to mimeType,
            ),
        )
    }

    private fun openFile(call: MethodCall, result: MethodChannel.Result) {
        val mimeType = call.argument<String>("mimeType") ?: "*/*"
        val uriValue = call.argument<String>("uri")
        val path = call.argument<String>("path")
        val uri = when {
            !uriValue.isNullOrBlank() -> Uri.parse(uriValue)
            !path.isNullOrBlank() -> FileProvider.getUriForFile(
                this,
                "$packageName.fileProvider",
                File(path),
            )
            else -> null
        }
        if (uri == null) {
            result.error("OPEN_FAILED", "Dosya adresi bulunamadı.", null)
            return
        }

        val intent = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(uri, mimeType)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        try {
            startActivity(intent)
            result.success(true)
        } catch (_: android.content.ActivityNotFoundException) {
            result.error(
                "NO_APPLICATION",
                "Bu dosyayı açabilecek bir uygulama bulunamadı.",
                null,
            )
        } catch (error: Exception) {
            result.error("OPEN_FAILED", error.message ?: "Dosya açılamadı.", null)
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != storagePermissionRequest) return
        val pending = pendingSave
        pendingSave = null
        if (pending == null) return
        if (grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED) {
            saveFileWithPermission(pending.first, pending.second)
        } else {
            pending.second.error(
                "PERMISSION_DENIED",
                "Dosyayı Downloads klasörüne kaydetme izni verilmedi.",
                null,
            )
        }
    }

    private fun sanitizeDirectory(value: String): String =
        value.replace(Regex("""[\\/:*?"<>|]"""), "_").trim().ifBlank { "Puantaj" }

    private fun sanitizeFileName(value: String): String =
        value.replace(Regex("""[\\/:*?"<>|]"""), "_").trim().ifBlank { "puantaj" }

    private fun uniqueFile(directory: File, fileName: String): File {
        var candidate = File(directory, fileName)
        if (!candidate.exists()) return candidate
        val dot = fileName.lastIndexOf('.')
        val base = if (dot > 0) fileName.substring(0, dot) else fileName
        val extension = if (dot > 0) fileName.substring(dot) else ""
        var suffix = 1
        while (candidate.exists()) {
            candidate = File(directory, "$base ($suffix)$extension")
            suffix++
        }
        return candidate
    }
}
