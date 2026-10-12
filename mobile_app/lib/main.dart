import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'translation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'match_screen.dart';
import 'players_screen.dart';
import 'player_edit_sheet.dart';
import 'honours_screen.dart';
import 'tournaments_screen.dart';

const kBg = Color(0xFF0D0D0D); // Deep dark
const kSurface = Color(0xFF1E1E1E); // Surface
const kCard = Color(0xFF262626); // Card
const kPrimary = Color(0xFF34D399); // Vibrant Mint Emerald
const kTeal = Color(0xFF34D399); // Emerald
const kOrange = Color(0xFFFF5A00); // Volleyball Court Orange
const kTextSub = Color(0xFF94A3B8); // Slate 400
const String kBase = 'http://127.0.0.1:8080';

void main() {
  runApp(const RotationApp());
}

class RotationApp extends StatelessWidget {
  const RotationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Rotation',
      translations: AppTranslations(),
      locale: const Locale('tr'),
      fallbackLocale: const Locale('en'),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: kBg,
        colorScheme: const ColorScheme.dark(
          primary: kPrimary,
          surface: kSurface,
        ),
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: kBg,
          elevation: 0,
          centerTitle: false,
          systemOverlayStyle: SystemUiOverlayStyle.light,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: kCard,
          labelStyle: const TextStyle(color: kTextSub),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.06)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.06)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: kPrimary, width: 2),
          ),
        ),
      ),
      home: const DashboardScreen(),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  VOLLEYBALL COURT CUSTOM PAINTER
