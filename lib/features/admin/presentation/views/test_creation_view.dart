import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' as excel_lib;
import 'dart:convert';
import '../../../../core/theme/app_pallete.dart';
import '../../../../core/common/widgets/glass_container.dart';
import '../../../../core/services/admin_service.dart';

class TestCreationView extends StatefulWidget {
  const TestCreationView({super.key});

  @override
  State<TestCreationView> createState() => _TestCreationViewState();
}

class _TestCreationViewState extends State<TestCreationView> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final AdminService _adminService = AdminService();

  DateTime _startDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));
  TimeOfDay _endTime = TimeOfDay.now();
  int _durationMinutes = 60;

  String? _fileName;
  List<Map<String, dynamic>> _questions = [];
  bool _isLoading = false;

  // User Assignment
  List<Map<String, dynamic>> _allUsers = [];
  Set<String> _selectedUserIds = {};
  bool _assignToAll = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final users = await _adminService.getAssignableUsers();
    if (mounted) {
      setState(() {
        _allUsers = users;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickCSVFile() async {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reading file…'),
          duration: Duration(seconds: 1),
        ),
      );
    }
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xlsx', 'xls'],
        withData: true,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final bytes = result.files.first.bytes;
        final fileName = result.files.first.name.toLowerCase();

        if (bytes == null || bytes.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Could not read file bytes. Please try again or use a different file.'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }

        final questions = <Map<String, dynamic>>[];

        if (fileName.endsWith('.xlsx') || fileName.endsWith('.xls')) {
          // ── Excel parsing with full null safety ─────────────────────────
          excel_lib.Excel? excelFile;

          // Try 1: direct decode
          try {
            excelFile = excel_lib.Excel.decodeBytes(List<int>.from(bytes));
          } catch (_) {
            excelFile = null;
          }

          // Try 2: copy bytes to plain List<int> (fixes some Uint8List issues)
          if (excelFile == null) {
            try {
              final bytesCopy = bytes.toList();
              excelFile = excel_lib.Excel.decodeBytes(bytesCopy);
            } catch (_) {
              excelFile = null;
            }
          }

          if (excelFile == null) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'Could not parse this Excel file. Try re-saving it as .xlsx in Excel/Google Sheets and uploading again.'),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 4),
                ),
              );
            }
            return;
          }

          // Find the first sheet with data
          for (var table in excelFile.tables.keys) {
            final sheet = excelFile.tables[table];
            if (sheet == null || sheet.maxRows < 2) continue;

            // Auto-detect column layout from header row
            final headerRow = sheet.row(0);
            final colMap = _detectColumns(headerRow);

            for (var i = 1; i < sheet.maxRows; i++) {
              try {
                final row = sheet.row(i);
                if (row.isEmpty) continue;

                String cell(int index) {
                  if (index < 0 || index >= row.length) return '';
                  final c = row[index];
                  if (c == null) return '';
                  final v = c.value;
                  if (v == null) return '';
                  
                  // Handle newer excel package TextCellValue where toString might be weird
                  String strVal = '';
                  try {
                    // ignore: avoid_dynamic_calls
                    strVal = (v as dynamic).value.toString();
                  } catch (_) {
                    strVal = v.toString();
                  }
                  
                  if (strVal.startsWith("TextCellValue(")) {
                    strVal = strVal.replaceAll("TextCellValue(", "").replaceAll(RegExp(r'\)$'), "");
                  }
                  return strVal.trim();
                }

                final question = cell(colMap['question']!);
                if (question.isEmpty) continue;

                final type = cell(colMap['type']!).toLowerCase();
                final options = <String>[];

                for (var oi in colMap['options']!) {
                  final opt = cell(oi);
                  if (opt.isNotEmpty) options.add(opt);
                }

                final correctStr = cell(colMap['correct']!);
                List<int> correct;
                if (correctStr.isEmpty) {
                  correct = [0];
                } else {
                  correct = correctStr
                      .split(',')
                      .map((s) => (int.tryParse(s.trim()) ?? 1) - 1)
                      .where((v) => v >= 0)
                      .toList();
                  if (correct.isEmpty) correct = [0];
                }

                final explanation =
                    (colMap['explanation']! >= 0) ? cell(colMap['explanation']!) : '';

                questions.add({
                  'question': question,
                  'type': type == 'multiple' ? 'multiple' : 'single',
                  'options': options.isNotEmpty ? options : ['True', 'False'], // Fallback options
                  'correct_answer': correct.first,
                  'explanation': explanation,
                });
              } catch (_) {
                // Skip malformed row silently
                continue;
              }
            }
            // Only break out of sheets loop if we actually found questions!
            if (questions.isNotEmpty) {
              break; 
            }
          }
        } else {
          // ── CSV parsing ─────────────────────────────────────────────────
          final content = utf8.decode(bytes);
          final rows = _parseCSV(content);

          for (var i = 1; i < rows.length; i++) {
            final fields = rows[i];
            if (fields.length < 2) continue; // Minimum: Question and Type

            final question = fields[0];
            final type = fields[1].toLowerCase();
            final options = <String>[];

            for (var j = 2; j < 6 && j < fields.length; j++) {
              if (fields[j].isNotEmpty) options.add(fields[j]);
            }

            final correctStr = fields.length > 6 ? fields[6] : '';
            final correct = correctStr
                .split(',')
                .map((s) => (int.tryParse(s.trim()) ?? 1) - 1)
                .where((v) => v >= 0)
                .toList();

            final explanation = fields.length > 7 ? fields[7] : '';

            questions.add({
              'question': question,
              'type': type == 'multiple' ? 'multiple' : 'single',
              'options': options.isNotEmpty ? options : ['True', 'False'],
              'correct_answer': correct.isNotEmpty ? correct.first : 0,
              'explanation': explanation,
            });
          }
        }

        if (questions.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'No valid questions found. Check that your file has: Question, Type, Option A-D, Correct Answer columns.'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 4),
              ),
            );
          }
          return;
        }

        setState(() {
          _fileName = result.files.first.name;
          _questions = questions;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Loaded ${questions.length} questions from ${fileName.endsWith('.csv') ? 'CSV' : 'Excel'}',
              ),
              backgroundColor: AppPallete.success,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error reading file: $e'),
            backgroundColor: AppPallete.error,
          ),
        );
      }
    }
  }

  /// Auto-detect column positions from header row.
  /// Returns a map with keys: question, type, options (list), correct, explanation.
  Map<String, dynamic> _detectColumns(List<excel_lib.Data?> headerRow) {
    int questionCol = 0;
    int typeCol = 1;
    List<int> optionCols = [2, 3, 4, 5];
    int correctCol = 6;
    int explanationCol = 7;

    // Try to match by header names
    for (int i = 0; i < headerRow.length; i++) {
      final h = (headerRow[i]?.value?.toString() ?? '').toLowerCase().trim();
      if (h.contains('question') || h.contains('ques')) {
        questionCol = i;
      } else if (h.contains('type') || h.contains('kind')) {
        typeCol = i;
      } else if (h.contains('correct') || h.contains('answer') || h.contains('ans')) {
        correctCol = i;
      } else if (h.contains('explain') || h.contains('reason') || h.contains('hint')) {
        explanationCol = i;
      }
    }

    // Options: columns between type and correct
    if (correctCol > typeCol + 1) {
      optionCols = List.generate(
          correctCol - typeCol - 1, (i) => typeCol + 1 + i);
    }

    return {
      'question': questionCol,
      'type': typeCol,
      'options': optionCols,
      'correct': correctCol,
      'explanation': explanationCol < headerRow.length ? explanationCol : -1,
    };
  }

  List<List<String>> _parseCSV(String content) {
    final rows = <List<String>>[];
    var currentRow = <String>[];
    var currentField = StringBuffer();
    var inQuotes = false;

    for (var i = 0; i < content.length; i++) {
      final char = content[i];
      final nextChar = (i + 1 < content.length) ? content[i + 1] : null;

      if (char == '"') {
        if (inQuotes && nextChar == '"') {
          currentField.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char == ',' && !inQuotes) {
        currentRow.add(currentField.toString().trim());
        currentField.clear();
      } else if ((char == '\n' || (char == '\r' && nextChar == '\n')) && !inQuotes) {
        if (char == '\r') i++;
        currentRow.add(currentField.toString().trim());
        if (currentRow.isNotEmpty && (currentRow.length > 1 || currentRow[0].isNotEmpty)) {
           rows.add(List.from(currentRow));
        }
        currentRow.clear();
        currentField.clear();
      } else {
        if (char != '\r') {
           currentField.write(char);
        }
      }
    }
    
    if (currentField.isNotEmpty || currentRow.isNotEmpty) {
      currentRow.add(currentField.toString().trim());
      if (currentRow.isNotEmpty && (currentRow.length > 1 || currentRow[0].isNotEmpty)) {
        rows.add(currentRow);
      }
    }
    return rows;
  }



  Future<void> _createTest() async {
    if (!_formKey.currentState!.validate()) return;
    if (_questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload a CSV file with questions'),
          backgroundColor: AppPallete.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final startDateTime = DateTime(
        _startDate.year,
        _startDate.month,
        _startDate.day,
        _startTime.hour,
        _startTime.minute,
      );
      final endDateTime = DateTime(
        _endDate.year,
        _endDate.month,
        _endDate.day,
        _endTime.hour,
        _endTime.minute,
      );

      final testId = await _adminService.createTest(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        startDate: startDateTime,
        endDate: endDateTime,
        durationMinutes: _durationMinutes,
      );

      if (testId != null) {
        final questionsAdded = await _adminService.addQuestions(testId, _questions);
        if (!questionsAdded && mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(
               content: Text('Warning: Test created, but failed to save questions.'),
               backgroundColor: AppPallete.error,
             ),
           );
        }

        // Assign test to users
        List<String> userIdsToAssign;
        if (_assignToAll) {
          userIdsToAssign = _allUsers.map((u) => u['id'] as String).toList();
        } else {
          userIdsToAssign = _selectedUserIds.toList();
        }

        if (userIdsToAssign.isNotEmpty) {
          await _adminService.assignTestToUsers(testId, userIdsToAssign);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Test created and assigned to ${userIdsToAssign.length} users!',
              ),
              backgroundColor: AppPallete.success,
            ),
          );
          _clearForm();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppPallete.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _clearForm() {
    _titleController.clear();
    _descriptionController.clear();
    setState(() {
      _fileName = null;
      _questions = [];
      _startDate = DateTime.now();
      _endDate = DateTime.now().add(const Duration(days: 7));
      _durationMinutes = 60;
      _selectedUserIds = {};
      _assignToAll = true;
    });
  }

  Future<void> _selectDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _selectTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: AppPallete.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.quiz_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create Test',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppPallete.textPrimary,
                      ),
                    ),
                    const Text(
                      'Upload questions from CSV',
                      style: TextStyle(
                        color: AppPallete.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ).animate().fadeIn().slideX(begin: -0.1),

            const SizedBox(height: 30),

            // Form
            GlassContainer(
              borderRadius: BorderRadius.circular(24),
              blur: 10,
              opacity: 0.05,
              color: AppPallete.surface,
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    TextFormField(
                      controller: _titleController,
                      style: const TextStyle(color: AppPallete.textPrimary),
                      decoration: _inputDecoration('Test Title', Icons.title),
                      validator: (v) =>
                          v?.isEmpty == true ? 'Title is required' : null,
                    ),
                    const SizedBox(height: 16),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 2,
                      style: const TextStyle(color: AppPallete.textPrimary),
                      decoration: _inputDecoration(
                        'Description (optional)',
                        Icons.description,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Date/Time Section
                    Text(
                      'Schedule',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppPallete.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Start Date/Time
                    Row(
                      children: [
                        Expanded(
                          child: _buildDateTimeButton(
                            'Start Date',
                            '${_startDate.day}/${_startDate.month}/${_startDate.year}',
                            () => _selectDate(true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDateTimeButton(
                            'Start Time',
                            _startTime.format(context),
                            () => _selectTime(true),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // End Date/Time
                    Row(
                      children: [
                        Expanded(
                          child: _buildDateTimeButton(
                            'End Date',
                            '${_endDate.day}/${_endDate.month}/${_endDate.year}',
                            () => _selectDate(false),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDateTimeButton(
                            'End Time',
                            _endTime.format(context),
                            () => _selectTime(false),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Duration - Modern Timer Style
                    Text(
                      'Duration',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppPallete.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppPallete.background,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Hours
                          _buildTimerDigit(
                            _durationMinutes ~/ 60,
                            'Hours',
                            (val) => setState(() {
                              _durationMinutes =
                                  (val * 60) + (_durationMinutes % 60);
                            }),
                            0,
                            3,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              ':',
                              style: GoogleFonts.poppins(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: AppPallete.primary,
                              ),
                            ),
                          ),
                          // Minutes
                          _buildTimerDigit(
                            _durationMinutes % 60,
                            'Minutes',
                            (val) => setState(() {
                              _durationMinutes =
                                  ((_durationMinutes ~/ 60) * 60 + val).toInt();
                            }),
                            0,
                            59,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),

            const SizedBox(height: 20),

            // CSV Upload Section
            GlassContainer(
              borderRadius: BorderRadius.circular(24),
              blur: 10,
              opacity: 0.05,
              color: AppPallete.surface,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Questions',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppPallete.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Upload Button
                  GestureDetector(
                    onTap: _pickCSVFile,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppPallete.background,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppPallete.primary.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            _fileName != null
                                ? Icons.check_circle
                                : Icons.upload_file_rounded,
                            size: 48,
                            color: _fileName != null
                                ? AppPallete.success
                                : AppPallete.primary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _fileName ?? 'Upload CSV File',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              color: AppPallete.textPrimary,
                            ),
                          ),
                          if (_questions.isNotEmpty)
                            Text(
                              '${_questions.length} questions loaded',
                              style: const TextStyle(
                                color: AppPallete.success,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Sample Format
                  ExpansionTile(
                    title: const Text(
                      'CSV & Excel Format Reference',
                      style: TextStyle(color: AppPallete.textSecondary),
                    ),
                    iconColor: AppPallete.textSecondary,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppPallete.background,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Excel (.xlsx) files are auto-detected by headers:\n"Question", "Type", "Correct", "Explain".\nOptions will be the columns in between.',
                              style: TextStyle(color: AppPallete.textPrimary, fontSize: 13),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'CSV files must strictly follow this order:',
                              style: TextStyle(color: AppPallete.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            _buildFormatRow('Column 1', 'Question text'),
                            _buildFormatRow(
                              'Column 2',
                              'Type (single/multiple)',
                            ),
                            _buildFormatRow('Column 3-6', 'Options A-D'),
                            _buildFormatRow(
                              'Column 7',
                              'Correct answer (1=A, 2=B, 3=C, 4=D)',
                            ),
                            _buildFormatRow('Column 8', 'Explanation'),
                            const Divider(color: AppPallete.textSecondary),
                            const Text(
                              'Sample CSV:',
                              style: TextStyle(
                                color: AppPallete.textSecondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppPallete.surface,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Question,Type,OptA,OptB,OptC,OptD,Correct,Explanation\n'
                                '"What is 2+2?",single,3,4,5,6,2,"The answer is 4"',
                                style: TextStyle(
                                  color: AppPallete.textPrimary,
                                  fontSize: 10,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),

            const SizedBox(height: 20),

            // User Assignment Section
            GlassContainer(
              borderRadius: BorderRadius.circular(24),
              blur: 10,
              opacity: 0.05,
              color: AppPallete.surface,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Assign to Users',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppPallete.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Toggle: All Users vs Select Users
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _assignToAll = true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _assignToAll
                                  ? AppPallete.primary
                                  : AppPallete.background,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                'All Users',
                                style: TextStyle(
                                  color: _assignToAll
                                      ? Colors.white
                                      : AppPallete.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _assignToAll = false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: !_assignToAll
                                  ? AppPallete.primary
                                  : AppPallete.background,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                'Select Users',
                                style: TextStyle(
                                  color: !_assignToAll
                                      ? Colors.white
                                      : AppPallete.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // User Selection List (only when Select Users is active)
                  if (!_assignToAll) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Select ${_selectedUserIds.length} of ${_allUsers.length} users',
                      style: const TextStyle(
                        color: AppPallete.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _allUsers.length,
                        itemBuilder: (context, index) {
                          final user = _allUsers[index];
                          final userId = user['id'] as String;
                          final userName = user['full_name'] ?? 'Unknown';
                          final isSelected = _selectedUserIds.contains(userId);

                          return CheckboxListTile(
                            value: isSelected,
                            onChanged: (val) {
                              setState(() {
                                if (val == true) {
                                  _selectedUserIds.add(userId);
                                } else {
                                  _selectedUserIds.remove(userId);
                                }
                              });
                            },
                            title: Text(
                              userName,
                              style: const TextStyle(
                                color: AppPallete.textPrimary,
                              ),
                            ),
                            activeColor: AppPallete.primary,
                            checkColor: Colors.white,
                            controlAffinity: ListTileControlAffinity.leading,
                            dense: true,
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.1),

            const SizedBox(height: 24),

            // Create Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createTest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppPallete.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_circle_rounded),
                          const SizedBox(width: 8),
                          Text(
                            'Create Test',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
              ),
            ).animate().fadeIn(delay: 300.ms),

            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppPallete.textSecondary),
      prefixIcon: Icon(icon, color: AppPallete.textSecondary),
      filled: true,
      fillColor: AppPallete.background,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppPallete.primary),
      ),
    );
  }

  Widget _buildDateTimeButton(String label, String value, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppPallete.background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppPallete.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: AppPallete.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormatRow(String column, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              column,
              style: const TextStyle(
                color: AppPallete.primary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              description,
              style: const TextStyle(
                color: AppPallete.textPrimary,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerDigit(
    int value,
    String label,
    Function(int) onChanged,
    int min,
    int max,
  ) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppPallete.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              // Up button
              IconButton(
                onPressed: value < max ? () => onChanged(value + 1) : null,
                icon: Icon(
                  Icons.keyboard_arrow_up_rounded,
                  color: value < max
                      ? AppPallete.primary
                      : AppPallete.textSecondary,
                ),
              ),
              // Value display
              Container(
                width: 60,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  gradient: AppPallete.primaryGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  value.toString().padLeft(2, '0'),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              // Down button
              IconButton(
                onPressed: value > min ? () => onChanged(value - 1) : null,
                icon: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: value > min
                      ? AppPallete.primary
                      : AppPallete.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: AppPallete.textSecondary, fontSize: 12),
        ),
      ],
    );
  }
}
