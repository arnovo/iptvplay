import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/playlist_profile.dart';
import '../../providers/profile_provider.dart';
import '../../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

class AddProfileDialog extends StatefulWidget {
  const AddProfileDialog({super.key});

  @override
  State<AddProfileDialog> createState() => _AddProfileDialogState();
}

class _AddProfileDialogState extends State<AddProfileDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // M3U controllers
  final _m3uNameController = TextEditingController();
  final _m3uUrlController = TextEditingController();

  // Xtream controllers
  final _xtreamNameController = TextEditingController();
  final _xtreamServerController = TextEditingController();
  final _xtreamUserController = TextEditingController();
  final _xtreamPassController = TextEditingController();

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _m3uNameController.dispose();
    _m3uUrlController.dispose();
    _xtreamNameController.dispose();
    _xtreamServerController.dispose();
    _xtreamUserController.dispose();
    _xtreamPassController.dispose();
    super.dispose();
  }

  void _loadDemoM3u() {
    setState(() {
      _m3uNameController.text = 'Public Demo Channels';
      _m3uUrlController.text = 'https://iptv-org.github.io/iptv/countries/es.m3u';
    });
  }

  Future<void> _saveM3u() async {
    final name = _m3uNameController.text.trim();
    final url = _m3uUrlController.text.trim();

    if (name.isEmpty || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete name and URL / Por favor completa el nombre y la URL')),
      );
      return;
    }

    setState(() => _isSaving = true);
    final profile = PlaylistProfile(
      id: const Uuid().v4(),
      name: name,
      type: PlaylistType.m3u,
      m3uUrl: url,
      createdAt: DateTime.now(),
    );

    await context.read<ProfileProvider>().addProfile(profile);
    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _saveXtream() async {
    final name = _xtreamNameController.text.trim();
    final server = _xtreamServerController.text.trim();
    final user = _xtreamUserController.text.trim();
    final pass = _xtreamPassController.text.trim();

    if (name.isEmpty || server.isEmpty || user.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all Xtream fields / Por favor completa todos los campos de Xtream')),
      );
      return;
    }

    setState(() => _isSaving = true);
    final profile = PlaylistProfile(
      id: const Uuid().v4(),
      name: name,
      type: PlaylistType.xtream,
      serverUrl: server,
      username: user,
      password: pass,
      createdAt: DateTime.now(),
    );

    await context.read<ProfileProvider>().addProfile(profile);
    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.addList,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TabBar(
                controller: _tabController,
                indicatorColor: AppTheme.primary,
                labelColor: AppTheme.primary,
                unselectedLabelColor: AppTheme.textSecondary,
                tabs: const [
                  Tab(text: 'M3U / URL'),
                  Tab(text: 'Xtream Codes API'),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 280,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // M3U Tab
                    SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: _m3uNameController,
                            decoration: InputDecoration(
                              labelText: l10n.playlistName,
                              hintText: 'My Playlist / Mi Lista',
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _m3uUrlController,
                            decoration: InputDecoration(
                              labelText: l10n.m3uUrl,
                              hintText: 'https://example.com/playlist.m3u',
                            ),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: _loadDemoM3u,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.primary,
                              side: const BorderSide(color: AppTheme.primary),
                            ),
                            icon: const Icon(Icons.bolt, size: 18),
                            label: const Text('Demo IPTV (Legal / Public)'),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _isSaving ? null : _saveM3u,
                            child: _isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : Text(l10n.saveAndLoad),
                          ),
                        ],
                      ),
                    ),

                    // Xtream Codes Tab
                    SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: _xtreamNameController,
                            decoration: InputDecoration(
                              labelText: l10n.playlistName,
                              hintText: 'Xtream Provider',
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _xtreamServerController,
                            decoration: InputDecoration(
                              labelText: l10n.xtreamServer,
                              hintText: 'http://server.com:8080',
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _xtreamUserController,
                                  decoration: InputDecoration(
                                    labelText: l10n.username,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: _xtreamPassController,
                                  obscureText: true,
                                  decoration: InputDecoration(
                                    labelText: l10n.password,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _isSaving ? null : _saveXtream,
                            child: _isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : Text(l10n.saveAndLoad),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
