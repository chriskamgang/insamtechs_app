import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/chapter.dart';
import '../models/course.dart';
import '../providers/auth_provider.dart';
import '../providers/course_provider.dart';
import '../providers/enrollment_provider.dart';
import '../services/logger_service.dart';
import 'enhanced_video_player_screen.dart';

class CourseDetailScreen extends StatefulWidget {
  final String courseTitle;
  final String instructor;
  final double rating;
  final String price;
  final String description;
  final String? slug;

  const CourseDetailScreen({
    super.key,
    required this.courseTitle,
    required this.instructor,
    required this.rating,
    required this.price,
    required this.description,
    this.slug,
  });

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isBookmarked = false;
  Course? _course;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isEnrolled = false;
  bool _checkingEnrollment = false;

  @override
  void initState() {
    super.initState();
    logger.logScreenStart('CourseDetailScreen', arguments: {
      'courseTitle': widget.courseTitle,
      'instructor': widget.instructor,
      'slug': widget.slug,
      'price': widget.price,
    });
    _tabController = TabController(length: 4, vsync: this);
    _loadCourseDetails();
  }

  Future<void> _loadCourseDetails() async {
    logger.logInfo('Loading course details', screen: 'CourseDetailScreen', data: {
      'slug': widget.slug,
    });

    if (widget.slug != null) {
      logger.logStateChange('CourseDetailScreen', 'idle', 'loading', screen: 'CourseDetailScreen');
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        logger.logApiCall('GET', '/courses/${widget.slug}');

        final course = await context.read<CourseProvider>().getCourseBySlug(
          widget.slug!,
        );

        if (course == null) {
          throw Exception('Course not found for slug: ${widget.slug}');
        }

        logger.logSuccess('Course loaded successfully', screen: 'CourseDetailScreen', data: {
          'courseId': course.id,
          'courseTitle': course.title,
          'chaptersCount': course.chapters.length,
        });

        logger.logStateChange('CourseDetailScreen', 'loading', 'loaded', screen: 'CourseDetailScreen');
        setState(() {
          _course = course;
          _isLoading = false;
        });

        // Check enrollment status
        logger.logInfo('Checking enrollment status', screen: 'CourseDetailScreen');
        await _checkEnrollmentStatus();
        logger.logSuccess('Course details loading completed', screen: 'CourseDetailScreen');
      } catch (e) {
        logger.logError(
          'Failed to load course details',
          screen: 'CourseDetailScreen',
          error: e,
          data: {'slug': widget.slug},
        );

        logger.logStateChange('CourseDetailScreen', 'loading', 'error', screen: 'CourseDetailScreen');
        setState(() {
          _errorMessage = 'Erreur lors du chargement du cours: $e';
          _isLoading = false;
        });
      }
    } else {
      logger.logWarning('No slug provided for course details', screen: 'CourseDetailScreen');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _checkEnrollmentStatus() async {
    final authProvider = context.read<AuthProvider>();

    if (!authProvider.isAuthenticated || _course == null) {
      logger.logInfo('Skipping enrollment check - user not authenticated or course null',
        screen: 'CourseDetailScreen',
        data: {
          'isAuthenticated': authProvider.isAuthenticated,
          'hasCourse': _course != null,
        });
      return;
    }

    final user = authProvider.user;
    if (user == null || user.id == null) {
      logger.logWarning('User or User ID is null', screen: 'CourseDetailScreen');
      return;
    }

    logger.logInfo('Starting enrollment status check', screen: 'CourseDetailScreen', data: {
      'userId': user.id!,
      'courseId': _course?.id,
    });

    logger.logStateChange('EnrollmentCheck', 'idle', 'checking', screen: 'CourseDetailScreen');
    setState(() {
      _checkingEnrollment = true;
    });

    try {
      final enrollmentProvider = context.read<EnrollmentProvider>();
      logger.logApiCall('GET', '/enrollment/check', requestData: {
        'courseId': _course?.id,
        'userId': user.id,
      });

      final isEnrolled = await enrollmentProvider.isEnrolledInCourse(
        _course?.id ?? 0,
        user.id!,
      );

      logger.logSuccess('Enrollment status checked', screen: 'CourseDetailScreen', data: {
        'isEnrolled': isEnrolled,
        'userId': user.id!,
        'courseId': _course?.id,
      });

      logger.logStateChange('EnrollmentCheck', 'checking', 'completed', screen: 'CourseDetailScreen');
      setState(() {
        _isEnrolled = isEnrolled;
        _checkingEnrollment = false;
      });
    } catch (e) {
      logger.logError('Failed to check enrollment status', screen: 'CourseDetailScreen', error: e, data: {
        'userId': user.id!,
        'courseId': _course?.id,
      });

      logger.logStateChange('EnrollmentCheck', 'checking', 'error', screen: 'CourseDetailScreen');
      setState(() {
        _checkingEnrollment = false;
      });
    }
  }

  @override
  void dispose() {
    logger.logScreenEnd('CourseDetailScreen');
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? _buildErrorWidget()
            : _buildContent(screenWidth, screenHeight),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(_errorMessage!, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              logger.logUserGesture('tap', 'retry_button', screen: 'CourseDetailScreen', data: {
                'errorMessage': _errorMessage,
              });
              _loadCourseDetails();
            },
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(double screenWidth, double screenHeight) {
    final course = _course;
    // Priorité aux données de l'API si disponibles, sinon fallback sur les paramètres
    final displayTitle = course?.title ?? widget.courseTitle;
    final displayInstructor = course?.instructor ?? widget.instructor;
    final displayRating = course?.rating ?? widget.rating;
    final displayPrice = course?.price ?? widget.price;
    final displayDescription = course?.courseDescription ?? widget.description;

    return CustomScrollView(
      slivers: [
        _buildSliverAppBar(screenWidth, screenHeight, displayTitle, course),
        SliverToBoxAdapter(
          child: Column(
            children: [
              _buildCourseInfo(
                screenWidth,
                displayTitle,
                displayInstructor,
                displayRating,
                displayPrice,
              ),
              _buildTabBar(screenWidth),
              _buildTabBarView(
                screenWidth,
                screenHeight,
                displayDescription,
                course,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSliverAppBar(
    double screenWidth,
    double screenHeight,
    String title,
    Course? course,
  ) {
    return SliverAppBar(
      expandedHeight: screenHeight * 0.3,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF1E3A8A),
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () {
          logger.logUserGesture('tap', 'back_button', screen: 'CourseDetailScreen');
          logger.logNavigation('CourseDetailScreen', 'previous_screen');
          Navigator.pop(context);
        },
      ),
      actions: [
        IconButton(
          icon: Icon(
            _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
            color: Colors.white,
          ),
          onPressed: () {
            logger.logUserGesture('tap', 'bookmark_button', screen: 'CourseDetailScreen', data: {
              'wasBookmarked': _isBookmarked,
              'courseTitle': widget.courseTitle,
            });
            logger.logStateChange('BookmarkStatus', _isBookmarked.toString(), (!_isBookmarked).toString(), screen: 'CourseDetailScreen');
            setState(() {
              _isBookmarked = !_isBookmarked;
            });
          },
        ),
        IconButton(
          icon: const Icon(Icons.share, color: Colors.white),
          onPressed: () {
            logger.logUserGesture('tap', 'share_button', screen: 'CourseDetailScreen', data: {
              'courseTitle': widget.courseTitle,
              'instructor': widget.instructor,
            });
            // TODO: Implement share functionality
          },
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
            ),
          ),
          child: course?.imageUrl != null
              ? Stack(
                  children: [
                    Image.network(
                      course?.imageUrl ?? '',
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildPlaceholderImage(title);
                      },
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.6),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              : _buildPlaceholderImage(title),
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage(String title) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.school, color: Colors.white, size: 80),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseInfo(
    double screenWidth,
    String title,
    String instructor,
    double rating,
    String price,
  ) {
    return Container(
      padding: EdgeInsets.all(screenWidth * 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: screenWidth * 0.06,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            instructor,
            style: TextStyle(
              fontSize: screenWidth * 0.04,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Row(
                children: [
                  Icon(
                    Icons.star,
                    color: Colors.amber,
                    size: screenWidth * 0.05,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    rating.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: screenWidth * 0.04,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '(${_course?.reviewCount ?? 0} avis)',
                    style: TextStyle(
                      fontSize: screenWidth * 0.035,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A8A),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$price€',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: screenWidth * 0.045,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_course != null) ...[
            Row(
              children: [
                _buildInfoChip(
                  Icons.video_library,
                  '${_course?.totalVideos ?? 0} vidéos',
                ),
                const SizedBox(width: 12),
                _buildInfoChip(Icons.schedule, _course?.duree ?? '0:00'),
                const SizedBox(width: 12),
                _buildInfoChip(
                  Icons.library_books,
                  '${_course?.totalChapters ?? 0} chapitres',
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _checkingEnrollment
                    ? null
                    : () {
                        logger.logUserGesture('tap', 'enrollment_button', screen: 'CourseDetailScreen', data: {
                          'isEnrolled': _isEnrolled,
                          'courseId': _course?.id,
                          'courseTitle': _course?.title ?? widget.courseTitle,
                          'buttonAction': _isEnrolled ? 'continue_course' : 'enroll',
                        });
                        _handleEnrollment();
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isEnrolled
                      ? Colors.green
                      : const Color(0xFF1E3A8A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _checkingEnrollment
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        _isEnrolled
                            ? 'CONTINUER LE COURS'
                            : 'S\'INSCRIRE MAINTENANT',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildTabBar(double screenWidth) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
      child: TabBar(
        controller: _tabController,
        labelColor: const Color(0xFF1E3A8A),
        unselectedLabelColor: Colors.grey[600],
        indicatorColor: const Color(0xFF1E3A8A),
        labelStyle: TextStyle(
          fontSize: screenWidth * 0.04,
          fontWeight: FontWeight.w600,
        ),
        tabs: const [
          Tab(text: 'Aperçu'),
          Tab(text: 'Curriculum'),
          Tab(text: 'Examen'),
          Tab(text: 'Avis'),
        ],
      ),
    );
  }

  Widget _buildTabBarView(
    double screenWidth,
    double screenHeight,
    String description,
    Course? course,
  ) {
    return SizedBox(
      height: screenHeight * 0.6,
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(screenWidth, description, course),
          _buildCurriculumTab(screenWidth, course),
          _buildExamTab(screenWidth, course),
          _buildReviewsTab(screenWidth, course),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(
    double screenWidth,
    String description,
    Course? course,
  ) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(screenWidth * 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Intro Video Section
          if (course?.hasIntroVideo == true) ...[
            Text(
              'Vidéo introductive',
              style: TextStyle(
                fontSize: screenWidth * 0.05,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Video thumbnail or placeholder
                  if (course?.imageUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        course?.imageUrl ?? '',
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: const Color(
                              0xFF1E3A8A,
                            ).withValues(alpha: 0.1),
                            child: const Center(
                              child: Icon(
                                Icons.video_library,
                                size: 48,
                                color: Color(0xFF1E3A8A),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  // Play button overlay
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      logger.logUserGesture('tap', 'intro_video_play_button', screen: 'CourseDetailScreen', data: {
                        'courseId': course?.id,
                        'videoUrl': course?.introVideoUrl,
                      });
                      if (course?.introVideoUrl != null) {
                        _playIntroVideo(course!.introVideoUrl!);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E3A8A).withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          Text(
            'Description',
            style: TextStyle(
              fontSize: screenWidth * 0.05,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description.isNotEmpty
                ? description
                : 'Aucune description disponible pour ce cours.',
            style: TextStyle(
              fontSize: screenWidth * 0.04,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
          if (course != null && course.isEnrolled && course.progress > 0) ...[
            const SizedBox(height: 24),
            Text(
              'Votre progression',
              style: TextStyle(
                fontSize: screenWidth * 0.05,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: course.progress / 100,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF1E3A8A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${course.progress.toStringAsFixed(0)}% terminé',
              style: TextStyle(
                fontSize: screenWidth * 0.035,
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCurriculumTab(double screenWidth, Course? course) {
    if (course == null || course.chapters.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.video_library_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Curriculum en cours de préparation',
              style: TextStyle(
                fontSize: screenWidth * 0.04,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(screenWidth * 0.05),
      itemCount: course.chapters.length,
      itemBuilder: (context, index) {
        final chapter = course.chapters[index];
        return _buildChapterCard(screenWidth, chapter, index + 1);
      },
    );
  }

  Widget _buildChapterCard(
    double screenWidth,
    Chapter chapter,
    int chapterNumber,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF1E3A8A),
          child: Text(
            chapterNumber.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          chapter.title,
          style: TextStyle(
            fontSize: screenWidth * 0.04,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          '${chapter.videoCount} vidéos • ${chapter.duree ?? "Durée non spécifiée"}',
          style: TextStyle(
            fontSize: screenWidth * 0.035,
            color: Colors.grey[600],
          ),
        ),
        children:
            chapter.videos
                ?.map((video) => _buildVideoTile(screenWidth, video))
                .toList() ??
            [],
      ),
    );
  }

  Widget _buildVideoTile(double screenWidth, Video video) {
    return ListTile(
      leading: Icon(
        video.isFree ? Icons.play_circle : Icons.lock,
        color: video.isFree ? Colors.green : Colors.grey,
      ),
      title: Text(video.title, style: TextStyle(fontSize: screenWidth * 0.035)),
      subtitle: Text(
        video.duration,
        style: TextStyle(fontSize: screenWidth * 0.03, color: Colors.grey[600]),
      ),
      trailing: video.isFree
          ? const Icon(Icons.play_arrow, color: Color(0xFF1E3A8A))
          : const Icon(Icons.lock, color: Colors.grey),
      onTap: video.isFree
          ? () {
              logger.logUserGesture('tap', 'video_tile', screen: 'CourseDetailScreen', data: {
                'videoTitle': video.title,
                'videoId': video.id,
                'isFree': video.isFree,
                'duration': video.duration,
              });
              _playVideo(video);
            }
          : () {
              logger.logUserGesture('tap', 'locked_video_tile', screen: 'CourseDetailScreen', data: {
                'videoTitle': video.title,
                'videoId': video.id,
                'isFree': video.isFree,
              });
            },
    );
  }

  Widget _buildExamTab(double screenWidth, Course? course) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(screenWidth * 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Exam info section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF1E3A8A).withValues(alpha: 0.1),
                  const Color(0xFF3B82F6).withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF1E3A8A).withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E3A8A),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.quiz,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Examen de Certification',
                            style: TextStyle(
                              fontSize: screenWidth * 0.045,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            'Validez vos connaissances et obtenez votre certificat',
                            style: TextStyle(
                              fontSize: screenWidth * 0.035,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Exam requirements
                Text(
                  'Prérequis pour l\'examen:',
                  style: TextStyle(
                    fontSize: screenWidth * 0.04,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),

                _buildRequirementItem(Icons.school, 'Compléter 100% du cours'),
                _buildRequirementItem(
                  Icons.video_library,
                  'Visionner toutes les vidéos',
                ),
                _buildRequirementItem(
                  Icons.quiz,
                  'Score minimum de 70% requis',
                ),
                _buildRequirementItem(Icons.timer, 'Durée: 60 minutes maximum'),

                const SizedBox(height: 24),

                if (_isEnrolled && course != null) ...[
                  // Progress check
                  if (course.progress >= 100) ...[
                    // Exam available
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.green.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Félicitations! Vous êtes éligible pour l\'examen',
                            style: TextStyle(
                              fontSize: screenWidth * 0.04,
                              fontWeight: FontWeight.w600,
                              color: Colors.green[700],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                logger.logUserGesture('tap', 'start_exam_button', screen: 'CourseDetailScreen', data: {
                                  'courseId': course.id,
                                  'courseTitle': course.title,
                                  'progress': course.progress,
                                });
                                _navigateToExam(course.id);
                              },
                              icon: const Icon(Icons.quiz),
                              label: const Text('COMMENCER L\'EXAMEN'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E3A8A),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // Progress required
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.orange.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.schedule, color: Colors.orange, size: 32),
                          const SizedBox(height: 8),
                          Text(
                            'Progression requise pour débloquer l\'examen',
                            style: TextStyle(
                              fontSize: screenWidth * 0.04,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange[700],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          LinearProgressIndicator(
                            value: course.progress / 100,
                            backgroundColor: Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.orange,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${course.progress.toStringAsFixed(0)}% / 100%',
                            style: TextStyle(
                              fontSize: screenWidth * 0.035,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ] else ...[
                  // Not enrolled
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.lock, color: Colors.grey[600], size: 32),
                        const SizedBox(height: 8),
                        Text(
                          'Inscription au cours requise',
                          style: TextStyle(
                            fontSize: screenWidth * 0.04,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          'Inscrivez-vous au cours pour accéder à l\'examen de certification',
                          style: TextStyle(
                            fontSize: screenWidth * 0.035,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Certificate info
          Text(
            'À propos du certificat',
            style: TextStyle(
              fontSize: screenWidth * 0.045,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),

          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.verified,
                        color: const Color(0xFF1E3A8A),
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Certificat numérique officiel',
                        style: TextStyle(
                          fontSize: screenWidth * 0.04,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Une fois l\'examen réussi avec un score minimum de 70%, vous recevrez un certificat numérique officiel que vous pourrez:',
                    style: TextStyle(
                      fontSize: screenWidth * 0.035,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 12),

                  _buildCertificateFeature(
                    Icons.download,
                    'Télécharger en PDF',
                  ),
                  _buildCertificateFeature(
                    Icons.share,
                    'Partager sur les réseaux sociaux',
                  ),
                  _buildCertificateFeature(
                    Icons.link,
                    'Vérifier l\'authenticité en ligne',
                  ),
                  _buildCertificateFeature(
                    Icons.work,
                    'Ajouter à votre CV professionnel',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF1E3A8A)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCertificateFeature(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.green),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToExam(int formationId) {
    logger.logNavigation('CourseDetailScreen', '/exam-detail', arguments: {
      'formationId': formationId,
      'formationTitle': _course?.title ?? widget.courseTitle,
    });

    Navigator.pushNamed(
      context,
      '/exam-detail',
      arguments: {
        'formationId': formationId,
        'formationTitle': _course?.title ?? widget.courseTitle,
      },
    );
  }

  Widget _buildReviewsTab(double screenWidth, Course? course) {
    if (course == null || course.reviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.star_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Aucun avis pour le moment',
              style: TextStyle(
                fontSize: screenWidth * 0.04,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Soyez le premier à donner votre avis !',
              style: TextStyle(
                fontSize: screenWidth * 0.035,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(screenWidth * 0.05),
      itemCount: course.reviews.length,
      itemBuilder: (context, index) {
        final review = course.reviews[index];
        return _buildReviewCard(screenWidth, review);
      },
    );
  }

  Widget _buildReviewCard(double screenWidth, CourseReview review) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF1E3A8A),
                  child: Text(
                    review.userName.isNotEmpty
                        ? review.userName[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.userName,
                        style: TextStyle(
                          fontSize: screenWidth * 0.04,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Row(
                        children: List.generate(5, (index) {
                          return Icon(
                            index < review.rating
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.amber,
                            size: 16,
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (review.comment.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                review.comment,
                style: TextStyle(
                  fontSize: screenWidth * 0.035,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _handleEnrollment() async {
    logger.logUserAction('handleEnrollment', screen: 'CourseDetailScreen', data: {
      'isEnrolled': _isEnrolled,
      'courseId': _course?.id,
      'courseTitle': _course?.title ?? widget.courseTitle,
    });

    if (_isEnrolled) {
      logger.logUserAction('continue_course_redirect', screen: 'CourseDetailScreen');
      // Navigate to course player/continue learning
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Redirection vers le lecteur de cours...'),
        ),
      );
    } else {
      // Check if user is authenticated
      final authProvider = context.read<AuthProvider>();
      if (!authProvider.isAuthenticated) {
        logger.logWarning('User not authenticated, redirecting to signin', screen: 'CourseDetailScreen');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez vous connecter pour vous inscrire'),
          ),
        );
        logger.logNavigation('CourseDetailScreen', '/signin');
        Navigator.pushNamed(context, '/signin');
        return;
      }

      // Show enrollment confirmation dialog
      logger.logInfo('Showing enrollment confirmation dialog', screen: 'CourseDetailScreen');
      final shouldEnroll = await _showEnrollmentDialog();
      if (shouldEnroll && mounted) {
        logger.logUserAction('enrollment_confirmed', screen: 'CourseDetailScreen');
        await _processEnrollment();
      } else {
        logger.logUserAction('enrollment_cancelled', screen: 'CourseDetailScreen');
      }
    }
  }

  Future<bool> _showEnrollmentDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Inscription au cours'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Cours: ${_course?.title ?? 'N/A'}'),
                  const SizedBox(height: 8),
                  Text('Prix: ${_course?.price ?? 0}€'),
                  const SizedBox(height: 16),
                  Text('Confirmer votre inscription à ce cours?'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                  ),
                  child: Text(
                    'S\'inscrire',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Future<void> _processEnrollment() async {
    if (_course == null) {
      logger.logError('Cannot process enrollment - course is null', screen: 'CourseDetailScreen');
      return;
    }

    final enrollmentProvider = context.read<EnrollmentProvider>();
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;

    if (user == null || user.id == null) {
      logger.logError('Cannot process enrollment - user or user ID is null', screen: 'CourseDetailScreen');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur: utilisateur non connecté')),
      );
      return;
    }

    logger.logInfo('Starting enrollment process', screen: 'CourseDetailScreen', data: {
      'userId': user.id!,
      'courseId': _course?.id,
      'courseTitle': _course?.title ?? widget.courseTitle,
    });

    logger.logStateChange('EnrollmentProcess', 'idle', 'processing', screen: 'CourseDetailScreen');
    setState(() {
      _checkingEnrollment = true; // Désactiver le bouton pendant le traitement
    });

    try {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Inscription en cours...')));

      logger.logApiCall('POST', '/enrollment/enroll', requestData: {
        'formationId': _course?.id ?? 0,
        'userId': user.id!,
      });

      final response = await enrollmentProvider.enrollInCourse(
        formationId: _course?.id ?? 0,
        userId: user?.id ?? 0,
      );

      if (mounted) {
        final message = response['message'] ?? 'Inscription réussie!';
        logger.logSuccess('Enrollment successful', screen: 'CourseDetailScreen', data: {
          'userId': user?.id,
          'courseId': _course?.id,
          'responseMessage': message,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        // Rafraîchir le statut d'inscription
        logger.logInfo('Refreshing enrollment status after successful enrollment', screen: 'CourseDetailScreen');
        await _checkEnrollmentStatus();
      }
    } catch (e) {
      logger.logError('Enrollment failed', screen: 'CourseDetailScreen', error: e, data: {
        'userId': user?.id,
        'courseId': _course?.id,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        logger.logStateChange('EnrollmentProcess', 'processing', 'completed', screen: 'CourseDetailScreen');
        setState(() {
          _checkingEnrollment = false; // Réactiver le bouton
        });
      }
    }
  }

  void _playVideo(Video video) {
    logger.logUserAction('play_video', screen: 'CourseDetailScreen', data: {
      'videoId': video.id,
      'videoTitle': video.title,
      'duration': video.duration,
      'isFree': video.isFree,
      'courseId': _course?.id,
    });

    // Vérifier si l'utilisateur est connecté pour les vidéos payantes
    if (!video.isFree && !_isEnrolled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vous devez être inscrit à ce cours pour accéder à cette vidéo'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Naviguer vers le lecteur vidéo
    if (video.url != null && video.url!.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EnhancedVideoPlayerScreen(
            video: video,
            title: video.title,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('URL de la vidéo non disponible'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _playIntroVideo(String videoUrl) {
    logger.logUserAction('play_intro_video', screen: 'CourseDetailScreen', data: {
      'videoUrl': videoUrl,
      'courseId': _course?.id,
      'courseTitle': _course?.title ?? widget.courseTitle,
    });

    // Créer un objet vidéo temporaire pour la vidéo d'intro
    final introVideo = Video(
      id: 0,
      chapitreId: 0,
      titre: {'fr': 'Vidéo introductive', 'en': 'Intro video'},
      url: videoUrl,
      duree: '0:00',
      gratuit: true,
    );

    // Utiliser le même lecteur vidéo
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EnhancedVideoPlayerScreen(
          video: introVideo,
          title: 'Vidéo introductive - ${_course?.title ?? widget.courseTitle}',
        ),
      ),
    );
  }
}
