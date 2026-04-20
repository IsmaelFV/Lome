import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';
import '../../../../core/utils/extensions/context_extensions.dart';

/// Pantalla de splash / carga inicial.
///
/// Flujo de comprobación de sesión:
/// 1. La app se abre y muestra el logo animado.
/// 2. Se comprueba si existe una sesión activa (access_token + refresh_token)
///    almacenados de forma segura por Supabase Flutter.
/// 3. Si la sesión es válida → se obtiene el perfil del usuario (con memberships)
///    y se redirige al dashboard según su rol.
/// 4. Si no hay sesión o es inválida → se redirige al login.
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  bool _animationComplete = false;
  bool _navigationDone = false;

  @override
  void initState() {
    super.initState();
    // Esperar a que la animación mínima termine antes de navegar
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) {
        setState(() => _animationComplete = true);
        _tryNavigate();
      }
    });
  }

  /// Intenta navegar al destino correcto.
  /// Solo navega si la animación terminó Y los datos de auth están listos.
  void _tryNavigate() {
    if (_navigationDone || !_animationComplete || !mounted) return;

    final authState = ref.read(authStateProvider);

    authState.when(
      data: (user) {
        _navigationDone = true;
        if (user != null) {
          if (user.isPlatformAdmin) {
            context.go(RoutePaths.admin);
          } else if (user.hasTenants) {
            ref.read(activeTenantIdProvider.notifier).state =
                user.defaultMembership!.tenantId;
            context.go(RoutePaths.tables);
          } else {
            // Usuario sin restaurante → marketplace para clientes
            context.go(RoutePaths.marketplace);
          }
        } else {
          context.go(RoutePaths.welcome);
        }
      },
      loading: () {
        // Los datos todavía cargan — esperar al siguiente cambio de estado
      },
      error: (_, __) {
        _navigationDone = true;
        context.go(RoutePaths.welcome);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Escuchar cambios del auth state para navegar en cuanto esté listo
    ref.listen(authStateProvider, (_, __) => _tryNavigate());

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ─── Logo animado ───
            Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'L',
                      style: TextStyle(
                        fontSize: 52,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -1,
                      ),
                    ),
                  ),
                )
                .animate()
                .fadeIn(duration: 600.ms, curve: Curves.easeOut)
                .scaleXY(
                  begin: 0.6,
                  end: 1,
                  duration: 700.ms,
                  curve: Curves.easeOutBack,
                ),

            const SizedBox(height: 24),

            // ─── Nombre ───
            Text(
              'LŌME',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.grey900,
                letterSpacing: 8,
              ),
            ).animate().fadeIn(delay: 300.ms, duration: 500.ms),

            const SizedBox(height: 8),

            // ─── Tagline ───
            Text(
              context.l10n.splashTagline,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppColors.grey500,
              ),
            ).animate().fadeIn(delay: 500.ms, duration: 500.ms),

            const SizedBox(height: 48),

            // ─── Indicador de carga ───
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation(AppColors.primary),
              ),
            ).animate().fadeIn(delay: 700.ms, duration: 400.ms),
          ],
        ),
      ),
    );
  }
}
