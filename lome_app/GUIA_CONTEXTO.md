# Guia de Contexto - LOME

Esta guia resume el contexto operativo del proyecto para mantener consistencia entre equipos.

## Stack principal
- Flutter (Dart) + Riverpod + go_router
- Supabase como backend
- Estructura feature-first

## Modulo menu editor (estado actual)
- Canvas con multiseleccion local en `design_canvas.dart`
- Operaciones de grupo en `canvas_provider.dart`:
  - duplicar en bloque
  - mover en bloque
  - traer al frente / enviar atras en bloque
  - alinear (izq, centroX, der, arriba, centroY, abajo)
  - distribuir (horizontal, vertical)
- Barra flotante contextual con acciones rapidas
- Duplicado por arrastre desde la barra flotante
- Guias visuales de snap y de distancia entre bloques
- Bloqueo de proporcion para tipos visuales (imagen, circulo, carrusel)
- Seleccion por marco (long press + arrastre en lienzo vacio)
- HUD de zoom con porcentaje y ajuste al encuadre

## Archivos clave del editor
- `lib/features/restaurant/menu/presentation/widgets/design_canvas.dart`
- `lib/features/restaurant/menu/presentation/providers/canvas_provider.dart`
- `lib/features/restaurant/menu/presentation/widgets/property_panel.dart`
- `lib/features/restaurant/menu/presentation/widgets/editor_toolbar.dart`
- `lib/features/restaurant/menu/presentation/widgets/canvas_element_widget.dart`

## Entorno
- Variables en `.env` (local, no versionado)
- No subir claves sensibles a git

## Regla para sincronizacion entre equipos
- Todo contexto que deba viajar entre ordenadores debe guardarse en archivos versionados (como esta guia o README) y hacer commit/push.
- Las notas de memoria del asistente no sustituyen una guia versionada en el repo.
