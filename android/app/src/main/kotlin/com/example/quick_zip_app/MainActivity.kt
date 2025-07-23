package com.example.quick_zip_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.launch
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlin.coroutines.CoroutineContext

class MainActivity : FlutterActivity(), CoroutineScope {
    private val CHANNEL = "com.example.quick_zip_app/archive"
    private val PROGRESS_CHANNEL = "com.example.quick_zip_app/progress"
    private val job = Job()
    private val _progressState = MutableStateFlow<Map<String, Any>?>(null)
    private var progressJob: Job? = null
    
    override val coroutineContext: CoroutineContext
        get() = Dispatchers.Main + job

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Set up progress event channel
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, PROGRESS_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                    progressJob = launch {
                        _progressState.asStateFlow().collect { progress ->
                            if (progress != null) {
                                events.success(progress)
                            }
                        }
                    }
                }

                override fun onCancel(arguments: Any?) {
                    progressJob?.cancel()
                    progressJob = null
                }
            }
        )

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "validatePassword" -> {
                    val zipFilePath = call.argument<String>("zipFilePath")
                    val password = call.argument<String>("password")

                    if (zipFilePath != null && password != null) {
                        launch {
                            ArchiveExtractor.validatePassword(zipFilePath, password, result)
                        }
                    } else {
                        result.error("INVALID_ARGUMENTS", "Zip file path or password is null", null)
                    }
                }
                "extractZip" -> {
                    val zipFilePath = call.argument<String>("zipFilePath")
                    val outputDirPath = call.argument<String>("outputDirPath")
                    val password = call.argument<String>("password")

                    if (zipFilePath != null && outputDirPath != null) {
                        launch {
                            ArchiveExtractor.extractZip(zipFilePath, outputDirPath, password, result, _progressState)
                        }
                    } else {
                        result.error("INVALID_ARGUMENTS", "Zip file path or output directory path is null", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        progressJob?.cancel()
        job.cancel()
    }
}