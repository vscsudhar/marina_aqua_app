import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stacked/stacked.dart';
import '../../common/app_colors.dart';
import '../../common/app_strings.dart';
import '../../widgets/marina_logo.dart';
import 'login_viewmodel.dart';

class LoginView extends StackedView<LoginViewModel> {
  const LoginView({super.key});

  @override
  void onViewModelReady(LoginViewModel viewModel) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      viewModel.init();
    });
    super.onViewModelReady(viewModel);
  }

  @override
  Widget builder(BuildContext context, LoginViewModel viewModel, Widget? child) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 1024;
    final isTablet = size.width >= 650 && size.width < 1024;

    return Scaffold(
      backgroundColor: kcBackgroundColor,
      body: isDesktop
          ? _buildDesktopLayout(context, viewModel)
          : _buildMobileTabletLayout(context, viewModel, isTablet),
    );
  }

  // Desktop Split-Screen Layout
  Widget _buildDesktopLayout(BuildContext context, LoginViewModel viewModel) {
    return Row(
      children: [
        // Left Branding & Hero Section
        Expanded(
          flex: 5,
          child: Container(
            decoration: const BoxDecoration(
              gradient: kcHeroDarkGradient,
            ),
            child: Stack(
              children: [
                // Ambient Glow Orbs
                Positioned(
                  top: -80,
                  left: -80,
                  child: Container(
                    width: 320,
                    height: 320,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: kcPrimaryColor.withOpacity(0.18),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -60,
                  right: -60,
                  child: Container(
                    width: 350,
                    height: 350,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: kcAquaCyan.withOpacity(0.12),
                    ),
                  ),
                ),
                // Content
                SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 56.0, vertical: 48.0),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height - 96),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const MarinaLogo(
                          size: 52,
                          isDark: true,
                          useCompanyLogo: false,
                          subtitle: 'ENTERPRISE DISTRIBUTION',
                        ),
                        const SizedBox(height: 32),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: kcAquaCyan.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: kcAquaCyan.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.verified_rounded, color: kcAquaCyan, size: 16),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      'TRUSTED WATER DISTRIBUTION PLATFORM',
                                      style: GoogleFonts.inter(
                                        color: kcAquaCyan,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.0,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Pure Mineral Hydration,\nPrecision Dealer Operations.',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 38,
                                fontWeight: FontWeight.w800,
                                height: 1.2,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Seamlessly manage 20L water jars, dealer credit ledgers, daily cash collections, automated GST invoices, and 15-day settlement statements.',
                              style: GoogleFonts.inter(
                                color: kcLightGrey,
                                fontSize: 15,
                                height: 1.6,
                              ),
                            ),
                            const SizedBox(height: 36),
                            // Feature Highlights Cards
                            _buildFeatureBadge(
                              icon: Icons.account_balance_wallet_outlined,
                              title: 'Single Source of Truth Ledgers',
                              subtitle: 'Strict debit/credit tracking with immutable transaction histories.',
                            ),
                            const SizedBox(height: 16),
                            _buildFeatureBadge(
                              icon: Icons.receipt_long_outlined,
                              title: 'Automated GST Tax Invoicing',
                              subtitle: 'Instant manual tax invoices with A4 landscape print support.',
                            ),
                            const SizedBox(height: 16),
                            _buildFeatureBadge(
                              icon: Icons.inventory_2_outlined,
                              title: 'Inventory & Empty Can Tracking',
                              subtitle: 'Real-time monitoring of filled 20L jars, deposits, and returns.',
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        // Footer info
                        Row(
                          children: [
                            const Icon(Icons.shield_outlined, color: kcPrimaryLight, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '256-Bit SSL Encrypted • Role-Based Access • FSSAI Certified',
                                style: GoogleFonts.inter(
                                  color: kcLightGrey.withOpacity(0.7),
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Right Form Section
        Expanded(
          flex: 6,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: _buildFormCard(context, viewModel, isCompact: false),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Mobile & Tablet Responsive Layout
  Widget _buildMobileTabletLayout(
    BuildContext context,
    LoginViewModel viewModel,
    bool isTablet,
  ) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 36 : 20,
          vertical: 24,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isTablet ? 500 : 420),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              const Center(
                child: MarinaLogo(
                  size: 48,
                  isDark: false,
                  useCompanyLogo: false,
                  subtitle: 'DEALER MANAGEMENT PORTAL',
                ),
              ),
              const SizedBox(height: 28),
              _buildFormCard(context, viewModel, isCompact: !isTablet),
              const SizedBox(height: 20),
              Text(
                AppStrings.copyrightNotice,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: kcTextMuted,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // The Login Form Card
  Widget _buildFormCard(
    BuildContext context,
    LoginViewModel viewModel, {
    required bool isCompact,
  }) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 24 : 36),
      decoration: BoxDecoration(
        color: kcSurfaceWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kcBorderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: kcDeepNavy.withOpacity(0.06),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppStrings.loginTitle,
            style: GoogleFonts.outfit(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: kcTextPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            AppStrings.loginSubtitle,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: kcTextSecondary,
            ),
          ),
          const SizedBox(height: 24),

          // Error Message Alert
          if (viewModel.errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: kcErrorColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kcErrorColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: kcErrorColor, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      viewModel.errorMessage!,
                      style: GoogleFonts.inter(
                        color: kcErrorColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 16, color: kcErrorColor),
                    onPressed: viewModel.clearErrorMessage,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Login Field (Email or Username)
          Text(
            AppStrings.labelEmailOrUsername,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: kcTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: viewModel.loginController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            onChanged: (_) => viewModel.clearErrorMessage(),
            decoration: InputDecoration(
              hintText: AppStrings.hintEmailOrUsername,
              hintStyle: GoogleFonts.inter(color: kcTextMuted, fontSize: 14),
              prefixIcon: const Icon(Icons.person_outline_rounded, color: kcPrimaryDark, size: 20),
              filled: true,
              fillColor: kcVeryLightGrey.withOpacity(0.5),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: kcBorderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: kcBorderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: kcPrimaryColor, width: 1.8),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Password Field
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.labelPassword,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: kcTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: viewModel.passwordController,
            obscureText: !viewModel.isPasswordVisible,
            textInputAction: TextInputAction.done,
            onChanged: (_) => viewModel.clearErrorMessage(),
            onFieldSubmitted: (_) => viewModel.submitLogin(),
            decoration: InputDecoration(
              hintText: AppStrings.hintPassword,
              hintStyle: GoogleFonts.inter(color: kcTextMuted, fontSize: 14),
              prefixIcon: const Icon(Icons.lock_outline_rounded, color: kcPrimaryDark, size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  viewModel.isPasswordVisible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: kcMediumGrey,
                  size: 20,
                ),
                onPressed: viewModel.togglePasswordVisibility,
              ),
              filled: true,
              fillColor: kcVeryLightGrey.withOpacity(0.5),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: kcBorderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: kcBorderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: kcPrimaryColor, width: 1.8),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Remember Me Checkbox
          Row(
            children: [
              SizedBox(
                height: 24,
                width: 24,
                child: Checkbox(
                  value: viewModel.rememberMe,
                  onChanged: viewModel.setRememberMe,
                  activeColor: kcPrimaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () => viewModel.setRememberMe(!viewModel.rememberMe),
                  child: Text(
                    AppStrings.labelRememberMe,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: kcTextSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Submit Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: viewModel.isBusy ? null : viewModel.submitLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: kcPrimaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: viewModel.isBusy
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            AppStrings.buttonSigningIn,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      AppStrings.buttonSignIn,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 20),

          // Demo Quick Credentials Fill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: kcVeryLightGrey,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: kcBorderColor),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Admin Initial Account',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: kcTextSecondary,
                        ),
                      ),
                      Text(
                        'admin@marinaaqua.com',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: kcPrimaryDark,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: viewModel.fillDemoAdmin,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Auto-fill',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: kcPrimaryColor,
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

  // Left feature bullet badge
  Widget _buildFeatureBadge({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: Icon(icon, color: kcAquaCyan, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  color: kcLightGrey,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  LoginViewModel viewModelBuilder(BuildContext context) => LoginViewModel();
}
