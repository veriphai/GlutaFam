import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:eureka_app/models/searchableConcept.dart';
import '../models/app_colors.dart';

class SearchOverlay extends StatelessWidget {
  final AnimationController animationController;
  final Animation<double> slideAnimation;
  final Animation<double> fadeAnimation;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final String searchQuery;
  final List<SearchableChapter> matchedChapters;
  final List<SearchableTopic> matchedTopics;
  final List<SearchableConcept> matchedConcepts;
  final Function(String) onSearchChanged;
  final VoidCallback onClose;
  final Function(SearchableConcept) onConceptTap;
  final Function(SearchableTopic) onTopicTap;
  final Function(SearchableChapter) onChapterTap;

  const SearchOverlay({
    super.key,
    required this.animationController,
    required this.slideAnimation,
    required this.fadeAnimation,
    required this.searchController,
    required this.searchFocusNode,
    required this.searchQuery,
    required this.matchedChapters,
    required this.matchedTopics,
    required this.matchedConcepts,
    required this.onSearchChanged,
    required this.onClose,
    required this.onConceptTap,
    required this.onTopicTap,
    required this.onChapterTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animationController,
      builder: (context, child) {
        return Stack(
          children: [
            // Backdrop
            Positioned.fill(
              child: GestureDetector(
                onTap: onClose,
                child: Container(
                  color: Colors.black.withOpacity(0.35 * fadeAnimation.value),
                ),
              ),
            ),
            // Search container
            Positioned(
              top: slideAnimation.value * MediaQuery.of(context).size.height,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                color: AppColors.card,
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    children: [
                      // Search header
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: onClose,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.close,
                                  size: 18,
                                  color: AppColors.ink,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  searchFocusNode.requestFocus();
                                  if (!kIsWeb && Platform.isIOS) {
                                    Future.delayed(
                                        const Duration(milliseconds: 50), () {
                                      SystemChannels.textInput
                                          .invokeMethod('TextInput.show');
                                    });
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: AppColors.card,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.search,
                                        size: 18,
                                        color: AppColors.sub,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: TextField(
                                          controller: searchController,
                                          focusNode: searchFocusNode,
                                          autofocus: false,
                                          enableInteractiveSelection: true,
                                          textInputAction:
                                              TextInputAction.search,
                                          decoration: InputDecoration(
                                            hintText:
                                                "Search chapters, topics, lessons…",
                                            border: InputBorder.none,
                                            hintStyle: GoogleFonts.inter(
                                              fontSize: 15,
                                              color: AppColors.sub,
                                            ),
                                          ),
                                          style: GoogleFonts.inter(
                                            fontSize: 15,
                                            color: AppColors.ink,
                                          ),
                                          onChanged: onSearchChanged,
                                          onTap: () {
                                            if (!kIsWeb && Platform.isIOS) {
                                              searchFocusNode.requestFocus();
                                              Future.delayed(
                                                  const Duration(
                                                      milliseconds: 50), () {
                                                SystemChannels.textInput
                                                    .invokeMethod(
                                                        'TextInput.show');
                                              });
                                            }
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Search results
                      Expanded(
                        child: _buildSearchResults(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchResults() {
    if (searchQuery.trim().length < 2) {
      return Center(
        child: Text(
          "Type at least 2 characters to search",
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.sub,
          ),
        ),
      );
    }

    if (matchedChapters.isEmpty &&
        matchedTopics.isEmpty &&
        matchedConcepts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            "No matches found. Try a different keyword.",
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.sub,
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (matchedChapters.isNotEmpty) ...[
            Text(
              "CHAPTERS",
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.sub,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            ...matchedChapters
                .take(5)
                .map((chapter) => _buildSearchChapterItem(chapter)),
            const SizedBox(height: 20),
          ],
          if (matchedTopics.isNotEmpty) ...[
            Text(
              "TOPICS",
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.sub,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            ...matchedTopics
                .take(5)
                .map((topic) => _buildSearchTopicItem(topic)),
            const SizedBox(height: 20),
          ],
          if (matchedConcepts.isNotEmpty) ...[
            Text(
              "CONCEPTS",
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.sub,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            ...matchedConcepts
                .take(5)
                .map((concept) => _buildSearchConceptItem(concept)),
          ],
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildSearchConceptItem(SearchableConcept concept) {
    final color = _getSubjectColor(concept.subject);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    _getSubjectEmoji(concept.subject),
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      concept.conceptName,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "${concept.subject} • ${concept.chapterName} • ${concept.topicName}",
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.sub,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.access_time,
                            size: 16, color: AppColors.ink),
                        const SizedBox(width: 6),
                        Text("15 mins",
                            style: GoogleFonts.inter(
                                fontSize: 13, color: AppColors.ink)),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => onConceptTap(concept),
                          child: Container(
                            height: 40,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: Text(
                                'Start discussion',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 6,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: 0.0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchTopicItem(SearchableTopic topic) {
    final color = _getSubjectColor(topic.subject);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              _getSubjectEmoji(topic.subject),
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ),
        title: Text(
          topic.topicName,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          "${topic.chapterName} • ${topic.subject}",
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.sub,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: AppColors.sub,
        ),
        onTap: () => onTopicTap(topic),
      ),
    );
  }

  Widget _buildSearchChapterItem(SearchableChapter chapter) {
    final color = _getSubjectColor(chapter.subject);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              _getSubjectEmoji(chapter.subject),
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ),
        title: Text(
          chapter.chapterName,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          chapter.subject,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.sub,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: AppColors.sub,
        ),
        onTap: () => onChapterTap(chapter),
      ),
    );
  }

  Color _getSubjectColor(String subject) {
    const colors = {
      'mathematics': Color(0xFF1D4ED8),
      'physics': Color(0xFF0EA5E9),
      'chemistry': Color(0xFF10B981),
      'biology': Color(0xFF84CC16),
      'history': Color(0xFFF59E0B),
      'geography': Color(0xFF8B5CF6),
      'english': Color(0xFFEC4899),
      'science': Color(0xFF10B981),
      'maths': Color(0xFF1D4ED8),
    };
    return colors[subject.toLowerCase()] ?? AppColors.accent;
  }

  String _getSubjectEmoji(String subject) {
    switch (subject.toLowerCase()) {
      case 'mathematics':
      case 'maths':
        return "🧮";
      case 'physics':
        return "🧲";
      case 'chemistry':
        return "⚗️";
      case 'biology':
        return "🧬";
      case 'science':
        return "🔬";
      case 'history':
        return "🏺";
      case 'geography':
        return "🗺️";
      case 'english':
        return "📚";
      default:
        return "📘";
    }
  }
}
