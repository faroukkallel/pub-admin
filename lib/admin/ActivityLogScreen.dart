import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'ActivityLogModel.dart';
import 'package:video_player/video_player.dart';

class ActivityLogScreen extends StatefulWidget {
  @override
  _ActivityLogScreenState createState() => _ActivityLogScreenState();
}

class _ActivityLogScreenState extends State<ActivityLogScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _selectedAction;
  String? _selectedCollection;
  String? _selectedClient;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _showFilters = false;

  // Cached filter options to avoid rebuilding dropdowns on every log change
  List<String> _actionOptions = [];
  List<String> _collectionOptions = [];
  Map<String, String> _clientOptions = {}; // clientId -> email
  bool _filterOptionsLoaded = false;

  final GlobalKey<FormState> _filterFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadFilterOptions();
  }

  Future<void> _loadFilterOptions() async {
    try {
      final snapshot = await _firestore.collection('activity_logs')
          .orderBy('timestamp', descending: true)
          .limit(500)
          .get();

      Set<String> actions = {};
      Set<String> collections = {};
      Map<String, String> clients = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final action = data['action']?.toString() ?? '';
        final collName = data['collectionName']?.toString() ?? '';
        final clientId = data['clientId']?.toString() ?? '';
        final clientEmail = data['clientEmail']?.toString() ?? '';

        if (action.isNotEmpty) actions.add(action);
        if (collName.isNotEmpty) collections.add(collName);
        if (clientId.isNotEmpty) clients[clientId] = clientEmail;
      }

      if (mounted) {
        setState(() {
          _actionOptions = actions.toList()..sort();
          _collectionOptions = collections.toList()..sort();
          _clientOptions = clients;
          _filterOptionsLoaded = true;
        });
      }
    } catch (e) {
      debugPrint("Error loading filter options: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Column(
        children: [
          // App bar
          SafeArea(
            bottom: false,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: 14),
              decoration: const BoxDecoration(
                color: Color(0xFF0A0A0A),
                border: Border(
                  bottom: BorderSide(color: Color(0xFF1E1E1E), width: 1),
                ),
              ),
              child: Row(
                children: [
                  const Text(
                    'Activity Logs',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                  ),
                  const Spacer(),
                  // Filter toggle
                  GestureDetector(
                    onTap: () => setState(() => _showFilters = !_showFilters),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: _showFilters
                            ? const Color(0xFFD4AF37).withOpacity(0.15)
                            : const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _showFilters
                              ? const Color(0xFFD4AF37).withOpacity(0.3)
                              : const Color(0xFF2A2A2A),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.filter_list_rounded,
                            size: 16,
                            color: _showFilters ? const Color(0xFFD4AF37) : Colors.white.withOpacity(0.5),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Filters',
                            style: TextStyle(
                              color: _showFilters ? const Color(0xFFD4AF37) : Colors.white.withOpacity(0.5),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (_hasActiveFilters()) ...[
                            const SizedBox(width: 6),
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFFD4AF37),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Filter section
          if (_showFilters)
            _buildFilterSection(isMobile),

          // Logs list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _buildQuery(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(color: const Color(0xFFD4AF37), strokeWidth: 2.5),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history_rounded, size: 48, color: Colors.white.withOpacity(0.1)),
                        const SizedBox(height: 16),
                        Text(
                          'No activity logs found',
                          style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Activity will appear here as users interact',
                          style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 13),
                        ),
                      ],
                    ),
                  );
                }

                final logs = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final logData = logs[index].data() as Map<String, dynamic>;
                    final log = ActivityLogModel.fromMap(logData, logs[index].id);

                    return ActivityLogItem(log: log);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  bool _hasActiveFilters() {
    return _selectedAction != null ||
        _selectedCollection != null ||
        _selectedClient != null ||
        _startDate != null ||
        _endDate != null;
  }

  Widget _buildFilterSection(bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF111111),
        border: Border(
          bottom: BorderSide(color: Color(0xFF1E1E1E), width: 1),
        ),
      ),
      child: Form(
        key: _filterFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Action & TV Screen
            if (isMobile)
              Column(
                children: [
                  _buildFilterDropdown('Action Type', _selectedAction, 'action', (v) => setState(() => _selectedAction = v)),
                  const SizedBox(height: 10),
                  _buildFilterDropdown('TV Screen', _selectedCollection, 'collectionName', (v) => setState(() => _selectedCollection = v)),
                  const SizedBox(height: 10),
                  _buildFilterDropdown('Client', _selectedClient, 'clientId', (v) => setState(() => _selectedClient = v), isClient: true),
                ],
              )
            else
              Row(
                children: [
                  Expanded(child: _buildFilterDropdown('Action Type', _selectedAction, 'action', (v) => setState(() => _selectedAction = v))),
                  const SizedBox(width: 10),
                  Expanded(child: _buildFilterDropdown('TV Screen', _selectedCollection, 'collectionName', (v) => setState(() => _selectedCollection = v))),
                  const SizedBox(width: 10),
                  Expanded(child: _buildFilterDropdown('Client', _selectedClient, 'clientId', (v) => setState(() => _selectedClient = v), isClient: true)),
                ],
              ),

            const SizedBox(height: 12),

            // Date pickers row
            Row(
              children: [
                Expanded(child: _buildDatePicker('Start Date', _startDate, (d) => setState(() => _startDate = d))),
                const SizedBox(width: 10),
                Expanded(child: _buildDatePicker('End Date', _endDate, (d) => setState(() => _endDate = d))),
              ],
            ),

            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _selectedAction = null;
                        _selectedCollection = null;
                        _selectedClient = null;
                        _startDate = null;
                        _endDate = null;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF333333)),
                      foregroundColor: Colors.white70,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Clear All', style: TextStyle(fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() {}),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4AF37),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: const Text('Apply Filters', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterDropdown(String label, String? currentValue, String fieldName, Function(String?) onChanged, {bool isClient = false}) {
    List<DropdownMenuItem<String>> items = [
      DropdownMenuItem<String>(
        value: null,
        child: Text('All', style: TextStyle(color: Colors.white.withOpacity(0.5))),
      ),
    ];

    if (_filterOptionsLoaded) {
      if (isClient) {
        items.addAll(_clientOptions.entries.map((entry) => DropdownMenuItem<String>(
          value: entry.key,
          child: Text(entry.value, style: const TextStyle(color: Colors.white)),
        )));
      } else if (fieldName == 'action') {
        items.addAll(_actionOptions.map((v) => DropdownMenuItem<String>(
          value: v,
          child: Text(v.capitalize(), style: const TextStyle(color: Colors.white)),
        )));
      } else if (fieldName == 'collectionName') {
        items.addAll(_collectionOptions.map((v) => DropdownMenuItem<String>(
          value: v,
          child: Text(v.toUpperCase(), style: const TextStyle(color: Colors.white)),
        )));
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<String>(
          value: currentValue,
          items: items,
          onChanged: onChanged,
          dropdownColor: const Color(0xFF1A1A1A),
          style: const TextStyle(color: Colors.white, fontSize: 13),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFFD4AF37), size: 18),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12),
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ),
    );
  }

  Widget _buildDatePicker(String label, DateTime? value, Function(DateTime) onPicked) {
    return GestureDetector(
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
          builder: (context, child) {
            return Theme(
              data: ThemeData.dark().copyWith(
                colorScheme: ColorScheme.dark(
                  primary: const Color(0xFFD4AF37),
                  onPrimary: Colors.black,
                  surface: const Color(0xFF1A1A1A),
                  onSurface: Colors.white,
                ),
                dialogBackgroundColor: const Color(0xFF141414),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          onPicked(picked);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2A2A2A)),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded, size: 14, color: const Color(0xFFD4AF37).withOpacity(0.6)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 10, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value == null ? 'Select' : DateFormat('MM/dd/yyyy').format(value),
                    style: TextStyle(
                      color: value == null ? Colors.white.withOpacity(0.2) : Colors.white,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Stream<QuerySnapshot> _buildQuery() {
    Query query = _firestore.collection('activity_logs')
        .orderBy('timestamp', descending: true);

    if (_selectedAction != null && _selectedAction!.isNotEmpty) {
      query = query.where('action', isEqualTo: _selectedAction);
    }

    if (_selectedCollection != null && _selectedCollection!.isNotEmpty) {
      query = query.where('collectionName', isEqualTo: _selectedCollection);
    }

    if (_selectedClient != null && _selectedClient!.isNotEmpty) {
      query = query.where('clientId', isEqualTo: _selectedClient);
    }

    // Apply date filters
    if (_startDate != null) {
      query = query.where('timestamp',
          isGreaterThanOrEqualTo: Timestamp.fromDate(_startDate!));
    }

    if (_endDate != null) {
      // End of the selected day
      final endOfDay = DateTime(_endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59);
      query = query.where('timestamp',
          isLessThanOrEqualTo: Timestamp.fromDate(endOfDay));
    }

    return query.snapshots();
  }
}

// Activity Log Item
class ActivityLogItem extends StatelessWidget {
  final ActivityLogModel log;

  ActivityLogItem({required this.log});

  @override
  Widget build(BuildContext context) {
    IconData actionIcon;
    Color actionColor;

    if (log.action == 'upload') {
      actionIcon = Icons.cloud_upload_outlined;
      actionColor = const Color(0xFFD4AF37);
    } else {
      actionIcon = Icons.delete_outline_rounded;
      actionColor = Colors.red;
    }

    final dateFormat = DateFormat('MMM dd, yyyy \u2022 hh:mm a');
    final formattedDate = dateFormat.format(log.timestamp.toDate());

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF222222)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: actionColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(actionIcon, color: actionColor, size: 18),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: actionColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  log.action.capitalize().toUpperCase(),
                  style: TextStyle(
                    color: actionColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  log.clientEmail,
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Text(
                  log.collectionName.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.25),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '  \u2022  $formattedDate',
                  style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 11),
                ),
              ],
            ),
          ),
          iconColor: Colors.white.withOpacity(0.3),
          children: [
            // Video preview
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: const Color(0xFF0F0F0F),
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.antiAlias,
              child: VideoPreview(videoUrl: log.videoUrl),
            ),
            const SizedBox(height: 16),

            // Details grid
            _buildDetailRow('Action', log.action.capitalize(), actionColor),
            _buildDetailRow('Client', log.clientEmail, null),
            _buildDetailRow('Screen', log.collectionName.toUpperCase(), null),
            _buildDetailRow('Time', formattedDate, null),

            if (log.videoCreatedAt != null)
              _buildDetailRow('Upload Date', dateFormat.format(log.videoCreatedAt!.toDate()), null),

            if (log.action == 'delete' && log.activeDays != null)
              _buildDetailRow(
                'Active Duration',
                '${log.activeDays} days',
                log.activeDays! > 30 ? const Color(0xFFD4AF37) : Colors.orange,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, Color? valueColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? Colors.white.withOpacity(0.7),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Detail Row helper
class DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  DetailRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(color: Colors.white.withOpacity(0.3), fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: valueColor ?? Colors.white, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

// Video preview
class VideoPreview extends StatefulWidget {
  final String videoUrl;

  const VideoPreview({Key? key, required this.videoUrl}) : super(key: key);

  @override
  _VideoPreviewState createState() => _VideoPreviewState();
}

class _VideoPreviewState extends State<VideoPreview> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
  }

  void _initializeVideoPlayer() {
    _controller = VideoPlayerController.network(widget.videoUrl);
    _controller.initialize().then((_) {
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    }).catchError((error) {
      // Error initializing video player
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitialized) {
      return Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                if (_controller.value.isPlaying) {
                  _controller.pause();
                } else {
                  _controller.play();
                }
              });
            },
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _controller.value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      );
    } else {
      return Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(color: const Color(0xFFD4AF37), strokeWidth: 2),
        ),
      );
    }
  }
}

// String extension for capitalize
extension StringExtension on String {
  String capitalize() {
    if (this.isEmpty) return this;
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}
