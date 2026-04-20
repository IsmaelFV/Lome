# LŌME — Documentación de Arquitectura del Sistema

> **Versión**: 1.0.0 · **Última actualización**: Junio 2025  
> **Plataforma**: SaaS Multi-Tenant para Gestión de Restaurantes y Marketplace

---

## Índice

1. [Visión General](#1-visión-general)
2. [Arquitectura Backend](#2-arquitectura-backend)
3. [Arquitectura Frontend](#3-arquitectura-frontend)
4. [Infraestructura Cloud](#4-infraestructura-cloud)
5. [Sistema Multi-Tenant](#5-sistema-multi-tenant)
6. [Seguridad y Control de Acceso](#6-seguridad-y-control-de-acceso)
7. [Sistema de Auditoría](#7-sistema-de-auditoría)
8. [Sistema de Monitorización](#8-sistema-de-monitorización)
9. [Escalabilidad](#9-escalabilidad)
10. [Esquema de Base de Datos](#10-esquema-de-base-de-datos)
11. [API y RPCs](#11-api-y-rpcs)
12. [Módulos Funcionales](#12-módulos-funcionales)
13. [Dependencias y Stack Tecnológico](#13-dependencias-y-stack-tecnológico)

---

## 1. Visión General

**LŌME** es una plataforma SaaS integral para la gestión de restaurantes que unifica tres aplicaciones en una sola:

| Aplicación | Usuarios | Función |
|---|---|---|
| **App Restaurante** | Dueños, managers, chefs, camareros, cajeros | Gestión operativa: mesas, pedidos, cocina, menú, inventario, empleados, analíticas |
| **Marketplace** | Clientes finales | Descubrimiento, pedidos delivery/takeaway, reseñas, favoritos, seguimiento de pedidos |
| **Panel Admin** | Super administradores | Gestión global de la plataforma: restaurantes, analíticas, incidencias, moderación, suscripciones, auditoría, monitorización |

### Diagrama de Alto Nivel

```
┌─────────────────────────────────────────────────────────┐
│                    LŌME Flutter App                      │
│  ┌──────────┐  ┌──────────────┐  ┌───────────────────┐  │
│  │Restaurant │  │  Marketplace │  │   Admin Panel     │  │
│  │   App     │  │     App      │  │                   │  │
│  └────┬──────┘  └──────┬───────┘  └────────┬──────────┘  │
│       │                │                    │             │
│       └────────────┬───┴────────────────────┘             │
│              Riverpod + GoRouter                          │
└──────────────────────┬──────────────────────────────────┘
                       │ HTTPS / WebSocket
┌──────────────────────┴──────────────────────────────────┐
│                     Supabase                             │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌────────────┐  │
│  │PostgreSQL│ │   Auth   │ │ Realtime │ │   Edge     │  │
│  │  + RLS   │ │  (PKCE)  │ │ (WSS)   │ │ Functions  │  │
│  └──────────┘ └──────────┘ └──────────┘ └────────────┘  │
│  ┌──────────┐                                            │
│  │ Storage  │                            Cloudinary CDN  │
│  └──────────┘                                            │
└──────────────────────────────────────────────────────────┘
```

---

## 2. Arquitectura Backend

### 2.1. Supabase como BaaS

El backend se construye íntegramente sobre **Supabase**, que proporciona:

| Servicio | Uso en LŌME |
|---|---|
| **PostgreSQL** | Base de datos relacional con 21 tablas, 10 enums, 50+ políticas RLS |
| **Auth** | Autenticación email/contraseña con flujo PKCE, verificación de email, recuperación de contraseña |
| **Realtime** | Suscripciones en tiempo real a `orders`, `order_items`, `restaurant_tables`, `table_sessions`, `notifications`, `error_logs` |
| **Edge Functions** | 2 funciones serverless en Deno/TypeScript: `delete-account`, `log-event` |
| **Storage** | Almacenamiento de archivos (imágenes vía Cloudinary) |
| **RPCs** | 13+ funciones PostgreSQL expuestas como API REST |

### 2.2. Migraciones SQL

El esquema evoluciona mediante 12 migraciones versionadas:

| # | Archivo | Contenido |
|---|---|---|
| 1 | `00001_initial_schema.sql` | Esquema base completo: 18 tablas, 10 enums, 45+ RLS, triggers de negocio |
| 2 | `00002_account_deletion.sql` | Soporte para eliminación de cuenta |
| 3 | `00003_roles_logs_hours_status.sql` | Roles personalizados, logs de actividad, horarios, estados |
| 4 | `00004_table_shape_status.sql` | Geometría y estados de mesas |
| 5 | `00005_reservations_order_triggers.sql` | Sistema de reservaciones y triggers de pedidos |
| 6 | `00006_assignments_history_stats.sql` | Asignaciones, historial, estadísticas |
| 7 | `00007_order_ready_notifications.sql` | Notificaciones de pedido listo |
| 8 | `00008_payments_table.sql` | Tabla de pagos |
| 9 | `00009_promotions_recommendations.sql` | Promociones y sistema de recomendaciones |
| 10 | `00010_admin_panel_rpcs.sql` | RPCs del panel de administración |
| 11 | `00011_subscriptions_invoices.sql` | Suscripciones y facturación |
| 12 | `00012_audit_monitoring_system.sql` | Sistema de auditoría y monitorización técnica |

### 2.3. Edge Functions

| Función | Runtime | Propósito |
|---|---|---|
| `delete-account` | Deno + TypeScript | Eliminación completa de cuenta de usuario usando service_role key |
| `log-event` | Deno + TypeScript | Ingesta centralizada de eventos (errores, uso de API, auditoría manual). Soporta eventos individuales y batch (hasta 100 por lote) |

### 2.4. Triggers de Negocio

| Trigger | Tabla | Función |
|---|---|---|
| `on_auth_user_created` | `auth.users` | Auto-crea perfil en `profiles` al registrarse |
| `on_review_change` | `reviews` | Recalcula rating promedio del restaurante |
| `on_inventory_movement` | `inventory_movements` | Actualiza stock en `inventory_items` |
| `on_order_completed` | `orders` | Incrementa `total_orders` en `tenants` |
| `on_session_change` | `table_sessions` | Actualiza estado de mesa cuando se abre/cierra sesión |

### 2.5. Triggers de Auditoría (14)

La función genérica `audit_trigger_fn()` registra automáticamente en `audit_logs` toda operación INSERT/UPDATE/DELETE sobre las tablas críticas:

`orders` · `order_items` · `payments` · `tenants` · `tenant_memberships` · `menu_items` · `inventory_movements` · `subscriptions` · `invoices` · `incidents` · `reviews` · `profiles` · `promotions`

---

## 3. Arquitectura Frontend

### 3.1. Patrones Arquitectónicos

```
┌─────────────────────────────────────────────────────┐
│                 Feature-First + Clean                 │
│                                                       │
│   features/                                           │
│   ├── admin/           ← Panel de administración      │
│   │   ├── domain/      (entidades compartidas)        │
│   │   ├── dashboard/   ├── presentation/              │
│   │   ├── restaurants/     ├── pages/                 │
│   │   ├── analytics/       ├── providers/             │
│   │   ├── incidents/       └── widgets/               │
│   │   ├── moderation/                                 │
│   │   ├── subscriptions/                              │
│   │   ├── audit/                                      │
│   │   └── monitoring/                                 │
│   ├── auth/            ← Autenticación                │
│   │   ├── data/        (repositorios, datasources)    │
│   │   ├── domain/      (entidades, repos abstractos)  │
│   │   └── presentation/ (páginas, providers)          │
│   ├── marketplace/     ← App cliente                  │
│   ├── profile/         ← Perfil de usuario            │
│   └── restaurant/      ← App restaurante              │
│                                                       │
│   core/                                               │
│   ├── auth/            (RBAC, permisos, guards)       │
│   ├── config/          (env, variables de entorno)    │
│   ├── constants/       (constantes globales)          │
│   ├── errors/          (excepciones, failures)        │
│   ├── network/         (conectividad)                 │
│   ├── router/          (rutas, GoRouter)              │
│   ├── services/        (audit, monitoring, storage)   │
│   ├── theme/           (colores, tipografía)          │
│   ├── utils/           (utilidades)                   │
│   └── widgets/         (componentes reutilizables)    │
│                                                       │
│   shared/                                             │
│   ├── providers/       (supabase, session)            │
│   └── services/        (cloudinary, session_manager)  │
└─────────────────────────────────────────────────────┘
```

### 3.2. State Management — Riverpod

| Tipo de Provider | Uso |
|---|---|
| `Provider` | Servicios singleton (Supabase client, storage, monitoring) |
| `StateProvider` | Estado simple de filtros UI (status, severity, periodo) |
| `FutureProvider` | Queries async a Supabase (listas, stats, RPCs) |
| `FutureProvider.family` | Queries parametrizadas (detalles por ID) |
| `StreamProvider` | Datos en tiempo real (sesión, conectividad) |
| `StateNotifierProvider` | Estado complejo mutable (carrito, auth) |

### 3.3. Routing — GoRouter

El sistema cuenta con **3 shells de navegación** con `StatefulShellRoute.indexedStack` y **45+ rutas**:

| Shell | Tabs | Rutas |
|---|---|---|
| **Restaurant** | Mesas, Pedidos, Cocina, Menú, Inventario | + 15 rutas secundarias (dashboard, empleados, settings, analytics...) |
| **Marketplace** | Inicio, Búsqueda, Carrito, Perfil | + 5 rutas full-screen (detalle restaurante, checkout, tracking...) |
| **Admin** | Dashboard, Restaurantes, Analíticas, Incidencias, Moderación, Suscripciones, Auditoría, Monitor | + 2 rutas detalle (restaurante, incidencia) |

### 3.4. Sistema de Diseño

| Token | Valor |
|---|---|
| **Primary** | `#15803D` (verde) |
| **Primary Light** | `#22C55E` |
| **Success** | `#22C55E` |
| **Error** | `#EF4444` |
| **Warning** | `#FBBF24` |
| **Info** | `#3B82F6` |
| **Border Radius** | Sm: 8, Md: 12, Lg: 16 |
| **Spacing** | Xs: 4, Sm: 8, Md: 16, Lg: 24, Xl: 32 |

**Componentes reutilizables**: `LomeCard`, `LomeStatCard`, `LomeButton` (5 variantes), `LomeLoading`, `LomeSearchField`, `LomeEmptyState`

### 3.5. Manejo de Errores

Arquitectura de errores tipados con separación entre excepciones e informes:

| Capa | Clase | Propósito |
|---|---|---|
| Data | `ServerException`, `CacheException`, `AuthException`, `NetworkException`, `ValidationException`, `StorageException`, `PermissionException` | Excepciones que se lanzan internamente |
| Domain | `Failure` (sealed): `ServerFailure`, `CacheFailure`, `AuthFailure`, `NetworkFailure`, `ValidationFailure`, `PermissionFailure`, `UnexpectedFailure` | ADTs para Either (dartz) |

---

## 4. Infraestructura Cloud

### 4.1. Servicios Cloud

```
┌──────────────────────────────────────────────────────┐
│                   Supabase Cloud                      │
│  ┌──────────────┐  ┌─────────┐  ┌────────────────┐   │
│  │  PostgreSQL   │  │  Auth   │  │   Realtime     │   │
│  │  (Dedicated   │  │  (GoTrue│  │  (WebSocket    │   │
│  │   Instance)   │  │   PKCE) │  │   Pub/Sub)     │   │
│  └──────────────┘  └─────────┘  └────────────────┘   │
│  ┌──────────────┐  ┌─────────────────────────────┐   │
│  │Edge Functions │  │       Storage (S3)          │   │
│  │  (Deno V8)   │  │                             │   │
│  └──────────────┘  └─────────────────────────────┘   │
└──────────────────────────────────────────────────────┘
         │
         ├── Cloudinary CDN (imágenes optimizadas)
         │
         ├── Flutter App (iOS / Android / Web)
         │
         └── GitHub (repositorio + CI/CD)
```

### 4.2. Distribución por Plataforma

| Plataforma | Configuración |
|---|---|
| **Android** | namespace `com.lome.lome_app`, Java 17, SDK dinámico (Flutter) |
| **iOS** | Bundle ID `com.lome.lomeApp`, deployment target iOS 13.0, URL Scheme `io.supabase.lome` |
| **Web** | SPA con index.html y manifest.json |
| **Desktop** | Linux, macOS, Windows (configurados pero secundarios) |

---

## 5. Sistema Multi-Tenant

### 5.1. Modelo de Tenancy

LŌME implementa **multi-tenancy a nivel de filas** (Row-Level Security) donde cada restaurante es un **tenant**:

```
┌─────────────┐     ┌──────────────────┐     ┌──────────────┐
│   profiles   │────▶│ tenant_memberships│◀────│    tenants   │
│  (auth.users)│     │  (rol por tenant) │     │(restaurantes)│
└─────────────┘     └──────────────────┘     └──────────────┘
                            │
         ┌──────────────────┼──────────────────┐
         ▼                  ▼                  ▼
    restaurant_tables   menu_items         orders
    table_sessions      inventory_items    payments
    reservations        ...                ...
```

### 5.2. Aislamiento de Datos

| Mecanismo | Implementación |
|---|---|
| **RLS Policies** | Cada tabla tiene políticas que filtran por `tenant_id` según el rol del usuario actual |
| **JWT Claims** | El `tenant_id` activo se extrae de `get_current_tenant_id()` o del contexto de la membresía |
| **Helper Functions** | `is_super_admin()`, `has_role_in_tenant(uuid, roles[])` para verificación de permisos en SQL |
| **Client-Side** | `StorageService.activeTenantId` almacena el tenant seleccionado; `sessionManagerProvider` gestiona la sesión |

### 5.3. Roles por Tenant

| Rol | Scope | Permisos |
|---|---|---|
| `super_admin` | Global (plataforma) | Acceso total, gestión de todos los tenants |
| `owner` | Tenant | Configuración completa del restaurante |
| `manager` | Tenant | Gestión operativa, empleados, menú, inventario |
| `chef` | Tenant | Cocina, preparación de pedidos |
| `waiter` | Tenant | Mesas, pedidos, servicio |
| `cashier` | Tenant | Pagos, cierre de caja |
| `customer` | Global | Marketplace, pedidos, reseñas |

---

## 6. Seguridad y Control de Acceso

### 6.1. Autenticación

| Aspecto | Implementación |
|---|---|
| **Protocolo** | OAuth 2.0 PKCE (Proof Key for Code Exchange) |
| **Provider** | Supabase GoTrue (email/password) |
| **Verificación** | Email verification obligatorio |
| **Recuperación** | Flujo de reset password con enlace mágico |
| **Sesión** | JWT auto-refresh, `SessionManager` con validación periódica |
| **Almacenamiento** | Tokens sensibles en `FlutterSecureStorage` |
| **Eliminación** | Edge Function `delete-account` con service_role key |

### 6.2. Autorización (RBAC)

El sistema RBAC en Flutter se implementa en `core/auth/`:

| Componente | Función |
|---|---|
| `AppPermission` (enum) | 17 permisos granulares (manage_tables, manage_orders, manage_menu, view_analytics, manage_employees, etc.) |
| `rolePermissions` | Mapa estático rol → permisos autorizados |
| `PermissionGuard` | Widget que oculta contenido si no tiene permiso |
| `ManagerGuard` | Widget wrapper para contenido de managers+ |
| `PlatformAdminGuard` | Widget wrapper para super_admin |
| `currentRoleProvider` | Provider del rol actual del usuario en el tenant activo |
| `hasPermissionProvider` | Provider paramétrico para verificar un permiso |

### 6.3. Row-Level Security (RLS)

Todas las 21 tablas tienen RLS habilitado con **~50 políticas** que garantizan:

- **Aislamiento de tenant**: Empleados solo ven datos de sus restaurantes
- **Aislamiento de usuario**: Clientes solo ven sus propios pedidos, direcciones, favoritos
- **Escalamiento de privilegios controlado**: Managers pueden lo que waiters + gestión; owners todo
- **Super admin bypass**: Acceso global para administración de plataforma
- **Funciones SECURITY DEFINER**: RPCs que ejecutan con privilegios elevados cuando es necesario, con validación interna

### 6.4. Seguridad en la Comunicación

| Capa | Protección |
|---|---|
| **Transporte** | HTTPS/TLS obligatorio (Supabase Cloud) |
| **WebSocket** | WSS para Realtime con JWT |
| **Edge Functions** | Verificación de JWT en cada invocación |
| **Imágenes** | Cloudinary CDN con URLs firmadas y optimización automática |

---

## 7. Sistema de Auditoría

### 7.1. Arquitectura

```
┌──────────────────────────────────────────────────────────┐
│                   Sistema de Auditoría                     │
│                                                            │
│  ┌─────────────────────┐  ┌─────────────────────────────┐ │
│  │  Auditoría Automática│  │   Auditoría Manual          │ │
│  │  (DB Triggers)       │  │   (Flutter → RPC/Edge Fn)   │ │
│  │                      │  │                              │ │
│  │  14 triggers on:     │  │  AuditService.log()         │ │
│  │  orders, payments,   │  │  → logLogin, logLogout      │ │
│  │  tenants, menu_items │  │  → logAdminAccess           │ │
│  │  profiles, reviews   │  │  → logSettingsChange        │ │
│  │  promotions...       │  │  → logModeration            │ │
│  └──────────┬───────────┘  └──────────┬──────────────────┘ │
│             │                          │                    │
│             ▼                          ▼                    │
│  ┌──────────────────────────────────────────────────────┐  │
│  │                    audit_logs                         │  │
│  │  id, tenant_id, user_id, action, entity_type,        │  │
│  │  entity_id, old_data(JSONB), new_data(JSONB),        │  │
│  │  ip_address, user_agent, metadata(JSONB), created_at │  │
│  └──────────────────────────────────────────────────────┘  │
│             │                                               │
│             ▼                                               │
│  ┌──────────────────────────────────────────────────────┐  │
│  │            Admin Panel — Auditoría                    │  │
│  │  get_audit_summary() → KPIs + gráficos               │  │
│  │  get_audit_logs()    → Lista paginada con filtros     │  │
│  └──────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────┘
```

### 7.2. Datos Capturados

| Campo | Descripción |
|---|---|
| `action` | INSERT, UPDATE, DELETE, login, logout, admin_access, settings_change, moderation, data_export |
| `entity_type` | Tabla afectada (orders, profiles, menu_items, etc.) |
| `old_data` / `new_data` | Snapshot JSONB completo del registro antes/después del cambio |
| `metadata` | Contexto adicional (sección accedida, motivo de moderación, etc.) |

### 7.3. Consultas de Auditoría

| RPC | Descripción | Acceso |
|---|---|---|
| `get_audit_summary(p_hours)` | Total eventos, desglose por acción/entidad, top 10 usuarios | super_admin |
| `get_audit_logs(filtros)` | Lista paginada con filtros por entidad, acción, usuario, tenant, rango de fechas | super_admin |
| `insert_audit_log(...)` | Inserción manual desde clientes | authenticated |

---

## 8. Sistema de Monitorización

### 8.1. Arquitectura

```
┌───────────────────────────────────────────────────────────┐
│              Sistema de Monitorización Técnica              │
│                                                             │
│  ┌────────────────────────────────────────────────────────┐ │
│  │               Flutter Client-Side                       │ │
│  │                                                         │ │
│  │  MonitoringService                                      │ │
│  │  ├── captureFlutterError()  ← FlutterError.onError     │ │
│  │  ├── capturePlatformError() ← PlatformDispatcher       │ │
│  │  ├── reportError()          ← Manual                    │ │
│  │  ├── trackApiCall()         ← Wraps async + Stopwatch   │ │
│  │  └── logApiCall()           ← Manual                    │ │
│  │                                                         │ │
│  │  Buffer: Queue (max 50, flush each 30s)                 │ │
│  └─────────────────────┬──────────────────────────────────┘ │
│                        │ POST /functions/v1/log-event       │
│                        │ { type: "batch", events: [...] }   │
│  ┌─────────────────────▼──────────────────────────────────┐ │
│  │              Edge Function: log-event                    │ │
│  │  ├── Verifica JWT ← anon key                            │ │
│  │  ├── Procesa batch (max 100)                            │ │
│  │  └── Inserta con service_role ─┐                        │ │
│  └────────────────────────────────┼────────────────────────┘ │
│                                   │                          │
│  ┌────────────────────────────────▼────────────────────────┐ │
│  │              PostgreSQL Tables                           │ │
│  │                                                          │ │
│  │  error_logs         → severity, source, message,         │ │
│  │                       stack_trace, device_info, context   │ │
│  │                                                          │ │
│  │  api_usage_logs     → endpoint, method, status_code,     │ │
│  │                       response_time_ms, sizes             │ │
│  │                                                          │ │
│  │  performance_metrics → metric_name, value, unit,          │ │
│  │                        dimensions, period                 │ │
│  └─────────────────────────────────────────────────────────┘ │
│                        │                                     │
│  ┌─────────────────────▼───────────────────────────────────┐ │
│  │          Admin Panel — Monitorización                    │ │
│  │                                                          │ │
│  │  get_monitoring_dashboard():                             │ │
│  │  ├── Errores: total, critical, error, warning, by_source │ │
│  │  ├── API: requests, avg/p95/p99 ms, error_rate%          │ │
│  │  ├── top_endpoints, slow_endpoints (>1s)                 │ │
│  │  └── recent_critical_errors (últimos 20)                 │ │
│  │                                                          │ │
│  │  get_error_logs(): Lista paginada con filtros             │ │
│  │  purge_old_logs(): Retención configurable (default 90d)  │ │
│  └──────────────────────────────────────────────────────────┘ │
└───────────────────────────────────────────────────────────┘
```

### 8.2. Severidades de Error

| Nivel | Uso |
|---|---|
| `critical` | Errores fatales, crashes de plataforma |
| `error` | Errores de operación (fallos de red, excepciones no manejadas) |
| `warning` | Condiciones degradadas (timeouts, reintentos) |
| `info` | Eventos informativos |
| `debug` | Solo en desarrollo |

### 8.3. Fuentes de Error

| Fuente | Origen |
|---|---|
| `flutter` | FlutterError.onError, PlatformDispatcher.onError |
| `edge_function` | Errores en funciones serverless |
| `database` | Errores de PostgreSQL |
| `rls` | Violaciones de Row-Level Security |

### 8.4. Realtime

`error_logs` está publicada en `supabase_realtime` para notificación instantánea al admin cuando se registra un error crítico.

### 8.5. Retención

La RPC `purge_old_logs(p_retention_days)` permite limpieza periódica:

| Tabla | Retención por defecto |
|---|---|
| `audit_logs` | 90 días |
| `error_logs` | 90 días |
| `api_usage_logs` | 90 días |
| `performance_metrics` | 90 días |

---

## 9. Escalabilidad

### 9.1. Estrategia de Escalado

| Capa | Estrategia |
|---|---|
| **Base de datos** | Índices en columnas de filtro frecuente (tenant_id, created_at, status); particionamiento implícito vía RLS; purga de logs antiguos |
| **Edge Functions** | Stateless, autoescalado en Deno V8 (Supabase Cloud) |
| **Realtime** | Pub/Sub selectivo solo en tablas críticas (orders, tables, notifications, errors) |
| **Frontend** | Buffered monitoring (batch de 50 eventos, flush cada 30s) para minimizar requests |
| **CDN** | Cloudinary para todas las imágenes, con transformaciones on-the-fly y caché global |
| **API** | Paginación en todas las queries de listado (limit/offset) |

### 9.2. Patrones de Optimización

| Patrón | Implementación |
|---|---|
| **Lazy loading** | Riverpod FutureProvider se ejecuta solo cuando se consume |
| **Invalidación selectiva** | `ref.invalidate()` solo en providers afectados tras mutaciones |
| **Offline detection** | `NetworkInfo` con `connectivity_plus` para degradación graceful |
| **Image optimization** | Cloudinary: webp, quality auto, responsive widths |
| **Batch processing** | Edge Function `log-event` procesa hasta 100 eventos por request |

### 9.3. Límites y Consideraciones

| Aspecto | Límite actual | Mitigación |
|---|---|---|
| Monitoring buffer | 50 eventos / 30s flush | Re-enqueue on failure (hasta 2x buffer) |
| Log-event batch | 100 eventos por request | Múltiples batches si excede |
| Audit triggers | 14 tablas | Impacto mínimo por ser AFTER triggers |
| Retention | 90 días default | Configurable vía RPC |

---

## 10. Esquema de Base de Datos

### 10.1. Tablas Principales (21)

```
┌─────────────────────────────────────────────────────────────┐
│                       USER LAYER                             │
│  profiles ←──── auth.users (auto-sync via trigger)          │
│  customer_addresses                                          │
│  notifications                                               │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                      TENANT LAYER                            │
│  tenants (restaurantes)                                      │
│  tenant_memberships (usuario ←→ restaurant + rol)            │
│  subscriptions                                               │
│  invoices                                                    │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                    RESTAURANT OPS                             │
│  restaurant_tables ──── table_sessions                       │
│  menu_categories ──── menu_items ──── menu_item_options      │
│  inventory_items ──── inventory_movements                    │
│  orders ──── order_items                                     │
│  payments                                                    │
│  reservations                                                │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                    MARKETPLACE                               │
│  reviews                                                     │
│  favorites                                                   │
│  promotions                                                  │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                 PLATFORM OPERATIONS                           │
│  incidents                                                   │
│  audit_logs                                                  │
│  error_logs                                                  │
│  api_usage_logs                                              │
│  performance_metrics                                         │
└─────────────────────────────────────────────────────────────┘
```

### 10.2. Enums PostgreSQL (10)

| Enum | Valores |
|---|---|
| `user_role` | super_admin, owner, manager, chef, waiter, cashier, customer |
| `tenant_status` | active, pending, suspended, cancelled |
| `table_status` | available, occupied, reserved, maintenance |
| `order_type` | dine_in, takeaway, delivery |
| `order_status` | pending, confirmed, preparing, ready, delivering, delivered, completed, cancelled |
| `payment_status` | pending, paid, refunded, failed |
| `order_item_status` | pending, preparing, ready, served, cancelled |
| `inventory_movement_type` | purchase, sale, adjustment, waste, transfer |
| `incident_priority` | critical, high, medium, low |
| `incident_status` | open, in_progress, resolved, closed |

---

## 11. API y RPCs

### 11.1. Funciones RPC Expuestas

| RPC | Parámetros | Retorno | Acceso |
|---|---|---|---|
| `nearby_restaurants` | lat, lon, radius_km | Restaurantes cercanos | public |
| `search_restaurants` | query | Búsqueda full-text | public |
| `get_restaurant_stats` | tenant_id | Stats del restaurante | owner/manager |
| `get_admin_stats` | — | Stats globales plataforma | super_admin |
| `insert_audit_log` | action, entity_type, ... | void | authenticated |
| `get_audit_logs` | filtros + paginación | Lista de audit_logs | super_admin |
| `get_audit_summary` | p_hours | Resumen JSONB | super_admin |
| `log_error` | severity, source, message, ... | void | authenticated |
| `log_api_usage` | endpoint, method, status, ... | void | authenticated |
| `get_monitoring_dashboard` | p_hours | Dashboard JSONB | super_admin |
| `get_error_logs` | filtros + paginación | Lista de error_logs | super_admin |
| `purge_old_logs` | p_retention_days | Counts eliminados | super_admin |
| `get_admin_subscription_stats` | — | Stats suscripciones | super_admin |

### 11.2. Tablas Realtime

| Tabla | Eventos | Consumidor |
|---|---|---|
| `orders` | INSERT, UPDATE | Kitchen Display, Order Pages |
| `order_items` | INSERT, UPDATE | Kitchen Display |
| `restaurant_tables` | UPDATE | Tables Page |
| `table_sessions` | INSERT, UPDATE | Tables Page |
| `notifications` | INSERT | Notification System |
| `error_logs` | INSERT | Admin Monitoring (alertas críticas) |

---

## 12. Módulos Funcionales

### 12.1. App Restaurante (15 sub-features)

| Módulo | Funcionalidad |
|---|---|
| **Dashboard** | KPIs del día: ingresos, pedidos, mesas activas, reservas |
| **Tables** | Gestión visual de mesas, editor de layout, sesiones, estadísticas |
| **Orders** | Lista de pedidos activos, crear pedidos, historial |
| **Kitchen** | Display de cocina en tiempo real, cambio de estados |
| **Menu** | CRUD de categorías, ítems con fotos, opciones/modificadores |
| **Inventory** | Stock actual, movimientos (compra, venta, ajuste, merma) |
| **Employees** | Lista de empleados, invitar por email, gestión de roles |
| **Roles** | Roles personalizados con permisos granulares |
| **Analytics** | Métricas de rendimiento del restaurante |
| **Reservations** | Sistema de reservaciones |
| **Settings** | Configuración del restaurante, horarios |
| **Activity Logs** | Registro de actividad del restaurante |
| **Hours** | Horarios de apertura configurables |
| **Notifications** | Sistema de notificaciones push/in-app |
| **Presentation** | Shell con bottom navigation (5 tabs) |

### 12.2. Marketplace (14 sub-features)

| Módulo | Funcionalidad |
|---|---|
| **Home** | Feed de restaurantes cercanos, promociones, recomendaciones |
| **Search** | Búsqueda full-text con filtros (cocina, rating, distancia) |
| **Menu** | Carta del restaurante con categorías y opciones |
| **Cart** | Carrito de compra con modificadores |
| **Checkout** | Proceso de pago con dirección de entrega |
| **Order Tracking** | Seguimiento en tiempo real del pedido |
| **Profile** | Perfil del cliente, direcciones guardadas |
| **Orders** | Historial de pedidos del cliente |
| **Favorites** | Restaurantes favoritos |
| **Reviews** | Sistema de reseñas y valoraciones |
| **Promotions** | Códigos de descuento y ofertas |
| **Recommendations** | Motor de recomendaciones personalizadas |
| **Domain** | Entidades compartidas del marketplace |
| **Presentation** | Shell con bottom navigation (4 tabs) |

### 12.3. Panel Admin (10 sub-features)

| Módulo | Funcionalidad |
|---|---|
| **Dashboard** | KPIs globales: restaurantes, usuarios, ingresos, incidencias |
| **Restaurants** | Lista + detalle de todos los restaurantes, activar/suspender |
| **Analytics** | Métricas globales, top restaurantes por ingresos |
| **Incidents** | Gestión de incidencias (CRUD, estados, prioridades, resolución) |
| **Moderation** | Reseñas flaggeadas para moderación |
| **Subscriptions** | Gestión de suscripciones y facturación |
| **Audit** | Trail de auditoría: resumen + log detallado con filtros |
| **Monitoring** | Dashboard técnico: errores, tiempos de respuesta, API usage |
| **Domain** | Entidades compartidas del admin |
| **Presentation** | Shell con bottom navigation (8 tabs) |

---

## 13. Dependencias y Stack Tecnológico

### 13.1. Stack Principal

| Capa | Tecnología | Versión |
|---|---|---|
| **Framework** | Flutter | SDK ^3.11.1 |
| **Lenguaje** | Dart | ^3.11.1 |
| **Backend** | Supabase (PostgreSQL 15+) | supabase_flutter ^2.8.4 |
| **State Management** | Riverpod | flutter_riverpod ^2.6.1 |
| **Routing** | GoRouter | ^14.8.1 |
| **Serverless** | Deno (Edge Functions) | @supabase/supabase-js@2 |
| **CDN** | Cloudinary | HTTP API |

### 13.2. Dependencias por Categoría

| Categoría | Paquetes |
|---|---|
| **State/Serialization** | flutter_riverpod, riverpod_annotation, freezed_annotation, json_annotation, equatable, dartz |
| **UI/Animaciones** | flutter_animate, rive, lottie, flutter_svg, cached_network_image, shimmer, google_fonts, phosphor_flutter |
| **Utilities** | intl, uuid, collection, connectivity_plus, url_launcher, logger, http |
| **Local Storage** | shared_preferences, flutter_secure_storage |
| **Media** | image_picker |
| **Printing** | pdf, printing |
| **Code Generation** | build_runner, freezed, json_serializable, riverpod_generator |
| **Linting** | flutter_lints, custom_lint, riverpod_lint |

### 13.3. Estructura de Archivos (Resumen)

```
lome_app/
├── lib/
│   ├── main.dart                    ← Entry point
│   ├── bootstrap.dart               ← Inicialización + error handling global
│   ├── app.dart                     ← MaterialApp + ProviderScope
│   ├── core/                        ← Infraestructura compartida
│   │   ├── auth/                    (RBAC: 17 permisos, guards, providers)
│   │   ├── config/                  (Env: Supabase URL, keys, Cloudinary)
│   │   ├── errors/                  (7 excepciones, 7 failures sealed)
│   │   ├── network/                 (NetworkInfo: connectivity)
│   │   ├── router/                  (GoRouter: 3 shells, 45+ rutas)
│   │   ├── services/               (AuditService, MonitoringService, 
│   │   │                            CloudinaryService, StorageService)
│   │   ├── theme/                   (AppColors, AppTheme)
│   │   ├── utils/                   (Utilidades varias)
│   │   └── widgets/                 (LomeCard, LomeButton, LomeLoading...)
│   ├── features/
│   │   ├── admin/                   (10 sub-features)
│   │   ├── auth/                    (Clean Architecture: data/domain/pres)
│   │   ├── marketplace/             (14 sub-features)
│   │   ├── profile/                 (Edición de perfil)
│   │   └── restaurant/              (15 sub-features)
│   └── shared/
│       ├── providers/               (supabase_provider, session_provider)
│       └── services/                (cloudinary_service, session_manager)
├── supabase/
│   ├── migrations/                  (12 migraciones SQL)
│   └── functions/                   (2 Edge Functions: TypeScript)
├── assets/
│   ├── animations/                  (Lottie/Rive)
│   ├── icons/                       (SVG icons)
│   └── images/                      (Imágenes estáticas)
├── android/                         (Config nativa Android)
├── ios/                             (Config nativa iOS)
├── web/                             (SPA config)
├── linux/ macos/ windows/           (Desktop configs)
└── pubspec.yaml                     (42 dependencias)
```

---

> **LŌME** · Plataforma SaaS Multi-Tenant para Restaurantes  
> Arquitectura: Flutter + Riverpod + GoRouter + Supabase + Cloudinary  
> Seguridad: PKCE Auth + RLS + RBAC (17 permisos) + Auditoría automática (14 triggers)  
> Monitorización: Error tracking + API performance + Alertas en tiempo real  
> 21 tablas · 10 enums · 50+ RLS policies · 13+ RPCs · 45+ rutas · 39 sub-features
