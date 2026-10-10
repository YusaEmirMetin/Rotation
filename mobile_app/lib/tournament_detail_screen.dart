import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'match_screen.dart';

const Color kBg = Color(0xFF0A0F1A);
const Color kSurface = Color(0xFF151D2A);
const Color kCard = Color(0xFF1E2838);
const Color kPrimary = Color(0xFFFF5A00);
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
  List<dynamic> _standings = [];
  List<dynamic> _fixtures = [];

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

      // 3. Puan Durumunu al
      final resStandings = await http.get(Uri.parse('$kBaseUrl/api/tournaments/${widget.tournament['id']}/standings'));

      // 4. Fikstürü al
      final resFixtures = await http.get(Uri.parse('$kBaseUrl/api/fixtures/tournament/${widget.tournament['id']}'));

      if (resTour.statusCode == 200 && resTeams.statusCode == 200) {
        final tourData = json.decode(utf8.decode(resTour.bodyBytes));
        setState(() {
          _tournamentTeams = tourData['teams'] ?? [];
          _allTeams = json.decode(utf8.decode(resTeams.bodyBytes));
          if (resStandings.statusCode == 200) {
            _standings = json.decode(utf8.decode(resStandings.bodyBytes));
          }
          if (resFixtures.statusCode == 200) {
            _fixtures = json.decode(utf8.decode(resFixtures.bodyBytes));
          }
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

  Future<void> _startMatchFromFixture(int fixtureId) async {
    try {
      final res = await http.post(
        Uri.parse('$kBaseUrl/api/fixtures/$fixtureId/start'),
      );
      if (res.statusCode == 200) {
        final match = json.decode(utf8.decode(res.bodyBytes));
        if (mounted) {
          Navigator.push(context, MaterialPageRoute(builder: (context) => MatchScreen(matchId: match['id']))).then((_) => _fetchData());
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to start match: ${res.body}')));
        }
      }
    } catch (e) {
      debugPrint('Start Match Error: $e');
    }
  }

  Future<void> _generateFixtures() async {
    if (_tournamentTeams.length < 2) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('At least 2 teams are required to generate fixtures!')),
        );
      }
      return;
    }
    
    setState(() => _isLoading = true);
    try {
      final res = await http.post(
        Uri.parse('$kBaseUrl/api/fixtures/tournament/${widget.tournament['id']}/generate'),
      );
      
      if (res.statusCode == 200) {
        _fetchData(); // Fikstürler oluştuktan sonra veriyi tekrar çek
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${res.body}')),
          );
        }
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Generate Fixtures Error: $e');
      setState(() => _isLoading = false);
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

  Future<void> _confirmDeleteTournament() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurface,
        title: const Text('DELETE TOURNAMENT', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to delete this tournament? This action cannot be undone and will delete all associated standings and fixtures.', style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCEL', style: TextStyle(color: kTextSub)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('DELETE', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _deleteTournament();
    }
  }

  Future<void> _deleteTournament() async {
    setState(() => _isLoading = true);
    try {
      final res = await http.delete(
        Uri.parse('$kBaseUrl/api/tournaments'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(widget.tournament),
      );
      if (res.statusCode == 200) {
        if (mounted) Navigator.pop(context, true); // Return to previous screen
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete: ${res.statusCode}')));
        }
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Delete Error: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
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
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                onPressed: _confirmDeleteTournament,
              ),
            ],
            bottom: const TabBar(
              indicatorColor: kPrimary,
              labelColor: kPrimary,
              unselectedLabelColor: kTextSub,
              labelStyle: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
              tabs: [
                Tab(text: 'STANDINGS'),
                Tab(text: 'FIXTURES'),
                Tab(text: 'TEAMS'),
              ],
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
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('STATUS', style: TextStyle(color: kTextSub, fontSize: 12, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(widget.tournament['tournamentStatus']?.toString().toUpperCase() ?? 'ACTIVE', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          // TAB 1: STANDINGS
                          _buildStandingsTab(),
                          
                          // TAB 2: FIXTURES
                          _buildFixturesTab(),
                          
                          // TAB 3: TEAMS
                          _buildTeamsTab(),
                        ],
                      ),
                    ),
                  ],
                ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: kPrimary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)), // Sharp corner
            onPressed: _showAddTeamSheet,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('ADD TEAM', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  Widget _buildStandingsTab() {
    if (_standings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events, size: 48, color: Colors.white.withOpacity(0.1)),
            const SizedBox(height: 16),
            const Text('NO STANDINGS AVAILABLE', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1)),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          headingTextStyle: const TextStyle(color: kTextSub, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1),
          dataTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
          columnSpacing: 24,
          columns: const [
            DataColumn(label: Text('#')),
            DataColumn(label: Text('TEAM')),
            DataColumn(label: Text('P'), tooltip: 'Played'),
            DataColumn(label: Text('W'), tooltip: 'Won'),
            DataColumn(label: Text('L'), tooltip: 'Lost'),
            DataColumn(label: Text('PTS'), tooltip: 'Points'),
            DataColumn(label: Text('SW'), tooltip: 'Sets Won'),
            DataColumn(label: Text('SL'), tooltip: 'Sets Lost'),
          ],
          rows: List.generate(_standings.length, (index) {
            final st = _standings[index];
            final team = st['team'] ?? {};
            return DataRow(
              color: MaterialStateProperty.resolveWith<Color?>((Set<MaterialState> states) {
                if (index < 4) return kPrimary.withOpacity(0.05); // Playoff positions
                return null; // Default
              }),
              cells: [
                DataCell(Text('${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold))),
                DataCell(Text(team['name']?.toString().toUpperCase() ?? 'UNKNOWN', style: const TextStyle(fontWeight: FontWeight.bold))),
                DataCell(Text('${st['playedMatches'] ?? 0}')),
                DataCell(Text('${st['wins'] ?? 0}')),
                DataCell(Text('${st['losses'] ?? 0}')),
                DataCell(Text('${st['points'] ?? 0}', style: const TextStyle(fontWeight: FontWeight.bold, color: kTeal))),
                DataCell(Text('${st['wonSets'] ?? 0}')),
                DataCell(Text('${st['lostSets'] ?? 0}')),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildFixturesTab() {
    if (_fixtures.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_month, size: 48, color: Colors.white.withOpacity(0.1)),
            const SizedBox(height: 16),
            const Text('FIXTURES NOT GENERATED YET', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _generateFixtures,
              icon: const Icon(Icons.generating_tokens, color: Colors.white, size: 18),
              label: const Text('GENERATE FIXTURES', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)), // Corporate sharp corner
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _fixtures.length,
      itemBuilder: (context, index) {
        final fix = _fixtures[index];
        final homeTeamId = fix['homeTeamId'];
        final awayTeamId = fix['awayTeamId'];
        final status = fix['status'] ?? 'SCHEDULED';
        final matchId = fix['matchId'];
        
        final homeTeam = _tournamentTeams.firstWhere((t) => t['id'] == homeTeamId, orElse: () => {'name': 'Unknown'});
        final awayTeam = _tournamentTeams.firstWhere((t) => t['id'] == awayTeamId, orElse: () => {'name': 'Unknown'});

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: kSurface,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('WEEK ${fix['tournamentWeek']}', style: const TextStyle(color: kPrimary, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: status == 'FINISHED' ? kTextSub.withOpacity(0.1) : 
                             status == 'ACTIVE' ? kTeal.withOpacity(0.1) : 
                             Colors.white.withOpacity(0.1), 
                      borderRadius: BorderRadius.circular(2)
                    ),
                    child: Text(status, style: TextStyle(
                      color: status == 'FINISHED' ? kTextSub : 
                             status == 'ACTIVE' ? kTeal : 
                             Colors.white70, 
                      fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1
                    )),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(homeTeam['name']?.toString().toUpperCase() ?? 'UNKNOWN', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                  
                  if (status == 'FINISHED')
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('${fix['homeTeamScore']} - ${fix['awayTeamScore']}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                    )
                  else
                    const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('VS', style: TextStyle(color: kTextSub, fontSize: 12, fontWeight: FontWeight.bold))),
                  
                  Expanded(child: Text(awayTeam['name']?.toString().toUpperCase() ?? 'UNKNOWN', textAlign: TextAlign.right, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                ],
              ),
              if (status != 'FINISHED') ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (status == 'SCHEDULED') {
                        _startMatchFromFixture(fix['id']);
                      } else if (status == 'ACTIVE' && matchId != null) {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => MatchScreen(matchId: matchId))).then((_) => _fetchData());
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: status == 'ACTIVE' ? kTeal : kPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(status == 'ACTIVE' ? 'RESUME MATCH' : 'START MATCH', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildTeamsTab() {
    if (_tournamentTeams.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.group_off, size: 48, color: Colors.white.withOpacity(0.1)),
            const SizedBox(height: 16),
            const Text('NO TEAMS ADDED YET', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1)),
          ],
        ),
      );
    }
    
    return ListView.builder(
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
    );
  }
}
