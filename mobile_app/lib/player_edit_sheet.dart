import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

const _sheetSurface = Color(0xFF1E2838);
const _sheetCard = Color(0xFF151D2A);
const _sheetAccent = Color(0xFF34D399);
const _sheetTextSub = Color(0xFF94A3B8);
const _sheetBaseUrl = 'http://127.0.0.1:8080';

class PlayerEditSheet extends StatefulWidget {
  final Map<String, dynamic> player;
  final int teamId;
  final VoidCallback onSaved;

  const PlayerEditSheet({
    super.key,
    required this.player,
    required this.teamId,
    required this.onSaved,
  });

  @override
  State<PlayerEditSheet> createState() => _PlayerEditSheetState();
}

class _PlayerEditSheetState extends State<PlayerEditSheet> {
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _jerseyController;
  late final TextEditingController _heightController;
  late String _position;
  bool _isSaving = false;
  String? _error;

  static const _positions = [
    'SETTER',
    'OUTSIDE_HITTER',
    'MIDDLE_BLOCKER',
    'OPPOSITE_HITTER',
    'LIBERO',
  ];

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: '${widget.player['firstName'] ?? ''}');
    _lastNameController = TextEditingController(text: '${widget.player['lastName'] ?? ''}');
    _jerseyController = TextEditingController(text: '${widget.player['jerseyNumber'] ?? ''}');
    _heightController = TextEditingController(text: '${widget.player['heightCm'] ?? ''}');
    final position = '${widget.player['position'] ?? 'SETTER'}';
    _position = _positions.contains(position) ? position : 'SETTER';
  }

  Future<void> _save() async {
    final jerseyNumber = int.tryParse(_jerseyController.text.trim());
    final heightText = _heightController.text.trim();
    final heightCm = heightText.isEmpty ? null : int.tryParse(heightText);
    if (_firstNameController.text.trim().isEmpty ||
        _lastNameController.text.trim().isEmpty ||
        jerseyNumber == null ||
        (heightText.isNotEmpty && heightCm == null)) {
      setState(() => _error = 'player_form_invalid'.tr);
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final response = await http.put(
        Uri.parse('$_sheetBaseUrl/api/teams/${widget.teamId}/players/${widget.player['id']}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'firstName': _firstNameController.text.trim(),
          'lastName': _lastNameController.text.trim(),
          'jerseyNumber': jerseyNumber,
          'position': _position,
          'heightCm': heightCm,
        }),
      );

      if (!mounted) return;
      if (response.statusCode == 200) {
        Navigator.pop(context);
        widget.onSaved();
      } else {
        setState(() {
          _error = response.body.trim().isEmpty
              ? '${'error_occurred'.tr} (${response.statusCode})'
              : response.body.trim();
          _isSaving = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'connection_error'.tr;
          _isSaving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _jerseyController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + bottomInset),
      decoration: const BoxDecoration(
        color: _sheetSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 22),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            Text(
              'edit_player'.tr,
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(child: _textField(_firstNameController, 'first_name'.tr, Icons.badge_outlined)),
                const SizedBox(width: 12),
                Expanded(child: _textField(_lastNameController, 'last_name'.tr, Icons.badge_outlined)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _textField(_jerseyController, 'jersey_number'.tr, Icons.tag, numeric: true)),
                const SizedBox(width: 12),
                Expanded(child: _textField(_heightController, 'height_cm'.tr, Icons.height, numeric: true)),
              ],
            ),
            const SizedBox(height: 18),
            Text('position'.tr, style: const TextStyle(color: _sheetTextSub, fontSize: 13)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _position,
              dropdownColor: _sheetCard,
              decoration: const InputDecoration(),
              items: _positions
                  .map((position) => DropdownMenuItem(
                        value: position,
                        child: Text(_positionLabel(position).tr, style: const TextStyle(color: Colors.white)),
                      ))
                  .toList(),
              onChanged: _isSaving ? null : (value) => setState(() => _position = value ?? _position),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save_outlined),
                label: Text('save_changes'.tr),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _sheetAccent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _positionLabel(String position) => switch (position) {
        'SETTER' => 'setter',
        'OUTSIDE_HITTER' => 'outside_hitter',
        'MIDDLE_BLOCKER' => 'middle_blocker',
        'OPPOSITE_HITTER' => 'opposite_hitter',
        'LIBERO' => 'libero',
        _ => 'position',
      };

  Widget _textField(TextEditingController controller, String label, IconData icon, {bool numeric = false}) {
    return TextField(
      controller: controller,
      keyboardType: numeric ? TextInputType.number : TextInputType.name,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: _sheetAccent, size: 18),
      ),
    );
  }
}
