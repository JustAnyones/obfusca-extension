import 'package:browser_extension/providers/user.dart';
import 'package:browser_extension/web/interop.dart';
import 'package:browser_extension/widgets/read_entries.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';

Widget buildSidebar(BuildContext context, String currentPage) {
  return Container(
    width: 60,
    height: double.infinity,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: 4,
          offset: Offset(2, 0),
        ),
      ],
    ),
    child: Column(
      children: [
        SizedBox(height: 20),
        // Home button (highlighted on home page)
        Tooltip(
          message: AppLocalizations.of(context)!.generator_page_title,
          child: IconButton(
            icon: Icon(Icons.home),
            iconSize: 28,
            color:
                currentPage == 'home'
                    ? Theme.of(context).colorScheme.primary
                    : null,
            onPressed:
                currentPage == 'home'
                    ? null
                    : () {
                      Navigator.pop(context);
                    },
          ),
        ),
        SizedBox(height: 16),
        // Entries Button
        Tooltip(
          message: AppLocalizations.of(context)!.button_view_entries,
          child: IconButton(
            icon: Icon(Icons.list_alt),
            iconSize: 28,
            color:
                currentPage == 'entries'
                    ? Theme.of(context).colorScheme.primary
                    : null,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => EntriesPage()),
              );
            },
          ),
        ),
        Divider(thickness: 1, color: Colors.grey),
        //SizedBox(height: 16),
        // User Profile Button
        Tooltip(
          message: AppLocalizations.of(context)!.user_profile_page_title,
          child: IconButton(
            icon: Icon(Icons.person),
            iconSize: 28,
            color:
                currentPage == 'profile'
                    ? Theme.of(context).colorScheme.primary
                    : null,
            onPressed: () async {
              if (UserProvider.getInstance().isLoggedIn) {
                await navigateToPageRoute('/profile');
                await closeLastFocusedWindow();
              } else {
                Navigator.pushNamed(context, '/login');
              }
            },
          ),
        ),
        SizedBox(height: 16),
        // Settings Button (last)
        Tooltip(
          message: AppLocalizations.of(context)!.settings_title,
          child: IconButton(
            icon: Icon(Icons.settings),
            iconSize: 28,
            color:
                currentPage == 'settings'
                    ? Theme.of(context).colorScheme.primary
                    : null,
            onPressed: () async {
              await navigateToPageRoute('/settings');
              await closeLastFocusedWindow();
            },
          ),
        ),
      ],
    ),
  );
}
