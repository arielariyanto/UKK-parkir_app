import 'package:flutter/material.dart';
import '../../config/theme_config.dart';
import '../../models/user_model.dart';
import '../../services/user_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/admin_sidebar.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  List<User> users = [];
  List<User> filteredUsers = [];
  bool isLoading = true;
  String selectedRoleFilter = 'Semua';
  String selectedStatusFilter = 'Semua';
  int? currentUserId;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadUsers();
  }

  Future<void> _loadCurrentUser() async {
    final user = await AuthService.getUserInfo();
    if (user != null) {
      setState(() {
        currentUserId = user.idUser;
      });
    }
  }

  Future<void> _loadUsers() async {
    print('Loading users...');
    setState(() => isLoading = true);
    try {
      final data = await UserService.getAllUsers();
      print('Received ${data.length} users');
      setState(() {
        users = data;
        _applyFilters();
        print('Filtered users: ${filteredUsers.length}');
        isLoading = false;
      });
    } catch (e) {
      print('Error loading users: $e');
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error memuat data user: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _applyFilters() {
    print('Applying filters - Role: $selectedRoleFilter, Status: $selectedStatusFilter');
    print('Total users before filter: ${users.length}');
    
    filteredUsers = users.where((user) {
      bool matchRole = selectedRoleFilter == 'Semua' || user.role == selectedRoleFilter.toLowerCase();
      bool matchStatus = selectedStatusFilter == 'Semua' || 
          (selectedStatusFilter == 'Aktif' && user.isAktif) ||
          (selectedStatusFilter == 'Nonaktif' && !user.isAktif);
      
      print('User: ${user.username}, Role match: $matchRole, Status match: $matchStatus');
      return matchRole && matchStatus;
    }).toList();
    
    print('Filtered users count: ${filteredUsers.length}');
  }

  void _showUserDialog({User? user}) {
    final nameController = TextEditingController(text: user?.namaLengkap);
    final usernameController = TextEditingController(text: user?.username);
    final passwordController = TextEditingController();
    String selectedRole = user?.role ?? 'admin';
    bool obscurePassword = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(user == null ? 'Tambah User' : 'Edit User'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Lengkap',
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    prefixIcon: Icon(Icons.account_circle),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  decoration: InputDecoration(
                    labelText: user == null ? 'Password' : 'Password (kosongkan jika tidak diubah)',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(obscurePassword ? Icons.visibility : Icons.visibility_off),
                      onPressed: () {
                        setDialogState(() {
                          obscurePassword = !obscurePassword;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Role',
                    prefixIcon: Icon(Icons.badge),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    DropdownMenuItem(value: 'petugas', child: Text('Petugas')),
                    DropdownMenuItem(value: 'owner', child: Text('Owner')),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      selectedRole = value!;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty || usernameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Nama lengkap dan username harus diisi')),
                  );
                  return;
                }

                if (user == null && passwordController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Password harus diisi untuk user baru')),
                  );
                  return;
                }

                try {
                  if (user == null) {
                    await UserService.createUser(
                      namaLengkap: nameController.text,
                      username: usernameController.text,
                      password: passwordController.text,
                      role: selectedRole,
                    );
                  } else {
                    await UserService.updateUser(
                      idUser: user.idUser!,
                      namaLengkap: nameController.text,
                      username: usernameController.text,
                      password: passwordController.text.isEmpty ? null : passwordController.text,
                      role: selectedRole,
                    );
                  }

                  if (context.mounted) {
                    Navigator.pop(context);
                    _loadUsers();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(user == null ? 'User berhasil ditambahkan' : 'User berhasil diupdate'),
                        backgroundColor: AppTheme.accentColor,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: AppTheme.errorColor,
                      ),
                    );
                  }
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteUser(User user) async {
    // Cek apakah user mencoba menghapus akun sendiri
    if (user.idUser == currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak dapat menghapus akun sendiri'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: Text('Hapus user ${user.namaLengkap}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await UserService.deleteUser(user.idUser!);
        _loadUsers();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User berhasil dihapus'),
              backgroundColor: AppTheme.accentColor,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola User'),
        automaticallyImplyLeading: !isMobile,
      ),
      drawer: isMobile ? const AdminSidebar(currentRoute: '/admin/users') : null,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showUserDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Tambah User'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: Row(
        children: [
          if (!isMobile) const AdminSidebar(currentRoute: '/admin/users'),
          Expanded(
            child: Column(
              children: [
                // Filter Section
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.grey[100],
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedRoleFilter,
                          decoration: const InputDecoration(
                            labelText: 'Filter Role',
                            prefixIcon: Icon(Icons.filter_list),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          items: const [
                            DropdownMenuItem(value: 'Semua', child: Text('Semua Role')),
                            DropdownMenuItem(value: 'admin', child: Text('Admin')),
                            DropdownMenuItem(value: 'petugas', child: Text('Petugas')),
                            DropdownMenuItem(value: 'owner', child: Text('Owner')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              selectedRoleFilter = value!;
                              _applyFilters();
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedStatusFilter,
                          decoration: const InputDecoration(
                            labelText: 'Filter Status',
                            prefixIcon: Icon(Icons.toggle_on),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          items: const [
                            DropdownMenuItem(value: 'Semua', child: Text('Semua Status')),
                            DropdownMenuItem(value: 'Aktif', child: Text('Aktif')),
                            DropdownMenuItem(value: 'Nonaktif', child: Text('Nonaktif')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              selectedStatusFilter = value!;
                              _applyFilters();
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                // User List
                Expanded(
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : RefreshIndicator(
                          onRefresh: _loadUsers,
                          child: filteredUsers.isEmpty
                              ? const Center(child: Text('Tidak ada data user'))
                              : ListView.builder(
                                  padding: EdgeInsets.all(isMobile ? 16 : 24),
                                  itemCount: filteredUsers.length,
                                  itemBuilder: (context, index) {
                                    final user = filteredUsers[index];
                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      child: ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor: AppTheme.primaryColor,
                                          child: Text(
                                            user.namaLengkap.isNotEmpty ? user.namaLengkap[0].toUpperCase() : 'U',
                                            style: const TextStyle(color: Colors.white),
                                          ),
                                        ),
                                        title: Text(
                                          user.namaLengkap,
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('Username: ${user.username}'),
                                            Text('Role: ${user.role.toUpperCase()}'),
                                          ],
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: user.isAktif ? AppTheme.accentColor : Colors.grey,
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                user.isAktif ? 'Aktif' : 'Nonaktif',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            IconButton(
                                              icon: const Icon(Icons.edit, color: AppTheme.primaryColor),
                                              onPressed: () => _showUserDialog(user: user),
                                              tooltip: 'Edit',
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete, color: AppTheme.errorColor),
                                              onPressed: () => _deleteUser(user),
                                              tooltip: 'Hapus',
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
