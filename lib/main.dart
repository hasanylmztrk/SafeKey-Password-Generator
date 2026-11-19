import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

void main() => runApp(const SafeKeyApp());

class SafeKeyApp extends StatelessWidget {
  const SafeKeyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SafeKey',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B0B14),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF7C5CFF),
          secondary: Color(0xFF00E5A0),
          surface: Color(0xFF171826),
        ),
        useMaterial3: true,
        cardTheme: CardTheme(
          color: const Color(0xFF171826),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF171826),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF7C5CFF), width: 1.5)),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF7C5CFF),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final storage = const FlutterSecureStorage();
  final siteCtrl = TextEditingController();
  final userCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  Map<String, dynamic> data = {};
  bool isPasswordHidden = true;

  double genLength = 16;
  bool genUpper = true;
  bool genLower = true;
  bool genNumbers = true;
  bool genSymbols = true;
  String generatedPassword = "";
  bool isGeneratorOpen = false;

  final String currentVersion = "1.0.1";
  final String repoOwner = "hasanylmztrk";
  final String repoName = "SafeKey-Password-Generator";

  @override
  void initState() {
    super.initState();
    load();
    siteCtrl.addListener(() {
      final site = siteCtrl.text.trim().toLowerCase();
      if (site.isEmpty) return;
      final item = data[site];
      if (item != null) {
        userCtrl.text = item['username'] ?? '';
        passCtrl.text = item['password'] ?? '';
      }
    });
  }

  @override
  void dispose() {
    siteCtrl.dispose(); userCtrl.dispose(); passCtrl.dispose();
    super.dispose();
  }

  Future<void> load() async {
    final jsonStr = await storage.read(key: 'safekey_data');
    if (jsonStr != null) setState(() => data = jsonDecode(jsonStr));
  }

  Future<void> save() async {
    await storage.write(key: 'safekey_data', value: jsonEncode(data));
  }

  void add() async {
    final site = siteCtrl.text.trim().toLowerCase();
    final user = userCtrl.text.trim();
    final pass = passCtrl.text.trim();
    if (site.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Site and password cannot be empty!')));
      return;
    }
    setState(() {
      data[site] = {'username': user, 'password': pass};
      siteCtrl.clear(); userCtrl.clear(); passCtrl.clear();
    });
    await save();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$site saved! ✅'), backgroundColor: const Color(0xFF00E5A0)));
  }

  void delete(String site) async {
    setState(() => data.remove(site));
    await save();
  }

  void copy(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied!')));
  }

  void fill(String site) {
    final item = data[site];
    if (item == null) return;
    setState(() {
      siteCtrl.text = site;
      userCtrl.text = item['username'] ?? '';
      passCtrl.text = item['password'] ?? '';
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$site filled!')));
  }

  void generatePassword() {
    String chars = "";
    if (genUpper) chars += "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    if (genLower) chars += "abcdefghijklmnopqrstuvwxyz";
    if (genNumbers) chars += "0123456789";
    if (genSymbols) chars += "!@#\$%^&*()-_=+";
    if (chars.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select at least one option!')));
      return;
    }
    final rand = Random.secure();
    final newPass = List.generate(genLength.toInt(), (_) => chars[rand.nextInt(chars.length)]).join();
    setState(() { generatedPassword = newPass; passCtrl.text = newPass; isPasswordHidden = false; });
  }

  Future<void> checkForUpdate() async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Checking for updates...')));
    try {
      final url = Uri.parse('https://api.github.com/repos/$repoOwner/$repoName/releases/latest');
      final response = await http.get(url, headers: {'Accept': 'application/vnd.github+json', 'User-Agent': 'SafeKey-App'});
      if (response.statusCode != 200) throw Exception('Failed');
      final json = jsonDecode(response.body);
      String latest = (json['tag_name'] as String).replaceAll('v', '');
      String downloadUrl = json['html_url'] ?? 'https://github.com/$repoOwner/$repoName/releases';
      if (!mounted) return;
      if (latest != currentVersion) {
        showDialog(context: context, builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF171826),
          title: const Text('🎉 New Update Available!'),
          content: Text('You have v$currentVersion\nNew version: v$latest\n\nDo you want to update?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Later')),
            FilledButton(onPressed: () async {
              Navigator.pop(context);
              final uri = Uri.parse(downloadUrl);
              if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
            }, child: const Text('DOWNLOAD')),
          ],
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You are on the latest version ✅')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Internet error $e.')));
    }
  }

  Future<void> exportBackup() async {
    if (data.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nothing to backup!')));
      return;
    }
    try {
      final jsonStr = jsonEncode(data);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/safekey-backup-${DateTime.now().millisecondsSinceEpoch}.json');
      await file.writeAsString(jsonStr);
      await Share.shareXFiles([XFile(file.path)], text: 'SafeKey Backup - Keep this file safe!');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Backup failed!')));
    }
  }

  Future<void> importBackup() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.any);
      if (result == null || result.files.single.path == null) return;
      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      final Map<String, dynamic> imported = jsonDecode(content);
      if (!mounted) return;
      showDialog(context: context, builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF171826),
        title: const Text('Restore Backup?'),
        content: Text('Found ${imported.length} passwords.\nThis will merge with your current passwords. Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () async {
            Navigator.pop(context);
            setState(() => data.addAll(imported));
            await save();
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Backup restored! ✅')));
          }, child: const Text('RESTORE')),
        ],
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid backup file!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // HEADER
              Row(
                children: [
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(color: const Color(0xFF7C5CFF), borderRadius: BorderRadius.circular(16)),
                    child: const Icon(Icons.lock, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('SafeKey', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
                    Text('Your passwords, safe.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  ])),
                  IconButton(onPressed: checkForUpdate, icon: const Icon(Icons.system_update_alt), tooltip: 'Check for Updates', style: IconButton.styleFrom(backgroundColor: const Color(0xFF171826))),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFF171826), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF7C5CFF).withOpacity(0.3))),
                child: Row(children: [
                  const Icon(Icons.shield, color: Color(0xFF00E5A0)),
                  const SizedBox(width: 10),
                  Text('${data.length} passwords saved', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const Spacer(),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: const Color(0xFF7C5CFF).withOpacity(0.2), borderRadius: BorderRadius.circular(20)), child: Text('v$currentVersion', style: const TextStyle(fontSize: 12, color: Color(0xFF7C5CFF)))),
                ]),
              ),
              const SizedBox(height: 20),

              TextField(controller: siteCtrl, enableSuggestions: false, autocorrect: false, textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Site (e.g. instagram)', hintText: 'Type to autofill...', prefixIcon: Icon(Icons.language, color: Color(0xFF7C5CFF)))),
              const SizedBox(height: 12),
              TextField(controller: userCtrl, enableSuggestions: false, autocorrect: false, keyboardType: TextInputType.emailAddress, textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Username / Email', prefixIcon: Icon(Icons.person, color: Color(0xFF7C5CFF)))),
              const SizedBox(height: 12),
              TextField(controller: passCtrl, enableSuggestions: false, autocorrect: false, obscureText: isPasswordHidden, textInputAction: TextInputAction.done, onSubmitted: (_) => add(),
                decoration: InputDecoration(labelText: 'Password', prefixIcon: const Icon(Icons.lock, color: Color(0xFF7C5CFF)), suffixIcon: Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(icon: const Icon(Icons.casino, color: Color(0xFF00E5A0)), tooltip: 'Generate Password', onPressed: () => setState(() => isGeneratorOpen = !isGeneratorOpen)),
                  IconButton(icon: Icon(isPasswordHidden ? Icons.visibility : Icons.visibility_off), onPressed: () => setState(() => isPasswordHidden = !isPasswordHidden)),
                ]))),
              if (isGeneratorOpen)
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: const Color(0xFF1E1B3A), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF7C5CFF))),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      const Icon(Icons.auto_fix_high, color: Color(0xFF7C5CFF)),
                      const SizedBox(width: 8),
                      const Text('Password Generator', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => isGeneratorOpen = false)),
                    ]),
                    const SizedBox(height: 12),
                    Container(width: double.infinity, padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), borderRadius: BorderRadius.circular(12)), child: Row(children: [
                      Expanded(child: SelectableText(generatedPassword.isEmpty ? "Press Generate..." : generatedPassword, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                      IconButton(icon: const Icon(Icons.copy, color: Color(0xFF00E5A0)), onPressed: () => copy(generatedPassword)),
                    ])),
                    const SizedBox(height: 8),
                    Text('Length: ${genLength.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Slider(value: genLength, min: 6, max: 32, divisions: 26, label: genLength.toInt().toString(), activeColor: const Color(0xFF7C5CFF), onChanged: (v) => setState(() => genLength = v)),
                    SwitchListTile(title: const Text('Uppercase (ABC)'), value: genUpper, activeColor: const Color(0xFF7C5CFF), onChanged: (v) => setState(() => genUpper = v)),
                    SwitchListTile(title: const Text('Lowercase (abc)'), value: genLower, activeColor: const Color(0xFF7C5CFF), onChanged: (v) => setState(() => genLower = v)),
                    SwitchListTile(title: const Text('Numbers (123)'), value: genNumbers, activeColor: const Color(0xFF7C5CFF), onChanged: (v) => setState(() => genNumbers = v)),
                    SwitchListTile(title: const Text('Symbols (!@#)'), value: genSymbols, activeColor: const Color(0xFF7C5CFF), onChanged: (v) => setState(() => genSymbols = v)),
                    SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: generatePassword, icon: const Icon(Icons.refresh), label: const Text('GENERATE PASSWORD'))),
                  ]),
                ),
              const SizedBox(height: 16),
              FilledButton.icon(onPressed: add, icon: const Icon(Icons.save), label: const Text('SAVE PASSWORD')),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: OutlinedButton.icon(onPressed: exportBackup, icon: const Icon(Icons.backup), label: const Text('BACKUP'), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))))),
                const SizedBox(width: 10),
                Expanded(child: OutlinedButton.icon(onPressed: importBackup, icon: const Icon(Icons.restore), label: const Text('RESTORE'), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))))),
              ]),
              const SizedBox(height: 24),
              Row(children: [
                const Text('Saved Passwords', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
                const Spacer(),
                Text('${data.length} total', style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ]),
              const SizedBox(height: 12),
              if (data.isEmpty)
                Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: const Color(0xFF171826), borderRadius: BorderRadius.circular(20)), child: const Column(children: [Icon(Icons.lock_open, size: 40, color: Colors.grey), SizedBox(height: 8), Text('No passwords yet', style: TextStyle(fontWeight: FontWeight.bold)), Text('Add your first password above', style: TextStyle(color: Colors.grey))])),

              ...data.keys.map((site) {
                final item = data[site];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(color: const Color(0xFF171826), borderRadius: BorderRadius.circular(20)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    onTap: () => fill(site),
                    leading: Container(width: 46, height: 46, decoration: BoxDecoration(color: const Color(0xFF7C5CFF), borderRadius: BorderRadius.circular(14)), child: Center(child: Text(site[0].toUpperCase(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)))),
                    title: Text(site.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('User: ${item['username']}  •  ••••••••', style: const TextStyle(color: Colors.grey)),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      IconButton(icon: const Icon(Icons.copy, size: 20, color: Color(0xFF00E5A0)), onPressed: () => copy(item['password'])),
                      IconButton(icon: const Icon(Icons.delete, size: 20, color: Colors.redAccent), onPressed: () => delete(site)),
                    ]),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
