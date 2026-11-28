import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(const NanNotesApp());

class NotesTheme {
  static const Color bg = Color(0xFF0C0E12);
  static const Color panel = Color(0xFF141820);
  static const Color sidebar = Color(0xFF11141B);
  static const Color amber = Color(0xFFC99342);
  static const Color cyan = Color(0xFF4C99BA);
  static const Color textMain = Color(0xFFCBD5E1);
  static const Color textDim = Color(0xFF64748B);

  static const List<Color> palette = <Color>[
    Color(0xFF56A888), // Шалфей
    Color(0xFFC97863), // Терракота
    Color(0xFF5894BD), // Сизый голубой
    Color(0xFFB59A4C), // Приглушённая охра
    Color(0xFF8B7EC8), // Пыльная лаванда
    Color(0xFF4CA398), // Спокойная бирюза
    Color(0xFFC26D82), // Пыльный коралл
    Color(0xFF72A366), // Травяной
    Color(0xFF6882C4), // Приглушённый василёк
    Color(0xFFC48B52), // Мягкий янтарь
    Color(0xFF5C9EB5), // Морская волна
    Color(0xFFA378B5), // Приглушённая слива
    Color(0xFF8FA356), // Оливковый
    Color(0xFFBD6E96), // Пыльная роза
    Color(0xFF52A675), // Хвойный
    Color(0xFFBA7C56), // Корица
    Color(0xFF5A8FB8), // Стальной синий
    Color(0xFF9EA154), // Горчичный
    Color(0xFF7A85C2), // Барвинок
    Color(0xFF4E9E8B), // Нефрит
    Color(0xFFBF6F73), // Брусничный
    Color(0xFF6BA18E), // Эвкалипт
    Color(0xFF967BB0), // Вереск
    Color(0xFFB88F56), // Песочный
  ];

  static Color colorForFolder(
      String folder, bool isLink, List<String> allFolders) {
    if (folder == 'Общее') return isLink ? cyan : amber;
    final idx = allFolders.indexOf(folder);
    final safeIdx = idx >= 0 ? idx : folder.length;
    final offset = isLink ? 7 : 0;
    return palette[(safeIdx * 3 + offset) % palette.length];
  }
}

IconData iconForCategory(String folder, bool isLink) {
  final f = folder.toLowerCase();
  if (f.contains('иде')) return Icons.lightbulb_outline_rounded;
  if (f.contains('фильм') || f.contains('кино')) return Icons.movie_outlined;
  if (f.contains('книг')) return Icons.auto_stories_outlined;
  if (f.contains('видео')) return Icons.play_circle_outline_rounded;
  if (f.contains('сервис')) return Icons.widgets_outlined;
  if (f.contains('стат')) return Icons.article_outlined;
  return isLink ? Icons.language_rounded : Icons.sticky_note_2_outlined;
}

void playSound(String name) {
  final file = '/usr/share/sounds/freedesktop/stereo/$name.oga';
  Process.run('paplay', <String>['--volume=36000', file])
      .catchError((_) => ProcessResult(0, 0, '', ''));
}

void openUrlInBrowser(String rawUrl) {
  var url = rawUrl.trim();
  if (!url.startsWith('http://') && !url.startsWith('https://')) {
    url = 'https://$url';
  }
  Process.run('xdg-open', <String>[url])
      .catchError((_) => ProcessResult(0, 0, '', ''));
}

class NanNotesApp extends StatelessWidget {
  const NanNotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseTheme = ThemeData.dark();
    return MaterialApp(
      title: 'NanNotes',
      debugShowCheckedModeBanner: false,
      theme: baseTheme.copyWith(
        scaffoldBackgroundColor: NotesTheme.bg,
        textTheme: baseTheme.textTheme.apply(
          fontFamily: 'Inter',
          fontFamilyFallback: const ['Ubuntu', 'Noto Sans', 'sans-serif'],
          bodyColor: NotesTheme.textMain,
          displayColor: NotesTheme.textMain,
        ),
      ),
      home: const NotesScreen(),
    );
  }
}



