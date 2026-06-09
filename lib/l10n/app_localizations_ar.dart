// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'محرك';

  @override
  String welcomeMessage(String name) {
    return 'مرحباً، $name';
  }

  @override
  String get goodMorning => 'صباح الخير';

  @override
  String get goodAfternoon => 'مساء الخير';

  @override
  String get goodEvening => 'مساء النور';

  @override
  String goalLabel(String goal) {
    return 'هدفك: $goal';
  }

  @override
  String get growthProgress => 'تقدم النمو';

  @override
  String get tasksCompleted => 'مهام منجزة';

  @override
  String get inProgress => 'جاري التنفيذ';

  @override
  String get waitingApproval => 'بانتظار موافقتك';

  @override
  String get completed => 'مكتمل';

  @override
  String get delayed => 'متأخر';

  @override
  String get todo => 'لم يبدأ';

  @override
  String get inReview => 'قيد المراجعة';

  @override
  String get homeTab => 'الرئيسية';

  @override
  String get tasksTab => 'المهام';

  @override
  String get resultsTab => 'النتائج';

  @override
  String get reportsTab => 'التقارير';

  @override
  String get chatTab => 'المحادثة';

  @override
  String get journeyTitle => 'رحلة النمو';

  @override
  String get auditStage => 'التحليل';

  @override
  String get strategyStage => 'الاستراتيجية';

  @override
  String get setupStage => 'الإعداد';

  @override
  String get executionStage => 'التنفيذ';

  @override
  String get optimizationStage => 'التحسين';

  @override
  String get resultsStage => 'النتائج';

  @override
  String get seoResults => 'نتائج SEO';

  @override
  String get adsResults => 'نتائج الإعلانات';

  @override
  String get aiVisibility => 'الظهور في AI';

  @override
  String get trustEngine => 'محرك الثقة';

  @override
  String get keywords => 'الكلمات المفتاحية';

  @override
  String get organicTraffic => 'الزيارات العضوية';

  @override
  String get leads => 'العملاء المحتملون';

  @override
  String get roas => 'العائد على الإعلان';

  @override
  String get costPerLead => 'تكلفة العميل';

  @override
  String get conversionRate => 'معدل التحويل';

  @override
  String get pendingApprovals => 'موافقات معلقة';

  @override
  String get approve => 'موافقة';

  @override
  String get requestChanges => 'طلب تعديلات';

  @override
  String get approved => 'تمت الموافقة';

  @override
  String get changesRequested => 'تم طلب تعديلات';

  @override
  String get newReport => 'تقرير جديد';

  @override
  String get weeklyReport => 'التقرير الأسبوعي';

  @override
  String get monthlyReport => 'التقرير الشهري';

  @override
  String get downloadPdf => 'تحميل PDF';

  @override
  String get viewReport => 'عرض التقرير';

  @override
  String get reportReady => 'التقرير جاهز';

  @override
  String get startVideoCall => 'بدء مكالمة فيديو';

  @override
  String get startVoiceCall => 'بدء مكالمة صوتية';

  @override
  String get endCall => 'إنهاء المكالمة';

  @override
  String get mute => 'كتم الصوت';

  @override
  String get unmute => 'إلغاء الكتم';

  @override
  String get hideCamera => 'إخفاء الكاميرا';

  @override
  String get showCamera => 'إظهار الكاميرا';

  @override
  String get incomingCall => 'مكالمة واردة';

  @override
  String get accept => 'قبول';

  @override
  String get decline => 'رفض';

  @override
  String get callEnded => 'انتهت المكالمة';

  @override
  String callDuration(String duration) {
    return 'مدة المكالمة: $duration';
  }

  @override
  String get holdToRecord => 'اضغط مطولاً للتسجيل';

  @override
  String get releaseToSend => 'ارفع إصبعك للإرسال';

  @override
  String get swipeToCancel => 'اسحب للإلغاء';

  @override
  String get voiceMessage => 'رسالة صوتية';

  @override
  String get recording => 'جاري التسجيل...';

  @override
  String get recordingCancelled => 'تم إلغاء التسجيل';

  @override
  String get connecting => 'جاري الاتصال...';

  @override
  String get ringing => 'يرن الآن...';

  @override
  String get accepted => 'تم القبول، جاري الانضمام...';

  @override
  String get callDeclined => 'تم رفض المكالمة';

  @override
  String get callTimeout => 'لا يوجد رد من الطرف الآخر';

  @override
  String get typeMessage => 'اكتب رسالة...';

  @override
  String get send => 'إرسال';

  @override
  String get micPermissionDenied =>
      'يرجى السماح بالوصول إلى الميكروفون في الإعدادات';

  @override
  String get today => 'اليوم';

  @override
  String get yesterday => 'أمس';

  @override
  String get requestMeeting => 'طلب اجتماع';

  @override
  String get upcomingMeetings => 'الاجتماعات القادمة';

  @override
  String get joinMeeting => 'الانضمام للاجتماع';

  @override
  String get meetingSummary => 'ملخص الاجتماع';

  @override
  String get actionItems => 'بنود العمل';

  @override
  String get contracts => 'العقود';

  @override
  String get signed => 'موقّع';

  @override
  String get pendingSignature => 'بانتظار التوقيع';

  @override
  String get expired => 'منتهي';

  @override
  String get invoices => 'الفواتير';

  @override
  String get payNow => 'ادفع الآن';

  @override
  String get paid => 'مدفوع';

  @override
  String get overdue => 'متأخر السداد';

  @override
  String get paymentSuccessful => 'تمت عملية الدفع بنجاح ✅';

  @override
  String get files => 'الملفات';

  @override
  String get brandGuidelines => 'دليل الهوية';

  @override
  String get contentPlan => 'خطة المحتوى';

  @override
  String get campaignAssets => 'مواد الحملة';

  @override
  String get settings => 'الإعدادات';

  @override
  String get language => 'اللغة';

  @override
  String get arabic => 'العربية';

  @override
  String get english => 'English';

  @override
  String get notifications => 'الإشعارات';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get profile => 'الملف الشخصي';

  @override
  String get healthScore => 'مؤشر الصحة';

  @override
  String get thriving => 'ممتاز';

  @override
  String get growing => 'في نمو';

  @override
  String get steady => 'مستقر';

  @override
  String get needsAttention => 'يحتاج اهتمام';

  @override
  String get milestoneReached => 'إنجاز جديد! 🎉';

  @override
  String get keywordPage1 => 'كلمتك المفتاحية وصلت للصفحة الأولى!';

  @override
  String get trafficDoubled => 'تضاعفت زياراتك! 🚀';

  @override
  String get leads100 => 'وصلت لـ 100 عميل محتمل 🏆';

  @override
  String get howAreYouFeeling => 'كيف تشعر تجاه تقدم نموك؟';

  @override
  String get submitFeedback => 'إرسال';

  @override
  String get maybeLater => 'لاحقاً';

  @override
  String get thankYouFeedback => 'شكراً لرأيك! ❤️';

  @override
  String get emptyTasks => 'فريقك يجهّز المهام الأولى — تابع قريباً';

  @override
  String get emptyReports => 'تقريرك الأول سيكون جاهزاً نهاية الشهر';

  @override
  String get emptyResults => 'البيانات تبدأ بعد أسبوعين من التنفيذ';

  @override
  String get emptyApprovals => 'لا يوجد شيء ينتظر موافقتك ☕';

  @override
  String get emptyChat => 'قل مرحباً لمدير نموك 👋';

  @override
  String get newSinceLastVisit => 'جديد منذ آخر زيارة';

  @override
  String tasksCompletedSince(int count) {
    return 'تم إنجاز $count مهام منذ آخر زيارة';
  }

  @override
  String trafficIncrease(int percent) {
    return 'زياراتك زادت $percent% هذا الأسبوع';
  }

  @override
  String itemNeedsApproval(int count) {
    return 'يوجد $count عنصر يحتاج موافقتك';
  }

  @override
  String get onboardingWelcomeTitle => 'مرحباً بك في محرك';

  @override
  String get onboardingWelcomeSubtitle => 'رحلة نموك تبدأ الآن';

  @override
  String get onboardingBegin => 'لنبدأ ←';

  @override
  String get onboardingTeamTitle => 'هؤلاء يعملون لأجل نموك';

  @override
  String get onboardingRoadmapTitle => 'خطتك للـ 90 يوم القادمة';

  @override
  String get onboardingGoalTitle => 'ما هو هدفك الأول لهذا العام؟';

  @override
  String get goalMoreLeads => 'زيادة العملاء المحتملين';

  @override
  String get goalBrandAwareness => 'تقوية الحضور الرقمي';

  @override
  String get goalMoreSales => 'زيادة المبيعات';

  @override
  String get goalImproveRanking => 'تحسين ترتيب الموقع';

  @override
  String get loginTitle => 'مرحباً بك في محرك';

  @override
  String get loginSubtitle => 'سجل الدخول للوصول إلى بوابة العملاء';

  @override
  String get emailLabel => 'البريد الإلكتروني';

  @override
  String get passwordLabel => 'كلمة المرور';

  @override
  String get forgotPassword => 'نسيت كلمة المرور؟';

  @override
  String get signIn => 'تسجيل الدخول';

  @override
  String get loginError => 'يرجى إدخال البريد الإلكتروني وكلمة المرور.';

  @override
  String get unexpectedError => 'حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى.';

  @override
  String get reportsTitle => 'التقارير';

  @override
  String get growthStory => 'قصة النمو';

  @override
  String get ready => 'جاهز';

  @override
  String errorOccurred(String error) {
    return 'حدث خطأ: $error';
  }

  @override
  String get quickActions => 'روابط سريعة';

  @override
  String get performanceSnapshots => 'لقطات الأداء';

  @override
  String get projectGrowth => 'نمو المشروع';

  @override
  String get viewJourney => 'عرض الرحلة';

  @override
  String currentStage(String stage) {
    return 'المرحلة الحالية: $stage';
  }

  @override
  String focusedOn(String goal) {
    return 'التركيز على: $goal';
  }

  @override
  String get contractAwaitingSignature => 'عقد بانتظار توقيعك';

  @override
  String get tapToReview => 'اضغط للمراجعة والتوقيع';

  @override
  String get adSpend => 'ميزانية الإعلانات';

  @override
  String get tasksTitle => 'مهام المشروع';

  @override
  String get allTab => 'الكل';

  @override
  String get waitingMeTab => 'بانتظاري';

  @override
  String get general => 'عام';

  @override
  String get noDate => 'بدون تاريخ';

  @override
  String get offlineMessage =>
      'لا يوجد اتصال بالإنترنت. يرجى التحقق من الشبكة.';

  @override
  String get aiVisibilityTitle => 'الظهور في منصات AI';

  @override
  String get noDataYet => 'لا توجد بيانات حالياً';

  @override
  String resultsAppearLater(String type) {
    return 'ستظهر نتائج $type هنا بمجرد تسجيلها';
  }

  @override
  String get notVisible => 'غير ظاهر';

  @override
  String get feedback => 'ملاحظات';

  @override
  String get cancel => 'إلغاء';

  @override
  String get describeChanges => 'صف التعديلات المطلوبة...';

  @override
  String get monthlyReports => 'التقارير الشهرية';

  @override
  String get taskUpdates => 'تحديثات المهام';

  @override
  String get chatMessages => 'رسائل المحادثة';

  @override
  String get milestonesWins => 'الإنجازات والنجاحات';

  @override
  String get adminDashboard => 'لوحة الإدارة';

  @override
  String get clients => 'العملاء';

  @override
  String get notify => 'التنبيهات';

  @override
  String get reportsEmptyTitle => 'بانتظار قصة نجاحك';

  @override
  String get reportsEmptyMsg =>
      'تقارير النمو ستظهر هنا قريباً. نحن نعمل حالياً على تحليل بياناتك وتحويلها إلى أرقام تعكس نجاحك.';

  @override
  String get tasksEmptyTitle => 'الطريق ممهد';

  @override
  String get tasksEmptyMsg =>
      'لا توجد مهام حالية تتطلب انتباهك. فريقنا يعمل في الخلفية لضمان سير الأمور بسلاسة.';

  @override
  String get approvalsEmptyTitle => 'كل شيء جاهز';

  @override
  String get approvalsEmptyMsg =>
      'لا توجد طلبات موافقة معلقة حالياً. سنقوم بإبلاغك فور حاجتنا لرأيك في الخطوات القادمة.';

  @override
  String get genericEmptyTitle => 'لا يوجد بيانات';

  @override
  String get genericEmptyMsg => 'هذا القسم سيتم تحديثه بمجرد وجود نشاط جديد.';

  @override
  String get welcomeTitle => 'مرحباً بك.\nرحلة نموك تبدأ الآن.';

  @override
  String get thrilledPartner => 'نحن متحمسون للشراكة معك.';

  @override
  String get letsBegin => 'لنبدأ';

  @override
  String get meetYourTeam => 'تعرف على فريقك';

  @override
  String get peopleWorkingForYou =>
      'هؤلاء هم الأشخاص الذين يعملون لأجلك كل يوم.';

  @override
  String get next => 'التالي';

  @override
  String get roadmapTitle => 'خارطة الطريق لـ 90 يوماً';

  @override
  String get structuredPlan => 'خطة مدروسة للنجاح.';

  @override
  String get whatToExpect => 'ماذا تتوقع';

  @override
  String get trackResults => 'تتبع نتائجك هنا - يتم تحديثها أسبوعياً';

  @override
  String get approveContent => 'وافق على المحتوى قبل نشره';

  @override
  String get talkGrowthManager => 'تحدث إلى مدير النمو الخاص بك في أي وقت';

  @override
  String get almostDone => 'شارفنا على الانتهاء';

  @override
  String get tellUsGoal => 'قبل أن نبدأ، أخبرنا شيئاً واحداً:';

  @override
  String get goalQuestion => 'ما هو هدفك الأول لهذا العام؟';

  @override
  String get finishEnterDashboard => 'إنهاء والدخول إلى لوحة التحكم';

  @override
  String get increaseSales => 'زيادة المبيعات';

  @override
  String get improvePresence => 'تحسين الظهور الرقمي';

  @override
  String get launchProduct => 'إطلاق منتج جديد';

  @override
  String get rebrand => 'إعادة بناء الهوية';

  @override
  String get auditOnboarding => 'التدقيق والتهيئة';

  @override
  String get strategyDelivered => 'تسليم الاستراتيجية';

  @override
  String get firstCampaign => 'إطلاق أول حملة';

  @override
  String get optimizationReview => 'التحسين والمراجعة';

  @override
  String get quarterlyReport => 'تقرير النمو الربع سنوي';

  @override
  String get growthJourney => 'رحلة النمو';

  @override
  String get audit => 'التدقيق';

  @override
  String get strategy => 'الاستراتيجية';

  @override
  String get setup => 'التجهيز';

  @override
  String get execution => 'التنفيذ';

  @override
  String get optimization => 'التحسين';

  @override
  String get results => 'النتائج';

  @override
  String get nextPhaseGrowth => 'الاستعداد للمرحلة القادمة من النمو.';

  @override
  String get trackingProgress => 'تتبع التقدم وتحسين النتائج لهذه المرحلة.';

  @override
  String get noMessagesYet => 'لا توجد رسائل بعد';

  @override
  String get sendMessageToStart => 'أرسل رسالة للبدء!';

  @override
  String get photo => 'صورة';

  @override
  String get supportTeam => 'فريق الدعم';

  @override
  String get tapToJoin => 'اضغط للانضمام';

  @override
  String uploadFailed(String error) {
    return 'فشل الرفع: $error';
  }

  @override
  String get amountDue => 'المبلغ المستحق';

  @override
  String get dueDate => 'تاريخ الاستحقاق';

  @override
  String get noInvoicesFound => 'لا توجد فواتير.';

  @override
  String get invoiceLabel => 'فاتورة';

  @override
  String get unpaid => 'غير مدفوعة';

  @override
  String get pending => 'معلقة';

  @override
  String get meetings => 'الاجتماعات';

  @override
  String get request => 'طلب';

  @override
  String get upcoming => 'القادمة';

  @override
  String get pastMeetings => 'الاجتماعات السابقة';

  @override
  String get noMeetingsScheduled => 'لا توجد اجتماعات مجدولة';

  @override
  String get tapRequestSchedule => 'اضغط على \'طلب\' لجدولة اجتماع.';

  @override
  String get whatDiscuss => 'ماذا تريد أن تناقش؟';

  @override
  String get pickDate => 'اختر التاريخ المفضل';

  @override
  String get sendRequest => 'إرسال الطلب';

  @override
  String get ongoing => 'جارٍ';

  @override
  String get cancelled => 'ملغي';

  @override
  String get topic => 'الموضوع';

  @override
  String get date => 'التاريخ والوقت';

  @override
  String get submit => 'إرسال';

  @override
  String get requestSent => 'تم إرسال الطلب بنجاح! ✅';

  @override
  String get sendResetLink => 'إرسال رابط إعادة التعيين';

  @override
  String get checkInbox => 'تحقق من بريدك الوارد!';

  @override
  String sentResetLinkTo(String email) {
    return 'لقد أرسلنا رابط إعادة تعيين كلمة المرور إلى $email';
  }

  @override
  String get backToSignIn => 'العودة إلى تسجيل الدخول';

  @override
  String get resetPasswordDescription =>
      'أدخل بريدك الإلكتروني وسنرسل لك رابطاً لإعادة التعيين.';

  @override
  String get clientsManagement => 'إدارة العملاء';

  @override
  String get newClient => 'عميل جديد';

  @override
  String get noClientsFound => 'لا يوجد عملاء.';

  @override
  String get fillAllFields => 'يرجى ملء جميع الحقول';

  @override
  String get clientCreatedSuccess => '✅ تم إنشاء العميل بنجاح!';

  @override
  String get fullName => 'الاسم الكامل';

  @override
  String get projectName => 'اسم المشروع';

  @override
  String get createClient => 'إنشاء عميل';

  @override
  String get adminConsole => 'لوحة الإدارة';

  @override
  String get operations => 'العمليات';

  @override
  String get activeClients => 'العملاء النشطون';

  @override
  String pendingTasksCount(int count) {
    return '$count مهام معلقة';
  }

  @override
  String approvalsWaitingCount(int count) {
    return '$count موافقات بانتظار المراجعة';
  }

  @override
  String unsignedContractsCount(int count) {
    return '$count عقود غير موقعة';
  }

  @override
  String get allClients => 'كل العملاء';

  @override
  String get filter => 'تصفية';

  @override
  String get uploadContract => 'رفع عقد';

  @override
  String get contractSentSuccess => 'تم إرسال العقد للعميل ✅';

  @override
  String get clickNewClientToAdd =>
      'اضغط على \"عميل جديد\" لإضافة أول عميل لك.';

  @override
  String get photoLabel => 'صورة';

  @override
  String get fileLabel => 'ملف';

  @override
  String callStarted(String type) {
    return '$type بدأت';
  }

  @override
  String get viewContract => 'عرض العقد';

  @override
  String get signContract => 'توقيع العقد';

  @override
  String get contractSignedSuccess => 'تم توقيع العقد بنجاح! ✅';

  @override
  String get iAgree => 'أنا أوافق';

  @override
  String signContractConfirmation(String title) {
    return 'بالنقر على \"أنا أوافق\"، فإنك تؤكد أنك قرأت وقبلت شروط \"$title\".';
  }

  @override
  String get noPdfAvailable => 'لا يوجد ملف PDF متاح';

  @override
  String get filesTab => 'الملفات';

  @override
  String get noFilesFound => 'لا توجد ملفات';

  @override
  String get brandLabel => 'الهوية';

  @override
  String get companyName => 'اسم الشركة';

  @override
  String get contentLabel => 'المحتوى';

  @override
  String get campaignsLabel => 'الحملات';

  @override
  String get strategyLabel => 'الاستراتيجية';

  @override
  String get unknownUser => 'مستخدم غير معروف';

  @override
  String get noCompany => 'لا توجد شركة';

  @override
  String get failedToCreateClient => 'فشل في إنشاء العميل';

  @override
  String get uploadPdfInstructions =>
      'قم برفع ملف PDF إلى Supabase Storage أولاً، ثم الصق الرابط هنا.';

  @override
  String get myProfile => 'ملفي الشخصي';

  @override
  String get signOut => 'تسجيل الخروج';

  @override
  String get signOutConfirm => 'هل أنت متأكد أنك تريد تسجيل الخروج؟';

  @override
  String get accountSettings => 'إعدادات الحساب';

  @override
  String get personalInfo => 'المعلومات الشخصية';

  @override
  String get companyProfile => 'ملف الشركة';

  @override
  String get billingInvoices => 'الفواتير والاشتراكات';

  @override
  String get appSettingsNotifications => 'إعدادات التطبيق والتنبيهات';

  @override
  String get support => 'الدعم الفني';

  @override
  String get helpCenter => 'مركز المساعدة';

  @override
  String get contactManager => 'التواصل مع مدير الحساب';

  @override
  String get termsOfService => 'شروط الخدمة';

  @override
  String version(String version) {
    return 'بوابة عملاء محرك v$version';
  }

  @override
  String get howAreWeDoing => 'كيف ترى مستوى خدمتنا؟';

  @override
  String get feedbackHelpGrow => 'رأيك يساعدنا في تنمية أعمالك بشكل أسرع.';

  @override
  String get anySpecificFeedback => 'هل لديك أي ملاحظات محددة؟ (اختياري)';

  @override
  String get sendFeedback => 'إرسال الملاحظات';

  @override
  String get recentWins => 'إنجازات أخيرة';

  @override
  String get projectHealth => 'صحة المشروع';

  @override
  String get healthScoreDisclaimer =>
      'بناءً على المهام، الموافقات، وتقدم الرحلة.';

  @override
  String get dangerZone => 'منطقة الخطر';

  @override
  String get deleteAccount => 'حذف الحساب';

  @override
  String get deleteAccountConfirm =>
      'هل أنت متأكد من حذف حسابك؟ سيؤدي هذا الإجراء إلى حذف جميع بياناتك نهائياً ولا يمكن التراجع عنه.';

  @override
  String get delete => 'حذف';

  @override
  String get campaignDetail => 'تفاصيل الحملة';

  @override
  String get performance => 'الأداء';

  @override
  String get budgetUsed => 'الميزانية المستخدمة';

  @override
  String get supportHub => 'مركز الدعم';

  @override
  String get myTickets => 'تذاكري';

  @override
  String get newTicket => 'تذكرة جديدة';

  @override
  String get howCanWeHelp => 'كيف يمكننا مساعدتك؟';

  @override
  String get supportDescription =>
      'فريقنا متواجد دائماً لضمان سير نموك بسلاسة. اطرح سؤالاً أو أبلغ عن مشكلة وسنرد عليك في أقرب وقت.';

  @override
  String get billingAndPayments => 'الفواتير والمدفوعات';

  @override
  String get paymentHistory => 'سجل الدفع';

  @override
  String get currentPlan => 'الخطة الحالية';

  @override
  String get nextRenewal => 'التجديد القادم';

  @override
  String get noInvoicesYet => 'لا توجد فواتير بعد';

  @override
  String get history => 'السجل';

  @override
  String get filesCenter => 'مركز الملفات';

  @override
  String get campaigns => 'الحملات';

  @override
  String get budget => 'الميزانية';

  @override
  String get duration => 'المدة';

  @override
  String get teamNotes => 'ملاحظات الفريق';

  @override
  String get yourFeedback => 'ملاحظاتك';

  @override
  String get viewDesign => 'عرض المرفق';

  @override
  String get viewDocument => 'عرض المرفق';

  @override
  String get rejected => 'مرفوض';

  @override
  String get approvalDetail => 'تفاصيل الموافقة';

  @override
  String get description => 'الوصف';

  @override
  String get reject => 'رفض';

  @override
  String get approvals => 'الموافقات';

  @override
  String get ticketSubject => 'الموضوع';

  @override
  String get ticketDescription => 'الوصف';

  @override
  String get ticketCategory => 'الفئة';

  @override
  String get submitTicket => 'إرسال التذكرة';

  @override
  String get highlightStat => 'إحصائية مميزة';

  @override
  String get highlightContext => 'سياق الإحصائية';

  @override
  String get nextMonthPriorities => 'أولويات الشهر القادم';

  @override
  String get aiMagic => 'سحر الذكاء الاصطناعي';

  @override
  String get googleIntegration => 'ربط جوجل';

  @override
  String get connectGoogle => 'ربط حساب جوجل';

  @override
  String get gscSiteUrl => 'رابط موقع GSC';

  @override
  String get ga4PropertyId => 'معرف GA4';

  @override
  String get teamManagement => 'إدارة الفريق';

  @override
  String get inviteTeamMember => 'دعوة عضو فريق';

  @override
  String get accountManager => 'مدير حسابات';

  @override
  String get seoExpert => 'خبير سيو';

  @override
  String get adsExpert => 'خبير إعلانات';

  @override
  String get techExpert => 'مطور تقني';
}
