import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'main_navigation_screen.dart';

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({Key? key}) : super(key: key);

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack),
        );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    // Start animations
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _slideController.forward();
    });
    Future.delayed(const Duration(milliseconds: 400), () {
      _scaleController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  Future<void> _requestPermission() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Check current status for all permission types
      final storageStatus = await Permission.storage.status;
      final photosStatus = await Permission.photos.status;
      final videosStatus = await Permission.videos.status;
      final audioStatus = await Permission.audio.status;

      print('Current permission status:');
      print('Storage: $storageStatus');
      print('Photos: $photosStatus');
      print('Videos: $videosStatus');
      print('Audio: $audioStatus');

      // Check if any permission is already granted
      if (storageStatus.isGranted ||
          photosStatus.isGranted ||
          videosStatus.isGranted ||
          audioStatus.isGranted) {
        // Permission already granted
        print('Permission already granted, navigating to main screen');
        if (mounted) {
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const MainNavigationScreen(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
              transitionDuration: const Duration(milliseconds: 500),
            ),
          );
        }
        return;
      }

      // For Android 13+ (API 33+), we need to request media permissions
      print('Requesting storage permission...');
      PermissionStatus status;

      // Try different permission types based on Android version
      if (await Permission.photos.status.isGranted ||
          await Permission.videos.status.isGranted ||
          await Permission.audio.status.isGranted) {
        // Media permissions already granted
        print('Media permissions already granted');
        status = PermissionStatus.granted;
      } else {
        // Request storage permission (this should show the system dialog)
        print('Requesting storage permission - this should show system dialog');
        status = await Permission.storage.request();
        print('Permission request result: $status');

        // If storage permission fails, try media permissions
        if (!status.isGranted) {
          print('Storage permission failed, trying media permissions');
          final photosStatus = await Permission.photos.request();
          final videosStatus = await Permission.videos.request();
          final audioStatus = await Permission.audio.request();

          if (photosStatus.isGranted ||
              videosStatus.isGranted ||
              audioStatus.isGranted) {
            status = PermissionStatus.granted;
            print('Media permissions granted');
          } else {
            status = PermissionStatus.denied;
            print('All permissions denied');
          }
        }
      }

      if (status.isGranted) {
        // Permission granted, navigate to main screen
        print('Permission granted, navigating to main screen');
        if (mounted) {
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const MainNavigationScreen(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    return FadeTransition(opacity: animation, child: child);
                  },
              transitionDuration: const Duration(milliseconds: 500),
            ),
          );
        }
      } else if (status.isDenied) {
        // Permission denied, show message
        print('Permission denied by user');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Storage permission is required to access media files.',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: Colors.red.withOpacity(0.8),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else if (status.isPermanentlyDenied) {
        // Permission permanently denied, open settings
        print('Permission permanently denied, opening settings');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Permission permanently denied. Please enable storage permission in settings.',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: Colors.red.withOpacity(0.8),
              duration: const Duration(seconds: 3),
              action: SnackBarAction(
                label: 'Settings',
                onPressed: () {
                  openAppSettings();
                },
              ),
            ),
          );
        }
      } else {
        // Other status
        print('Permission status: $status');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Unexpected permission status: $status',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: Colors.red.withOpacity(0.8),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      print('Error requesting permission: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error requesting permission: $e',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red.withOpacity(0.8),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
            colors: [
              Color(0xFF06151C),
              Color(0xFF0C1A24),
              Color(0xFF172734),
              Color(0xFF2F404D),
              Color(0xFF64727A),
              Color(0xFFCCD1CF),
            ],
            stops: [0.0, 0.2, 0.43, 0.54, 0.78, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // App title
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Text(
                      'Media Player',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              // Main content
              Expanded(
                child: Center(
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Illustration
                            ScaleTransition(
                              scale: _scaleAnimation,
                              child: Container(
                                width: 200,
                                height: 120,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: const Color(0xFFF5F5F5),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.asset(
                                    'assets/welcome2.png',
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          gradient: const LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              Color(0xFFE8F4FD),
                                              Color(0xFFF0E8FF),
                                            ],
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.music_note,
                                          size: 60,
                                          color: Color(0xFF9B59B6),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Permission text
                            Text(
                              'To find and manage media files, we need permission to access the files on your device.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF333333),
                                fontSize: 16,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 32),
                            // Allow button
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _isLoading
                                    ? null
                                    : _requestPermission,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFF333333),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: const BorderSide(
                                      color: Color(0xFFDDDDDD),
                                      width: 1,
                                    ),
                                  ),
                                ),
                                child: _isLoading
                                    ? SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                const Color(0xFF333333),
                                              ),
                                        ),
                                      )
                                    : Text(
                                        'ALLOW',
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
