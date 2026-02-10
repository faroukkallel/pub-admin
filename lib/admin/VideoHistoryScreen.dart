import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'VideoModel.dart';
import 'TVSettings.dart';

class VideoHistoryScreen extends StatefulWidget {
  @override
  _VideoHistoryScreenState createState() => _VideoHistoryScreenState();
}

class _VideoHistoryScreenState extends State<VideoHistoryScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<TVSettings> _tvSettings = [];
  String _selectedTVId = '';
  bool _isLoading = true;

  String _statusFilter = 'all';
  String _sortBy = 'newest';
  String? _userFilter;

  bool _editNameMode = false;
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTVSettings();
  }

  Future<void> _loadTVSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      QuerySnapshot collNamesSnapshot = await _firestore.collection('CollNames').get();
      List<String> collectionNames = [];

      if (collNamesSnapshot.docs.isNotEmpty) {
        final namesDoc = collNamesSnapshot.docs.first;
        final namesData = namesDoc.data() as Map<String, dynamic>;
        List<dynamic> allNames = namesData['AllNames'] ?? [];
        collectionNames = List<String>.from(allNames);
      }

      QuerySnapshot tvSettingsSnapshot = await _firestore.collection('tv_settings').get();
      Map<String, TVSettings> settingsMap = {};

      for (var doc in tvSettingsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final collectionName = data['collectionName'] as String?;
        if (collectionName != null) {
          settingsMap[collectionName] = TVSettings.fromMap(data, doc.id);
        }
      }

      _tvSettings = [];
      for (String name in collectionNames) {
        if (settingsMap.containsKey(name)) {
          _tvSettings.add(settingsMap[name]!);
        } else {
          DocumentReference docRef = await _firestore.collection('tv_settings').add({
            'collectionName': name,
            'displayName': name.toUpperCase(),
            'location': '',
            'lastUpdated': Timestamp.now(),
            'updatedBy': _auth.currentUser?.email ?? 'admin'
          });

          _tvSettings.add(TVSettings(
            id: docRef.id,
            collectionName: name,
            displayName: name.toUpperCase(),
            location: '',
            lastUpdated: Timestamp.now(),
            updatedBy: _auth.currentUser?.email ?? 'admin',
          ));
        }
      }

      _tvSettings.sort((a, b) => a.displayName.compareTo(b.displayName));

      if (_tvSettings.isNotEmpty && _selectedTVId.isEmpty) {
        _selectedTVId = _tvSettings.first.id;
      }
    } catch (e) {
      // Error loading TV settings
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _selectTV(String tvId) {
    setState(() {
      _selectedTVId = tvId;
    });
  }

  void _editTVName(TVSettings tv) {
    _displayNameController.text = tv.displayName;
    _locationController.text = tv.location;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 440),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF2A2A2A)),
          ),
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4AF37).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.tv_rounded, color: Color(0xFFD4AF37), size: 20),
                  ),
                  const SizedBox(width: 14),
                  const Text(
                    'Edit TV Details',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildDialogField(controller: _displayNameController, label: 'Display Name', icon: Icons.tv_rounded),
              const SizedBox(height: 14),
              _buildDialogField(controller: _locationController, label: 'Location (optional)', icon: Icons.location_on_outlined),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF333333)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        _saveTVName(tv.id);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD4AF37),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDialogField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13),
        filled: true,
        fillColor: const Color(0xFF0F0F0F),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFD4AF37)),
        ),
        prefixIcon: Icon(icon, color: const Color(0xFFD4AF37), size: 18),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      style: const TextStyle(color: Colors.white, fontSize: 14),
    );
  }

  Future<void> _saveTVName(String tvId) async {
    try {
      await _firestore.collection('tv_settings').doc(tvId).update({
        'displayName': _displayNameController.text.trim(),
        'location': _locationController.text.trim(),
        'lastUpdated': Timestamp.now(),
        'updatedBy': _auth.currentUser?.email ?? 'admin'
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('TV details updated successfully')),
      );

      _loadTVSettings();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update TV details')),
      );
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  TVSettings? get selectedTV {
    if (_selectedTVId.isEmpty) return null;
    for (var tv in _tvSettings) {
      if (tv.id == _selectedTVId) return tv;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    if (_isLoading) {
      return Center(
        child: SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            color: const Color(0xFFD4AF37),
            strokeWidth: 2.5,
          ),
        ),
      );
    }

    if (_tvSettings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.tv_off_rounded, size: 48, color: Colors.white.withOpacity(0.15)),
            const SizedBox(height: 16),
            const Text(
              'No TVs Found',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Add TVs from the Videos tab first',
              style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              onPressed: _loadTVSettings,
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // TV selector
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF111111),
              border: Border(
                bottom: BorderSide(color: Color(0xFF1E1E1E), width: 1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // TV chips
                SizedBox(
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: _tvSettings.map((tv) {
                      bool isSelected = tv.id == _selectedTVId;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => _selectTV(tv.id),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFD4AF37) : const Color(0xFF1A1A1A),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected ? const Color(0xFFD4AF37) : const Color(0xFF2A2A2A),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (tv.displayName.isNotEmpty && tv.displayName != tv.collectionName.toUpperCase()) ...[
                                  Text(
                                    tv.displayName,
                                    style: TextStyle(
                                      color: isSelected ? Colors.black : Colors.white.withOpacity(0.8),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    ' \u2022 ${tv.collectionName.toUpperCase()}',
                                    style: TextStyle(
                                      color: isSelected ? Colors.black.withOpacity(0.5) : Colors.white.withOpacity(0.3),
                                      fontSize: 11,
                                    ),
                                  ),
                                ] else
                                  Text(
                                    tv.collectionName.toUpperCase(),
                                    style: TextStyle(
                                      color: isSelected ? Colors.black : Colors.white.withOpacity(0.7),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                if (isSelected) ...[
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () => _editTVName(tv),
                                    child: Icon(Icons.edit_rounded, size: 14, color: Colors.black.withOpacity(0.5)),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Filter row
          if (selectedTV != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: isMobile
                  ? Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: _buildFilterChip('Status', _statusFilter, ['all', 'active', 'deleted'], (v) => setState(() => _statusFilter = v))),
                            const SizedBox(width: 8),
                            Expanded(child: _buildFilterChip('Sort', _sortBy, ['newest', 'oldest', 'longest', 'shortest'], (v) => setState(() => _sortBy = v))),
                          ],
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        _buildFilterChip('Status', _statusFilter, ['all', 'active', 'deleted'], (v) => setState(() => _statusFilter = v)),
                        const SizedBox(width: 8),
                        _buildFilterChip('Sort', _sortBy, ['newest', 'oldest', 'longest', 'shortest'], (v) => setState(() => _sortBy = v)),
                        const Spacer(),
                        GestureDetector(
                          onTap: _loadTVSettings,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1A1A),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFF2A2A2A)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.refresh_rounded, size: 14, color: const Color(0xFFD4AF37).withOpacity(0.7)),
                                const SizedBox(width: 6),
                                Text(
                                  'Refresh',
                                  style: TextStyle(
                                    color: const Color(0xFFD4AF37).withOpacity(0.7),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
            ),

          // Video grid
          if (selectedTV != null)
            Expanded(
              child: VideoHistoryGrid(
                tv: selectedTV!,
                statusFilter: _statusFilter,
                sortBy: _sortBy,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String currentValue, List<String> options, Function(String) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentValue,
          items: options.map((o) => DropdownMenuItem(
            value: o,
            child: Text(
              o == 'all' ? 'All' : o[0].toUpperCase() + o.substring(1),
              style: const TextStyle(fontSize: 13),
            ),
          )).toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
          style: const TextStyle(color: Colors.white),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFFD4AF37), size: 18),
          dropdownColor: const Color(0xFF1A1A1A),
          isDense: true,
        ),
      ),
    );
  }
}

class VideoHistoryGrid extends StatelessWidget {
  final TVSettings tv;
  final String statusFilter;
  final String sortBy;

  const VideoHistoryGrid({
    Key? key,
    required this.tv,
    this.statusFilter = 'all',
    this.sortBy = 'newest',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QuerySnapshot>(
      future: _buildQuery().get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              color: const Color(0xFFD4AF37),
              strokeWidth: 2.5,
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading videos', style: TextStyle(color: Colors.red.shade300)),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }

        final videos = snapshot.data!.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return VideoModel.fromMap(data, doc.id);
        }).toList();

        _sortVideos(videos);

        return Padding(
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cols = constraints.maxWidth > 1200 ? 4 : constraints.maxWidth > 800 ? 3 : constraints.maxWidth > 500 ? 2 : 1;
              return GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  childAspectRatio: 1.2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                ),
                itemCount: videos.length,
                itemBuilder: (context, index) {
                  return VideoHistoryCard(video: videos[index]);
                },
              );
            },
          ),
        );
      },
    );
  }

  Query _buildQuery() {
    Query query = FirebaseFirestore.instance.collection('videos')
        .where('collectionName', isEqualTo: tv.collectionName);

    if (statusFilter != 'all') {
      query = query.where('status', isEqualTo: statusFilter);
    }

    return query;
  }

  void _sortVideos(List<VideoModel> videos) {
    switch (sortBy) {
      case 'newest':
        videos.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'oldest':
        videos.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case 'longest':
        videos.sort((a, b) {
          final aDays = a.activeDays ?? 0;
          final bDays = b.activeDays ?? 0;
          return bDays.compareTo(aDays);
        });
        break;
      case 'shortest':
        videos.sort((a, b) {
          final aDays = a.activeDays ?? 0;
          final bDays = b.activeDays ?? 0;
          return aDays.compareTo(bDays);
        });
        break;
    }
  }

  Widget _buildEmptyState() {
    String message = 'No videos found';
    if (statusFilter == 'active') {
      message = 'No active videos found';
    } else if (statusFilter == 'deleted') {
      message = 'No deleted videos found';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.videocam_off_outlined, size: 48, color: Colors.white.withOpacity(0.15)),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text('Try changing filters or adding videos', style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 13)),
        ],
      ),
    );
  }
}

