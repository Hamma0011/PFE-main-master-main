import 'dart:typed_data';

import 'package:caferesto/utils/constants/colors.dart';
import 'package:caferesto/utils/constants/sizes.dart';
import 'package:caferesto/utils/helpers/helper_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../common/widgets/appbar/appbar.dart';
import '../../../../data/repositories/horaire/horaire_repository.dart';
import '../../../../utils/popups/loaders.dart';
import '../../../shop/controllers/etablissement_controller.dart';
import '../../../shop/controllers/product/horaire_controller.dart';
import '../../../shop/models/etablissement_model.dart';
import '../../../shop/models/horaire_model.dart';
import '../../../shop/models/jour_semaine.dart';
import '../../../shop/models/statut_etablissement_model.dart';
import '../../controllers/user_controller.dart';
import '../categories/widgets/category_form_widgets.dart';
import '../etablisment/gestion_horaires_screen.dart';

class EditEtablissementScreen extends StatefulWidget {
  final Etablissement etablissement;

  const EditEtablissementScreen({super.key, required this.etablissement});

  @override
  State<EditEtablissementScreen> createState() =>
      _EditEtablissementScreenState();
}

class _EditEtablissementScreenState extends State<EditEtablissementScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();

  final EtablissementController _etablissementController =
      Get.find<EtablissementController>();
  final UserController _userController = Get.find<UserController>();
  late final HoraireController _horaireController;

  bool _isLoading = false;
  bool _horairesLoaded = false;
  StatutEtablissement _selectedStatut = StatutEtablissement.en_attente;

  // Gestion de l'image
  XFile? _selectedImage;
  String? _currentImageUrl;
  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeHoraireController();
    _initializeForm();
    _loadHoraires();
    _initializeAnimation();
  }

  @override
  void dispose() {
    _animationController?.dispose();
    _nameController.dispose();
    _addressController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  void _initializeAnimation() {
    _animationController = AnimationController(
        duration: const Duration(milliseconds: 700), vsync: this);
    _fadeAnimation =
        CurvedAnimation(parent: _animationController!, curve: Curves.easeInOut);
    _animationController!.forward();
  }

  void _initializeHoraireController() {
    try {
      _horaireController = Get.find<HoraireController>();
    } catch (e) {
      _horaireController = Get.put(HoraireController(HoraireRepository()));
    }
  }

  void _initializeForm() {
    _nameController.text = widget.etablissement.name;
    _addressController.text = widget.etablissement.address;
    _latitudeController.text = widget.etablissement.latitude?.toString() ?? '';
    _longitudeController.text =
        widget.etablissement.longitude?.toString() ?? '';
    _selectedStatut = widget.etablissement.statut;
    _currentImageUrl = widget.etablissement.imageUrl;
  }

  // Sélection d'image
  Future<void> _pickMainImage() async {
    try {
      final picked = await ImagePicker()
          .pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (picked != null) {
        setState(() => _selectedImage = picked);
      }
    } catch (e) {
      TLoaders.errorSnackBar(message: 'Erreur sélection image: $e');
    }
  }

  Future<void> _loadHoraires() async {
    try {
      setState(() {
        _horairesLoaded = false;
      });

      await _horaireController.fetchHoraires(widget.etablissement.id!);

      setState(() {
        _horairesLoaded = true;
      });
    } catch (e) {
      setState(() {
        _horairesLoaded = true;
      });
    }
  }

  void _gererHoraires() async {
    try {
      final result = await Get.to(() => GestionHorairesEtablissement(
            etablissementId: widget.etablissement.id!,
            nomEtablissement: widget.etablissement.name,
            isCreation: false,
          ));

      if (result == true) {
        await _loadHoraires();
        TLoaders.successSnackBar(message: 'Horaires mis à jour avec succès');
      }
    } catch (e) {
      TLoaders.errorSnackBar(
          message: 'Impossible de modifier les horaires: $e');
    }
  }

  void _updateEtablissement() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Upload de l'image si une nouvelle est sélectionnée
      String? imageUrl = _currentImageUrl;
      if (_selectedImage != null) {
        imageUrl = await _etablissementController
            .uploadEtablissementImage(_selectedImage!);
        if (imageUrl == null) {
          TLoaders.errorSnackBar(
              message: 'Erreur lors de l\'upload de l\'image');
          setState(() => _isLoading = false);
          return;
        }
      }

      final updateData = <String, dynamic>{
        'name': _nameController.text.trim(),
        'address': _addressController.text.trim(),
        'image_url': imageUrl,
      };

      // Inclure le statut si l'utilisateur est Admin
      if (_userController.userRole == 'Admin') {
        updateData['statut'] = _selectedStatut;

        if (_latitudeController.text.isNotEmpty) {
          updateData['latitude'] = double.tryParse(_latitudeController.text);
        }
        if (_longitudeController.text.isNotEmpty) {
          updateData['longitude'] = double.tryParse(_longitudeController.text);
        }
      }

      final success = await _etablissementController.updateEtablissement(
        widget.etablissement.id,
        updateData,
      );

      if (success) {
        TLoaders.successSnackBar(
            message: 'Établissement mis à jour avec succès');
        Get.back(result: true);
      } else {
        TLoaders.errorSnackBar(message: 'Échec de la mise à jour');
      }
    } catch (e) {
      TLoaders.errorSnackBar(message: 'Erreur: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Section image
  Widget _buildImageSection(double width) {
    final previewHeight =
        (width >= 900) ? 220.0 : (width >= 600 ? 200.0 : 160.0);
    final previewWidth = double.infinity;
    final borderRadius = BorderRadius.circular(12.0);

    Widget mainImageWidget() {
      if (_selectedImage != null) {
        return FutureBuilder<Uint8List?>(
          future: _selectedImage!.readAsBytes(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return ClipRRect(
                borderRadius: borderRadius,
                child: Image.memory(snapshot.data!,
                    fit: BoxFit.cover,
                    width: previewWidth,
                    height: previewHeight),
              );
            } else {
              return SizedBox(
                height: previewHeight,
                child: const Center(child: CircularProgressIndicator()),
              );
            }
          },
        );
      } else if (_currentImageUrl != null && _currentImageUrl!.isNotEmpty) {
        return ClipRRect(
          borderRadius: borderRadius,
          child: Image.network(_currentImageUrl!,
              fit: BoxFit.cover, width: previewWidth, height: previewHeight,
              errorBuilder: (context, error, stackTrace) {
            return Container(
              height: previewHeight,
              color: Colors.grey.shade200,
              child:
                  const Icon(Icons.broken_image, color: Colors.grey, size: 40),
            );
          }),
        );
      } else {
        return SizedBox(
          height: previewHeight,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_photo_alternate_outlined,
                    color: Colors.grey, size: 40),
                const SizedBox(height: 8),
                Text(
                  'Ajouter une image',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        );
      }
    }

    return CategoryFormCard(
      children: [
        const Text('Image de l\'établissement',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _pickMainImage,
          child: Container(
            width: previewWidth,
            height: previewHeight,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: borderRadius,
            ),
            child: Stack(
              children: [
                mainImageWidget(),
                if (_selectedImage != null ||
                    (_currentImageUrl != null && _currentImageUrl!.isNotEmpty))
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child:
                          const Icon(Icons.edit, color: Colors.white, size: 16),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Cliquez pour changer l\'image',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  // Section informations de base
  Widget _buildBasicInfoSection(double width) {
    final isWide = width >= 900;

    return CategoryFormCard(children: [
      const Text('Informations de base',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      const SizedBox(height: 16),
      TextFormField(
        controller: _nameController,
        decoration: const InputDecoration(
            labelText: 'Nom de l\'établissement *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.business_outlined)),
        validator: (v) =>
            v == null || v.isEmpty ? 'Veuillez entrer le nom' : null,
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _addressController,
        decoration: const InputDecoration(
            labelText: 'Adresse complète *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.location_on_outlined)),
        maxLines: isWide ? 4 : 3,
        validator: (v) =>
            v == null || v.isEmpty ? 'Veuillez entrer l\'adresse' : null,
      ),
    ]);
  }

  // Section coordonnées GPS
  Widget _buildCoordinatesSection(double width) {
    return CategoryFormCard(children: [
      const Text('Coordonnées GPS',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _latitudeController,
              decoration: const InputDecoration(
                labelText: 'Latitude',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.explore_outlined),
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextFormField(
              controller: _longitudeController,
              decoration: const InputDecoration(
                labelText: 'Longitude',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.explore_outlined),
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      Text(
        'Les coordonnées GPS sont optionnelles',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ]);
  }

  // Section statut (pour Admin seulement)
  Widget _buildStatutSection() {
    if (_userController.userRole != 'Admin') {
      return const SizedBox();
    }

    return CategoryFormCard(
      children: [
        const Text('Statut de l\'établissement',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            return ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: constraints.maxWidth
              ),
              child: DropdownButtonFormField<StatutEtablissement>(
                isExpanded: true,
                value: _selectedStatut,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Statut',
                  prefixIcon: Icon(Icons.info_outline),
                ),
                items: StatutEtablissement.values.map((statut) {
                  return DropdownMenuItem<StatutEtablissement>(
                    value: statut,
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: _getStatutColor(statut),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                            child: Text(
                          _getStatutText(statut),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        )),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (newStatut) {
                  if (newStatut != null) {
                    setState(() {
                      _selectedStatut = newStatut;
                    });
                  }
                },
              ),
            );
          }
        ),
      ],
    );
  }

  // Section rôle utilisateur
  Widget _buildUserRoleSection() {
    final user = _userController.user.value;

    return CategoryFormCard(
      children: [
        const Text('Rôle utilisateur',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          children: [
            const Icon(Icons.person, color: Colors.blue),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Connecté en tant que :',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    user.role,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.fullName,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Section horaires
  Widget _buildHorairesSection(double width) {
    final isWide = width >= 900;

    return CategoryFormCard(
      children: [
        const Text('Horaires d\'ouverture',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        if (!_horairesLoaded)
          const Center(child: CircularProgressIndicator())
        else if (!_horaireController.hasHoraires.value)
          _buildAucunHoraire()
        else
          _buildHorairesPreview(),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _gererHoraires,
          icon: const Icon(Icons.schedule),
          label: Text(_horaireController.hasHoraires.value
              ? 'Modifier les horaires'
              : 'Configurer les horaires'),
          style: ElevatedButton.styleFrom(
            minimumSize: Size(double.infinity, isWide ? 55 : 50),
            backgroundColor: Colors.orange[50],
            foregroundColor: Colors.orange[800],
          ),
        ),
      ],
    );
  }

  // Méthodes helper pour les horaires
  Widget _buildAucunHoraire() {
    return const Column(
      children: [
        Icon(Icons.access_time, size: 48, color: Colors.grey),
        SizedBox(height: 8),
        Text(
          'Aucun horaire configuré',
          style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
        ),
        SizedBox(height: 4),
        Text(
          'Configurez les horaires d\'ouverture de votre établissement',
          style: TextStyle(color: Colors.grey, fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildHorairesPreview() {
    final dark = THelperFunctions.isDarkMode(context);
    final horairesOuverts = _horaireController.horaires
        .where((h) => h.estOuvert && h.isValid)
        .toList();
    horairesOuverts.sort((a, b) => a.jour.index.compareTo(b.jour.index));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_horaireController.nombreJoursOuverts} jours ouverts',
          style: TextStyle(
            color: Colors.green[700],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        ...horairesOuverts.take(3).map(_buildHorairePreview).toList(),
        if (horairesOuverts.length > 3)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '... et ${horairesOuverts.length - 3} autres jours',
              style: const TextStyle(
                  fontStyle: FontStyle.italic, color: Colors.grey),
            ),
          ),
      ],
    );
  }

  Widget _buildHorairePreview(Horaire horaire) {
    final dark = THelperFunctions.isDarkMode(context);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: dark ? AppColors.eerieBlack : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                _getJourAbrege(horaire.jour),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  horaire.jour.valeur,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  '${horaire.ouverture} - ${horaire.fermeture}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
          Icon(
            Icons.check_circle,
            color: Colors.green[400],
            size: 20,
          ),
        ],
      ),
    );
  }

  // Méthodes helper pour le statut
  String _getStatutText(StatutEtablissement statut) {
    switch (statut) {
      case StatutEtablissement.approuve:
        return 'Approuvé ✓';
      case StatutEtablissement.rejete:
        return 'Rejeté ✗';
      case StatutEtablissement.en_attente:
        return 'En attente de validation';
    }
  }

  Color _getStatutColor(StatutEtablissement statut) {
    switch (statut) {
      case StatutEtablissement.approuve:
        return Colors.green;
      case StatutEtablissement.rejete:
        return Colors.red;
      case StatutEtablissement.en_attente:
        return Colors.orange;
    }
  }

  String _getJourAbrege(JourSemaine jour) {
    switch (jour) {
      case JourSemaine.lundi:
        return 'LUN';
      case JourSemaine.mardi:
        return 'MAR';
      case JourSemaine.mercredi:
        return 'MER';
      case JourSemaine.jeudi:
        return 'JEU';
      case JourSemaine.vendredi:
        return 'VEN';
      case JourSemaine.samedi:
        return 'SAM';
      case JourSemaine.dimanche:
        return 'DIM';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TAppBar(
        title: const Text('Modifier l\'établissement'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _updateEtablissement,
            tooltip: 'Enregistrer',
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation!,
        child: LayoutBuilder(builder: (context, constraints) {
          final width = constraints.maxWidth;
          final isMobile = width < 600;
          final isTablet = width >= 600 && width < 900;
          final isDesktop = width >= 900;

          final content = ConstrainedBox(
            constraints: BoxConstraints(
                maxWidth:
                    isDesktop ? 1100 : (isTablet ? 760 : double.infinity)),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Responsive two-column layout for tablet/desktop
                    if (isDesktop || isTablet)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left column: image + user role + statut
                          Expanded(
                            flex: 5,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildImageSection(width),
                                const SizedBox(
                                    height: AppSizes.spaceBtwSections),
                                _buildUserRoleSection(),
                                const SizedBox(
                                    height: AppSizes.spaceBtwSections),
                                _buildStatutSection(),
                                const SizedBox(
                                    height: AppSizes.spaceBtwSections),
                                _buildHorairesSection(width),
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),
                          // Right column: basic info + coordinates + submit
                          Expanded(
                            flex: 6,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildBasicInfoSection(width),
                                const SizedBox(
                                    height: AppSizes.spaceBtwSections),
                                _buildCoordinatesSection(width),
                                const SizedBox(
                                    height: AppSizes.spaceBtwSections),
                                // Submit area
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: _isLoading
                                            ? null
                                            : _updateEtablissement,
                                        icon: const Icon(Iconsax.save_2),
                                        label: const Text(
                                            'Enregistrer les modifications'),
                                        style: ElevatedButton.styleFrom(
                                          minimumSize:
                                              const Size.fromHeight(55),
                                          backgroundColor: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () => Get.back(),
                                        icon: const Icon(Iconsax.close_circle),
                                        label: const Text('Annuler'),
                                        style: OutlinedButton.styleFrom(
                                          minimumSize:
                                              const Size.fromHeight(55),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Les champs marqués d\'un * sont requis.',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    else
                      // Mobile single-column layout
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildImageSection(width),
                          const SizedBox(height: AppSizes.spaceBtwSections),
                          _buildUserRoleSection(),
                          const SizedBox(height: AppSizes.spaceBtwSections),
                          _buildStatutSection(),
                          const SizedBox(height: AppSizes.spaceBtwSections),
                          _buildBasicInfoSection(width),
                          const SizedBox(height: AppSizes.spaceBtwSections),
                          _buildCoordinatesSection(width),
                          const SizedBox(height: AppSizes.spaceBtwSections),
                          _buildHorairesSection(width),
                          const SizedBox(height: AppSizes.spaceBtwSections),
                          ElevatedButton.icon(
                            onPressed: _isLoading ? null : _updateEtablissement,
                            icon: const Icon(Iconsax.save_2),
                            label: const Text('Enregistrer les modifications'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size.fromHeight(55),
                              backgroundColor: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: () => Get.back(),
                            icon: const Icon(Iconsax.close_circle),
                            label: const Text('Annuler'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(55),
                            ),
                          ),
                          const SizedBox(height: 30),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          );

          return Center(
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 12 : 20, vertical: 16),
              child: content,
            ),
          );
        }),
      ),
    );
  }
}
