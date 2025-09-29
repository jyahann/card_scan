package com.example.card_scan

import android.app.Activity
import android.app.PendingIntent
import android.content.IntentSender
import android.util.Log
import androidx.activity.ComponentActivity
import androidx.activity.result.IntentSenderRequest
import androidx.activity.result.contract.ActivityResultContracts
import com.google.android.gms.wallet.*
import com.google.android.gms.wallet.cardrecognition.PaymentCardRecognitionIntentRequest
import com.google.android.gms.wallet.cardrecognition.PaymentCardRecognitionResult
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class CardScanPlugin : FlutterPlugin, MethodChannel.MethodCallHandler, ActivityAware {

    private lateinit var channel: MethodChannel
    private var activity: ComponentActivity? = null
    private var paymentsClient: PaymentsClient? = null
    private var cardRecognitionPendingIntent: PendingIntent? = null

    private val resultLauncher by lazy {
        activity?.registerForActivityResult(
            ActivityResultContracts.StartIntentSenderForResult()
        ) { result ->
            val resultCode = result.resultCode
            val data = result.data

            if (resultCode == Activity.RESULT_OK && data != null) {
                PaymentCardRecognitionResult.getFromIntent(data)?.let {
                    handleResult(it)
                    return@registerForActivityResult
                }
                // если null — значит пусто
                sendCancelledEvent()
            } else if (resultCode == Activity.RESULT_CANCELED) {
                sendCancelledEvent()
            } else {
                sendErrorEvent("Unexpected resultCode: $resultCode")
            }
        }
    }

    private fun sendCancelledEvent() {
        val event: Map<String, Any?> = mapOf(
            "type" to "scanCancelled"
        )
        channel.invokeMethod("onEvent", event)
    }

    private fun sendErrorEvent(message: String) {
        val event: Map<String, Any?> = mapOf(
            "type" to "scanFailed",
            "error" to message
        )
        channel.invokeMethod("onEvent", event)
    }


    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "jyahann:card_scan")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "startScan" -> {
                val isTest = call.argument<Boolean>("isTest") ?: true
                startScan(isTest)
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun startScan(isTest: Boolean) {
        val act = activity ?: return
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
                launchOcr()
            }
            .addOnFailureListener { e ->
                Log.e("CardScanPlugin", "OCR not available", e)
            }
    }


    private fun launchOcr() {
        val pendingIntent = cardRecognitionPendingIntent ?: return
        try {
            val request = IntentSenderRequest.Builder(pendingIntent.intentSender).build()
            resultLauncher?.launch(request)
        } catch (e: IntentSender.SendIntentException) {
            Log.e("CardScanPlugin", "Failed to launch OCR", e)
        }
    }

    private fun handleResult(result: PaymentCardRecognitionResult) {
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

        channel.invokeMethod("onEvent", event)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity as? ComponentActivity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity as? ComponentActivity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