class VideoHistoryCard extends StatefulWidget {
  final VideoModel video;

  const VideoHistoryCard({Key? key, required this.video}) : super(key: key);

  @override
  _VideoHistoryCardState createState() => _VideoHistoryCardState();
}

class _VideoHistoryCardState extends State<VideoHistoryCard> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _isExpanded = false;
  bool _isHovering = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  void _initializeController() {
    _controller = VideoPlayerController.network(widget.video.videoUrl);
    _controller.initialize().then((_) {
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _controller.setVolume(0);
          _controller.setLooping(true);
        });
      }
    }).catchError((error) {
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showVideoDetails() {
    showDialog(
      context: context,
      builder: (context) => VideoDetailDialog(video: widget.video),
    );
  }

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return DateFormat('MMM dd, yyyy \u2022 HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    bool isDeleted = widget.video.status == 'deleted';

    return InkWell(
      onTap: _showVideoDetails,
      onHover: (hovering) {
        setState(() {
          _isHovering = hovering;
          if (_isInitialized && !_hasError) {
            if (hovering) {
              _controller.play();
            } else {
              _controller.pause();
            }
          }
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF141414),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isHovering ? const Color(0xFFD4AF37).withOpacity(0.3) : const Color(0xFF222222),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Video thumbnail
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: _hasError
                      ? Container(
                          color: const Color(0xFF0F0F0F),
                          child: Center(child: Icon(Icons.error_outline_rounded, color: Colors.red.withOpacity(0.5), size: 24)),
                        )
                      : !_isInitialized
                          ? Container(
                              color: const Color(0xFF0F0F0F),
                              child: Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(color: const Color(0xFFD4AF37), strokeWidth: 2),
                                ),
                              ),
                            )
                          : VideoPlayer(_controller),
                ),

                // Hover overlay
                if (_isHovering && _isInitialized && !_hasError)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withOpacity(0.2),
                      child: Center(
                        child: Icon(Icons.play_circle_outline_rounded, color: Colors.white.withOpacity(0.8), size: 40),
                      ),
                    ),
                  ),

                // Status badge
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isDeleted ? Colors.red.withOpacity(0.85) : const Color(0xFFD4AF37),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isDeleted ? Icons.delete_outline_rounded : Icons.check_circle_outline_rounded,
                          color: isDeleted ? Colors.white : Colors.black,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isDeleted ? 'Deleted' : 'Active',
                          style: TextStyle(
                            color: isDeleted ? Colors.white : Colors.black,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Days active badge (for deleted)
                if (isDeleted && widget.video.activeDays != null)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${widget.video.activeDays}d active',
                        style: const TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
              ],
            ),

            // Info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isDeleted && widget.video.deletedAt != null
                        ? 'Deleted ${_formatDate(widget.video.deletedAt!)}'
                        : 'Added ${_formatDate(widget.video.createdAt)}',
                    style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isDeleted
                        ? 'By ${widget.video.deletedByEmail ?? 'Unknown'}'
                        : 'By ${widget.video.uploadedByEmail.isNotEmpty ? widget.video.uploadedByEmail : 'Unknown'}',
                    style: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VideoDetailDialog extends StatefulWidget {
  final VideoModel video;

  const VideoDetailDialog({Key? key, required this.video}) : super(key: key);

  @override
  _VideoDetailDialogState createState() => _VideoDetailDialogState();
}

