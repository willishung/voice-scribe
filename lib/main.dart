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
        const Text('離線逐字稿及自動語者辨識：尚未整合', style: TextStyle(color: Colors.deepOrange)),
        const Divider(height: 36),
        const Align(alignment: Alignment.centerLeft, child: Text('錄音紀錄')),
        Expanded(child: ListView.builder(
          itemCount: files.length,
          itemBuilder: (context, index) {
            final f = files[index];
            return ListTile(
              leading: const Icon(Icons.audiotrack),
              title: Text(f.uri.pathSegments.last),
              trailing: IconButton(
                icon: const Icon(Icons.share),
                onPressed: () async => SharePlus.instance.share(
                  ShareParams(files: [XFile(f.path)]),
                ),
              ),
            );
          },
        )),
      ]),
    ),
  );
}
