import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:html' as html;
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';
import 'VideoModel.dart';
import 'TVSettings.dart';

class ClientPanel extends StatefulWidget {
  final List<String> accessibleCollections;

  const ClientPanel({
    Key? key,
    required this.accessibleCollections,
  }) : super(key: key);

  @override
  _ClientPanelState createState() => _ClientPanelState();
}

class _ClientPanelState extends State<ClientPanel> {
  String selectedCollection = '';
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  double uploadProgress = 0.0;
  bool isUploading = false;
  List<TVSettings> _tvSettings = [];
  bool _isLoading = true;

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
      QuerySnapshot tvSettingsSnapshot = await _firestore.collection('tv_settings').get();
      Map<String, TVSettings> settingsMap = {};

      for (var doc in tvSettingsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        settingsMap[data['collectionName']] = TVSettings.fromMap(data, doc.id);
      }

      _tvSettings = [];
      for (String name in widget.accessibleCollections) {
        if (settingsMap.containsKey(name)) {
          _tvSettings.add(settingsMap[name]!);
        } else {
          DocumentReference docRef = await _firestore.collection('tv_settings').add({
            'collectionName': name,
            'displayName': name.toUpperCase(),
            'location': '',
            'lastUpdated': Timestamp.now(),
            'updatedBy': _auth.currentUser?.email ?? 'client'
          });

          _tvSettings.add(TVSettings(
            id: docRef.id,
            collectionName: name,
            displayName: name.toUpperCase(),
            location: '',
            lastUpdated: Timestamp.now(),
            updatedBy: _auth.currentUser?.email ?? 'client',
          ));
        }
      }

      _tvSettings.sort((a, b) => a.displayName.compareTo(b.displayName));

