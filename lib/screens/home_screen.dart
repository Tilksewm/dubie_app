import 'dart:io';

import 'package:dubie_app/app_constants.dart';
import 'package:dubie_app/l10n/app_localizations.dart';
import 'package:dubie_app/providers/language_provider.dart';
import 'package:dubie_app/screens/auth/login_screen.dart';
import 'package:dubie_app/screens/pin_lock_screen.dart';
import 'package:dubie_app/screens/profile_edit_screen.dart';
import 'package:dubie_app/screens/settings_screen.dart';
import 'package:dubie_app/screens/signin_suggestion_card.dart';
import 'package:dubie_app/services/sync_service.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // For number formatting

import 'package:dubie_app/providers/auth_provider.dart';
import 'package:dubie_app/providers/home_provider.dart';
import 'package:dubie_app/widgets/home_user_card.dart'; // We will create this
import 'package:dubie_app/screens/add_user_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/sync_provider.dart';
import '../widgets/sync_status_indicator.dart'; // We will create this

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  bool suggestLogin = false;
  late TabController _tabController;

  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;

  @override
  void initState() {
    super.initState();
    validSuggestionCount();
    _tabController = TabController(length: 2, vsync: this);
    // Fetch initial data when the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Provider.of<HomeProvider>(context, listen: false).fetchAllHomeData();
    });
  }
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadBannerAd();
  }

  void _loadBannerAd() async {
    final width = MediaQuery.of(context).size.width.truncate();
    final AnchoredAdaptiveBannerAdSize? size =
        await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);

    if (size == null) {
      debugPrint('Failed to get adaptive ad size');
      return;
    }
    _bannerAd = BannerAd(
      adUnitId: AppConstants.bannerAdUnitIdHome,
      request: const AdRequest(),
      size: size,
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          print('$BannerAd loaded.');
          setState(() {
            _bannerAd = ad as BannerAd;
            _isBannerAdLoaded = true;
          });
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          print('$BannerAd failedToLoad: $error');
          ad.dispose();
          setState(() {
            _isBannerAdLoaded = false;
          });
        },
        onAdOpened: (Ad ad) => print('$BannerAd onAdOpened.'),
        onAdClosed: (Ad ad) => print('$BannerAd onAdClosed.'),
        onAdImpression: (Ad ad) => print('$BannerAd onAdImpression.'),
      ),
    )..load();
  }


  @override
  void dispose() {
    _tabController.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  Future<void> _refreshHomeData() async {
    await Provider.of<HomeProvider>(context, listen: false).fetchAllHomeData();
  }
  // New: Method to manually lock the app
  void _lockAppManually() async {
    final loc = AppLocalizations.of(context)!;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isPinEnabled) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (ctx) => PinLockScreen(
            onPinVerified: () {
              Navigator.of(ctx).pop();
            },
          ),
          fullscreenDialog: true,
          settings: const RouteSettings(name: '/pin_lock'), // Use route name
        ),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
            builder: (ctx) => SettingsScreen(),
        )
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.enablePinInSettings)),
      );
    }
  }
  String getInitials(String fullName) {
    final parts = fullName.trim().split(" ");
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return "${parts[0][0].toUpperCase()}${parts[1][0].toUpperCase()}";
  }
  Future<void> validSuggestionCount() async {
    final preferences = await SharedPreferences.getInstance();
    if (preferences.getInt('visibility_count') == null){
      await preferences.setInt('visibility_count', 0);
    }
    int visibilityCount = preferences.getInt('visibility_count')!;
    suggestLogin = visibilityCount<3;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final homeProvider = context.watch<HomeProvider>();
    final langProvider = Provider.of<LanguageProvider>(context);
    final syncProvider = Provider.of<SyncProvider>(context);
    final loc = AppLocalizations.of(context)!;
    final user = authProvider.currentUser;
    final bool suggestLogin = (!authProvider.isAuthenticated) && this.suggestLogin;
    // Format numbers as currency
    final NumberFormat currencyFormatter = NumberFormat.currency(
      locale: 'en_US', // Or your desired locale for currency
      symbol: 'ETB ', // Ethiopian Birr, or '$' etc.
      decimalDigits: 2,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.appName),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: SyncStatusIndicator(isSynced: syncProvider.isSynced),
          ),
          IconButton(
            icon: const Icon(Icons.lock_open),
            onPressed: _lockAppManually,
            tooltip: loc.lockApp,
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            UserAccountsDrawerHeader(
              accountName: Text(user?.name ?? loc.guestUser),
              accountEmail: Text(user?.email ?? loc.noEmail),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : '?',
                  style: const TextStyle(fontSize: 40.0, color: Colors.blue),
                ),
              ),
              decoration: const BoxDecoration(
                color: Colors.blue,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: Text(loc.profile),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(

                    content:
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Center(
                          child: CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.teal.shade700,
                            child: Text(
                              getInitials(user!.name),
                              style: const TextStyle(
                                fontSize: 28,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: Text(
                            user.name,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: Text(
                            user.email ?? "",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),
                        if (user.phone != null && user.phone!.isNotEmpty) ...[
                          Row(
                            children: [
                              const Icon(Icons.phone, color: Colors.blueAccent),
                              const SizedBox(width: 10),
                              Text(user.phone!),
                            ],
                          ),
                          const SizedBox(height: 10),
                        ],
                        if (user.username != null && user.username!.isNotEmpty) ...[
                          Row(
                            children: [
                              const Icon(Icons.person, color: Colors.teal),
                              const SizedBox(width: 10),
                              Text(user.username!),
                            ],
                          ),
                        ],
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(ctx).pop(); // Close dialog
                        },
                        child: Text(loc.close),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          Navigator.of(ctx).pop(); // Close current dialog
                          await Navigator.of(context).push(
                            MaterialPageRoute(builder: (ctx) => const ProfileEditScreen()),
                          );
                          // Refresh profile data in drawer after editing
                          authProvider.refreshProfileData();
                        },
                        child: Text(loc.edit),
                      ),
                    ],
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: Text(loc.settings),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (ctx) => const SettingsScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.language),
              title: Text(loc.language),
              trailing: DropdownButton<Locale>(
                value: langProvider.locale,
                  items: AppLocalizations.supportedLocales.map((locale) {
                    final code = locale.languageCode;
                    return DropdownMenuItem(
                      value: locale,
                        child: Text('${getCountry(code)}')
                    );
                  }).toList(),
                  onChanged: (locale) {
                  if (locale != null){
                    langProvider.setLanguage(locale);
                    Navigator.pop(context);
                  }
                }
              ),
            ),
            authProvider.isAuthenticated ?
              ListTile(
                leading: const Icon(Icons.logout),
                title: Text(loc.logout),
                onTap: () async {
                  await logout(authProvider);
                  },
              ):
            // The sign in/sign up section
            const Divider(),
            if (!authProvider.isAuthenticated)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    loc.signinSuggestion,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14.0),
                  ),
                  const SizedBox(height: 16.0),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32.0, vertical: 12.0),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (context) => const LoginScreen()
                          )
                      );
                    },
                    child: Text(loc.signinSignup),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          homeProvider.isLoadingSummary
              ? const Center(child: CircularProgressIndicator())
              : homeProvider.summaryError != null
              ? RefreshIndicator(
                  onRefresh: _refreshHomeData,
                  child: Center(child: Text('${loc.error}: ${homeProvider.summaryError}')),
              )
              :
          // Home Summary Cards
          TabBar(
            controller: _tabController,
            tabs: [
              Tab(
                child:
                Column(
                  children: [
                    Text(loc.youLent, style: TextStyle(fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(
                      currencyFormatter.format(homeProvider.homeSummary?['lent'] ?? 0.0),
                      style: TextStyle(fontSize: 12, color: Colors.green.shade700, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Tab(
                child:// Borrowers (users who owe current user)
                Column(
                  children: [
                    Text(loc.youBorrow, style: TextStyle(fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(
                      currencyFormatter.format(homeProvider.homeSummary?['borrow'] ?? 0.0),
                      style: TextStyle(fontSize: 12, color: Colors.red.shade700, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              )// Creditors (users current user owes)
            ],
            labelColor: Colors.black,
            unselectedLabelColor: Colors.black87,
            indicatorColor: Colors.black,
          ),
          if (suggestLogin)
          SignInSuggestionCard(),
          Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshHomeData,
                child:
                TabBarView(
                  controller: _tabController,
                  children: [

                    // "Owes You" Tab (Borrowers)
                    homeProvider.isLoadingBorrowers || homeProvider.borrowers == null
                        ? const Center(child: CircularProgressIndicator())
                        : homeProvider.borrowersError != null
                        ?
                    RefreshIndicator(
                      onRefresh: _refreshHomeData,
                      child: LayoutBuilder(builder: (context, constraints){
                        return ListView(
                          children: [
                            ConstrainedBox (
                                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                                child: Center( child: Text('${loc.error}: ${homeProvider.borrowersError}'))
                            )
                          ],
                        );
                      }),
                    )
                        : homeProvider.borrowers!.isEmpty
                        ?
                    RefreshIndicator(
                        onRefresh: _refreshHomeData,
                        child: LayoutBuilder(builder: (context, constraints){
                          return ListView(
                            children: [
                              ConstrainedBox (
                                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                                child: Center( child: Text(loc.noLent))
                              )
                            ],
                          );
                        }),
                    )
                        :
                    RefreshIndicator( // Added RefreshIndicator
                      onRefresh: _refreshHomeData,
                      child:
                      ListView.builder(
                        itemCount: homeProvider.borrowers!.length,
                        itemBuilder: (context, index) {
                          final user = homeProvider.borrowers![index];
                          return HomeUserCard(
                            homeUser: user,
                            isOwedByMe: true,
                            mainUser: authProvider.currentUser!, // They owe me
                          );
                        },
                      ),
                    ),

                    // "You Owe" Tab (Creditors)
                    homeProvider.isLoadingCreditors || homeProvider.creditors == null
                        ? const Center(child: CircularProgressIndicator())
                        : homeProvider.creditorsError != null
                        ?
                    RefreshIndicator(
                      onRefresh: _refreshHomeData,
                      child: LayoutBuilder(builder: (context, constraints){
                        return ListView(
                          children: [
                            ConstrainedBox (
                                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                                child: Center( child: Text('${loc.error}: ${homeProvider.creditorsError}'))
                            )
                          ],
                        );
                      }),
                    )
                        : homeProvider.creditors!.isEmpty
                        ?
                    RefreshIndicator(
                        onRefresh: _refreshHomeData,
                      child: LayoutBuilder(builder: (context, constraints){
                        return ListView(
                          children: [
                            ConstrainedBox (
                                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                                child: Center( child: Text(loc.noBorrow))
                            )
                          ],
                        );
                      }),
                    )
                        :
                    RefreshIndicator( // Added RefreshIndicator
                      onRefresh: _refreshHomeData,
                      child: ListView.builder(
                        itemCount: homeProvider.creditors!.length,
                        itemBuilder: (context, index) {
                          final user = homeProvider.creditors![index];
                          return HomeUserCard(
                            homeUser: user,
                            isOwedByMe: false, // This should likely be false for the "You Owe" tab
                            mainUser: authProvider.currentUser!, // User owes them
                          );
                        },
                      ),
                    ),
                  ],
                ),
              )
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => AddUserScreen(mainUser: user!,)),
          );
          if (result == true) {
            // If a new user was added successfully, refresh the home screen data
            _refreshHomeData();
          }
        },
        child: const Icon(Icons.person_add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: _bannerAd != null && _isBannerAdLoaded
          ? SizedBox(
              height: _bannerAd!.size.height.toDouble(),
              width: _bannerAd!.size.width.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            )
          : const SizedBox.shrink(), // Placeholder height until ad loads
    );
  }

  getCountry(String code) {
    switch(code){
      case 'en':
        return 'English';
      case 'am':
        return 'Amharic';
      default:
        return code;
    }
  }

  Future<void> logout(AuthProvider authProvider) async {
    final loc = AppLocalizations.of(context)!;
    final syncProvider = Provider.of<SyncProvider>(context, listen: false);
    SyncService syncService = SyncService();
    await syncService.syncData();
    if (syncProvider.isLoading){
      const CircularProgressIndicator(); // This will not be visible here, consider a dialog or snackbar
    }else if (syncProvider.isSynced){
      Navigator.pop(context); // Close the drawer first
      await authProvider.logout();
      await Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => const LoginScreen()));
    }else {
      showDialog(
        context: context,
        builder: (ctx) =>
            AlertDialog(
              title: Text(loc.syncFailed),
              content: Text(
                  loc.onLogoutSyncFailedMessage),
              actions: [
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx); // Close the dialog
                    Navigator.pop(context); // Close the drawer
                    await authProvider.logout();
                    await Navigator.of(context).push(MaterialPageRoute(
                        builder: (ctx) => const LoginScreen()));
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: Text(loc.logoutAnyway,
                      style: const TextStyle(color: Colors.white)),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(ctx); // Close the dialog
                    await logout(authProvider);
                  },
                  child: Text(loc.trySyncAgain),
                ),
              ],
            ),
      );
    }
  }
}