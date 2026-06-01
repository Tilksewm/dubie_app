import 'package:dubie_app/screens/pin_lock_screen.dart';
import 'package:dubie_app/screens/profile_edit_screen.dart';
import 'package:dubie_app/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // For number formatting

import 'package:dubie_app/providers/auth_provider.dart';
import 'package:dubie_app/providers/home_provider.dart';
import 'package:dubie_app/models/user.dart';
import 'package:dubie_app/widgets/home_user_card.dart'; // We will create this
import 'package:dubie_app/screens/add_user_screen.dart'; // We will create this

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showCashActions = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Fetch initial data when the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<HomeProvider>(context, listen: false).fetchAllHomeData();
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
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (ctx) => SettingsScreen()));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('PIN lock is not enabled.')));
    }
  }

  String getInitials(String fullName) {
    final parts = fullName.trim().split(" ");
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return "${parts[0][0].toUpperCase()}${parts[1][0].toUpperCase()}";
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final homeProvider = Provider.of<HomeProvider>(context);
    final user = authProvider.currentUser;
    // Format numbers as currency
    final NumberFormat currencyFormatter = NumberFormat.currency(
      locale: 'en_US', // Or your desired locale for currency
      symbol: 'ETB ', // Ethiopian Birr, or '$' etc.
      decimalDigits: 2,
    );
    final double onHand = homeProvider.homeSummary?['on_hand'] ?? 0.0;

    final double lent = homeProvider.homeSummary?['lent'] ?? 0.0;

    final double borrow = homeProvider.homeSummary?['borrow'] ?? 0.0;

    final double receivableImpact = onHand + lent;

    final double netWorth = onHand + lent - borrow;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ዱቤ App'),
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
              accountEmail: Text(user?.email ?? 'N/A'),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  user?.name.isNotEmpty == true
                      ? user!.name[0].toUpperCase()
                      : '?',
                  style: const TextStyle(fontSize: 40.0, color: Colors.blue),
                ),
              ),
              decoration: const BoxDecoration(color: Colors.blue),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    content: Column(
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
                        if (user.username != null &&
                            user.username!.isNotEmpty) ...[
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
                            MaterialPageRoute(
                              builder: (ctx) => const ProfileEditScreen(),
                            ),
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
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                Navigator.pop(context); // Close the drawer first
                await authProvider.logout();
                if (mounted) {
                  Navigator.of(
                    context,
                  ).pushReplacementNamed('/login'); // Corrected from /auth
                }
              },
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
                  child: Center(
                    child: Text('Error: ${homeProvider.summaryError}'),
                  ),
                )
              :
                // Home Summary Cards
                TabBar(
                  controller: _tabController,
                  tabs: [
                    Tab(
                      child: Column(
                        children: [
                          Text('You Lent', style: TextStyle(fontSize: 14)),
                          const SizedBox(height: 4),
                          Text(
                            currencyFormatter.format(
                              homeProvider.homeSummary?['lent'] ?? 0.0,
                            ),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Tab(
                      child: // Borrowers (users who owe current user)
                      Column(
                        children: [
                          Text('You Borrow', style: TextStyle(fontSize: 14)),
                          const SizedBox(height: 4),
                          Text(
                            currencyFormatter.format(
                              homeProvider.homeSummary?['borrow'] ?? 0.0,
                            ),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ), // Creditors (users current user owes)
                    Tab(
                      child: Column(
                        children: [
                          const Text('On Hand', style: TextStyle(fontSize: 14)),
                          const SizedBox(height: 4),
                          Text(
                            currencyFormatter.format(
                              homeProvider.homeSummary?['on_hand'] ?? 0.0,
                            ),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  labelColor: Colors.black,
                  unselectedLabelColor: Colors.black87,
                  indicatorColor: Colors.black,
                ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshHomeData,
              child: TabBarView(
                controller: _tabController,
                children: [
                  // "Owes You" Tab (Borrowers)
                  homeProvider.isLoadingBorrowers
                      ? const Center(child: CircularProgressIndicator())
                      : homeProvider.borrowersError != null
                      ? RefreshIndicator(
                          onRefresh: _refreshHomeData,
                          child: Center(
                            child: Text(
                              'Error: ${homeProvider.borrowersError}',
                            ),
                          ),
                        )
                      : homeProvider.borrowers!.isEmpty
                      ? RefreshIndicator(
                          onRefresh: _refreshHomeData,
                          child: const Center(
                            child: Text('No one currently owes you money.'),
                          ),
                        )
                      : RefreshIndicator(
                          // Added RefreshIndicator
                          onRefresh: _refreshHomeData,
                          child: ListView.builder(
                            itemCount: homeProvider.borrowers!.length,
                            itemBuilder: (context, index) {
                              final user = homeProvider.borrowers![index];
                              return Dismissible(
                                key: Key(user.userId.toString()),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                    vertical: 8.0,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 24),
                                  child: const Icon(
                                    Icons.delete,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                ),
                                confirmDismiss: (_) async {
                                  if (user.totalAmount == 0) {
                                    return await showDialog<bool>(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            title: const Text('Delete User'),
                                            content: Text(
                                              'Are you sure you want to remove ${user.name}?',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(ctx, false),
                                                child: const Text('Cancel'),
                                              ),
                                              ElevatedButton(
                                                onPressed: () =>
                                                    Navigator.pop(ctx, true),
                                                child: const Text('Delete'),
                                              ),
                                            ],
                                          ),
                                        ) ??
                                        false;
                                  }

                                  // User still has debts
                                  return await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          icon: const Icon(
                                            Icons.warning_amber_rounded,
                                            color: Colors.orange,
                                            size: 40,
                                          ),
                                          title: const Text('Unsettled Debts'),
                                          content: Text(
                                            '${user.name} still has an outstanding balance of '
                                            'ETB ${user.totalAmount.abs().toStringAsFixed(2)}.\n\n'
                                            'Deleting this user may make it difficult to track these debts later.\n\n'
                                            'Do you want to delete anyway?',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(ctx, false),
                                              child: const Text('Keep User'),
                                            ),
                                            ElevatedButton(
                                              onPressed: () =>
                                                  Navigator.pop(ctx, true),
                                              child: const Text(
                                                'Delete Anyway',
                                              ),
                                            ),
                                          ],
                                        ),
                                      ) ??
                                      false;
                                },
                                onDismissed: (_) async {
                                  try {
                                    await Provider.of<HomeProvider>(
                                      context,
                                      listen: false,
                                    ).apiService.deleteUser(user.userId);

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('${user.name} removed'),
                                      ),
                                    );
                                  } catch (e) {}
                                },
                                child: HomeUserCard(
                                  homeUser: user,
                                  isOwedByMe: true,
                                ),
                              );
                            },
                          ),
                        ),

                  // "You Owe" Tab (Creditors)
                  homeProvider.isLoadingCreditors
                      ? const Center(child: CircularProgressIndicator())
                      : homeProvider.creditorsError != null
                      ? Center(
                          child: Text('Error: ${homeProvider.creditorsError}'),
                        )
                      : homeProvider.creditors!.isEmpty
                      ? const Center(
                          child: Text('No one you currently owe money to.'),
                        )
                      : RefreshIndicator(
                          // Added RefreshIndicator
                          onRefresh: _refreshHomeData,
                          child: ListView.builder(
                            itemCount: homeProvider.creditors!.length,
                            itemBuilder: (context, index) {
                              final user = homeProvider.creditors![index];
                              return Dismissible(
                                key: Key(user.userId.toString()),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                    vertical: 8.0,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 24),
                                  child: const Icon(
                                    Icons.delete,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                ),
                                confirmDismiss: (_) async {
                                  if (user.totalAmount == 0) {
                                    return await showDialog<bool>(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            title: const Text('Delete User'),
                                            content: Text(
                                              'Are you sure you want to remove ${user.name}?',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(ctx, false),
                                                child: const Text('Cancel'),
                                              ),
                                              ElevatedButton(
                                                onPressed: () =>
                                                    Navigator.pop(ctx, true),
                                                child: const Text('Delete'),
                                              ),
                                            ],
                                          ),
                                        ) ??
                                        false;
                                  }

                                  // User still has debts
                                  return await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          icon: const Icon(
                                            Icons.warning_amber_rounded,
                                            color: Colors.orange,
                                            size: 40,
                                          ),
                                          title: const Text('Unsettled Debts'),
                                          content: Text(
                                            '${user.name} still has an outstanding balance of '
                                            'ETB ${user.totalAmount.abs().toStringAsFixed(2)}.\n\n'
                                            'Deleting this user may make it difficult to track these debts later.\n\n'
                                            'Do you want to delete anyway?',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(ctx, false),
                                              child: const Text('Keep User'),
                                            ),
                                            ElevatedButton(
                                              onPressed: () =>
                                                  Navigator.pop(ctx, true),
                                              child: const Text(
                                                'Delete Anyway',
                                              ),
                                            ),
                                          ],
                                        ),
                                      ) ??
                                      false;
                                },
                                onDismissed: (_) async {
                                  try {
                                    await Provider.of<HomeProvider>(
                                      context,
                                      listen: false,
                                    ).apiService.deleteUser(user.userId);

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('${user.name} removed'),
                                      ),
                                    );
                                  } catch (e) {}
                                },
                                child: HomeUserCard(
                                  homeUser: user,
                                  isOwedByMe: false,
                                ),
                              );
                            },
                          ),
                        ),
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: _summaryCard(
                                title: 'Receivable Impact',
                                value: receivableImpact,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _summaryCard(
                                title: 'Net Worth',
                                value: netWorth,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                      ),

                      Expanded(
                        child: ListView.builder(
                          itemCount: homeProvider.cashTransactions.length,
                          itemBuilder: (context, index) {
                            return CashTransactionCard(
                              transaction: homeProvider.cashTransactions[index],
                            );
                          },
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

      floatingActionButton: _tabController.index == 2
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (_showCashActions) ...[
                  FloatingActionButton.small(
                    heroTag: 'deposit',
                    onPressed: () {
                      _showTransactionDialog('deposit');
                    },
                    child: const Icon(Icons.arrow_downward),
                  ),

                  const SizedBox(height: 12),

                  FloatingActionButton.small(
                    heroTag: 'expense',
                    onPressed: () {
                      _showTransactionDialog('expense');
                    },
                    child: const Icon(Icons.arrow_upward),
                  ),

                  const SizedBox(height: 12),
                ],

                FloatingActionButton(
                  heroTag: 'main',
                  onPressed: () {
                    setState(() {
                      _showCashActions = !_showCashActions;
                    });
                  },
                  child: Icon(_showCashActions ? Icons.close : Icons.add),
                ),
              ],
            )
          : FloatingActionButton(
              onPressed: () async {
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AddUserScreen(),
                  ),
                );

                if (result == true) {
                  _refreshHomeData();
                }
              },
              child: const Icon(Icons.person_add),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
