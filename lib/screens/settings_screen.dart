import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'dart:ui'; // Added for ImageFilter

// Move _SettingsTile and _SettingsTileState to the top level, outside of SettingsScreen

class _SettingsTile extends StatefulWidget {
  final Icon leading;
  final String title;
  final VoidCallback onTap;
  const _SettingsTile({
    required this.leading,
    required this.title,
    required this.onTap,
    Key? key,
  }) : super(key: key);
  @override
  State<_SettingsTile> createState() => _SettingsTileState();
}

class _SettingsTileState extends State<_SettingsTile> {
  bool _isPressed = false;
  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _isPressed ? 0.96 : 1.0,
      duration: const Duration(milliseconds: 120),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: widget.onTap,
        onHighlightChanged: (v) => setState(() => _isPressed = v),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: const Color(0xFF11212D).withOpacity(0.85),
            border: Border.all(
              color: const Color(0xFF253745).withOpacity(0.18),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF06141B).withOpacity(0.18),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              widget.leading,
              const SizedBox(width: 18),
              Expanded(
                child: Text(
                  widget.title,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF9BA8AB)),
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  void _shareApp(BuildContext context) {
    Share.share('Check out this app! link');
  }

  void _showRateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        int selectedStars = 0;
        bool showCheckmark = false;
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            backgroundColor: const Color(0xFF11212D).withOpacity(0.95),
            title: Text(
              'Rate Us',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    5,
                    (i) => IconButton(
                      icon: Icon(
                        i < selectedStars ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 32,
                      ),
                      onPressed: () => setState(() => selectedStars = i + 1),
                    ),
                  ),
                ),
                if (showCheckmark)
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) => ScaleTransition(
                      scale: animation,
                      child: FadeTransition(opacity: animation, child: child),
                    ),
                    child: Icon(
                      Icons.check_circle,
                      key: const ValueKey('checkmark'),
                      color: Colors.green,
                      size: 48,
                    ),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() => showCheckmark = true);
                  Future.delayed(const Duration(milliseconds: 800), () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Thanks for rating us!',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                        backgroundColor: const Color(0xFF4A5C6A),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  });
                },
                child: Text(
                  'Submit',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: const Color(0xFF11212D).withOpacity(0.95),
        title: Text(
          'Privacy Policy',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        content: Text(
          'Privacy Policy will be added soon.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: Theme.of(context).textTheme.bodyLarge),
          ),
        ],
      ),
    );
  }

  void _showFeedback(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: const Color(0xFF11212D).withOpacity(0.95),
        title: Text('Feedback', style: Theme.of(context).textTheme.titleLarge),
        content: Text(
          'Feedback form will be added soon.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: Theme.of(context).textTheme.bodyLarge),
          ),
        ],
      ),
    );
  }

  void _exitApp(BuildContext context) {
    if (Platform.isAndroid) {
      // Use SystemNavigator.pop() for Android
      Future.delayed(const Duration(milliseconds: 200), () {
        // Delay to allow dialog to close
        Navigator.of(context).popUntil((route) => route.isFirst);
        Future.delayed(const Duration(milliseconds: 100), () {
          // ignore: deprecated_member_use
          // SystemNavigator.pop();
          exit(0);
        });
      });
    } else if (Platform.isIOS) {
      // iOS does not allow programmatic exit
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Use the home button to exit the app.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings', style: Theme.of(context).textTheme.titleLarge),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: theme.colorScheme.onBackground,
        centerTitle: true,
        titleTextStyle: null, // Remove custom style
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF06141B),
              Color(0xFF11212D),
              Color(0xFF253745),
              Color(0xFF4A5C6A),
              Color(0xFF9BA8AB),
            ],
            stops: [0.0, 0.25, 0.5, 0.75, 1.0],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            children: [
              _SettingsTile(
                leading: const Icon(
                  Icons.share_outlined,
                  color: Color(0xFF4A5C6A),
                ),
                title: 'Share App',
                onTap: () => _shareApp(context),
              ),
              _SettingsTile(
                leading: const Icon(
                  Icons.star_outline_rounded,
                  color: Colors.amber,
                ),
                title: 'Rate App',
                onTap: () => _showRateDialog(context),
              ),
              _SettingsTile(
                leading: const Icon(
                  Icons.privacy_tip_outlined,
                  color: Color(0xFF9BA8AB),
                ),
                title: 'Privacy Policy',
                onTap: () => _showPrivacyPolicy(context),
              ),
              _SettingsTile(
                leading: const Icon(
                  Icons.feedback_outlined,
                  color: Color(0xFF9BA8AB),
                ),
                title: 'Feedback',
                onTap: () => _showFeedback(context),
              ),
              _SettingsTile(
                leading: const Icon(
                  Icons.exit_to_app_rounded,
                  color: Color(0xFF9BA8AB),
                ),
                title: 'Exit App',
                onTap: () => _exitApp(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
