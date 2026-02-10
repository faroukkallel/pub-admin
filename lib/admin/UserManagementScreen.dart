import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserManagementScreen extends StatefulWidget {
  final List<String> allCollections;
  final bool embedded;

  const UserManagementScreen({
    Key? key,
    required this.allCollections,
    this.embedded = false,
  }) : super(key: key);

  @override
  _UserManagementScreenState createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _selectedRole = 'client';
  List<String> _selectedCollections = [];
  bool _isCreatingUser = false;
  String? _errorMessage;
  bool _showCreateForm = false;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isWide = screenWidth > 900;

    final body = Column(
        children: [
          // App bar (only when not embedded)
          if (!widget.embedded)
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
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(10),
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
                      'User Management',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                    ),
                    const Spacer(),
                    if (!_showCreateForm)
                      ElevatedButton.icon(
                        onPressed: () => setState(() => _showCreateForm = true),
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: Text(isMobile ? 'Add' : 'Add User'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD4AF37),
                          foregroundColor: Colors.black,
                          padding: EdgeInsets.symmetric(horizontal: isMobile ? 14 : 20, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ),
                  ],
                ),
              ),
            ),

          // Embedded header (Add User button only)
          if (widget.embedded)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFF0A0A0A),
                border: Border(
                  bottom: BorderSide(color: Color(0xFF1E1E1E), width: 1),
                ),
              ),
              child: Row(
                children: [
                  const Spacer(),
                  if (!_showCreateForm)
                    ElevatedButton.icon(
                      onPressed: () => setState(() => _showCreateForm = true),
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: Text(isMobile ? 'Add' : 'Add User'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD4AF37),
                        foregroundColor: Colors.black,
                        padding: EdgeInsets.symmetric(horizontal: isMobile ? 14 : 20, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                ],
              ),
            ),

          // Content
          Expanded(
            child: isWide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Create user form (side panel on wide)
                      if (_showCreateForm)
                        Container(
                          width: 380,
                          decoration: const BoxDecoration(
                            color: Color(0xFF111111),
                            border: Border(
                              right: BorderSide(color: Color(0xFF1E1E1E), width: 1),
                            ),
                          ),
                          child: _buildCreateUserForm(isMobile),
                        ),
                      // User list
                      Expanded(child: _buildUserList()),
                    ],
                  )
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        if (_showCreateForm) _buildCreateUserForm(isMobile),
                        SizedBox(
                          height: MediaQuery.of(context).size.height - 200,
                          child: _buildUserList(),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      );

    if (widget.embedded) {
      return body;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: body,
    );
  }

  Widget _buildCreateUserForm(bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.person_add_outlined, color: Color(0xFFD4AF37), size: 18),
              ),
              const SizedBox(width: 12),
              const Text(
                'Create New User',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => _showCreateForm = false),
                child: Icon(Icons.close_rounded, color: Colors.white.withOpacity(0.3), size: 20),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Email & Password
          if (isMobile) ...[
            _buildFormField(controller: _emailController, label: 'Email', hint: 'user@example.com', icon: Icons.mail_outline_rounded),
            const SizedBox(height: 12),
            _buildFormField(controller: _passwordController, label: 'Password', hint: 'Min. 6 characters', icon: Icons.lock_outline_rounded, obscure: true),
          ] else
            Row(
              children: [
                Expanded(child: _buildFormField(controller: _emailController, label: 'Email', hint: 'user@example.com', icon: Icons.mail_outline_rounded)),
                const SizedBox(width: 12),
                Expanded(child: _buildFormField(controller: _passwordController, label: 'Password', hint: 'Min. 6 characters', icon: Icons.lock_outline_rounded, obscure: true)),
              ],
            ),
          const SizedBox(height: 16),

          // Role selector
          Text(
            'Role',
            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildRoleChip('Admin', 'admin'),
              const SizedBox(width: 8),
              _buildRoleChip('Client', 'client'),
            ],
          ),
          const SizedBox(height: 16),

          // Collection access
          if (_selectedRole == 'client') ...[
            Text(
              'Accessible TV Screens',
              style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.allCollections.map((collection) {
                bool isSelected = _selectedCollections.contains(collection);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedCollections.remove(collection);
                      } else {
                        _selectedCollections.add(collection);
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                        if (isSelected)
                          const Padding(
                            padding: EdgeInsets.only(right: 6),
                            child: Icon(Icons.check_rounded, size: 14, color: Colors.black),
                          ),
                        Text(
                          collection.toUpperCase(),
                          style: TextStyle(
                            color: isSelected ? Colors.black : Colors.white.withOpacity(0.6),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],

          // Error
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2D1515),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline_rounded, color: Colors.red.shade300, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red.shade300, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Create button
          SizedBox(
            width: double.infinity,
            child: _isCreatingUser
                ? Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: const Color(0xFFD4AF37), strokeWidth: 2.5),
                    ),
                  )
                : ElevatedButton(
                    onPressed: _createUser,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4AF37),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                      textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    child: const Text('Create User'),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscure = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscure,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.15), fontSize: 14),
            prefixIcon: Icon(icon, color: const Color(0xFFD4AF37), size: 18),
            filled: true,
            fillColor: const Color(0xFF0F0F0F),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFD4AF37)),
            ),
          ),
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildRoleChip(String label, String value) {
    final isSelected = _selectedRole == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD4AF37) : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFFD4AF37) : const Color(0xFF2A2A2A),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white.withOpacity(0.6),
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildUserList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
          child: Text(
            'All Users',
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('users').snapshots(),
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
                      Icon(Icons.people_outline_rounded, size: 48, color: Colors.white.withOpacity(0.1)),
                      const SizedBox(height: 12),
                      Text('No users found', style: TextStyle(color: Colors.white.withOpacity(0.3))),
                    ],
                  ),
                );
              }

              final users = snapshot.data!.docs;

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final userData = users[index].data() as Map<String, dynamic>;
                  final userId = users[index].id;
                  final userEmail = userData['email'] ?? 'No email';
                  final userRole = userData['role'] ?? 'client';
                  final userCollections = List<String>.from(userData['accessibleCollections'] ?? []);

                  return _buildUserCard(userId, userEmail, userRole, userCollections);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUserCard(String userId, String userEmail, String userRole, List<String> userCollections) {
    final isAdmin = userRole == 'admin';

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
          tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isAdmin
                  ? const Color(0xFFD4AF37).withOpacity(0.1)
                  : const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isAdmin ? Icons.admin_panel_settings_outlined : Icons.person_outline_rounded,
              color: isAdmin ? const Color(0xFFD4AF37) : Colors.white.withOpacity(0.4),
              size: 18,
            ),
          ),
          title: Text(
            userEmail,
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
          ),
          subtitle: Row(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isAdmin
                      ? const Color(0xFFD4AF37).withOpacity(0.15)
                      : const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  userRole.toUpperCase(),
                  style: TextStyle(
                    color: isAdmin ? const Color(0xFFD4AF37) : Colors.white.withOpacity(0.4),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              if (userCollections.isNotEmpty) ...[
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '${userCollections.length} screen${userCollections.length > 1 ? 's' : ''}',
                    style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 11),
                  ),
                ),
              ],
            ],
          ),
          trailing: GestureDetector(
            onTap: () => _confirmDeleteUser(userId, userEmail),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.delete_outline_rounded, color: Colors.red.withOpacity(0.6), size: 16),
            ),
          ),
          iconColor: Colors.white.withOpacity(0.3),
          children: [
            if (userRole == 'client') ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'ACCESSIBLE SCREENS',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.3),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.allCollections.map((collection) {
                  bool isSelected = userCollections.contains(collection);
                  return GestureDetector(
                    onTap: () {
                      List<String> updatedCollections = List.from(userCollections);
                      if (isSelected) {
                        updatedCollections.remove(collection);
                      } else {
                        updatedCollections.add(collection);
                      }
                      _updateUserCollections(userId, updatedCollections);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                          if (isSelected)
                            const Padding(
                              padding: EdgeInsets.only(right: 6),
                              child: Icon(Icons.check_rounded, size: 14, color: Colors.black),
                            ),
                          Text(
                            collection.toUpperCase(),
                            style: TextStyle(
                              color: isSelected ? Colors.black : Colors.white.withOpacity(0.5),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _createUser() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Email and password are required';
      });
      return;
    }

    // Email format validation
    final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$');
    if (!emailRegex.hasMatch(email)) {
      setState(() {
        _errorMessage = 'Please enter a valid email address';
      });
      return;
    }

    // Password validation (Firebase requires min 6 characters)
    if (password.length < 6) {
      setState(() {
        _errorMessage = 'Password must be at least 6 characters';
      });
      return;
    }

    setState(() {
      _isCreatingUser = true;
      _errorMessage = null;
    });

    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'email': email,
        'role': _selectedRole,
        'accessibleCollections': _selectedRole == 'admin' ? [] : _selectedCollections,
      });

      _emailController.clear();
      _passwordController.clear();
      setState(() {
        _selectedRole = 'client';
        _selectedCollections = [];
        _showCreateForm = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User created successfully')),
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isCreatingUser = false;
      });
    }
  }

  Future<void> _updateUserCollections(String userId, List<String> collections) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'accessibleCollections': collections,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User access updated')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating user: $e')),
      );
    }
  }

  Future<void> _confirmDeleteUser(String userId, String email) async {
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
                  child: const Icon(Icons.person_remove_outlined, color: Colors.red, size: 28),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Delete User',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  'Are you sure you want to delete $email?',
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
        await _firestore.collection('users').doc(userId).delete();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User deleted successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting user: $e')),
        );
      }
    }
  }
}
