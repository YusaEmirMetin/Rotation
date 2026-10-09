import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';

// Tema renkleri
const Color kBg = Color(0xFF070714);
const Color kOrange = Color(0xFFFF6D00);
const Color kTeal = Color(0xFF00E5FF);
const Color kCard = Color(0xFF131326);
const Color kTextSub = Color(0xFF8E8E9F);

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<dynamic> _matches = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    try {
      final res = await http.get(Uri.parse('http://localhost:8080/api/matches/history'));
      if (res.statusCode == 200) {
        setState(() {
          _matches = json.decode(res.body);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Geçmiş alınamadı: ${res.statusCode}';
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
                      'Maç Geçmişi',
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
                    ? const Center(child: CircularProgressIndicator(color: kOrange))
                    : _error.isNotEmpty
                        ? Center(child: Text(_error, style: const TextStyle(color: Colors.red)))
                        : _matches.isEmpty
                            ? const Center(
                                child: Text(
                                  'Henüz bitmiş maç yok.',
                                  style: TextStyle(color: kTextSub, fontSize: 16),
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                itemCount: _matches.length,
                                itemBuilder: (context, index) {
                                  final match = _matches[index];
                                  return _buildMatchCard(match);
                                },
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteMatch(int id) async {
    try {
      final res = await http.delete(Uri.parse('http://localhost:8080/api/matches/$id'));
      if (res.statusCode == 200) {
        _fetchHistory(); // Sildikten sonra listeyi yenile
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: ${res.statusCode}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Bağlantı hatası: $e')));
    }
  }

  Widget _buildMatchCard(dynamic match) {
    final matchId = match['id'];
    final t1Name = match['team1Name'] ?? 'Takım 1';
    final t2Name = match['team2Name'] ?? 'Takım 2';
    final t1Sets = match['team1Sets'] ?? 0;
    final t2Sets = match['team2Sets'] ?? 0;
    final t1Score = match['team1Score'] ?? 0;
    final t2Score = match['team2Score'] ?? 0;

    // Kazananı renklendirmek için
    final t1Won = t1Sets > t2Sets;
    final t2Won = t2Sets > t1Sets;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Maç Sonucu rozeti
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('MAÇ SONUCU', style: TextStyle(color: kTextSub, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
              ),
              // Sil butonu
              GestureDetector(
                onTap: () => _deleteMatch(matchId),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Takım 1
              Expanded(
                child: Column(
                  children: [
                    Text(
                      t1Name.toString().toUpperCase(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: t1Won ? Colors.white : kTextSub,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: t1Won ? kOrange.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: t1Won ? kOrange.withOpacity(0.5) : Colors.transparent),
                      ),
                      child: Text(
                        '$t1Sets',
                        style: TextStyle(
                          color: t1Won ? kOrange : Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // VS
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    const Text('VS', style: TextStyle(color: kTextSub, fontSize: 12, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text(
                      '$t1Score - $t2Score',
                      style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12),
                    ),
                  ],
                ),
              ),

              // Takım 2
              Expanded(
                child: Column(
                  children: [
                    Text(
                      t2Name.toString().toUpperCase(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: t2Won ? Colors.white : kTextSub,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: t2Won ? kTeal.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: t2Won ? kTeal.withOpacity(0.5) : Colors.transparent),
                      ),
                      child: Text(
                        '$t2Sets',
                        style: TextStyle(
                          color: t2Won ? kTeal : Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
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
    );
  }
}
