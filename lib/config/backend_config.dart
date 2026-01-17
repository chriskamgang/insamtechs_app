/// Fichier de configuration pour l'URL du backend
///
/// PRODUCTION: Utilise le serveur de production https://admin.insamtechs.com
/// DEVELOPMENT: Pour utiliser un serveur local, changez USE_PRODUCTION en false
///             et configurez BACKEND_IP avec votre IP locale

// Configuration de l'environnement
const bool USE_PRODUCTION = true; // Mettre à false pour utiliser le serveur local

// Configuration serveur de production
const String PRODUCTION_URL = 'https://admin.insamtechs.com/api';

// Configuration serveur local (pour développement)
const String BACKEND_IP = '192.168.1.196';
const int BACKEND_PORT = 8001;

/// Fonction utilitaire pour obtenir l'URL complète du backend
String getBackendUrl() {
  if (USE_PRODUCTION) {
    return PRODUCTION_URL;
  } else {
    return 'http://$BACKEND_IP:$BACKEND_PORT/api';
  }
}
