import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const NanNotesApp());
}

// ==========================================
// ПАЛИТРА И ИКОНКИ ПРИЛОЖЕНИЯ
// ==========================================
class VibeTheme {
  static const Color bgMain = Color(0xFF0B0E14);
  static const Color bgSide = Color(0xFF111620);
  static const Color bgCard = Color(0xFF161C28);
  static const Color border = Color(0xFF252E3F);
  static const Color textMain = Color(0xFFF8FAFC);
  static const Color textMuted = Color(0xFF94A3B8);

  // Тёплый янтарно-оранжевый для заметок
  static const Color noteColor = Color(0xFFFBBF24);
  static const Color noteSecondary = Color(0xFFF97316);

  // Неоново-голубой для ссылок
  static const Color linkColor = Color(0xFF38BDF8);
  static const Color linkSecondary = Color(0xFF818CF8);

  static const double radius = 18.0;

  static const List<IconData> availableIcons = [
    Icons.movie_filter_rounded,
    Icons.lightbulb_rounded,
    Icons.auto_stories_rounded,
    Icons.music_note_rounded,
    Icons.code_rounded,
    Icons.star_rounded,
    Icons.rocket_launch_rounded,
    Icons.bookmark_rounded,
  ];
}

class NoteCategory {
  String name;
  String type; // 'note' или 'link'
  int iconIndex;

  NoteCategory({
    required this.name,
    required this.type,
    this.iconIndex = 0,
  });

  IconData get icon => VibeTheme
      .availableIcons[iconIndex.clamp(0, VibeTheme.availableIcons.length - 1)];

  Map<String, dynamic> toJson() => {
        'name': name,
        'type': type,
        'iconIndex': iconIndex,
      };

  factory NoteCategory.fromJson(Map<String, dynamic> json) => NoteCategory(
        name: json['name']?.toString() ?? 'Заметки',
        type: json['type'] == 'link' ? 'link' : 'note',
        iconIndex: (json['iconIndex'] is int) ? json['iconIndex'] as int : 0,
      );
}

class NoteItem {
  String id;
  String type; // 'note' или 'link'
  String title;
  String text;
  String category;

  NoteItem({
    required this.id,
    required this.type,
    this.title = '',
    required this.text,
    required this.category,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'title': title,
        'text': text,
        'category': category,
      };

  factory NoteItem.fromJson(Map<String, dynamic> json) => NoteItem(
        id: json['id']?.toString() ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        type: json['type'] == 'link' ? 'link' : 'note',
        title: json['title']?.toString() ?? '',
        text: json['text']?.toString() ?? json['content']?.toString() ?? '',
        category: json['category']?.toString() ?? 'Фильмы',
      );
}

class NanNotesApp extends StatelessWidget {
  const NanNotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NanNotes',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: VibeTheme.bgMain,
        cardColor: VibeTheme.bgCard,
        colorScheme: const ColorScheme.dark(
          primary: VibeTheme.linkColor,
          surface: VibeTheme.bgCard,
        ),
      ),
      home: const NotesHomeScreen(),
    );
  }
}



// ==========================================
// ВЕКТОРНЫЕ ИЛЛЮСТРАЦИИ (SVG-СТИЛЬ)
// ==========================================
class CardArtPainter extends CustomPainter {
  final bool isNote;
  final Color color;

