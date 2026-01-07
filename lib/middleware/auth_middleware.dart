import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';

class AuthMiddleware {
  static void checkAuth(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (!authProvider.isAuthenticated) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  static Widget guard({
    required Widget child,
    required BuildContext context,
  }) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        if (!authProvider.isAuthenticated) {
          // Redirect to login if not authenticated
          Future.microtask(() {
            Navigator.pushReplacementNamed(context, '/login');
          });
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        return child;
      },
    );
  }
}

// Widget wrapper untuk protected routes
class ProtectedRoute extends StatelessWidget {
  final Widget child;

  const ProtectedRoute({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        if (!authProvider.isAuthenticated) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, '/login');
          });
          
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        return child;
      },
    );
  }
}