import 'package:flutter/material.dart';
import 'package:moharek_app/core/theme/app_theme.dart';
import 'package:moharek_app/shared/models/report.dart';
import 'package:moharek_app/shared/widgets/pdf_viewer_screen.dart';

class ReportViewerScreen extends StatefulWidget {
  final List<ProjectReport> reports;
  final int initialIndex;

  const ReportViewerScreen({
    super.key,
    required this.reports,
    this.initialIndex = 0,
  });

  @override
  State<ReportViewerScreen> createState() => _ReportViewerScreenState();
}

class _ReportViewerScreenState extends State<ReportViewerScreen> {
  late PageController _reportController;
  late int _currentReportIndex;

  @override
  void initState() {
    super.initState();
    _currentReportIndex = widget.initialIndex;
    _reportController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _reportController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          isAr ? 'قصة النمو' : 'Growth Story',
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: PageView.builder(
        controller: _reportController,
        onPageChanged: (index) => setState(() => _currentReportIndex = index),
        itemCount: widget.reports.length,
        itemBuilder: (context, index) {
          return _GrowthStoryStory(report: widget.reports[index]);
        },
      ),
    );
  }
}

class _GrowthStoryStory extends StatefulWidget {
  final ProjectReport report;
  const _GrowthStoryStory({required this.report});

  @override
  State<_GrowthStoryStory> createState() => _GrowthStoryStoryState();
}

class _GrowthStoryStoryState extends State<_GrowthStoryStory> {
  late PageController _storyController;
  int _currentStoryStep = 0;
  late int _totalSteps;

  @override
  void initState() {
    super.initState();
    _storyController = PageController();
    _totalSteps = 1 + // Hero
        (widget.report.managerNote != null ? 1 : 0) +
        (widget.report.nextMonthPriorities != null && widget.report.nextMonthPriorities!.isNotEmpty ? 1 : 0) +
        1; // PDF Call to action
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Stack(
      children: [
        PageView(
          controller: _storyController,
          onPageChanged: (i) => setState(() => _currentStoryStep = i),
          children: [
            _buildHeroSlide(isAr),
            if (widget.report.managerNote != null) _buildNoteSlide(isAr),
            if (widget.report.nextMonthPriorities != null && widget.report.nextMonthPriorities!.isNotEmpty) _buildPrioritiesSlide(isAr),
            _buildActionSlide(isAr),
          ],
        ),
        // Progress indicators at top
        Positioned(
          top: 10,
          left: 20,
          right: 20,
          child: Row(
            children: List.generate(_totalSteps, (index) => Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: index <= _currentStoryStep ? AppTheme.primaryGreen : Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            )),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroSlide(bool isAr) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black, AppTheme.primaryBlue.withValues(alpha: 0.2)],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primaryGreen.withValues(alpha: 0.1),
            ),
            child: const Icon(Icons.auto_awesome, color: AppTheme.primaryGreen, size: 48),
          ),
          const SizedBox(height: 40),
          Text(
            widget.report.titleAr ?? widget.report.title,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (widget.report.highlightStat != null)
            Text(
              widget.report.highlightStat!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.primaryGreen, fontSize: 40, fontWeight: FontWeight.w900),
            ),
          if (widget.report.highlightContext != null)
            Text(
              widget.report.highlightContext!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 18),
            ),
          const SizedBox(height: 60),
          const Icon(Icons.keyboard_arrow_down, color: Colors.white24),
          Text(isAr ? 'اسحب للأعلى أو لليمين للتفاصيل' : 'Swipe for details', style: const TextStyle(color: Colors.white24, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildNoteSlide(bool isAr) {
    return Container(
      padding: const EdgeInsets.all(30),
      color: Colors.black,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(backgroundColor: AppTheme.primaryBlue, radius: 15, child: Icon(Icons.person, size: 18, color: Colors.white)),
              const SizedBox(width: 12),
              Text(isAr ? 'رسالة من مدير الحساب' : 'Message from Manager', style: const TextStyle(color: Colors.grey, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            widget.report.managerNote ?? '',
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w500, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildPrioritiesSlide(bool isAr) {
    return Container(
      padding: const EdgeInsets.all(30),
      color: Colors.black,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isAr ? 'أولويات الشهر القادم' : 'Next Month Priorities',
            style: const TextStyle(color: AppTheme.primaryGreen, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),
          if (widget.report.nextMonthPriorities != null)
            ...widget.report.nextMonthPriorities!.map((p) => Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle_outline, color: AppTheme.primaryGreen, size: 24),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(p, style: const TextStyle(color: Colors.white, fontSize: 18)),
                  ),
                ],
              ),
            )).toList(),
        ],
      ),
    );
  }

  Widget _buildActionSlide(bool isAr) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black, AppTheme.primaryGreen.withValues(alpha: 0.1)],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.picture_as_pdf, color: Colors.redAccent, size: 64),
          const SizedBox(height: 24),
          Text(
            isAr ? 'التقرير الكامل جاهز' : 'Full Report Ready',
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            isAr ? 'تحليل تفصيلي لكل الأرقام والنتائج' : 'Detailed analysis of all metrics and results',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey, fontSize: 16),
          ),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PdfViewerScreen(
                      url: widget.report.fileUrl,
                      title: widget.report.title,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(isAr ? 'فتح ملف PDF' : 'Open PDF Report', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}
