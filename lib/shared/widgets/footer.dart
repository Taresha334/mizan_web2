import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/app_localizations.dart';

class Footer extends StatelessWidget {
  const Footer({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      color: const Color(0xFF1A1A1A),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            children: [
              Wrap(
                spacing: 80,
                runSpacing: 40,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  _buildBrandColumn(l10n),
                  _buildLegalColumn(context, l10n),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 30),
                child: Divider(color: Colors.white10),
              ),
              Text(
                "© 2026 ${l10n.appTitle} PLC. Adama, Ethiopia",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBrandColumn(AppLocalizations l10n) => SizedBox(
    width: 300,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.appTitle.toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          l10n.digitalBridgeStatement,
          style: const TextStyle(color: Colors.white54, fontSize: 13),
        ),
      ],
    ),
  );

  Widget _buildLegalColumn(BuildContext context, AppLocalizations l10n) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _footerLink(l10n.privacyPolicy, '/privacy', context),
          _footerLink(l10n.termsOfUse, '/terms', context),
        ],
      );

  Widget _footerLink(String title, String path, BuildContext context) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: InkWell(
          onTap: () => context.go(path),
          child: Text(
            title,
            style: const TextStyle(color: Colors.white60, fontSize: 14),
          ),
        ),
      );
}