class NoteItem {
  String id;
  bool isLink;
  String text;
  String title;
  String folder;

  NoteItem({
    required this.id,
    required this.isLink,
    required this.text,
    this.title = '',
    this.folder = 'Общее',
  });

  bool get isLong => text.length > 72 || text.contains('\n');

  Map<String, dynamic> toJson() => {
        'id': id,
        'isLink': isLink,
        'text': text,
        'title': title,
        'folder': folder,
      };

  factory NoteItem.fromJson(Map<String, dynamic> json) {
    return NoteItem(
      id: json['id']?.toString() ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      isLink: json['isLink'] == true || json['type'] == 'link',
      text: (json['text'] ?? json['url'] ?? json['content'] ?? '').toString(),
      title: (json['title'] ?? json['desc'] ?? '').toString(),
      folder: (json['folder'] ?? json['category'] ?? 'Общее').toString(),
    );
  }
}

class BackgroundArtPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final dotPaint = Paint()..color = Colors.white.withOpacity(0.03);
    const step = 36.0;
    for (double x = 24; x < size.width; x += step) {
      for (double y = 24; y < size.height; y += step) {
        canvas.drawCircle(Offset(x, y), 1.0, dotPaint);
      }
    }

    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = Colors.white.withOpacity(0.025);

    final center = Offset(size.width * 0.85, size.height * 0.78);
    canvas.drawCircle(center, 180, arcPaint);
    canvas.drawCircle(center, 310, arcPaint);
    canvas.drawCircle(center, 440, arcPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}



