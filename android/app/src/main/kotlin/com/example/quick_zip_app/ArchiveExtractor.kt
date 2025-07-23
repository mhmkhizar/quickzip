package com.example.quick_zip_app

import android.util.Log
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import net.lingala.zip4j.ZipFile
import net.lingala.zip4j.exception.ZipException
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.flow.MutableStateFlow
import java.io.File

class ArchiveExtractor {
    companion object {
        private fun validateZipPassword(zipFile: ZipFile, password: String?): Boolean {
            if (!zipFile.isEncrypted) return true
            if (password == null) return false
            
            try {
                zipFile.setPassword(password.toCharArray())
                // Try to read the first entry to validate password
                val inputStream = zipFile.getInputStream(zipFile.fileHeaders.first())
                val buffer = ByteArray(1024)
                inputStream.read(buffer)
                inputStream.close()
                return true
            } catch (e: ZipException) {
                Log.e("ArchiveExtractor", "Password validation failed: ${e.message}")
                return false
            } catch (e: Exception) {
                Log.e("ArchiveExtractor", "Error during validation: ${e.message}")
                return false
            }
        }

        suspend fun validatePassword(zipFilePath: String, password: String, result: MethodChannel.Result) {
            try {
                withContext(Dispatchers.IO) {
                    val zipFile = ZipFile(zipFilePath)
                    
                    try {
                        if (!zipFile.isEncrypted) {
                            withContext(Dispatchers.Main) {
                                result.error("NOT_ENCRYPTED", "File is not password protected", null)
                            }
                            return@withContext
                        }

                        val isValid = validateZipPassword(zipFile, password)
                        
                        withContext(Dispatchers.Main) {
                            if (isValid) {
                                result.success(true)
                            } else {
                                result.error("WRONG_PASSWORD", "Incorrect password", null)
                            }
                        }
                    } finally {
                        try {
                            zipFile.close()
                        } catch (e: Exception) {
                            Log.e("ArchiveExtractor", "Error closing zip file", e)
                        }
                    }
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    result.error("VALIDATION_ERROR", "Error validating password: ${e.message}", null)
                }
            }
        }

        suspend fun extractZip(
            zipFilePath: String,
            outputDirPath: String,
            password: String?,
            result: MethodChannel.Result,
            progressState: MutableStateFlow<Map<String, Any>?>
        ) {
            try {
                withContext(Dispatchers.IO) {
                    val zipFile = ZipFile(zipFilePath)
                    
                    try {
                        // Initialize progress to 0
                        withContext(Dispatchers.Main) {
                            progressState.value = mapOf(
                                "progress" to 0.0,
                                "status" to "Starting extraction..."
                            )
                        }

                        if (zipFile.isEncrypted) {
                            if (password == null) {
                                withContext(Dispatchers.Main) {
                                    result.error("PASSWORD_REQUIRED", "Password is required for this file", null)
                                }
                                return@withContext
                            }

                            // Validate password before extraction
                            if (!validateZipPassword(zipFile, password)) {
                                withContext(Dispatchers.Main) {
                                    result.error("WRONG_PASSWORD", "Incorrect password", null)
                                }
                                return@withContext
                            }
                        }

                        // Calculate total uncompressed size
                        var totalSize: Long = 0
                        for (fileHeader in zipFile.fileHeaders) {
                            totalSize += fileHeader.uncompressedSize
                        }

                        // Create output directory if it doesn't exist
                        val outputDir = File(outputDirPath)
                        if (!outputDir.exists()) {
                            outputDir.mkdirs()
                        }

                        var processedSize: Long = 0
                        val totalFiles = zipFile.fileHeaders.size
                        var processedFiles = 0

                        // Extract all files with progress tracking
                        for (fileHeader in zipFile.fileHeaders) {
                            val fileName = fileHeader.fileName
                            val file = File(outputDir, fileName)
                            
                            // Create parent directories if they don't exist
                            val parentFile = file.parentFile
                            if (parentFile != null && !parentFile.exists()) {
                                parentFile.mkdirs()
                            }

                            // Update progress before starting file extraction
                            withContext(Dispatchers.Main) {
                                progressState.value = mapOf(
                                    "progress" to (processedFiles.toDouble() / totalFiles.toDouble() * 100.0),
                                    "currentFile" to fileName,
                                    "totalFiles" to totalFiles,
                                    "processedFiles" to processedFiles
                                )
                            }

                            // If it's a directory, just create it
                            if (fileHeader.isDirectory) {
                                if (!file.exists()) {
                                    file.mkdirs()
                                }
                                processedFiles++
                                continue
                            }

                            // Extract the file with progress tracking
                            val inputStream = zipFile.getInputStream(fileHeader)
                            val outputStream = file.outputStream()
                            
                            val buffer = ByteArray(8192) // 8KB buffer
                            var bytesRead: Int
                            var fileProcessedSize: Long = 0
                            
                            while (inputStream.read(buffer).also { bytesRead = it } != -1) {
                                outputStream.write(buffer, 0, bytesRead)
                                fileProcessedSize += bytesRead
                                processedSize += bytesRead
                                
                                // Calculate and update progress
                                val progress = (processedSize.toDouble() / totalSize.toDouble()) * 100.0
                                
                                // Ensure progress doesn't exceed 99% until fully complete
                                val safeProgress = if (processedFiles < totalFiles - 1) {
                                    minOf(progress, 99.0)
                                } else {
                                    minOf(progress, 100.0)
                                }
                                
                                // Send progress update
                                withContext(Dispatchers.Main) {
                                    progressState.value = mapOf(
                                        "progress" to safeProgress,
                                        "currentFile" to fileName,
                                        "totalFiles" to totalFiles,
                                        "processedFiles" to processedFiles
                                    )
                                }
                            }
                            
                            inputStream.close()
                            outputStream.close()
                            processedFiles++
                        }

                        Log.d("ArchiveExtractor", "Extraction completed successfully")
                        
                        // Send final progress update
                        withContext(Dispatchers.Main) {
                            progressState.value = mapOf(
                                "progress" to 100.0,
                                "status" to "Extraction completed",
                                "currentFile" to "",
                                "totalFiles" to totalFiles,
                                "processedFiles" to totalFiles
                            )
                            result.success("Extraction completed")
                        }
                    } finally {
                        try {
                            zipFile.close()
                        } catch (e: Exception) {
                            Log.e("ArchiveExtractor", "Error closing zip file", e)
                        }
                    }
                }
            } catch (e: Exception) {
                Log.e("ArchiveExtractor", "Error extracting zip file", e)
                withContext(Dispatchers.Main) {
                    when {
                        e is ZipException && e.message?.contains("Wrong Password", ignoreCase = true) == true ->
                            result.error("WRONG_PASSWORD", "Incorrect password", null)
                        else ->
                            result.error("EXTRACTION_FAILED", e.message, null)
                    }
                }
            }
        }
    }
}