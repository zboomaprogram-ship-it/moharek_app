// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Moharek';

  @override
  String welcomeMessage(String name) {
    return 'Welcome, $name';
  }

  @override
  String get goodMorning => 'Good morning';

  @override
  String get goodAfternoon => 'Good afternoon';

  @override
  String get goodEvening => 'Good evening';

  @override
  String goalLabel(String goal) {
    return 'Your goal: $goal';
  }

  @override
  String get growthProgress => 'Growth Progress';

  @override
  String get tasksCompleted => 'Tasks Completed';

  @override
  String get inProgress => 'In Progress';

  @override
  String get waitingApproval => 'Waiting Your Approval';

  @override
  String get completed => 'Completed';

  @override
  String get delayed => 'Delayed';

  @override
  String get todo => 'To Do';

  @override
  String get inReview => 'In Review';

  @override
  String get homeTab => 'Home';

  @override
  String get tasksTab => 'Tasks';

  @override
  String get resultsTab => 'Results';

  @override
  String get reportsTab => 'Reports';

  @override
  String get chatTab => 'Chat';

  @override
  String get journeyTitle => 'Growth Journey';

  @override
  String get auditStage => 'Audit';

  @override
  String get strategyStage => 'Strategy';

  @override
  String get setupStage => 'Setup';

  @override
  String get executionStage => 'Execution';

  @override
  String get optimizationStage => 'Optimization';

  @override
  String get resultsStage => 'Results';

  @override
  String get seoResults => 'SEO Results';

  @override
  String get adsResults => 'Ads Results';

  @override
  String get aiVisibility => 'AI Visibility';

  @override
  String get trustEngine => 'Trust Engine';

  @override
  String get keywords => 'Keywords';

  @override
  String get organicTraffic => 'Organic Traffic';

  @override
  String get leads => 'Leads';

  @override
  String get roas => 'ROAS';

  @override
  String get costPerLead => 'Cost per Lead';

  @override
  String get conversionRate => 'Conversion Rate';

  @override
  String get pendingApprovals => 'Pending Approvals';

  @override
  String get approve => 'Approve';

  @override
  String get requestChanges => 'Request Changes';

  @override
  String get approved => 'Approved';

  @override
  String get changesRequested => 'Changes Requested';

  @override
  String get newReport => 'New Report';

  @override
  String get weeklyReport => 'Weekly Report';

  @override
  String get monthlyReport => 'Monthly Report';

  @override
  String get downloadPdf => 'Download PDF';

  @override
  String get viewReport => 'View Report';

  @override
  String get reportReady => 'Report Ready';

  @override
  String get startVideoCall => 'Start Video Call';

  @override
  String get startVoiceCall => 'Start Voice Call';

  @override
  String get endCall => 'End Call';

  @override
  String get mute => 'Mute';

  @override
  String get unmute => 'Unmute';

  @override
  String get hideCamera => 'Hide Camera';

  @override
  String get showCamera => 'Show Camera';

  @override
  String get incomingCall => 'Incoming Call';

  @override
  String get accept => 'Accept';

  @override
  String get decline => 'Decline';

  @override
  String get callEnded => 'Call Ended';

  @override
  String callDuration(String duration) {
    return 'Call Duration: $duration';
  }

  @override
  String get holdToRecord => 'Hold to record a voice message';

  @override
  String get releaseToSend => 'Release to send';

  @override
  String get swipeToCancel => 'Slide to cancel';

  @override
  String get voiceMessage => 'Voice message';

  @override
  String get recording => 'Recording...';

  @override
  String get recordingCancelled => 'Recording cancelled';

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
  String get typeMessage => 'Type a message...';

  @override
  String get send => 'Send';

  @override
  String get micPermissionDenied =>
      'Please allow microphone access in settings';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get requestMeeting => 'Request Meeting';

  @override
  String get upcomingMeetings => 'Upcoming Meetings';

  @override
  String get joinMeeting => 'Join Meeting';

  @override
  String get meetingSummary => 'Meeting Summary';

  @override
  String get actionItems => 'Action Items';

  @override
  String get contracts => 'Contracts';

  @override
  String get signed => 'Signed';

  @override
  String get pendingSignature => 'Pending Signature';

  @override
  String get expired => 'Expired';

  @override
  String get invoices => 'Invoices';

  @override
  String get payNow => 'Pay Now';

  @override
  String get paid => 'Paid';

  @override
  String get overdue => 'Overdue';

  @override
  String get paymentSuccessful => 'Payment Successful ✅';

  @override
  String get files => 'Files';

  @override
  String get brandGuidelines => 'Brand Guidelines';

  @override
  String get contentPlan => 'Content Plan';

  @override
  String get campaignAssets => 'Campaign Assets';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get arabic => 'Arabic';

  @override
  String get english => 'English';

  @override
  String get notifications => 'Notifications';

  @override
  String get logout => 'Logout';

  @override
  String get profile => 'Profile';

  @override
  String get healthScore => 'Health Score';

  @override
  String get thriving => 'Thriving';

  @override
  String get growing => 'Growing';

  @override
  String get steady => 'Steady';

  @override
  String get needsAttention => 'Needs Attention';

  @override
  String get milestoneReached => 'Milestone Reached! 🎉';

  @override
  String get keywordPage1 => 'Keyword on Page 1!';

  @override
  String get trafficDoubled => 'Traffic Doubled! 🚀';

  @override
  String get leads100 => '100 Leads Reached 🏆';

  @override
  String get howAreYouFeeling => 'How are you feeling about your progress?';

  @override
  String get submitFeedback => 'Submit Feedback';

  @override
  String get maybeLater => 'Maybe Later';

  @override
  String get thankYouFeedback => 'Thank you for your feedback! ❤️';

  @override
  String get emptyTasks =>
      'Your team is prepping the first tasks — check back soon';

  @override
  String get emptyReports => 'Your first report will be ready at end of month';

  @override
  String get emptyResults =>
      'Data starts rolling in after 2 weeks of execution';

  @override
  String get emptyApprovals =>
      'Nothing waiting for your approval — enjoy the peace ☕';

  @override
  String get emptyChat => 'Say hi to your growth manager 👋';

  @override
  String get newSinceLastVisit => 'New since last visit';

  @override
  String tasksCompletedSince(int count) {
    return '$count tasks completed since last visit';
  }

  @override
  String trafficIncrease(int percent) {
    return 'Your traffic increased $percent% this week';
  }

  @override
  String itemNeedsApproval(int count) {
    return '$count items need approval';
  }

  @override
  String get onboardingWelcomeTitle => 'Welcome to Moharek';

  @override
  String get onboardingWelcomeSubtitle => 'Your growth journey starts now';

  @override
  String get onboardingBegin => 'Let\'s begin →';

  @override
  String get onboardingTeamTitle => 'These people are working for your growth';

  @override
  String get onboardingRoadmapTitle => 'Your plan for the next 90 days';

  @override
  String get onboardingGoalTitle => 'What is your #1 goal this year?';

  @override
  String get goalMoreLeads => 'More qualified leads';

  @override
  String get goalBrandAwareness => 'Stronger digital presence';

  @override
  String get goalMoreSales => 'Increase sales';

  @override
  String get goalImproveRanking => 'Improve search rankings';

  @override
  String get loginTitle => 'Welcome to Moharek';

  @override
  String get loginSubtitle => 'Sign in to access your client portal';

  @override
  String get emailLabel => 'Email Address';

  @override
  String get passwordLabel => 'Password';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get signIn => 'Sign In';

  @override
  String get loginError => 'Please enter your email and password.';

  @override
  String get unexpectedError =>
      'An unexpected error occurred. Please try again.';

  @override
  String get reportsTitle => 'Reports';

  @override
  String get growthStory => 'Growth Story';

  @override
  String get ready => 'Ready';

  @override
  String errorOccurred(String error) {
    return 'Error: $error';
  }

  @override
  String get quickActions => 'Quick Actions';

  @override
  String get performanceSnapshots => 'Performance Snapshots';

  @override
  String get projectGrowth => 'Project Growth';

  @override
  String get viewJourney => 'View Journey';

  @override
  String currentStage(String stage) {
    return 'Current Stage: $stage';
  }

  @override
  String focusedOn(String goal) {
    return 'Focused on: $goal';
  }

  @override
  String get contractAwaitingSignature => 'Contract Awaiting Your Signature';

  @override
  String get tapToReview => 'Tap to review and sign.';

  @override
  String get adSpend => 'Ad Spend';

  @override
  String get tasksTitle => 'Project Tasks';

  @override
  String get allTab => 'All';

  @override
  String get waitingMeTab => 'Waiting Me';

  @override
  String get general => 'General';

  @override
  String get noDate => 'No date';

  @override
  String get offlineMessage =>
      'No internet connection. Please check your network.';

  @override
  String get aiVisibilityTitle => 'AI Platform Visibility';

  @override
  String get noDataYet => 'No data yet';

  @override
  String resultsAppearLater(String type) {
    return '$type results will appear here once recorded';
  }

  @override
  String get notVisible => 'Not Visible';

  @override
  String get feedback => 'Feedback';

  @override
  String get cancel => 'Cancel';

  @override
  String get describeChanges => 'Describe the changes needed...';

  @override
  String get monthlyReports => 'Monthly Reports';

  @override
  String get taskUpdates => 'Task Updates';

  @override
  String get chatMessages => 'Chat Messages';

  @override
  String get milestonesWins => 'Milestones & Wins';

  @override
  String get adminDashboard => 'Admin Dashboard';

  @override
  String get clients => 'Clients';

  @override
  String get notify => 'Notify';

  @override
  String get reportsEmptyTitle => 'Waiting for your success story';

  @override
  String get reportsEmptyMsg =>
      'Growth reports will appear here soon. We are currently analyzing your data.';

  @override
  String get tasksEmptyTitle => 'Clear Path';

  @override
  String get tasksEmptyMsg =>
      'No current tasks require your attention. Our team is working in the background.';

  @override
  String get approvalsEmptyTitle => 'All Set';

  @override
  String get approvalsEmptyMsg => 'No pending approval requests at the moment.';

  @override
  String get genericEmptyTitle => 'No Data';

  @override
  String get genericEmptyMsg =>
      'This section will be updated once there is new activity.';

  @override
  String get welcomeTitle => 'Welcome.\nYour growth journey starts now.';

  @override
  String get thrilledPartner => 'We are thrilled to partner with you.';

  @override
  String get letsBegin => 'Let\'s begin';

  @override
  String get meetYourTeam => 'Meet Your Team';

  @override
  String get peopleWorkingForYou =>
      'These are the people working for you every day.';

  @override
  String get next => 'Next';

  @override
  String get roadmapTitle => 'Your 90-Day Roadmap';

  @override
  String get structuredPlan => 'A structured plan for success.';

  @override
  String get whatToExpect => 'What to Expect';

  @override
  String get trackResults => 'Track your results here — updated weekly';

  @override
  String get approveContent => 'Approve content before it goes live';

  @override
  String get talkGrowthManager => 'Talk to your growth manager anytime';

  @override
  String get almostDone => 'Almost done';

  @override
  String get tellUsGoal => 'Before we start, tell us one thing:';

  @override
  String get goalQuestion => 'What\'s your #1 goal this year?';

  @override
  String get finishEnterDashboard => 'Finish & Enter Dashboard';

  @override
  String get increaseSales => 'Increase Sales';

  @override
  String get improvePresence => 'Improve Online Presence';

  @override
  String get launchProduct => 'Launch New Product';

  @override
  String get rebrand => 'Rebrand';

  @override
  String get auditOnboarding => 'Audit & Onboarding';

  @override
  String get strategyDelivered => 'Strategy Delivered';

  @override
  String get firstCampaign => 'First Campaign Launched';

  @override
  String get optimizationReview => 'Optimization & Review';

  @override
  String get quarterlyReport => 'Quarterly Growth Report';

  @override
  String get growthJourney => 'Growth Journey';

  @override
  String get audit => 'Audit';

  @override
  String get strategy => 'Strategy';

  @override
  String get setup => 'Setup';

  @override
  String get execution => 'Execution';

  @override
  String get optimization => 'Optimization';

  @override
  String get results => 'Results';

  @override
  String get nextPhaseGrowth => 'Getting ready for the next phase of growth.';

  @override
  String get trackingProgress =>
      'Tracking progress and optimizing results for this phase.';

  @override
  String get noMessagesYet => 'No messages yet';

  @override
  String get sendMessageToStart => 'Send a message to get started!';

  @override
  String get photo => 'Photo';

  @override
  String get supportTeam => 'Support Team';

  @override
  String get tapToJoin => 'Tap to join';

  @override
  String uploadFailed(String error) {
    return 'Upload failed: $error';
  }

  @override
  String get amountDue => 'Amount Due';

  @override
  String get dueDate => 'Due Date';

  @override
  String get noInvoicesFound => 'No invoices found.';

  @override
  String get invoiceLabel => 'INVOICE';

  @override
  String get unpaid => 'Unpaid';

  @override
  String get pending => 'Pending';

  @override
  String get meetings => 'Meetings';

  @override
  String get request => 'Request';

  @override
  String get upcoming => 'Upcoming';

  @override
  String get pastMeetings => 'Past Meetings';

  @override
  String get noMeetingsScheduled => 'No meetings scheduled';

  @override
  String get tapRequestSchedule => 'Tap \'Request\' to schedule one.';

  @override
  String get whatDiscuss => 'What do you want to discuss?';

  @override
  String get pickDate => 'Pick Preferred Date';

  @override
  String get sendRequest => 'Send Request';

  @override
  String get ongoing => 'Ongoing';

  @override
  String get cancelled => 'Cancelled';

  @override
  String get topic => 'Topic';

  @override
  String get date => 'Date & Time';

  @override
  String get submit => 'Submit';

  @override
  String get requestSent => 'Request sent successfully! ✅';

  @override
  String get sendResetLink => 'Send Reset Link';

  @override
  String get checkInbox => 'Check your inbox!';

  @override
  String sentResetLinkTo(String email) {
    return 'We sent a password reset link to $email';
  }

  @override
  String get backToSignIn => 'Back to Sign In';

  @override
  String get resetPasswordDescription =>
      'Enter your email and we\'ll send you a reset link.';

  @override
  String get clientsManagement => 'Clients Management';

  @override
  String get newClient => 'New Client';

  @override
  String get noClientsFound => 'No clients found.';

  @override
  String get fillAllFields => 'Please fill in all fields';

  @override
  String get clientCreatedSuccess => '✅ Client created successfully!';

  @override
  String get fullName => 'Full Name';

  @override
  String get projectName => 'Project Name';

  @override
  String get createClient => 'Create Client';

  @override
  String get adminConsole => 'Admin Console';

  @override
  String get operations => 'Operations';

  @override
  String get activeClients => 'Active Clients';

  @override
  String pendingTasksCount(int count) {
    return '$count Pending Tasks';
  }

  @override
  String approvalsWaitingCount(int count) {
    return '$count Approvals Waiting';
  }

  @override
  String unsignedContractsCount(int count) {
    return '$count Unsigned Contracts';
  }

  @override
  String get allClients => 'All Clients';

  @override
  String get filter => 'Filter';

  @override
  String get uploadContract => 'Upload Contract';

  @override
  String get contractSentSuccess => 'Contract sent to client ✅';

  @override
  String get clickNewClientToAdd =>
      'Click \"New Client\" to add your first client.';

  @override
  String get photoLabel => 'Photo';

  @override
  String get fileLabel => 'File';

  @override
  String callStarted(String type) {
    return '$type started';
  }

  @override
  String get viewContract => 'View Contract';

  @override
  String get signContract => 'Sign Contract';

  @override
  String get contractSignedSuccess => 'Contract signed successfully! ✅';

  @override
  String get iAgree => 'I Agree';

  @override
  String signContractConfirmation(String title) {
    return 'By tapping \"I Agree\", you confirm that you have read and accept the terms of \"$title\".';
  }

  @override
  String get noPdfAvailable => 'No PDF available';

  @override
  String get filesTab => 'Files';

  @override
  String get noFilesFound => 'No files found';

  @override
  String get brandLabel => 'Brand';

  @override
  String get companyName => 'Company Name';

  @override
  String get contentLabel => 'Content';

  @override
  String get campaignsLabel => 'Campaigns';

  @override
  String get strategyLabel => 'Strategy';

  @override
  String get unknownUser => 'Unknown User';

  @override
  String get noCompany => 'No Company';

  @override
  String get failedToCreateClient => 'Failed to create client';

  @override
  String get uploadPdfInstructions =>
      'Upload the PDF to Supabase Storage first, then paste the URL here.';

  @override
  String get myProfile => 'My Profile';

  @override
  String get signOut => 'Sign Out';

  @override
  String get signOutConfirm => 'Are you sure you want to sign out?';

  @override
  String get accountSettings => 'Account Settings';

  @override
  String get personalInfo => 'Personal Information';

  @override
  String get companyProfile => 'Company Profile';

  @override
  String get billingInvoices => 'Billing & Invoices';

  @override
  String get appSettingsNotifications => 'App Settings & Notifications';

  @override
  String get support => 'Support';

  @override
  String get helpCenter => 'Help Center';

  @override
  String get contactManager => 'Contact Account Manager';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String version(String version) {
    return 'Moharek Client Portal v$version';
  }

  @override
  String get howAreWeDoing => 'How are we doing?';

  @override
  String get feedbackHelpGrow =>
      'Your feedback helps us grow your business faster.';

  @override
  String get anySpecificFeedback => 'Any specific feedback? (Optional)';

  @override
  String get sendFeedback => 'Send Feedback';

  @override
  String get recentWins => 'Recent Wins';

  @override
  String get projectHealth => 'Project Health';

  @override
  String get healthScoreDisclaimer =>
      'Based on tasks, approvals, and journey progress.';

  @override
  String get dangerZone => 'Danger Zone';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String get deleteAccountConfirm =>
      'Are you sure you want to delete your account? This action will permanently remove all your data and cannot be undone.';

  @override
  String get delete => 'Delete';

  @override
  String get campaignDetail => 'Campaign Details';

  @override
  String get performance => 'Performance';

  @override
  String get budgetUsed => 'Budget Used';

  @override
  String get supportHub => 'Support Hub';

  @override
  String get myTickets => 'My Tickets';

  @override
  String get newTicket => 'New Ticket';

  @override
  String get howCanWeHelp => 'How can we help?';

  @override
  String get supportDescription =>
      'Our team is here to ensure your growth journey is smooth. Ask a question or report an issue, and we\'ll get back to you shortly.';

  @override
  String get billingAndPayments => 'Billing & Payments';

  @override
  String get paymentHistory => 'Payment History';

  @override
  String get currentPlan => 'Current Plan';

  @override
  String get nextRenewal => 'Next Renewal';

  @override
  String get noInvoicesYet => 'No invoices yet';

  @override
  String get history => 'History';

  @override
  String get filesCenter => 'Files Center';

  @override
  String get campaigns => 'Campaigns';

  @override
  String get budget => 'Budget';

  @override
  String get duration => 'Duration';

  @override
  String get teamNotes => 'Team Notes';

  @override
  String get yourFeedback => 'Your Feedback';

  @override
  String get viewDesign => 'View Attachment';

  @override
  String get viewDocument => 'View Attachment';

  @override
  String get rejected => 'Rejected';

  @override
  String get approvalDetail => 'Approval Details';

  @override
  String get description => 'Description';

  @override
  String get reject => 'Reject';

  @override
  String get approvals => 'Approvals';

  @override
  String get ticketSubject => 'Subject';

  @override
  String get ticketDescription => 'Description';

  @override
  String get ticketCategory => 'Category';

  @override
  String get submitTicket => 'Submit Ticket';

  @override
  String get highlightStat => 'Highlight Stat';

  @override
  String get highlightContext => 'Highlight Context';

  @override
  String get nextMonthPriorities => 'Next Month Priorities';

  @override
  String get aiMagic => 'AI Magic';

  @override
  String get googleIntegration => 'Google Integration';

  @override
  String get connectGoogle => 'Connect Google Account';

  @override
  String get gscSiteUrl => 'GSC Site URL';

  @override
  String get ga4PropertyId => 'GA4 Property ID';

  @override
  String get teamManagement => 'Team Management';

  @override
  String get inviteTeamMember => 'Invite Team Member';

  @override
  String get accountManager => 'Account Manager';

  @override
  String get seoExpert => 'SEO Expert';

  @override
  String get adsExpert => 'Ads Expert';

  @override
  String get techExpert => 'Tech Expert';
}