class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final TextEditingController _mainInput = TextEditingController();
  final TextEditingController _titleInput = TextEditingController();

  List<NoteItem> _items = [];
  List<String> _noteFolders = ['Общее', 'Идеи', 'Фильмы', 'Книги'];
  List<String> _linkFolders = ['Общее', 'Видео', 'Сервисы', 'Статьи'];

  bool _isLinkMode = false;
  String _selectedFolder = 'Общее';
  String? _copiedId;

  String get _savePath {
    final home = Platform.environment['HOME'] ?? '.';
    return '$home/.nan_notes.json';
  }

  List<String> get _currentFolders =>
      _isLinkMode ? _linkFolders : _noteFolders;

  List<NoteItem> get _filteredItems {
    return _items.where((item) {
      if (item.isLink != _isLinkMode) return false;
      if (_selectedFolder != 'Общее' && item.folder != _selectedFolder) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final f = File(_savePath);
      if (await f.exists()) {
        final raw = jsonDecode(await f.readAsString());
        if (raw is List) {
          setState(() {
            _items = raw
                .whereType<Map<String, dynamic>>()
                .map(NoteItem.fromJson)
                .toList();
          });
        } else if (raw is Map<String, dynamic>) {
          final list = raw['items'] ?? raw['notes'];
          if (list is List) {
            setState(() {
              _items = list
                  .whereType<Map<String, dynamic>>()
                  .map(NoteItem.fromJson)
                  .toList();
            });
          }
          if (raw['noteFolders'] is List) {
            _noteFolders = List<String>.from(raw['noteFolders'] as List);
          }
          if (raw['linkFolders'] is List) {
            _linkFolders = List<String>.from(raw['linkFolders'] as List);
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _save() async {
    try {
      final f = File(_savePath);
      await f.writeAsString(jsonEncode({
        'items': _items.map((e) => e.toJson()).toList(),
        'noteFolders': _noteFolders,
        'linkFolders': _linkFolders,
      }));
    } catch (_) {}
  }

  void _addItem() {
    final text = _mainInput.text.trim();
    if (text.isEmpty) return;
    final title = _titleInput.text.trim();

    setState(() {
      _items.insert(
        0,
        NoteItem(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          isLink: _isLinkMode,
          text: text,
          title: _isLinkMode ? title : '',
          folder: _selectedFolder,
        ),
      );
      _mainInput.clear();
      _titleInput.clear();
    });
    playSound('message-new-instant');
    _save();
  }

  Future<void> _copyItem(NoteItem item) async {
    await Clipboard.setData(ClipboardData(text: item.text));
    playSound('audio-volume-change');
    setState(() => _copiedId = item.id);
    Future.delayed(const Duration(milliseconds: 1100), () {
      if (mounted && _copiedId == item.id) {
        setState(() => _copiedId = null);
      }
    });
  }



  void _showFullNoteDialog(NoteItem item) {
    final folders = item.isLink ? _linkFolders : _noteFolders;
    final accent =
        NotesTheme.colorForFolder(item.folder, item.isLink, folders);
    playSound('audio-volume-change');

    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: NotesTheme.panel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: accent.withOpacity(0.22), width: 1.0),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 580, maxHeight: 540),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      iconForCategory(item.folder, item.isLink),
                      size: 18,
                      color: accent.withOpacity(0.85),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      item.folder,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.2,
                        color: accent.withOpacity(0.85),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Копировать текст',
                      icon: Icon(Icons.copy_rounded,
                          size: 19, color: accent.withOpacity(0.85)),
                      onPressed: () {
                        _copyItem(item);
                        Navigator.pop(ctx);
                      },
                    ),
                    IconButton(
                      tooltip: 'Закрыть',
                      icon: const Icon(Icons.close_rounded,
                          size: 20, color: NotesTheme.textDim),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: SingleChildScrollView(
                    child: SelectableText(
                      item.text,
                      style: const TextStyle(
                        fontSize: 16.5,
                        height: 1.6,
                        letterSpacing: 0.2,
                        fontWeight: FontWeight.w400,
                        color: NotesTheme.textMain,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showAddFolderDialog() async {
    final ctrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: NotesTheme.panel,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Новая папка',
          style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w500,
              color: NotesTheme.textMain),
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(fontSize: 15.5, color: NotesTheme.textMain),
          decoration: const InputDecoration(
            hintText: 'Название папки...',
            hintStyle: TextStyle(color: NotesTheme.textDim),
          ),
          onSubmitted: (val) => Navigator.pop(ctx, val.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена',
                style: TextStyle(color: NotesTheme.textDim)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: Text(
              'Создать',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: _isLinkMode ? NotesTheme.cyan : NotesTheme.amber,
              ),
            ),
          ),
        ],
      ),
    );

    if (name != null && name.isNotEmpty) {
      setState(() {
        final list = _currentFolders;
        if (!list.contains(name)) list.add(name);
        _selectedFolder = name;
      });
      _save();
    }
  }

  void _deleteFolder(String folder) {
    if (folder == 'Общее') return;
    setState(() {
      for (final item in _items) {
        if (item.isLink == _isLinkMode && item.folder == folder) {
          item.folder = 'Общее';
        }
      }
      _currentFolders.remove(folder);
      if (_selectedFolder == folder) {
        _selectedFolder = 'Общее';
      }
    });
    playSound('audio-volume-change');
    _save();
  }




  Widget _buildSidebar() {
    final notesCount = _items.where((e) => !e.isLink).length;
    final linksCount = _items.where((e) => e.isLink).length;

    Widget modeButton({
      required bool linkTab,
      required String label,
      required int count,
      required IconData icon,
    }) {
      final active = _isLinkMode == linkTab;
      final tabColor = linkTab ? NotesTheme.cyan : NotesTheme.amber;
      return Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (_isLinkMode == linkTab) return;
            setState(() {
              _isLinkMode = linkTab;
              _selectedFolder = 'Общее';
            });
            playSound('audio-volume-change');
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              color: active ? tabColor.withOpacity(0.14) : Colors.transparent,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                color: active ? tabColor.withOpacity(0.32) : Colors.transparent,
                width: 1.0,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: active ? tabColor.withOpacity(0.9) : NotesTheme.textDim,
                ),
                const SizedBox(height: 4),
                Text(
                  '$label · $count',
                  style: TextStyle(
                    fontSize: 12.5,
                    letterSpacing: 0.2,
                    fontWeight: active ? FontWeight.w500 : FontWeight.w400,
                    color: active ? NotesTheme.textMain : NotesTheme.textDim,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      width: 224,
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 16),
      decoration: BoxDecoration(
        color: NotesTheme.sidebar,
        border: Border(
          right: BorderSide(
            color: Colors.white.withOpacity(0.05),
            width: 1.0,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: NotesTheme.panel,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                modeButton(
                  linkTab: false,
                  label: 'Заметки',
                  count: notesCount,
                  icon: Icons.notes_rounded,
                ),
                const SizedBox(width: 4),
                modeButton(
                  linkTab: true,
                  label: 'Ссылки',
                  count: linksCount,
                  icon: Icons.link_rounded,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              children: [
                Text(
                  'КАТЕГОРИИ',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 1.0,
                    fontWeight: FontWeight.w500,
                    color: NotesTheme.textDim.withOpacity(0.8),
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: _showAddFolderDialog,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.add_rounded,
                      size: 18,
                      color: NotesTheme.textMain.withOpacity(0.8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              itemCount: _currentFolders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (_, idx) {
                final folder = _currentFolders[idx];
                final selected = _selectedFolder == folder;
                final fColor = NotesTheme.colorForFolder(
                    folder, _isLinkMode, _currentFolders);
                final canDelete = folder != 'Общее';
                final itemCount = _items
                    .where((e) =>
                        e.isLink == _isLinkMode &&
                        (folder == 'Общее' || e.folder == folder))
                    .length;

                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    setState(() => _selectedFolder = folder);
                    playSound('audio-volume-change');
                  },
                  onSecondaryTap:
                      canDelete ? () => _deleteFolder(folder) : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 11, vertical: 9),
                    decoration: BoxDecoration(
                      color: selected
                          ? fColor.withOpacity(0.14)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? fColor.withOpacity(0.32)
                            : Colors.transparent,
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          iconForCategory(folder, _isLinkMode),
                          size: 16,
                          color: fColor.withOpacity(0.85),
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            folder,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              letterSpacing: 0.2,
                              fontWeight:
                                  selected ? FontWeight.w500 : FontWeight.w400,
                              color: selected
                                  ? fColor.withOpacity(0.95)
                                  : NotesTheme.textMain.withOpacity(0.82),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        if (selected && canDelete)
                          GestureDetector(
                            onTap: () => _deleteFolder(folder),
                            child: Icon(
                              Icons.close_rounded,
                              size: 15,
                              color: fColor.withOpacity(0.8),
                            ),
                          )
                        else
                          Text(
                            '$itemCount',
                            style: TextStyle(
                              fontSize: 12,
                              color: NotesTheme.textDim.withOpacity(0.75),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildInputBar() {
    final accent = NotesTheme.colorForFolder(
        _selectedFolder, _isLinkMode, _currentFolders);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
      decoration: BoxDecoration(
        color: NotesTheme.panel,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: accent.withOpacity(0.16),
          width: 1.0,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isLinkMode) ...[
            TextField(
              controller: _titleInput,
              textInputAction: TextInputAction.next,
              style: const TextStyle(
                fontSize: 15.5,
                letterSpacing: 0.2,
                fontWeight: FontWeight.w400,
                color: NotesTheme.textMain,
              ),
              decoration: const InputDecoration(
                hintText: 'Описание ссылки...',
                hintStyle: TextStyle(color: NotesTheme.textDim),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
            Divider(height: 14, color: Colors.white.withOpacity(0.05)),
          ],
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _mainInput,
                  minLines: 1,
                  maxLines: _isLinkMode ? 1 : 4,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _addItem(),
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.45,
                    letterSpacing: 0.2,
                    fontWeight: FontWeight.w400,
                    color: NotesTheme.textMain,
                  ),
                  decoration: InputDecoration(
                    hintText: _isLinkMode
                        ? 'Вставьте ссылку в «$_selectedFolder»...'
                        : 'Новая заметка в «$_selectedFolder» (Enter — сохранить)...',
                    hintStyle: const TextStyle(color: NotesTheme.textDim),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Сохранить',
                onPressed: _addItem,
                icon: Icon(
                  Icons.arrow_upward_rounded,
                  color: accent.withOpacity(0.85),
                  size: 23,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }



  Widget _buildFlexCard(NoteItem item, double tileWidth) {
    final folders = item.isLink ? _linkFolders : _noteFolders;
    final accent =
        NotesTheme.colorForFolder(item.folder, item.isLink, folders);
    final canExpand = !item.isLink && item.isLong;
    final isCopied = _copiedId == item.id;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (item.isLink) {
          openUrlInBrowser(item.text);
        } else if (canExpand) {
          _showFullNoteDialog(item);
        } else {
          _copyItem(item);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: tileWidth,
        height: 148,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isCopied ? accent.withOpacity(0.12) : NotesTheme.panel,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isCopied
                ? accent.withOpacity(0.45)
                : accent.withOpacity(0.18),
            width: 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  iconForCategory(item.folder, item.isLink),
                  size: 15,
                  color: accent.withOpacity(0.85),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    isCopied ? 'Скопировано' : item.folder,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      letterSpacing: 0.2,
                      fontWeight: FontWeight.w500,
                      color: accent.withOpacity(0.85),
                    ),
                  ),
                ),
                if (canExpand)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Icon(
                      Icons.open_in_full_rounded,
                      size: 14,
                      color: accent.withOpacity(0.75),
                    ),
                  ),
                IconButton(
                  tooltip: 'Копировать',
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                  icon: Icon(
                    isCopied ? Icons.check_rounded : Icons.copy_rounded,
                    size: 16,
                    color: isCopied
                        ? accent.withOpacity(0.9)
                        : NotesTheme.textDim.withOpacity(0.75),
                  ),
                  onPressed: () => _copyItem(item),
                ),
                IconButton(
                  tooltip: 'Удалить',
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                  icon: Icon(
                    Icons.close_rounded,
                    size: 17,
                    color: NotesTheme.textDim.withOpacity(0.55),
                  ),
                  onPressed: () {
                    setState(() => _items.remove(item));
                    _save();
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (item.isLink) ...[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.title.isNotEmpty ? item.title : item.text,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15.5,
                        height: 1.4,
                        letterSpacing: 0.15,
                        fontWeight: FontWeight.w500,
                        color: NotesTheme.textMain.withOpacity(0.92),
                      ),
                    ),
                    if (item.title.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          letterSpacing: 0.15,
                          fontWeight: FontWeight.w400,
                          color: accent.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ] else ...[
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    item.text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15.5,
                      height: 1.45,
                      letterSpacing: 0.15,
                      fontWeight: FontWeight.w400,
                      color: NotesTheme.textMain.withOpacity(0.92),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    final visibleItems = _filteredItems;

    return Scaffold(
      body: CustomPaint(
        painter: BackgroundArtPainter(),
        child: SafeArea(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSidebar(),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildInputBar(),
                      const SizedBox(height: 18),
                      Expanded(
                        child: visibleItems.isEmpty
                            ? Center(
                                child: Text(
                                  _isLinkMode
                                      ? 'В этой папке пока нет ссылок'
                                      : 'В этой папке пока нет заметок',
                                  style: const TextStyle(
                                    fontSize: 15.5,
                                    letterSpacing: 0.2,
                                    fontWeight: FontWeight.w400,
                                    color: NotesTheme.textDim,
                                  ),
                                ),
                              )
                            : LayoutBuilder(
                                builder: (context, constraints) {
                                  const spacing = 14.0;
                                  final fullWidth = constraints.maxWidth;
                                  final cols =
                                      (fullWidth / 250).floor().clamp(1, 5);
                                  final tileWidth =
                                      (fullWidth - spacing * (cols - 1)) / cols;

                                  return SingleChildScrollView(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: Wrap(
                                      spacing: spacing,
                                      runSpacing: spacing,
                                      children: visibleItems
                                          .map((item) =>
                                              _buildFlexCard(item, tileWidth))
                                          .toList(),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

