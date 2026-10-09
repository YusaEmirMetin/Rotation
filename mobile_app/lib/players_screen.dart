import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'honours_screen.dart';

const Color kBg = Color(0xFF0F172A); // Slate 900
const Color kCard = Color(0xFF1E293B); // Slate 800
const Color kSurface = Color(0xFF334155); // Slate 700
const Color kOrange = Color(0xFF3B82F6); // Professional Blue
const Color kTeal = Color(0xFF10B981); // Emerald Green
const Color kTextSub = Color(0xFF94A3B8); // Slate 400
const String kBaseUrl = 'http://127.0.0.1:8080';

class PlayersScreen extends StatefulWidget {
  const PlayersScreen({super.key});

  @override
  State<PlayersScreen> createState() => _PlayersScreenState();
}

class _PlayersScreenState extends State<PlayersScreen> {
  List<dynamic> _players = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _fetchPlayers();
  }

  Future<void> _fetchPlayers() async {
    try {
      // Backend'deki endpointin, sınıfındaki @RequestMapping nedeniyle: 
      // /api/teams/{teamId}/players/all oldu. Biz şimdilik rastgele bir teamId (örn 1) veriyoruz
      // çünkü yazdığın getAllPlayers() fonksiyonu arka planda tüm oyuncuları çekiyor.
      final res = await http.get(Uri.parse('$kBaseUrl/api/teams/1/players/all'));
      if (res.statusCode == 200) {
        setState(() {
          _players = json.decode(utf8.decode(res.bodyBytes));
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Hata kodu: ${res.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Bağlantı hatası: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _deletePlayer(int playerId) async {
    try {
      // Not: Şu an test amaçlı teamId = 1 gönderiyoruz. (Endpoint: /api/teams/1/players/{id})
      final res = await http.delete(Uri.parse('$kBaseUrl/api/teams/1/players/$playerId'));
      if (res.statusCode == 204 || res.statusCode == 200) {
        _fetchPlayers(); // Sildikten sonra listeyi yenile
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: ${res.statusCode}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Bağlantı hatası: $e')));
    }
  }

  Color _getValueColor(double val) {
    if (val >= 90) return const Color(0xFF10B981);
    if (val >= 80) return const Color(0xFF34D399);
    if (val >= 70) return const Color(0xFF60A5FA);
    if (val >= 60) return const Color(0xFFFBBF24);
    return const Color(0xFFEF4444);
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
                    const Text(
                      'Tüm Oyuncular',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
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
                        : _players.isEmpty
                            ? const Center(
                                child: Text(
                                  'Ligde henüz kayıtlı oyuncu yok.',
                                  style: TextStyle(color: kTextSub, fontSize: 16),
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                itemCount: _players.length,
                                itemBuilder: (context, index) {
                                  final player = _players[index];
                                  final playerId = player['id'];
                                  final firstName = player['firstName'] ?? '';
                                  final lastName = player['lastName'] ?? '';
                                  final name = '$firstName $lastName'.trim().isEmpty ? 'İsimsiz' : '$firstName $lastName';
                                  final num = player['jerseyNumber'] ?? '#';
                                  final pos = player['position'] ?? 'Bilinmiyor';
                                  final double playerValue = (player['playerValue'] ?? 0).toDouble();
                                  
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: kCard,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                                    ),
                                    child: Row(
                                      children: [
                                        // Forma Numarası
                                        Container(
                                          width: 50, height: 50,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: kBg,
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: Colors.white.withOpacity(0.1)),
                                          ),
                                          child: Text(
                                            '$num',
                                            style: const TextStyle(color: kTeal, fontSize: 20, fontWeight: FontWeight.w900),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        // Oyuncu Bilgileri
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                name,
                                                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                pos.toString().toUpperCase(),
                                                style: const TextStyle(color: kTextSub, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // OVR Value
                                        Container(
                                          margin: const EdgeInsets.only(right: 8),
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: kBg,
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: Colors.white.withOpacity(0.08)),
                                          ),
                                          child: Column(
                                            children: [
                                              Text(
                                                playerValue.toStringAsFixed(1),
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w900,
                                                  color: _getValueColor(playerValue),
                                                ),
                                              ),
                                              const Text('OVR', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: kTextSub, letterSpacing: 1)),
                                            ],
                                          ),
                                        ),
                                        // Başarılar Butonu
                                        GestureDetector(
                                          onTap: () {
                                            Navigator.push(context, MaterialPageRoute(builder: (_) => HonoursScreen(
                                              playerId: playerId,
                                              titleName: name,
                                            )));
                                          },
                                          child: Container(
                                            margin: const EdgeInsets.only(right: 8),
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: kSurface,
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(color: Colors.amber.withOpacity(0.3)),
                                            ),
                                            child: const Icon(Icons.emoji_events, color: Colors.amber, size: 20),
                                          ),
                                        ),
                                        // Sil Butonu
                                        GestureDetector(
                                          onTap: () => _deletePlayer(playerId),
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: kBg,
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(color: Colors.red.withOpacity(0.3)),
                                            ),
                                            child: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
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
