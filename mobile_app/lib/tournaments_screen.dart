import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'tournament_detail_screen.dart';

const Color kBg = Color(0xFF0F172A);
const Color kSurface = Color(0xFF1E293B);
const Color kCard = Color(0xFF334155);
const Color kPrimary = Color(0xFF3B82F6);
const Color kTextSub = Color(0xFF94A3B8);
const String kBaseUrl = 'http://127.0.0.1:8080';

class TournamentsScreen extends StatefulWidget {
  const TournamentsScreen({super.key});

  @override
  State<TournamentsScreen> createState() => _TournamentsScreenState();
}

class _TournamentsScreenState extends State<TournamentsScreen> {
  List<dynamic> _tournaments = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _fetchTournaments();
  }

  Future<void> _fetchTournaments() async {
    setState(() => _isLoading = true);
    try {
      final res = await http.get(Uri.parse('$kBaseUrl/api/tournaments'));
      if (res.statusCode == 200) {
        setState(() {
          _tournaments = json.decode(utf8.decode(res.bodyBytes));
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to fetch tournaments (${res.statusCode})';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Connection error. Check backend.';
        _isLoading = false;
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'ACTIVE': return const Color(0xFF10B981); // Green
      case 'UPCOMING': return const Color(0xFFFBBF24); // Yellow
      case 'COMPLETED': return const Color(0xFF94A3B8); // Gray
      default: return kPrimary;
    }
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
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('TOURNAMENTS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
              Text('MANAGE & TRACK', style: TextStyle(fontSize: 10, color: kTextSub, letterSpacing: 1.2)),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: kPrimary))
            : _error.isNotEmpty
                ? Center(child: Text(_error, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)))
                : _tournaments.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.tour, size: 48, color: Colors.white.withOpacity(0.1)),
                            const SizedBox(height: 16),
                            const Text('NO TOURNAMENTS YET', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _tournaments.length,
                        itemBuilder: (context, index) {
                          final t = _tournaments[index];
                          final statusColor = _getStatusColor(t['tournamentStatus']);
                          
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TournamentDetailScreen(tournament: t),
                                ),
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: kSurface,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.white.withOpacity(0.05)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: kBg,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                                  ),
                                  child: const Icon(Icons.tour, color: kPrimary),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        t['tournamentName']?.toString().toUpperCase() ?? 'UNKNOWN',
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${t['tournamentType']} • ${t['tournamentStartDate']} / ${t['tournamentEndDate']}',
                                        style: const TextStyle(color: kTextSub, fontSize: 10, letterSpacing: 0.5),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    t['tournamentStatus'] ?? '',
                                    style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ); // Close GestureDetector
                        },
                      ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: kPrimary,
          onPressed: () => _showCreateTournamentSheet(context),
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  void _showCreateTournamentSheet(BuildContext context) {
    final nameController = TextEditingController();
    final typeController = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 24,
          left: 24,
          right: 24,
        ),
        decoration: const BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('NEW TOURNAMENT', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1)),
            const SizedBox(height: 24),
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Tournament Name',
                labelStyle: const TextStyle(color: kTextSub),
                filled: true,
                fillColor: kBg,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: typeController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Tournament Type (e.g. Cup, League)',
                labelStyle: const TextStyle(color: kTextSub),
                filled: true,
                fillColor: kBg,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
                onPressed: () async {
                  if (nameController.text.isNotEmpty && typeController.text.isNotEmpty) {
                    await _createTournament(nameController.text, typeController.text);
                    if (context.mounted) Navigator.pop(context);
                  }
                },
                child: const Text('CREATE TOURNAMENT', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _createTournament(String name, String type) async {
    try {
      final res = await http.post(
        Uri.parse('$kBaseUrl/api/tournaments'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'tournamentName': name,
          'tournamentType': type,
          'tournamentStartDate': DateTime.now().toIso8601String().split('T')[0],
          'tournamentEndDate': DateTime.now().add(const Duration(days: 30)).toIso8601String().split('T')[0],
          'tournamentStatus': 'UPCOMING'
        }),
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        _fetchTournaments(); // Refresh list
      }
    } catch (e) {
      debugPrint('Error creating tournament: $e');
    }
  }
}
