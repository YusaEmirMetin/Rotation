import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'history_screen.dart';
import 'statistics_screen.dart';

const String _baseUrl = 'http://127.0.0.1:8080';
const String _wsUrl = 'ws://127.0.0.1:8080/ws';

// Renkler
const kBg = Color(0xFF0F172A); // Slate 900
const kSurface = Color(0xFF1E293B); // Slate 800
const kCard = Color(0xFF334155); // Slate 700
const kOrange = Color(0xFF3B82F6); // Professional Blue
const kYellow = Color(0xFF60A5FA); // Blue 400
const kTeal = Color(0xFF10B981); // Emerald 500
const kTextSub = Color(0xFF94A3B8); // Slate 400

class MatchScreen extends StatefulWidget {
  const MatchScreen({super.key});

  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen>
    with TickerProviderStateMixin {
  // ─── State ──────────────────────────────────────────────────────────────
  bool _showSetup = true;
  bool _isLoading = false;
  String? _error;

  int? _matchId;
  String _team1Name = '';
  String _team2Name = '';
  int _team1Score = 0;
  int _team2Score = 0;
  int _team1Sets = 0;
  int _team2Sets = 0;
  String _status = 'ACTIVE';

  // Takım seçici için yeni state
  List<dynamic> _availableTeams = [];
  dynamic _selectedTeam1;   // seçilen 1. takım objesi
  dynamic _selectedTeam2;   // seçilen 2. takım objesi
  bool _isLoadingTeams = false;

  // ─── Animasyonlar ───────────────────────────────────────────────────────
  late AnimationController _t1BounceCtrl;
  late AnimationController _t2BounceCtrl;
  late AnimationController _t1GlowCtrl;
  late AnimationController _t2GlowCtrl;
  late Animation<double> _t1Scale;
  late Animation<double> _t2Scale;
  late Animation<double> _t1Glow;
  late Animation<double> _t2Glow;

  StompClient? _stompClient;

  @override
  void initState() {
    super.initState();

    _t1BounceCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _t2BounceCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _t1GlowCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _t2GlowCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));

