import '../models/course.dart';
import '../models/chapter.dart';

class MockData {
  // Mock Categories
  static List<CourseCategory> getMockCategories() {
    return [
      CourseCategory(
        id: 1,
        intitule: {'fr': 'Développement Web', 'en': 'Web Development'},
        type: 1,
        date: '2024-01-15',
        slug: 'developpement-web',
      ),
      CourseCategory(
        id: 2,
        intitule: {'fr': 'Mobile App', 'en': 'Mobile App'},
        type: 1,
        date: '2024-01-20',
        slug: 'mobile-app',
      ),
      CourseCategory(
        id: 3,
        intitule: {'fr': 'Data Science', 'en': 'Data Science'},
        type: 1,
        date: '2024-01-25',
        slug: 'data-science',
      ),
      CourseCategory(
        id: 4,
        intitule: {'fr': 'Design UI/UX', 'en': 'UI/UX Design'},
        type: 1,
        date: '2024-02-01',
        slug: 'design-ui-ux',
      ),
      CourseCategory(
        id: 5,
        intitule: {'fr': 'Cybersécurité', 'en': 'Cybersecurity'},
        type: 1,
        date: '2024-02-05',
        slug: 'cybersecurite',
      ),
    ];
  }

  // Mock Videos
  static List<Video> getMockVideos(int chapitreId) {
    return [
      Video(
        id: 1,
        chapitreId: chapitreId,
        titre: {'fr': 'Introduction au sujet', 'en': 'Introduction to the topic'},
        description: {'fr': 'Vue d\'ensemble du chapitre', 'en': 'Chapter overview'},
        url: 'https://example.com/video1.mp4',
        duree: '15:30',
        gratuit: true,
      ),
      Video(
        id: 2,
        chapitreId: chapitreId,
        titre: {'fr': 'Concepts avancés', 'en': 'Advanced concepts'},
        description: {'fr': 'Approfondissement des notions', 'en': 'Deep dive into concepts'},
        url: 'https://example.com/video2.mp4',
        duree: '22:45',
        gratuit: false,
      ),
      Video(
        id: 3,
        chapitreId: chapitreId,
        titre: {'fr': 'Exercices pratiques', 'en': 'Practical exercises'},
        description: {'fr': 'Mise en pratique', 'en': 'Hands-on practice'},
        url: 'https://example.com/video3.mp4',
        duree: '18:20',
        gratuit: false,
      ),
    ];
  }

  // Mock Chapters
  static List<Chapter> getMockChapters(int formationId) {
    return [
      Chapter(
        id: 1,
        formationId: formationId,
        titre: {'fr': 'Introduction générale', 'en': 'General Introduction'},
        description: {'fr': 'Bases du sujet', 'en': 'Subject basics'},
        duree: '45:00',
        gratuit: true,
        videos: getMockVideos(1),
      ),
      Chapter(
        id: 2,
        formationId: formationId,
        titre: {'fr': 'Concepts fondamentaux', 'en': 'Fundamental Concepts'},
        description: {'fr': 'Théorie essentielle', 'en': 'Essential theory'},
        duree: '60:30',
        gratuit: false,
        videos: getMockVideos(2),
      ),
      Chapter(
        id: 3,
        formationId: formationId,
        titre: {'fr': 'Applications pratiques', 'en': 'Practical Applications'},
        description: {'fr': 'Projets réels', 'en': 'Real projects'},
        duree: '75:15',
        gratuit: false,
        videos: getMockVideos(3),
      ),
      Chapter(
        id: 4,
        formationId: formationId,
        titre: {'fr': 'Projet final', 'en': 'Final Project'},
        description: {'fr': 'Consolidation des acquis', 'en': 'Consolidating knowledge'},
        duree: '90:45',
        gratuit: false,
        videos: getMockVideos(4),
      ),
    ];
  }

  // Mock Reviews
  static List<CourseReview> getMockReviews() {
    return [
      CourseReview(
        id: 1,
        userId: 1,
        formationId: 1,
        note: 5,
        commentaire: 'Excellente formation, très complète !',
        user: ReviewUser(id: 1, nom: 'Martin', prenom: 'Jean'),
      ),
      CourseReview(
        id: 2,
        userId: 2,
        formationId: 1,
        note: 4,
        commentaire: 'Très bon contenu, instructeur compétent.',
        user: ReviewUser(id: 2, nom: 'Dubois', prenom: 'Marie'),
      ),
      CourseReview(
        id: 3,
        userId: 3,
        formationId: 1,
        note: 5,
        commentaire: 'Je recommande vivement cette formation !',
        user: ReviewUser(id: 3, nom: 'Lemaire', prenom: 'Paul'),
      ),
    ];
  }

