import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:image/image.dart' as img;

import '../core/providers/session_provider.dart';
import '../app_theme.dart';

/// Home screen - entry point for SmileCraft
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const PatientCasesScreen(),
    const PhotoCaptureScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.folder_outlined),
            activeIcon: Icon(Icons.folder),
            label: 'Cases',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt_outlined),
            activeIcon: Icon(Icons.camera_alt),
            label: 'New Case',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

/// Screen showing list of patient cases
class PatientCasesScreen extends ConsumerStatefulWidget {
  const PatientCasesScreen({super.key});

  @override
  ConsumerState<PatientCasesScreen> createState() => _PatientCasesScreenState();
}

class _PatientCasesScreenState extends ConsumerState<PatientCasesScreen> {
  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(sessionNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Cases'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search
            },
          ),
        ],
      ),
      body: sessionState.currentCase == null
          ? _buildEmptyState(context)
          : _buildCaseList(context, ref),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Navigate to new case creation
          // Trigger bottom nav change via parent
        },
        icon: const Icon(Icons.add),
        label: const Text('New Case'),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            'No patient cases yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap "New Case" to get started',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              // Trigger bottom nav to go to camera
            },
            icon: const Icon(Icons.camera_alt),
            label: const Text('Create New Case'),
          ),
        ],
      ),
    );
  }

  Widget _buildCaseList(BuildContext context, WidgetRef ref) {
    // TODO: Load saved cases from local storage
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 1, // Placeholder
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryBlue,
              child: const Icon(Icons.person, color: Colors.white),
            ),
            title: Text(
              'Sample Patient',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            subtitle: Text(
              'Created today • 2 restorations',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Open case details
            },
          ),
        );
      },
    );
  }
}

/// Screen for capturing or selecting a photo
class PhotoCaptureScreen extends ConsumerStatefulWidget {
  const PhotoCaptureScreen({super.key});

  @override
  ConsumerState<PhotoCaptureScreen> createState() => _PhotoCaptureScreenState();
}

class _PhotoCaptureScreenState extends ConsumerState<PhotoCaptureScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isProcessing = false;

  Future<void> _takePhoto() async {
    try {
      setState(() => _isProcessing = true);

      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 100,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (photo != null) {
        await _processImage(photo.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error taking photo: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      setState(() => _isProcessing = true);

      final XFile? photo = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );

      if (photo != null) {
        await _processImage(photo.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error selecting photo: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _processImage(String imagePath) async {
    // Decode image
    final file = File(imagePath);
    final bytes = await file.readAsBytes();
    final image = img.decodeImage(bytes);

    if (image == null) {
      throw Exception('Failed to decode image');
    }

    // Load into session
    await ref.read(sessionNotifierProvider.notifier).loadPhoto(imagePath, image);

    if (mounted) {
      Navigator.pushNamed(context, '/editor');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Case'),
      ),
      body: _isProcessing
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.photo_camera,
                      size: 100,
                      color: AppTheme.primaryBlue.withOpacity(0.5),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Capture or select a photo\nof the patient\'s smile',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.grey[700],
                          ),
                    ),
                    const SizedBox(height: 48),
                    ElevatedButton.icon(
                      onPressed: _takePhoto,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Take Photo'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(200, 50),
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _pickFromGallery,
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Choose from Gallery'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(200, 50),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

/// Settings screen
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionTitle('About'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('About SmileCraft'),
              subtitle: const Text('Version 1.0.0'),
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: 'SmileCraft',
                  applicationVersion: '1.0.0',
                  applicationLegalese: '© 2024 SmileCraft. All rights reserved.',
                  children: [
                    const SizedBox(height: 16),
                    const Text(
                      'Dental Restoration Simulator\n100% on-device processing\nNo internet required',
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Models & Assets'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Model Status'),
              subtitle: const Text('MobileSAM: Not loaded'),
              trailing: const Icon(Icons.warning, color: Colors.orange),
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Privacy'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.security),
                  title: const Text('Data Storage'),
                  subtitle: const Text('All data stored locally on device'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.cloud_off),
                  title: const Text('No Internet Required'),
                  subtitle: const Text('Works completely offline'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey[600],
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
