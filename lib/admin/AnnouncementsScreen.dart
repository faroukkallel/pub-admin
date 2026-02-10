import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class AnnouncementsScreen extends StatefulWidget {
  final bool embedded;
  const AnnouncementsScreen({Key? key, this.embedded = false}) : super(key: key);

  @override
  _AnnouncementsScreenState createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<String> _screenNames = [];

  @override
  void initState() {
    super.initState();
    _loadScreenNames();
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

  void _showAnnouncementDialog({DocumentSnapshot? existing}) {
    final textController = TextEditingController(text: existing != null ? (existing.data() as Map<String, dynamic>)['text'] ?? '' : '');
    bool isActive = existing != null ? (existing.data() as Map<String, dynamic>)['active'] ?? true : true;
    List<String> selectedScreens = existing != null
        ? List<String>.from((existing.data() as Map<String, dynamic>)['targetScreens'] ?? ['all'])
        : ['all'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
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
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4AF37).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.campaign_rounded, color: Color(0xFFD4AF37), size: 20),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      existing != null ? 'Edit Announcement' : 'New Announcement',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Text field
                Text('Announcement Text', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  controller: textController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Enter announcement text...',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 13),
                    filled: true,
                    fillColor: const Color(0xFF0F0F0F),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF2A2A2A))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF2A2A2A))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFD4AF37))),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
                const SizedBox(height: 16),
                // Active toggle
                Row(
                  children: [
                    Text('Active', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Switch(
                      value: isActive,
                      onChanged: (v) => setDialogState(() => isActive = v),
                      activeColor: const Color(0xFFD4AF37),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Target screens
                Text('Target Screens', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildScreenChip('all', 'All TVs', selectedScreens, (screens) => setDialogState(() => selectedScreens = screens)),
                    ..._screenNames.map((name) =>
                        _buildScreenChip(name, name.toUpperCase(), selectedScreens, (screens) => setDialogState(() => selectedScreens = screens))),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    if (existing != null)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            await existing.reference.delete();
                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                            foregroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      )
                    else
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
                          final text = textController.text.trim();
                          if (text.isEmpty) return;

                          final docData = {
                            'text': text,
                            'active': isActive,
                            'targetScreens': selectedScreens,
                            'updatedAt': Timestamp.now(),
                            'updatedBy': _auth.currentUser?.email ?? 'admin',
                          };

                          if (existing != null) {
                            await existing.reference.update(docData);
                          } else {
                            docData['createdAt'] = Timestamp.now();
                            docData['createdBy'] = _auth.currentUser?.email ?? 'admin';
                            await _firestore.collection('announcements').add(docData);
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
                        child: Text(existing != null ? 'Update' : 'Create', style: const TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScreenChip(String value, String label, List<String> selected, Function(List<String>) onChanged) {
    final isSelected = selected.contains(value);
    return GestureDetector(
      onTap: () {
        final newSelected = List<String>.from(selected);
        if (value == 'all') {
          onChanged(['all']);
        } else {
          newSelected.remove('all');
          if (isSelected) {
            newSelected.remove(value);
            if (newSelected.isEmpty) newSelected.add('all');
          } else {
            newSelected.add(value);
          }
          onChanged(newSelected);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD4AF37).withOpacity(0.15) : const Color(0xFF0F0F0F),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? const Color(0xFFD4AF37).withOpacity(0.4) : const Color(0xFF2A2A2A)),
        ),
        child: Text(label, style: TextStyle(color: isSelected ? const Color(0xFFD4AF37) : Colors.white.withOpacity(0.5), fontSize: 11, fontWeight: FontWeight.w600)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAnnouncementDialog(),
        backgroundColor: const Color(0xFFD4AF37),
        child: const Icon(Icons.add_rounded, color: Colors.black),
      ),
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
                child: const Row(
                  children: [
                    Text('Announcements', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 18)),
                  ],
                ),
              ),
            ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('announcements').orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37), strokeWidth: 2.5));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.campaign_outlined, size: 48, color: Colors.white.withOpacity(0.15)),
                        const SizedBox(height: 16),
                        Text('No announcements', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 16, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 6),
                        Text('Tap + to create one', style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 13)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final isActive = data['active'] ?? false;
                    final targets = List<String>.from(data['targetScreens'] ?? ['all']);
                    final updatedAt = data['updatedAt'] as Timestamp?;

                    return GestureDetector(
                      onTap: () => _showAnnouncementDialog(existing: doc),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFF141414),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: isActive ? const Color(0xFFD4AF37).withOpacity(0.3) : const Color(0xFF222222)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isActive ? Colors.green.withOpacity(0.15) : Colors.red.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    isActive ? 'ACTIVE' : 'INACTIVE',
                                    style: TextStyle(
                                      color: isActive ? Colors.green : Colors.red,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Wrap(
                                    spacing: 4,
                                    children: targets.map((t) => Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1A1A1A),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        t == 'all' ? 'ALL' : t.toUpperCase(),
                                        style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 9, fontWeight: FontWeight.w600),
                                      ),
                                    )).toList(),
                                  ),
                                ),
                                Icon(Icons.edit_rounded, size: 14, color: Colors.white.withOpacity(0.2)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              data['text'] ?? '',
                              style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14, fontWeight: FontWeight.w500),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (updatedAt != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Updated ${DateFormat('MMM dd, yyyy HH:mm').format(updatedAt.toDate())}',
                                style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 11),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
