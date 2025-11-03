import 'package:caferesto/features/personalization/screens/brands/widgets/etablissement_subtitle.dart';
import 'package:caferesto/features/personalization/screens/brands/widgets/no_results_state.dart';
import 'package:caferesto/utils/popups/loaders.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../common/widgets/appbar/appbar.dart';
import '../../../../data/repositories/etablissement/etablissement_repository.dart';
import '../../../../features/personalization/controllers/user_controller.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../../shop/controllers/etablissement_controller.dart';
import '../../../shop/models/etablissement_model.dart';
import '../../../shop/models/statut_etablissement_model.dart';
import 'add_brand_screen.dart';
import 'edit_brand_screen.dart';
import 'widgets/etablissement_image.dart';

class MonEtablissementScreen extends StatefulWidget {
  const MonEtablissementScreen({super.key});

  @override
  State<MonEtablissementScreen> createState() => _MonEtablissementScreenState();
}

class _MonEtablissementScreenState extends State<MonEtablissementScreen> {
  late final EtablissementController _controller;
  late final UserController userController;
  String _userRole = '';

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  // Initialisation
  void _initializeControllers() {
    if (!Get.isRegistered<UserController>()) {
      Get.put(UserController());
    }
    userController = Get.find<UserController>();

    // Initialiser EtablissementController
    if (!Get.isRegistered<EtablissementController>()) {
      Get.put(EtablissementController(EtablissementRepository()));
    }
    _controller = Get.find<EtablissementController>();

    _userRole = userController.userRole;

    // Charger les données après un court délai
    Future.delayed(const Duration(milliseconds: 100), () {
      _chargerEtablissements();
    });
  }

  // Chargement
  Future<void> _chargerEtablissements() async {
    try {
      _controller.isLoading.value = true;
      final user = userController.user.value;

      if (_userRole == 'Gérant' && user.id.isNotEmpty) {
        await _controller.fetchEtablissementsByOwner(user.id);
      } else if (_userRole == 'Admin') {
        await _controller.getTousEtablissements();
      }
    } catch (e) {
      print('Erreur chargement établissements: $e');
      TLoaders.errorSnackBar(
          title: 'Erreur', message: 'Impossible de charger les établissements');
    } finally {
      _controller.isLoading.value = false;
    }
  }