  CardArtPainter({required this.isNote, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = color.withOpacity(0.11)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final fillPaint = Paint()
      ..color = color.withOpacity(0.05)
      ..style = PaintingStyle.fill;

    if (isNote) {
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width - 78, size.height - 78, 66, 66),
        const Radius.circular(14),
      );
      canvas.drawRRect(rect, fillPaint);
      canvas.drawRRect(rect, strokePaint);

      canvas.drawLine(
        Offset(size.width - 62, size.height - 54),
        Offset(size.width - 28, size.height - 54),
        strokePaint,
      );
      canvas.drawLine(
        Offset(size.width - 62, size.height - 40),
        Offset(size.width - 38, size.height - 40),
        strokePaint,
      );
    } else {
      final center = Offset(size.width - 36, size.height - 36);
      canvas.drawCircle(center, 34, fillPaint);
      canvas.drawCircle(center, 34, strokePaint);
      canvas.drawOval(
        Rect.fromCenter(center: center, width: 68, height: 26),
        strokePaint,
      );
      canvas.drawOval(
        Rect.fromCenter(center: center, width: 26, height: 68),
        strokePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CardArtPainter oldDelegate) =>
      oldDelegate.isNote != isNote || oldDelegate.color != color;
}

class EmptyBoardArtPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          VibeTheme.noteColor.withOpacity(0.18),
          VibeTheme.linkColor.withOpacity(0.10),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: 75));
    canvas.drawCircle(center, 75, glowPaint);

    // Левая карточка (заметка)
    canvas.save();
    canvas.translate(center.dx - 24, center.dy);
    canvas.rotate(-10 * math.pi / 180);
    final noteRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-28, -34, 56, 68),
      const Radius.circular(12),
    );
    canvas.drawRRect(
      noteRect,
      Paint()..color = VibeTheme.noteColor.withOpacity(0.18),
    );
    canvas.drawRRect(
      noteRect,
      Paint()
        ..color = VibeTheme.noteColor.withOpacity(0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.restore();

    // Правая карточка (ссылка)
    canvas.save();
    canvas.translate(center.dx + 24, center.dy + 4);
    canvas.rotate(10 * math.pi / 180);
    final linkRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-28, -34, 56, 68),
      const Radius.circular(12),
    );
    canvas.drawRRect(
      linkRect,
      Paint()..color = VibeTheme.linkColor.withOpacity(0.18),
    );
    canvas.drawRRect(
      linkRect,
      Paint()
        ..color = VibeTheme.linkColor.withOpacity(0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}



class NotesHomeScreen extends StatefulWidget {
  const NotesHomeScreen({super.key});

  @override
  State<NotesHomeScreen> createState() => _NotesHomeScreenState();
}

class _NotesHomeScreenState extends State<NotesHomeScreen> {
  List<NoteCategory> _categories = [
    NoteCategory(name: 'Фильмы', type: 'note', iconIndex: 0),
    NoteCategory(name: 'Идеи', type: 'note', iconIndex: 1),
    NoteCategory(name: 'Посмотреть', type: 'link', iconIndex: 6),
    NoteCategory(name: 'Сайты', type: 'link', iconIndex: 7),
  ];

  List<NoteItem> _items = [];
  String _selectedCat = 'Все';
  String _inputType = 'note'; // 'note' или 'link'
  String _inputCategory = 'Фильмы';

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _inputController = TextEditingController();

  String get _storagePath {
    final home = Platform.environment['HOME'] ?? '.';
    return '$home/.nan_notes.json';
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final file = File(_storagePath);
      if (await file.exists()) {
        final decoded = jsonDecode(await file.readAsString());
        if (decoded is Map<String, dynamic>) {
          final rawCats = decoded['categories'];
          final rawItems = decoded['items'];
          setState(() {
            if (rawCats is List && rawCats.isNotEmpty) {
              _categories = rawCats
                  .whereType<Map<String, dynamic>>()
                  .map((e) => NoteCategory.fromJson(e))
                  .toList();
            }
            if (rawItems is List) {
              _items = rawItems
                  .whereType<Map<String, dynamic>>()
                  .map((e) => NoteItem.fromJson(e))
                  .toList();
            }
            _syncInputCategory();
          });
        }
      }
    } catch (_) {}
  }

  void _syncInputCategory() {
    final matching = _categories.where((c) => c.type == _inputType).toList();
    if (matching.isEmpty) {
      _inputCategory = _inputType == 'note' ? 'Заметки' : 'Ссылки';
    } else if (!matching.any((c) => c.name == _inputCategory)) {
      _inputCategory = matching.first.name;
    }
  }

  Future<void> _saveData() async {
    try {
      final file = File(_storagePath);
      final data = {
        'categories': _categories.map((e) => e.toJson()).toList(),
        'items': _items.map((e) => e.toJson()).toList(),
      };
      await file.writeAsString(const JsonEncoder.withIndent('  ').convert(data));
    } catch (_) {}
  }

  void _showToast(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        width: 300,
        behavior: SnackBarBehavior.floating,
        backgroundColor: VibeTheme.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withOpacity(0.5)),
        ),
        duration: const Duration(milliseconds: 1600),
        content: Text(
          msg,
          textAlign: TextAlign.center,
          style: const TextStyle(color: VibeTheme.textMain, fontSize: 15),
        ),
      ),
    );
  }

  Future<void> _addQuickItem() async {
    final mainText = _inputController.text.trim();
    final titleText = _titleController.text.trim();

    if (_inputType == 'note' && mainText.isEmpty) return;
    if (_inputType == 'link' && mainText.isEmpty) {
      _showToast('Введите адрес ссылки', VibeTheme.linkColor);
      return;
    }

    setState(() {
      _items.insert(
        0,
        NoteItem(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          type: _inputType,
          title: _inputType == 'link'
              ? (titleText.isNotEmpty ? titleText : mainText)
              : '',
          text: mainText,
          category: _inputCategory,
        ),
      );
      _inputController.clear();
      _titleController.clear();
    });
    await _saveData();
  }

  Future<void> _openUrl(String rawUrl) async {
    String url = rawUrl.trim();
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    await Process.start('xdg-open', [url], mode: ProcessStartMode.detached);
    _showToast('Открыто в браузере', VibeTheme.linkColor);
  }

  Future<void> _copyText(String text, Color color) async {
    await Clipboard.setData(ClipboardData(text: text));
    _showToast('Скопировано в буфер', color);
  }




  Future<void> _createCategoryDialog(String type) async {
    final controller = TextEditingController();
    final isNote = type == 'note';
    final color = isNote ? VibeTheme.noteColor : VibeTheme.linkColor;
    int pickedIconIndex = isNote ? 0 : 6;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: VibeTheme.bgCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(VibeTheme.radius),
            side: BorderSide(color: color.withOpacity(0.45)),
          ),
          title: Row(
            children: [
              Icon(VibeTheme.availableIcons[pickedIconIndex], color: color),
              const SizedBox(width: 10),
              Text(
                isNote ? 'Новая папка заметок' : 'Новая папка ссылок',
                style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: controller,
                  autofocus: true,
                  style: const TextStyle(fontSize: 16),
                  decoration: InputDecoration(
                    hintText: isNote
                        ? 'Например: Фильмы, Цитаты...'
                        : 'Например: Статьи, Музыка...',
                    filled: true,
                    fillColor: VibeTheme.bgMain,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Выберите иконку:',
                  style: TextStyle(color: VibeTheme.textMuted, fontSize: 13),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(VibeTheme.availableIcons.length, (i) {
                    final selected = i == pickedIconIndex;
                    return InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => setDialogState(() => pickedIconIndex = i),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: selected
                              ? color.withOpacity(0.2)
                              : VibeTheme.bgMain,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selected ? color : VibeTheme.border,
                            width: selected ? 1.5 : 1,
                          ),
                        ),
                        child: Icon(
                          VibeTheme.availableIcons[i],
                          size: 20,
                          color: selected ? color : VibeTheme.textMuted,
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Отмена',
                style: TextStyle(color: VibeTheme.textMuted, fontSize: 15),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.black,
              ),
              onPressed: () async {
                final name = controller.text.trim();
                if (name.isNotEmpty &&
                    !_categories.any(
                        (c) => c.name.toLowerCase() == name.toLowerCase())) {
                  setState(() {
                    _categories.add(NoteCategory(
                      name: name,
                      type: type,
                      iconIndex: pickedIconIndex,
                    ));
                    _selectedCat = name;
                    _inputType = type;
                    _inputCategory = name;
                  });
                  await _saveData();
                }
                if (mounted) Navigator.pop(context);
              },
              child: const Text(
                'Создать',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }




  Widget _buildSidebar() {
    final noteCats = _categories.where((c) => c.type == 'note').toList();
    final linkCats = _categories.where((c) => c.type == 'link').toList();

    return Container(
      width: 245,
      decoration: const BoxDecoration(
        color: VibeTheme.bgSide,
        border: Border(right: BorderSide(color: VibeTheme.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Градиентный логотип
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 22),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [VibeTheme.noteColor, VibeTheme.linkColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_mosaic_rounded,
                    color: Colors.black,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'NanNotes',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: VibeTheme.textMain,
                  ),
                ),
              ],
            ),
          ),

          _navItem(
            title: 'Все записи',
            icon: Icons.grid_view_rounded,
            color: VibeTheme.textMain,
            isSelected: _selectedCat == 'Все',
            onTap: () => setState(() => _selectedCat = 'Все'),
          ),

          const SizedBox(height: 22),

          Expanded(
            child: ListView(
              children: [
                // СЕКЦИЯ ЗАМЕТОК
                _sectionTitle(
                  'ЗАМЕТКИ',
                  VibeTheme.noteColor,
                  () => _createCategoryDialog('note'),
                ),
                const SizedBox(height: 6),
                ...noteCats.map((cat) => _navItem(
                      title: cat.name,
                      icon: cat.icon,
                      color: VibeTheme.noteColor,
                      isSelected: _selectedCat == cat.name,
                      onTap: () => setState(() {
                        _selectedCat = cat.name;
                        _inputType = 'note';
                        _inputCategory = cat.name;
                      }),
                      onDelete: () async {
                        setState(() {
                          _categories.remove(cat);
                          if (_selectedCat == cat.name) _selectedCat = 'Все';
                          _syncInputCategory();
                        });
                        await _saveData();
                      },
                    )),

                const SizedBox(height: 22),

                // СЕКЦИЯ ССЫЛОК
                _sectionTitle(
                  'ССЫЛКИ',
                  VibeTheme.linkColor,
                  () => _createCategoryDialog('link'),
                ),
                const SizedBox(height: 6),
                ...linkCats.map((cat) => _navItem(
                      title: cat.name,
                      icon: cat.icon,
                      color: VibeTheme.linkColor,
                      isSelected: _selectedCat == cat.name,
                      onTap: () => setState(() {
                        _selectedCat = cat.name;
                        _inputType = 'link';
                        _inputCategory = cat.name;
                      }),
                      onDelete: () async {
                        setState(() {
                          _categories.remove(cat);
                          if (_selectedCat == cat.name) _selectedCat = 'Все';
                          _syncInputCategory();
                        });
                        await _saveData();
                      },
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text, Color color, VoidCallback onAdd) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
              color: color,
            ),
          ),
          const Spacer(),
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onAdd,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(Icons.add_rounded, size: 20, color: color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem({
    required String title,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
    VoidCallback? onDelete,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, size: 19, color: isSelected ? color : VibeTheme.textMuted),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? VibeTheme.textMain : VibeTheme.textMuted,
                  ),
                ),
              ),
              if (isSelected && onDelete != null)
                InkWell(
                  onTap: onDelete,
                  child: const Icon(Icons.close, size: 16, color: Colors.redAccent),
                ),
            ],
          ),
        ),
      ),
    );
  }




  @override
  Widget build(BuildContext context) {
    final visibleItems = _selectedCat == 'Все'
        ? _items
        : _items.where((i) => i.category == _selectedCat).toList();

    final isNoteMode = _inputType == 'note';
    final activeColor = isNoteMode ? VibeTheme.noteColor : VibeTheme.linkColor;
    final secondaryColor =
        isNoteMode ? VibeTheme.noteSecondary : VibeTheme.linkSecondary;

    final matchingCats = _categories.where((c) => c.type == _inputType).toList();
    final dropdownItems = matchingCats.isNotEmpty
        ? matchingCats.map((c) => c.name).toList()
        : [isNoteMode ? 'Заметки' : 'Ссылки'];
    final safeCategory = dropdownItems.contains(_inputCategory)
        ? _inputCategory
        : dropdownItems.first;

    return Scaffold(
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedCat == 'Все' ? 'Все записи' : _selectedCat,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: VibeTheme.textMain,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // ПАНЕЛЬ БЫСТРОГО ВВОДА С ГРАДИЕНТНОЙ ПОДСВЕТКОЙ
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: VibeTheme.bgCard,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: activeColor.withOpacity(0.45),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: activeColor.withOpacity(0.08),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            // Переключатель типа: Заметка / Ссылка
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: VibeTheme.bgMain,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  _typeSwitchBtn(
                                    label: 'Заметка',
                                    icon: Icons.edit_note_rounded,
                                    color: VibeTheme.noteColor,
                                    active: isNoteMode,
                                    onTap: () => setState(() {
                                      _inputType = 'note';
                                      _syncInputCategory();
                                    }),
                                  ),
                                  _typeSwitchBtn(
                                    label: 'Ссылка',
                                    icon: Icons.link_rounded,
                                    color: VibeTheme.linkColor,
                                    active: !isNoteMode,
                                    onTap: () => setState(() {
                                      _inputType = 'link';
                                      _syncInputCategory();
                                    }),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Выбор категории прямо при создании
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: VibeTheme.bgMain,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: activeColor.withOpacity(0.35),
                                ),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: safeCategory,
                                  dropdownColor: VibeTheme.bgCard,
                                  icon: Icon(Icons.keyboard_arrow_down_rounded,
                                      color: activeColor),
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: activeColor,
                                  ),
                                  items: dropdownItems
                                      .map((cat) => DropdownMenuItem(
                                            value: cat,
                                            child: Text(cat),
                                          ))
                                      .toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() => _inputCategory = val);
                                    }
                                  },
                                ),
                              ),
                            ),
                            const Spacer(),

                            // Градиентная кнопка добавления
                            InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: _addQuickItem,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 22,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [activeColor, secondaryColor],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Добавить',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),


                        const SizedBox(height: 10),
                        const Divider(height: 1, color: VibeTheme.border),
                        const SizedBox(height: 8),

                        // Поля ввода (1 поле для заметки, 2 поля для ссылки)
                        if (isNoteMode)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: TextField(
                              controller: _inputController,
                              onSubmitted: (_) => _addQuickItem(),
                              style: const TextStyle(
                                fontSize: 17,
                                color: VibeTheme.textMain,
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Черкануть заметку или название фильма...',
                                hintStyle: TextStyle(
                                  fontSize: 16,
                                  color: VibeTheme.textMuted,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: TextField(
                                    controller: _titleController,
                                    onSubmitted: (_) => _addQuickItem(),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: VibeTheme.textMain,
                                    ),
                                    decoration: const InputDecoration(
                                      hintText: 'Описание / название ссылки...',
                                      hintStyle: TextStyle(
                                        fontSize: 15,
                                        color: VibeTheme.textMuted,
                                      ),
                                      border: InputBorder.none,
                                      isDense: true,
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 24,
                                  color: VibeTheme.border,
                                  margin: const EdgeInsets.symmetric(horizontal: 12),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: TextField(
                                    controller: _inputController,
                                    onSubmitted: (_) => _addQuickItem(),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: VibeTheme.linkColor,
                                    ),
                                    decoration: const InputDecoration(
                                      hintText: 'Вставьте URL (https://...)',
                                      hintStyle: TextStyle(
                                        fontSize: 15,
                                        color: VibeTheme.textMuted,
                                      ),
                                      border: InputBorder.none,
                                      isDense: true,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),


                  // СПИСОК КАРТОЧЕК С ВЕКТОРНЫМ ФОНОМ
                  Expanded(
                    child: visibleItems.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CustomPaint(
                                  size: const Size(150, 120),
                                  painter: EmptyBoardArtPainter(),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Здесь пока чисто',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: VibeTheme.textMain,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Черканите короткую заметку или сохраните ссылку в панели сверху',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: VibeTheme.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.only(bottom: 24),
                            gridDelegate:
                                const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 360,
                              mainAxisExtent: 165,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            itemCount: visibleItems.length,
                            itemBuilder: (context, index) {
                              final item = visibleItems[index];
                              final isNote = item.type == 'note';
                              final color = isNote
                                  ? VibeTheme.noteColor
                                  : VibeTheme.linkColor;

                              final catObj = _categories.firstWhere(
                                (c) => c.name == item.category,
                                orElse: () => NoteCategory(
                                  name: item.category,
                                  type: item.type,
                                  iconIndex: isNote ? 0 : 6,
                                ),
                              );

                              return InkWell(
                                borderRadius:
                                    BorderRadius.circular(VibeTheme.radius),
                                onTap: () {
                                  if (isNote) {
                                    _copyText(item.text, color);
                                  } else {
                                    _openUrl(item.text);
                                  }
                                },
                                child: ClipRRect(
                                  borderRadius:
                                      BorderRadius.circular(VibeTheme.radius),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: VibeTheme.bgCard,
                                      borderRadius: BorderRadius.circular(
                                          VibeTheme.radius),
                                      border: Border.all(
                                        color: color.withOpacity(0.32),
                                        width: 1.3,
                                      ),
                                    ),
                                    child: CustomPaint(
                                      painter: CardArtPainter(
                                        isNote: isNote,
                                        color: color,
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(18),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // Верхняя строка: иконка и название папки + кнопки
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 10,
                                                    vertical: 5,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        color.withOpacity(0.15),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(catObj.icon,
                                                          size: 15,
                                                          color: color),
                                                      const SizedBox(width: 6),
                                                      Text(
                                                        item.category,
                                                        style: TextStyle(
                                                          fontSize: 13,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: color,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const Spacer(),


                                                if (!isNote)
                                                  IconButton(
                                                    tooltip:
                                                        'Копировать ссылку',
                                                    constraints:
                                                        const BoxConstraints(),
                                                    padding:
                                                        const EdgeInsets.all(4),
                                                    icon: const Icon(
                                                      Icons.copy_rounded,
                                                      size: 18,
                                                      color:
                                                          VibeTheme.textMuted,
                                                    ),
                                                    onPressed: () => _copyText(
                                                        item.text, color),
                                                  ),
                                                const SizedBox(width: 4),
                                                IconButton(
                                                  tooltip: 'Удалить',
                                                  constraints:
                                                      const BoxConstraints(),
                                                  padding:
                                                      const EdgeInsets.all(4),
                                                  icon: const Icon(
                                                    Icons.close_rounded,
                                                    size: 19,
                                                    color: VibeTheme.textMuted,
                                                  ),
                                                  onPressed: () async {
                                                    setState(() =>
                                                        _items.remove(item));
                                                    await _saveData();
                                                  },
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),

                                            // Содержимое карточки
                                            if (isNote)
                                              Expanded(
                                                child: Text(
                                                  item.text,
                                                  maxLines: 3,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontSize: 17,
                                                    height: 1.35,
                                                    fontWeight: FontWeight.w500,
                                                    color: VibeTheme.textMain,
                                                  ),
                                                ),
                                              )
                                            else ...[
                                              Text(
                                                item.title,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 17,
                                                  fontWeight: FontWeight.w600,
                                                  color: VibeTheme.textMain,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons
                                                        .open_in_new_rounded,
                                                    size: 15,
                                                    color: color,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Expanded(
                                                    child: Text(
                                                      item.text,
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color: color,
                                                        decoration:
                                                            TextDecoration
                                                                .underline,
                                                        decorationColor: color
                                                            .withOpacity(0.5),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
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
    );
  }

  Widget _typeSwitchBtn({
    required String label,
    required IconData icon,
    required Color color,
    required bool active,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: active ? color.withOpacity(0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, size: 19, color: active ? color : VibeTheme.textMuted),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: active ? FontWeight.bold : FontWeight.normal,
                color: active ? color : VibeTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

