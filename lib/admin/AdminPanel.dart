import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:html' as html; // For web file picking
import 'package:video_player/video_player.dart';
import 'UserManagementScreen.dart';
import 'VideoHistoryScreen.dart';
import 'TVSettings.dart';
import 'AnalyticsDashboardScreen.dart';
import 'AnnouncementsScreen.dart';
import 'BillingDashboardScreen.dart';
import 'ActivityLogScreen.dart';

class AdminPanel extends StatefulWidget {
  @override
  _AdminPanelState createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  List<String> collections = [];
  List<TVSettings> _tvSettings = [];
  double uploadProgress = 0.0;
  bool isUploading = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  String selectedCollection = '';
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    fetchCollections();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> fetchCollections() async {
    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('CollNames')
          .doc('Names')
          .get();

      if (snapshot.exists) {
        Map<String, dynamic>? data = snapshot.data() as Map<String, dynamic>?;
        List<dynamic> allNames = data?['AllNames'] ?? [];
        setState(() {
          collections = allNames.cast<String>();
          if (collections.isNotEmpty && selectedCollection.isEmpty) {
            selectedCollection = collections.first;
          }
        });
        await _loadTVSettings();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No collections found. Create one to get started.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading collections: $e')),
        );
      }
    }
  }

  Future<void> _loadTVSettings() async {
    try {
      QuerySnapshot tvSettingsSnapshot = await _firestore.collection('tv_settings').get();
      Map<String, TVSettings> settingsMap = {};

      for (var doc in tvSettingsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final collName = data['collectionName'] as String?;
        if (collName != null) {
          settingsMap[collName] = TVSettings.fromMap(data, doc.id);
        }
      }

      _tvSettings = [];
      for (String name in collections) {
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
      if (mounted) setState(() {});
    } catch (e) {
      // Error loading TV settings
    }
  }

  TVSettings? _findTVSettings(String collectionName) {
    for (var tv in _tvSettings) {
      if (tv.collectionName == collectionName) return tv;
    }
    return null;
  }

  String _getDisplayLabel(String collectionName) {
    final tv = _findTVSettings(collectionName);
    if (tv != null && tv.displayName.isNotEmpty && tv.displayName != collectionName.toUpperCase()) {
      return '${tv.displayName} \u2022 ${collectionName.toUpperCase()}';
    }
    return collectionName.toUpperCase();
  }

  void _editTVName(String collectionName) {
    final tv = _findTVSettings(collectionName);
    if (tv == null) return;

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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Edit TV Details',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        collectionName.toUpperCase(),
                        style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildDialogField(
                controller: _displayNameController,
                label: 'Display Name',
                icon: Icons.label_outline_rounded,
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
        'updatedBy': _auth.currentUser?.email ?? 'admin'
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('TV details updated successfully')),
      );

      _loadTVSettings();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update TV details')),
      );
    }
  }

  Future<void> _signOut() async {
    await _auth.signOut();
    if (context.mounted) {
      Navigator.of(context).pop();
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
          final batch = FirebaseFirestore.instance.batch();

          final collDocRef = FirebaseFirestore.instance
              .collection(selectedCollection)
              .doc();
          batch.set(collDocRef, {
            'videoUrl': mediaUrl,
            'order': now.millisecondsSinceEpoch,
            'type': type,
            'duration': type == 'image' ? 10 : 0,
            'priority': 5,
          });

          final historyDocRef = FirebaseFirestore.instance
              .collection('videos')
              .doc();
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

  void _showMediaConfigDialog(String docId, Map<String, dynamic> currentData) {
    final priorityController = TextEditingController(text: (currentData['priority'] ?? 5).toString());
    final durationController = TextEditingController(text: (currentData['duration'] ?? 10).toString());
    String selectedType = currentData['type'] ?? 'video';
    String playlistGroup = currentData['playlistGroup'] ?? '';
    final playlistController = TextEditingController(text: playlistGroup);

    // Schedule state
    final existingSchedule = currentData['schedule'] as Map<String, dynamic>?;
    bool scheduleEnabled = existingSchedule?['enabled'] ?? false;
    String startTime = existingSchedule?['startTime'] ?? '00:00';
    String endTime = existingSchedule?['endTime'] ?? '23:59';
    List<int> selectedDays = existingSchedule?['daysOfWeek'] != null
        ? List<int>.from(existingSchedule!['daysOfWeek'])
        : [];

    // Expiry state
    DateTime? expiresAt;
    final existingExpiry = currentData['expiresAt'] as Timestamp?;
    if (existingExpiry != null) {
      expiresAt = existingExpiry.toDate();
    }

    // QR code
    final qrUrlController = TextEditingController(text: currentData['qrUrl'] ?? '');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF2A2A2A)),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4AF37).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.tune_rounded, color: Color(0xFFD4AF37), size: 20),
                      ),
                      const SizedBox(width: 14),
                      const Text('Media Settings', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Priority
                  _configLabel('Priority (1-10)'),
                  const SizedBox(height: 8),
                  _configTextField(priorityController, '1-10 (higher = more frequent)', TextInputType.number),

                  if (selectedType == 'image') ...[
                    const SizedBox(height: 14),
                    _configLabel('Display Duration (seconds)'),
                    const SizedBox(height: 8),
                    _configTextField(durationController, 'Seconds', TextInputType.number),
                  ],

                  // Playlist Group
                  const SizedBox(height: 14),
                  _configLabel('Playlist Group (optional)'),
                  const SizedBox(height: 8),
                  _configTextField(playlistController, 'e.g. promo, weekend, happy-hour', TextInputType.text),

                  // QR Code URL
                  const SizedBox(height: 14),
                  _configLabel('QR Code URL (optional)'),
                  const SizedBox(height: 8),
                  _configTextField(qrUrlController, 'https://example.com', TextInputType.url),

                  // Expiry date
                  const SizedBox(height: 14),
                  _configLabel('Expires At (optional)'),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: expiresAt ?? DateTime.now().add(const Duration(days: 30)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        builder: (context, child) => Theme(
                          data: ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(primary: Color(0xFFD4AF37), onPrimary: Colors.black, surface: Color(0xFF1A1A1A), onSurface: Colors.white), dialogBackgroundColor: const Color(0xFF141414)),
                          child: child!,
                        ),
                      );
                      if (picked != null) setDialogState(() => expiresAt = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F0F0F),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF2A2A2A)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today_rounded, size: 14, color: const Color(0xFFD4AF37).withOpacity(0.6)),
                          const SizedBox(width: 10),
                          Text(
                            expiresAt != null ? '${expiresAt!.day}/${expiresAt!.month}/${expiresAt!.year}' : 'No expiry (tap to set)',
                            style: TextStyle(color: expiresAt != null ? Colors.white : Colors.white.withOpacity(0.2), fontSize: 13),
                          ),
                          const Spacer(),
                          if (expiresAt != null)
                            GestureDetector(
                              onTap: () => setDialogState(() => expiresAt = null),
                              child: Icon(Icons.close_rounded, size: 14, color: Colors.white.withOpacity(0.3)),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // Schedule section
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      _configLabel('Schedule'),
                      const Spacer(),
                      Switch(
                        value: scheduleEnabled,
                        onChanged: (v) => setDialogState(() => scheduleEnabled = v),
                        activeColor: const Color(0xFFD4AF37),
                      ),
                    ],
                  ),
                  if (scheduleEnabled) ...[
                    const SizedBox(height: 8),
                    // Time range
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              final parts = startTime.split(':');
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1])),
                                builder: (context, child) => Theme(
                                  data: ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(primary: Color(0xFFD4AF37), onPrimary: Colors.black, surface: Color(0xFF1A1A1A), onSurface: Colors.white)),
                                  child: child!,
                                ),
                              );
                              if (picked != null) {
                                setDialogState(() => startTime = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}');
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: const Color(0xFF0F0F0F), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF2A2A2A))),
                              child: Column(
                                children: [
                                  Text('Start', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 10)),
                                  const SizedBox(height: 4),
                                  Text(startTime, style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 16, fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text('to', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12)),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              final parts = endTime.split(':');
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1])),
                                builder: (context, child) => Theme(
                                  data: ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(primary: Color(0xFFD4AF37), onPrimary: Colors.black, surface: Color(0xFF1A1A1A), onSurface: Colors.white)),
                                  child: child!,
                                ),
                              );
                              if (picked != null) {
                                setDialogState(() => endTime = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}');
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: const Color(0xFF0F0F0F), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF2A2A2A))),
                              child: Column(
                                children: [
                                  Text('End', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 10)),
                                  const SizedBox(height: 4),
                                  Text(endTime, style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 16, fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Days of week
                    _configLabel('Days of Week (empty = all days)'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      children: [
                        _dayChip(1, 'Mon', selectedDays, (days) => setDialogState(() => selectedDays = days)),
                        _dayChip(2, 'Tue', selectedDays, (days) => setDialogState(() => selectedDays = days)),
                        _dayChip(3, 'Wed', selectedDays, (days) => setDialogState(() => selectedDays = days)),
                        _dayChip(4, 'Thu', selectedDays, (days) => setDialogState(() => selectedDays = days)),
                        _dayChip(5, 'Fri', selectedDays, (days) => setDialogState(() => selectedDays = days)),
                        _dayChip(6, 'Sat', selectedDays, (days) => setDialogState(() => selectedDays = days)),
                        _dayChip(7, 'Sun', selectedDays, (days) => setDialogState(() => selectedDays = days)),
                      ],
                    ),
                  ],

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
                          onPressed: () async {
                            final priority = int.tryParse(priorityController.text) ?? 5;
                            final duration = int.tryParse(durationController.text) ?? 10;
                            final updateData = <String, dynamic>{
                              'priority': priority.clamp(1, 10),
                              'duration': duration.clamp(1, 300),
                              'playlistGroup': playlistController.text.trim(),
                              'qrUrl': qrUrlController.text.trim(),
                              'schedule': scheduleEnabled ? {
                                'enabled': true,
                                'startTime': startTime,
                                'endTime': endTime,
                                'daysOfWeek': selectedDays,
                              } : {'enabled': false},
                            };

                            if (expiresAt != null) {
                              updateData['expiresAt'] = Timestamp.fromDate(expiresAt!);
                            } else {
                              updateData['expiresAt'] = FieldValue.delete();
                            }

                            try {
                              await FirebaseFirestore.instance.collection(selectedCollection).doc(docId).update(updateData);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Media settings updated')));
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update settings')));
                              }
                            }
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
        ),
      ),
    );
  }

  Widget _configLabel(String text) {
    return Text(text, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12, fontWeight: FontWeight.w600));
  }

  Widget _configTextField(TextEditingController controller, String hint, TextInputType type) {
    return TextField(
      controller: controller,
      keyboardType: type,
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFF0F0F0F),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF2A2A2A))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF2A2A2A))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFD4AF37))),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 13),
      ),
      style: const TextStyle(color: Colors.white, fontSize: 14),
    );
  }

  Widget _dayChip(int day, String label, List<int> selected, Function(List<int>) onChanged) {
    final isSelected = selected.contains(day);
    return GestureDetector(
      onTap: () {
        final newList = List<int>.from(selected);
        if (isSelected) {
          newList.remove(day);
        } else {
          newList.add(day);
        }
        onChanged(newList);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD4AF37).withOpacity(0.15) : const Color(0xFF0F0F0F),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? const Color(0xFFD4AF37).withOpacity(0.4) : const Color(0xFF2A2A2A)),
        ),
        child: Text(label, style: TextStyle(color: isSelected ? const Color(0xFFD4AF37) : Colors.white.withOpacity(0.4), fontSize: 11, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Future<void> bulkUpload() async {
    html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
    uploadInput.accept = 'video/*,image/*';
    uploadInput.multiple = true;
    uploadInput.click();

    uploadInput.onChange.listen((e) async {
      final files = uploadInput.files;
      if (files == null || files.isEmpty) return;

      setState(() {
        isUploading = true;
        uploadProgress = 0.0;
      });

      for (int i = 0; i < files.length; i++) {
        final file = files[i];
        final isImage = file.type.startsWith('image');
        final type = isImage ? 'image' : 'video';
        final ext = isImage ? '.jpg' : '.mp4';
        final folder = isImage ? 'images' : 'videos';
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_$i$ext';

        Reference storageReference = FirebaseStorage.instance.ref().child('$folder/$fileName');
        UploadTask uploadTask = storageReference.putBlob(file);

        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          if (mounted) {
            setState(() {
              final fileProgress = (snapshot.bytesTransferred / snapshot.totalBytes);
              uploadProgress = ((i + fileProgress) / files.length) * 100;
            });
          }
        });

        try {
          await uploadTask.whenComplete(() async {
            String mediaUrl = await storageReference.getDownloadURL();
            final now = Timestamp.now();

            final batch = FirebaseFirestore.instance.batch();

            final collDocRef = FirebaseFirestore.instance.collection(selectedCollection).doc();
            batch.set(collDocRef, {
              'videoUrl': mediaUrl,
              'order': now.millisecondsSinceEpoch + i,
              'type': type,
              'duration': isImage ? 10 : 0,
              'priority': 5,
            });

            final historyDocRef = FirebaseFirestore.instance.collection('videos').doc();
            batch.set(historyDocRef, {
              'videoUrl': mediaUrl,
              'collectionName': selectedCollection,
              'order': now.millisecondsSinceEpoch + i,
              'type': type,
              'status': 'active',
              'createdAt': now,
              'uploadedBy': _auth.currentUser?.uid,
              'uploadedByEmail': _auth.currentUser?.email,
            });

            await batch.commit();
          });
        } catch (e) {
          debugPrint('Error uploading file $i: $e');
        }
      }

      if (mounted) {
        setState(() {
          isUploading = false;
          uploadProgress = 0.0;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${files.length} files uploaded successfully')),
        );
      }
    });
  }

  Future<void> _sendRestartCommand(String collectionName) async {
    try {
      await FirebaseFirestore.instance.collection('tv_commands').add({
        'screenName': collectionName,
        'command': 'restart',
        'status': 'pending',
        'createdAt': Timestamp.now(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Restart command sent to TV')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send restart command')),
        );
      }
    }
  }

  Future<void> deleteVideo(String videoId, String videoUrl) async {
    try {
      QuerySnapshot videoQuery = await FirebaseFirestore.instance
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

        await FirebaseFirestore.instance.collection('videos').doc(videoDoc.id).update({
          'status': 'deleted',
          'deletedAt': Timestamp.now(),
          'deletedBy': _auth.currentUser?.uid,
          'deletedByEmail': _auth.currentUser?.email,
          'activeDays': activeDays,
        });
      }

      await FirebaseFirestore.instance.collection(selectedCollection).doc(videoId).delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Video deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting video: $e')),
      );
    }
  }

  Future<void> changeVideoOrder(int currentIndex, int targetIndex, List<QueryDocumentSnapshot> videoDocs) async {
    if (targetIndex < 0 || targetIndex >= videoDocs.length) return;

    final currentDoc = videoDocs[currentIndex];
    final targetDoc = videoDocs[targetIndex];

    // Atomic batch write to prevent scrambled order on live TVs
    try {
      final batch = FirebaseFirestore.instance.batch();
      batch.update(
        FirebaseFirestore.instance.collection(selectedCollection).doc(currentDoc.id),
        {'order': targetDoc['order']},
      );
      batch.update(
        FirebaseFirestore.instance.collection(selectedCollection).doc(targetDoc.id),
        {'order': currentDoc['order']},
      );
      await batch.commit();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error updating video order')),
        );
      }
    }
  }

  void showVideoPreview(String videoId) {
    showDialog(
      context: context,
      builder: (context) {
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection(selectedCollection).doc(videoId).get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return AlertDialog(
                title: Text("Error"),
                content: Text("Video not found."),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text("Close", style: TextStyle(color: const Color(0xFFD4AF37))),
                  ),
                ],
              );
            }

            final videoUrl = snapshot.data!['videoUrl'] as String;

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
      },
    );
  }

  Future<void> deleteCollection(String collectionName) async {
    final displayLabel = _getDisplayLabel(collectionName);
    bool confirmDelete = false;

    await showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
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
                  'Delete Collection',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  'Are you sure you want to delete "$displayLabel"? This action cannot be undone.',
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
      try {
        QuerySnapshot collectionSnapshot = await FirebaseFirestore.instance
            .collection(collectionName)
            .get();

        for (var doc in collectionSnapshot.docs) {
          await FirebaseFirestore.instance
              .collection(collectionName)
              .doc(doc.id)
              .delete();
        }

        DocumentReference collNamesDoc = FirebaseFirestore.instance
            .collection('CollNames')
            .doc('Names');
        DocumentSnapshot snapshot = await collNamesDoc.get();

        if (snapshot.exists) {
          List<dynamic> allNames =
              (snapshot.data() as Map<String, dynamic>)['AllNames'] ?? [];
          allNames.remove(collectionName);

          await collNamesDoc.update({'AllNames': allNames});
        }

        // Also delete the tv_settings document for this collection
        final tvSettingsQuery = await FirebaseFirestore.instance
            .collection('tv_settings')
            .where('collectionName', isEqualTo: collectionName)
            .get();
        for (var doc in tvSettingsQuery.docs) {
          await doc.reference.delete();
        }

        setState(() {
          collections.remove(collectionName);
          _tvSettings.removeWhere((tv) => tv.collectionName == collectionName);
          if (selectedCollection == collectionName) {
            selectedCollection = collections.isNotEmpty ? collections.first : '';
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Collection deleted successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete collection')),
        );
      }
    }
  }

  Future<void> addNewCollection() async {
    TextEditingController collectionNameController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
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
                      'Add New TV Screen',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: collectionNameController,
                  decoration: InputDecoration(
                    hintText: 'Enter screen name',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
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
                    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 24),
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
                        onPressed: () async {
                          String newCollection = collectionNameController.text.trim();
                          if (newCollection.isNotEmpty) {
                            try {
                              // Use arrayUnion for race-safe collection name creation
                              // No dummy document needed - the collection will be created
                              // when the first video is uploaded
                              DocumentReference collNamesDoc = FirebaseFirestore.instance
                                  .collection('CollNames')
                                  .doc('Names');

                              await collNamesDoc.set({
                                'AllNames': FieldValue.arrayUnion([newCollection]),
                              }, SetOptions(merge: true));

                              setState(() {
                                if (!collections.contains(newCollection)) {
                                  collections.add(newCollection);
                                }
                                selectedCollection = newCollection;
                              });

                              Navigator.of(context).pop();

                              // Reload TV settings to create entry for new collection
                              _loadTVSettings();

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Collection "$newCollection" added successfully')),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to add collection "$newCollection"')),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD4AF37),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: const Text('Add Screen', style: TextStyle(fontWeight: FontWeight.w600)),
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
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 800;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: isWide ? _buildWideLayout() : _buildNarrowLayout(),
    );
  }

  Widget _buildWideLayout() {
    return Row(
      children: [
        // Sidebar
        Container(
          width: 240,
          decoration: const BoxDecoration(
            color: Color(0xFF111111),
            border: Border(
              right: BorderSide(color: Color(0xFF1E1E1E), width: 1),
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 8),
                child: Row(
                  children: [
                    Image.asset(
                      'assets/prest-zone-logo-removebg.png',
                      height: 28,
                      errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                    ),
                    const SizedBox(width: 10),
                    const Text('Admin', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, const Color(0xFFD4AF37).withOpacity(0.3), Colors.transparent],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildSidebarItem(0, Icons.video_library_outlined, Icons.video_library_rounded, 'Videos'),
              _buildSidebarItem(1, Icons.people_outline_rounded, Icons.people_rounded, 'Users'),
              _buildSidebarItem(2, Icons.history_outlined, Icons.history_rounded, 'History'),
              _buildSidebarItem(3, Icons.analytics_outlined, Icons.analytics_rounded, 'Analytics'),
              _buildSidebarItem(4, Icons.campaign_outlined, Icons.campaign_rounded, 'Announce'),
              _buildSidebarItem(5, Icons.receipt_long_outlined, Icons.receipt_long_rounded, 'Billing'),
              _buildSidebarItem(6, Icons.list_alt_outlined, Icons.list_alt_rounded, 'Logs'),
              const Spacer(),
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF2A2A2A)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4AF37).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.person_outline_rounded, color: Color(0xFFD4AF37), size: 16),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _auth.currentUser?.email ?? 'Admin',
                        style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    InkWell(
                      onTap: _signOut,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(Icons.logout_rounded, color: Colors.white.withOpacity(0.3), size: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                decoration: const BoxDecoration(
                  color: Color(0xFF0A0A0A),
                  border: Border(bottom: BorderSide(color: Color(0xFF1E1E1E), width: 1)),
                ),
                child: Row(
                  children: [
                    Text(
                      _selectedIndex == 0 ? 'Video Management'
                          : _selectedIndex == 1 ? 'User Management'
                          : _selectedIndex == 2 ? 'Video History'
                          : _selectedIndex == 3 ? 'Analytics Dashboard'
                          : _selectedIndex == 4 ? 'Announcements'
                          : _selectedIndex == 5 ? 'Client Billing'
                          : 'Activity Logs',
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.3),
                    ),
                    const Spacer(),
                    if (_selectedIndex == 0 && collections.isNotEmpty)
                      Text('${collections.length} TV screens', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13)),
                  ],
                ),
              ),
              Expanded(
                child: _selectedIndex == 0
                    ? _buildVideoManagementView()
                    : _selectedIndex == 1
                        ? UserManagementScreen(allCollections: collections, embedded: true)
                        : _selectedIndex == 2
                            ? VideoHistoryScreen()
                            : _selectedIndex == 3
                                ? const AnalyticsDashboardScreen(embedded: true)
                                : _selectedIndex == 4
                                    ? const AnnouncementsScreen(embedded: true)
                                    : _selectedIndex == 5
                                        ? const BillingDashboardScreen(embedded: true)
                                        : ActivityLogScreen(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSidebarItem(int index, IconData icon, IconData activeIcon, String label) {
    final isSelected = _selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => setState(() => _selectedIndex = index),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFD4AF37).withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(isSelected ? activeIcon : icon, color: isSelected ? const Color(0xFFD4AF37) : Colors.white.withOpacity(0.35), size: 20),
                const SizedBox(width: 14),
                Text(label, style: TextStyle(color: isSelected ? const Color(0xFFD4AF37) : Colors.white.withOpacity(0.5), fontSize: 14, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400)),
                if (isSelected) ...[const Spacer(), Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFFD4AF37), shape: BoxShape.circle))],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNarrowLayout() {
    return Column(
      children: [
        SafeArea(
          bottom: false,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              color: Color(0xFF0A0A0A),
              border: Border(bottom: BorderSide(color: Color(0xFF1E1E1E), width: 1)),
            ),
            child: Row(
              children: [
                Image.asset('assets/prest-zone-logo-removebg.png', height: 26, errorBuilder: (context, error, stackTrace) => const SizedBox.shrink()),
                const SizedBox(width: 12),
                Text(
                  ['Videos', 'Users', 'History', 'Analytics', 'Announce', 'Billing', 'Logs'][_selectedIndex],
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 18),
                ),
                const Spacer(),
                InkWell(
                  onTap: _signOut,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(10)),
                    child: Icon(Icons.logout_rounded, color: Colors.white.withOpacity(0.5), size: 18),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: _selectedIndex == 0
              ? _buildVideoManagementView()
              : _selectedIndex == 1
                  ? UserManagementScreen(allCollections: collections, embedded: true)
                  : _selectedIndex == 2
                      ? VideoHistoryScreen()
                      : _selectedIndex == 3
                          ? const AnalyticsDashboardScreen(embedded: true)
                          : _selectedIndex == 4
                              ? const AnnouncementsScreen(embedded: true)
                              : _selectedIndex == 5
                                  ? const BillingDashboardScreen(embedded: true)
                                  : ActivityLogScreen(),
        ),
        Container(
          decoration: const BoxDecoration(color: Color(0xFF111111), border: Border(top: BorderSide(color: Color(0xFF1E1E1E), width: 1))),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                child: Row(
                  children: [
                    _buildBottomNavItem(0, Icons.video_library_outlined, Icons.video_library_rounded, 'Videos'),
                    _buildBottomNavItem(1, Icons.people_outline_rounded, Icons.people_rounded, 'Users'),
                    _buildBottomNavItem(2, Icons.history_outlined, Icons.history_rounded, 'History'),
                    _buildBottomNavItem(3, Icons.analytics_outlined, Icons.analytics_rounded, 'Analytics'),
                    _buildBottomNavItem(4, Icons.campaign_outlined, Icons.campaign_rounded, 'Announce'),
                    _buildBottomNavItem(5, Icons.receipt_long_outlined, Icons.receipt_long_rounded, 'Billing'),
                    _buildBottomNavItem(6, Icons.list_alt_outlined, Icons.list_alt_rounded, 'Logs'),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavItem(int index, IconData icon, IconData activeIcon, String label) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD4AF37).withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isSelected ? activeIcon : icon, color: isSelected ? const Color(0xFFD4AF37) : Colors.white.withOpacity(0.35), size: 22),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: isSelected ? const Color(0xFFD4AF37) : Colors.white.withOpacity(0.35), fontSize: 11, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400)),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoManagementView() {
    return selectedCollection.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(width: 32, height: 32, child: CircularProgressIndicator(color: const Color(0xFFD4AF37), strokeWidth: 2.5)),
                const SizedBox(height: 16),
                Text('Loading collections...', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 14)),
              ],
            ),
          )
        : Column(
            children: [
              // TV selector + actions bar
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFF111111),
                  border: Border(bottom: BorderSide(color: Color(0xFF1E1E1E), width: 1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ...collections.map((collection) {
                            final isSelected = collection == selectedCollection;
                            final tv = _findTVSettings(collection);
                            final hasCustomName = tv != null && tv.displayName.isNotEmpty && tv.displayName != collection.toUpperCase();
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                onTap: () => setState(() => selectedCollection = collection),
                                child: StreamBuilder<DocumentSnapshot>(
                                  stream: FirebaseFirestore.instance.collection('tv_heartbeat').doc(collection).snapshots(),
                                  builder: (context, heartbeatSnapshot) {
                                    bool isOnline = false;
                                    if (heartbeatSnapshot.hasData && heartbeatSnapshot.data!.exists) {
                                      final hbData = heartbeatSnapshot.data!.data() as Map<String, dynamic>?;
                                      if (hbData != null && hbData['lastSeen'] != null) {
                                        final lastSeen = (hbData['lastSeen'] as Timestamp).toDate();
                                        isOnline = DateTime.now().difference(lastSeen).inMinutes < 2;
                                      }
                                    }
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: isSelected ? const Color(0xFFD4AF37) : const Color(0xFF1A1A1A),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: isSelected ? const Color(0xFFD4AF37) : const Color(0xFF2A2A2A)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          // Online/offline dot
                                          Container(
                                            width: 8, height: 8,
                                            decoration: BoxDecoration(
                                              color: isOnline ? Colors.green : Colors.red.withOpacity(0.6),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          if (hasCustomName) ...[
                                            Text(
                                              tv.displayName,
                                              style: TextStyle(
                                                color: isSelected ? Colors.black : Colors.white.withOpacity(0.8),
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            Text(
                                              ' \u2022 ${collection.toUpperCase()}',
                                              style: TextStyle(
                                                color: isSelected ? Colors.black.withOpacity(0.5) : Colors.white.withOpacity(0.3),
                                                fontSize: 11,
                                              ),
                                            ),
                                          ] else
                                            Text(
                                              collection.toUpperCase(),
                                              style: TextStyle(
                                                color: isSelected ? Colors.black : Colors.white.withOpacity(0.7),
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          if (isSelected) ...[
                                            const SizedBox(width: 8),
                                            GestureDetector(
                                              onTap: () => _editTVName(collection),
                                              child: Icon(Icons.edit_rounded, size: 13, color: Colors.black.withOpacity(0.5)),
                                            ),
                                            const SizedBox(width: 6),
                                            GestureDetector(
                                              onTap: () => _sendRestartCommand(collection),
                                              child: Icon(Icons.restart_alt_rounded, size: 14, color: Colors.black.withOpacity(0.5)),
                                            ),
                                            const SizedBox(width: 6),
                                            GestureDetector(
                                              onTap: () => deleteCollection(collection),
                                              child: Icon(Icons.close_rounded, size: 14, color: Colors.black.withOpacity(0.5)),
                                            ),
                                          ],
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          }).toList(),
                          GestureDetector(
                            onTap: addNewCollection,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.add_rounded, size: 14, color: const Color(0xFFD4AF37).withOpacity(0.7)),
                                  const SizedBox(width: 6),
                                  Text('Add TV', style: TextStyle(color: const Color(0xFFD4AF37).withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isUploading) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF2A2A2A))),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                SizedBox(width: 16, height: 16, child: CircularProgressIndicator(valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFD4AF37)), strokeWidth: 2)),
                                const SizedBox(width: 12),
                                Text('Uploading video...', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
                                const Spacer(),
                                Text('${uploadProgress.toStringAsFixed(0)}%', style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 13, fontWeight: FontWeight.w600)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(value: uploadProgress / 100, backgroundColor: const Color(0xFF2A2A2A), valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFD4AF37)), minHeight: 4),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection(selectedCollection).orderBy('order', descending: false).snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator(color: const Color(0xFFD4AF37), strokeWidth: 2.5));
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.videocam_off_outlined, size: 48, color: Colors.white.withOpacity(0.15)),
                            const SizedBox(height: 16),
                            Text('No videos yet', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 16, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 6),
                            Text('Upload your first video to get started', style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 13)),
                          ],
                        ),
                      );
                    }
                    final videoDocs = snapshot.data!.docs;
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final cols = constraints.maxWidth > 1200 ? 4 : constraints.maxWidth > 800 ? 3 : constraints.maxWidth > 500 ? 2 : 1;
                        return GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: cols, crossAxisSpacing: 14, mainAxisSpacing: 14, childAspectRatio: 16 / 12),
                          itemCount: videoDocs.length,
                          itemBuilder: (context, index) {
                            final video = videoDocs[index];
                            return _buildVideoCard(video, index, videoDocs);
                          },
                        );
                      },
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(color: Color(0xFF111111), border: Border(top: BorderSide(color: Color(0xFF1E1E1E), width: 1))),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: isUploading ? null : () => addMediaFromFile(type: 'video'),
                          icon: const Icon(Icons.videocam_outlined, size: 18),
                          label: const Text('Video'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD4AF37), foregroundColor: Colors.black,
                            disabledBackgroundColor: const Color(0xFF333333),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                            textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: isUploading ? null : () => addMediaFromFile(type: 'image'),
                          icon: const Icon(Icons.image_outlined, size: 18),
                          label: const Text('Image'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1A1A1A), foregroundColor: const Color(0xFFD4AF37),
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
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: isUploading ? null : bulkUpload,
                          icon: const Icon(Icons.upload_file_rounded, size: 18),
                          label: const Text('Bulk'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1A1A1A), foregroundColor: Colors.teal,
                            disabledBackgroundColor: const Color(0xFF333333),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(color: Colors.teal.withOpacity(0.3)),
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
          );
  }

  Widget _buildVideoCard(QueryDocumentSnapshot video, int index, List<QueryDocumentSnapshot> videoDocs) {
    final data = video.data() as Map<String, dynamic>;
    final mediaType = data['type'] ?? 'video';
    final priority = data['priority'] ?? 5;
    final isImage = mediaType == 'image';
    final playlistGroup = data['playlistGroup'] as String?;
    final hasSchedule = data['schedule'] is Map && (data['schedule'] as Map)['enabled'] == true;
    final expiresAt = data['expiresAt'] as Timestamp?;
    final isExpired = expiresAt != null && expiresAt.toDate().isBefore(DateTime.now());
    final qrUrl = data['qrUrl'] as String?;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isExpired ? Colors.red.withOpacity(0.4) : const Color(0xFF222222)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => isImage ? null : showVideoPreview(video.id),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (isImage)
                    Image.network(data['videoUrl'], fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(color: const Color(0xFF0F0F0F), child: const Center(child: Icon(Icons.broken_image, color: Colors.white24))))
                  else
                    VideoPlayerWidget(key: ValueKey(video['videoUrl']), videoUrl: video['videoUrl']),
                  // Position badge
                  Positioned(top: 8, left: 8, child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(8)),
                    child: Text('#${index + 1}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                  )),
                  // Type badge
                  Positioned(top: 8, right: 8, child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isImage ? Colors.blue.withOpacity(0.85) : const Color(0xFFD4AF37),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(isImage ? Icons.image_rounded : Icons.videocam_rounded, size: 10, color: isImage ? Colors.white : Colors.black),
                        const SizedBox(width: 4),
                        Text(isImage ? 'IMG' : 'VID', style: TextStyle(color: isImage ? Colors.white : Colors.black, fontSize: 9, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  )),
                  // Bottom-left badges row
                  Positioned(bottom: 8, left: 8, right: 8, child: Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      if (priority != 5)
                        _badgePill('P$priority', priority > 5 ? const Color(0xFFD4AF37) : Colors.white54),
                      if (hasSchedule)
                        _badgePill('SCHED', Colors.teal),
                      if (playlistGroup != null && playlistGroup.isNotEmpty)
                        _badgePill(playlistGroup.toUpperCase(), Colors.purple),
                      if (qrUrl != null && qrUrl.isNotEmpty)
                        _badgePill('QR', Colors.cyan),
                      if (isExpired)
                        _badgePill('EXPIRED', Colors.red)
                      else if (expiresAt != null)
                        _badgePill('EXP ${expiresAt.toDate().day}/${expiresAt.toDate().month}', Colors.orange),
                    ],
                  )),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            color: const Color(0xFF141414),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSmallIconButton(icon: Icons.chevron_left_rounded, color: const Color(0xFFD4AF37), onTap: index > 0 ? () => changeVideoOrder(index, index - 1, videoDocs) : null),
                _buildSmallIconButton(icon: Icons.tune_rounded, color: Colors.white.withOpacity(0.5), onTap: () => _showMediaConfigDialog(video.id, data)),
                Text('${index + 1}', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11, fontWeight: FontWeight.w500)),
                _buildSmallIconButton(icon: Icons.chevron_right_rounded, color: const Color(0xFFD4AF37), onTap: index < videoDocs.length - 1 ? () => changeVideoOrder(index, index + 1, videoDocs) : null),
                _buildSmallIconButton(icon: Icons.delete_outline_rounded, color: Colors.red.withOpacity(0.7), onTap: () => deleteVideo(video.id, video['videoUrl'])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _badgePill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(5)),
      child: Text(text, style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.w700)),
    );
  }

  Widget _buildSmallIconButton({required IconData icon, required Color color, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32, height: 32,
        decoration: BoxDecoration(color: onTap != null ? color.withOpacity(0.1) : Colors.transparent, borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: onTap != null ? color : Colors.white.withOpacity(0.1), size: 18),
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
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        _controller.setVolume(0);
        _controller.setLooping(true);
        _controller.play();
        setState(() { _isPlaying = true; });
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
                      if (_controller.value.isPlaying) { _controller.pause(); _isPlaying = false; }
                      else { _controller.play(); _isPlaying = true; }
                    });
                  },
                  child: AnimatedOpacity(
                    opacity: _isPlaying ? 0.0 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      color: Colors.black.withOpacity(0.3),
                      child: Center(child: Icon(Icons.play_circle_filled_rounded, color: Colors.white.withOpacity(0.8), size: 48)),
                    ),
                  ),
                ),
              ),
            ],
          )
        : Container(
            color: const Color(0xFF0F0F0F),
            child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: const Color(0xFFD4AF37), strokeWidth: 2))),
          );
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }
}
