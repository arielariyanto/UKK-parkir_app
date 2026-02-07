import 'package:flutter/material.dart';
import '../../config/theme_config.dart';
import '../../config/api_config.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';
import '../../widgets/admin_sidebar.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  List<User> users = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => isLoading = true);
    try {
      final response = await ApiService.get(ApiConfig.users, auth: true);
      final data = ApiService.handleResponse(response);
      setState(() {
        users = (data['data'] as List).map((json) => User.fromJson(json)).toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _deleteUser(int id) async {
    try {
      await ApiService.delete('${ApiConfig.users}/$id', auth: true);
      _loadUsers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User berhasil dihapus')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showUserDialog({User? user}) {
    final nameController = TextEditingController(text: user?.namaLengkap);
    final usernameController = TextEditingController(text: user?.username);
    final passwordController = TextEditingController();
    String selectedRole = user?.role ?? 'petugas';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(user == null ? 'Tambah User' : 'Edit User'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nama Lengkap'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(labelText: 'Username'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                decoration: InputDecoration(
                  labelText: user == null ? 'Password' : 'Password (kosongkan jika tidak diubah)',
                ),
                obscureText: true,
              ),
              const SizedBox(height: 12),
              StatefulBuilder(
                builder: (context, setState) => DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: ['admin', 'petugas', 'owner']
                      .map((role) => DropdownMenuItem(value: role, child: Text(role)))
                      .toList(),
                  onChanged: (value) => setState(() => selectedRole = value!),
                ),
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
              final data = {
                'nama_lengkap': nameController.text,
                'username': usernameController.text,
                'role': selectedRole,
                if (passwordController.text.isNotEmpty) 'password': passwordController.text,
              };

              try {
                if (user == null) {
                  await ApiService.post('${ApiConfig.users}/register', data, auth: true);
                } else {
                  await ApiService.put('${ApiConfig.users}/${user.idUser}', data, auth: true);
                }
                if (context.mounted) {
                  Navigator.pop(context);
                  _loadUsers();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(user == null ? 'User berhasil ditambahkan' : 'User berhasil diupdate')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola User'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showUserDialog(),
          ),
        ],
      ),
      drawer: isMobile ? const AdminSidebar(currentRoute: '/admin/users') : null,
      body: Row(
        children: [
          if (!isMobile) const AdminSidebar(currentRoute: '/admin/users'),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadUsers,
                    child: ListView(
                      padding: EdgeInsets.all(isMobile ? 16 : 24),
                      children: [
                        Card(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columns: const [
                                DataColumn(label: Text('Nama Lengkap')),
                                DataColumn(label: Text('Username')),
                                DataColumn(label: Text('Role')),
                                DataColumn(label: Text('Status')),
                                DataColumn(label: Text('Aksi')),
                              ],
                              rows: users.map((user) => DataRow(cells: [
                                DataCell(Text(user.namaLengkap)),
                                DataCell(Text(user.username)),
                                DataCell(Chip(label: Text(user.role.toUpperCase()))),
                                DataCell(Chip(
                                  label: Text(user.statusAktif == 1 ? 'Aktif' : 'Nonaktif'),
                                  backgroundColor: user.statusAktif == 1 ? AppTheme.accentColor : AppTheme.errorColor,
                                )),
                                DataCell(Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: AppTheme.primaryColor),
                                      onPressed: () => _showUserDialog(user: user),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: AppTheme.errorColor),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('Konfirmasi'),
                                            content: Text('Hapus user ${user.namaLengkap}?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(context),
                                                child: const Text('Batal'),
                                              ),
                                              ElevatedButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                  _deleteUser(user.idUser);
                                                },
                                                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
                                                child: const Text('Hapus'),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                )),
                              ])).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
