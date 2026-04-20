import 'package:equatable/equatable.dart';

// ─── Platform Stats ──────────────────────────────────────────────────────────

class AdminPlatformStats extends Equatable {
  final int totalTenants;
  final int activeTenants;
  final int pendingTenants;
  final int suspendedTenants;
  final int totalUsers;
  final int todayOrders;
  final int monthOrders;
  final double todayRevenue;
  final double monthRevenue;
  final int openIncidents;
  final int inProgressIncidents;
  final int flaggedReviews;
  final double avgPlatformRating;

  const AdminPlatformStats({
    required this.totalTenants,
    required this.activeTenants,
    required this.pendingTenants,
    required this.suspendedTenants,
    required this.totalUsers,
    required this.todayOrders,
    required this.monthOrders,
    required this.todayRevenue,
    required this.monthRevenue,
    required this.openIncidents,
    required this.inProgressIncidents,
    required this.flaggedReviews,
    required this.avgPlatformRating,
  });

  factory AdminPlatformStats.fromJson(Map<String, dynamic> json) {
    return AdminPlatformStats(
      totalTenants: (json['total_tenants'] as num?)?.toInt() ?? 0,
      activeTenants: (json['active_tenants'] as num?)?.toInt() ?? 0,
      pendingTenants: (json['pending_tenants'] as num?)?.toInt() ?? 0,
      suspendedTenants: (json['suspended_tenants'] as num?)?.toInt() ?? 0,
      totalUsers: (json['total_users'] as num?)?.toInt() ?? 0,
      todayOrders: (json['today_orders'] as num?)?.toInt() ?? 0,
      monthOrders: (json['month_orders'] as num?)?.toInt() ?? 0,
      todayRevenue: (json['today_revenue'] as num?)?.toDouble() ?? 0,
      monthRevenue: (json['month_revenue'] as num?)?.toDouble() ?? 0,
      openIncidents: (json['open_incidents'] as num?)?.toInt() ?? 0,
      inProgressIncidents:
          (json['in_progress_incidents'] as num?)?.toInt() ?? 0,
      flaggedReviews: (json['flagged_reviews'] as num?)?.toInt() ?? 0,
      avgPlatformRating:
          (json['avg_platform_rating'] as num?)?.toDouble() ?? 0,
    );
  }

  @override
  List<Object?> get props => [
        totalTenants,
        activeTenants,
        todayOrders,
        monthRevenue,
      ];
}

// ─── Admin Restaurant ────────────────────────────────────────────────────────

class AdminRestaurant extends Equatable {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final String? logoUrl;
  final String? city;
  final String? phone;
  final String? email;
  final String status; // active, pending, suspended, cancelled
  final double rating;
  final int totalReviews;
  final int totalOrders;
  final String? subscriptionPlan;
  final List<String> cuisineType;
  final DateTime createdAt;

  const AdminRestaurant({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.logoUrl,
    this.city,
    this.phone,
    this.email,
    required this.status,
    required this.rating,
    required this.totalReviews,
    required this.totalOrders,
    this.subscriptionPlan,
    required this.cuisineType,
    required this.createdAt,
  });

