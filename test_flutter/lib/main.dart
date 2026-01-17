import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:io';

void main() {
  runApp(const SoundboardApp());
}

class SoundboardApp extends StatelessWidget {
  const SoundboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Soundboard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF2F2F7),
        fontFamily: '.SF Pro Text',
      ),
      home: const SoundboardScreen(),
    );
  }
}

class SoundItem {
  final String name;
  final String path;
  final bool isAsset;

  SoundItem({required this.name, required this.path, this.isAsset = false});
}

class SoundboardScreen extends StatefulWidget {
  const SoundboardScreen({super.key});

  @override
  State<SoundboardScreen> createState() => _SoundboardScreenState();
}

class _SoundboardScreenState extends State<SoundboardScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  
  List<SoundItem> sounds = [
    SoundItem(name: 'Campana', path: 'https://www.soundjay.com/buttons/sounds/button-09.mp3', isAsset: false),
    SoundItem(name: 'Click', path: 'https://www.soundjay.com/buttons/sounds/button-16.mp3', isAsset: false),
    SoundItem(name: 'Pop', path: 'https://www.soundjay.com/buttons/sounds/button-21.mp3', isAsset: false),
    SoundItem(name: 'Notificación', path: 'https://www.soundjay.com/buttons/sounds/button-35.mp3', isAsset: false),
  ];

  int? _playingIndex;

  Future<void> _playSound(int index) async {
    final sound = sounds[index];
    setState(() => _playingIndex = index);
    
    try {
      await _audioPlayer.stop();
      if (sound.isAsset) {
        await _audioPlayer.play(DeviceFileSource(sound.path));
      } else {
        await _audioPlayer.play(UrlSource(sound.path));
      }
    } catch (e) {
      _showError('Error al reproducir el sonido');
    }
    
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _playingIndex = null);
    });
  }

  Future<void> _addLocalSound() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = result.files.single;
        final fileName = file.name.replaceAll(RegExp(r'\.[^.]+$'), '');
        
        setState(() {
          sounds.add(SoundItem(
            name: fileName,
            path: file.path!,
            isAsset: true,
          ));
        });
      }
    } catch (e) {
      _showError('Error al seleccionar archivo');
    }
  }

  Future<void> _downloadSound(String url, String name) async {
    if (url.isEmpty || name.isEmpty) {
      _showError('Por favor ingresa URL y nombre');
      return;
    }

    try {
      _showLoading();
      
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final dir = await getApplicationDocumentsDirectory();
        final fileName = '${name.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.mp3';
        final file = File('${dir.path}/$fileName');
        await file.writeAsBytes(response.bodyBytes);
        
        setState(() {
          sounds.add(SoundItem(
            name: name,
            path: file.path,
            isAsset: true,
          ));
        });
        
        Navigator.pop(context);
        Navigator.pop(context);
        _showSuccess('Sonido descargado');
      } else {
        Navigator.pop(context);
        _showError('Error al descargar');
      }
    } catch (e) {
      Navigator.pop(context);
      _showError('URL inválida');
    }
  }

  void _showLoading() {
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CupertinoActivityIndicator(radius: 20),
      ),
    );
  }

  void _showError(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showSuccess(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Éxito'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showAddOptions() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Añadir Sonido'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _addLocalSound();
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.folder, size: 20),
                SizedBox(width: 8),
                Text('Desde archivo local'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _showUrlDialog();
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.link, size: 20),
                SizedBox(width: 8),
                Text('Desde URL'),
              ],
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDestructiveAction: true,
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
      ),
    );
  }

  void _showUrlDialog() {
    _urlController.clear();
    _nameController.clear();
    
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Descargar desde URL'),
        content: Column(
          children: [
            const SizedBox(height: 16),
            CupertinoTextField(
              controller: _nameController,
              placeholder: 'Nombre del sonido',
              padding: const EdgeInsets.all(12),
            ),
            const SizedBox(height: 12),
            CupertinoTextField(
              controller: _urlController,
              placeholder: 'URL del archivo de audio',
              padding: const EdgeInsets.all(12),
              keyboardType: TextInputType.url,
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => _downloadSound(_urlController.text, _nameController.text),
            child: const Text('Descargar'),
          ),
        ],
      ),
    );
  }

  void _deleteSound(int index) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Eliminar sonido'),
        content: Text('¿Eliminar "${sounds[index].name}"?'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              setState(() => sounds.removeAt(index));
              Navigator.pop(context);
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _urlController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Soundboard',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Tus sonidos favoritos',
                        style: TextStyle(
                          fontSize: 15,
                          color: Color(0xFF8E8E93),
                        ),
                      ),
                    ],
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: _showAddOptions,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF007AFF),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Icon(
                        CupertinoIcons.add,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Sound Grid
            Expanded(
              child: sounds.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            CupertinoIcons.speaker_slash,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Sin sonidos',
                            style: TextStyle(
                              fontSize: 17,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Toca + para añadir uno',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey[400],
                            ),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1,
                      ),
                      itemCount: sounds.length,
                      itemBuilder: (context, index) {
                        final isPlaying = _playingIndex == index;
                        return GestureDetector(
                          onTap: () => _playSound(index),
                          onLongPress: () => _deleteSound(index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            decoration: BoxDecoration(
                              color: isPlaying 
                                  ? const Color(0xFF007AFF) 
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: isPlaying 
                                        ? Colors.white.withOpacity(0.2)
                                        : const Color(0xFFF2F2F7),
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: Icon(
                                    isPlaying 
                                        ? CupertinoIcons.speaker_2_fill
                                        : CupertinoIcons.speaker_2,
                                    size: 28,
                                    color: isPlaying 
                                        ? Colors.white 
                                        : const Color(0xFF007AFF),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: Text(
                                    sounds[index].name,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: isPlaying 
                                          ? Colors.white 
                                          : const Color(0xFF1C1C1E),
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (sounds[index].isAsset)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Icon(
                                      CupertinoIcons.device_phone_portrait,
                                      size: 14,
                                      color: isPlaying 
                                          ? Colors.white70 
                                          : const Color(0xFF8E8E93),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            
            // Footer hint
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Mantén presionado para eliminar',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[400],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
