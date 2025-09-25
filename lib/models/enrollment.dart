import 'package:json_annotation/json_annotation.dart';
import 'course.dart';

part 'enrollment.g.dart';

@JsonSerializable()
class EnrollmentRequest {
  @JsonKey(name: 'formation_id')
  final int formationId;
  final double prix;
  @JsonKey(name: 'mode_paiement')
  final String? modePaiement;
  final String? notes;

  EnrollmentRequest({
    required this.formationId,
    required this.prix,
    this.modePaiement,
    this.notes,
  });

  factory EnrollmentRequest.fromJson(Map<String, dynamic> json) => _$EnrollmentRequestFromJson(json);
  Map<String, dynamic> toJson() => _$EnrollmentRequestToJson(this);
}

@JsonSerializable()
class EnrollmentResponse {
  final bool success;
  final String message;
  final Enrollment? enrollment;
  @JsonKey(name: 'payment_url')
  final String? paymentUrl;
  @JsonKey(name: 'order_id')
  final String? orderId;

  EnrollmentResponse({
    required this.success,
    required this.message,
    this.enrollment,
    this.paymentUrl,
    this.orderId,
  });

  factory EnrollmentResponse.fromJson(Map<String, dynamic> json) => _$EnrollmentResponseFromJson(json);
  Map<String, dynamic> toJson() => _$EnrollmentResponseToJson(this);
}

@JsonSerializable()
class Enrollment {
  final int id;
  @JsonKey(name: 'user_id')
  final int userId;
  @JsonKey(name: 'formation_id')
  final int formationId;
  final String date;
  @JsonKey(name: 'etat_commande')
  final int etatCommande;
  final double prix;
  @JsonKey(name: 'mode_paiement')
  final String? modePaiement;
  @JsonKey(name: 'statut_paiement')
  final String? statutPaiement;
  @JsonKey(name: 'date_paiement')
  final String? datePaiement;
  @JsonKey(name: 'progression')
  final double? progression;
  @JsonKey(name: 'date_completion')
  final String? dateCompletion;
  @JsonKey(name: 'created_at')
  final String? createdAt;
  @JsonKey(name: 'updated_at')
  final String? updatedAt;
  final Course? formation;

  Enrollment({
    required this.id,
    required this.userId,
    required this.formationId,
    required this.date,
    required this.etatCommande,
    required this.prix,
    this.modePaiement,
    this.statutPaiement,
    this.datePaiement,
    this.progression,
    this.dateCompletion,
    this.createdAt,
    this.updatedAt,
    this.formation,
  });

  factory Enrollment.fromJson(Map<String, dynamic> json) => _$EnrollmentFromJson(json);
  Map<String, dynamic> toJson() => _$EnrollmentToJson(this);

  // Convenience getters
  bool get isActive => etatCommande == 1;
  bool get isPaid => statutPaiement == 'paid' || statutPaiement == 'completed';
  bool get isPending => statutPaiement == 'pending';
  double get progressPercentage => progression ?? 0.0;
  String get statusText {
    switch (etatCommande) {
      case 0:
        return 'En attente';
      case 1:
        return 'Actif';
      case 2:
        return 'Suspendu';
      case 3:
        return 'Terminé';
      default:
        return 'Inconnu';
    }
  }

  String get paymentStatusText {
    switch (statutPaiement) {
      case 'pending':
        return 'En attente de paiement';
      case 'paid':
        return 'Payé';
      case 'completed':
        return 'Terminé';
      case 'failed':
        return 'Échec du paiement';
      case 'cancelled':
        return 'Annulé';
      default:
        return 'Non défini';
    }
  }
}

@JsonSerializable()
class UserEnrollments {
  final List<Enrollment> enrollments;
  @JsonKey(name: 'total_courses')
  final int totalCourses;
  @JsonKey(name: 'active_courses')
  final int activeCourses;
  @JsonKey(name: 'completed_courses')
  final int completedCourses;
  @JsonKey(name: 'total_progress')
  final double totalProgress;

  UserEnrollments({
    required this.enrollments,
    required this.totalCourses,
    required this.activeCourses,
    required this.completedCourses,
    required this.totalProgress,
  });

  factory UserEnrollments.fromJson(Map<String, dynamic> json) => _$UserEnrollmentsFromJson(json);
  Map<String, dynamic> toJson() => _$UserEnrollmentsToJson(this);
}

@JsonSerializable()
class PaymentConfirmation {
  @JsonKey(name: 'order_id')
  final String orderId;
  @JsonKey(name: 'payment_id')
  final String paymentId;
  @JsonKey(name: 'payment_status')
  final String paymentStatus;
  final double amount;
  @JsonKey(name: 'payment_method')
  final String paymentMethod;
  @JsonKey(name: 'transaction_id')
  final String? transactionId;

  PaymentConfirmation({
    required this.orderId,
    required this.paymentId,
    required this.paymentStatus,
    required this.amount,
    required this.paymentMethod,
    this.transactionId,
  });

  factory PaymentConfirmation.fromJson(Map<String, dynamic> json) => _$PaymentConfirmationFromJson(json);
  Map<String, dynamic> toJson() => _$PaymentConfirmationToJson(this);
}