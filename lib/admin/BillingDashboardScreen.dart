import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BillingDashboardScreen extends StatefulWidget {
  final bool embedded;
  const BillingDashboardScreen({Key? key, this.embedded = false}) : super(key: key);

  @override
  _BillingDashboardScreenState createState() => _BillingDashboardScreenState();
}

class _BillingDashboardScreenState extends State<BillingDashboardScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;

  // Billing data
  List<_ClientBillingData> _clientBillingData = [];
  int _totalActiveMedia = 0;
  int _totalActiveDays = 0;
  int _totalDeletedMedia = 0;

  @override
  void initState() {
    super.initState();
    _loadBillingData();
  }

  Future<void> _loadBillingData() async {
    setState(() => _isLoading = true);

    try {
      final snapshot = await _firestore.collection('videos').get();

      Map<String, _ClientBillingData> clientMap = {};
      int totalActive = 0;
      int totalDays = 0;
      int totalDeleted = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final email = data['uploadedByEmail']?.toString() ?? 'Unknown';
        final clientId = data['uploadedBy']?.toString() ?? 'unknown';
        final status = data['status']?.toString() ?? 'active';
        final collectionName = data['collectionName']?.toString() ?? '';
        final createdAt = data['createdAt'] as Timestamp?;
        final activeDays = data['activeDays'] as int?;

        if (!clientMap.containsKey(clientId)) {
          clientMap[clientId] = _ClientBillingData(
            clientId: clientId,
            email: email,
          );
        }

        final client = clientMap[clientId]!;

        if (status == 'active') {
          totalActive++;
          client.activeMedia++;

          if (createdAt != null) {
            final days = DateTime.now().difference(createdAt.toDate()).inDays;
            client.totalActiveDays += days;
            totalDays += days;
          }

          if (!client.collections.contains(collectionName)) {
            client.collections.add(collectionName);
          }
        } else if (status == 'deleted') {
          totalDeleted++;
          client.deletedMedia++;
          if (activeDays != null) {
            client.totalActiveDays += activeDays;
            totalDays += activeDays;
          }
        }
      }

      final billingList = clientMap.values.toList()
        ..sort((a, b) => b.totalActiveDays.compareTo(a.totalActiveDays));

      if (mounted) {
        setState(() {
          _clientBillingData = billingList;
          _totalActiveMedia = totalActive;
          _totalActiveDays = totalDays;
          _totalDeletedMedia = totalDeleted;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading billing data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
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
                    const Text('Billing', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 18)),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, color: Color(0xFFD4AF37), size: 20),
                      onPressed: _loadBillingData,
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37), strokeWidth: 2.5))
                : _clientBillingData.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long_outlined, size: 48, color: Colors.white.withOpacity(0.15)),
                            const SizedBox(height: 16),
                            Text('No billing data', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 16)),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSummaryCards(),
                            const SizedBox(height: 20),
                            _buildClientTable(),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return LayoutBuilder(builder: (context, constraints) {
      final cols = constraints.maxWidth > 800 ? 4 : 2;
      final items = [
        _SummaryItem('Active Media', '$_totalActiveMedia', Icons.play_circle_outline_rounded, const Color(0xFFD4AF37)),
        _SummaryItem('Total Active Days', '$_totalActiveDays', Icons.schedule_rounded, Colors.teal),
        _SummaryItem('Deleted Media', '$_totalDeletedMedia', Icons.delete_outline_rounded, Colors.red),
        _SummaryItem('Clients', '${_clientBillingData.length}', Icons.people_outline_rounded, Colors.blue),
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
                    decoration: BoxDecoration(color: item.color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
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

  Widget _buildClientTable() {
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
            child: Text('Client Billing Summary', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13, fontWeight: FontWeight.w600)),
          ),
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              border: Border(
                top: BorderSide(color: const Color(0xFF222222)),
                bottom: BorderSide(color: const Color(0xFF222222)),
              ),
            ),
            child: Row(
              children: [
                Expanded(flex: 3, child: Text('CLIENT', style: _headerStyle())),
                Expanded(flex: 2, child: Text('TV SCREENS', style: _headerStyle())),
                Expanded(flex: 1, child: Text('ACTIVE', style: _headerStyle(), textAlign: TextAlign.center)),
                Expanded(flex: 1, child: Text('DELETED', style: _headerStyle(), textAlign: TextAlign.center)),
                Expanded(flex: 2, child: Text('TOTAL DAYS', style: _headerStyle(), textAlign: TextAlign.right)),
              ],
            ),
          ),
          ..._clientBillingData.map((client) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFF1E1E1E))),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(client.email, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: client.collections.take(3).map((c) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(4)),
                        child: Text(c.toUpperCase(), style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 9, fontWeight: FontWeight.w600)),
                      )).toList(),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      '${client.activeMedia}',
                      style: TextStyle(color: client.activeMedia > 0 ? const Color(0xFFD4AF37) : Colors.white.withOpacity(0.3), fontSize: 13, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      '${client.deletedMedia}',
                      style: TextStyle(color: client.deletedMedia > 0 ? Colors.red.withOpacity(0.7) : Colors.white.withOpacity(0.3), fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '${client.totalActiveDays} days',
                      style: TextStyle(color: _getDaysColor(client.totalActiveDays), fontSize: 13, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  TextStyle _headerStyle() => TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5);

  Color _getDaysColor(int days) {
    if (days < 7) return Colors.white.withOpacity(0.5);
    if (days < 30) return Colors.orange;
    if (days < 90) return Colors.yellow;
    return const Color(0xFFD4AF37);
  }
}

class _ClientBillingData {
  final String clientId;
  final String email;
  int activeMedia = 0;
  int deletedMedia = 0;
  int totalActiveDays = 0;
  List<String> collections = [];

  _ClientBillingData({required this.clientId, required this.email});
}

class _SummaryItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  _SummaryItem(this.label, this.value, this.icon, this.color);
}
