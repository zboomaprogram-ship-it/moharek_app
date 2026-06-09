import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:moharek_app/l10n/app_localizations.dart';

class ErrorHandler {
  static String getFriendlyMessage(dynamic error, BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isAr = l10n?.localeName == 'ar';

    if (error == null) {
      return isAr ? 'حدث خطأ غير متوقع' : 'An unexpected error occurred';
    }

    final errorStr = error.toString().toLowerCase();

    // 1. Network / Connection Errors
    if (error is SocketException ||
        errorStr.contains('socketexception') ||
        errorStr.contains('network') ||
        errorStr.contains('failed host lookup') ||
        errorStr.contains('connection refused') ||
        errorStr.contains('connection timed out') ||
        errorStr.contains('handshake') ||
        errorStr.contains('xmlhttprequest') ||
        errorStr.contains('network_error') ||
        errorStr.contains('host lookup')) {
      return isAr
          ? 'تعذر الاتصال بالشبكة. يرجى التحقق من اتصال الإنترنت الخاص بك.'
          : 'Could not connect to the network. Please check your internet connection.';
    }

    // 2. Supabase / Postgres Errors
    if (error is PostgrestException) {
      if (error.code == 'PGRST116') {
        return isAr ? 'السجل المطلوب غير موجود.' : 'Requested record was not found.';
      }
      if (error.code == '23505') {
        return isAr ? 'هذا السجل موجود بالفعل.' : 'This record already exists.';
      }
      if (error.code == '42501' || error.message.contains('policy')) {
        return isAr ? 'ليس لديك صلاحية لإجراء هذه العملية.' : 'You do not have permission to perform this action.';
      }
      return isAr
          ? 'حدث خطأ أثناء الاتصال بقاعدة البيانات. يرجى المحاولة لاحقاً.'
          : 'A database error occurred. Please try again later.';
    }

    if (error is AuthException) {
      final msg = error.message.toLowerCase();
      if (msg.contains('invalid login credentials') || msg.contains('invalid credentials')) {
        return isAr
            ? 'بيانات الدخول غير صحيحة. يرجى التأكد من البريد الإلكتروني وكلمة المرور.'
            : 'Invalid login credentials. Please check your email and password.';
      }
      if (msg.contains('email not confirmed')) {
        return isAr
            ? 'يرجى تأكيد حسابك من خلال الرابط المرسل إلى بريدك الإلكتروني.'
            : 'Please confirm your account using the link sent to your email.';
      }
      if (msg.contains('rate limit')) {
        return isAr
            ? 'محاولات كثيرة جداً. يرجى الانتظار قليلاً والمحاولة مرة أخرى.'
            : 'Too many attempts. Please wait a moment and try again.';
      }
      return error.message;
    }

    // 3. Common technical keywords
    if (errorStr.contains('unauthorized') || errorStr.contains('forbidden')) {
      return isAr ? 'ليس لديك صلاحية للوصول.' : 'Unauthorized access.';
    }
    if (errorStr.contains('not found') || errorStr.contains('404')) {
      return isAr ? 'المحتوى المطلوب غير موجود.' : 'Requested content not found.';
    }
    if (errorStr.contains('timeout')) {
      return isAr ? 'انتهت مهلة الطلب. يرجى المحاولة مرة أخرى.' : 'Request timed out. Please try again.';
    }

    // 4. Default fallback (clean up raw exceptions if they are extremely technical, but preserve standard short messages)
    if (errorStr.contains('exception:') || errorStr.contains('error:') || errorStr.contains('postgrestexception') || errorStr.contains('bad request')) {
      return isAr
          ? 'حدث خطأ أثناء معالجة طلبك. يرجى المحاولة لاحقاً.'
          : 'An error occurred while processing your request. Please try again later.';
    }

    return error.toString();
  }

  static void showErrorSnackBar(BuildContext context, dynamic error) {
    if (!context.mounted) return;
    final message = getFriendlyMessage(error, context);
    
    // Clear existing snackbars first
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontFamily: 'Cairo', 
            fontWeight: FontWeight.w600, 
            color: Colors.white,
            fontSize: 14,
          ),
        ),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
