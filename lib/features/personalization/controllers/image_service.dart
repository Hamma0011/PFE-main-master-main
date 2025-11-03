// services/image_service.dart
/*
class ImageService {
  static final ImageService _instance = ImageService._internal();
  factory ImageService() => _instance;
  ImageService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();

  /// Sélectionner une image depuis la galerie
  Future<File?> pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 512,
        maxHeight: 512,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      print('Erreur lors de la sélection d\'image: $e');
      return null;
    }
  }

  /// Télécharger une image vers Supabase Storage
  Future<String?> uploadProfileImage(File imageFile, String userId) async {
    try {
      // Générer un nom de fichier unique
      final String fileName =
          '${DateTime.now().millisecondsSinceEpoch}_$userId';
      final String filePath = 'profile_images/$fileName.jpg';

      // Lire les bytes du fichier
      final bytes = await imageFile.readAsBytes();

      // Télécharger l'image
      await _supabase.storage
          .from('profile_images')
          .uploadBinary(filePath, bytes,
              fileOptions: FileOptions(
                contentType: 'image/jpeg',
                upsert: true,
              ));

      // Récupérer l'URL publique
      final String imageUrl =
          _supabase.storage.from('profile_images').getPublicUrl(filePath);

      return imageUrl;
    } catch (e) {
      print('Erreur lors du téléchargement: $e');
      return null;
    }
  }

  /// Supprimer l'ancienne image de profil
  Future<void> deleteOldProfileImage(String imageUrl) async {
    try {
      if (imageUrl.isNotEmpty) {
        // Extraire le chemin du fichier depuis l'URL
        final uri = Uri.parse(imageUrl);
        final pathSegments = uri.pathSegments;
        if (pathSegments.length >= 3) {
          final filePath = pathSegments.sublist(2).join('/');
          await _supabase.storage.from('profile_images').remove([filePath]);
        }
      }
    } catch (e) {
      print('Erreur lors de la suppression de l\'ancienne image: $e');
    }
  }
}
*/