    _t1Scale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.35).chain(CurveTween(curve: Curves.easeOut)), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.35, end: 1.0).chain(CurveTween(curve: Curves.elasticIn)), weight: 60),
    ]).animate(_t1BounceCtrl);

    _t2Scale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.35).chain(CurveTween(curve: Curves.easeOut)), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.35, end: 1.0).chain(CurveTween(curve: Curves.elasticIn)), weight: 60),
    ]).animate(_t2BounceCtrl);

    _t1Glow = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _t1GlowCtrl, curve: Curves.easeOut),
    );
    _t2Glow = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _t2GlowCtrl, curve: Curves.easeOut),
    );

    _checkActiveMatch();
    _fetchTeams(); // Takımları backend'den çek
  }

  @override
  void dispose() {
    _stompClient?.deactivate();
    _t1BounceCtrl.dispose();
    _t2BounceCtrl.dispose();
    _t1GlowCtrl.dispose();
    _t2GlowCtrl.dispose();
    super.dispose();
  }

  // ─── Backend ────────────────────────────────────────────────────────────
  Future<void> _checkActiveMatch() async {
    try {
      final res = await http.get(Uri.parse('$_baseUrl/api/matches/active'));
      if (res.statusCode == 200) {
        final data = json.decode(utf8.decode(res.bodyBytes));
        setState(() {
          _applyMatchData(data);
          _showSetup = false;
        });
        _connectWebSocket();
      }
    } catch (_) {}
  }

  // Takımları API'den çek
  Future<void> _fetchTeams() async {
    setState(() => _isLoadingTeams = true);
    try {
      final res = await http.get(Uri.parse('$_baseUrl/api/teams'));
      if (res.statusCode == 200) {
        setState(() {
          _availableTeams = json.decode(utf8.decode(res.bodyBytes));
          _isLoadingTeams = false;
        });
      }
    } catch (_) {
      setState(() => _isLoadingTeams = false);
    }
  }

  // Seçilen takım ID'leriyle maç başlat
  Future<void> _startMatchFromTeams() async {
    if (_selectedTeam1 == null || _selectedTeam2 == null) {
      setState(() => _error = 'İki takım seçmem lazım');
      return;
    }
    if (_selectedTeam1['id'] == _selectedTeam2['id']) {
      setState(() => _error = 'Farklı iki takım seç');
      return;
    }
    setState(() { _isLoading = true; _error = null; });
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/api/matches/start-teams'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'team1Id': _selectedTeam1['id'],
          'team2Id': _selectedTeam2['id'],
        }),
      );
      if (res.statusCode == 200) {
        final data = json.decode(utf8.decode(res.bodyBytes));
        setState(() {
          _applyMatchData(data);
          _showSetup = false;
          _isLoading = false;
        });
        _connectWebSocket();
      }
    } catch (e) {
      setState(() { _error = 'Bağlantı hatası'; _isLoading = false; });
    }
  }

  Future<void> _updateScore(int team, int delta) async {
    if (_matchId == null || _status != 'ACTIVE') return;

    HapticFeedback.mediumImpact();

    setState(() {
      if (team == 1) {
        _team1Score = (_team1Score + delta).clamp(0, 999);
        _t1BounceCtrl.forward(from: 0);
        _t1GlowCtrl.forward(from: 0).then((_) => _t1GlowCtrl.reverse());
      } else {
        _team2Score = (_team2Score + delta).clamp(0, 999);
        _t2BounceCtrl.forward(from: 0);
        _t2GlowCtrl.forward(from: 0).then((_) => _t2GlowCtrl.reverse());
      }
    });

    try {
      await http.post(
        Uri.parse('$_baseUrl/api/matches/$_matchId/score'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'team': team, 'delta': delta}),
      );
    } catch (e) {
      debugPrint('Skor hatası: $e');
    }
  }

  Future<void> _finishMatch() async {
    if (_matchId == null) return;
    try {
      final res = await http.post(Uri.parse('$_baseUrl/api/matches/$_matchId/finish'));
      if (res.statusCode == 200) {
        final data = json.decode(utf8.decode(res.bodyBytes));
        setState(() => _applyMatchData(data));
      }
    } catch (_) {}
  }

  void _connectWebSocket() {
    _stompClient = StompClient(
      config: StompConfig(
        url: _wsUrl,
        onConnect: (frame) {
          _stompClient!.subscribe(
            destination: '/topic/score',
            callback: (f) {
              if (f.body != null && mounted) {
                final data = json.decode(f.body!);
                setState(() => _applyMatchData(data));
              }
            },
          );
        },
        onWebSocketError: (e) => debugPrint('WS hata: $e'),
        reconnectDelay: const Duration(seconds: 3),
      ),
    );
    _stompClient!.activate();
  }

  void _applyMatchData(Map<String, dynamic> data) {
    _matchId = (data['id'] ?? data['matchId']) as int?;
    _team1Name = data['team1Name'] ?? '';
    _team2Name = data['team2Name'] ?? '';
    _team1Score = data['team1Score'] ?? 0;
    _team2Score = data['team2Score'] ?? 0;
    _team1Sets = data['team1Sets'] ?? 0;
    _team2Sets = data['team2Sets'] ?? 0;
    _status = data['status'] ?? 'ACTIVE';
  }

  void _resetMatch() {
    _stompClient?.deactivate();
    setState(() {
      _showSetup = true;
      _matchId = null;
      _team1Score = 0;
      _team2Score = 0;
      _team1Sets = 0;
      _team2Sets = 0;
      _status = 'ACTIVE';
      _selectedTeam1 = null;
      _selectedTeam2 = null;
    });
  }

  // ─── UI ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: _showSetup ? _buildSetup() : _buildMatch(),
    );
  }

  // ── Kurulum ─────────────────────────────────────────────────────────────
  Widget _buildSetup() {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Column(
          children: [
            // Üst bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
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
                  const Spacer(),
                  // Geçmiş Maçlar Butonu
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const HistoryScreen()),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.history_rounded, color: Colors.white, size: 16),
                          SizedBox(width: 8),
                          Text(
                            'Geçmiş',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Maç\nBaşlat',
                      style: TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.1,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'İki takım adını gir ve sahaya çık',
                      style: TextStyle(fontSize: 15, color: kTextSub),
                    ),

                    const SizedBox(height: 48),

                    // Takım 1 kutusu
                    _SetupTeamBox(
                      teams: _availableTeams,
                      selectedTeam: _selectedTeam1,
                      onChanged: (val) => setState(() => _selectedTeam1 = val),
                      label: 'Ev Sahibi',
                      number: '1',
                      color: kOrange,
                      gradientColors: const [Color(0xFF3D1A00), Color(0xFF1A0D00)],
                    ),

                    // VS
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Container(
                          width: 52, height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF1E1E38),
                            border: Border.all(color: Colors.white.withOpacity(0.1), width: 1.5),
                            boxShadow: [
                              BoxShadow(color: kOrange.withOpacity(0.15), blurRadius: 20, spreadRadius: 4),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              'VS',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Takım 2 kutusu
                    _SetupTeamBox(
                      teams: _availableTeams,
                      selectedTeam: _selectedTeam2,
                      onChanged: (val) => setState(() => _selectedTeam2 = val),
                      label: 'Deplasman',
                      number: '2',
                      color: kTeal,
                      gradientColors: const [Color(0xFF001A15), Color(0xFF001210)],
                    ),

                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 18),
                            const SizedBox(width: 10),
                            Text(_error!, style: const TextStyle(color: Colors.redAccent)),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 40),

                    // Başlat butonu
                    SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: ElevatedButton(
                        onPressed: _isLoading || _isLoadingTeams ? null : _startMatchFromTeams,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          elevation: 0,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        ),
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [kOrange, kYellow],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: kOrange.withOpacity(0.45),
                                blurRadius: 20,
                                spreadRadius: 1,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Center(
                            child: _isLoading
                                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.sports_volleyball_rounded, color: Colors.white, size: 22),
                                      SizedBox(width: 10),
                                      Text(
                                        'DÜDÜĞÜ ÇAL!',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Maç ─────────────────────────────────────────────────────────────────
  Widget _buildMatch() {
    final isFinished = _status == 'FINISHED';
    final leading = _team1Score > _team2Score ? 1 : (_team2Score > _team1Score ? 2 : 0);

    return Scaffold(
      backgroundColor: kBg,
      body: Column(
        children: [
          // ── Takım 1 paneli (üst)
          Expanded(
            child: _ScorePanel(
              teamName: _team1Name,
              score: _team1Score,
              teamNumber: 1,
              color: kOrange,
              bgColors: const [Color(0xFF1A0800), Color(0xFF0D0500)],
              scaleAnim: _t1Scale,
              glowAnim: _t1Glow,
              isTop: true,
              isFinished: isFinished,
              isLeading: leading == 1,
              onTap: () => _updateScore(1, 1),
              onLongPress: () => _updateScore(1, -1),
            ),
          ),

          // ── Orta bar
          _buildMidBar(isFinished),

          // ── Takım 2 paneli (alt)
          Expanded(
            child: _ScorePanel(
              teamName: _team2Name,
              score: _team2Score,
              teamNumber: 2,
              color: kTeal,
              bgColors: const [Color(0xFF001510), Color(0xFF000F0C)],
              scaleAnim: _t2Scale,
              glowAnim: _t2Glow,
              isTop: false,
              isFinished: isFinished,
              isLeading: leading == 2,
              onTap: () => _updateScore(2, 1),
              onLongPress: () => _updateScore(2, -1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMidBar(bool isFinished) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: const Color(0xFF0E0E20),
        border: Border.symmetric(
          horizontal: BorderSide(color: Colors.white.withOpacity(0.06)),
        ),
      ),
      child: Row(
        children: [
          // Geri
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: IconButton(
              icon: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 14),
              ),
              onPressed: _resetMatch,
            ),
          ),

          // Canlı / Bitti badge
          if (!isFinished)
            _LiveBadge()
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('SONA ERDİ', style: TextStyle(color: kTextSub, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
            ),

          // Skor özeti ortada
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'SETLER: $_team1Sets - $_team2Sets',
                  style: const TextStyle(
                    color: kOrange,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                Text(
                  '$_team1Score  —  $_team2Score',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),

          // İstatistik Butonu
          if (!isFinished && _matchId != null)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: IconButton(
                icon: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.bar_chart_rounded, color: Colors.white, size: 16),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StatisticsScreen(
                        matchId: _matchId!,
                        team1Name: _team1Name,
                        team2Name: _team2Name,
                      ),
                    ),
                  );
                },
              ),
            ),

          // Bitir
          if (!isFinished)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: TextButton(
                onPressed: _confirmFinish,
                style: TextButton.styleFrom(
                  backgroundColor: Colors.red.withOpacity(0.12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
                child: const Text('BİTİR', style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1)),
              ),
            )
          else
            const SizedBox(width: 60),
        ],
      ),
    );
  }

  void _confirmFinish() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A35),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Maçı Bitir?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Setler: $_team1Sets - $_team2Sets',
              style: const TextStyle(color: kOrange, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1),
            ),
            const SizedBox(height: 12),
            Text(
              'Final Skor',
              style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12, letterSpacing: 1),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _scoreChip(_team1Name, _team1Score, kOrange),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('—', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 22)),
                ),
                _scoreChip(_team2Name, _team2Score, kTeal),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Devam Et', style: TextStyle(color: Colors.white.withOpacity(0.5))),
          ),
          ElevatedButton(
            onPressed: () { Navigator.pop(ctx); _finishMatch(); },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Maçı Bitir'),
          ),
        ],
      ),
    );
  }

  Widget _scoreChip(String name, int score, Color color) {
    return Column(
      children: [
        Text(score.toString(), style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: color)),
        const SizedBox(height: 4),
        Text(name, style: const TextStyle(color: kTextSub, fontSize: 12), overflow: TextOverflow.ellipsis),
      ],
    );
  }
}