  // Mock Courses
  static List<Course> getMockCourses() {
    return [
      Course(
        id: 1,
        categorieId: 1,
        typeFormationId: 1,
        intitule: {'fr': 'Développement Flutter Avancé', 'en': 'Advanced Flutter Development'},
        description: {'fr': 'Maîtrisez Flutter pour créer des applications mobiles performantes', 'en': 'Master Flutter to create high-performance mobile applications'},
        prix: {'fr': '99€', 'en': '99€'},
        duree: '40:30:00',
        date: '2024-01-15',
        slug: 'developpement-flutter-avance',
        etat: 1,
        img: 'https://via.placeholder.com/300x200/1E3A8A/FFFFFF?text=Flutter',
        categorie: getMockCategories()[0],
        chapitres: getMockChapters(1),
        avis: getMockReviews(),
        lien: 'https://example.com/intro-flutter.mp4',
      ),
      Course(
        id: 2,
        categorieId: 2,
        typeFormationId: 1,
        intitule: {'fr': 'React Native pour Débutants', 'en': 'React Native for Beginners'},
        description: {'fr': 'Apprenez React Native de zéro pour développer des apps cross-platform', 'en': 'Learn React Native from scratch to develop cross-platform apps'},
        prix: {'fr': '79€', 'en': '79€'},
        duree: '25:15:00',
        date: '2024-01-20',
        slug: 'react-native-debutants',
        etat: 1,
        img: 'https://via.placeholder.com/300x200/61DAFB/000000?text=React+Native',
        categorie: getMockCategories()[1],
        chapitres: getMockChapters(2),
        avis: getMockReviews(),
        lien: 'https://example.com/intro-react-native.mp4',
      ),
      Course(
        id: 3,
        categorieId: 1,
        typeFormationId: 1,
        intitule: {'fr': 'Vue.js 3 Masterclass', 'en': 'Vue.js 3 Masterclass'},
        description: {'fr': 'Développez des applications web modernes avec Vue.js 3', 'en': 'Develop modern web applications with Vue.js 3'},
        prix: {'fr': '89€', 'en': '89€'},
        duree: '35:45:00',
        date: '2024-01-25',
        slug: 'vuejs-3-masterclass',
        etat: 1,
        img: 'https://via.placeholder.com/300x200/4FC08D/FFFFFF?text=Vue.js',
        categorie: getMockCategories()[0],
        chapitres: getMockChapters(3),
        avis: getMockReviews(),
        lien: 'https://example.com/intro-vuejs.mp4',
      ),
      Course(
        id: 4,
        categorieId: 3,
        typeFormationId: 1,
        intitule: {'fr': 'Machine Learning avec Python', 'en': 'Machine Learning with Python'},
        description: {'fr': 'Explorez l\'intelligence artificielle et le machine learning', 'en': 'Explore artificial intelligence and machine learning'},
        prix: {'fr': '129€', 'en': '129€'},
        duree: '50:20:00',
        date: '2024-02-01',
        slug: 'machine-learning-python',
        etat: 1,
        img: 'https://via.placeholder.com/300x200/3776AB/FFFFFF?text=Python+ML',
        categorie: getMockCategories()[2],
        chapitres: getMockChapters(4),
        avis: getMockReviews(),
        lien: 'https://example.com/intro-ml.mp4',
      ),
      Course(
        id: 5,
        categorieId: 4,
        typeFormationId: 1,
        intitule: {'fr': 'Design System avec Figma', 'en': 'Design System with Figma'},
        description: {'fr': 'Créez des design systems cohérents et professionnels', 'en': 'Create consistent and professional design systems'},
        prix: {'fr': '69€', 'en': '69€'},
        duree: '20:10:00',
        date: '2024-02-05',
        slug: 'design-system-figma',
        etat: 1,
        img: 'https://via.placeholder.com/300x200/F24E1E/FFFFFF?text=Figma',
        categorie: getMockCategories()[3],
        chapitres: getMockChapters(5),
        avis: getMockReviews(),
        lien: 'https://example.com/intro-figma.mp4',
      ),
      Course(
        id: 6,
        categorieId: 5,
        typeFormationId: 1,
        intitule: {'fr': 'Sécurité des Applications Web', 'en': 'Web Application Security'},
        description: {'fr': 'Sécurisez vos applications contre les vulnérabilités courantes', 'en': 'Secure your applications against common vulnerabilities'},
        prix: {'fr': '149€', 'en': '149€'},
        duree: '45:30:00',
        date: '2024-02-10',
        slug: 'securite-applications-web',
        etat: 1,
        img: 'https://via.placeholder.com/300x200/FF6B6B/FFFFFF?text=Security',
        categorie: getMockCategories()[4],
        chapitres: getMockChapters(6),
        avis: getMockReviews(),
        lien: 'https://example.com/intro-security.mp4',
      ),
    ];
  }

  // Mock Featured Courses
  static List<Course> getFeaturedCourses() {
    return getMockCourses().take(4).toList();
  }

  // Mock Courses by Category
  static List<Course> getCoursesByCategory(String categorySlug) {
    final courses = getMockCourses();
    switch (categorySlug) {
      case 'developpement-web':
        return [courses[0], courses[2]];
      case 'mobile-app':
        return [courses[0], courses[1]];
      case 'data-science':
        return [courses[3]];
      case 'design-ui-ux':
        return [courses[4]];
      case 'cybersecurite':
        return [courses[5]];
      default:
        return courses;
    }
  }

  // Mock Course by Slug
  static Course? getCourseBySlug(String slug) {
    return getMockCourses().firstWhere(
      (course) => course.slug == slug,
      orElse: () => getMockCourses().first,
    );
  }

  // Mock Search Results
  static List<Course> searchCourses(String query) {
    if (query.isEmpty) return getMockCourses();

    final queryLower = query.toLowerCase();
    return getMockCourses().where((course) {
      return course.title.toLowerCase().contains(queryLower) ||
             course.courseDescription.toLowerCase().contains(queryLower) ||
             course.categoryName.toLowerCase().contains(queryLower);
    }).toList();
  }
}