import 'package:flutter/material.dart';
import '../utils/constants.dart';

class SmartSavingAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showLogo;
  final List<Widget>? actions;
  final VoidCallback? onBackPressed;
  final bool centerTitle;

  const SmartSavingAppBar({
    super.key,
    required this.title,
    this.showLogo = false,
    this.actions,
    this.onBackPressed,
    this.centerTitle = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56.0);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showLogo)
            Text(
              AppStrings.appName,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
          ),
        ],
      ),
      centerTitle: centerTitle || showLogo,
      backgroundColor: const Color(AppColors.primary),
      elevation: 2,
      actions: actions,
      leading: onBackPressed != null
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: onBackPressed,
            )
          : null,
    );
  }
}
