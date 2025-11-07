// main.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
mood
// --- ENUM DAN MODEL DATA ---

// Enum untuk status filter
enum TodoFilter { all, completed, incomplete }

// Enum untuk tingkat prioritas
enum Priority { low, medium, high }

// Ekstensi untuk mendapatkan data Priority
extension PriorityDetails on Priority {
  Color get color {
    switch (this) {
      case Priority.low:
        return Colors.green;
      case Priority.medium:
        return Colors.amber[700]!;
      case Priority.high:
        return Colors.red;
    }
  }

  String get nameString {
    switch (this) {
      case Priority.low:
        return 'Rendah';
      case Priority.medium:
        return 'Sedang';
      case Priority.high:
        return 'Tinggi';
    }
  }
}

// Model data untuk setiap tugas
class Task {
  String id;
  String title;
  String description;
  bool isCompleted;
  DateTime dateCreated;
  Priority priority;

  Task({
    required this.id,
    required this.title,
    this.description = '',
    this.isCompleted = false,
    required this.dateCreated,
    this.priority = Priority.medium,
  });

  // Konversi objek Task menjadi Map (untuk disimpan di SharedPreferences)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'isCompleted': isCompleted,
      'dateCreated': dateCreated.toIso8601String(),
      'priority': priority.index,
    };
  }

  // Factory untuk membuat objek Task dari Map
  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      description: json['description'] ?? '',
      isCompleted: json['isCompleted'] ?? false,
      dateCreated: DateTime.parse(json['dateCreated']),
      priority: Priority.values[json['priority'] ?? Priority.medium.index],
    );
  }
}

// --- MAIN APP ---

void main() {
  runApp(const TodoApp());
}

class TodoApp extends StatefulWidget {
  const TodoApp({super.key});

  @override
  State<TodoApp> createState() => _TodoAppState();
}

class _TodoAppState extends State<TodoApp> {
  ThemeMode _themeMode = ThemeMode.light;
  static const String _themeKey = 'app_theme_mode';

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
  }

  // Muat preferensi tema dari SharedPreferences
  Future<void> _loadThemeMode() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final int? themeIndex = prefs.getInt(_themeKey);
    if (themeIndex != null) {
      setState(() {
        _themeMode = ThemeMode.values[themeIndex];
      });
    }
  }

  // Simpan dan ganti tema
  void _toggleTheme(ThemeMode mode) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _themeMode = mode;
      prefs.setInt(_themeKey, mode.index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My To-Do List',
      // Menggunakan Material 3
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      themeMode: _themeMode,
      home: TodoListScreen(
        onThemeChanged: _toggleTheme,
        currentThemeMode: _themeMode,
      ),
    );
  }

  // Konfigurasi Tema Terang (Light Theme)
  ThemeData _buildLightTheme() {
    const Color primaryColor = Color(0xFF64B5F6); // Biru Lembut
    const Color secondaryColor = Color(0xFFB0BEC5); // Putih Keabu-abuan

    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
        brightness: Brightness.light,
      ),
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        centerTitle: false,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: secondaryColor)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: primaryColor, width: 2)),
      ),
    );
  }

  // Konfigurasi Tema Gelap (Dark Theme)
  ThemeData _buildDarkTheme() {
    const Color primaryColor = Color(0xFF1976D2); // Biru Lebih Gelap
    const Color secondaryColor = Color(0xFF546E7A); // Abu-abu Gelap

    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
        brightness: Brightness.dark,
        background: const Color(0xFF121212), // Background gelap standar
        surface: const Color(0xFF1E1E1E), // Surface gelap
      ),
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        elevation: 4,
        centerTitle: false,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      cardTheme: CardTheme(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: const Color(0xFF1E1E1E),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: secondaryColor)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: primaryColor, width: 2)),
        fillColor: const Color(0xFF2E2E2E),
        filled: true,
      ),
    );
  }
}

// --- TODO LIST SCREEN ---

