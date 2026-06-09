import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:moharek_app/core/theme/app_theme.dart';
import 'package:moharek_app/core/config/app_config.dart';
import 'package:moharek_app/shared/services/data_providers.dart';
import 'package:particles_flutter/particles_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:moharek_app/l10n/app_localizations.dart';
import 'package:moharek_app/shared/services/haptic_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:moharek_app/core/router/app_router.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late final PageController _pageController;
  int _currentPage = 0;
  int _briefStep = 0;
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _isInitialized = true;
      final uri = GoRouterState.of(context).uri;
      final isEdit = uri.queryParameters['edit'] == 'true';
      final isLoggedIn = Supabase.instance.client.auth.currentUser != null;
      if (isEdit || isLoggedIn) {
        _currentPage = 4;
        _pageController = PageController(initialPage: 4);
      } else {
        _currentPage = 0;
        _pageController = PageController(initialPage: 0);
      }

      final project = ref.read(currentProjectProvider).valueOrNull;
      if (project != null && project.clientBrief != null) {
        _briefData.addAll(project.clientBrief!);
      }
    }
  }

  final Map<String, dynamic> _briefData = {
    // 1. Account & Platform
    'platform_mail': '',
    'platform_password': '',
    // 2. Communication & General
    'best_contact_time': '',
    'employment_type': '', 
    'business_structure': '', 
    'investment_timeline': '',
    'store_age': '',
    'has_offline_store': '',
    'store_market_stage': '',
    // 3. Goals & Audience
    'current_future_goals': '',
    'target_age_group': '',
    'best_selling_products': '',
    'competitors': '',
    'competitive_advantage': '',
    // 4. Marketing Channels
    'has_ad_snapchat': false,
    'has_ad_meta': false,
    'has_ad_google': false,
    'has_ad_tiktok': false,
    'past_campaigns_details': '',
    'past_marketing_agency': '',
    'past_seo': '',
    'ad_budget': '',
    // 5. Operations & Shipping
    'shipping_service_details': '',
    'past_shipping_problems': '',
    'shipping_companies': '',
    'product_source': '', 
    'inventory_quantities': '',
    'pricing_vs_competitors': '',
    'profit_margin_range': '',
    'minimum_roas': '',
    'product_photos_link': '',
    'brand_identity_link': '',
    // 6. Payments & Integrations
    'payment_mada': false,
    'payment_visa': false,
    'payment_mastercard': false,
    'payment_applepay': false,
    'payment_stcpay': false,
    'payment_tabby': false,
    'payment_tamara': false,
    'payment_cod': false,
    'payment_bank_transfer': false,
    'active_discount_code': '',
    'past_technical_issues': '',
    'integration_gsc': false,
    'integration_gtm': false,
    'integration_ga4': false,
    'integration_yandex': false,
    'integration_clarity': false,
    'integration_gmc': false,
    'integration_gmb': false,
    'abandoned_cart_cartat': false,
    'abandoned_cart_carezone': false,
    'has_loyalty_program': '',
    'additional_notes': '',
    'social_media_access': <String, dynamic>{},
    'account_notes': '', 
  };

  Future<void> _completeOnboardingWithBrief() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryGreen),
      ),
    );

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        // 1. Mark onboarding completed in profiles table
        await Supabase.instance.client
            .from('profiles')
            .update({
              'onboarding_completed': true,
              'client_goal': _briefData['current_future_goals']?.toString() ?? 'إطلاق المتجر وزيادة المبيعات',
            })
            .eq('id', user.id);

        // 2. Save the complete client brief to the projects table
        await Supabase.instance.client
            .from('projects')
            .update({
              'client_brief': _briefData,
            })
            .eq('client_id', user.id);
      }

      if (mounted) {
        Navigator.pop(context); // close loading
        clearAppRouterCache();
        ref.invalidate(profileProvider);
        ref.invalidate(currentProjectProvider);
        context.go('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Widget _buildTextField({
    required String label,
    required String key,
    String? hint,
    bool isPassword = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          TextFormField(
            key: ValueKey(key),
            initialValue: _briefData[key]?.toString(),
            obscureText: isPassword,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
              filled: true,
              fillColor: AppTheme.cardColor,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white10),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white10),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.primaryGreen),
              ),
            ),
            onChanged: (val) {
              _briefData[key] = val;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String key,
    required List<String> options,
  }) {
    final val = _briefData[key]?.toString();
    final dropdownOptions = List<String>.from(options);
    if (val != null && val.isNotEmpty && !dropdownOptions.contains(val)) {
      dropdownOptions.add(val);
    }
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            key: ValueKey(key),
            value: val != null && val.isNotEmpty && dropdownOptions.contains(val) ? val : null,
            dropdownColor: AppTheme.cardColor,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: isAr ? 'اختر من القائمة...' : 'Select...',
              hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
              filled: true,
              fillColor: AppTheme.cardColor,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white10),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white10),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.primaryGreen),
              ),
            ),
            items: dropdownOptions.map((option) {
              return DropdownMenuItem<String>(
                value: option,
                child: Text(option, textDirection: TextDirection.rtl),
              );
            }).toList(),
            onChanged: (newVal) {
              if (newVal != null) {
                setState(() {
                  _briefData[key] = newVal;
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMultipleChoiceField({
    required String label,
    required String key,
    required List<String> options,
  }) {
    final rawVal = _briefData[key];
    List<String> selectedItems = [];
    if (rawVal is List) {
      selectedItems = List<String>.from(rawVal);
    } else if (rawVal is String && rawVal.isNotEmpty) {
      selectedItems = rawVal.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }

    return Padding(
      key: ValueKey(key),
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((option) {
              final isSelected = selectedItems.contains(option);
              return FilterChip(
                label: Text(option),
                selected: isSelected,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.black : Colors.white70,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                selectedColor: AppTheme.primaryGreen,
                checkmarkColor: Colors.black,
                backgroundColor: AppTheme.cardColor,
                side: BorderSide(
                  color: isSelected ? AppTheme.primaryGreen : Colors.white10,
                ),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      selectedItems.add(option);
                    } else {
                      selectedItems.remove(option);
                    }
                    _briefData[key] = selectedItems;
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialMediaOnboardingWidget() {
    final rawAccess = _briefData['social_media_access'];
    final Map<String, dynamic> accessMap = (rawAccess is Map)
        ? Map<String, dynamic>.from(rawAccess)
        : {};

    final platforms = [
      {'id': 'instagram', 'name': 'إنستغرام', 'icon': Icons.camera_alt_outlined, 'color': Colors.pink},
      {'id': 'snapchat', 'name': 'سناب شات', 'icon': Icons.snapchat_outlined, 'color': Colors.yellow},
      {'id': 'tiktok', 'name': 'تيك توك', 'icon': Icons.music_note_outlined, 'color': Colors.cyan},
      {'id': 'twitter', 'name': 'تويتر (X)', 'icon': Icons.close_outlined, 'color': Colors.white},
      {'id': 'youtube', 'name': 'يوتيوب', 'icon': Icons.play_circle_outline, 'color': Colors.red},
      {'id': 'facebook', 'name': 'فيسبوك', 'icon': Icons.facebook_outlined, 'color': Colors.blue},
      {'id': 'linkedin', 'name': 'لينكد إن', 'icon': Icons.work_outline, 'color': Colors.blueAccent},
    ];

    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isAr ? 'حسابات التواصل الاجتماعي (اختر المنصات أولاً):' : 'Social Media Accounts (Select platforms first):',
            style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: platforms.map((p) {
              final id = p['id'] as String;
              final isSelected = accessMap.containsKey(id);
              return FilterChip(
                label: Text(p['name'] as String),
                selected: isSelected,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.black : Colors.white70,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                selectedColor: AppTheme.primaryGreen,
                checkmarkColor: Colors.black,
                backgroundColor: const Color(0xFF0F172A),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      accessMap[id] = <String, dynamic>{'email': '', 'password': ''};
                    } else {
                      accessMap.remove(id);
                    }
                    _briefData['social_media_access'] = accessMap;
                  });
                },
              );
            }).toList(),
          ),
          if (accessMap.isNotEmpty) ...[
            const SizedBox(height: 16),
            ...platforms.where((p) => accessMap.containsKey(p['id'])).map((p) {
              final id = p['id'] as String;
              final dynamic rawCreds = accessMap[id];
              String email = '';
              String password = '';
              if (rawCreds is Map) {
                email = rawCreds['email']?.toString() ?? '';
                password = rawCreds['password']?.toString() ?? '';
              } else if (rawCreds is String) {
                email = rawCreds;
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(p['icon'] as IconData, color: p['color'] as Color, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          isAr ? 'بيانات دخول ${p['name']}' : '${p['name']} Access Credentials',
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Username/Email Field
                    TextFormField(
                      key: ValueKey('${id}_email'),
                      initialValue: email,
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: isAr
                            ? 'اسم المستخدم أو البريد الإلكتروني أو الرابط لـ ${p['name']}'
                            : 'Username, Email, or Link for ${p['name']}',
                        hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
                        filled: true,
                        fillColor: AppTheme.cardColor,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Colors.white10),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Colors.white10),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppTheme.primaryGreen),
                        ),
                      ),
                      onChanged: (newVal) {
                        final currentMap = (accessMap[id] is Map)
                            ? Map<String, dynamic>.from(accessMap[id] as Map)
                            : <String, dynamic>{'password': password};
                        currentMap['email'] = newVal;
                        accessMap[id] = currentMap;
                        _briefData['social_media_access'] = accessMap;
                      },
                    ),
                    const SizedBox(height: 8),
                    // Password Field
                    TextFormField(
                      key: ValueKey('${id}_password'),
                      initialValue: password,
                      obscureText: true,
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: isAr
                            ? 'كلمة المرور لـ ${p['name']}'
                            : 'Password for ${p['name']}',
                        hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
                        filled: true,
                        fillColor: AppTheme.cardColor,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Colors.white10),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Colors.white10),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppTheme.primaryGreen),
                        ),
                      ),
                      onChanged: (newVal) {
                        final currentMap = (accessMap[id] is Map)
                            ? Map<String, dynamic>.from(accessMap[id] as Map)
                            : <String, dynamic>{'email': email};
                        currentMap['password'] = newVal;
                        accessMap[id] = currentMap;
                        _briefData['social_media_access'] = accessMap;
                      },
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildCheckboxRow({
    required String label,
    required String key,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Checkbox(
            value: _briefData[key] == true,
            activeColor: AppTheme.primaryGreen,
            checkColor: Colors.black,
            side: const BorderSide(color: Colors.white30),
            onChanged: (val) {
              setState(() {
                _briefData[key] = val ?? false;
              });
            },
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  void _nextPage() {
    if (_currentPage < 4) {
      HapticService.light();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.fastOutSlowIn,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Global Particles Background
          CircularParticle(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            particleColor: AppTheme.primaryGreen.withValues(alpha: 0.2),
            numberOfParticles: 40,
            speedOfParticles: 0.5,
            maxParticleSize: 4,
            isRandomColor: false,
            randColorList: const [AppTheme.primaryGreen, AppTheme.primaryBlue],
            isRandSize: true,
            connectDots: false,
          ),

          SafeArea(
            child: PageView(
              controller: _pageController,
              physics:
                  const NeverScrollableScrollPhysics(), // user must use buttons to advance
              onPageChanged: (i) => setState(() => _currentPage = i),
              children: [
                _buildWelcomeStep(),
                _buildTeamStep(),
                _buildRoadmapStep(),
                _buildExpectationsStep(),
                if (Supabase.instance.client.auth.currentUser != null) _buildGoalStep(),
              ],
            ),
          ),

          // Progress Dots
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                Supabase.instance.client.auth.currentUser != null ? 5 : 4,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? AppTheme.primaryGreen
                        : Colors.white24,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeStep() {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          Image.asset(
            AppConfig.logoAsset,
            width: 200,
            color: Colors.white,
            errorBuilder: (c, e, s) => const Icon(
              Icons.rocket_launch,
              size: 80,
              color: AppTheme.primaryGreen,
            ),
          ),
          const SizedBox(height: 40),
          Text(
            l10n.welcomeTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.thrilledPartner,
            style: const TextStyle(color: Colors.grey, fontSize: 16),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                l10n.letsBegin,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildTeamStep() {
    final l10n = AppLocalizations.of(context)!;
    final projectAsync = ref.watch(currentProjectProvider);

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          Text(
            l10n.meetYourTeam,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.peopleWorkingForYou,
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 16),
          ),
          const SizedBox(height: 48),

          projectAsync.when(
            data: (p) {
              final isAr = Localizations.localeOf(context).languageCode == 'ar';
              final amName = (isAr ? 'مدير النمو' : 'Growth Manager');
              final amRole = isAr ? 'مدير حسابك الشخصي' : 'Your Growth Manager';
              const String? amAvatar = null;

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _teamCard(amName, amRole, Icons.person, avatarUrl: amAvatar),
                    _teamCard(
                      isAr ? 'فريق الدعم' : 'Support Team', 
                      isAr ? 'دعم فني 24/7' : '24/7 Tech Support', 
                      Icons.support_agent_outlined
                    ),
                    _teamCard(
                      isAr ? 'محرك الذكاء' : 'Moharek AI', 
                      isAr ? 'مساعدك الرقمي' : 'Digital Intelligence', 
                      Icons.auto_awesome_outlined
                    ),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
            error: (_, __) => const Text('Error loading team', style: TextStyle(color: Colors.red)),
          ),

          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
              ),
              child: Text(
                l10n.next,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _teamCard(String name, String role, IconData icon, {String? avatarUrl}) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF334155)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.1),
            backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
            child: avatarUrl == null ? Icon(icon, color: AppTheme.primaryGreen, size: 30) : null,
          ),
          const SizedBox(height: 20),
          Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            role,
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRoadmapStep() {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          Text(
            l10n.roadmapTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.structuredPlan,
            style: const TextStyle(color: Colors.grey, fontSize: 16),
          ),
          const SizedBox(height: 40),

          Expanded(
            child: ListView(
              children: [
                _timelineItem('Day 1', l10n.auditOnboarding, true),
                _timelineItem('Day 7', l10n.strategyDelivered, false),
                _timelineItem('Day 30', l10n.firstCampaign, false),
                _timelineItem('Day 60', l10n.optimizationReview, false),
                _timelineItem(
                  'Day 90',
                  l10n.quarterlyReport,
                  false,
                  isLast: true,
                ),
              ],
            ),
          ),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                l10n.next,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _timelineItem(
    String day,
    String title,
    bool active, {
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: active
                    ? AppTheme.primaryGreen
                    : Colors.grey.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 50,
                color: active
                    ? AppTheme.primaryGreen.withValues(alpha: 0.5)
                    : Colors.white10,
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  day,
                  style: TextStyle(
                    color: active ? AppTheme.primaryGreen : Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(
                    color: active ? Colors.white : Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExpectationsStep() {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          Text(
            l10n.whatToExpect,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 40),

          _expectationRow(Icons.bar_chart, l10n.trackResults),
          const SizedBox(height: 24),
          _expectationRow(Icons.check_circle_outline, l10n.approveContent),
          const SizedBox(height: 24),
          _expectationRow(Icons.chat_bubble_outline, l10n.talkGrowthManager),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                final user = Supabase.instance.client.auth.currentUser;
                if (user == null) {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('onboarding_shown', true);
                  if (mounted) {
                    context.go('/login');
                  }
                } else {
                  _nextPage();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                l10n.almostDone,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _expectationRow(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppTheme.primaryBlue, size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGoalStep() {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    String stepTitle = '';
    List<Widget> stepFields = [];

    switch (_briefStep) {
      case 0:
        stepTitle = isAr ? '1. معلومات النشاط والحساب' : '1. Account & Business Info';
        stepFields = [
          _buildTextField(
            label: isAr ? 'بريد المنصة الإلكترونية' : 'Platform Email',
            key: 'platform_mail',
            hint: 'example@store.com',
          ),
          _buildTextField(
            label: isAr ? 'كلمة مرور المنصة' : 'Platform Password',
            key: 'platform_password',
            isPassword: true,
          ),
          _buildTextField(
            label: isAr ? 'الوقت المناسب للتواصل' : 'Best Contact Time',
            key: 'best_contact_time',
            hint: 'مثال: مساءً من 4 إلى 8',
          ),
          _buildDropdownField(
            label: isAr ? 'طبيعة العمل' : 'Employment Type',
            key: 'employment_type',
            options: [
              'موظف بدوام كامل',
              'عمل حر',
              'رائد أعمال / صاحب عمل',
              'غير ذلك',
            ],
          ),
          _buildDropdownField(
            label: isAr ? 'كيان النشاط' : 'Business Structure',
            key: 'business_structure',
            options: [
              'مؤسسة فردية',
              'شركة',
              'شراكة',
              'غير ذلك',
            ],
          ),
          _buildDropdownField(
            label: isAr ? 'المدة المتوقعة للاستثمار لتحقيق نتائج' : 'Expected Investment Timeline',
            key: 'investment_timeline',
            options: [
              'أقل من ٣ أشهر',
              'من ٣ إلى ٦ أشهر',
              'من ٦ إلى ١٢ شهر',
              'أكثر من سنة',
            ],
          ),
          _buildTextField(
            label: isAr ? 'عمر المتجر وتاريخ البدء' : 'Store Age & Start Date',
            key: 'store_age',
            hint: 'مثال: سنة / متجر جديد',
          ),
          _buildTextField(
            label: isAr ? 'هل يوجد مقر أو متجر على أرض الواقع؟' : 'Has Offline Retail Store?',
            key: 'has_offline_store',
            hint: 'مثال: نعم في الرياض / لا متجر إلكتروني فقط',
          ),
          _buildDropdownField(
            label: isAr ? 'مرحلة المتجر ووضعه الحالي في السوق' : 'Current Market Stage',
            key: 'store_market_stage',
            options: [
              'مرحلة البداية',
              'مرحلة النمو',
              'مرحلة النضج',
            ],
          ),
        ];
        break;
      case 1:
        stepTitle = isAr ? '2. الأهداف والمنافسة' : '2. Goals & Competition';
        stepFields = [
          _buildTextField(
            label: isAr ? 'أهداف المتجر الحالية والمستقبلية' : 'Current & Future Goals',
            key: 'current_future_goals',
            hint: 'مثال: زيادة المبيعات، بناء علامة تجارية',
          ),
          _buildMultipleChoiceField(
            label: isAr ? 'أكثر فئة عمرية مستهدفة/تتفاعل معنا' : 'Target Age Group',
            key: 'target_age_group',
            options: [
              '١٣-١٧',
              '١٨-٢٤',
              '٢٥-٣٤',
              '٣٥-٤٤',
              '٤٥-٥٤',
              '٥٥+',
              'جميع الفئات العمرية',
            ],
          ),
          _buildTextField(
            label: isAr ? 'أكثر المنتجات مبيعاً للمتجر' : 'Best Selling Products',
            key: 'best_selling_products',
            hint: 'اذكر أهم المنتجات مبيعاً حالياً',
          ),
          _buildTextField(
            label: isAr ? 'المنافسون لنشاطك' : 'Competitors',
            key: 'competitors',
            hint: 'مثال: متجر س، متجر ص',
          ),
          _buildTextField(
            label: isAr ? 'الميزة التنافسية لمتجرك' : 'Competitive Advantage / USP',
            key: 'competitive_advantage',
            hint: 'شحن مجاني سريع، سعر منافس، جودة أعلى...',
          ),
        ];
        break;
      case 2:
        stepTitle = isAr ? '3. التسويق والمنصات الإعلانية' : '3. Marketing & Ad Channels';
        stepFields = [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              isAr ? 'هل تمتلك حسابات إعلانية فعالة للمنصات التالية؟' : 'Do you have active ad accounts on these platforms?',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
          _buildCheckboxRow(label: 'Snapchat', key: 'has_ad_snapchat'),
          _buildCheckboxRow(label: 'Meta (Instagram / Facebook)', key: 'has_ad_meta'),
          _buildCheckboxRow(label: 'Google Ads', key: 'has_ad_google'),
          _buildCheckboxRow(label: 'TikTok', key: 'has_ad_tiktok'),
          const SizedBox(height: 16),
          _buildTextField(
            label: isAr ? 'هل توجد حملات إعلانية سابقة؟ وكيف كان مردودها؟' : 'Previous Ad Campaigns & Results',
            key: 'past_campaigns_details',
            hint: 'اذكر المنصات والمردود العام للحملات',
          ),
          _buildTextField(
            label: isAr ? 'هل تعاملت مع شركة/وكالة تسويق من قبل؟' : 'Previous Agency Experience',
            key: 'past_marketing_agency',
            hint: 'نعم (اذكر التجربة باختصار) / لا',
          ),
          _buildTextField(
            label: isAr ? 'هل تم عمل سيو (SEO) للموقع من قبل؟' : 'Previous SEO Work Done',
            key: 'past_seo',
            hint: 'نعم / لا',
          ),
          _buildTextField(
            label: isAr ? 'الميزانية الشهرية المتاحة للحملات الإعلانية' : 'Monthly Ad Budget',
            key: 'ad_budget',
            hint: isAr ? 'مثال: ١٠,٠٠٠ ريال / شهر' : 'e.g. 10,000 SAR / month',
          ),
        ];
        break;
      case 3:
        stepTitle = isAr ? '4. العمليات، الدفع، والربط التقني' : '4. Operations, Payments & Integrations';
        stepFields = [
          _buildTextField(
            label: isAr ? 'تفاصيل الشحن (أقصى قيمة، مدة، التغطية)' : 'Shipping Details (Cost, Duration, Region)',
            key: 'shipping_service_details',
            hint: 'مثال: 25 ريال، 3 أيام، كافة مناطق المملكة',
          ),
          _buildTextField(
            label: isAr ? 'أبرز مشاكل الشحن السابقة التي واجهت العملاء' : 'Past Shipping Issues',
            key: 'past_shipping_problems',
          ),
          _buildTextField(
            label: isAr ? 'شركات الشحن المتعاقد معها حالياً' : 'Shipping Companies Contracted',
            key: 'shipping_companies',
            hint: 'أرامكس، سمسا، سبل...',
          ),
          _buildDropdownField(
            label: isAr ? 'مصدر المنتجات (مالك ومستورد أم دروب شيبنج؟)' : 'Product Sourcing / Ownership',
            key: 'product_source',
            options: [
              'مالك ومستورد',
              'دروب شيبنج',
              'كلاهما',
            ],
          ),
          _buildTextField(
            label: isAr ? 'كميات المنتجات المتوفرة والمخزون المتاح' : 'Available Inventory Stock',
            key: 'inventory_quantities',
          ),
          _buildTextField(
            label: isAr ? 'رنج الأسعار مقارنة بالمنافسين وطريقة التسعير' : 'Pricing Range & Strategy vs Competitors',
            key: 'pricing_vs_competitors',
          ),
          _buildTextField(
            label: isAr ? 'هامش الربح المتوقع (%)' : 'Expected Profit Margin (%)',
            key: 'profit_margin_range',
            hint: 'مثال: 30% - 50%',
          ),
          _buildTextField(
            label: isAr ? 'أفضل عائد إعلاني (ROAS) لتحقيق الربح' : 'Minimum Required ROAS',
            key: 'minimum_roas',
          ),
          _buildTextField(
            label: isAr ? 'رابط لصور المنتجات بجودة عالية (إن وجد)' : 'High Quality Product Photos Link',
            key: 'product_photos_link',
          ),
          _buildTextField(
            label: isAr ? 'رابط للهوية البصرية / شعار المتجر' : 'Brand Identity Files Link',
            key: 'brand_identity_link',
          ),
          const SizedBox(height: 16),
          Text(
            isAr ? 'بوابات الدفع المفعلة:' : 'Enabled Payment Gateways:',
            style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildCheckboxRow(label: 'مدى (Mada)', key: 'payment_mada'),
          _buildCheckboxRow(label: 'فيزا (Visa)', key: 'payment_visa'),
          _buildCheckboxRow(label: 'ماستركارد (Mastercard)', key: 'payment_mastercard'),
          _buildCheckboxRow(label: 'أبل باي (Apple Pay)', key: 'payment_applepay'),
          _buildCheckboxRow(label: 'STC Pay', key: 'payment_stcpay'),
          _buildCheckboxRow(label: 'تابي (Tabby)', key: 'payment_tabby'),
          _buildCheckboxRow(label: 'تمارا (Tamara)', key: 'payment_tamara'),
          _buildCheckboxRow(label: 'الدفع عند الاستلام (COD)', key: 'payment_cod'),
          _buildCheckboxRow(label: 'تحويل بنكي (Bank Transfer)', key: 'payment_bank_transfer'),
          const SizedBox(height: 16),
          _buildTextField(
            label: isAr ? 'كود خصم فعال لتجربة الشراء' : 'Active Discount Code',
            key: 'active_discount_code',
          ),
          _buildTextField(
            label: isAr ? 'أي مشاكل تقنية واجهتكم أو اشتكى منها العملاء' : 'Past Technical Store Issues',
            key: 'past_technical_issues',
          ),
          const SizedBox(height: 16),
          Text(
            isAr ? 'الربط والتحليلات المفعلة:' : 'Enabled Integrations & Analytics:',
            style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildCheckboxRow(label: 'Google Search Console', key: 'integration_gsc'),
          _buildCheckboxRow(label: 'Google Tag Manager', key: 'integration_gtm'),
          _buildCheckboxRow(label: 'Google Analytics (GA4)', key: 'integration_ga4'),
          _buildCheckboxRow(label: 'Yandex Metrica', key: 'integration_yandex'),
          _buildCheckboxRow(label: 'Microsoft Clarity', key: 'integration_clarity'),
          _buildCheckboxRow(label: 'Google Merchant Center', key: 'integration_gmc'),
          _buildCheckboxRow(label: 'Google My Business', key: 'integration_gmb'),
          const SizedBox(height: 16),
          Text(
            isAr ? 'برامج التواصل مع السلات المتروكة:' : 'Abandoned Cart Tools:',
            style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildCheckboxRow(label: 'كارتات (Cartat)', key: 'abandoned_cart_cartat'),
          _buildCheckboxRow(label: 'كيرزون (Carezone)', key: 'abandoned_cart_carezone'),
          const SizedBox(height: 16),
          _buildTextField(
            label: isAr ? 'هل يوجد برنامج ولاء ومكافآت للعملاء؟' : 'Is Customer Loyalty Program Available?',
            key: 'has_loyalty_program',
            hint: 'مثال: نعم (قطاف / نقاط) / لا',
          ),
          _buildSocialMediaOnboardingWidget(),
          _buildTextField(
            label: isAr ? 'أي ملاحظات أو طلبات إضافية' : 'Any Additional Notes',
            key: 'additional_notes',
          ),
        ];
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isAr ? 'تعبئة بريف المشروع' : 'Complete Project Brief',
                    style: const TextStyle(color: AppTheme.primaryGreen, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_briefStep + 1} / 4',
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () async {
                  HapticService.light();
                  await _completeOnboardingWithBrief();
                },
                icon: const Icon(Icons.exit_to_app, color: Colors.amberAccent, size: 16),
                label: Text(
                  isAr ? 'حفظ وخروج' : 'Save & Exit',
                  style: const TextStyle(color: Colors.amberAccent, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            stepTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: stepFields,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (_briefStep > 0)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: OutlinedButton(
                      onPressed: () {
                        HapticService.light();
                        setState(() {
                          _briefStep--;
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white24),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(isAr ? 'السابق' : 'Previous'),
                    ),
                  ),
                ),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    HapticService.light();
                    if (_briefStep < 3) {
                      setState(() {
                        _briefStep++;
                      });
                    } else {
                      await _completeOnboardingWithBrief();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    _briefStep < 3 
                        ? (isAr ? 'التالي' : 'Next') 
                        : (isAr ? 'حفظ ودخول لوحة التحكم' : 'Save & Enter Dashboard'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }
}