// ── Canlı Badge ──────────────────────────────────────────────────────────────
class _LiveBadge extends StatefulWidget {
  @override
  State<_LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<_LiveBadge> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.red.withOpacity(0.3 + _ctrl.value * 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7, height: 7,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.5 + _ctrl.value * 0.5),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            const Text('CANLI', style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
          ],
        ),
      ),
    );
  }
}

// ── Score Panel ──────────────────────────────────────────────────────────────
class _ScorePanel extends StatelessWidget {
  final String teamName;
  final int score;
  final int teamNumber;
  final Color color;
  final List<Color> bgColors;
  final Animation<double> scaleAnim;
  final Animation<double> glowAnim;
  final bool isTop;
  final bool isFinished;
  final bool isLeading;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _ScorePanel({
    required this.teamName,
    required this.score,
    required this.teamNumber,
    required this.color,
    required this.bgColors,
    required this.scaleAnim,
    required this.glowAnim,
    required this.isTop,
    required this.isFinished,
    required this.isLeading,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isFinished ? null : onTap,
      onLongPress: isFinished ? null : onLongPress,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: Listenable.merge([scaleAnim, glowAnim]),
        builder: (context, child) {
          return Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isTop ? bgColors : bgColors.reversed.toList(),
                begin: isTop ? Alignment.topCenter : Alignment.bottomCenter,
                end: isTop ? Alignment.bottomCenter : Alignment.topCenter,
              ),
            ),
            child: Stack(
              children: [
                // Arkaplan halkası
                Positioned(
                  right: isTop ? -60 : null,
                  left: isTop ? null : -60,
                  top: isTop ? -60 : null,
                  bottom: isTop ? null : -60,
                  child: AnimatedBuilder(
                    animation: glowAnim,
                    builder: (_, __) => Container(
                      width: 260,
                      height: 260,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            color.withOpacity(0.15 + glowAnim.value * 0.2),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Voleybol ağ çizgisi dekorasyonu
                Positioned.fill(
                  child: CustomPaint(painter: _NetLinePainter(color: color, isTop: isTop)),
                ),

                // İçerik
                SafeArea(
                  top: isTop,
                  bottom: !isTop,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: isTop
                          ? [
                              const Spacer(),
                              _buildTeamBadge(),
                              const Spacer(),
                              _buildScore(),
                              const SizedBox(height: 6),
                              if (!isFinished) _buildHint(),
                              const Spacer(),
                            ]
                          : [
                              const Spacer(),
                              if (!isFinished) _buildHint(),
                              const SizedBox(height: 6),
                              _buildScore(),
                              const Spacer(),
                              _buildTeamBadge(),
                              const Spacer(),
                            ],
                    ),
                  ),
                ),

                // Önde olduğunda şerit göster
                if (isLeading && !isFinished)
                  Positioned(
                    right: 0,
                    top: isTop ? 0 : null,
                    bottom: isTop ? null : 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.only(
                          topLeft: isTop ? Radius.zero : const Radius.circular(10),
                          bottomLeft: isTop ? const Radius.circular(10) : Radius.zero,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 14),
                          SizedBox(height: 2),
                          Text('ÖNDE', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
        child: const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildTeamBadge() {
    return Row(
      children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.5), width: 1.5),
          ),
          child: Center(
            child: Text(
              teamName.isNotEmpty ? teamName[0].toUpperCase() : '?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            teamName.toUpperCase(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 2,
              shadows: [Shadow(color: color.withOpacity(0.6), blurRadius: 10)],
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildScore() {
    return ScaleTransition(
      scale: scaleAnim,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SizedBox(
            width: constraints.maxWidth,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                score.toString().padLeft(2, '0'),
                style: TextStyle(
                  fontSize: 108,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 0.95,
                  letterSpacing: -4,
                  shadows: [
                    Shadow(color: color.withOpacity(0.7), blurRadius: 40),
                    Shadow(color: color.withOpacity(0.3), blurRadius: 80),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHint() {
    return Row(
      children: [
        Icon(Icons.touch_app_rounded, size: 13, color: Colors.white.withOpacity(0.25)),
        const SizedBox(width: 5),
        Text(
          'Dokun +1  •  Basılı tut −1',
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withOpacity(0.25),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

// ── Net Line Dekorasyon ──────────────────────────────────────────────────────
class _NetLinePainter extends CustomPainter {
  final Color color;
  final bool isTop;

  _NetLinePainter({required this.color, required this.isTop});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.04)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Yatay çizgiler
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    // Dikey çizgiler
    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(_NetLinePainter old) => false;
}

// ── Setup Team Box ───────────────────────────────────────────────────────────
class _SetupTeamBox extends StatelessWidget {
  final List<dynamic> teams;
  final dynamic selectedTeam;
  final ValueChanged<dynamic> onChanged;
  final String label;
  final String number;
  final Color color;
  final List<Color> gradientColors;

  const _SetupTeamBox({
    required this.teams,
    required this.selectedTeam,
    required this.onChanged,
    required this.label,
    required this.number,
    required this.color,
    required this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withOpacity(0.25), width: 1.5),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.12), blurRadius: 20, spreadRadius: 2),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withOpacity(0.5)),
                ),
                child: Center(
                  child: Text(number, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 14)),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                label.toUpperCase(),
                style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.5),
              ),
            ],
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<dynamic>(
            value: selectedTeam,
            onChanged: onChanged,
            dropdownColor: const Color(0xFF1A1A35),
            icon: Icon(Icons.keyboard_arrow_down_rounded, color: color),
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              hintText: 'Takım seç...',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 16, fontWeight: FontWeight.w400),
              filled: true,
              fillColor: Colors.white.withOpacity(0.06),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: color.withOpacity(0.2)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: color.withOpacity(0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: color, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            ),
            items: teams.map((team) {
              return DropdownMenuItem<dynamic>(
                value: team,
                child: Text(team['name']),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