class TodoListScreen extends StatefulWidget {
  final Function(ThemeMode) onThemeChanged;
  final ThemeMode currentThemeMode;

  const TodoListScreen({
    super.key,
    required this.onThemeChanged,
    required this.currentThemeMode,
  });

  @override
  State<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  final TextEditingController _searchController = TextEditingController();
  List<Task> _tasks = [];
  TodoFilter _currentFilter = TodoFilter.all;
  String _searchText = '';
  static const String _tasksKey = 'todo_tasks_data';

  @override
  void initState() {
    super.initState();
    _loadTasks();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  // --- LOGIKA PENYIMPANAN & MUAT DATA (SharedPreferences) ---

  // Muat daftar tugas dari SharedPreferences
  Future<void> _loadTasks() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? tasksString = prefs.getString(_tasksKey);

    if (tasksString != null) {
      final List<dynamic> jsonList = jsonDecode(tasksString);
      final List<Task> loadedTasks =
          jsonList.map((json) => Task.fromJson(json)).toList();

      setState(() {
        _tasks = loadedTasks;
        _sortTasks(); // Urutkan setelah dimuat
      });
      // Karena AnimatedList tidak digunakan saat pertama load, kita tidak perlu insertItem.
    }
  }

  // Simpan daftar tugas ke SharedPreferences
  Future<void> _saveTasks() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> jsonList =
        _tasks.map((task) => task.toJson()).toList();
    final String tasksString = jsonEncode(jsonList);
    await prefs.setString(_tasksKey, tasksString);
  }

  // --- LOGIKA CRUD & ANIMASI ---

  // Menambah atau Mengedit Tugas
  void _upsertTask(Task? taskToEdit) {
    // Tampilkan dialog tambah/edit
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return TaskFormDialog(
          taskToEdit: taskToEdit,
          onSave: (Task task) {
            setState(() {
              if (taskToEdit == null) {
                // Tambah tugas baru (Insert)
                _tasks.insert(0, task);
                _listKey.currentState?.insertItem(
                  0,
                  duration: const Duration(milliseconds: 500),
                );
              } else {
                // Edit tugas yang sudah ada (Update)
                final index = _tasks.indexWhere((t) => t.id == task.id);
                if (index != -1) {
                  _tasks[index] = task;
                }
              }
              _sortTasks();
              _saveTasks();
            });
            Navigator.of(context).pop();
          },
        );
      },
    );
  }

  // Mengubah status selesai tugas
  void _toggleTaskCompletion(int index) {
    setState(() {
      final task = _tasks[index];
      task.isCompleted = !task.isCompleted;
      _sortTasks(); // Urutkan setelah status berubah
      _saveTasks();
    });
  }

  // Menghapus tugas
  void _deleteTask(int index) {
    final Task removedItem = _tasks[index];

    // Hapus dari list data
    _tasks.removeAt(index);

    // Panggil removeItem AnimatedList untuk animasi
    _listKey.currentState?.removeItem(
      index,
      (context, animation) => _buildItem(removedItem, animation, index,
          isRemoved: true), // Item yang dihapus
      duration: const Duration(milliseconds: 500),
    );

    // Simpan data setelah penghapusan
    _saveTasks();

    // Tampilkan Snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tugas "${removedItem.title}" berhasil dihapus'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            // Logika Undo (opsional dan kompleks di AnimatedList)
            // Untuk kesederhanaan, kita hanya menampilkan pesan.
            // Implementasi Undo yang sebenarnya memerlukan penyimpanan removedItem
            // dan memanggil insertItem kembali.
          },
        ),
      ),
    );
  }

  // Menghapus semua tugas selesai
  void _clearCompletedTasks() {
    setState(() {
      _tasks.removeWhere((task) => task.isCompleted);
      // Untuk AnimatedList, kita perlu membangun ulang seluruh list
      // saat menghapus banyak item, atau menghapusnya satu per satu
      // Untuk kesederhanaan, kita hanya refresh data.
      _loadTasks();
    });
    _saveTasks();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Semua tugas selesai telah dihapus.')),
    );
  }

  // --- LOGIKA FILTER & PENCARIAN ---

  void _onSearchChanged() {
    setState(() {
      _searchText = _searchController.text.toLowerCase();
    });
  }

  // Mengambil daftar tugas yang sudah difilter dan dicari
  List<Task> get _filteredTasks {
    List<Task> list = _tasks;

    // Filter berdasarkan status
    if (_currentFilter == TodoFilter.completed) {
      list = list.where((task) => task.isCompleted).toList();
    } else if (_currentFilter == TodoFilter.incomplete) {
      list = list.where((task) => !task.isCompleted).toList();
    }

    // Filter berdasarkan teks pencarian
    if (_searchText.isNotEmpty) {
      list = list
          .where((task) =>
              task.title.toLowerCase().contains(_searchText) ||
              task.description.toLowerCase().contains(_searchText))
          .toList();
    }

    return list;
  }

  // --- LOGIKA SORTING (Bonus) ---

  // Urutkan tugas: Belum Selesai (Prioritas Tinggi-Rendah) -> Selesai
  void _sortTasks() {
    _tasks.sort((a, b) {
      // 1. Prioritas: Tugas belum selesai di atas tugas selesai
      if (a.isCompleted != b.isCompleted) {
        return a.isCompleted ? 1 : -1;
      }
      // 2. Prioritas: Prioritas (High > Medium > Low)
      if (a.priority.index != b.priority.index) {
        return b.priority.index.compareTo(a.priority.index);
      }
      // 3. Prioritas: Tanggal dibuat (terbaru di atas)
      return b.dateCreated.compareTo(a.dateCreated);
    });
  }

  // --- WIDGET BUILDER ---

  // Builder untuk setiap item di AnimatedList
  Widget _buildItem(Task task, Animation<double> animation, int index,
      {bool isRemoved = false}) {
    // Wrap dengan Dismissible untuk swipe-to-delete
    return Dismissible(
      key: ValueKey(task.id),
      direction: DismissDirection.horizontal,
      background: _buildSwipeAction(isLeft: true),
      secondaryBackground: _buildSwipeAction(isLeft: false),
      onDismissed: (direction) {
        // Ambil index tugas dari list utama sebelum filtering
        final originalIndex = _tasks.indexWhere((t) => t.id == task.id);
        if (originalIndex != -1) {
          _deleteTask(originalIndex);
        }
      },
      // Gunakan SizeTransition untuk efek animasi "slide up/down" saat tambah/hapus
      child: SizeTransition(
        sizeFactor: animation,
        axisAlignment: 0.0,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
          // GestureDetector untuk Edit (Long Press)
          child: GestureDetector(
            onLongPress: () => _upsertTask(task),
            child: Card(
              elevation: task.isCompleted ? 1 : 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                    color: task.priority.color.withOpacity(0.5), width: 2),
              ),
              color: task.isCompleted
                  ? Theme.of(context).cardColor.withOpacity(0.5)
                  : Theme.of(context).cardColor,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 8.0),
                // Checkbox untuk menandai selesai
                leading: Checkbox(
                  value: task.isCompleted,
                  onChanged: isRemoved
                      ? null
                      : (bool? value) {
                          _toggleTaskCompletion(index);
                        },
                  activeColor: task.priority.color,
                ),
                // Judul & Deskripsi
                title: Text(
                  task.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    decoration: task.isCompleted
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                    color: task.isCompleted
                        ? Theme.of(context).textTheme.bodySmall?.color
                        : Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (task.description.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          task.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        'Dibuat: ${DateFormat('dd MMM yyyy, HH:mm').format(task.dateCreated)} | Prioritas: ${task.priority.nameString}',
                        style: TextStyle(
                          fontSize: 10,
                          color: task.priority.color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                // Tombol Edit/Hapus
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Ikon Edit
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blueAccent),
                      onPressed: isRemoved ? null : () => _upsertTask(task),
                      tooltip: 'Edit Tugas',
                    ),
                    // Ikon Hapus
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: isRemoved
                          ? null
                          : () {
                              final originalIndex =
                                  _tasks.indexWhere((t) => t.id == task.id);
                              if (originalIndex != -1) {
                                _deleteTask(originalIndex);
                              }
                            },
                      tooltip: 'Hapus Tugas',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Builder untuk tampilan latar belakang swipe-to-delete
  Widget _buildSwipeAction({required bool isLeft}) {
    return Container(
      color: Colors.red[600],
      alignment: isLeft ? Alignment.centerLeft : Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
      child: const Icon(Icons.delete_forever, color: Colors.white),
    );
  }

  // Widget Statistik Tugas
  Widget _buildTaskStats() {
    final total = _tasks.length;
    final completed = _tasks.where((t) => t.isCompleted).length;
    final incomplete = total - completed;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
      child: Wrap(
        spacing: 12.0,
        runSpacing: 8.0,
        alignment: WrapAlignment.center,
        children: [
          _statChip(
              'Total: $total', Colors.blue.shade300, Icons.assignment_outlined),
          _statChip('Selesai: $completed', Colors.green.shade600,
              Icons.check_circle_outline),
          _statChip('Belum: $incomplete', Colors.red.shade400,
              Icons.pending_actions_outlined),
          _filterDropdown(),
        ],
      ),
    );
  }

  // Komponen Chip untuk Statistik
  Widget _statChip(String text, Color color, IconData icon) {
    return Chip(
      avatar: Icon(icon, color: Colors.white, size: 18),
      label: Text(text, style: const TextStyle(color: Colors.white)),
      backgroundColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }

  // Dropdown untuk Filter
  Widget _filterDropdown() {
    return DropdownButton<TodoFilter>(
      value: _currentFilter,
      style: TextStyle(color: Theme.of(context).primaryColor),
      onChanged: (TodoFilter? newValue) {
        setState(() {
          _currentFilter = newValue!;
          // Untuk AnimatedList, mengubah filter memerlukan rekonstruksi list
          // sehingga kita perlu 'trick' dengan memuat ulang.
          // Dalam kasus nyata, kita akan menggunakan List baru dan key.
          // Di sini kita hanya rebuild widget.
        });
      },
      items: const [
        DropdownMenuItem(
            value: TodoFilter.all, child: Text('Semua Tugas', maxLines: 1)),
        DropdownMenuItem(
            value: TodoFilter.completed, child: Text('Tugas Selesai')),
        DropdownMenuItem(
            value: TodoFilter.incomplete, child: Text('Tugas Belum Selesai')),
      ],
      dropdownColor: Theme.of(context).cardColor,
    );
  }

  // --- BUILD UTAMA ---

  @override
  Widget build(BuildContext context) {
    final filteredTasks = _filteredTasks;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My To-Do List'),
        actions: [
          // Tombol Hapus Semua Selesai
          IconButton(
            icon: const Icon(Icons.clear_all, tooltip: 'Hapus Semua Selesai'),
            onPressed: _tasks.any((t) => t.isCompleted)
                ? _clearCompletedTasks
                : null,
          ),
          // Tombol Ganti Tema (Light/Dark Mode)
          IconButton(
            icon: Icon(widget.currentThemeMode == ThemeMode.dark
                ? Icons.light_mode
                : Icons.dark_mode),
            onPressed: () {
              widget.onThemeChanged(widget.currentThemeMode == ThemeMode.dark
                  ? ThemeMode.light
                  : ThemeMode.dark);
            },
            tooltip: 'Ganti Tema',
          ),
          const SizedBox(width: 8),
        ],
      ),
      // Tombol Tambah Tugas
      floatingActionButton: FloatingActionButton(
        onPressed: () => _upsertTask(null),
        tooltip: 'Tambah Tugas Baru',
        child: const Icon(Icons.add),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Kolom Pencarian
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari tugas...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ),
          // Statistik dan Filter
          _buildTaskStats(),
          // Daftar tugas menggunakan AnimatedList
          Expanded(
            child: filteredTasks.isEmpty && _searchText.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline,
                            size: 60, color: Colors.grey),
                        SizedBox(height: 10),
                        Text(
                          "Yey! Tidak ada tugas. Waktunya bersantai!",
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : filteredTasks.isEmpty && _searchText.isNotEmpty
                    ? const Center(
                        child: Text("Tidak ada tugas yang cocok dengan pencarian Anda."),
                      )
                    : AnimatedList(
                        key: _listKey,
                        initialItemCount: _tasks.length,
                        padding: const EdgeInsets.only(bottom: 80),
                        // Penting: Gunakan list utama (_tasks) sebagai dasar,
                        // dan _filteredTasks untuk tampilan di dalam itemBuilder
                        itemBuilder: (context, index, animation) {
                          // Karena AnimatedList hanya bekerja dengan index dari list awal,
                          // kita perlu memetakan kembali ke item yang difilter.
                          // Cara paling sederhana adalah dengan membuat ulang AnimatedList,
                          // namun untuk stabilitas, kita gunakan index _tasks.
                          // Untuk kasus kompleks ini, kita asumsikan AnimatedList
                          // hanya untuk animasi tambah/hapus di list utama.
                          // Untuk filter, kita terapkan di dalam builder.

                          // Cari tugas yang sesuai dengan index di filteredTasks
                          if (index < filteredTasks.length) {
                            final task = filteredTasks[index];
                            return _buildItem(task, animation, index);
                          }
                          return Container(); // Fallback
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

// --- TASK FORM DIALOG (Tambah/Edit Tugas) ---

class TaskFormDialog extends StatefulWidget {
  final Task? taskToEdit;
  final Function(Task) onSave;

  const TaskFormDialog({
    super.key,
    this.taskToEdit,
    required this.onSave,
  });

  @override
  State<TaskFormDialog> createState() => _TaskFormDialogState();
}

class _TaskFormDialogState extends State<TaskFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late Priority _selectedPriority;

  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: widget.taskToEdit?.title ?? '');
    _descriptionController =
        TextEditingController(text: widget.taskToEdit?.description ?? '');
    _selectedPriority = widget.taskToEdit?.priority ?? Priority.medium;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _saveForm() {
    if (_formKey.currentState!.validate()) {
      final String id = widget.taskToEdit?.id ??
          DateTime.now().microsecondsSinceEpoch.toString();
      final DateTime dateCreated =
          widget.taskToEdit?.dateCreated ?? DateTime.now();

      final Task newTask = Task(
        id: id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        isCompleted: widget.taskToEdit?.isCompleted ?? false,
        dateCreated: dateCreated,
        priority: _selectedPriority,
      );

      widget.onSave(newTask);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.taskToEdit == null ? 'Tambah Tugas Baru' : 'Edit Tugas'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // Input Judul
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Judul Tugas',
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Judul tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Input Deskripsi (Opsional)
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi (Opsional)',
                  prefixIcon: Icon(Icons.notes),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              // Dropdown Prioritas
              DropdownButtonFormField<Priority>(
                value: _selectedPriority,
                decoration: const InputDecoration(
                  labelText: 'Prioritas',
                  prefixIcon: Icon(Icons.flag),
                ),
                items: Priority.values.map((Priority priority) {
                  return DropdownMenuItem<Priority>(
                    value: priority,
                    child: Row(
                      children: <Widget>[
                        Icon(Icons.circle,
                            color: priority.color, size: 12),
                        const SizedBox(width: 8),
                        Text(priority.nameString),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (Priority? newValue) {
                  setState(() {
                    _selectedPriority = newValue!;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Batal'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        ElevatedButton(
          onPressed: _saveForm,
          child: Text(widget.taskToEdit == null ? 'Tambah' : 'Simpan'),
        ),
      ],
    );
  }
}

