import 'package:dubie_app/l10n/app_localizations.dart';
import 'package:dubie_app/providers/language_provider.dart';
import 'package:dubie_app/screens/auth/login_screen.dart';
import 'package:dubie_app/screens/pin_lock_screen.dart';
import 'package:dubie_app/screens/profile_edit_screen.dart';
import 'package:dubie_app/screens/settings_screen.dart';
import 'package:dubie_app/screens/signin_suggestion_card.dart';
import 'package:dubie_app/services/sync_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // For number formatting

import 'package:dubie_app/providers/auth_provider.dart';
import 'package:dubie_app/providers/home_provider.dart';
import 'package:dubie_app/widgets/home_user_card.dart'; // We will create this
import 'package:dubie_app/screens/add_user_screen.dart';
import 'package:shared_preferences/shared_preferences.dart'; // We will create this

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  bool suggestLogin = false;
  late TabController _tabController;

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
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshHomeData() async {
    await Provider.of<HomeProvider>(context, listen: false).fetchAllHomeData();
  }
  // New: Method to manually lock the app
  void _lockAppManually() async {
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
        const SnackBar(content: Text('PIN lock is not enabled.')),
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
          IconButton(
            icon: const Icon(Icons.lock_open),
            onPressed: _lockAppManually,
            tooltip: 'Lock App',
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            UserAccountsDrawerHeader(
              accountName: Text(user?.name ?? 'Guest User'),
              accountEmail: Text(user?.email ?? 'No Email'),
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
              title: const Text('Profile'),
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
                        child: const Text('Close'),
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
                        child: const Text('Edit'),
                      ),
                    ],
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (ctx) => const SettingsScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.language),
              title: const Text('Language'),
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
                title: const Text('Logout'),
                onTap: () async {
                  Navigator.pop(context); // Close the drawer first
                  await authProvider.logout();
                  await Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => const LoginScreen()));
                },
              ):
            // The sign in/sign up section
            const Divider(),
            if (!authProvider.isAuthenticated)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text(
                    'Sign in to sync your data and get personalized content.',
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
                    child: const Text('Sign In / Sign Up'),
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
                  child: Center(child: Text('Error: ${homeProvider.summaryError}')),
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
                    Text('You Lent', style: TextStyle(fontSize: 14)),
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
                    Text('You Borrow', style: TextStyle(fontSize: 14)),
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
                                child: Center( child: Text('Error: ${homeProvider.borrowersError}'))
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
                                child: Center( child: Text('No one currently owes you money.'))
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
                            isOwedByMe: true, // They owe me
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
                                child: Center( child: Text('Error: ${homeProvider.creditorsError}'))
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
                                child: Center( child: Text('No one currently you owes money.'))
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
                            isOwedByMe: true, // They owe me
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
            MaterialPageRoute(builder: (context) => const AddUserScreen()),
          );
          if (result == true) {
            // If a new user was added successfully, refresh the home screen data
            _refreshHomeData();
          }
        },
        child: const Icon(Icons.person_add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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
}