class _VideoDetailDialogState extends State<VideoDetailDialog> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  void _initializeController() {
    _controller = VideoPlayerController.network(widget.video.videoUrl);
    _controller.initialize().then((_) {
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _controller.setVolume(0);
        });
      }
    }).catchError((error) {
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return DateFormat('MMMM dd, yyyy \u2022 HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    bool isDeleted = widget.video.status == 'deleted';
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 700;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 860),
        decoration: BoxDecoration(
          color: const Color(0xFF141414),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF2A2A2A)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF0F0F0F),
                border: Border(
                  bottom: BorderSide(
                    color: isDeleted ? Colors.red.withOpacity(0.2) : const Color(0xFFD4AF37).withOpacity(0.2),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isDeleted ? Colors.red.withOpacity(0.15) : const Color(0xFFD4AF37).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isDeleted ? Icons.delete_outline_rounded : Icons.videocam_rounded,
                      color: isDeleted ? Colors.red : const Color(0xFFD4AF37),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isDeleted ? 'Deleted Video' : 'Active Video',
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          widget.video.collectionName.toUpperCase(),
                          style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: Colors.white.withOpacity(0.4), size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Content
            isMobile
                ? Column(
                    children: [
                      _buildVideoPlayer(),
                      _buildDetailsPanel(isDeleted),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: _buildVideoPlayer()),
                      Expanded(flex: 2, child: _buildDetailsPanel(isDeleted)),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    return Container(
      height: 360,
      color: Colors.black,
      child: _hasError
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline_rounded, color: Colors.red.withOpacity(0.5), size: 40),
                  const SizedBox(height: 12),
                  Text('Video no longer available', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14)),
                ],
              ),
            )
          : !_isInitialized
              ? Center(child: CircularProgressIndicator(color: const Color(0xFFD4AF37), strokeWidth: 2.5))
              : Stack(
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
                            _isPlaying = false;
                          } else {
                            _controller.play();
                            _isPlaying = true;
                          }
                        });
                      },
                      child: Container(
                        color: Colors.transparent,
                        child: AnimatedOpacity(
                          opacity: _isPlaying ? 0.0 : 1.0,
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            Icons.play_circle_filled_rounded,
                            color: Colors.white.withOpacity(0.7),
                            size: 56,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildDetailsPanel(bool isDeleted) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Details',
            style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1),
          ),
          const SizedBox(height: 16),

          _buildDetailItem(Icons.circle, 'Status', widget.video.status.toUpperCase(),
              valueColor: isDeleted ? Colors.red : const Color(0xFFD4AF37)),
          _buildDetailItem(Icons.person_outline_rounded, isDeleted ? 'Deleted By' : 'Added By',
              isDeleted ? widget.video.deletedByEmail ?? 'Unknown' : widget.video.uploadedByEmail),
          _buildDetailItem(Icons.calendar_today_rounded, isDeleted ? 'Deleted On' : 'Added On',
              isDeleted ? _formatDate(widget.video.deletedAt!) : _formatDate(widget.video.createdAt)),

          if (isDeleted && widget.video.activeDays != null)
            _buildDetailItem(Icons.schedule_rounded, 'Active Duration', '${widget.video.activeDays} days',
                valueColor: _getActivityColor(widget.video.activeDays!)),

          if (_isInitialized && !_hasError) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: Icon(
                      _controller.value.volume > 0 ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                      size: 16,
                    ),
                    label: Text(_controller.value.volume > 0 ? 'Mute' : 'Unmute'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF333333)),
                      foregroundColor: Colors.white70,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      setState(() {
                        _controller.setVolume(_controller.value.volume > 0 ? 0 : 1.0);
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.fullscreen_rounded, size: 16),
                    label: const Text('Fullscreen'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4AF37),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FullScreenVideoPage(videoUrl: widget.video.videoUrl),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String title, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFFD4AF37), size: 14),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: valueColor ?? Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getActivityColor(int days) {
    if (days < 7) return Colors.red;
    if (days < 30) return Colors.orange;
    if (days < 90) return Colors.yellow;
    return const Color(0xFFD4AF37);
  }
}

