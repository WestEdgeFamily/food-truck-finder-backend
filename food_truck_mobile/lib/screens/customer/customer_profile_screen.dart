import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/favorites_provider.dart';
import '../auth/role_selection_screen.dart';
import 'favorites_screen.dart';
import 'settings_screen.dart';

class CustomerProfileScreen extends StatelessWidget {
  const CustomerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Profile header
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          child: const Icon(
                            Icons.person,
                            size: 30,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                authProvider.user?.name ?? 'Customer',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                authProvider.user?.email ?? 'customer@example.com',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Menu items
                Consumer<FavoritesProvider>(
                  builder: (context, favoritesProvider, child) {
                    return _buildMenuCard(
                  context,
                  icon: Icons.favorite,
                  title: 'Favorite Food Trucks',
                      subtitle: '${favoritesProvider.favorites.length} saved trucks',
                  onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const FavoritesScreen(),
                          ),
                        );
                      },
                    );
                  },
                ),
                
                _buildMenuCard(
                  context,
                  icon: Icons.history,
                  title: 'Order History',
                  subtitle: 'Your past orders',
                  onTap: () {
                    // TODO: Navigate to order history
                  },
                ),
                
                _buildMenuCard(
                  context,
                  icon: Icons.notifications,
                  title: 'Notifications',
                  subtitle: 'Manage your notifications',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    );
                  },
                ),
                
                _buildMenuCard(
                  context,
                  icon: Icons.settings,
                  title: 'Settings',
                  subtitle: 'App preferences',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    );
                  },
                ),
                
                const Spacer(),
                
                // Logout button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _logout(context),
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();
    
    if (!context.mounted) return;
    
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
      (route) => false,
    );
  }
} 