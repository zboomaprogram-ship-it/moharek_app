import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appName.
  ///
  /// In ar, this message translates to:
  /// **'محرك'**
  String get appName;

  /// No description provided for @welcomeMessage.
  ///
  /// In ar, this message translates to:
  /// **'مرحباً، {name}'**
  String welcomeMessage(String name);

  /// No description provided for @goodMorning.
  ///
  /// In ar, this message translates to:
  /// **'صباح الخير'**
  String get goodMorning;

  /// No description provided for @goodAfternoon.
  ///
  /// In ar, this message translates to:
  /// **'مساء الخير'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In ar, this message translates to:
  /// **'مساء النور'**
  String get goodEvening;

  /// No description provided for @goalLabel.
  ///
  /// In ar, this message translates to:
  /// **'هدفك: {goal}'**
  String goalLabel(String goal);

  /// No description provided for @growthProgress.
  ///
  /// In ar, this message translates to:
  /// **'تقدم النمو'**
  String get growthProgress;

  /// No description provided for @tasksCompleted.
  ///
  /// In ar, this message translates to:
  /// **'مهام منجزة'**
  String get tasksCompleted;

  /// No description provided for @inProgress.
  ///
  /// In ar, this message translates to:
  /// **'جاري التنفيذ'**
  String get inProgress;

  /// No description provided for @waitingApproval.
  ///
  /// In ar, this message translates to:
  /// **'بانتظار موافقتك'**
  String get waitingApproval;

  /// No description provided for @completed.
  ///
  /// In ar, this message translates to:
  /// **'مكتمل'**
  String get completed;

  /// No description provided for @delayed.
  ///
  /// In ar, this message translates to:
  /// **'متأخر'**
  String get delayed;

  /// No description provided for @todo.
  ///
  /// In ar, this message translates to:
  /// **'لم يبدأ'**
  String get todo;

  /// No description provided for @inReview.
  ///
  /// In ar, this message translates to:
  /// **'قيد المراجعة'**
  String get inReview;

  /// No description provided for @homeTab.
  ///
  /// In ar, this message translates to:
  /// **'الرئيسية'**
  String get homeTab;

  /// No description provided for @tasksTab.
  ///
  /// In ar, this message translates to:
  /// **'المهام'**
  String get tasksTab;

  /// No description provided for @resultsTab.
  ///
  /// In ar, this message translates to:
  /// **'النتائج'**
  String get resultsTab;

  /// No description provided for @reportsTab.
  ///
  /// In ar, this message translates to:
  /// **'التقارير'**
  String get reportsTab;

  /// No description provided for @chatTab.
  ///
  /// In ar, this message translates to:
  /// **'المحادثة'**
  String get chatTab;

  /// No description provided for @journeyTitle.
  ///
  /// In ar, this message translates to:
  /// **'رحلة النمو'**
  String get journeyTitle;

  /// No description provided for @auditStage.
  ///
  /// In ar, this message translates to:
  /// **'التحليل'**
  String get auditStage;

  /// No description provided for @strategyStage.
  ///
  /// In ar, this message translates to:
  /// **'الاستراتيجية'**
  String get strategyStage;

  /// No description provided for @setupStage.
  ///
  /// In ar, this message translates to:
  /// **'الإعداد'**
  String get setupStage;

  /// No description provided for @executionStage.
  ///
  /// In ar, this message translates to:
  /// **'التنفيذ'**
  String get executionStage;

  /// No description provided for @optimizationStage.
  ///
  /// In ar, this message translates to:
  /// **'التحسين'**
  String get optimizationStage;

  /// No description provided for @resultsStage.
  ///
  /// In ar, this message translates to:
  /// **'النتائج'**
  String get resultsStage;

  /// No description provided for @seoResults.
  ///
  /// In ar, this message translates to:
  /// **'نتائج SEO'**
  String get seoResults;

  /// No description provided for @adsResults.
  ///
  /// In ar, this message translates to:
  /// **'نتائج الإعلانات'**
  String get adsResults;

  /// No description provided for @aiVisibility.
  ///
  /// In ar, this message translates to:
  /// **'الظهور في AI'**
  String get aiVisibility;

  /// No description provided for @trustEngine.
  ///
  /// In ar, this message translates to:
  /// **'محرك الثقة'**
  String get trustEngine;

  /// No description provided for @keywords.
  ///
  /// In ar, this message translates to:
  /// **'الكلمات المفتاحية'**
  String get keywords;

  /// No description provided for @organicTraffic.
  ///
  /// In ar, this message translates to:
  /// **'الزيارات العضوية'**
  String get organicTraffic;

  /// No description provided for @leads.
  ///
  /// In ar, this message translates to:
  /// **'العملاء المحتملون'**
  String get leads;

  /// No description provided for @roas.
  ///
  /// In ar, this message translates to:
  /// **'العائد على الإعلان'**
  String get roas;

  /// No description provided for @costPerLead.
  ///
  /// In ar, this message translates to:
  /// **'تكلفة العميل'**
  String get costPerLead;

  /// No description provided for @conversionRate.
  ///
  /// In ar, this message translates to:
  /// **'معدل التحويل'**
  String get conversionRate;

  /// No description provided for @pendingApprovals.
  ///
  /// In ar, this message translates to:
  /// **'موافقات معلقة'**
  String get pendingApprovals;

  /// No description provided for @approve.
  ///
  /// In ar, this message translates to:
  /// **'موافقة'**
  String get approve;

  /// No description provided for @requestChanges.
  ///
  /// In ar, this message translates to:
  /// **'طلب تعديلات'**
  String get requestChanges;

  /// No description provided for @approved.
  ///
  /// In ar, this message translates to:
  /// **'تمت الموافقة'**
  String get approved;

  /// No description provided for @changesRequested.
  ///
  /// In ar, this message translates to:
  /// **'تم طلب تعديلات'**
  String get changesRequested;

  /// No description provided for @newReport.
  ///
  /// In ar, this message translates to:
  /// **'تقرير جديد'**
  String get newReport;

  /// No description provided for @weeklyReport.
  ///
  /// In ar, this message translates to:
  /// **'التقرير الأسبوعي'**
  String get weeklyReport;

  /// No description provided for @monthlyReport.
  ///
  /// In ar, this message translates to:
  /// **'التقرير الشهري'**
  String get monthlyReport;

  /// No description provided for @downloadPdf.
  ///
  /// In ar, this message translates to:
  /// **'تحميل PDF'**
  String get downloadPdf;

  /// No description provided for @viewReport.
  ///
  /// In ar, this message translates to:
  /// **'عرض التقرير'**
  String get viewReport;

  /// No description provided for @reportReady.
  ///
  /// In ar, this message translates to:
  /// **'التقرير جاهز'**
  String get reportReady;

  /// No description provided for @startVideoCall.
  ///
  /// In ar, this message translates to:
  /// **'بدء مكالمة فيديو'**
  String get startVideoCall;

  /// No description provided for @startVoiceCall.
  ///
  /// In ar, this message translates to:
  /// **'بدء مكالمة صوتية'**
  String get startVoiceCall;

  /// No description provided for @endCall.
  ///
  /// In ar, this message translates to:
  /// **'إنهاء المكالمة'**
  String get endCall;

  /// No description provided for @mute.
  ///
  /// In ar, this message translates to:
  /// **'كتم الصوت'**
  String get mute;

  /// No description provided for @unmute.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء الكتم'**
  String get unmute;

  /// No description provided for @hideCamera.
  ///
  /// In ar, this message translates to:
  /// **'إخفاء الكاميرا'**
  String get hideCamera;

  /// No description provided for @showCamera.
  ///
  /// In ar, this message translates to:
  /// **'إظهار الكاميرا'**
  String get showCamera;

  /// No description provided for @incomingCall.
  ///
  /// In ar, this message translates to:
  /// **'مكالمة واردة'**
  String get incomingCall;

  /// No description provided for @accept.
  ///
  /// In ar, this message translates to:
  /// **'قبول'**
  String get accept;

  /// No description provided for @decline.
  ///
  /// In ar, this message translates to:
  /// **'رفض'**
  String get decline;

  /// No description provided for @callEnded.
  ///
  /// In ar, this message translates to:
  /// **'انتهت المكالمة'**
  String get callEnded;

  /// No description provided for @callDuration.
  ///
  /// In ar, this message translates to:
  /// **'مدة المكالمة: {duration}'**
  String callDuration(String duration);

  /// No description provided for @holdToRecord.
  ///
  /// In ar, this message translates to:
  /// **'اضغط مطولاً للتسجيل'**
  String get holdToRecord;

  /// No description provided for @releaseToSend.
  ///
  /// In ar, this message translates to:
  /// **'ارفع إصبعك للإرسال'**
  String get releaseToSend;

  /// No description provided for @swipeToCancel.
  ///
  /// In ar, this message translates to:
  /// **'اسحب للإلغاء'**
  String get swipeToCancel;

  /// No description provided for @voiceMessage.
  ///
  /// In ar, this message translates to:
  /// **'رسالة صوتية'**
  String get voiceMessage;

  /// No description provided for @recording.
  ///
  /// In ar, this message translates to:
  /// **'جاري التسجيل...'**
  String get recording;

  /// No description provided for @recordingCancelled.
  ///
  /// In ar, this message translates to:
  /// **'تم إلغاء التسجيل'**
  String get recordingCancelled;

  /// No description provided for @connecting.
  ///
  /// In ar, this message translates to:
  /// **'جاري الاتصال...'**
  String get connecting;

  /// No description provided for @ringing.
  ///
  /// In ar, this message translates to:
  /// **'يرن الآن...'**
  String get ringing;

  /// No description provided for @accepted.
  ///
  /// In ar, this message translates to:
  /// **'تم القبول، جاري الانضمام...'**
  String get accepted;

  /// No description provided for @callDeclined.
  ///
  /// In ar, this message translates to:
  /// **'تم رفض المكالمة'**
  String get callDeclined;

  /// No description provided for @callTimeout.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد رد من الطرف الآخر'**
  String get callTimeout;

  /// No description provided for @typeMessage.
  ///
  /// In ar, this message translates to:
  /// **'اكتب رسالة...'**
  String get typeMessage;

  /// No description provided for @send.
  ///
  /// In ar, this message translates to:
  /// **'إرسال'**
  String get send;

  /// No description provided for @micPermissionDenied.
  ///
  /// In ar, this message translates to:
  /// **'يرجى السماح بالوصول إلى الميكروفون في الإعدادات'**
  String get micPermissionDenied;

  /// No description provided for @today.
  ///
  /// In ar, this message translates to:
  /// **'اليوم'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In ar, this message translates to:
  /// **'أمس'**
  String get yesterday;

  /// No description provided for @requestMeeting.
  ///
  /// In ar, this message translates to:
  /// **'طلب اجتماع'**
  String get requestMeeting;

  /// No description provided for @upcomingMeetings.
  ///
  /// In ar, this message translates to:
  /// **'الاجتماعات القادمة'**
  String get upcomingMeetings;

  /// No description provided for @joinMeeting.
  ///
  /// In ar, this message translates to:
  /// **'الانضمام للاجتماع'**
  String get joinMeeting;

  /// No description provided for @meetingSummary.
  ///
  /// In ar, this message translates to:
  /// **'ملخص الاجتماع'**
  String get meetingSummary;

  /// No description provided for @actionItems.
  ///
  /// In ar, this message translates to:
  /// **'بنود العمل'**
  String get actionItems;

  /// No description provided for @contracts.
  ///
  /// In ar, this message translates to:
  /// **'العقود'**
  String get contracts;

  /// No description provided for @signed.
  ///
  /// In ar, this message translates to:
  /// **'موقّع'**
  String get signed;

  /// No description provided for @pendingSignature.
  ///
  /// In ar, this message translates to:
  /// **'بانتظار التوقيع'**
  String get pendingSignature;

  /// No description provided for @expired.
  ///
  /// In ar, this message translates to:
  /// **'منتهي'**
  String get expired;

  /// No description provided for @invoices.
  ///
  /// In ar, this message translates to:
  /// **'الفواتير'**
  String get invoices;

  /// No description provided for @payNow.
  ///
  /// In ar, this message translates to:
  /// **'ادفع الآن'**
  String get payNow;

  /// No description provided for @paid.
  ///
  /// In ar, this message translates to:
  /// **'مدفوع'**
  String get paid;

  /// No description provided for @overdue.
  ///
  /// In ar, this message translates to:
  /// **'متأخر السداد'**
  String get overdue;

  /// No description provided for @paymentSuccessful.
  ///
  /// In ar, this message translates to:
  /// **'تمت عملية الدفع بنجاح ✅'**
  String get paymentSuccessful;

  /// No description provided for @files.
  ///
  /// In ar, this message translates to:
  /// **'الملفات'**
  String get files;

  /// No description provided for @brandGuidelines.
  ///
  /// In ar, this message translates to:
  /// **'دليل الهوية'**
  String get brandGuidelines;

  /// No description provided for @contentPlan.
  ///
  /// In ar, this message translates to:
  /// **'خطة المحتوى'**
  String get contentPlan;

  /// No description provided for @campaignAssets.
  ///
  /// In ar, this message translates to:
  /// **'مواد الحملة'**
  String get campaignAssets;

  /// No description provided for @settings.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In ar, this message translates to:
  /// **'اللغة'**
  String get language;

  /// No description provided for @arabic.
  ///
  /// In ar, this message translates to:
  /// **'العربية'**
  String get arabic;

  /// No description provided for @english.
  ///
  /// In ar, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @notifications.
  ///
  /// In ar, this message translates to:
  /// **'الإشعارات'**
  String get notifications;

  /// No description provided for @logout.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الخروج'**
  String get logout;

  /// No description provided for @profile.
  ///
  /// In ar, this message translates to:
  /// **'الملف الشخصي'**
  String get profile;

  /// No description provided for @healthScore.
  ///
  /// In ar, this message translates to:
  /// **'مؤشر الصحة'**
  String get healthScore;

  /// No description provided for @thriving.
  ///
  /// In ar, this message translates to:
  /// **'ممتاز'**
  String get thriving;

  /// No description provided for @growing.
  ///
  /// In ar, this message translates to:
  /// **'في نمو'**
  String get growing;

  /// No description provided for @steady.
  ///
  /// In ar, this message translates to:
  /// **'مستقر'**
  String get steady;

  /// No description provided for @needsAttention.
  ///
  /// In ar, this message translates to:
  /// **'يحتاج اهتمام'**
  String get needsAttention;

  /// No description provided for @milestoneReached.
  ///
  /// In ar, this message translates to:
  /// **'إنجاز جديد! 🎉'**
  String get milestoneReached;

  /// No description provided for @keywordPage1.
  ///
  /// In ar, this message translates to:
  /// **'كلمتك المفتاحية وصلت للصفحة الأولى!'**
  String get keywordPage1;

  /// No description provided for @trafficDoubled.
  ///
  /// In ar, this message translates to:
  /// **'تضاعفت زياراتك! 🚀'**
  String get trafficDoubled;

  /// No description provided for @leads100.
  ///
  /// In ar, this message translates to:
  /// **'وصلت لـ 100 عميل محتمل 🏆'**
  String get leads100;

  /// No description provided for @howAreYouFeeling.
  ///
  /// In ar, this message translates to:
  /// **'كيف تشعر تجاه تقدم نموك؟'**
  String get howAreYouFeeling;

  /// No description provided for @submitFeedback.
  ///
  /// In ar, this message translates to:
  /// **'إرسال'**
  String get submitFeedback;

  /// No description provided for @maybeLater.
  ///
  /// In ar, this message translates to:
  /// **'لاحقاً'**
  String get maybeLater;

  /// No description provided for @thankYouFeedback.
  ///
  /// In ar, this message translates to:
  /// **'شكراً لرأيك! ❤️'**
  String get thankYouFeedback;

  /// No description provided for @emptyTasks.
  ///
  /// In ar, this message translates to:
  /// **'فريقك يجهّز المهام الأولى — تابع قريباً'**
  String get emptyTasks;

  /// No description provided for @emptyReports.
  ///
  /// In ar, this message translates to:
  /// **'تقريرك الأول سيكون جاهزاً نهاية الشهر'**
  String get emptyReports;

  /// No description provided for @emptyResults.
  ///
  /// In ar, this message translates to:
  /// **'البيانات تبدأ بعد أسبوعين من التنفيذ'**
  String get emptyResults;

  /// No description provided for @emptyApprovals.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد شيء ينتظر موافقتك ☕'**
  String get emptyApprovals;

  /// No description provided for @emptyChat.
  ///
  /// In ar, this message translates to:
  /// **'قل مرحباً لمدير نموك 👋'**
  String get emptyChat;

  /// No description provided for @newSinceLastVisit.
  ///
  /// In ar, this message translates to:
  /// **'جديد منذ آخر زيارة'**
  String get newSinceLastVisit;

  /// No description provided for @tasksCompletedSince.
  ///
  /// In ar, this message translates to:
  /// **'تم إنجاز {count} مهام منذ آخر زيارة'**
  String tasksCompletedSince(int count);

  /// No description provided for @trafficIncrease.
  ///
  /// In ar, this message translates to:
  /// **'زياراتك زادت {percent}% هذا الأسبوع'**
  String trafficIncrease(int percent);

  /// No description provided for @itemNeedsApproval.
  ///
  /// In ar, this message translates to:
  /// **'يوجد {count} عنصر يحتاج موافقتك'**
  String itemNeedsApproval(int count);

  /// No description provided for @onboardingWelcomeTitle.
  ///
  /// In ar, this message translates to:
  /// **'مرحباً بك في محرك'**
  String get onboardingWelcomeTitle;

  /// No description provided for @onboardingWelcomeSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'رحلة نموك تبدأ الآن'**
  String get onboardingWelcomeSubtitle;

  /// No description provided for @onboardingBegin.
  ///
  /// In ar, this message translates to:
  /// **'لنبدأ ←'**
  String get onboardingBegin;

  /// No description provided for @onboardingTeamTitle.
  ///
  /// In ar, this message translates to:
  /// **'هؤلاء يعملون لأجل نموك'**
  String get onboardingTeamTitle;

  /// No description provided for @onboardingRoadmapTitle.
  ///
  /// In ar, this message translates to:
  /// **'خطتك للـ 90 يوم القادمة'**
  String get onboardingRoadmapTitle;

  /// No description provided for @onboardingGoalTitle.
  ///
  /// In ar, this message translates to:
  /// **'ما هو هدفك الأول لهذا العام؟'**
  String get onboardingGoalTitle;

  /// No description provided for @goalMoreLeads.
  ///
  /// In ar, this message translates to:
  /// **'زيادة العملاء المحتملين'**
  String get goalMoreLeads;

  /// No description provided for @goalBrandAwareness.
  ///
  /// In ar, this message translates to:
  /// **'تقوية الحضور الرقمي'**
  String get goalBrandAwareness;

  /// No description provided for @goalMoreSales.
  ///
  /// In ar, this message translates to:
  /// **'زيادة المبيعات'**
  String get goalMoreSales;

  /// No description provided for @goalImproveRanking.
  ///
  /// In ar, this message translates to:
  /// **'تحسين ترتيب الموقع'**
  String get goalImproveRanking;

  /// No description provided for @loginTitle.
  ///
  /// In ar, this message translates to:
  /// **'مرحباً بك في محرك'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'سجل الدخول للوصول إلى بوابة العملاء'**
  String get loginSubtitle;

  /// No description provided for @emailLabel.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني'**
  String get emailLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور'**
  String get passwordLabel;

  /// No description provided for @forgotPassword.
  ///
  /// In ar, this message translates to:
  /// **'نسيت كلمة المرور؟'**
  String get forgotPassword;

  /// No description provided for @signIn.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول'**
  String get signIn;

  /// No description provided for @loginError.
  ///
  /// In ar, this message translates to:
  /// **'يرجى إدخال البريد الإلكتروني وكلمة المرور.'**
  String get loginError;

  /// No description provided for @unexpectedError.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى.'**
  String get unexpectedError;

  /// No description provided for @reportsTitle.
  ///
  /// In ar, this message translates to:
  /// **'التقارير'**
  String get reportsTitle;

  /// No description provided for @growthStory.
  ///
  /// In ar, this message translates to:
  /// **'قصة النمو'**
  String get growthStory;

  /// No description provided for @ready.
  ///
  /// In ar, this message translates to:
  /// **'جاهز'**
  String get ready;

  /// No description provided for @errorOccurred.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ: {error}'**
  String errorOccurred(String error);

  /// No description provided for @quickActions.
  ///
  /// In ar, this message translates to:
  /// **'روابط سريعة'**
  String get quickActions;

  /// No description provided for @performanceSnapshots.
  ///
  /// In ar, this message translates to:
  /// **'لقطات الأداء'**
  String get performanceSnapshots;

  /// No description provided for @projectGrowth.
  ///
  /// In ar, this message translates to:
  /// **'نمو المشروع'**
  String get projectGrowth;

  /// No description provided for @viewJourney.
  ///
  /// In ar, this message translates to:
  /// **'عرض الرحلة'**
  String get viewJourney;

  /// No description provided for @currentStage.
  ///
  /// In ar, this message translates to:
  /// **'المرحلة الحالية: {stage}'**
  String currentStage(String stage);

  /// No description provided for @focusedOn.
  ///
  /// In ar, this message translates to:
  /// **'التركيز على: {goal}'**
  String focusedOn(String goal);

  /// No description provided for @contractAwaitingSignature.
  ///
  /// In ar, this message translates to:
  /// **'عقد بانتظار توقيعك'**
  String get contractAwaitingSignature;

  /// No description provided for @tapToReview.
  ///
  /// In ar, this message translates to:
  /// **'اضغط للمراجعة والتوقيع'**
  String get tapToReview;

  /// No description provided for @adSpend.
  ///
  /// In ar, this message translates to:
  /// **'ميزانية الإعلانات'**
  String get adSpend;

  /// No description provided for @tasksTitle.
  ///
  /// In ar, this message translates to:
  /// **'مهام المشروع'**
  String get tasksTitle;

  /// No description provided for @allTab.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get allTab;

  /// No description provided for @waitingMeTab.
  ///
  /// In ar, this message translates to:
  /// **'بانتظاري'**
  String get waitingMeTab;

  /// No description provided for @general.
  ///
  /// In ar, this message translates to:
  /// **'عام'**
  String get general;

  /// No description provided for @noDate.
  ///
  /// In ar, this message translates to:
  /// **'بدون تاريخ'**
  String get noDate;

  /// No description provided for @offlineMessage.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد اتصال بالإنترنت. يرجى التحقق من الشبكة.'**
  String get offlineMessage;

  /// No description provided for @aiVisibilityTitle.
  ///
  /// In ar, this message translates to:
  /// **'الظهور في منصات AI'**
  String get aiVisibilityTitle;

  /// No description provided for @noDataYet.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد بيانات حالياً'**
  String get noDataYet;

  /// No description provided for @resultsAppearLater.
  ///
  /// In ar, this message translates to:
  /// **'ستظهر نتائج {type} هنا بمجرد تسجيلها'**
  String resultsAppearLater(String type);

  /// No description provided for @notVisible.
  ///
  /// In ar, this message translates to:
  /// **'غير ظاهر'**
  String get notVisible;

  /// No description provided for @feedback.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظات'**
  String get feedback;

  /// No description provided for @cancel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get cancel;

  /// No description provided for @describeChanges.
  ///
  /// In ar, this message translates to:
  /// **'صف التعديلات المطلوبة...'**
  String get describeChanges;

  /// No description provided for @monthlyReports.
  ///
  /// In ar, this message translates to:
  /// **'التقارير الشهرية'**
  String get monthlyReports;

  /// No description provided for @taskUpdates.
  ///
  /// In ar, this message translates to:
  /// **'تحديثات المهام'**
  String get taskUpdates;

  /// No description provided for @chatMessages.
  ///
  /// In ar, this message translates to:
  /// **'رسائل المحادثة'**
  String get chatMessages;

  /// No description provided for @milestonesWins.
  ///
  /// In ar, this message translates to:
  /// **'الإنجازات والنجاحات'**
  String get milestonesWins;

  /// No description provided for @adminDashboard.
  ///
  /// In ar, this message translates to:
  /// **'لوحة الإدارة'**
  String get adminDashboard;

  /// No description provided for @clients.
  ///
  /// In ar, this message translates to:
  /// **'العملاء'**
  String get clients;

  /// No description provided for @notify.
  ///
  /// In ar, this message translates to:
  /// **'التنبيهات'**
  String get notify;

  /// No description provided for @reportsEmptyTitle.
  ///
  /// In ar, this message translates to:
  /// **'بانتظار قصة نجاحك'**
  String get reportsEmptyTitle;

  /// No description provided for @reportsEmptyMsg.
  ///
  /// In ar, this message translates to:
  /// **'تقارير النمو ستظهر هنا قريباً. نحن نعمل حالياً على تحليل بياناتك وتحويلها إلى أرقام تعكس نجاحك.'**
  String get reportsEmptyMsg;

  /// No description provided for @tasksEmptyTitle.
  ///
  /// In ar, this message translates to:
  /// **'الطريق ممهد'**
  String get tasksEmptyTitle;

  /// No description provided for @tasksEmptyMsg.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد مهام حالية تتطلب انتباهك. فريقنا يعمل في الخلفية لضمان سير الأمور بسلاسة.'**
  String get tasksEmptyMsg;

  /// No description provided for @approvalsEmptyTitle.
  ///
  /// In ar, this message translates to:
  /// **'كل شيء جاهز'**
  String get approvalsEmptyTitle;

  /// No description provided for @approvalsEmptyMsg.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد طلبات موافقة معلقة حالياً. سنقوم بإبلاغك فور حاجتنا لرأيك في الخطوات القادمة.'**
  String get approvalsEmptyMsg;

  /// No description provided for @genericEmptyTitle.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد بيانات'**
  String get genericEmptyTitle;

  /// No description provided for @genericEmptyMsg.
  ///
  /// In ar, this message translates to:
  /// **'هذا القسم سيتم تحديثه بمجرد وجود نشاط جديد.'**
  String get genericEmptyMsg;

  /// No description provided for @welcomeTitle.
  ///
  /// In ar, this message translates to:
  /// **'مرحباً بك.\nرحلة نموك تبدأ الآن.'**
  String get welcomeTitle;

  /// No description provided for @thrilledPartner.
  ///
  /// In ar, this message translates to:
  /// **'نحن متحمسون للشراكة معك.'**
  String get thrilledPartner;

  /// No description provided for @letsBegin.
  ///
  /// In ar, this message translates to:
  /// **'لنبدأ'**
  String get letsBegin;

  /// No description provided for @meetYourTeam.
  ///
  /// In ar, this message translates to:
  /// **'تعرف على فريقك'**
  String get meetYourTeam;

  /// No description provided for @peopleWorkingForYou.
  ///
  /// In ar, this message translates to:
  /// **'هؤلاء هم الأشخاص الذين يعملون لأجلك كل يوم.'**
  String get peopleWorkingForYou;

  /// No description provided for @next.
  ///
  /// In ar, this message translates to:
  /// **'التالي'**
  String get next;

  /// No description provided for @roadmapTitle.
  ///
  /// In ar, this message translates to:
  /// **'خارطة الطريق لـ 90 يوماً'**
  String get roadmapTitle;

  /// No description provided for @structuredPlan.
  ///
  /// In ar, this message translates to:
  /// **'خطة مدروسة للنجاح.'**
  String get structuredPlan;

  /// No description provided for @whatToExpect.
  ///
  /// In ar, this message translates to:
  /// **'ماذا تتوقع'**
  String get whatToExpect;

  /// No description provided for @trackResults.
  ///
  /// In ar, this message translates to:
  /// **'تتبع نتائجك هنا - يتم تحديثها أسبوعياً'**
  String get trackResults;

  /// No description provided for @approveContent.
  ///
  /// In ar, this message translates to:
  /// **'وافق على المحتوى قبل نشره'**
  String get approveContent;

  /// No description provided for @talkGrowthManager.
  ///
  /// In ar, this message translates to:
  /// **'تحدث إلى مدير النمو الخاص بك في أي وقت'**
  String get talkGrowthManager;

  /// No description provided for @almostDone.
  ///
  /// In ar, this message translates to:
  /// **'شارفنا على الانتهاء'**
  String get almostDone;

  /// No description provided for @tellUsGoal.
  ///
  /// In ar, this message translates to:
  /// **'قبل أن نبدأ، أخبرنا شيئاً واحداً:'**
  String get tellUsGoal;

  /// No description provided for @goalQuestion.
  ///
  /// In ar, this message translates to:
  /// **'ما هو هدفك الأول لهذا العام؟'**
  String get goalQuestion;

  /// No description provided for @finishEnterDashboard.
  ///
  /// In ar, this message translates to:
  /// **'إنهاء والدخول إلى لوحة التحكم'**
  String get finishEnterDashboard;

  /// No description provided for @increaseSales.
  ///
  /// In ar, this message translates to:
  /// **'زيادة المبيعات'**
  String get increaseSales;

  /// No description provided for @improvePresence.
  ///
  /// In ar, this message translates to:
  /// **'تحسين الظهور الرقمي'**
  String get improvePresence;

  /// No description provided for @launchProduct.
  ///
  /// In ar, this message translates to:
  /// **'إطلاق منتج جديد'**
  String get launchProduct;

  /// No description provided for @rebrand.
  ///
  /// In ar, this message translates to:
  /// **'إعادة بناء الهوية'**
  String get rebrand;

  /// No description provided for @auditOnboarding.
  ///
  /// In ar, this message translates to:
  /// **'التدقيق والتهيئة'**
  String get auditOnboarding;

  /// No description provided for @strategyDelivered.
  ///
  /// In ar, this message translates to:
  /// **'تسليم الاستراتيجية'**
  String get strategyDelivered;

  /// No description provided for @firstCampaign.
  ///
  /// In ar, this message translates to:
  /// **'إطلاق أول حملة'**
  String get firstCampaign;

  /// No description provided for @optimizationReview.
  ///
  /// In ar, this message translates to:
  /// **'التحسين والمراجعة'**
  String get optimizationReview;

  /// No description provided for @quarterlyReport.
  ///
  /// In ar, this message translates to:
  /// **'تقرير النمو الربع سنوي'**
  String get quarterlyReport;

  /// No description provided for @growthJourney.
  ///
  /// In ar, this message translates to:
  /// **'رحلة النمو'**
  String get growthJourney;

  /// No description provided for @audit.
  ///
  /// In ar, this message translates to:
  /// **'التدقيق'**
  String get audit;

  /// No description provided for @strategy.
  ///
  /// In ar, this message translates to:
  /// **'الاستراتيجية'**
  String get strategy;

  /// No description provided for @setup.
  ///
  /// In ar, this message translates to:
  /// **'التجهيز'**
  String get setup;

  /// No description provided for @execution.
  ///
  /// In ar, this message translates to:
  /// **'التنفيذ'**
  String get execution;

  /// No description provided for @optimization.
  ///
  /// In ar, this message translates to:
  /// **'التحسين'**
  String get optimization;

  /// No description provided for @results.
  ///
  /// In ar, this message translates to:
  /// **'النتائج'**
  String get results;

  /// No description provided for @nextPhaseGrowth.
  ///
  /// In ar, this message translates to:
  /// **'الاستعداد للمرحلة القادمة من النمو.'**
  String get nextPhaseGrowth;

  /// No description provided for @trackingProgress.
  ///
  /// In ar, this message translates to:
  /// **'تتبع التقدم وتحسين النتائج لهذه المرحلة.'**
  String get trackingProgress;

  /// No description provided for @noMessagesYet.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد رسائل بعد'**
  String get noMessagesYet;

  /// No description provided for @sendMessageToStart.
  ///
  /// In ar, this message translates to:
  /// **'أرسل رسالة للبدء!'**
  String get sendMessageToStart;

  /// No description provided for @photo.
  ///
  /// In ar, this message translates to:
  /// **'صورة'**
  String get photo;

  /// No description provided for @supportTeam.
  ///
  /// In ar, this message translates to:
  /// **'فريق الدعم'**
  String get supportTeam;

  /// No description provided for @tapToJoin.
  ///
  /// In ar, this message translates to:
  /// **'اضغط للانضمام'**
  String get tapToJoin;

  /// No description provided for @uploadFailed.
  ///
  /// In ar, this message translates to:
  /// **'فشل الرفع: {error}'**
  String uploadFailed(String error);

  /// No description provided for @amountDue.
  ///
  /// In ar, this message translates to:
  /// **'المبلغ المستحق'**
  String get amountDue;

  /// No description provided for @dueDate.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ الاستحقاق'**
  String get dueDate;

  /// No description provided for @noInvoicesFound.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد فواتير.'**
  String get noInvoicesFound;

  /// No description provided for @invoiceLabel.
  ///
  /// In ar, this message translates to:
  /// **'فاتورة'**
  String get invoiceLabel;

  /// No description provided for @unpaid.
  ///
  /// In ar, this message translates to:
  /// **'غير مدفوعة'**
  String get unpaid;

  /// No description provided for @pending.
  ///
  /// In ar, this message translates to:
  /// **'معلقة'**
  String get pending;

  /// No description provided for @meetings.
  ///
  /// In ar, this message translates to:
  /// **'الاجتماعات'**
  String get meetings;

  /// No description provided for @request.
  ///
  /// In ar, this message translates to:
  /// **'طلب'**
  String get request;

  /// No description provided for @upcoming.
  ///
  /// In ar, this message translates to:
  /// **'القادمة'**
  String get upcoming;

  /// No description provided for @pastMeetings.
  ///
  /// In ar, this message translates to:
  /// **'الاجتماعات السابقة'**
  String get pastMeetings;

  /// No description provided for @noMeetingsScheduled.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد اجتماعات مجدولة'**
  String get noMeetingsScheduled;

  /// No description provided for @tapRequestSchedule.
  ///
  /// In ar, this message translates to:
  /// **'اضغط على \'طلب\' لجدولة اجتماع.'**
  String get tapRequestSchedule;

  /// No description provided for @whatDiscuss.
  ///
  /// In ar, this message translates to:
  /// **'ماذا تريد أن تناقش؟'**
  String get whatDiscuss;

  /// No description provided for @pickDate.
  ///
  /// In ar, this message translates to:
  /// **'اختر التاريخ المفضل'**
  String get pickDate;

  /// No description provided for @sendRequest.
  ///
  /// In ar, this message translates to:
  /// **'إرسال الطلب'**
  String get sendRequest;

  /// No description provided for @ongoing.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ'**
  String get ongoing;

  /// No description provided for @cancelled.
  ///
  /// In ar, this message translates to:
  /// **'ملغي'**
  String get cancelled;

  /// No description provided for @topic.
  ///
  /// In ar, this message translates to:
  /// **'الموضوع'**
  String get topic;

  /// No description provided for @date.
  ///
  /// In ar, this message translates to:
  /// **'التاريخ والوقت'**
  String get date;

  /// No description provided for @submit.
  ///
  /// In ar, this message translates to:
  /// **'إرسال'**
  String get submit;

  /// No description provided for @requestSent.
  ///
  /// In ar, this message translates to:
  /// **'تم إرسال الطلب بنجاح! ✅'**
  String get requestSent;

  /// No description provided for @sendResetLink.
  ///
  /// In ar, this message translates to:
  /// **'إرسال رابط إعادة التعيين'**
  String get sendResetLink;

  /// No description provided for @checkInbox.
  ///
  /// In ar, this message translates to:
  /// **'تحقق من بريدك الوارد!'**
  String get checkInbox;

  /// No description provided for @sentResetLinkTo.
  ///
  /// In ar, this message translates to:
  /// **'لقد أرسلنا رابط إعادة تعيين كلمة المرور إلى {email}'**
  String sentResetLinkTo(String email);

  /// No description provided for @backToSignIn.
  ///
  /// In ar, this message translates to:
  /// **'العودة إلى تسجيل الدخول'**
  String get backToSignIn;

  /// No description provided for @resetPasswordDescription.
  ///
  /// In ar, this message translates to:
  /// **'أدخل بريدك الإلكتروني وسنرسل لك رابطاً لإعادة التعيين.'**
  String get resetPasswordDescription;

  /// No description provided for @clientsManagement.
  ///
  /// In ar, this message translates to:
  /// **'إدارة العملاء'**
  String get clientsManagement;

  /// No description provided for @newClient.
  ///
  /// In ar, this message translates to:
  /// **'عميل جديد'**
  String get newClient;

  /// No description provided for @noClientsFound.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد عملاء.'**
  String get noClientsFound;

  /// No description provided for @fillAllFields.
  ///
  /// In ar, this message translates to:
  /// **'يرجى ملء جميع الحقول'**
  String get fillAllFields;

  /// No description provided for @clientCreatedSuccess.
  ///
  /// In ar, this message translates to:
  /// **'✅ تم إنشاء العميل بنجاح!'**
  String get clientCreatedSuccess;

  /// No description provided for @fullName.
  ///
  /// In ar, this message translates to:
  /// **'الاسم الكامل'**
  String get fullName;

  /// No description provided for @projectName.
  ///
  /// In ar, this message translates to:
  /// **'اسم المشروع'**
  String get projectName;

  /// No description provided for @createClient.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء عميل'**
  String get createClient;

  /// No description provided for @adminConsole.
  ///
  /// In ar, this message translates to:
  /// **'لوحة الإدارة'**
  String get adminConsole;

  /// No description provided for @operations.
  ///
  /// In ar, this message translates to:
  /// **'العمليات'**
  String get operations;

  /// No description provided for @activeClients.
  ///
  /// In ar, this message translates to:
  /// **'العملاء النشطون'**
  String get activeClients;

  /// No description provided for @pendingTasksCount.
  ///
  /// In ar, this message translates to:
  /// **'{count} مهام معلقة'**
  String pendingTasksCount(int count);

  /// No description provided for @approvalsWaitingCount.
  ///
  /// In ar, this message translates to:
  /// **'{count} موافقات بانتظار المراجعة'**
  String approvalsWaitingCount(int count);

  /// No description provided for @unsignedContractsCount.
  ///
  /// In ar, this message translates to:
  /// **'{count} عقود غير موقعة'**
  String unsignedContractsCount(int count);

  /// No description provided for @allClients.
  ///
  /// In ar, this message translates to:
  /// **'كل العملاء'**
  String get allClients;

  /// No description provided for @filter.
  ///
  /// In ar, this message translates to:
  /// **'تصفية'**
  String get filter;

  /// No description provided for @uploadContract.
  ///
  /// In ar, this message translates to:
  /// **'رفع عقد'**
  String get uploadContract;

  /// No description provided for @contractSentSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم إرسال العقد للعميل ✅'**
  String get contractSentSuccess;

  /// No description provided for @clickNewClientToAdd.
  ///
  /// In ar, this message translates to:
  /// **'اضغط على \"عميل جديد\" لإضافة أول عميل لك.'**
  String get clickNewClientToAdd;

  /// No description provided for @photoLabel.
  ///
  /// In ar, this message translates to:
  /// **'صورة'**
  String get photoLabel;

  /// No description provided for @fileLabel.
  ///
  /// In ar, this message translates to:
  /// **'ملف'**
  String get fileLabel;

  /// No description provided for @callStarted.
  ///
  /// In ar, this message translates to:
  /// **'{type} بدأت'**
  String callStarted(String type);

  /// No description provided for @viewContract.
  ///
  /// In ar, this message translates to:
  /// **'عرض العقد'**
  String get viewContract;

  /// No description provided for @signContract.
  ///
  /// In ar, this message translates to:
  /// **'توقيع العقد'**
  String get signContract;

  /// No description provided for @contractSignedSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم توقيع العقد بنجاح! ✅'**
  String get contractSignedSuccess;

  /// No description provided for @iAgree.
  ///
  /// In ar, this message translates to:
  /// **'أنا أوافق'**
  String get iAgree;

  /// No description provided for @signContractConfirmation.
  ///
  /// In ar, this message translates to:
  /// **'بالنقر على \"أنا أوافق\"، فإنك تؤكد أنك قرأت وقبلت شروط \"{title}\".'**
  String signContractConfirmation(String title);

  /// No description provided for @noPdfAvailable.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد ملف PDF متاح'**
  String get noPdfAvailable;

  /// No description provided for @filesTab.
  ///
  /// In ar, this message translates to:
  /// **'الملفات'**
  String get filesTab;

  /// No description provided for @noFilesFound.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد ملفات'**
  String get noFilesFound;

  /// No description provided for @brandLabel.
  ///
  /// In ar, this message translates to:
  /// **'الهوية'**
  String get brandLabel;

  /// No description provided for @companyName.
  ///
  /// In ar, this message translates to:
  /// **'اسم الشركة'**
  String get companyName;

  /// No description provided for @contentLabel.
  ///
  /// In ar, this message translates to:
  /// **'المحتوى'**
  String get contentLabel;

  /// No description provided for @campaignsLabel.
  ///
  /// In ar, this message translates to:
  /// **'الحملات'**
  String get campaignsLabel;

  /// No description provided for @strategyLabel.
  ///
  /// In ar, this message translates to:
  /// **'الاستراتيجية'**
  String get strategyLabel;

  /// No description provided for @unknownUser.
  ///
  /// In ar, this message translates to:
  /// **'مستخدم غير معروف'**
  String get unknownUser;

  /// No description provided for @noCompany.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد شركة'**
  String get noCompany;

  /// No description provided for @failedToCreateClient.
  ///
  /// In ar, this message translates to:
  /// **'فشل في إنشاء العميل'**
  String get failedToCreateClient;

  /// No description provided for @uploadPdfInstructions.
  ///
  /// In ar, this message translates to:
  /// **'قم برفع ملف PDF إلى Supabase Storage أولاً، ثم الصق الرابط هنا.'**
  String get uploadPdfInstructions;

  /// No description provided for @myProfile.
  ///
  /// In ar, this message translates to:
  /// **'ملفي الشخصي'**
  String get myProfile;

  /// No description provided for @signOut.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الخروج'**
  String get signOut;

  /// No description provided for @signOutConfirm.
  ///
  /// In ar, this message translates to:
  /// **'هل أنت متأكد أنك تريد تسجيل الخروج؟'**
  String get signOutConfirm;

  /// No description provided for @accountSettings.
  ///
  /// In ar, this message translates to:
  /// **'إعدادات الحساب'**
  String get accountSettings;

  /// No description provided for @personalInfo.
  ///
  /// In ar, this message translates to:
  /// **'المعلومات الشخصية'**
  String get personalInfo;

  /// No description provided for @companyProfile.
  ///
  /// In ar, this message translates to:
  /// **'ملف الشركة'**
  String get companyProfile;

  /// No description provided for @billingInvoices.
  ///
  /// In ar, this message translates to:
  /// **'الفواتير والاشتراكات'**
  String get billingInvoices;

  /// No description provided for @appSettingsNotifications.
  ///
  /// In ar, this message translates to:
  /// **'إعدادات التطبيق والتنبيهات'**
  String get appSettingsNotifications;

  /// No description provided for @support.
  ///
  /// In ar, this message translates to:
  /// **'الدعم الفني'**
  String get support;

  /// No description provided for @helpCenter.
  ///
  /// In ar, this message translates to:
  /// **'مركز المساعدة'**
  String get helpCenter;

  /// No description provided for @contactManager.
  ///
  /// In ar, this message translates to:
  /// **'التواصل مع مدير الحساب'**
  String get contactManager;

  /// No description provided for @termsOfService.
  ///
  /// In ar, this message translates to:
  /// **'شروط الخدمة'**
  String get termsOfService;

  /// No description provided for @version.
  ///
  /// In ar, this message translates to:
  /// **'بوابة عملاء محرك v{version}'**
  String version(String version);

  /// No description provided for @howAreWeDoing.
  ///
  /// In ar, this message translates to:
  /// **'كيف ترى مستوى خدمتنا؟'**
  String get howAreWeDoing;

  /// No description provided for @feedbackHelpGrow.
  ///
  /// In ar, this message translates to:
  /// **'رأيك يساعدنا في تنمية أعمالك بشكل أسرع.'**
  String get feedbackHelpGrow;

  /// No description provided for @anySpecificFeedback.
  ///
  /// In ar, this message translates to:
  /// **'هل لديك أي ملاحظات محددة؟ (اختياري)'**
  String get anySpecificFeedback;

  /// No description provided for @sendFeedback.
  ///
  /// In ar, this message translates to:
  /// **'إرسال الملاحظات'**
  String get sendFeedback;

  /// No description provided for @recentWins.
  ///
  /// In ar, this message translates to:
  /// **'إنجازات أخيرة'**
  String get recentWins;

  /// No description provided for @projectHealth.
  ///
  /// In ar, this message translates to:
  /// **'صحة المشروع'**
  String get projectHealth;

  /// No description provided for @healthScoreDisclaimer.
  ///
  /// In ar, this message translates to:
  /// **'بناءً على المهام، الموافقات، وتقدم الرحلة.'**
  String get healthScoreDisclaimer;

  /// No description provided for @dangerZone.
  ///
  /// In ar, this message translates to:
  /// **'منطقة الخطر'**
  String get dangerZone;

  /// No description provided for @deleteAccount.
  ///
  /// In ar, this message translates to:
  /// **'حذف الحساب'**
  String get deleteAccount;

  /// No description provided for @deleteAccountConfirm.
  ///
  /// In ar, this message translates to:
  /// **'هل أنت متأكد من حذف حسابك؟ سيؤدي هذا الإجراء إلى حذف جميع بياناتك نهائياً ولا يمكن التراجع عنه.'**
  String get deleteAccountConfirm;

  /// No description provided for @delete.
  ///
  /// In ar, this message translates to:
  /// **'حذف'**
  String get delete;

  /// No description provided for @campaignDetail.
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل الحملة'**
  String get campaignDetail;

  /// No description provided for @performance.
  ///
  /// In ar, this message translates to:
  /// **'الأداء'**
  String get performance;

  /// No description provided for @budgetUsed.
  ///
  /// In ar, this message translates to:
  /// **'الميزانية المستخدمة'**
  String get budgetUsed;

  /// No description provided for @supportHub.
  ///
  /// In ar, this message translates to:
  /// **'مركز الدعم'**
  String get supportHub;

  /// No description provided for @myTickets.
  ///
  /// In ar, this message translates to:
  /// **'تذاكري'**
  String get myTickets;

  /// No description provided for @newTicket.
  ///
  /// In ar, this message translates to:
  /// **'تذكرة جديدة'**
  String get newTicket;

  /// No description provided for @howCanWeHelp.
  ///
  /// In ar, this message translates to:
  /// **'كيف يمكننا مساعدتك؟'**
  String get howCanWeHelp;

  /// No description provided for @supportDescription.
  ///
  /// In ar, this message translates to:
  /// **'فريقنا متواجد دائماً لضمان سير نموك بسلاسة. اطرح سؤالاً أو أبلغ عن مشكلة وسنرد عليك في أقرب وقت.'**
  String get supportDescription;

  /// No description provided for @billingAndPayments.
  ///
  /// In ar, this message translates to:
  /// **'الفواتير والمدفوعات'**
  String get billingAndPayments;

  /// No description provided for @paymentHistory.
  ///
  /// In ar, this message translates to:
  /// **'سجل الدفع'**
  String get paymentHistory;

  /// No description provided for @currentPlan.
  ///
  /// In ar, this message translates to:
  /// **'الخطة الحالية'**
  String get currentPlan;

  /// No description provided for @nextRenewal.
  ///
  /// In ar, this message translates to:
  /// **'التجديد القادم'**
  String get nextRenewal;

  /// No description provided for @noInvoicesYet.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد فواتير بعد'**
  String get noInvoicesYet;

  /// No description provided for @history.
  ///
  /// In ar, this message translates to:
  /// **'السجل'**
  String get history;

  /// No description provided for @filesCenter.
  ///
  /// In ar, this message translates to:
  /// **'مركز الملفات'**
  String get filesCenter;

  /// No description provided for @campaigns.
  ///
  /// In ar, this message translates to:
  /// **'الحملات'**
  String get campaigns;

  /// No description provided for @budget.
  ///
  /// In ar, this message translates to:
  /// **'الميزانية'**
  String get budget;

  /// No description provided for @duration.
  ///
  /// In ar, this message translates to:
  /// **'المدة'**
  String get duration;

  /// No description provided for @teamNotes.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظات الفريق'**
  String get teamNotes;

  /// No description provided for @yourFeedback.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظاتك'**
  String get yourFeedback;

  /// No description provided for @viewDesign.
  ///
  /// In ar, this message translates to:
  /// **'عرض التصميم'**
  String get viewDesign;

  /// No description provided for @viewDocument.
  ///
  /// In ar, this message translates to:
  /// **'عرض المستند'**
  String get viewDocument;

  /// No description provided for @rejected.
  ///
  /// In ar, this message translates to:
  /// **'مرفوض'**
  String get rejected;

  /// No description provided for @approvalDetail.
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل الموافقة'**
  String get approvalDetail;

  /// No description provided for @description.
  ///
  /// In ar, this message translates to:
  /// **'الوصف'**
  String get description;

  /// No description provided for @reject.
  ///
  /// In ar, this message translates to:
  /// **'رفض'**
  String get reject;

  /// No description provided for @approvals.
  ///
  /// In ar, this message translates to:
  /// **'الموافقات'**
  String get approvals;

  /// No description provided for @ticketSubject.
  ///
  /// In ar, this message translates to:
  /// **'الموضوع'**
  String get ticketSubject;

  /// No description provided for @ticketDescription.
  ///
  /// In ar, this message translates to:
  /// **'الوصف'**
  String get ticketDescription;

  /// No description provided for @ticketCategory.
  ///
  /// In ar, this message translates to:
  /// **'الفئة'**
  String get ticketCategory;

  /// No description provided for @submitTicket.
  ///
  /// In ar, this message translates to:
  /// **'إرسال التذكرة'**
  String get submitTicket;

  /// No description provided for @highlightStat.
  ///
  /// In ar, this message translates to:
  /// **'إحصائية مميزة'**
  String get highlightStat;

  /// No description provided for @highlightContext.
  ///
  /// In ar, this message translates to:
  /// **'سياق الإحصائية'**
  String get highlightContext;

  /// No description provided for @nextMonthPriorities.
  ///
  /// In ar, this message translates to:
  /// **'أولويات الشهر القادم'**
  String get nextMonthPriorities;

  /// No description provided for @aiMagic.
  ///
  /// In ar, this message translates to:
  /// **'سحر الذكاء الاصطناعي'**
  String get aiMagic;

  /// No description provided for @googleIntegration.
  ///
  /// In ar, this message translates to:
  /// **'ربط جوجل'**
  String get googleIntegration;

  /// No description provided for @connectGoogle.
  ///
  /// In ar, this message translates to:
  /// **'ربط حساب جوجل'**
  String get connectGoogle;

  /// No description provided for @gscSiteUrl.
  ///
  /// In ar, this message translates to:
  /// **'رابط موقع GSC'**
  String get gscSiteUrl;

  /// No description provided for @ga4PropertyId.
  ///
  /// In ar, this message translates to:
  /// **'معرف GA4'**
  String get ga4PropertyId;

  /// No description provided for @teamManagement.
  ///
  /// In ar, this message translates to:
  /// **'إدارة الفريق'**
  String get teamManagement;

  /// No description provided for @inviteTeamMember.
  ///
  /// In ar, this message translates to:
  /// **'دعوة عضو فريق'**
  String get inviteTeamMember;

  /// No description provided for @accountManager.
  ///
  /// In ar, this message translates to:
  /// **'مدير حسابات'**
  String get accountManager;

  /// No description provided for @seoExpert.
  ///
  /// In ar, this message translates to:
  /// **'خبير سيو'**
  String get seoExpert;

  /// No description provided for @adsExpert.
  ///
  /// In ar, this message translates to:
  /// **'خبير إعلانات'**
  String get adsExpert;

  /// No description provided for @techExpert.
  ///
  /// In ar, this message translates to:
  /// **'مطور تقني'**
  String get techExpert;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