// ══════════════════════════════════════════════════════════════════════════════
class VolleyballCourtPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final topLeft = Offset(size.width * 0.22, size.height * 0.08);
    final topRight = Offset(size.width * 0.78, size.height * 0.08);
    final bottomRight = Offset(size.width * 0.94, size.height * 0.92);
    final bottomLeft = Offset(size.width * 0.06, size.height * 0.92);
    final court = Path()
      ..moveTo(topLeft.dx, topLeft.dy)
      ..lineTo(topRight.dx, topRight.dy)
      ..lineTo(bottomRight.dx, bottomRight.dy)
      ..lineTo(bottomLeft.dx, bottomLeft.dy)
      ..close();

    canvas.drawPath(
      court.shift(const Offset(0, 7)),
      Paint()
        ..color = Colors.black.withOpacity(0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    canvas.drawPath(
      court,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF234A38), Color(0xFF10271F)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Offset.zero & size),
    );

    final linePaint = Paint()
      ..color = const Color(0xFF8EE7BB).withOpacity(0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawPath(court, linePaint);

    Offset leftAt(double depth) => Offset.lerp(topLeft, bottomLeft, depth)!;
    Offset rightAt(double depth) => Offset.lerp(topRight, bottomRight, depth)!;
    for (final depth in [0.34, 0.66]) {
      canvas.drawLine(leftAt(depth), rightAt(depth), linePaint);
    }

    final netDepth = 0.5;
    final netLeft = leftAt(netDepth);
    final netRight = rightAt(netDepth);
    canvas.drawLine(
      netLeft,
      netRight,
      Paint()
        ..color = Colors.white.withOpacity(0.85)
        ..strokeWidth = 2.4,
    );
    for (var strand = 1; strand < 14; strand++) {
      final point = Offset.lerp(netLeft, netRight, strand / 14)!;
      canvas.drawLine(
        Offset(point.dx, point.dy - 4),
        Offset(point.dx, point.dy + 4),
        Paint()
          ..color = Colors.white.withOpacity(0.28)
          ..strokeWidth = 0.7,
      );
    }

    final ballCenter = Offset(size.width * 0.82, size.height * 0.28);
    canvas.drawCircle(
      ballCenter.translate(0, 2),
      9,
      Paint()..color = Colors.black.withOpacity(0.3),
    );
    canvas.drawCircle(ballCenter, 8, Paint()..color = const Color(0xFFF5A623));
    canvas.drawArc(
      Rect.fromCircle(center: ballCenter, radius: 6),
      -1.1,
      2.1,
      false,
      Paint()
        ..color = Colors.white.withOpacity(0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ══════════════════════════════════════════════════════════════════════════════
//  DASHBOARD SCREEN (MODERN COURT DESIGN)
// ══════════════════════════════════════════════════════════════════════════════
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _tournamentCount = 0;
  bool _hasActiveMatch = false;
  Map<String, dynamic>? _activeMatch;

  @override
  void initState() {
    super.initState();
    _fetchQuickStats();
  }

  Future<void> _fetchQuickStats() async {
    try {
      final resTour = await http.get(Uri.parse('$kBase/api/tournaments'));
      final resMatch = await http.get(Uri.parse('$kBase/api/matches/active'));

      if (mounted) {
        setState(() {
          if (resTour.statusCode == 200) {
            final list = json.decode(utf8.decode(resTour.bodyBytes)) as List;
            _tournamentCount = list.length;
          }
          if (resMatch.statusCode == 200 && resMatch.body.isNotEmpty) {
            _activeMatch = json.decode(utf8.decode(resMatch.bodyBytes));
            _hasActiveMatch = _activeMatch != null && _activeMatch!['status'] == 'ACTIVE';
          }
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              // App Bar / Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [kPrimary, Color(0xFF059669)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: kPrimary.withOpacity(0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.sports_volleyball, color: Colors.black, size: 26),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: const TextSpan(
                              children: [
                                TextSpan(
                                  text: 'ROTA',
                                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2),
                                ),
                                TextSpan(
                                  text: 'TION',
                                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: kPrimary, letterSpacing: 2),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'volleyball_management_system'.tr,
                            style: const TextStyle(color: kTextSub, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: kSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.06)),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.language, color: kPrimary, size: 22),
                      tooltip: 'change_language'.tr,
                      onPressed: () {
                        if (Get.locale?.languageCode == 'en') {
                          Get.updateLocale(const Locale('tr'));
                        } else {
                          Get.updateLocale(const Locale('en'));
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // ─── VOLLEYBALL COURT HERO CARD ─────────────────────────────
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF132A20),
                      const Color(0xFF151D2A),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: kPrimary.withOpacity(0.25), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: kPrimary.withOpacity(0.12),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: VolleyballCourtPainter(),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(22.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildStatBadge('$_tournamentCount', 'tournaments'.tr),
                                if (_hasActiveMatch) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.4),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Colors.redAccent.withOpacity(0.6)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.redAccent,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'live'.tr,
                                          style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _hasActiveMatch
                                      ? '${_activeMatch!['team1Name']} vs ${_activeMatch!['team2Name']}'.toUpperCase()
                                      : 'ROTATION PRO ARENA',
                                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _hasActiveMatch
                                      ? '${'score_label'.tr}${_activeMatch!['team1Score']} - ${_activeMatch!['team2Score']}  |  ${'set_label'.tr}${_activeMatch!['team1Sets']} - ${_activeMatch!['team2Sets']}'
                                      : 'pro_arena_subtitle'.tr,
                                  style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 12, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // ─── ACTION TILES ───────────────────────────────────────────
              _buildModernActionCard(
                context,
                title: 'tournaments'.tr,
                subtitle: 'leagues_and_cups'.tr,
                countText: '$_tournamentCount ${'tournaments_count'.tr}',
                icon: Icons.emoji_events_rounded,
                accentColor: kPrimary,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TournamentsScreen())).then((_) => _fetchQuickStats()),
              ),
              const SizedBox(height: 16),
              _buildModernActionCard(
                context,
                title: 'quick_match'.tr,
                subtitle: 'start_custom_match'.tr,
                countText: _hasActiveMatch ? 'live_match_running'.tr : 'new_match'.tr,
                icon: Icons.scoreboard_rounded,
                accentColor: const Color(0xFF60A5FA),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MatchScreen())).then((_) => _fetchQuickStats()),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatBadge(String count, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Text(
        '$count $label',
        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildModernActionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String countText,
    required IconData icon,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: accentColor.withOpacity(0.2)),
                  ),
                  child: Icon(icon, color: accentColor, size: 26),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(color: kTextSub, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: kCard,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withOpacity(0.04)),
                  ),
                  child: Text(
                    countText,
                    style: TextStyle(color: accentColor, fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_ios_rounded, color: kTextSub, size: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  TEAMS SCREEN
// ══════════════════════════════════════════════════════════════════════════════
class TeamsScreen extends StatefulWidget {
  const TeamsScreen({super.key});

  @override
  State<TeamsScreen> createState() => _TeamsScreenState();
}

class _TeamsScreenState extends State<TeamsScreen> {
  List<dynamic> _teams = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchTeams();
  }

  Future<void> _fetchTeams() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final res = await http.get(Uri.parse('$kBase/api/teams'));
      if (res.statusCode == 200) {
        setState(() {
          _teams = json.decode(utf8.decode(res.bodyBytes));
          _isLoading = false;
        });
      } else {
        setState(() { _error = 'Sunucu hatası: ${res.statusCode}'; _isLoading = false; });
      }
    } catch (_) {
      setState(() { _error = 'connection_error'.tr; _isLoading = false; });
    }
  }

  Future<void> _deleteTeam(int teamId) async {
    try {
      final res = await http.delete(Uri.parse('$kBase/api/teams/$teamId'));
      if (res.statusCode == 200 || res.statusCode == 204) {
        await _fetchTeams();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                res.body.trim().isEmpty
                    ? 'Takım silinemedi (${res.statusCode})'
                    : 'Takım silinemedi: ${res.body.trim()}',
              ),
            ),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('connection_error'.tr)),
        );
      }
    }
  }

  void _openAddTeamSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kBg,
      builder: (_) => AddTeamSheet(onCreated: _fetchTeams),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('teams_directory'.tr, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
        backgroundColor: kBg,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: _buildBody(),
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: kOrange, strokeWidth: 2),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.wifi_off_rounded, color: Colors.redAccent, size: 36),
            ),
            const SizedBox(height: 20),
            Text(
              _error!,
              style: const TextStyle(color: kTextSub, fontSize: 15),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _fetchTeams,
              icon: const Icon(Icons.refresh_rounded, color: kOrange),
              label: Text('retry'.tr, style: TextStyle(color: kOrange)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: kOrange),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    if (_teams.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sports_volleyball, size: 48, color: Colors.white.withOpacity(0.1)),
            const SizedBox(height: 24),
            Text(
              'no_teams_found'.tr,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2),
            ),
            const SizedBox(height: 8),
            Text(
              'add_team_to_start'.tr,
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, letterSpacing: 0.5),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _teams.length,
      padding: const EdgeInsets.only(top: 16, bottom: 100),
      itemBuilder: (context, index) => _TeamCard(
        team: _teams[index],
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TeamDetailScreen(team: _teams[index])),
        ),
        onDelete: () {
          final teamId = _teams[index]['id'] as int;
          final teamName = _teams[index]['name'] ?? '';
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: kSurface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text('remove_team_title'.tr, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
              content: Text(
                '${'are_you_sure_remove'.tr} $teamName?',
                style: const TextStyle(color: Colors.white),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('cancel'.tr, style: const TextStyle(color: kTextSub)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _deleteTeam(teamId);
                  },
                  child: Text('delete'.tr, style: const TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton.extended(
      onPressed: _openAddTeamSheet,
      backgroundColor: kOrange,
      foregroundColor: Colors.white,
      elevation: 0,
      icon: const Icon(Icons.add, size: 20),
      label: Text(
        'new_team'.tr,
        style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1, fontSize: 12),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }
}

// ── Team Card ────────────────────────────────────────────────────────────────
class _TeamCard extends StatelessWidget {
  final dynamic team;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _TeamCard({required this.team, required this.onTap, required this.onDelete});

  Color _avatarColor(String name) {
    final colors = [
      kOrange, kYellow, kTeal,
      const Color(0xFF7C5CBF), const Color(0xFFE91E8C),
    ];
    return colors[name.codeUnitAt(0) % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final name = (team['name'] ?? 'İsimsiz') as String;
    final coach = team['coachName'] as String?;
    final color = _avatarColor(name);
    final initials = name.length >= 2
        ? '${name[0]}${name.split(' ').length > 1 ? name.split(' ')[1][0] : name[1]}'.toUpperCase()
        : name[0].toUpperCase();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Stack(
          children: [
            // Sol kenar accent çizgisi
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.2)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    bottomLeft: Radius.circular(4),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 18, 18),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: kCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: color.withOpacity(0.5)),
                    ),
                    child: Center(
                      child: Text(
                        initials,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        if (coach != null) ...[
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              Icon(Icons.person_outline_rounded, size: 14, color: kTextSub),
                              const SizedBox(width: 4),
                              Text(
                                coach,
                                style: const TextStyle(fontSize: 13, color: kTextSub),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Sil butonu
                  IconButton(
                    onPressed: onDelete,
                    tooltip: 'Takımı sil',
                    constraints: const BoxConstraints.tightFor(width: 44, height: 44),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.red.withOpacity(0.08),
                      foregroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: Colors.red.withOpacity(0.2)),
                      ),
                    ),
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  ),
                  // Chevron
                  Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.3), size: 22),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  ADD TEAM SHEET
// ══════════════════════════════════════════════════════════════════════════════
class AddTeamSheet extends StatefulWidget {
  final VoidCallback onCreated;
  const AddTeamSheet({super.key, required this.onCreated});

  @override
  State<AddTeamSheet> createState() => _AddTeamSheetState();
}

class _AddTeamSheetState extends State<AddTeamSheet> {
  final _nameCtrl = TextEditingController();
  final _coachCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();
  bool _isLoading = false;
  String? _error;

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Takım adı boş olamaz');
      return;
    }
    setState(() { _isLoading = true; _error = null; });

    final body = <String, dynamic>{'name': _nameCtrl.text.trim()};
    if (_coachCtrl.text.trim().isNotEmpty) body['coachName'] = _coachCtrl.text.trim();
    if (_yearCtrl.text.trim().isNotEmpty) {
      body['establishedYear'] = int.tryParse(_yearCtrl.text.trim());
    }

    try {
      final res = await http.post(
        Uri.parse('$kBase/api/teams'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );
      if (res.statusCode == 201) {
        if (mounted) {
          Navigator.pop(context);
          widget.onCreated();
          HapticFeedback.lightImpact();
        }
      } else {
        setState(() { _error = 'Hata: ${res.statusCode}'; _isLoading = false; });
      }
    } catch (e) {
      setState(() { _error = 'Bağlantı hatası'; _isLoading = false; });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _coachCtrl.dispose(); _yearCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(24, 8, 24, 24 + bottom),
      decoration: const BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [kOrange, kYellow]),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.group_add_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('new_team_cap'.tr, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                  Text('enter_team_info'.tr, style: TextStyle(fontSize: 13, color: kTextSub)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Takım Adı
          _sheetField(
            controller: _nameCtrl,
            label: 'Takım Adı *',
            icon: Icons.shield_rounded,
            hint: 'örn. Fenerbahçe',
          ),
          const SizedBox(height: 14),

          // Koç
          _sheetField(
            controller: _coachCtrl,
            label: 'Koç Adı',
            icon: Icons.person_rounded,
            hint: 'örn. Ahmet Yılmaz',
          ),
          const SizedBox(height: 14),

          // Kuruluş yılı
          _sheetField(
            controller: _yearCtrl,
            label: 'Kuruluş Yılı',
            icon: Icons.calendar_today_rounded,
            hint: 'örn. 2010',
            keyboardType: TextInputType.number,
          ),

          if (_error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 18),
                  const SizedBox(width: 8),
                  Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
                ],
              ),
            ),
          ],

          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: kOrange,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isLoading
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text('save_team'.tr, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sheetField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
        prefixIcon: Icon(icon, color: kOrange, size: 20),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  TEAM DETAIL SCREEN
// ══════════════════════════════════════════════════════════════════════════════
class TeamDetailScreen extends StatefulWidget {
  final dynamic team;
  const TeamDetailScreen({super.key, required this.team});

  @override
  State<TeamDetailScreen> createState() => _TeamDetailScreenState();
}

class _TeamDetailScreenState extends State<TeamDetailScreen> {
  List<dynamic> _players = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchPlayers();
  }

  Future<void> _fetchPlayers() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final id = widget.team['id'];
      final res = await http.get(Uri.parse('$kBase/api/teams/$id/players'));
      if (res.statusCode == 200) {
        setState(() { _players = json.decode(utf8.decode(res.bodyBytes)); _isLoading = false; });
      } else {
        setState(() { _error = 'Hata: ${res.statusCode}'; _isLoading = false; });
      }
    } catch (_) {
      setState(() { _error = 'Bağlantı hatası'; _isLoading = false; });
    }
  }

  void _openAddPlayerSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kBg,
      builder: (_) => AddPlayerSheet(
        teamId: widget.team['id'],
        onCreated: _fetchPlayers,
      ),
    );
  }

  void _editPlayer(Map<String, dynamic> player) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PlayerEditSheet(
        player: player,
        teamId: int.parse('${widget.team['id']}'),
        onSaved: () {
          _fetchPlayers();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('player_updated'.tr)));
        },
      ),
    );
  }

  Future<void> _confirmDeletePlayer(Map<String, dynamic> player) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: kSurface,
        title: Text('delete_player'.tr, style: const TextStyle(color: Colors.white)),
        content: Text(
          '${player['firstName'] ?? ''} ${player['lastName'] ?? ''}\n${'player_delete_confirmation'.tr}',
          style: const TextStyle(color: kTextSub),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text('cancel'.tr)),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text('delete'.tr, style: const TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      final teamId = widget.team['id'];
      final playerId = player['id'];
      final response = await http.delete(Uri.parse('$kBase/api/teams/$teamId/players/$playerId'));
      if (response.statusCode == 200 || response.statusCode == 204) {
        await _fetchPlayers();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('player_deleted'.tr)));
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${'error_occurred'.tr} (${response.statusCode})')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('connection_error'.tr)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.team['name'] ?? 'Takım';
    final coach = widget.team['coachName'] as String?;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: kBg,
            leading: IconButton(
              icon: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Colors.white),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  color: kSurface,
                ),
                padding: const EdgeInsets.fromLTRB(24, 90, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: kCard,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: kOrange.withOpacity(0.5)),
                          ),
                          child: Center(
                            child: Text(
                              name[0].toUpperCase(),
                              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
                              if (coach != null)
                                Row(
                                  children: [
                                    const Icon(Icons.person_outline_rounded, size: 14, color: kTextSub),
                                    const SizedBox(width: 4),
                                    Text(coach, style: const TextStyle(color: kTextSub, fontSize: 13)),
                                  ],
                                ),
                            ],
                          ),
                        ),
                        // Başarılar Butonu
                        GestureDetector(
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => HonoursScreen(
                              teamId: widget.team['id'],
                              titleName: name,
                            )));
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: kSurface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: kOrange.withOpacity(0.3)),
                            ),
                            child: const Icon(Icons.emoji_events, color: kOrange, size: 24),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            sliver: _buildPlayersList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddPlayerSheet,
        backgroundColor: kOrange, // Professional Orange
        foregroundColor: Colors.white,
        elevation: 0,
        icon: const Icon(Icons.person_add, size: 20),
        label: Text('add_player'.tr, style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1, fontSize: 12)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // Sharp edges
      ),
    );
  }

  Widget _buildPlayersList() {
    if (_isLoading) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator(color: kOrange, strokeWidth: 2)),
      );
    }
    if (_error != null) {
      return SliverFillRemaining(
        child: Center(child: Text(_error!, style: const TextStyle(color: kTextSub))),
      );
    }
    if (_players.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.group, size: 48, color: Colors.white.withOpacity(0.1)),
              const SizedBox(height: 16),
              Text('no_players_yet'.tr, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1)),
              const SizedBox(height: 8),
              Text('tap_add_player_to_begin'.tr, style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
            ],
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, i) => _PlayerCard(
          player: _players[i],
          onEdit: () => _editPlayer(Map<String, dynamic>.from(_players[i] as Map)),
          onDelete: () => _confirmDeletePlayer(Map<String, dynamic>.from(_players[i] as Map)),
        ),
        childCount: _players.length,
      ),
    );
  }
}

