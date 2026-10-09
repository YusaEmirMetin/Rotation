import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'match_screen.dart';

const Color kBg = Color(0xFF0F172A);
const Color kSurface = Color(0xFF1E293B);
const Color kCard = Color(0xFF334155);
const Color kPrimary = Color(0xFF3B82F6);
const Color kTeal = Color(0xFF10B981);
const Color kTextSub = Color(0xFF94A3B8);
const String kBaseUrl = 'http://127.0.0.1:8080';

class TournamentDetailScreen extends StatefulWidget {
  final Map<String, dynamic> tournament;

  const TournamentDetailScreen({super.key, required this.tournament});

  @override
  State<TournamentDetailScreen> createState() => _TournamentDetailScreenState();
}

class _TournamentDetailScreenState extends State<TournamentDetailScreen> {
  bool _isLoading = true;
  List<dynamic> _tournamentTeams = [];
  List<dynamic> _allTeams = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      // 1. Turnuvadaki takımları al (Turnuva detayından)
      final resTour = await http.get(Uri.parse('$kBaseUrl/api/tournaments/${widget.tournament['id']}'));
      
      // 2. Sistemdeki tüm takımları al (Ekleme listesi için)
      final resTeams = await http.get(Uri.parse('$kBaseUrl/api/teams'));

      if (resTour.statusCode == 200 && resTeams.statusCode == 200) {
        final tourData = json.decode(utf8.decode(resTour.bodyBytes));
        setState(() {
          _tournamentTeams = tourData['teams'] ?? [];
          _allTeams = json.decode(utf8.decode(resTeams.bodyBytes));
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addTeamToTournament(int teamId) async {
    try {
      final res = await http.post(
        Uri.parse('$kBaseUrl/api/tournaments/${widget.tournament['id']}/teams/$teamId'),
      );
      if (res.statusCode == 200) {
        _fetchData(); // Listeyi yenile
      }
    } catch (e) {
      debugPrint('Add Team Error: $e');
    }
  }

  Future<void> _startMatch() async {
    try {
      final res = await http.post(
        Uri.parse('$kBaseUrl/api/matches/tournaments/${widget.tournament['id']}'),
      );
      if (res.statusCode == 200) {
        if (mounted) {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const MatchScreen()));
        }
      } else {
        debugPrint('Failed to start match: ${res.body}');
      }
    } catch (e) {
      debugPrint('Start Match Error: $e');
    }
  }

  void _showAddTeamSheet() {
    // Sadece turnuvada olmayan takımları filtrele
    final availableTeams = _allTeams.where((team) {
      return !_tournamentTeams.any((t) => t['id'] == team['id']);
    }).toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ADD TEAM TO TOURNAMENT', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
            const SizedBox(height: 16),
            if (availableTeams.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('All teams are already in this tournament or no teams exist.', style: TextStyle(color: kTextSub)),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: availableTeams.length,
                  itemBuilder: (context, index) {
                    final team = availableTeams[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(backgroundColor: kBg, child: Icon(Icons.shield, color: kPrimary, size: 20)),
                      title: Text(team['name'] ?? 'Unknown', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      trailing: IconButton(
                        icon: const Icon(Icons.add_circle, color: kPrimary),
                        onPressed: () {
                          Navigator.pop(context);
                          _addTeamToTournament(team['id']);
                        },
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
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
          title: Text(
            widget.tournament['tournamentName']?.toString().toUpperCase() ?? 'DETAILS',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: kPrimary))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    width: double.infinity,
                    color: kSurface,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('PARTICIPATING TEAMS', style: TextStyle(color: kTextSub, fontSize: 12, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${_tournamentTeams.length} TEAMS', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                            if (_tournamentTeams.length >= 2)
                              ElevatedButton.icon(
                                onPressed: _startMatch,
                                icon: const Icon(Icons.play_arrow, color: Colors.white, size: 18),
                                label: const Text('START MATCH', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kTeal,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _tournamentTeams.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.group_off, size: 48, color: Colors.white.withOpacity(0.1)),
                                const SizedBox(height: 16),
                                const Text('NO TEAMS ADDED YET', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _tournamentTeams.length,
                            itemBuilder: (context, index) {
                              final team = _tournamentTeams[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: kSurface,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.shield, color: kPrimary),
                                    const SizedBox(width: 16),
                                    Text(
                                      team['name']?.toString().toUpperCase() ?? 'UNKNOWN',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: kPrimary,
          onPressed: _showAddTeamSheet,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text('ADD TEAM', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