      if (_tvSettings.isNotEmpty && selectedCollection.isEmpty) {
        selectedCollection = _tvSettings.first.collectionName;
      }
    } catch (e) {
      // Error loading TV settings
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _signOut() async {
    await _auth.signOut();
    if (context.mounted) {
      Navigator.of(context).pop();
    }
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
              _buildDialogField(
                controller: _displayNameController,
                label: 'Display Name',
                icon: Icons.tv_rounded,
              ),
              const SizedBox(height: 14),
              _buildDialogField(
                controller: _locationController,
                label: 'Location (optional)',
                icon: Icons.location_on_outlined,
              ),
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
        'updatedBy': _auth.currentUser?.email ?? 'client'
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

  Future<void> addMediaFromFile({String type = 'video'}) async {
    html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
    uploadInput.accept = type == 'image' ? 'image/*' : 'video/*';
    uploadInput.click();

    uploadInput.onChange.listen((e) async {
      final files = uploadInput.files;
      if (files!.isEmpty) return;

      final file = files[0];
      final ext = type == 'image' ? '.jpg' : '.mp4';
      final fileName = DateTime.now().millisecondsSinceEpoch.toString() + ext;
      final folder = type == 'image' ? 'images' : 'videos';

      setState(() {
        isUploading = true;
        uploadProgress = 0.0;
      });

      Reference storageReference = FirebaseStorage.instance.ref().child('$folder/$fileName');
      UploadTask uploadTask = storageReference.putBlob(file);

      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        setState(() {
          uploadProgress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        });
      });

      try {
        await uploadTask.whenComplete(() async {
          String mediaUrl = await storageReference.getDownloadURL();
          final now = Timestamp.now();

          // Atomic batch write to prevent orphaned data
          final batch = _firestore.batch();

          final collDocRef = _firestore.collection(selectedCollection).doc();
          batch.set(collDocRef, {
            'videoUrl': mediaUrl,
            'order': now.millisecondsSinceEpoch,
            'type': type,
            'duration': type == 'image' ? 10 : 0,
            'priority': 5,
            'uploadedAt': now,
          });

          final historyDocRef = _firestore.collection('videos').doc();
          batch.set(historyDocRef, {
            'videoUrl': mediaUrl,
            'collectionName': selectedCollection,
            'order': now.millisecondsSinceEpoch,
            'type': type,
            'status': 'active',
            'createdAt': now,
            'uploadedBy': _auth.currentUser?.uid,
            'uploadedByEmail': _auth.currentUser?.email,
          });

          await batch.commit();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${type == 'image' ? 'Image' : 'Video'} uploaded successfully')),
            );
          }
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error uploading: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            isUploading = false;
          });
        }
      }
    });
  }

  Future<void> confirmDeleteVideo(String videoId, String videoUrl, int totalVideos) async {
    if (totalVideos <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot delete the last video. At least one video must remain.')),
      );
      return;
    }

    bool confirmDelete = false;

    await showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF2A2A2A)),
            ),
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 28),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Delete Video',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  'Are you sure you want to delete this video? This action cannot be undone.',
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
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
                          confirmDelete = true;
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirmDelete) {
      deleteVideo(videoId, videoUrl);
    }
  }

  Future<void> deleteVideo(String videoId, String videoUrl) async {
    try {
      QuerySnapshot videoQuery = await _firestore
          .collection('videos')
          .where('videoUrl', isEqualTo: videoUrl)
          .where('status', isEqualTo: 'active')
          .get();

      if (videoQuery.docs.isNotEmpty) {
        final videoDoc = videoQuery.docs.first;
        final videoData = videoDoc.data() as Map<String, dynamic>;

        final createdAt = videoData['createdAt'] as Timestamp;
        final now = DateTime.now();
        final createdDate = createdAt.toDate();
        final activeDays = now.difference(createdDate).inDays;

        await _firestore.collection('videos').doc(videoDoc.id).update({
          'status': 'deleted',
          'deletedAt': Timestamp.now(),
          'deletedBy': _auth.currentUser?.uid,
          'deletedByEmail': _auth.currentUser?.email,
          'activeDays': activeDays,
        });
      }

      await _firestore.collection(selectedCollection).doc(videoId).delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Video deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting video: $e')),
      );
    }
  }

  void _showFullScreenVideo(String videoUrl) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            decoration: BoxDecoration(
              color: const Color(0xFF141414),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF2A2A2A)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.play_circle_outline_rounded, color: Color(0xFFD4AF37), size: 20),
                      const SizedBox(width: 10),
                      const Text('Video Preview', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: VideoPlayerWidget(videoUrl: videoUrl),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  TVSettings? _findTVSettings(String collectionName) {
    for (var tvSetting in _tvSettings) {
      if (tvSetting.collectionName == collectionName) {
        return tvSetting;
      }
    }
    return null;
  }

  String _formatDuration(Duration duration) {
    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;

    if (days > 0) {
      return '$days ${days == 1 ? 'day' : 'days'}, $hours ${hours == 1 ? 'hour' : 'hours'}';
    } else if (hours > 0) {
      return '$hours ${hours == 1 ? 'hour' : 'hours'}, $minutes ${minutes == 1 ? 'min' : 'mins'}';
    } else {
      return '$minutes ${minutes == 1 ? 'minute' : 'minutes'}';
    }
  }

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return DateFormat('MMM dd, yyyy \u2022 HH:mm').format(date);
  }

  Color _getDurationColor(Duration duration) {
    final days = duration.inDays;

    if (days < 7) {
      return Colors.orange;
    } else if (days < 30) {
      return Colors.yellow;
    } else {
      return const Color(0xFFD4AF37);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A0A0A),
        body: Center(
          child: SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              color: const Color(0xFFD4AF37),
              strokeWidth: 2.5,
            ),
          ),
        ),
      );
    }

    TVSettings? currentTVSettings = selectedCollection.isNotEmpty
        ? _findTVSettings(selectedCollection)
        : null;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Column(
        children: [
          // Top app bar
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
                  Image.asset(
                    'assets/prest-zone-logo-removebg.png',
                    height: 26,
                    errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Dashboard',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                  ),
                  const Spacer(),
                  if (currentTVSettings != null && !isMobile)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4AF37).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.tv_rounded, color: Color(0xFFD4AF37), size: 14),
                          const SizedBox(width: 6),
                          Text(
                            currentTVSettings.displayName.isNotEmpty && currentTVSettings.displayName != currentTVSettings.collectionName.toUpperCase()
                                ? '${currentTVSettings.displayName} \u2022 ${currentTVSettings.collectionName.toUpperCase()}'
                                : currentTVSettings.collectionName.toUpperCase(),
                            style: const TextStyle(
                              color: Color(0xFFD4AF37),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(width: 12),
                  InkWell(
                    onTap: _signOut,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.logout_rounded, color: Colors.white.withOpacity(0.5), size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content
          if (widget.accessibleCollections.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_outline_rounded, size: 48, color: Colors.white.withOpacity(0.15)),
                    const SizedBox(height: 16),
                    Text(
                      'No Access',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Contact your administrator for access.',
                      style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 14),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            // TV selector bar
            if (_tvSettings.length > 1)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFF111111),
                  border: Border(
                    bottom: BorderSide(color: Color(0xFF1E1E1E), width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      'TV Screen',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SizedBox(
                        height: 38,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: _tvSettings.map((tv) {
                            bool isSelected = tv.collectionName == selectedCollection;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedCollection = tv.collectionName;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFFD4AF37)
                                        : const Color(0xFF1A1A1A),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFFD4AF37)
                                          : const Color(0xFF2A2A2A),
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
                                            color: isSelected
                                                ? Colors.black.withOpacity(0.5)
                                                : Colors.white.withOpacity(0.3),
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
                                          child: Icon(
                                            Icons.edit_rounded,
                                            size: 14,
                                            color: Colors.black.withOpacity(0.5),
                                          ),
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
                    ),
                  ],
                ),
              ),

            // Upload progress
            if (isUploading)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF141414),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF2A2A2A)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFD4AF37)),
                            strokeWidth: 2,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Uploading video...',
                          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
                        ),
                        const Spacer(),
                        Text(
                          '${uploadProgress.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            color: Color(0xFFD4AF37),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: uploadProgress / 100,
                        backgroundColor: const Color(0xFF2A2A2A),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFD4AF37)),
                        minHeight: 4,
                      ),
                    ),
                  ],
                ),
              ),

            // Video grid
            Expanded(
              child: selectedCollection.isEmpty
                  ? Center(
                      child: Text(
                        'Select a TV to view videos',
                        style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 15),
                      ),
                    )
                  : StreamBuilder<QuerySnapshot>(
                      stream: _firestore
                          .collection(selectedCollection)
                          .orderBy('order', descending: false)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(
                            child: CircularProgressIndicator(
                              color: const Color(0xFFD4AF37),
                              strokeWidth: 2.5,
                            ),
                          );
                        }

                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.videocam_off_outlined, size: 48, color: Colors.white.withOpacity(0.15)),
                                const SizedBox(height: 16),
                                Text(
                                  'No videos yet',
                                  style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 16, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          );
                        }

                        final videoDocs = snapshot.data!.docs;
                        final totalVideos = videoDocs.length;

                        return LayoutBuilder(
                          builder: (context, constraints) {
                            final cols = constraints.maxWidth > 1200
                                ? 4
                                : constraints.maxWidth > 800
                                    ? 3
                                    : constraints.maxWidth > 500
                                        ? 2
                                        : 1;
                            return GridView.builder(
                              padding: const EdgeInsets.all(16),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: cols,
                                crossAxisSpacing: 14,
                                mainAxisSpacing: 14,
                                childAspectRatio: 16 / 13,
                              ),
                              itemCount: totalVideos,
                              itemBuilder: (context, index) {
                                final video = videoDocs[index];
                                final videoData = video.data() as Map<String, dynamic>;

                                Timestamp? uploadTimestamp = videoData['uploadedAt'] as Timestamp?;
                                if (uploadTimestamp == null) {
                                  final orderMs = videoData['order'] as int?;
                                  if (orderMs != null) {
                                    uploadTimestamp = Timestamp.fromMillisecondsSinceEpoch(orderMs);
                                  } else {
                                    uploadTimestamp = Timestamp.now();
                                  }
                                }

                                final now = DateTime.now();
                                final uploadDate = uploadTimestamp.toDate();
                                final activeDuration = now.difference(uploadDate);

                                return _buildVideoCard(
                                  video: video,
                                  index: index,
                                  totalVideos: totalVideos,
                                  uploadTimestamp: uploadTimestamp,
                                  activeDuration: activeDuration,
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
            ),

            // Bottom upload bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF111111),
                border: Border(
                  top: BorderSide(color: Color(0xFF1E1E1E), width: 1),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: selectedCollection.isEmpty || isUploading ? null : () => addMediaFromFile(type: 'video'),
                        icon: const Icon(Icons.videocam_outlined, size: 18),
                        label: const Text('Upload Video'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD4AF37),
                          foregroundColor: Colors.black,
                          disabledBackgroundColor: const Color(0xFF333333),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: selectedCollection.isEmpty || isUploading ? null : () => addMediaFromFile(type: 'image'),
                        icon: const Icon(Icons.image_outlined, size: 18),
                        label: const Text('Upload Image'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A1A1A),
                          foregroundColor: const Color(0xFFD4AF37),
                          disabledBackgroundColor: const Color(0xFF333333),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(color: const Color(0xFFD4AF37).withOpacity(0.3)),
                          ),
                          elevation: 0,
                          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVideoCard({
    required QueryDocumentSnapshot video,
    required int index,
    required int totalVideos,
    required Timestamp uploadTimestamp,
    required Duration activeDuration,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF222222)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Video player
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                GestureDetector(
                  onTap: () => _showFullScreenVideo(video['videoUrl']),
                  child: VideoPlayerWidget(
                    key: ValueKey(video['videoUrl']),
                    videoUrl: video['videoUrl'],
                  ),
                ),
                // Video number
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
                      'Video ${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                // Delete button
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => confirmDeleteVideo(video.id, video['videoUrl'], totalVideos),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Info section
          Container(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 12,
                      color: Colors.white.withOpacity(0.3),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _formatDate(uploadTimestamp),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 12,
                      color: _getDurationColor(activeDuration),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Active: ${_formatDuration(activeDuration)}',
                        style: TextStyle(
                          color: _getDurationColor(activeDuration),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;

  const VideoPlayerWidget({Key? key, required this.videoUrl}) : super(key: key);

  @override
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  void _initializeController() {
    _controller = VideoPlayerController.network(widget.videoUrl);
    _controller.initialize().then((_) {
      if (mounted) {
        _controller.setVolume(0);
        _controller.setLooping(true);
        _controller.play();
        setState(() {
          _isPlaying = true;
        });
      }
    });
  }

  @override
  void didUpdateWidget(covariant VideoPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      _controller.dispose();
      _initializeController();
    }
  }

  @override
  Widget build(BuildContext context) {
    return _controller.value.isInitialized
        ? Stack(
            children: [
              VideoPlayer(_controller),
              Positioned.fill(
                child: GestureDetector(
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
                  child: AnimatedOpacity(
                    opacity: _isPlaying ? 0.0 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      color: Colors.black.withOpacity(0.3),
                      child: Center(
                        child: Icon(
                          Icons.play_circle_filled_rounded,
                          color: Colors.white.withOpacity(0.8),
                          size: 48,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          )
        : Container(
            color: const Color(0xFF0F0F0F),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: const Color(0xFFD4AF37),
                  strokeWidth: 2,
                ),
              ),
            ),
          );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
