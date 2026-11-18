package com.safekey.app

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.SharedPreferences
import android.os.Bundle
import android.widget.*
import androidx.appcompat.app.AppCompatActivity
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import org.json.JSONObject

class MainActivity : AppCompatActivity() {
    private lateinit var prefs: SharedPreferences
    private lateinit var siteInput: EditText
    private lateinit var userInput: EditText
    private lateinit var passInput: EditText
    private lateinit var listLayout: LinearLayout
    private lateinit var durumText: TextView

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        // EN GÜVENLİ SAKLAMA: Şifreli SharedPreferences
        val masterKey = MasterKey.Builder(this)
            .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
            .build()
        prefs = EncryptedSharedPreferences.create(
            this, "safekey_secure", masterKey,
            EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
            EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
        )

        siteInput = findViewById(R.id.siteInput)
        userInput = findViewById(R.id.userInput)
        passInput = findViewById(R.id.passInput)
        listLayout = findViewById(R.id.listLayout)
        durumText = findViewById(R.id.durumText)

        findViewById<Button>(R.id.ekleBtn).setOnClickListener { ekle() }
        listele()
    }

    private fun ekle() {
        val site = siteInput.text.toString().trim().lowercase()
        val user = userInput.text.toString().trim()
        val pass = passInput.text.toString().trim()
        if (site.isEmpty() || pass.isEmpty()) {
            Toast.makeText(this, "Site ve şifre boş olamaz!", Toast.LENGTH_SHORT).show()
            return
        }
        val obj = JSONObject(prefs.getString("data", "{}") ?: "{}")
        val item = JSONObject()
        item.put("kullanici", user)
        item.put("sifre", pass)
        obj.put(site, item)
        prefs.edit().putString("data", obj.toString()).apply()
        siteInput.setText(""); userInput.setText(""); passInput.setText("")
        Toast.makeText(this, "Şifreli olarak kaydedildi!", Toast.LENGTH_SHORT).show()
        listele()
    }

    private fun listele() {
        listLayout.removeAllViews()
        val obj = JSONObject(prefs.getString("data", "{}") ?: "{}")
        durumText.text = "Kayıtlı şifre: ${obj.length()}  •  Otomatik doldurma aktif"
        val keys = obj.keys()
        while (keys.hasNext()) {
            val site = keys.next()
            val item = obj.getJSONObject(site)
            val kullanici = item.optString("kullanici")
            val sifre = item.optString("sifre")

            val kutu = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL; setPadding(24, 24, 24, 24) }
            kutu.addView(TextView(this).apply { text = site.uppercase(); textSize = 18f; setTypeface(null, android.graphics.Typeface.BOLD) })
            kutu.addView(TextView(this).apply { text = "Kullanıcı: $kullanici" })
            kutu.addView(TextView(this).apply { text = "Şifre: ••••••••" })

            val btnRow = LinearLayout(this).apply { orientation = LinearLayout.HORIZONTAL }
            val kopyala = Button(this).apply { text = "Kopyala" }
            kopyala.setOnClickListener {
                val cm = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
                cm.setPrimaryClip(ClipData.newPlainText("sifre", sifre))
                Toast.makeText(this, "Kopyalandı!", Toast.LENGTH_SHORT).show()
            }
            val sil = Button(this).apply { text = "Sil" }
            sil.setOnClickListener {
                obj.remove(site)
                prefs.edit().putString("data", obj.toString()).apply()
                listele()
            }
            btnRow.addView(kopyala); btnRow.addView(sil)
            kutu.addView(btnRow)
            listLayout.addView(kutu)
        }
    }
}