// ── Player Card ──────────────────────────────────────────────────────────────
class _PlayerCard extends StatelessWidget {
  final dynamic player;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _PlayerCard({required this.player, required this.onEdit, required this.onDelete});

  static const _posMap = {
    'SETTER': ('Pasör', kTeal),
    'OUTSIDE_HITTER': ('Smaçör', kOrange),
    'MIDDLE_BLOCKER': ('Orta', kYellow),
    'OPPOSITE_HITTER': ('Çapraz', Color(0xFF9B59B6)),
    'LIBERO': ('Libero', Color(0xFFE91E8C)),
  };

  @override
  Widget build(BuildContext context) {
    final pos = _posMap[player['position']] ?? ('Bilinmiyor', kTextSub);
    final posLabel = pos.$1;
    final posColor = pos.$2;
    final jersey = player['jerseyNumber']?.toString() ?? '?';
    final double playerValue = (player['playerValue'] ?? 0).toDouble();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          // Jersey number
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: kCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: posColor.withOpacity(0.5), width: 2),
            ),
            child: Center(
              child: Text(
                jersey,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: posColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${player['firstName']} ${player['lastName']}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: posColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(posLabel, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: posColor)),
                    ),
                    if (player['heightCm'] != null) ...[
                      const SizedBox(width: 8),
                      Text('${player['heightCm']} cm', style: const TextStyle(fontSize: 12, color: kTextSub)),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Player Value
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: kBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Column(
              children: [
                Text(
                  playerValue.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: _valueColor(playerValue),
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'OVR',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: kTextSub, letterSpacing: 1),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: onEdit,
                tooltip: 'edit_player'.tr,
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.edit_outlined, color: kTeal, size: 20),
              ),
              IconButton(
                onPressed: onDelete,
                tooltip: 'delete_player'.tr,
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _valueColor(double val) {
    if (val >= 90) return const Color(0xFF10B981); // Green
    if (val >= 80) return const Color(0xFF34D399); // Light Green
    if (val >= 70) return const Color(0xFFFFC000); // Blue
    if (val >= 60) return const Color(0xFFFBBF24); // Yellow
    return const Color(0xFFEF4444); // Red
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  ADD PLAYER SHEET
// ══════════════════════════════════════════════════════════════════════════════
class AddPlayerSheet extends StatefulWidget {
  final dynamic teamId;
  final VoidCallback onCreated;
  const AddPlayerSheet({super.key, required this.teamId, required this.onCreated});

  @override
  State<AddPlayerSheet> createState() => _AddPlayerSheetState();
}

class _AddPlayerSheetState extends State<AddPlayerSheet> {
  final _firstCtrl = TextEditingController();
  final _lastCtrl = TextEditingController();
  final _jerseyCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  String _position = 'SETTER';
  bool _isLoading = false;
  String? _error;

  static const _positions = [
    ('SETTER', 'Pasör'),
    ('OUTSIDE_HITTER', 'Smaçör'),
    ('MIDDLE_BLOCKER', 'Orta Oyuncu'),
    ('OPPOSITE_HITTER', 'Çapraz'),
    ('LIBERO', 'Libero'),
  ];

  Future<void> _submit() async {
    if (_firstCtrl.text.trim().isEmpty || _lastCtrl.text.trim().isEmpty || _jerseyCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Ad, soyad ve forma numarası zorunludur');
      return;
    }
    setState(() { _isLoading = true; _error = null; });
    final body = {
      'firstName': _firstCtrl.text.trim(),
      'lastName': _lastCtrl.text.trim(),
      'jerseyNumber': int.tryParse(_jerseyCtrl.text.trim()) ?? 0,
      'position': _position,
      if (_heightCtrl.text.trim().isNotEmpty) 'heightCm': int.tryParse(_heightCtrl.text.trim()),
    };
    try {
      final res = await http.post(
        Uri.parse('$kBase/api/teams/${widget.teamId}/players'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );
      if (res.statusCode == 201) {
        if (mounted) {
          Navigator.pop(context);
          widget.onCreated();
          HapticFeedback.lightImpact();
        }
      } else {
        setState(() { _error = 'Hata: ${res.statusCode}'; _isLoading = false; });
      }
    } catch (e) {
      setState(() { _error = 'Bağlantı hatası'; _isLoading = false; });
    }
  }

  @override
  void dispose() {
    _firstCtrl.dispose(); _lastCtrl.dispose();
    _jerseyCtrl.dispose(); _heightCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(24, 8, 24, 24 + bottom),
      decoration: const BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [kTeal, Color(0xFF0099CC)]),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.person_add_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('new_player'.tr, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                    Text('enter_player_info'.tr, style: TextStyle(fontSize: 13, color: kTextSub)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(child: _field(_firstCtrl, 'Ad *', Icons.badge_rounded)),
                const SizedBox(width: 12),
                Expanded(child: _field(_lastCtrl, 'Soyad *', Icons.badge_outlined)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _field(_jerseyCtrl, 'Forma No *', Icons.tag_rounded, keyboard: TextInputType.number)),
                const SizedBox(width: 12),
                Expanded(child: _field(_heightCtrl, 'Boy (cm)', Icons.height_rounded, keyboard: TextInputType.number)),
              ],
            ),
            const SizedBox(height: 16),

            Text('position'.tr, style: TextStyle(color: kTextSub, fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _positions.map((p) {
                final isSelected = _position == p.$1;
                return GestureDetector(
                  onTap: () => setState(() => _position = p.$1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: isSelected ? kOrange : kCard,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? kOrange : Colors.white.withOpacity(0.1),
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      p.$2,
                      style: TextStyle(
                        color: isSelected ? Colors.white : kTextSub,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kTeal,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isLoading
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text('save_player'.tr, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon, {TextInputType? keyboard}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboard,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: kTeal, size: 18),
      ),
    );
  }
}
