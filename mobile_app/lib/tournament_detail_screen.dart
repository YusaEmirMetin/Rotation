import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'match_screen.dart';
import 'honours_screen.dart';

const Color kBg = Color(0xFF0D0D0D);
const Color kSurface = Color(0xFF1E1E1E);
const Color kCard = Color(0xFF2A2A2A);
const Color kPrimary = Color(0xFF34D399);
const Color kTeal = Color(0xFF34D399);
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
  List<dynamic> _allPlayers = [];
  String _currentStatus = 'UPCOMING';

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.tournament['tournamentStatus']?.toString().toUpperCase() ?? 'UPCOMING';
    _fetchData();
  }

  Future<void> _updateTournamentStatus(String newStatus) async {
    try {
      final res = await http.put(
        Uri.parse('$kBaseUrl/api/tournaments/${widget.tournament['id']}/status/$newStatus'),
      );
      if (res.statusCode == 200) {
        setState(() {
          _currentStatus = newStatus;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: kPrimary,
              content: Text('tournament_started'.tr, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Status update error: $e');
    }
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

      // 5. Oyuncuları al (Tüm oyunculardan filtreleyeceğiz)
      final resPlayers = await http.get(Uri.parse('$kBaseUrl/api/teams/1/players/all'));

      if (resTour.statusCode == 200 && resTeams.statusCode == 200) {
        final tourData = json.decode(utf8.decode(resTour.bodyBytes));
        setState(() {
          _currentStatus = tourData['tournamentStatus']?.toString().toUpperCase() ?? _currentStatus;
          _tournamentTeams = tourData['teams'] ?? [];
          _allTeams = json.decode(utf8.decode(resTeams.bodyBytes));
          if (resStandings.statusCode == 200) {
            _standings = json.decode(utf8.decode(resStandings.bodyBytes));
          }
          if (resFixtures.statusCode == 200) {
            _fixtures = json.decode(utf8.decode(resFixtures.bodyBytes));
          }
          if (resPlayers.statusCode == 200) {
            _allPlayers = json.decode(utf8.decode(resPlayers.bodyBytes));
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

  Future<void> _createNewTeamForTournament(String teamName) async {
    setState(() => _isLoading = true);
    try {
      final res = await http.post(
        Uri.parse('$kBaseUrl/api/teams'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'name': teamName}),
      );
      if (res.statusCode == 201 || res.statusCode == 200) {
        final newTeam = json.decode(utf8.decode(res.bodyBytes));
        await _addTeamToTournament(newTeam['id']);
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Create Team Error: $e');
      setState(() => _isLoading = false);
    }
  }

  void _showCreateTeamDialog() {
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurface,
        title: Text('create_new_team'.tr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
        content: TextField(
          controller: nameCtrl,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'enter_team_name'.tr,
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
            filled: true,
            fillColor: kBg,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('cancel'.tr, style: const TextStyle(color: kTextSub))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            onPressed: () {
              if (nameCtrl.text.isNotEmpty) {
                Navigator.pop(ctx);
                _createNewTeamForTournament(nameCtrl.text);
              }
            },
            child: Text('create'.tr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showAddPlayerToTeamDialog(Map<String, dynamic> team) {
    final firstCtrl = TextEditingController();
    final lastCtrl = TextEditingController();
    final numberCtrl = TextEditingController();
    final heightCtrl = TextEditingController();
    String selectedPos = 'OUTSIDE_HITTER';

    final positions = [
      {'val': 'OUTSIDE_HITTER', 'label': 'outside_hitter'.tr},
      {'val': 'SETTER', 'label': 'setter'.tr},
      {'val': 'MIDDLE_BLOCKER', 'label': 'middle_blocker'.tr},
      {'val': 'OPPOSITE_HITTER', 'label': 'opposite_hitter'.tr},
      {'val': 'LIBERO', 'label': 'libero'.tr},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: kPrimary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.person_add_rounded, color: kPrimary, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('add_player_to_team'.tr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          Text(team['name'] ?? '', style: TextStyle(color: kPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: kTextSub),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: firstCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'first_name'.tr,
                        filled: true,
                        fillColor: kSurface,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: lastCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'last_name'.tr,
                        filled: true,
                        fillColor: kSurface,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: numberCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'jersey_number'.tr,
                        filled: true,
                        fillColor: kSurface,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: heightCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'height_cm'.tr,
                        filled: true,
                        fillColor: kSurface,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: kSurface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedPos,
                    dropdownColor: kSurface,
                    isExpanded: true,
                    items: positions.map((pos) {
                      return DropdownMenuItem<String>(
                        value: pos['val'],
                        child: Text(pos['label']!, style: const TextStyle(color: Colors.white)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setModalState(() => selectedPos = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () async {
                    if (firstCtrl.text.trim().isEmpty || lastCtrl.text.trim().isEmpty || numberCtrl.text.trim().isEmpty) {
                      return;
                    }
                    Navigator.pop(ctx);
                    setState(() => _isLoading = true);
                    try {
                      final body = {
                        'firstName': firstCtrl.text.trim(),
                        'lastName': lastCtrl.text.trim(),
                        'jerseyNumber': int.tryParse(numberCtrl.text.trim()) ?? 1,
                        'position': selectedPos,
                        'heightCm': int.tryParse(heightCtrl.text.trim()) ?? 180,
                        'playerValue': 5.0,
                      };
                      final res = await http.post(
                        Uri.parse('$kBaseUrl/api/teams/${team['id']}/players'),
                        headers: {'Content-Type': 'application/json'},
                        body: json.encode(body),
                      );
                      if (res.statusCode == 201 || res.statusCode == 200) {
                        await _fetchData();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: kPrimary,
                              content: Text('${firstCtrl.text} (${team['name']}) ${'player_added_success'.tr}'.toUpperCase(), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                            ),
                          );
                        }
                      }
                    } catch (e) {
                      debugPrint('Add player error: $e');
                    } finally {
                      setState(() => _isLoading = false);
                    }
                  },
                  child: Text('save_button'.tr, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTeamPlayersSheet(Map<String, dynamic> team) {
    final teamPlayers = _allPlayers.where((p) => p['team'] != null && p['team']['id'] == team['id']).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.7,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.shield, color: kPrimary, size: 28),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(team['name']?.toString().toUpperCase() ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1)),
                        Text('team_players'.tr, style: const TextStyle(color: kTextSub, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: kTextSub),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  _showAddPlayerToTeamDialog(team);
                },
                icon: const Icon(Icons.person_add_rounded, size: 20),
                label: Text('add_player_to_team'.tr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: teamPlayers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_off_rounded, size: 48, color: Colors.white.withOpacity(0.1)),
                          const SizedBox(height: 12),
                          Text('no_players_yet'.tr, style: const TextStyle(color: kTextSub, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: teamPlayers.length,
                      itemBuilder: (context, idx) {
                        final p = teamPlayers[idx];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: kSurface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.04)),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: kCard,
                                child: Text(
                                  '#${p['jerseyNumber'] ?? ''}',
                                  style: const TextStyle(color: kPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${p['firstName']} ${p['lastName']}'.toUpperCase(),
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    Text(
                                      '${p['position']}  •  ${p['heightCm'] ?? '-'} cm',
                                      style: const TextStyle(color: kTextSub, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ],
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

  Future<void> _removeTeamFromTournament(int teamId) async {
    setState(() => _isLoading = true);
    try {
      final res = await http.delete(
        Uri.parse('$kBaseUrl/api/tournaments/${widget.tournament['id']}/teams/$teamId'),
      );
      if (res.statusCode == 200) {
        _fetchData(); // Listeyi yenile
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to remove team: ${res.body}')));
        }
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Remove Team Error: $e');
      setState(() => _isLoading = false);
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
      backgroundColor: kBg,
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('select_team'.tr, style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showCreateTeamDialog();
                  },
                  icon: const Icon(Icons.add, color: kPrimary, size: 16),
                  label: Text('create_new'.tr, style: TextStyle(color: kPrimary, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (availableTeams.isEmpty)
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('all_teams_in_tournament'.tr, style: TextStyle(color: kTextSub)),
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
        title: Text('delete_tournament'.tr, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
        content: Text('delete_confirm'.tr, style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('cancel'.tr, style: const TextStyle(color: kTextSub)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: Text('delete'.tr, style: const TextStyle(color: Colors.white)),
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
      length: 5,
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
            bottom: TabBar(
              indicatorColor: kPrimary,
              labelColor: kPrimary,
              unselectedLabelColor: kTextSub,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
              isScrollable: true,
              tabs: [
                Tab(text: 'standings'.tr),
                Tab(text: 'fixtures'.tr),
                Tab(text: 'teams'.tr),
                Tab(text: 'players'.tr),
                Tab(text: 'honours'.tr),
              ],
            ),
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator(color: kPrimary))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: kSurface,
                        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _currentStatus == 'ACTIVE'
                                      ? kPrimary
                                      : (_currentStatus == 'COMPLETED' ? Colors.blueAccent : Colors.amberAccent),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('status'.tr.toUpperCase(), style: const TextStyle(color: kTextSub, fontSize: 11, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 2),
                                  Text(
                                    (_currentStatus.toLowerCase()).tr.toUpperCase(),
                                    style: TextStyle(
                                      color: _currentStatus == 'ACTIVE'
                                          ? kPrimary
                                          : (_currentStatus == 'COMPLETED' ? Colors.blueAccent : Colors.amberAccent),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          if (_currentStatus == 'UPCOMING')
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kPrimary,
                                foregroundColor: Colors.black,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () => _updateTournamentStatus('ACTIVE'),
                              icon: const Icon(Icons.play_arrow_rounded, size: 20),
                              label: Text('start_tournament'.tr, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 0.5)),
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

                          // TAB 4: PLAYERS
                          _buildPlayersTab(),

                          // TAB 5: HONOURS
                          HonoursScreen(titleName: widget.tournament['tournamentName'] ?? 'TOURNAMENT HONOURS'),
                        ],
                      ),
                    ),
                  ],
                ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: kPrimary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), 
            onPressed: _showAddTeamSheet,
            icon: const Icon(Icons.add, color: Colors.white),
            label: Text('add_team'.tr, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
            Text('no_standings_available'.tr, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1)),
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
          columns: [
            const DataColumn(label: Text('#')),
            DataColumn(label: Text('team_label'.tr)),
            DataColumn(label: Text('played_short'.tr), tooltip: 'played_tooltip'.tr),
            DataColumn(label: Text('won_short'.tr), tooltip: 'won_tooltip'.tr),
            DataColumn(label: Text('lost_short'.tr), tooltip: 'lost_tooltip'.tr),
            DataColumn(label: Text('points_short'.tr), tooltip: 'points_tooltip'.tr),
            DataColumn(label: Text('sets_won_short'.tr), tooltip: 'sets_won_tooltip'.tr),
            DataColumn(label: Text('sets_lost_short'.tr), tooltip: 'sets_lost_tooltip'.tr),
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
            Text('fixtures_not_generated_yet'.tr, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _generateFixtures,
              icon: const Icon(Icons.generating_tokens, color: Colors.white, size: 18),
              label: Text('generate_fixtures'.tr, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), 
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
            borderRadius: BorderRadius.circular(16),
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
                      borderRadius: BorderRadius.circular(8)
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
                    Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('VS', style: TextStyle(color: kTextSub, fontSize: 12, fontWeight: FontWeight.bold))),
                  
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(status == 'ACTIVE' ? 'resume_match'.tr : 'start_match'.tr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
            Text('no_teams_added_yet'.tr, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1)),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _tournamentTeams.length,
      itemBuilder: (context, index) {
        final team = _tournamentTeams[index];
        final teamPlayersCount = _allPlayers.where((p) => p['team'] != null && p['team']['id'] == team['id']).length;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: kSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _showTeamPlayersSheet(team),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: kPrimary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.shield, color: kPrimary, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          team['name']?.toString().toUpperCase() ?? 'UNKNOWN',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.5),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '$teamPlayersCount ${'players'.tr.toLowerCase()}  •  ${'add_player_to_team'.tr.toLowerCase()}',
                          style: const TextStyle(color: kTextSub, fontSize: 11, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.person_add_rounded, color: kPrimary, size: 22),
                    tooltip: 'add_player_to_team'.tr,
                    onPressed: () => _showAddPlayerToTeamDialog(team),
                  ),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 22),
                    tooltip: 'remove'.tr,
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: kSurface,
                          title: Text('remove_team_title'.tr, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                          content: Text(('are_you_sure_remove'.tr + ' ${team['name']}? '), style: const TextStyle(color: Colors.white)),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL', style: TextStyle(color: kTextSub))),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                              onPressed: () {
                                Navigator.pop(ctx);
                                _removeTeamFromTournament(team['id']);
                              },
                              child: const Text('REMOVE', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlayersTab() {
    // Sadece turnuvadaki takımların oyuncularını filtrele
    final tournamentTeamIds = _tournamentTeams.map((t) => t['id']).toSet();
    final tournamentPlayers = _allPlayers.where((p) {
      final t = p['team'];
      if (t == null) return false;
      return tournamentTeamIds.contains(t['id']);
    }).toList();

    // Playerları skora göre sırala
    tournamentPlayers.sort((a, b) {
      final valA = (a['playerValue'] ?? 0.0) as double;
      final valB = (b['playerValue'] ?? 0.0) as double;
      return valB.compareTo(valA); // Büyükten küçüğe
    });

    if (tournamentPlayers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_alt_rounded, size: 48, color: Colors.white.withOpacity(0.1)),
            const SizedBox(height: 16),
            Text('no_players_found'.tr, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tournamentPlayers.length,
      itemBuilder: (context, index) {
        final player = tournamentPlayers[index];
        final teamName = player['team'] != null ? player['team']['name'] : 'Unknown';
        
        final mockPoints = ((player['playerValue'] ?? 1.0) * 15).round();
        final mockErrors = ((player['playerValue'] ?? 1.0) * 3).round();

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: kSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: index < 3 ? kPrimary : kBg,
              child: Text(
                '#${index + 1}',
                style: TextStyle(color: index < 3 ? Colors.white : kTextSub, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
            title: Text(
              '${player['firstName']} ${player['lastName']}'.toUpperCase(),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '$teamName | ${player['position']}',
              style: const TextStyle(color: kTextSub, fontSize: 12),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$mockPoints PTS',
                  style: const TextStyle(color: kTeal, fontWeight: FontWeight.w900, fontSize: 14),
                ),
                Text(
                  '$mockErrors ERR',
                  style: const TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
