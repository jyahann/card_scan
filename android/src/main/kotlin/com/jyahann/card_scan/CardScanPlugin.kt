package com.jyahann.card_scan

import android.app.Activity
import android.app.PendingIntent
import android.content.Intent
import android.content.IntentSender
import android.util.Log
import com.google.android.gms.wallet.*
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry.ActivityResultListener

class CardScanPlugin : FlutterPlugin, MethodChannel.MethodCallHandler, ActivityAware, ActivityResultListener {

    private lateinit var channel: MethodChannel
    private var activity: Activity? = null
    private var paymentsClient: PaymentsClient? = null
    private var cardRecognitionPendingIntent: PendingIntent? = null

    companion object {
        private const val TAG = "CardScanPlugin"
        private const val CARD_SCAN_REQUEST_CODE = 9912
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "jyahann:card_scan_channel")
        channel.setMethodCallHandler(this)
        Log.d(TAG, "Plugin attached to engine")
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        Log.d(TAG, "Plugin detached from engine")
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addActivityResultListener(this)
        Log.d(TAG, "Attached to activity: ${activity?.javaClass?.name}")
    }

    override fun onDetachedFromActivity() {
        Log.w(TAG, "Detached from activity")
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addActivityResultListener(this)
        Log.d(TAG, "Reattached to activity after config change: ${activity?.javaClass?.name}")
    }

    override fun onDetachedFromActivityForConfigChanges() {
        Log.w(TAG, "Detached from activity for config changes")
        activity = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "startScan" -> {
                    val isTest = call.argument<Boolean>("isTest") ?: true
                    Log.d(TAG, "startScan called (isTest=$isTest)")
                    startScan(isTest)
                    result.success(null)
                }
                else -> {
                    Log.w(TAG, "Method not implemented: ${call.method}")
                    result.notImplemented()
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Exception in onMethodCall", e)
            sendErrorEvent("Exception in onMethodCall: ${e.localizedMessage}")
            result.error("PLUGIN_ERROR", e.localizedMessage, null)
        }
    }

    private fun startScan(isTest: Boolean) {
        val act = activity
        if (act == null) {
            Log.e(TAG, "startScan failed: no activity")
            sendErrorEvent("Activity is null")
            return
        }

        try {
            paymentsClient = Wallet.getPaymentsClient(
                act,
                Wallet.WalletOptions.Builder()
                    .setEnvironment(
                        if (isTest) WalletConstants.ENVIRONMENT_TEST
                        else WalletConstants.ENVIRONMENT_PRODUCTION
                    )
                    .build()
            )

            val request = PaymentCardRecognitionIntentRequest.getDefaultInstance()
            paymentsClient!!.getPaymentCardRecognitionIntent(request)
                .addOnSuccessListener {
                    cardRecognitionPendingIntent = it.paymentCardRecognitionPendingIntent
                    Log.d(TAG, "Got PendingIntent, launching OCR")
                    launchOcr()
                }
                .addOnFailureListener { e ->
                    Log.e(TAG, "OCR not available", e)
                    sendErrorEvent("OCR not available: ${e.localizedMessage}")
                }
        } catch (e: Exception) {
            Log.e(TAG, "startScan exception", e)
            sendErrorEvent("startScan exception: ${e.localizedMessage}")
        }
    }

    private fun launchOcr() {
        val pendingIntent = cardRecognitionPendingIntent
        if (pendingIntent == null) {
            Log.e(TAG, "launchOcr failed: no PendingIntent")
            sendErrorEvent("launchOcr failed: no PendingIntent")
            return
        }
        try {
            activity?.startIntentSenderForResult(
                pendingIntent.intentSender,
                CARD_SCAN_REQUEST_CODE,
                null,
                0,
                0,
                0
            )
            Log.d(TAG, "launchOcr success: started intent sender")
        } catch (e: IntentSender.SendIntentException) {
            Log.e(TAG, "Failed to launch OCR", e)
            sendErrorEvent("Failed to launch OCR: ${e.localizedMessage}")
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode == CARD_SCAN_REQUEST_CODE) {
            Log.d(TAG, "onActivityResult: requestCode=$requestCode, resultCode=$resultCode")
            return try {
                if (resultCode == Activity.RESULT_OK && data != null) {
                    PaymentCardRecognitionResult.getFromIntent(data)?.let {
                        Log.d(TAG, "Card recognized: pan=${it.pan}, exp=${it.creditCardExpirationDate}")
                        handleResult(it)
                    } ?: run {
                        Log.w(TAG, "Recognition result is null")
                        sendCancelledEvent()
                    }
                } else if (resultCode == Activity.RESULT_CANCELED) {
                    Log.w(TAG, "User cancelled scan")
                    sendCancelledEvent()
                } else {
                    Log.e(TAG, "Unexpected resultCode: $resultCode")
                    sendErrorEvent("Unexpected resultCode: $resultCode")
                }
                true
            } catch (e: Exception) {
                Log.e(TAG, "Exception in onActivityResult", e)
                sendErrorEvent("onActivityResult exception: ${e.localizedMessage}")
                true
            }
        }
        return false
    }

    private fun handleResult(result: PaymentCardRecognitionResult) {
        try {
            val expDate = result.creditCardExpirationDate?.let {
                "%02d/%d".format(it.month, it.year)
            }

            val event: Map<String, Any?> = mapOf(
                "type" to "scanDataReceived",
                "data" to mapOf(
                    "cardNumber" to result.pan,
                    "expiryDate" to expDate,
                    "cardHolder" to null
                )
            )
            Log.d(TAG, "Sending scanDataReceived event to Flutter: $event")
            channel.invokeMethod("onEvent", event)
        } catch (e: Exception) {
            Log.e(TAG, "handleResult failed", e)
            sendErrorEvent("handleResult failed: ${e.localizedMessage}")
        }
    }

    private fun sendCancelledEvent() {
        val event: Map<String, Any?> = mapOf("type" to "scanCancelled")
        Log.d(TAG, "Sending scanCancelled event to Flutter")
        channel.invokeMethod("onEvent", event)
    }

    private fun sendErrorEvent(message: String) {
        val event: Map<String, Any?> = mapOf(
            "type" to "scanFailed",
            "error" to message
        )
        Log.e(TAG, "Sending scanFailed event to Flutter: $message")
        channel.invokeMethod("onEvent", event)
    }
}