  // Suppression avec confirmation
  Future<void> _deleteEtablissement(Etablissement etablissement) async {
    if (etablissement.id == null) {
      TLoaders.errorSnackBar(message: 'ID établissement manquant');
      return;
    }

    try {
      final success = await _controller.deleteEtablissement(etablissement.id!);
      if (success) {
        // La liste se met à jour automatiquement via les observables
        print('Établissement supprimé avec succès');
      }
    } catch (e) {
      print('Erreur suppression: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return TAppBar(
      title: Text(
        _userRole == 'Admin'
            ? "Gestion des établissements"
            : "Mon établissement",
      ),
    );
  }

  Widget _buildBody() {
    return Obx(() {
      if (_controller.isLoading.value) return _buildLoadingState();

      if (_userRole != 'Admin' && _userRole != 'Gérant') {
        return _buildAccesRefuse();
      }

      final data = _controller.filteredEtablissements;
      final hasResults = data.isNotEmpty;

      return RefreshIndicator(
        onRefresh: _chargerEtablissements,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),

            // Filtres stylés avec ChoiceChip
            if (_userRole == 'Admin') ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    _buildFilterChip('Récents'),
                    _buildFilterChip('Approuvés'),
                    _buildFilterChip('Rejetés'),
                    _buildFilterChip('En attente'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            const SizedBox(height: 12),

            // Liste des établissements
            Expanded(
              child: hasResults
                  ? ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: data.length,
                      itemBuilder: (context, index) {
                        final e = data[index];
                        return _buildEtablissementCard(e, index);
                      },
                    )
                  : _userRole == 'Gérant'
                      ? _buildEmptyState() // <- Message "Vous n'avez pas d'établissement"
                      : NoResultsState(
                          currentFilter: _controller.selectedFilter.value),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildFilterChip(String label) {
    return Obx(() {
      final isSelected = _controller.selectedFilter.value == label;
      return ChoiceChip(
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
        selected: isSelected,
        selectedColor: Colors.blue,
        backgroundColor: Colors.grey[200],
        onSelected: (_) => _controller.selectedFilter.value = label,
        elevation: 2,
        pressElevation: 3,
      );
    });
  }

  Widget _buildFloatingActionButton() {
    return Obx(() {
      // Si chargement => ne rien afficher pour éviter glitch visuel
      if (_controller.isLoading.value) return const SizedBox();

      // Gérant ne peut créer qu'un seul établissement
      if (_userRole == 'Gérant' && _controller.etablissements.isNotEmpty) {
        return const SizedBox();
      }

      // Afficher le bouton si le gérant n’a pas encore créé d’établissement
      if (_userRole == 'Gérant') {
        return FloatingActionButton(
          onPressed: () async {
            final result = await Get.to(() => AddEtablissementScreen());
            if (result == true) {
              await _chargerEtablissements();
            }
          },
          backgroundColor: Colors.blue.shade600,
          foregroundColor: Colors.white,
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: const Icon(Icons.add, size: 28),
        );
      }

      return const SizedBox();
    });
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            "Chargement des établissements...",
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildAccesRefuse() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.block, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            "Accès refusé",
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            "Cette fonctionnalité est réservée aux Gérants et Administrateurs",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          const SizedBox(height: 16),
          Text(
            "Votre rôle: $_userRole",
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.blue),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.business_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            _userRole == 'Admin'
                ? "Aucun établissement trouvé"
                : "Vous n'avez pas d'établissement",
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            _userRole == 'Admin'
                ? "Les établissements apparaîtront ici une fois créés"
                : "Commencez par créer votre établissement",
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          if (_userRole == 'Gérant') ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                final result = await Get.to(() => AddEtablissementScreen());
                if (result == true) _chargerEtablissements();
              },
              icon: const Icon(Icons.add),
              label: const Text("Créer mon établissement"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEtablissementCard(Etablissement etablissement, int index) {
    final dark = THelperFunctions.isDarkMode(context);
    final isRecent = etablissement.statut == StatutEtablissement.en_attente &&
        _controller.isRecentEtablissement(etablissement);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: dark ? AppColors.eerieBlack : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child: Stack(children: [
        ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          leading: EtablissementImage(etablissement: etablissement),
          title: Text(etablissement.name,
              style:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          subtitle: EtablissementSubtitle(etablissement: etablissement),
          trailing: _buildStatutBadge(etablissement.statut),
          onTap: () => _showEtablissementOptions(etablissement),
        ),
        if (isRecent)
          Positioned(
            top: 8,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.shade600,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                "Nouveau",
                style: TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
      ]),
    );
  }

  Widget _buildStatutBadge(StatutEtablissement statut) {
    final (color, text) = _getStatutInfo(statut);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3))),
      child: Text(text,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }

  (Color, String) _getStatutInfo(StatutEtablissement statut) {
    switch (statut) {
      case StatutEtablissement.en_attente:
        return (Colors.orange, "En attente");
      case StatutEtablissement.approuve:
        return (Colors.green, "Approuvé");
      case StatutEtablissement.rejete:
        return (Colors.red, "Rejeté");
    }
  }

  void _showEtablissementOptions(Etablissement etablissement) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildBottomSheetContent(etablissement),
    );
  }

  Widget _buildBottomSheetContent(Etablissement etablissement) {
    final dark = THelperFunctions.isDarkMode(context);
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dark ? AppColors.eerieBlack : AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 5))
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildBottomSheetHeader(etablissement),
          const SizedBox(height: 16),
          _buildActionButtons(etablissement),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[600],
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                child: const Text("Annuler"),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSheetHeader(Etablissement etablissement) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Afficher l'image réelle
          if (etablissement.imageUrl != null &&
              etablissement.imageUrl!.isNotEmpty)
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: NetworkImage(etablissement.imageUrl!),
                  fit: BoxFit.cover,
                ),
              ),
            )
          else
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.blue.shade50,
              ),
              child:
                  Icon(Icons.business, color: Colors.blue.shade600, size: 30),
            ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(etablissement.name,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(etablissement.address,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                _buildStatutBadge(etablissement.statut),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Etablissement etablissement) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              child: ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  final result = await Get.to(() =>
                      EditEtablissementScreen(etablissement: etablissement));
                  if (result == true) _chargerEtablissements();
                },
                icon: const Icon(Icons.edit_outlined, size: 20),
                label: const Text("Éditer"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade50,
                  foregroundColor: Colors.blue.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ),
          if (_userRole == 'Admin' || _userRole == 'Gérant')
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(left: 8),
                child: ElevatedButton.icon(
                  onPressed: () => _showDeleteConfirmationDialog(etablissement),
                  icon: const Icon(Icons.delete_outline, size: 20),
                  label: const Text("Supprimer"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade50,
                    foregroundColor: Colors.red.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog(Etablissement etablissement) {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.amber),
              SizedBox(width: 12),
              Text("Confirmer la suppression")
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  "Êtes-vous sûr de vouloir supprimer l'établissement \"${etablissement.name}\" ?",
                  style: const TextStyle(fontSize: 15)),
              const SizedBox(height: 8),
              Text(
                "Cette action est irréversible.",
                style: TextStyle(
                    fontSize: 14,
                    color: Colors.red.shade600,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                        foregroundColor: Colors.grey[600],
                        padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: const Text("Annuler"),
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _deleteEtablissement(etablissement);
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: const Text("Supprimer"),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
