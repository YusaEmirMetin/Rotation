import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

const Color kBg = Color(0xFF0F0F1A);
const Color kCard = Color(0xFF1B1B2A);
const Color kAccent = Color(0xFFFF5A00); // Professional blue
const Color kTextSub = Color(0xFF94A3B8);
const String kBaseUrl = 'http://127.0.0.1:8080';

class HonoursScreen extends StatefulWidget {
  final int? teamId;
  final int? playerId;
  final String titleName;

  const HonoursScreen({
    super.key,
    this.teamId,
    this.playerId,
    required this.titleName,
  });

  @override
  State<HonoursScreen> createState() => _HonoursScreenState();
}

class _HonoursScreenState extends State<HonoursScreen> {
  List<dynamic> _honours = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _fetchHonours();
  }

  Future<void> _fetchHonours() async {
    setState(() => _isLoading = true);
    try {
      final String endpoint = widget.teamId != null 
          ? '$kBaseUrl/honours/team/${widget.teamId}' 
          : widget.playerId != null 
              ? '$kBaseUrl/honours/player/${widget.playerId}'
              : '$kBaseUrl/honours/all';
          
      final res = await http.get(Uri.parse(endpoint));
      
      if (res.statusCode == 200) {
        setState(() {
          _honours = json.decode(utf8.decode(res.bodyBytes)) as List<dynamic>;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'FAILED TO FETCH DATA (${res.statusCode})';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'CONNECTION ERROR';
        _isLoading = false;
      });
    }
  }

  void _openAddHonourSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddHonourSheet(
        teamId: widget.teamId,
        playerId: widget.playerId,
        onCreated: _fetchHonours,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: kBg,
        appBar: AppBar(
          backgroundColor: kBg,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.titleName.toUpperCase(),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
              const Text(
                'HONOURS & AWARDS',
                style: TextStyle(fontSize: 10, color: kTextSub, letterSpacing: 1.2),
              ),
            ],
          ),
        ),
        body: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: kAccent))
              : _error.isNotEmpty
                  ? Center(child: Text(_error, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)))
                  : _honours.isEmpty
                      ? const Center(
                          child: Text('NO HONOURS RECORDED', style: TextStyle(color: kTextSub, fontSize: 12, letterSpacing: 1, fontWeight: FontWeight.bold)),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          itemCount: _honours.length,
                          itemBuilder: (context, index) {
                            final honour = _honours[index];
                            final name = honour['name'] ?? 'UNKNOWN';
                            final type = honour['type'] ?? 'GENERAL';
                            final number = honour['number'] ?? 1;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: kCard,
                                borderRadius: BorderRadius.circular(4), // Sharp edges
                                border: Border(left: BorderSide(color: kAccent, width: 4)),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name.toString().toUpperCase(),
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.5),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          type.toString().toUpperCase(),
                                          style: const TextStyle(color: kTextSub, fontSize: 10, letterSpacing: 1),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: kBg,
                                      borderRadius: BorderRadius.circular(2),
                                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                                    ),
                                    child: Text(
                                      'X$number',
                                      style: const TextStyle(color: kAccent, fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                  )
                                ],
                              ),
                            );
                          },
                        ),
        ),
        floatingActionButton: (widget.teamId != null || widget.playerId != null)
            ? FloatingActionButton.extended(
                onPressed: _openAddHonourSheet,
                backgroundColor: kAccent,
                foregroundColor: Colors.white,
                elevation: 0,
                icon: const Icon(Icons.add, size: 20),
                label: const Text(
                  'ADD HONOUR',
                  style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1, fontSize: 12),
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              )
            : null,
      ),
    );
  }
}

class _AddHonourSheet extends StatefulWidget {
  final int? teamId;
  final int? playerId;
  final VoidCallback onCreated;

  const _AddHonourSheet({this.teamId, this.playerId, required this.onCreated});

  @override
  State<_AddHonourSheet> createState() => _AddHonourSheetState();
}

class _AddHonourSheetState extends State<_AddHonourSheet> {
  final _nameCtrl = TextEditingController();
  final _typeCtrl = TextEditingController();
  final _numberCtrl = TextEditingController(text: "1");
  bool _isLoading = false;
  String? _error;

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty) {
      setState(() => _error = 'NAME CANNOT BE EMPTY');
      return;
    }
    setState(() { _isLoading = true; _error = null; });

    final body = <String, dynamic>{
      'name': _nameCtrl.text.trim(),
      'type': _typeCtrl.text.trim().isEmpty ? 'GENERAL' : _typeCtrl.text.trim(),
      'number': int.tryParse(_numberCtrl.text.trim()) ?? 1,
    };

    if (widget.teamId != null) body['team'] = {'id': widget.teamId};
    if (widget.playerId != null) body['player'] = {'id': widget.playerId};

    try {
      final res = await http.post(
        Uri.parse('$kBaseUrl/honours'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        if (mounted) {
          Navigator.pop(context);
          widget.onCreated();
          HapticFeedback.lightImpact();
        }
      } else {
        setState(() { _error = 'ERROR: ${res.statusCode}'; _isLoading = false; });
      }
    } catch (e) {
      setState(() { _error = 'CONNECTION ERROR'; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottom),
      decoration: const BoxDecoration(
        color: Color(0xFF1B1B2A), // kCard equivalent
        borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('NEW HONOUR', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 24),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(_error!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          _buildTextField(_nameCtrl, 'HONOUR NAME (e.g. CEV CHAMPION)'),
          const SizedBox(height: 16),
          _buildTextField(_typeCtrl, 'TYPE (e.g. GOLD MEDAL)'),
          const SizedBox(height: 16),
          _buildTextField(_numberCtrl, 'COUNT (e.g. 1)', isNumber: true),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5A00), // kAccent
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
              child: _isLoading
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('SAVE', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String hint, {bool isNumber = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12, letterSpacing: 1),
        filled: true,
        fillColor: const Color(0xFF0F0F1A), // kBg
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
