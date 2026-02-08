import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/theme_config.dart';
import '../../models/log_model.dart';
import '../../services/laporan_service.dart';
import '../../widgets/admin_sidebar.dart';

class AdminLogScreen extends StatefulWidget {
  const AdminLogScreen({super.key});

  @override
  State<AdminLogScreen> createState() => _AdminLogScreenState();
}

class _AdminLogScreenState extends State<AdminLogScreen> {
  List<LogAktivitas> logs = [];
  List<LogAktivitas> filteredLogs = [];
  List<Map<String, dynamic>> users = [];
  bool isLoading = true;
  
  final TextEditingController _searchController = TextEditingController();
  String? _selectedRole;
  int? _selectedUserId;
  DateTime? _selectedDate;

  final dateFormat = DateFormat('dd MMM yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_filterLogs);
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadLogs(),
      _loadUsers(),
    ]);
  }

  Future<void> _loadUsers() async {
    try {
      final response = await LaporanService.getAllUsers();
      setState(() {
        users = (response['data'] as List)
            .map((user) => {
                  'id_user': user['id_user'],
                  'nama_lengkap': user['nama_lengkap'],
                  'role': user['role'],
                })
            .toList();
      });
    } catch (e) {
      // Ignore error, users filter is optional
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLogs() async {
    setState(() => isLoading = true);
    try {
      final data = await LaporanService.getLaporanLogAktivitas();
      setState(() {
        logs = (data['data'] as List)
            .map((json) => LogAktivitas.fromJson(json))
            .toList();
        filteredLogs = logs;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error memuat log aktivitas: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _filterLogs() {
    setState(() {
      filteredLogs = logs.where((log) {
        // Filter by search text
        final searchText = _searchController.text.toLowerCase();
        final matchesSearch = searchText.isEmpty ||
            log.aktivitas.toLowerCase().contains(searchText) ||
            (log.namaLengkap?.toLowerCase().contains(searchText) ?? false);

        // Filter by role
        final matchesRole = _selectedRole == null || log.role == _selectedRole;

        // Filter by user
        final matchesUser = _selectedUserId == null || log.idUser == _selectedUserId;

        // Filter by date
        final matchesDate = _selectedDate == null ||
            (log.waktuAktivitas != null &&
                log.waktuAktivitas!.year == _selectedDate!.year &&
                log.waktuAktivitas!.month == _selectedDate!.month &&
                log.waktuAktivitas!.day == _selectedDate!.day);

        return matchesSearch && matchesRole && matchesUser && matchesDate;
      }).toList();
    });
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _filterLogs();
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedRole = null;
      _selectedUserId = null;
      _selectedDate = null;
      filteredLogs = logs;
    });
  }

  Color _getRoleColor(String? role) {
    switch (role?.toLowerCase()) {
      case 'admin':
        return Colors.purple;
      case 'petugas':
        return Colors.blue;
      case 'owner':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Aktivitas'),
        actions: [
          if (_selectedRole != null || _selectedDate != null)
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: _clearFilters,
              tooltip: 'Clear Filters',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLogs,
            tooltip: 'Refresh',
          ),
        ],
      ),
      drawer: isMobile ? const AdminSidebar(currentRoute: '/admin/log') : null,
      body: Row(
        children: [
          if (!isMobile) const AdminSidebar(currentRoute: '/admin/log'),
          Expanded(
            child: Column(
              children: [
                // Filter Section
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.grey[100],
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                labelText: 'Search',
                                hintText: 'Cari aktivitas atau nama user...',
                                prefixIcon: const Icon(Icons.search),
                                border: const OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.white,
                                suffixIcon: _searchController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear),
                                        onPressed: () => _searchController.clear(),
                                      )
                                    : null,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedRole,
                              decoration: const InputDecoration(
                                labelText: 'Filter Role',
                                border: OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              items: const [
                                DropdownMenuItem(value: null, child: Text('Semua Role')),
                                DropdownMenuItem(value: 'admin', child: Text('Admin')),
                                DropdownMenuItem(value: 'petugas', child: Text('Petugas')),
                                DropdownMenuItem(value: 'owner', child: Text('Owner')),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedRole = value;
                                  _filterLogs();
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              value: _selectedUserId,
                              decoration: const InputDecoration(
                                labelText: 'Filter User',
                                border: OutlineInputBorder(),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              items: [
                                const DropdownMenuItem(value: null, child: Text('Semua User')),
                                ...users.map((user) {
                                  return DropdownMenuItem<int>(
                                    value: user['id_user'],
                                    child: Text('${user['nama_lengkap']} (${user['role']})'),
                                  );
                                }),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedUserId = value;
                                  _filterLogs();
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _selectDate,
                              icon: const Icon(Icons.calendar_today),
                              label: Text(
                                _selectedDate == null
                                    ? 'Filter Tanggal'
                                    : DateFormat('dd MMM yyyy').format(_selectedDate!),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 20),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_selectedRole != null || _selectedUserId != null || _selectedDate != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            children: [
                              const Text('Active Filters: ', style: TextStyle(fontWeight: FontWeight.bold)),
                              if (_selectedRole != null) ...[
                                Chip(
                                  label: Text('Role: ${_selectedRole!.toUpperCase()}'),
                                  onDeleted: () {
                                    setState(() {
                                      _selectedRole = null;
                                      _filterLogs();
                                    });
                                  },
                                ),
                                const SizedBox(width: 8),
                              ],
                              if (_selectedUserId != null) ...[
                                Chip(
                                  label: Text('User: ${users.firstWhere((u) => u['id_user'] == _selectedUserId)['nama_lengkap']}'),
                                  onDeleted: () {
                                    setState(() {
                                      _selectedUserId = null;
                                      _filterLogs();
                                    });
                                  },
                                ),
                                const SizedBox(width: 8),
                              ],
                              if (_selectedDate != null)
                                Chip(
                                  label: Text('Date: ${DateFormat('dd MMM yyyy').format(_selectedDate!)}'),
                                  onDeleted: () {
                                    setState(() {
                                      _selectedDate = null;
                                      _filterLogs();
                                    });
                                  },
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                // Results Count
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: Colors.grey[200],
                  child: Row(
                    children: [
                      Text(
                        'Menampilkan ${filteredLogs.length} dari ${logs.length} log',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),

                // Log List
                Expanded(
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : RefreshIndicator(
                          onRefresh: _loadLogs,
                          child: filteredLogs.isEmpty
                              ? const Center(child: Text('Tidak ada log aktivitas'))
                              : ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: filteredLogs.length,
                                  itemBuilder: (context, index) {
                                    final log = filteredLogs[index];
                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      elevation: 1,
                                      child: ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor: _getRoleColor(log.role).withOpacity(0.2),
                                          child: Icon(
                                            Icons.person,
                                            color: _getRoleColor(log.role),
                                          ),
                                        ),
                                        title: Text(
                                          log.aktivitas,
                                          style: const TextStyle(fontWeight: FontWeight.w500),
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(Icons.person_outline, size: 14, color: Colors.grey[600]),
                                                const SizedBox(width: 4),
                                                Text(log.namaLengkap ?? 'Unknown'),
                                                const SizedBox(width: 12),
                                                Chip(
                                                  label: Text(
                                                    (log.role ?? 'unknown').toUpperCase(),
                                                    style: const TextStyle(fontSize: 10, color: Colors.white),
                                                  ),
                                                  backgroundColor: _getRoleColor(log.role),
                                                  padding: EdgeInsets.zero,
                                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                                                const SizedBox(width: 4),
                                                Text(
                                                  log.waktuAktivitas != null
                                                      ? dateFormat.format(log.waktuAktivitas!)
                                                      : '-',
                                                  style: TextStyle(color: Colors.grey[600]),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        isThreeLine: true,
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