  factory AdminRestaurant.fromJson(Map<String, dynamic> json) {
    return AdminRestaurant(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      description: json['description'] as String?,
      logoUrl: json['logo_url'] as String?,
      city: json['city'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      status: json['status'] as String? ?? 'pending',
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      totalReviews: (json['total_reviews'] as num?)?.toInt() ?? 0,
      totalOrders: (json['total_orders'] as num?)?.toInt() ?? 0,
      subscriptionPlan: json['subscription_plan'] as String?,
      cuisineType: (json['cuisine_type'] as List?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  @override
  List<Object?> get props => [id, name, status];
}

// ─── Restaurant Stats (admin view) ──────────────────────────────────────────

class AdminRestaurantStats extends Equatable {
  final int totalOrders;
  final int monthOrders;
  final double totalRevenue;
  final double monthRevenue;
  final double avgRating;
  final int totalReviews;
  final int totalEmployees;
  final int totalMenuItems;
  final int openIncidents;

  const AdminRestaurantStats({
    required this.totalOrders,
    required this.monthOrders,
    required this.totalRevenue,
    required this.monthRevenue,
    required this.avgRating,
    required this.totalReviews,
    required this.totalEmployees,
    required this.totalMenuItems,
    required this.openIncidents,
  });

  factory AdminRestaurantStats.fromJson(Map<String, dynamic> json) {
    return AdminRestaurantStats(
      totalOrders: (json['total_orders'] as num?)?.toInt() ?? 0,
      monthOrders: (json['month_orders'] as num?)?.toInt() ?? 0,
      totalRevenue: (json['total_revenue'] as num?)?.toDouble() ?? 0,
      monthRevenue: (json['month_revenue'] as num?)?.toDouble() ?? 0,
      avgRating: (json['avg_rating'] as num?)?.toDouble() ?? 0,
      totalReviews: (json['total_reviews'] as num?)?.toInt() ?? 0,
      totalEmployees: (json['total_employees'] as num?)?.toInt() ?? 0,
      totalMenuItems: (json['total_menu_items'] as num?)?.toInt() ?? 0,
      openIncidents: (json['open_incidents'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [totalOrders, totalRevenue];
}

// ─── Incident ────────────────────────────────────────────────────────────────

class Incident extends Equatable {
  final String id;
  final String? tenantId;
  final String? orderId;
  final String? reportedBy;
  final String? assignedTo;
  final String title;
  final String description;
  final String priority; // critical, high, medium, low
  final String status; // open, in_progress, resolved, closed
  final String? category; // payment, delivery, quality, technical, other
  final String? resolution;
  final DateTime? resolvedAt;
  final String? resolvedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined fields
  final String? tenantName;
  final String? reporterName;
  final String? assigneeName;

  const Incident({
    required this.id,
    this.tenantId,
    this.orderId,
    this.reportedBy,
    this.assignedTo,
    required this.title,
    required this.description,
    required this.priority,
    required this.status,
    this.category,
    this.resolution,
    this.resolvedAt,
    this.resolvedBy,
    required this.createdAt,
    required this.updatedAt,
    this.tenantName,
    this.reporterName,
    this.assigneeName,
  });

  factory Incident.fromJson(Map<String, dynamic> json) {
    return Incident(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String?,
      orderId: json['order_id'] as String?,
      reportedBy: json['reported_by'] as String?,
      assignedTo: json['assigned_to'] as String?,
      title: json['title'] as String,
      description: json['description'] as String,
      priority: json['priority'] as String? ?? 'medium',
      status: json['status'] as String? ?? 'open',
      category: json['category'] as String?,
      resolution: json['resolution'] as String?,
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'] as String)
          : null,
      resolvedBy: json['resolved_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      tenantName: json['tenants'] is Map
          ? json['tenants']['name'] as String?
          : null,
      reporterName: json['reporter'] is Map
          ? json['reporter']['full_name'] as String?
          : null,
      assigneeName: json['assignee'] is Map
          ? json['assignee']['full_name'] as String?
          : null,
    );
  }

  @override
  List<Object?> get props => [id, status, priority];
}

// ─── Flagged Review (moderation) ─────────────────────────────────────────────

class FlaggedReview extends Equatable {
  final String id;
  final String tenantId;
  final String userId;
  final String? orderId;
  final int rating;
  final String? comment;
  final String? flagReason;
  final bool isVisible;
  final DateTime createdAt;

  // Joined fields
  final String? userName;
  final String? tenantName;

  const FlaggedReview({
    required this.id,
    required this.tenantId,
    required this.userId,
    this.orderId,
    required this.rating,
    this.comment,
    this.flagReason,
    required this.isVisible,
    required this.createdAt,
    this.userName,
    this.tenantName,
  });

  factory FlaggedReview.fromJson(Map<String, dynamic> json) {
    return FlaggedReview(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      userId: json['user_id'] as String,
      orderId: json['order_id'] as String?,
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      comment: json['comment'] as String?,
      flagReason: json['flag_reason'] as String?,
      isVisible: json['is_visible'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      userName: json['profiles'] is Map
          ? json['profiles']['full_name'] as String?
          : null,
      tenantName: json['tenants'] is Map
          ? json['tenants']['name'] as String?
          : null,
    );
  }

  @override
  List<Object?> get props => [id, tenantId, userId];
}

// ─── Top Restaurant ──────────────────────────────────────────────────────────

class TopRestaurant extends Equatable {
  final String id;
  final String name;
  final String? city;
  final double rating;
  final int totalOrders;
  final double totalRevenue;

  const TopRestaurant({
    required this.id,
    required this.name,
    this.city,
    required this.rating,
    required this.totalOrders,
    required this.totalRevenue,
  });

  factory TopRestaurant.fromJson(Map<String, dynamic> json) {
    return TopRestaurant(
      id: json['id'] as String,
      name: json['name'] as String,
      city: json['city'] as String?,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      totalOrders: (json['total_orders'] as num?)?.toInt() ?? 0,
      totalRevenue: (json['total_revenue'] as num?)?.toDouble() ?? 0,
    );
  }

  @override
  List<Object?> get props => [id, name];
}

// ─── Subscription ────────────────────────────────────────────────────────────

class Subscription extends Equatable {
  final String id;
  final String tenantId;
  final String plan; // free, basic, pro, enterprise
  final String status; // active, past_due, cancelled, trialing
  final double amount;
  final String currency;
  final String billingCycle; // monthly, yearly
  final DateTime currentPeriodStart;
  final DateTime currentPeriodEnd;
  final DateTime? renewalDate;
  final DateTime? cancelledAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined
  final String? tenantName;

  const Subscription({
    required this.id,
    required this.tenantId,
    required this.plan,
    required this.status,
    required this.amount,
    required this.currency,
    required this.billingCycle,
    required this.currentPeriodStart,
    required this.currentPeriodEnd,
    this.renewalDate,
    this.cancelledAt,
    required this.createdAt,
    required this.updatedAt,
    this.tenantName,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      plan: json['plan'] as String? ?? 'free',
      status: json['status'] as String? ?? 'active',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String? ?? 'EUR',
      billingCycle: json['billing_cycle'] as String? ?? 'monthly',
      currentPeriodStart:
          DateTime.parse(json['current_period_start'] as String),
      currentPeriodEnd: DateTime.parse(json['current_period_end'] as String),
      renewalDate: json['renewal_date'] != null
          ? DateTime.parse(json['renewal_date'] as String)
          : null,
      cancelledAt: json['cancelled_at'] != null
          ? DateTime.parse(json['cancelled_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      tenantName: json['tenants'] is Map
          ? json['tenants']['name'] as String?
          : null,
    );
  }

  @override
  List<Object?> get props => [id, tenantId, plan, status];
}

// ─── Invoice ─────────────────────────────────────────────────────────────────

class Invoice extends Equatable {
  final String id;
  final String tenantId;
  final String? subscriptionId;
  final String invoiceNumber;
  final double amount;
  final double tax;
  final double total;
  final String currency;
  final String status; // pending, paid, overdue, cancelled, refunded
  final DateTime periodStart;
  final DateTime periodEnd;
  final DateTime? paidAt;
  final DateTime dueDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined
  final String? tenantName;

  const Invoice({
    required this.id,
    required this.tenantId,
    this.subscriptionId,
    required this.invoiceNumber,
    required this.amount,
    required this.tax,
    required this.total,
    required this.currency,
    required this.status,
    required this.periodStart,
    required this.periodEnd,
    this.paidAt,
    required this.dueDate,
    required this.createdAt,
    required this.updatedAt,
    this.tenantName,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      subscriptionId: json['subscription_id'] as String?,
      invoiceNumber: json['invoice_number'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      tax: (json['tax'] as num?)?.toDouble() ?? 0,
      total: (json['total'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String? ?? 'EUR',
      status: json['status'] as String? ?? 'pending',
      periodStart: DateTime.parse(json['period_start'] as String),
      periodEnd: DateTime.parse(json['period_end'] as String),
      paidAt: json['paid_at'] != null
          ? DateTime.parse(json['paid_at'] as String)
          : null,
      dueDate: DateTime.parse(json['due_date'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      tenantName: json['tenants'] is Map
          ? json['tenants']['name'] as String?
          : null,
    );
  }

  @override
  List<Object?> get props => [id, tenantId, invoiceNumber, status];
}

// ─── Subscription Stats ─────────────────────────────────────────────────────

class SubscriptionStats extends Equatable {
  final int totalSubscriptions;
  final int activeSubscriptions;
  final int pastDueSubscriptions;
  final int cancelledSubscriptions;
  final double mrr;
  final Map<String, int> planDistribution;
  final double totalRevenueInvoices;
  final int pendingInvoices;
  final int overdueInvoices;

  const SubscriptionStats({
    required this.totalSubscriptions,
    required this.activeSubscriptions,
    required this.pastDueSubscriptions,
    required this.cancelledSubscriptions,
    required this.mrr,
    required this.planDistribution,
    required this.totalRevenueInvoices,
    required this.pendingInvoices,
    required this.overdueInvoices,
  });

  factory SubscriptionStats.fromJson(Map<String, dynamic> json) {
    final planDist = json['plan_distribution'];
    final planMap = <String, int>{};
    if (planDist is Map) {
      for (final entry in planDist.entries) {
        planMap[entry.key as String] = (entry.value as num?)?.toInt() ?? 0;
      }
    }

    return SubscriptionStats(
      totalSubscriptions:
          (json['total_subscriptions'] as num?)?.toInt() ?? 0,
      activeSubscriptions:
          (json['active_subscriptions'] as num?)?.toInt() ?? 0,
      pastDueSubscriptions:
          (json['past_due_subscriptions'] as num?)?.toInt() ?? 0,
      cancelledSubscriptions:
          (json['cancelled_subscriptions'] as num?)?.toInt() ?? 0,
      mrr: (json['mrr'] as num?)?.toDouble() ?? 0,
      planDistribution: planMap,
      totalRevenueInvoices:
          (json['total_revenue_invoices'] as num?)?.toDouble() ?? 0,
      pendingInvoices: (json['pending_invoices'] as num?)?.toInt() ?? 0,
      overdueInvoices: (json['overdue_invoices'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [totalSubscriptions, mrr];
}

// ─── Audit Log Entry ─────────────────────────────────────────────────────────

class AuditLogEntry extends Equatable {
  final String id;
  final String? tenantId;
  final String? userId;
  final String? userName;
  final String action;
  final String entityType;
  final String? entityId;
  final Map<String, dynamic>? oldData;
  final Map<String, dynamic>? newData;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  const AuditLogEntry({
    required this.id,
    this.tenantId,
    this.userId,
    this.userName,
    required this.action,
    required this.entityType,
    this.entityId,
    this.oldData,
    this.newData,
    this.metadata,
    required this.createdAt,
  });

  factory AuditLogEntry.fromJson(Map<String, dynamic> json) {
    return AuditLogEntry(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String?,
      userId: json['user_id'] as String?,
      userName: json['user_name'] as String?,
      action: json['action'] as String? ?? '',
      entityType: json['entity_type'] as String? ?? '',
      entityId: json['entity_id'] as String?,
      oldData: json['old_data'] is Map
          ? Map<String, dynamic>.from(json['old_data'] as Map)
          : null,
      newData: json['new_data'] is Map
          ? Map<String, dynamic>.from(json['new_data'] as Map)
          : null,
      metadata: json['metadata'] is Map
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  @override
  List<Object?> get props => [id, action, entityType];
}

// ─── Error Log Entry ─────────────────────────────────────────────────────────

class ErrorLogEntry extends Equatable {
  final String id;
  final String severity;
  final String source;
  final String message;
  final String? stackTrace;
  final String? userId;
  final String? userName;
  final String? tenantId;
  final Map<String, dynamic>? deviceInfo;
  final String? appVersion;
  final Map<String, dynamic>? context;
  final DateTime createdAt;

  const ErrorLogEntry({
    required this.id,
    required this.severity,
    required this.source,
    required this.message,
    this.stackTrace,
    this.userId,
    this.userName,
    this.tenantId,
    this.deviceInfo,
    this.appVersion,
    this.context,
    required this.createdAt,
  });

  factory ErrorLogEntry.fromJson(Map<String, dynamic> json) {
    return ErrorLogEntry(
      id: json['id'] as String,
      severity: json['severity'] as String? ?? 'error',
      source: json['source'] as String? ?? 'unknown',
      message: json['message'] as String? ?? '',
      stackTrace: json['stack_trace'] as String?,
      userId: json['user_id'] as String?,
      userName: json['user_name'] as String?,
      tenantId: json['tenant_id'] as String?,
      deviceInfo: json['device_info'] is Map
          ? Map<String, dynamic>.from(json['device_info'] as Map)
          : null,
      appVersion: json['app_version'] as String?,
      context: json['context'] is Map
          ? Map<String, dynamic>.from(json['context'] as Map)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  @override
  List<Object?> get props => [id, severity, source];
}

// ─── Monitoring Dashboard Data ───────────────────────────────────────────────

class MonitoringDashboard {
  final MonitoringErrors errors;
  final MonitoringApiUsage apiUsage;
  final List<ErrorLogEntry> recentCriticalErrors;
  final int periodHours;
  final DateTime generatedAt;

  const MonitoringDashboard({
    required this.errors,
    required this.apiUsage,
    required this.recentCriticalErrors,
    required this.periodHours,
    required this.generatedAt,
  });

  factory MonitoringDashboard.fromJson(Map<String, dynamic> json) {
    final errorsData =
        json['errors'] as Map<String, dynamic>? ?? {};
    final apiData =
        json['api_usage'] as Map<String, dynamic>? ?? {};
    final recentErrors = json['recent_critical_errors'] as List? ?? [];

    return MonitoringDashboard(
      errors: MonitoringErrors.fromJson(errorsData),
      apiUsage: MonitoringApiUsage.fromJson(apiData),
      recentCriticalErrors: recentErrors
          .map((e) => ErrorLogEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      periodHours: (json['period_hours'] as num?)?.toInt() ?? 24,
      generatedAt: json['generated_at'] != null
          ? DateTime.parse(json['generated_at'] as String)
          : DateTime.now(),
    );
  }
}

class MonitoringErrors {
  final int total;
  final int critical;
  final int error;
  final int warning;
  final Map<String, int> bySource;

  const MonitoringErrors({
    required this.total,
    required this.critical,
    required this.error,
    required this.warning,
    required this.bySource,
  });

  factory MonitoringErrors.fromJson(Map<String, dynamic> json) {
    final sourceMap = <String, int>{};
    if (json['by_source'] is Map) {
      for (final e in (json['by_source'] as Map).entries) {
        sourceMap[e.key as String] = (e.value as num?)?.toInt() ?? 0;
      }
    }
    return MonitoringErrors(
      total: (json['total'] as num?)?.toInt() ?? 0,
      critical: (json['critical'] as num?)?.toInt() ?? 0,
      error: (json['error'] as num?)?.toInt() ?? 0,
      warning: (json['warning'] as num?)?.toInt() ?? 0,
      bySource: sourceMap,
    );
  }
}

class MonitoringApiUsage {
  final int totalRequests;
  final double avgResponseTimeMs;
  final double p95ResponseTimeMs;
  final double p99ResponseTimeMs;
  final double errorRatePercent;
  final Map<String, int> byMethod;
  final List<EndpointStat> topEndpoints;
  final List<EndpointStat> slowEndpoints;

  const MonitoringApiUsage({
    required this.totalRequests,
    required this.avgResponseTimeMs,
    required this.p95ResponseTimeMs,
    required this.p99ResponseTimeMs,
    required this.errorRatePercent,
    required this.byMethod,
    required this.topEndpoints,
    required this.slowEndpoints,
  });

  factory MonitoringApiUsage.fromJson(Map<String, dynamic> json) {
    final methodMap = <String, int>{};
    if (json['by_method'] is Map) {
      for (final e in (json['by_method'] as Map).entries) {
        methodMap[e.key as String] = (e.value as num?)?.toInt() ?? 0;
      }
    }

    final topList = (json['top_endpoints'] as List? ?? [])
        .map((e) => EndpointStat.fromJson(e as Map<String, dynamic>))
        .toList();
    final slowList = (json['slow_endpoints'] as List? ?? [])
        .map((e) => EndpointStat.fromJson(e as Map<String, dynamic>))
        .toList();

    return MonitoringApiUsage(
      totalRequests: (json['total_requests'] as num?)?.toInt() ?? 0,
      avgResponseTimeMs:
          (json['avg_response_time_ms'] as num?)?.toDouble() ?? 0,
      p95ResponseTimeMs:
          (json['p95_response_time_ms'] as num?)?.toDouble() ?? 0,
      p99ResponseTimeMs:
          (json['p99_response_time_ms'] as num?)?.toDouble() ?? 0,
      errorRatePercent:
          (json['error_rate_percent'] as num?)?.toDouble() ?? 0,
      byMethod: methodMap,
      topEndpoints: topList,
      slowEndpoints: slowList,
    );
  }
}

class EndpointStat {
  final String endpoint;
  final String? method;
  final int hits;
  final double avgMs;

  const EndpointStat({
    required this.endpoint,
    this.method,
    this.hits = 0,
    this.avgMs = 0,
  });

  factory EndpointStat.fromJson(Map<String, dynamic> json) {
    return EndpointStat(
      endpoint: json['endpoint'] as String? ?? '',
      method: json['method'] as String?,
      hits: (json['hits'] as num?)?.toInt() ??
          (json['sample_count'] as num?)?.toInt() ??
          0,
      avgMs: (json['avg_ms'] as num?)?.toDouble() ?? 0,
    );
  }
}

// ─── Audit Summary ───────────────────────────────────────────────────────────

class AuditSummary {
  final int totalEvents;
  final Map<String, int> actions;
  final Map<String, int> entities;
  final List<AuditTopUser> topUsers;
  final int periodHours;

  const AuditSummary({
    required this.totalEvents,
    required this.actions,
    required this.entities,
    required this.topUsers,
    required this.periodHours,
  });

  factory AuditSummary.fromJson(Map<String, dynamic> json) {
    final actionsMap = <String, int>{};
    if (json['actions'] is Map) {
      for (final e in (json['actions'] as Map).entries) {
        actionsMap[e.key as String] = (e.value as num?)?.toInt() ?? 0;
      }
    }
    final entitiesMap = <String, int>{};
    if (json['entities'] is Map) {
      for (final e in (json['entities'] as Map).entries) {
        entitiesMap[e.key as String] = (e.value as num?)?.toInt() ?? 0;
      }
    }
    final topUsersList = (json['top_users'] as List? ?? [])
        .map((e) => AuditTopUser.fromJson(e as Map<String, dynamic>))
        .toList();

    return AuditSummary(
      totalEvents: (json['total_events'] as num?)?.toInt() ?? 0,
      actions: actionsMap,
      entities: entitiesMap,
      topUsers: topUsersList,
      periodHours: (json['period_hours'] as num?)?.toInt() ?? 24,
    );
  }
}

class AuditTopUser {
  final String? userId;
  final String? fullName;
  final int eventCount;

  const AuditTopUser({this.userId, this.fullName, required this.eventCount});

  factory AuditTopUser.fromJson(Map<String, dynamic> json) {
    return AuditTopUser(
      userId: json['user_id'] as String?,
      fullName: json['full_name'] as String?,
      eventCount: (json['event_count'] as num?)?.toInt() ?? 0,
    );
  }
}
