import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

const Color kBg = Color(0xFF0A0F1A); // Slate 900
const Color kCard = Color(0xFF151D2A); // Slate 800
const Color kSurface = Color(0xFF1E2838); // Slate 700
const Color kOrange = Color(0xFFFF5A00); // Professional Blue
const Color kTeal = Color(0xFF10B981); // Emerald Green
const Color kTextSub = Color(0xFF94A3B8); // Slate 400
const String kBaseUrl = 'http://127.0.0.1:8080';

class StatisticsScreen extends StatefulWidget {
  final int matchId;
  final String team1Name;
  final String team2Name;

  const StatisticsScreen({
    super.key,
    required this.matchId,
    required this.team1Name,
    required this.team2Name,
  });

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  List<dynamic> _players = [];
  Map<int, dynamic> _playerStats = {};
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() { _isLoading = true; });
    try {
      // 1. Oyuncuları çek
      final pRes = await http.get(Uri.parse('$kBaseUrl/api/teams/1/players/all'));
      // 2. İstatistikleri çek
      final sRes = await http.get(Uri.parse('$kBaseUrl/api/player-stats/${widget.matchId}'));

      if (pRes.statusCode == 200 && sRes.statusCode == 200) {
        final allPlayers = json.decode(utf8.decode(pRes.bodyBytes)) as List<dynamic>;
        final allStats = json.decode(utf8.decode(sRes.bodyBytes)) as List<dynamic>;

        // İstatistikleri Map'e dönüştür (Hızlı erişim için)
        Map<int, dynamic> statsMap = {};
        for (var stat in allStats) {
          if (stat['player'] != null && stat['player']['id'] != null) {
             statsMap[stat['player']['id']] = stat;
          }
        }
        
        setState(() {
          _players = allPlayers;
          _playerStats = statsMap;
          _isLoading = false;
        });
      } else {
        setState(() { _error = 'Veri çekilemedi'; _isLoading = false; });
      }
    } catch (e) {
      setState(() { _error = 'Bağlantı hatası'; _isLoading = false; });
    }
  }

  Future<void> _recordAction(int playerId, String action) async {
    try {
      final res = await http.post(
        Uri.parse('$kBaseUrl/api/player-stats/$action?matchId=${widget.matchId}&playerId=$playerId')
      );
      if (res.statusCode == 200) {
        // İşlem başarılı olunca verileri tekrar çekerek ekrandaki sayıları güncelleyelim
        _fetchData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hata oluştu!')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bağlantı hatası!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: kBg,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Üst bar
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Row(
                  children: [
                    IconButton(
                      icon: Container(
                        width: 38, height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Colors.white),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'İstatistik Antrenörü',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white),
                        ),
                        Text(
                          '${widget.team1Name} vs ${widget.team2Name}',
                          style: const TextStyle(fontSize: 12, color: kTeal),
                        ),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      onPressed: _fetchData,
                    ),
                  ],
                ),
              ),

              // İçerik
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: kTeal))
                    : _error.isNotEmpty
                        ? Center(child: Text(_error, style: const TextStyle(color: Colors.red)))
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            itemCount: _players.length,
                            itemBuilder: (context, index) {
                              final player = _players[index];
                              final playerId = player['id'];
                              final firstName = player['firstName'] ?? '';
                              final lastName = player['lastName'] ?? '';
                              final name = '$firstName $lastName';
                              final num = player['jerseyNumber'] ?? '#';

                              // Oyuncunun mevcut istatistiklerini al (eğer varsa)
                              final pStat = _playerStats[playerId];
                              final int points = pStat != null ? (pStat['point'] ?? 0) : 0;
                              final int errors = pStat != null ? (pStat['error'] ?? 0) : 0;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: kCard,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40, height: 40,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle),
                                      child: Text('$num', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                          const SizedBox(height: 4),
                                          // İstatistikleri göster
                                          Row(
                                            children: [
                                              Text('Sayı: $points', style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                                              const SizedBox(width: 12),
                                              Text('Hata: $errors', style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    // + Sayı Butonu
                                    GestureDetector(
                                      onTap: () => _recordAction(playerId, 'point'),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                        decoration: BoxDecoration(color: Colors.green.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                                        child: const Text('+', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 18)),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // - Hata Butonu
                                    GestureDetector(
                                      onTap: () => _recordAction(playerId, 'error'),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                        decoration: BoxDecoration(color: Colors.red.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                                        child: const Text('-', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 18)),
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
      ),
    );
  }
}
