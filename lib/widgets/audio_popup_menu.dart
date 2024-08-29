import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class AudioPopupMenu extends StatelessWidget {
  final String audioFileName;
  final Function() onRename;
  final Function() onAddToCollection;
  final Function() onDelete;

  const AudioPopupMenu({
    super.key,
    required this.audioFileName,
    required this.onRename,
    required this.onAddToCollection,
    required this.onDelete,
  });

  Future<void> downloadAndShare(String url, String fileName) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes, flush: true);
      final xFile = XFile(filePath);
      await Share.shareXFiles([xFile],
          text: 'Я записал крутую сказу, послушай!');
    } else {
      throw Exception('Failed to download file: ${response.statusCode}');
    }
  }

  String getAudioUrl(String audioFileName) {
    return 'https://firebasestorage.googleapis.com/v0/b/memorybox2-da467.appspot.com/o/users%2FMOyYAuZQ7YdPIcEugsF8DLtzrZ13%2Faudio%2F$audioFileName?alt=media&token=';
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
      offset: const Offset(-45, 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      color: Colors.white,
      padding: EdgeInsets.zero,
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 1,
          child: Text('Переименовать'),
        ),
        const PopupMenuItem(
          value: 2,
          child: Text('Добавить в подборку'),
        ),
        const PopupMenuItem(
          value: 3,
          child: Text('Удалить'),
        ),
        const PopupMenuItem(
          value: 4,
          child: Text('Поделиться'),
        ),
      ],
      onSelected: (value) {
        switch (value) {
          case 1:
            onRename();
            break;
          case 2:
            onAddToCollection();
            break;
          case 3:
            onDelete();
            break;
          case 4:
            final url = getAudioUrl(audioFileName);
            downloadAndShare(url, audioFileName);
            break;
        }
      },
      child: Container(
        padding: const EdgeInsets.only(right: 25, bottom: 10),
        child: const Text('...', style: TextStyle(fontSize: 24)),
      ),
    );
  }
}
