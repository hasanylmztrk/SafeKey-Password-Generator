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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
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

  // PASSWORD GENERATOR SETTINGS
  double genLength = 16;
  bool genUpper = true;
  bool genLower = true;
  bool genNumbers = true;
  bool genSymbols = true;
  String generatedPassword = "";
  bool isGeneratorOpen = false;

  // UPDATE SETTINGS
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
    siteCtrl.dispose();
    userCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

  Future<void> load() async {
    final jsonStr = await storage.read(key: 'safekey_data');
    if (jsonStr != null) {
      setState(() => data = jsonDecode(jsonStr));
    }
  }

  Future<void> save() async {
    await storage.write(key: 'safekey_data', value: jsonEncode(data));
  }

  void add() async {
    final site = siteCtrl.text.trim().toLowerCase();
    final user = userCtrl.text.trim();
    final pass = passCtrl.text.trim();
    if (site.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Site and password cannot be empty!')));
      return;
    }
    setState(() {
      data[site] = {'username': user, 'password': pass};
      siteCtrl.clear(); userCtrl.clear(); passCtrl.clear();
    });
    await save();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$site saved! ✅')));
  }

  void delete(String site) async {
    setState(() => data.remove(site));
    await save();
  }

  void copy(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied!')));
  }

  void fill(String site) {
    final item = data[site];
    if (item == null) return;
    setState(() {
      siteCtrl.text = site;
      userCtrl.text = item['username'] ?? '';
      passCtrl.text = item['password'] ?? '';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$site filled!')));
  }

  void generatePassword() {
    String chars = "";
    if (genUpper) chars += "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    if (genLower) chars += "abcdefghijklmnopqrstuvwxyz";
    if (genNumbers) chars += "0123456789";
    if (genSymbols) chars += "!@#\$%^&*()-_=+";
    if (chars.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one option!')));
      return;
    }
    final rand = Random.secure();
    final newPass = List.generate(genLength.toInt(), (_) => chars[rand.nextInt(chars.length)]).join();
    setState(() {
      generatedPassword = newPass;
      passCtrl.text = newPass;
      isPasswordHidden = false;
    });
  }

  // CHECK FOR UPDATES
  Future<void> checkForUpdate() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Checking for updates...')));
    try {
      final url = Uri.parse('https://api.github.com/repos/$repoOwner/$repoName/releases/latest');
      final response = await http.get(url);
      if (response.statusCode != 200) throw Exception('Failed');
      final json = jsonDecode(response.body);
      String latest = (json['tag_name'] as String).replaceAll('v', '');
      String downloadUrl = json['html_url'] ?? 'https://github.com/$repoOwner/$repoName/releases';
      if (!mounted) return;
      if (latest != currentVersion) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('🎉 New Update Available!'),
            content: Text('You have v$currentVersion\nNew version: v$latest\n\nDo you want to update?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Later')),
              FilledButton(
                onPressed: () async {
                  Navigator.pop(context);
                  final uri = Uri.parse(downloadUrl);
                  if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
                },
                child: const Text('DOWNLOAD')),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You are on the latest version ✅')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not check for updates. Check internet.')));
    }
  }

  // BACKUP - Export
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

  // RESTORE - Import
  Future<void> importBackup() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.any);
      if (result == null || result.files.single.path == null) return;
      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      final Map<String, dynamic> imported = jsonDecode(content);

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Restore Backup?'),
          content: Text('Found ${imported.length} passwords.\nThis will merge with your current passwords. Continue?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                Navigator.pop(context);
                setState(() => data.addAll(imported));
                await save();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Backup restored! ✅')));
              },
              child: const Text('RESTORE')),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid backup file!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SafeKey 🔐'),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.system_update_alt), tooltip: 'Check for Updates', onPressed: checkForUpdate),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Saved: ${data.length} passwords  •  v$currentVersion  •  Android • iOS • Windows • macOS • Linux',
              style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            Column(
              children: [
                TextField(
                  controller: siteCtrl,
                  enableSuggestions: false,
                  autocorrect: false,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Site (e.g. instagram)',
                    hintText: 'Type to autofill...',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.language)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: userCtrl,
                  enableSuggestions: false,
                  autocorrect: false,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Username / Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passCtrl,
                  enableSuggestions: false,
                  autocorrect: false,
                  obscureText: isPasswordHidden,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => add(),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.casino, color: Colors.deepPurple),
                          tooltip: 'Generate Password',
                          onPressed: () => setState(() => isGeneratorOpen = !isGeneratorOpen),
                        ),
                        IconButton(
                          icon: Icon(isPasswordHidden ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => isPasswordHidden = !isPasswordHidden),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (isGeneratorOpen)
              Card(
                color: Colors.deepPurple.shade50,
                margin: const EdgeInsets.only(top: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.auto_fix_high, color: Colors.deepPurple),
                          const SizedBox(width: 8),
                          const Text('Password Generator', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                          const Spacer(),
                          IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => isGeneratorOpen = false)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.deepPurple.shade100)),
                        child: Row(
                          children: [
                            Expanded(child: SelectableText(generatedPassword.isEmpty ? "Press Generate..." : generatedPassword, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                            IconButton(icon: const Icon(Icons.copy), onPressed: () => copy(generatedPassword)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Length: ${genLength.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      Slider(value: genLength, min: 6, max: 32, divisions: 26, label: genLength.toInt().toString(), onChanged: (v) => setState(() => genLength = v)),
                      SwitchListTile(title: const Text('Uppercase (ABC)'), value: genUpper, onChanged: (v) => setState(() => genUpper = v)),
                      SwitchListTile(title: const Text('Lowercase (abc)'), value: genLower, onChanged: (v) => setState(() => genLower = v)),
                      SwitchListTile(title: const Text('Numbers (123)'), value: genNumbers, onChanged: (v) => setState(() => genNumbers = v)),
                      SwitchListTile(title: const Text('Symbols (!@#)'), value: genSymbols, onChanged: (v) => setState(() => genSymbols = v)),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(onPressed: generatePassword, icon: const Icon(Icons.refresh), label: const Text('GENERATE PASSWORD')),
                      ),
                      const SizedBox(height: 4),
                      const Text('Generated password is automatically written to the Password field above. Just press SAVE.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 12),
            FilledButton.icon(onPressed: add, icon: const Icon(Icons.save), label: const Text('SAVE')),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: OutlinedButton.icon(onPressed: exportBackup, icon: const Icon(Icons.backup), label: const Text('BACKUP'))),
                const SizedBox(width: 8),
                Expanded(child: OutlinedButton.icon(onPressed: importBackup, icon: const Icon(Icons.restore), label: const Text('RESTORE'))),
              ],
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(onPressed: checkForUpdate, icon: const Icon(Icons.system_update_alt), label: const Text('CHECK FOR UPDATES')),
            const Divider(height: 32),
            const Text('Saved Passwords', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...data.keys.map((site) {
              final item = data[site];
              return Card(
                child: ListTile(
                  onTap: () => fill(site),
                  leading: CircleAvatar(child: Text(site[0].toUpperCase())),
                  title: Text(site.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('User: ${item['username']}  •  Password: ••••••••'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.auto_fix_high), onPressed: () => fill(site)),
                      IconButton(icon: const Icon(Icons.copy), onPressed: () => copy(item['password'])),
                      IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => delete(site)),
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
