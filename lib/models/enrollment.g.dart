// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'enrollment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EnrollmentRequest _$EnrollmentRequestFromJson(Map<String, dynamic> json) =>
    EnrollmentRequest(
      formationId: (json['formation_id'] as num).toInt(),
      prix: (json['prix'] as num).toDouble(),
      modePaiement: json['mode_paiement'] as String?,
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$EnrollmentRequestToJson(EnrollmentRequest instance) =>
    <String, dynamic>{
      'formation_id': instance.formationId,
      'prix': instance.prix,
      'mode_paiement': instance.modePaiement,
      'notes': instance.notes,
    };

EnrollmentResponse _$EnrollmentResponseFromJson(Map<String, dynamic> json) =>
    EnrollmentResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      enrollment: json['enrollment'] == null
          ? null
          : Enrollment.fromJson(json['enrollment'] as Map<String, dynamic>),
      paymentUrl: json['payment_url'] as String?,
      orderId: json['order_id'] as String?,
    );

Map<String, dynamic> _$EnrollmentResponseToJson(EnrollmentResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'enrollment': instance.enrollment,
      'payment_url': instance.paymentUrl,
      'order_id': instance.orderId,
    };

Enrollment _$EnrollmentFromJson(Map<String, dynamic> json) => Enrollment(
  id: (json['id'] as num).toInt(),
  userId: (json['user_id'] as num).toInt(),
  formationId: (json['formation_id'] as num).toInt(),
  date: json['date'] as String,
  etatCommande: (json['etat_commande'] as num).toInt(),
  prix: (json['prix'] as num).toDouble(),
  modePaiement: json['mode_paiement'] as String?,
  statutPaiement: json['statut_paiement'] as String?,
  datePaiement: json['date_paiement'] as String?,
  progression: (json['progression'] as num?)?.toDouble(),
  dateCompletion: json['date_completion'] as String?,
  createdAt: json['created_at'] as String?,
  updatedAt: json['updated_at'] as String?,
  formation: json['formation'] == null
      ? null
      : Course.fromJson(json['formation'] as Map<String, dynamic>),
);

Map<String, dynamic> _$EnrollmentToJson(Enrollment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'formation_id': instance.formationId,
      'date': instance.date,
      'etat_commande': instance.etatCommande,
      'prix': instance.prix,
      'mode_paiement': instance.modePaiement,
      'statut_paiement': instance.statutPaiement,
      'date_paiement': instance.datePaiement,
      'progression': instance.progression,
      'date_completion': instance.dateCompletion,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
      'formation': instance.formation,
    };

UserEnrollments _$UserEnrollmentsFromJson(Map<String, dynamic> json) =>
    UserEnrollments(
      enrollments: (json['enrollments'] as List<dynamic>)
          .map((e) => Enrollment.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalCourses: (json['total_courses'] as num).toInt(),
      activeCourses: (json['active_courses'] as num).toInt(),
      completedCourses: (json['completed_courses'] as num).toInt(),
      totalProgress: (json['total_progress'] as num).toDouble(),
    );

Map<String, dynamic> _$UserEnrollmentsToJson(UserEnrollments instance) =>
    <String, dynamic>{
      'enrollments': instance.enrollments,
      'total_courses': instance.totalCourses,
      'active_courses': instance.activeCourses,
      'completed_courses': instance.completedCourses,
      'total_progress': instance.totalProgress,
    };

PaymentConfirmation _$PaymentConfirmationFromJson(Map<String, dynamic> json) =>
    PaymentConfirmation(
      orderId: json['order_id'] as String,
      paymentId: json['payment_id'] as String,
      paymentStatus: json['payment_status'] as String,
      amount: (json['amount'] as num).toDouble(),
      paymentMethod: json['payment_method'] as String,
      transactionId: json['transaction_id'] as String?,
    );

Map<String, dynamic> _$PaymentConfirmationToJson(
  PaymentConfirmation instance,
) => <String, dynamic>{
  'order_id': instance.orderId,
  'payment_id': instance.paymentId,
  'payment_status': instance.paymentStatus,
  'amount': instance.amount,
  'payment_method': instance.paymentMethod,
  'transaction_id': instance.transactionId,
};
