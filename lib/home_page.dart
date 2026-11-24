import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'api.dart';
import 'config.dart';
import 'file_reader.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final GlobalKey _resultKey = GlobalKey();

  RemoteConfig _config = RemoteConfig.fallback;
  int _mode = 1;
  String _lang = 'en';
  String _output = '';
  bool _loading = false;
  bool _readingFile = false;

  @override
  void initState() {
    super.initState();
    ParaphraseApi.fetchConfig().then((c) {
      if (mounted) setState(() => _config = c);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  int _wordCount(String text) {
    final t = text.trim();
    if (t.isEmpty) return 0;
    return RegExp(r'\S+').allMatches(t).length;
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _open(String url) async {
    try {
      final ok =
          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      if (!ok) _snack('Could not open the link.');
    } catch (_) {
      _snack('Could not open the link.');
    }
  }

  void _showUpgrade(String message) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Premium feature'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Not now'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.orange),
            onPressed: () {
              Navigator.pop(ctx);
              _open(AppConfig.pricingUrl);
            },
            child: const Text('Upgrade'),
          ),
        ],
      ),
    );
  }

  Future<void> _paraphrase() async {
    FocusScope.of(context).unfocus();
    final text = _controller.text.trim();
    if (text.isEmpty) {
      _snack('Please enter some text first.');
      return;
    }
    if (_wordCount(text) > _config.wordLimit) {
      _showUpgrade(
          'You can paraphrase up to ${_config.wordLimit} words at once. Get Premium for unlimited words!');
      return;
    }

    setState(() => _loading = true);
    try {
      final result = await ParaphraseApi.paraphrase(
        text: text,
        language: _lang,
        mode: _mode,
      );
      if (!mounted) return;
      setState(() => _output = result);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = _resultKey.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(ctx,
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOut);
        }
      });
    } on ApiException catch (e) {
      if (e.premiumRequired) {
        _showUpgrade(e.message);
      } else {
        _snack(e.message);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickFile() async {
    setState(() => _readingFile = true);
    try {
      final text = await FileReader.pickAndRead();
      if (text == null) return;
      setState(() {
        _controller.text = text;
        _output = '';
      });
      final n = _wordCount(text);
      if (n > _config.wordLimit) {
        _snack('This file has $n words. The limit is ${_config.wordLimit}.');
      }
    } on FileReadException catch (e) {
      _snack(e.message);
    } catch (_) {
      _snack('Could not read this file.');
    } finally {
      if (mounted) setState(() => _readingFile = false);
    }
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text ?? '';
    if (text.isEmpty) {
      _snack('Clipboard is empty.');
      return;
    }
    setState(() {
      _controller.text = text;
      _output = '';
    });
  }

  void _clear() {
    setState(() {
      _controller.clear();
      _output = '';
    });
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _output));
    _snack('Copied to clipboard.');
  }

  Future<void> _download() async {
    try {
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Save paraphrased text',
        fileName: 'paraphrased_content.txt',
        bytes: Uint8List.fromList(utf8.encode(_output)),
      );
      if (path != null) _snack('File saved.');
    } catch (_) {
      _snack('Could not save the file.');
    }
  }

  // ---------------------------------------------------------------- UI

  @override
  Widget build(BuildContext context) {
    final words = _wordCount(_controller.text);
    final overLimit = words > _config.wordLimit;
    final selectedMode = kModes.firstWhere((m) => m.id == _mode);

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Image.asset('assets/logo.png', height: 34),
        actions: [
          PopupMenuButton<String>(
            onSelected: _open,
            itemBuilder: (_) => const [
              PopupMenuItem(
                  value: AppConfig.pricingUrl, child: Text('Upgrade to Premium')),
              PopupMenuItem(value: AppConfig.aboutUrl, child: Text('About Us')),
              PopupMenuItem(
                  value: AppConfig.contactUrl, child: Text('Contact Us')),
              PopupMenuItem(
                  value: AppConfig.privacyUrl, child: Text('Privacy Policy')),
              PopupMenuItem(
                  value: AppConfig.termsUrl,
                  child: Text('Terms & Conditions')),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            controller: _scroll,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Free Paraphrasing Tool',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.darkPurple,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Paste your text, choose a mode and rewrite it in seconds.',
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 16),

                // Modes
                SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: kModes.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) => _modeChip(kModes[i]),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  selectedMode.description,
                  style: const TextStyle(color: Colors.black54, fontSize: 12.5),
                ),
                const SizedBox(height: 12),

                // Language
                DropdownButtonFormField<String>(
                  value: _lang,
                  decoration: InputDecoration(
                    labelText: 'Language',
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                  items: kLanguages
                      .map((l) =>
                          DropdownMenuItem(value: l.code, child: Text(l.name)))
                      .toList(),
                  onChanged: (v) => setState(() => _lang = v ?? 'en'),
                ),
                const SizedBox(height: 14),

                // Input
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _controller,
                        minLines: 8,
                        maxLines: 14,
                        keyboardType: TextInputType.multiline,
                        textCapitalization: TextCapitalization.sentences,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          hintText: 'Enter or paste your text here...',
                          border: InputBorder.none,
                        ),
                      ),
                      Text(
                        'Words: $words / ${_config.wordLimit}',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: overLimit ? Colors.red : Colors.black54,
                        ),
                      ),
                      if (overLimit)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            "You can't exceed the ${_config.wordLimit} words limit. Get Premium for unlimited words!",
                            style: const TextStyle(
                                color: Colors.red, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _readingFile ? null : _pickFile,
                      icon: _readingFile
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.upload_file, size: 18),
                      label: const Text('Upload file'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _paste,
                      icon: const Icon(Icons.content_paste, size: 18),
                      label: const Text('Paste'),
                    ),
                    TextButton.icon(
                      onPressed: _clear,
                      icon: const Icon(Icons.clear, size: 18),
                      label: const Text('Clear'),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Supported files: .txt, .docx, .pdf',
                  style: TextStyle(color: Colors.black45, fontSize: 11.5),
                ),
                const SizedBox(height: 14),

                // Paraphrase button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.orange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _loading ? null : _paraphrase,
                    child: _loading
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.5, color: Colors.white),
                              ),
                              SizedBox(width: 12),
                              Text('Paraphrasing...',
                                  style: TextStyle(fontSize: 16)),
                            ],
                          )
                        : const Text('Paraphrase',
                            style: TextStyle(
                                fontSize: 17, fontWeight: FontWeight.w700)),
                  ),
                ),

                // Result
                if (_output.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Container(
                    key: _resultKey,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.purple, width: 1.2),
                    ),
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('Result',
                                style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.darkPurple,
                                    fontSize: 16)),
                            const Spacer(),
                            Text('Words: ${_wordCount(_output)}',
                                style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black54)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SelectableText(_output,
                            style: const TextStyle(fontSize: 15.5, height: 1.5)),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            FilledButton.icon(
                              style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.purple),
                              onPressed: _copy,
                              icon: const Icon(Icons.copy, size: 18),
                              label: const Text('Copy'),
                            ),
                            OutlinedButton.icon(
                              onPressed: _download,
                              icon: const Icon(Icons.download, size: 18),
                              label: const Text('Download .txt'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],

                // Upgrade banner
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.purple, AppColors.darkPurple],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Need more power?',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      const Text(
                        'Get Premium for unlimited words and extra modes.',
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        style: FilledButton.styleFrom(
                            backgroundColor: AppColors.orange,
                            foregroundColor: Colors.white),
                        onPressed: () => _open(AppConfig.pricingUrl),
                        child: const Text('Upgrade'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _modeChip(ParaphraseMode m) {
    final locked = _config.lockedModes.contains(m.id);
    final selected = _mode == m.id && !locked;
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () {
        if (locked) {
          _showUpgrade('${m.name} mode is a Premium feature.');
        } else {
          setState(() => _mode = m.id);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.purple : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
              color: selected ? AppColors.purple : AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (m.icon != null) ...[
              Image.asset(m.icon!, width: 20, height: 20),
              const SizedBox(width: 6),
            ],
            Text(
              m.name,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.darkPurple,
              ),
            ),
            if (locked) ...[
              const SizedBox(width: 6),
              const Icon(Icons.lock, size: 14, color: AppColors.orange),
            ],
          ],
        ),
      ),
    );
  }
}