class FullScreenVideoPage extends StatefulWidget {
  final String videoUrl;

  const FullScreenVideoPage({Key? key, required this.videoUrl}) : super(key: key);

  @override
  _FullScreenVideoPageState createState() => _FullScreenVideoPageState();
}

class _FullScreenVideoPageState extends State<FullScreenVideoPage> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _isPlaying = true;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        setState(() {
          _isInitialized = true;
          _controller.play();
        });
      }).catchError((error) {
        setState(() {
          _hasError = true;
        });
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0xFF1E1E1E), width: 1),
                ),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.arrow_back_rounded, color: Colors.white.withOpacity(0.6), size: 18),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Text(
                    'Full Screen',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  const Spacer(),
                  if (_isInitialized && !_hasError)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _controller.setVolume(_controller.value.volume > 0 ? 0 : 1.0);
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _controller.value.volume > 0 ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                          color: Colors.white.withOpacity(0.6),
                          size: 18,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Video
            Expanded(
              child: Center(
                child: _hasError
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline_rounded, color: Colors.red.withOpacity(0.5), size: 48),
                          const SizedBox(height: 16),
                          Text('Error loading video', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 16)),
                        ],
                      )
                    : _isInitialized
                        ? AspectRatio(
                            aspectRatio: _controller.value.aspectRatio,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                VideoPlayer(_controller),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      if (_controller.value.isPlaying) {
                                        _controller.pause();
                                        _isPlaying = false;
                                      } else {
                                        _controller.play();
                                        _isPlaying = true;
                                      }
                                    });
                                  },
                                ),
                                if (!_isPlaying)
                                  Container(
                                    color: Colors.black.withOpacity(0.3),
                                    child: Center(
                                      child: Icon(Icons.play_arrow_rounded, color: Colors.white.withOpacity(0.8), size: 64),
                                    ),
                                  ),
                              ],
                            ),
                          )
                        : CircularProgressIndicator(color: const Color(0xFFD4AF37), strokeWidth: 2.5),
              ),
            ),

            // Bottom controls
            if (_isInitialized && !_hasError)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Color(0xFF1E1E1E), width: 1),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildControlButton(Icons.replay_10_rounded, () {
                      _controller.seekTo(_controller.value.position - const Duration(seconds: 10));
                    }),
                    const SizedBox(width: 24),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          if (_controller.value.isPlaying) {
                            _controller.pause();
                            _isPlaying = false;
                          } else {
                            _controller.play();
                            _isPlaying = true;
                          }
                        });
                      },
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4AF37),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _controller.value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: Colors.black,
                          size: 28,
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    _buildControlButton(Icons.forward_10_rounded, () {
                      _controller.seekTo(_controller.value.position + const Duration(seconds: 10));
                    }),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white.withOpacity(0.7), size: 22),
      ),
    );
  }
}
