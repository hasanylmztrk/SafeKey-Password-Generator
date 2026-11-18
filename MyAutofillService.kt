package com.safekey.app

import android.app.assist.AssistStructure
import android.content.Context
import android.os.CancellationSignal
import android.service.autofill.*
import android.view.autofill.AutofillId
import android.view.autofill.AutofillValue
import android.widget.RemoteViews
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import org.json.JSONObject

class MyAutofillService : AutofillService() {

    override fun onFillRequest(request: FillRequest, cancellationSignal: CancellationSignal, callback: FillCallback) {
        val context = request.fillContexts.lastOrNull()?.structure ?: run { callback.onSuccess(null); return }
        val (userId, passId) = findFields(context)
        if (userId == null && passId == null) { callback.onSuccess(null); return }

        val prefs = try {
            val masterKey = MasterKey.Builder(this).setKeyScheme(MasterKey.KeyScheme.AES256_GCM).build()
            EncryptedSharedPreferences.create(this, "safekey_secure", masterKey,
                EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
                EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM)
        } catch (e: Exception) { callback.onSuccess(null); return }

        val data = JSONObject(prefs.getString("data", "{}") ?: "{}")
        val response = FillResponse.Builder()
        val keys = data.keys()
        while (keys.hasNext()) {
            val site = keys.next()
            val item = data.getJSONObject(site)
            val kullanici = item.optString("kullanici")
            val sifre = item.optString("sifre")

            val presentation = RemoteViews(packageName, android.R.layout.simple_list_item_2).apply {
                setTextViewText(android.R.id.text1, site)
                setTextViewText(android.R.id.text2, kullanici)
            }
            val dataset = Dataset.Builder(presentation)
            userId?.let { dataset.setValue(it, AutofillValue.forText(kullanici)) }
            passId?.let { dataset.setValue(it, AutofillValue.forText(sifre)) }
            response.addDataset(dataset.build())
        }
        callback.onSuccess(response.build())
    }

    override fun onSaveRequest(request: SaveRequest, callback: SaveCallback) { callback.onSuccess() }

    private fun findFields(structure: AssistStructure): Pair<AutofillId?, AutofillId?> {
        var userId: AutofillId? = null
        var passId: AutofillId? = null
        for (i in 0 until structure.windowNodeCount) {
            val pair = collect(structure.getWindowNodeAt(i).rootViewNode)
            if (pair.first != null) userId = pair.first
            if (pair.second != null) passId = pair.second
        }
        return Pair(userId, passId)
    }

    private fun collect(node: AssistStructure.ViewNode): Pair<AutofillId?, AutofillId?> {
        var userId: AutofillId? = null
        var passId: AutofillId? = null
        val hints = node.autofillHints ?: emptyArray()
        val hintStr = hints.joinToString(" ").lowercase()
        val idStr = (node.idEntry ?: "").lowercase()
        val combined = "$hintStr $idStr"
        if (combined.contains("password")) passId = node.autofillId
        else if (combined.contains("username") || combined.contains("email")) userId = node.autofillId

        for (i in 0 until node.childCount) {
            val child = collect(node.getChildAt(i))
            if (child.first != null) userId = child.first
            if (child.second != null) passId = child.second
        }
        return Pair(userId, passId)
    }
}
