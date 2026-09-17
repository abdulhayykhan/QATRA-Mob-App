import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Hybrid Enterprise PostgreSQL Client for QATRA
/// Connects to Supabase project `talimcuofkvphkvreryo` (Alkhidmat Karachi)
/// Used for relational queries, audit trails, and hospital registry.
class SupabaseService {
  static const String supabaseUrl = 'https://talimcuofkvphkvreryo.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRhbGltY3VvZmt2cGhrdnJlcnlvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODg5ODI1ODksImV4cCI6MjEwNDU1ODU4OX0.Pq0mommzR15F6bwi5vNKLmJ5DqTu2A3y64TXCC_5Tgc';

  static bool _isInitialized = false;
  static bool get isInitialized => _isInitialized;

  static SupabaseClient? get client {
    if (!_isInitialized) return null;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  static Future<void> initialize() async {
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
      );
      _isInitialized = true;
      debugPrint('Supabase initialized successfully: talimcuofkvphkvreryo');
    } catch (e) {
      debugPrint('Supabase initialization notice (offline fallback active): $e');
      _isInitialized = false;
    }
  }

  /// Records an emergency blood request audit row into Supabase PostgreSQL
  static Future<void> recordRequestAudit({
    required String requestId,
    required String seekerId,
    required String seekerName,
    required String hospitalId,
    required String bloodGroup,
    required String component,
    required int units,
    required String urgency,
  }) async {
    final sb = client;
    if (sb == null) return;
    try {
      await sb.from('emergency_requests').upsert({
        'id': requestId,
        'seeker_id': seekerId,
        'seeker_name': seekerName,
        'hospital_id': hospitalId,
        'blood_group': bloodGroup,
        'component': component,
        'units_required': units,
        'urgency': urgency,
        'status': 'Broadcasting to Radius',
      });
    } catch (e) {
      debugPrint('Supabase recordRequestAudit error: $e');
    }
  }

  /// Records a fraud policy violation audit into Supabase PostgreSQL
  static Future<void> recordFraudAudit({
    String? requestId,
    required String cnic,
    String? phone,
    String? mrn,
    required String reason,
    required String confidence,
    String status = 'Flagged',
  }) async {
    final sb = client;
    if (sb == null) return;
    try {
      await sb.from('fraud_audit_log').insert({
        'request_id': requestId,
        'cnic': cnic,
        'phone': phone,
        'mrn': mrn,
        'reason': reason,
        'confidence': confidence,
        'status': status,
      });
    } catch (e) {
      debugPrint('Supabase recordFraudAudit error: $e');
    }
  }
}
