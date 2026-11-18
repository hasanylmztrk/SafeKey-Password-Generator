import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() => runApp(const SafeKeyApp());

class SafeKeyApp extends StatelessWidget {
  const SafeKeyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SafeKey',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const AnaSayfa(),
    );
  }
}

class AnaSayfa extends StatefulWidget {
  const AnaSayfa({super.key});
  @override
  State<AnaSayfa> createState() => _AnaSayfaState();
}

class _AnaSayfaState extends State<AnaSayfa> {
  final storage = const FlutterSecureStorage();
  final siteCtrl = TextEditingController();
  final userCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  Map<String, dynamic> veriler = {};
  bool sifreGizli = true;

  @override
  void initState() {
    super.initState();
    yukle();
    // OTOMATIK DOLDURMA: Site yazildikca dinle
    siteCtrl.addListener(() {
      final site = siteCtrl.text.trim().toLowerCase();
      if (site.isEmpty) return;
      final item = veriler[site];
      if (item != null) {
        // Eger kullanici zaten elle bir sey yazmadiysa doldur
        // veya direkt doldur, cunku site eslesti
        userCtrl.text = item['kullanici'] ?? '';
        passCtrl.text = item['sifre'] ?? '';
      }
    });
  }

  @override
  void dispose() {
    siteCtrl.dispose();
    userCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

  Future<void> yukle() async {
    final jsonStr = await storage.read(key: 'safekey_data');
    if (jsonStr != null) {
      setState(() => veriler = jsonDecode(jsonStr));
    }
  }

  Future<void> kaydet() async {
    await storage.write(key: 'safekey_data', value: jsonEncode(veriler));
  }

  void ekle() async {
    final site = siteCtrl.text.trim().toLowerCase();
    final user = userCtrl.text.trim();
    final pass = passCtrl.text.trim();
    if (site.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Site ve şifre boş olamaz!')));
      return;
    }
    setState(() {
      veriler[site] = {'kullanici': user, 'sifre': pass};
      siteCtrl.clear(); userCtrl.clear(); passCtrl.clear();
    });
    await kaydet();
    // OTOMATIK DOLDURMA: Sisteme "kayit bitti" de, Android/iOS kaydetmeyi teklif etsin
    TextInput.finishAutofillContext();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$site kaydedildi! ✅')));
  }

  void sil(String site) async {
    setState(() => veriler.remove(site));
    await kaydet();
  }

  void kopyala(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Kopyalandı!')));
  }

  void doldur(String site) {
    final item = veriler[site];
    if (item == null) return;
    setState(() {
      siteCtrl.text = site;
      userCtrl.text = item['kullanici'] ?? '';
      passCtrl.text = item['sifre'] ?? '';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$site dolduruldu!')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SafeKey 🔐'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Kayıtlı: ${veriler.length} şifre  •  Android • iOS • Windows • macOS • Linux',
              style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            AutofillGroup(
              child: Column(
                children: [
                  TextField(
                    controller: siteCtrl,
                    autofillHints: const [AutofillHints.url],
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Site (örn: instagram)',
                      hintText: 'Yazınca otomatik dolar...',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.language)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: userCtrl,
                    autofillHints: const [AutofillHints.username, AutofillHints.email],
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Kullanıcı adı / E-posta',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passCtrl,
                    autofillHints: const [AutofillHints.password],
                    obscureText: sifreGizli,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => ekle(),
                    decoration: InputDecoration(
                      labelText: 'Şifre',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(sifreGizli ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => sifreGizli = !sifreGizli),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: ekle,
              icon: const Icon(Icons.save),
              label: const Text('KAYDET'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => TextInput.finishAutofillContext(),
              icon: const Icon(Icons.auto_fix_high),
              label: const Text('OTOMATİK DOLDURMAYI BİTİR / KAYDET'),
            ),
            const Divider(height: 32),
            const Text('Kayıtlı Şifreler', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...veriler.keys.map((site) {
              final item = veriler[site];
              return Card(
                child: ListTile(
                  onTap: () => doldur(site),
                  leading: CircleAvatar(child: Text(site[0].toUpperCase())),
                  title: Text(site.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Kullanıcı: ${item['kullanici']}  •  Şifre: ••••••••'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.auto_fix_high), onPressed: () => doldur(site)),
                      IconButton(icon: const Icon(Icons.copy), onPressed: () => kopyala(item['sifre'])),
                      IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => sil(site)),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
