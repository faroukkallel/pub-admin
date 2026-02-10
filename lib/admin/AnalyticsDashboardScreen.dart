import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AnalyticsDashboardScreen extends StatefulWidget {
  final bool embedded;
  const AnalyticsDashboardScreen({Key? key, this.embedded = false}) : super(key: key);

  @override
  _AnalyticsDashboardScreenState createState() => _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = true;
  String _selectedPeriod = '7d';
  String? _selectedScreen;

  // Aggregated data
  int _totalPlays = 0;
  int _totalSeconds = 0;
  int _uniqueMedia = 0;
  Map<String, int> _playsByScreen = {};
  Map<String, int> _playsByMedia = {};
  Map<String, int> _playsByType = {};
  Map<String, int> _playsByHour = {};
  List<String> _screenNames = [];

  @override
  void initState() {
    super.initState();
    _loadScreenNames();
    _loadAnalytics();
  }

  Future<void> _loadScreenNames() async {
    try {
      final doc = await _firestore.collection('CollNames').doc('Names').get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _screenNames = List<String>.from(data['AllNames'] ?? []);
        });
      }
    } catch (e) {
      debugPrint('Error loading screen names: $e');
    }
  }

  DateTime _getPeriodStart() {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case '24h':
        return now.subtract(const Duration(hours: 24));
      case '7d':
        return now.subtract(const Duration(days: 7));
      case '30d':
        return now.subtract(const Duration(days: 30));
      case '90d':
        return now.subtract(const Duration(days: 90));
      default:
        return now.subtract(const Duration(days: 7));
    }
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);

    try {
      final periodStart = _getPeriodStart();
      Query query = _firestore
          .collection('tv_analytics')
          .where('playedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(periodStart))
          .orderBy('playedAt', descending: true)
          .limit(2000);

      if (_selectedScreen != null) {
        query = query.where('screenName', isEqualTo: _selectedScreen);
      }

      final snapshot = await query.get();

      int totalPlays = 0;
      int totalSeconds = 0;
      Set<String> uniqueMedia = {};
      Map<String, int> playsByScreen = {};
      Map<String, int> playsByMedia = {};
      Map<String, int> playsByType = {};
      Map<String, int> playsByHour = {};

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        totalPlays++;

        final duration = (data['durationSeconds'] as num?)?.toInt() ?? 0;
        totalSeconds += duration;

        final mediaId = data['mediaId']?.toString() ?? 'unknown';
        uniqueMedia.add(mediaId);

        final screenName = data['screenName']?.toString() ?? 'unknown';
        playsByScreen[screenName] = (playsByScreen[screenName] ?? 0) + 1;

        playsByMedia[mediaId] = (playsByMedia[mediaId] ?? 0) + 1;

        final type = data['type']?.toString() ?? 'video';
        playsByType[type] = (playsByType[type] ?? 0) + 1;

        final playedAt = (data['playedAt'] as Timestamp?)?.toDate();
        if (playedAt != null) {
          final hourKey = '${playedAt.hour.toString().padLeft(2, '0')}:00';
          playsByHour[hourKey] = (playsByHour[hourKey] ?? 0) + 1;
        }
      }

      if (mounted) {
        setState(() {
          _totalPlays = totalPlays;
          _totalSeconds = totalSeconds;
          _uniqueMedia = uniqueMedia.length;
          _playsByScreen = playsByScreen;
          _playsByMedia = playsByMedia;
          _playsByType = playsByType;
          _playsByHour = playsByHour;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading analytics: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatDuration(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Column(
        children: [
          if (!widget.embedded)
            SafeArea(
              bottom: false,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                decoration: const BoxDecoration(
                  color: Color(0xFF0A0A0A),
                  border: Border(bottom: BorderSide(color: Color(0xFF1E1E1E), width: 1)),
                ),
                child: Row(
                  children: [
                    const Text('Analytics', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 18)),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, color: Color(0xFFD4AF37), size: 20),
                      onPressed: _loadAnalytics,
                    ),
                  ],
                ),
              ),
            ),
          // Period selector + Screen filter
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF111111),
              border: Border(bottom: BorderSide(color: Color(0xFF1E1E1E), width: 1)),
            ),
            child: Row(
              children: [
                ..._buildPeriodChips(),
                const Spacer(),
                if (_screenNames.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF2A2A2A)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedScreen,
                        hint: Text('All TVs', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                        items: [
                          DropdownMenuItem<String>(value: null, child: Text('All TVs', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12))),
                          ..._screenNames.map((s) => DropdownMenuItem(value: s, child: Text(s.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 12)))),
                        ],
                        onChanged: (v) {
                          setState(() => _selectedScreen = v);
                          _loadAnalytics();
                        },
                        dropdownColor: const Color(0xFF1A1A1A),
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFFD4AF37), size: 16),
                        isDense: true,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37), strokeWidth: 2.5))
                : _totalPlays == 0
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.analytics_outlined, size: 48, color: Colors.white.withOpacity(0.15)),
                            const SizedBox(height: 16),
                            Text('No analytics data yet', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 16)),
                            const SizedBox(height: 6),
                            Text('Data will appear as TVs play media', style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 13)),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildStatCards(),
                            const SizedBox(height: 20),
                            _buildSection('Plays by TV Screen', _buildBarChart(_playsByScreen, const Color(0xFFD4AF37))),
                            const SizedBox(height: 20),
                            _buildSection('Plays by Hour', _buildBarChart(_playsByHour, Colors.teal)),
                            const SizedBox(height: 20),
                            _buildSection('Media Type Breakdown', _buildTypeBreakdown()),
                            const SizedBox(height: 20),
                            _buildSection('Top Media (by plays)', _buildTopMedia()),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPeriodChips() {
    final periods = {'24h': '24H', '7d': '7D', '30d': '30D', '90d': '90D'};
    return periods.entries.map((e) {
      final isSelected = _selectedPeriod == e.key;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: GestureDetector(
          onTap: () {
            setState(() => _selectedPeriod = e.key);
            _loadAnalytics();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFD4AF37) : const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isSelected ? const Color(0xFFD4AF37) : const Color(0xFF2A2A2A)),
            ),
            child: Text(
              e.value,
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.white.withOpacity(0.5),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildStatCards() {
    return LayoutBuilder(builder: (context, constraints) {
      final cols = constraints.maxWidth > 800 ? 4 : 2;
      final items = [
        _StatItem('Total Plays', '$_totalPlays', Icons.play_circle_outline_rounded, const Color(0xFFD4AF37)),
        _StatItem('Watch Time', _formatDuration(_totalSeconds), Icons.schedule_rounded, Colors.teal),
        _StatItem('Unique Media', '$_uniqueMedia', Icons.collections_outlined, Colors.blue),
        _StatItem('Active TVs', '${_playsByScreen.length}', Icons.tv_rounded, Colors.green),
      ];

      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: items.map((item) {
          return SizedBox(
            width: (constraints.maxWidth - (cols - 1) * 12) / cols,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF141414),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF222222)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: item.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(item.icon, color: item.color, size: 18),
                  ),
                  const SizedBox(height: 14),
                  Text(item.value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(item.label, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
                ],
              ),
            ),
          );
        }).toList(),
      );
    });
  }

  Widget _buildSection(String title, Widget child) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF222222)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
            child: Text(title, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13, fontWeight: FontWeight.w600)),
          ),
          child,
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildBarChart(Map<String, int> data, Color color) {
    if (data.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Text('No data', style: TextStyle(color: Colors.white.withOpacity(0.3))),
      );
    }

    final sorted = data.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final maxVal = sorted.first.value;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: sorted.take(12).map((entry) {
          final ratio = maxVal > 0 ? entry.value / maxVal : 0.0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 80,
                  child: Text(
                    entry.key.toUpperCase(),
                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Stack(
                    children: [
                      Container(height: 24, decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(6))),
                      FractionallySizedBox(
                        widthFactor: ratio,
                        child: Container(height: 24, decoration: BoxDecoration(color: color.withOpacity(0.3), borderRadius: BorderRadius.circular(6))),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 40,
                  child: Text('${entry.value}', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700), textAlign: TextAlign.right),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTypeBreakdown() {
    if (_playsByType.isEmpty) {
      return Padding(padding: const EdgeInsets.all(20), child: Text('No data', style: TextStyle(color: Colors.white.withOpacity(0.3))));
    }

    final total = _playsByType.values.fold(0, (a, b) => a + b);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: _playsByType.entries.map((entry) {
          final pct = total > 0 ? (entry.value / total * 100).toStringAsFixed(1) : '0';
          final isVideo = entry.key == 'video';
          final color = isVideo ? const Color(0xFFD4AF37) : Colors.blue;
          return Expanded(
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  Icon(isVideo ? Icons.videocam_rounded : Icons.image_rounded, color: color, size: 24),
                  const SizedBox(height: 8),
                  Text('${entry.value}', style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w700)),
                  Text('$pct%', style: TextStyle(color: color.withOpacity(0.6), fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(entry.key.toUpperCase(), style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTopMedia() {
    if (_playsByMedia.isEmpty) {
      return Padding(padding: const EdgeInsets.all(20), child: Text('No data', style: TextStyle(color: Colors.white.withOpacity(0.3))));
    }

    final sorted = _playsByMedia.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: sorted.take(10).toList().asMap().entries.map((indexed) {
          final entry = indexed.value;
          final rank = indexed.key + 1;
          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Container(
                  width: 24, height: 24,
                  decoration: BoxDecoration(
                    color: rank <= 3 ? const Color(0xFFD4AF37).withOpacity(0.15) : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text(
                      '#$rank',
                      style: TextStyle(
                        color: rank <= 3 ? const Color(0xFFD4AF37) : Colors.white.withOpacity(0.3),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    entry.key,
                    style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text('${entry.value} plays', style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _StatItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  _StatItem(this.label, this.value, this.icon, this.color);
}
