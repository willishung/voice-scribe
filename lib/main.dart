import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:share_plus/share_plus.dart';

void main() => runApp(const VoiceScribeApp());

class VoiceScribeApp extends StatelessWidget {
  const VoiceScribeApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: '聲記',
    theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal),
    home: const RecorderPage(),
  );
}

class RecorderPage extends StatefulWidget {
  const RecorderPage({super.key});
  @override
  State<RecorderPage> createState() => _RecorderPageState();
}

class _RecorderPageState extends State<RecorderPage> {
  final AudioRecorder recorder = AudioRecorder();
  bool recording = false;
  String status = '準備錄音';
  List<File> files = [];

  @override
  void initState() {
    super.initState();
    refresh();
  }

  Future<Directory> get folder async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/recordings');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<void> refresh() async {
    final dir = await folder;
    final items = dir.listSync().whereType<File>()
      .where((f) => f.path.endsWith('.wav')).toList()
      ..sort((a, b) => b.path.compareTo(a.path));
    if (mounted) setState(() => files = items);
  }

  Future<void> editTranscript(File audio) async {
    final transcript = File('${audio.path}.txt');
    final controller = TextEditingController(
      text: await transcript.exists() ? await transcript.readAsString() : '',
    );
    if (!mounted) { controller.dispose(); return; }
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('逐字稿（手動編輯）'),
        content: SizedBox(
          width: double.maxFinite,
          child: TextField(
            controller: controller,
            minLines: 5,
            maxLines: 12,
            decoration: const InputDecoration(
              hintText: '離線 AI 辨識尚未整合，可先輸入或修改逐字稿。',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              await transcript.writeAsString(controller.text, flush: true);
              if (dialogContext.mounted) Navigator.pop(dialogContext);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('逐字稿已儲存')),
                );
              }
            },
            child: const Text('儲存'),
          ),
        ],
      ),
    );
    controller.dispose();
  }

  Future<void> exportTranscript(File audio) async {
    final transcript = File('${audio.path}.txt');
    if (!await transcript.exists()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('請先編輯並儲存逐字稿')),
        );
      }
      return;
    }
    await SharePlus.instance.share(
      ShareParams(files: [XFile(transcript.path)]),
    );
  }

  Future<void> toggle() async {
    try {
      if (recording) {
        await recorder.stop();
        setState(() { recording = false; status = '錄音已儲存'; });
        await refresh();
      } else {
        if (!await recorder.hasPermission()) {
          setState(() => status = '請允許麥克風權限');
          return;
        }
        final dir = await folder;
        final path = '${dir.path}/rec_${DateTime.now().millisecondsSinceEpoch}.wav';
        await recorder.start(
          const RecordConfig(encoder: AudioEncoder.wav, sampleRate: 16000, numChannels: 1),
          path: path,
        );
        setState(() { recording = true; status = '錄音中'; });
      }
    } catch (e) {
      if (mounted) setState(() => status = '發生錯誤：$e');
    }
  }

  @override
  void dispose() {
    recorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('聲記 Voice Scribe')),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        const Icon(Icons.mic, size: 70, color: Colors.teal),
        const SizedBox(height: 16),
        Text(status, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: toggle,
          icon: Icon(recording ? Icons.stop : Icons.fiber_manual_record),
          label: Text(recording ? '停止並儲存' : '開始錄音'),
        ),
        const SizedBox(height: 12),
        const Text('離線 AI 轉錄及自動語者辨識尚未整合；現可手動編輯及匯出 TXT', style: TextStyle(color: Colors.deepOrange)),
        const Divider(height: 36),
        const Align(alignment: Alignment.centerLeft, child: Text('錄音紀錄')),
        Expanded(child: ListView.builder(
          itemCount: files.length,
          itemBuilder: (context, index) {
            final f = files[index];
            return ListTile(
              leading: const Icon(Icons.audiotrack),
              title: Text(f.uri.pathSegments.last),
              trailing: PopupMenuButton<String>(
                onSelected: (action) async {
                  if (action == 'edit') await editTranscript(f);
                  if (action == 'txt') await exportTranscript(f);
                  if (action == 'audio') {
                    await SharePlus.instance.share(
                      ShareParams(files: [XFile(f.path)]),
                    );
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: Text('編輯逐字稿')),
                  PopupMenuItem(value: 'txt', child: Text('匯出 TXT')),
                  PopupMenuItem(value: 'audio', child: Text('分享錄音')),
                ],
              ),
            );
          },
        )),
      ]),
    ),
  );
}
