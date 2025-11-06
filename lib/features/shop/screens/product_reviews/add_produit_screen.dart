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
import '../../../../utils/constants/enums.dart';
import '../../../../utils/popups/loaders.dart';
import '../../controllers/product/produit_controller.dart';
import '../../models/produit_model.dart';
import '../../../../data/repositories/categories/category_repository.dart';
import '../../controllers/etablissement_controller.dart';
import '../../../personalization/screens/categories/widgets/category_form_widgets.dart';
import '../../../personalization/controllers/user_controller.dart';
import '../../../shop/models/statut_etablissement_model.dart';

class AddProduitScreen extends StatefulWidget {
  final ProduitModel? produit;
  const AddProduitScreen({super.key, this.produit});

  @override
  State<AddProduitScreen> createState() => _AddProduitScreenState();
}

class _AddProduitScreenState extends State<AddProduitScreen>
    with SingleTickerProviderStateMixin {
  final ProduitController _produitController = Get.find<ProduitController>();
  final CategoryRepository _categoryRepository = Get.find<CategoryRepository>();
  final EtablissementController _etablissementController =
      Get.find<EtablissementController>();

  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tempsPreparationController = TextEditingController();
  final _quantiteStockController = TextEditingController();
  final _prixController = TextEditingController();
  final _prixPromoController = TextEditingController();
  final _tailleController = TextEditingController();
  final _prixTailleController = TextEditingController();

  String? _selectedCategorieId;
  final List<ProductSizePrice> _taillesPrix = [];
  final List<String> _supplements = [];
  final List<String> _images = [];
  bool _estStockable = false;
  bool _isFeatured = false;
  ProductType _productType = ProductType.single;
  bool _isEditing = false;
  bool _isLoading = false;
  XFile? _selectedImage;
  int? _editingIndex;
  final FocusNode _tailleFocusNode = FocusNode();

  List<Map<String, dynamic>> _categories = [];

  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.produit != null;
    if (_isEditing) _fillFormData();
    _initializeAnimation();
    _loadCategories();
    _guardAccess();
  }

  @override
  void dispose() {
    _animationController?.dispose();
    _tailleFocusNode.dispose();
    _nomController.dispose();
    _descriptionController.dispose();
    _tempsPreparationController.dispose();
    _quantiteStockController.dispose();
    _prixController.dispose();
    _prixPromoController.dispose();
    _tailleController.dispose();
    _prixTailleController.dispose();
    super.dispose();
  }

  void _initializeAnimation() {
    _animationController = AnimationController(
        duration: const Duration(milliseconds: 700), vsync: this);
    _fadeAnimation =
        CurvedAnimation(parent: _animationController!, curve: Curves.easeInOut);
    _animationController!.forward();
  }

  void _fillFormData() {
    final produit = widget.produit!;
    _nomController.text = produit.name;
    _descriptionController.text = produit.description ?? '';
    _tempsPreparationController.text = produit.preparationTime.toString();
    _selectedCategorieId = produit.categoryId;
    _taillesPrix.addAll(produit.sizesPrices);
    _supplements.addAll(produit.supplements ?? []);
    _estStockable = produit.isStockable;
    _quantiteStockController.text = produit.stockQuantity.toString();
    _isFeatured = produit.isFeatured ?? false;
    _productType = produit.productType == 'variable'
        ? ProductType.variable
        : ProductType.single;
    _prixController.text = (produit.price ?? 0).toString();
    _prixPromoController.text = (produit.salePrice ?? 0).toString();
    _images.addAll(produit.images ?? []);
    // Note: main image handled via produit.imageUrl
  }

  Future<void> _loadCategories() async {
    try {
      setState(() => _isLoading = true);
      final categories = await _categoryRepository.getAllCategories();
      setState(() {
        _categories =
            categories.map((cat) => {'id': cat.id, 'name': cat.name}).toList();
      });
    } catch (e) {
      TLoaders.errorSnackBar(message: 'Erreur chargement catégories: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ================= IMAGES =================

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

  Future<void> _pickMultipleImages() async {
    try {
      final picked = await ImagePicker().pickMultiImage(imageQuality: 80);
      if (picked.isNotEmpty) {
        setState(() => _images.addAll(picked.map((x) => x.path)));
      }
    } catch (e) {
      TLoaders.errorSnackBar(message: 'Erreur sélection images: $e');
    }
  }

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
      } else if (widget.produit?.imageUrl != null &&
          widget.produit!.imageUrl.isNotEmpty) {
        return ClipRRect(
          borderRadius: borderRadius,
          child: Image.network(widget.produit!.imageUrl,
              fit: BoxFit.cover, width: previewWidth, height: previewHeight),
        );
      } else {
        return SizedBox(
          height: previewHeight,
          child: Center(
            child: Icon(Icons.add_photo_alternate_outlined,
                color: Colors.grey, size: 40),
          ),
        );
      }
    }

    return CategoryFormCard(
      children: [
        const Text('Image principale',
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
            child: mainImageWidget(),
          ),
        ),
        const SizedBox(height: 16),
        const Text('Galerie d\'images'),
        const SizedBox(height: 12),
        SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _images.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, index) {
              if (index == _images.length) {
                return GestureDetector(
                  onTap: _pickMultipleImages,
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                    child: const Icon(Icons.add, size: 32, color: Colors.grey),
                  ),
                );
              }
              final url = _images[index];
              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(url,
                        width: 110, height: 110, fit: BoxFit.cover),
                  ),
                  Positioned(
                    right: 2,
                    top: 2,
                    child: GestureDetector(
                      onTap: () => setState(() => _images.removeAt(index)),
                      child: Container(
                        decoration: const BoxDecoration(
                            color: Colors.black54, shape: BoxShape.circle),
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 18),
                      ),
                    ),
                  )
                ],
              );
            },
          ),
        )
      ],
    );
  }

  // ================= SECTIONS FORM =================

  Widget _buildFeaturedSection() {
    return CategoryFormCard(
      children: [
        SwitchListTile(
          title: const Text('Produit en vedette'),
          subtitle: const Text('Afficher ce produit en avant sur la vitrine'),
          value: _isFeatured,
          onChanged: (val) => setState(() => _isFeatured = val),
        ),
      ],
    );
  }

  Widget _buildProductTypeSection() {
    final priceField = TextFormField(
      controller: _prixController,
      decoration: const InputDecoration(
          labelText: 'Prix (DT) *',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.attach_money_outlined)),
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      validator: (v) =>
          _productType == ProductType.single && (v == null || v.isEmpty)
              ? 'Entrez un prix'
              : null,
    );

    final promoField = TextFormField(
      controller: _prixPromoController,
      decoration: const InputDecoration(
          labelText: 'Prix promo (optionnel)',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.local_offer_outlined)),
      keyboardType: TextInputType.numberWithOptions(decimal: true),
    );

    return CategoryFormCard(children: [
      const Text('Type de produit',
          style: TextStyle(fontWeight: FontWeight.bold)),
      Row(children: [
        Expanded(
          child: RadioListTile<ProductType>(
            title: const Text('Simple'),
            value: ProductType.single,
            groupValue: _productType,
            onChanged: (v) => setState(() => _productType = v!),
          ),
        ),
        Expanded(
          child: RadioListTile<ProductType>(
            title: const Text('Variable'),
            value: ProductType.variable,
            groupValue: _productType,
            onChanged: (v) => setState(() => _productType = v!),
          ),
        ),
      ]),
      const SizedBox(height: 12),
      if (_productType == ProductType.single) ...[
        priceField,
        const SizedBox(height: 12),
        promoField,
      ]
    ]);
  }

  Widget _buildTaillesSection(double width) {
    if (_productType == ProductType.single) return const SizedBox.shrink();
    final dark = THelperFunctions.isDarkMode(context);
    final fieldWidth = (width >= 900) ? 240.0 : (width >= 600 ? 200.0 : 150.0);

    return CategoryFormCard(children: [
      const Text('Tailles & prix',
          style: TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: fieldWidth,
              child: TextFormField(
                controller: _tailleController,
                focusNode: _tailleFocusNode,
                decoration: const InputDecoration(
                    labelText: 'Taille', border: OutlineInputBorder()),
              ),
            ),
            SizedBox(
              width: fieldWidth,
              child: TextFormField(
                controller: _prixTailleController,
                decoration: const InputDecoration(
                    labelText: 'Prix', border: OutlineInputBorder()),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
            ),
            ElevatedButton.icon(
              icon: Icon(
                  _editingIndex != null ? Iconsax.save_2 : Icons.add_circle),
              label: Text(_editingIndex != null ? 'Sauvegarder' : 'Ajouter'),
              onPressed: () {
                final t = _tailleController.text.trim();
                final p = double.tryParse(_prixTailleController.text) ?? 0;
                if (t.isEmpty || p <= 0) {
                  TLoaders.errorSnackBar(message: 'Taille ou prix invalide');
                  return;
                }
                setState(() {
                  if (_editingIndex != null) {
                    _taillesPrix[_editingIndex!] =
                        ProductSizePrice(size: t, price: p);
                    _editingIndex = null;
                  } else {
                    _taillesPrix.add(ProductSizePrice(size: t, price: p));
                  }
                  _tailleController.clear();
                  _prixTailleController.clear();
                });
              },
            )
          ]),
      const SizedBox(height: 12),
      if (_taillesPrix.isNotEmpty)
        Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _taillesPrix.asMap().entries.map((e) {
              final i = e.key;
              final tp = e.value;
              return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: dark ? Colors.grey.shade800 : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text('${tp.size} - ${tp.price} DT'),
                    IconButton(
                        icon: const Icon(Icons.edit, size: 18),
                        onPressed: () {
                          setState(() {
                            _tailleController.text = tp.size;
                            _prixTailleController.text = tp.price.toString();
                            _editingIndex = i;
                          });
                          FocusScope.of(context).requestFocus(_tailleFocusNode);
                        }),
                    IconButton(
                        icon: const Icon(Icons.delete, size: 18),
                        onPressed: () =>
                            setState(() => _taillesPrix.removeAt(i))),
                  ]));
            }).toList())
      else
        const Text('Aucune taille ajoutée.')
    ]);
  }

  Widget _buildStockSection() {
    return CategoryFormCard(children: [
      const Text('Stock', style: TextStyle(fontWeight: FontWeight.bold)),
      SwitchListTile(
        title: const Text('Produit stockable'),
        value: _estStockable,
        onChanged: (v) => setState(() => _estStockable = v),
      ),
      if (_estStockable)
        TextFormField(
          controller: _quantiteStockController,
          decoration: const InputDecoration(
              labelText: 'Quantité en stock', border: OutlineInputBorder()),
          keyboardType: TextInputType.number,
        ),
    ]);
  }

  Widget _buildBasicInfoSection(double width) {
    final isWide = width >= 900;
    return CategoryFormCard(children: [
      const Text('Informations de base',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      const SizedBox(height: 16),
      TextFormField(
        controller: _nomController,
        decoration: const InputDecoration(
            labelText: 'Nom *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.fastfood_outlined)),
        validator: (v) => v == null || v.isEmpty ? 'Nom requis' : null,
      ),
      const SizedBox(height: 16),
      DropdownButtonFormField<String>(
        value: _selectedCategorieId,
        decoration: const InputDecoration(
            labelText: 'Catégorie *', border: OutlineInputBorder()),
        items: _categories
            .map((c) => DropdownMenuItem(
                value: c['id'] as String, child: Text(c['name'])))
            .toList(),
        onChanged: (v) => setState(() => _selectedCategorieId = v),
        validator: (v) => v == null ? 'Sélectionnez une catégorie' : null,
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _descriptionController,
        decoration: const InputDecoration(
            labelText: 'Description', border: OutlineInputBorder()),
        maxLines: isWide ? 5 : 3,
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _tempsPreparationController,
        decoration: const InputDecoration(
            labelText: 'Temps de préparation (min)',
            border: OutlineInputBorder()),
        keyboardType: TextInputType.number,
      )
    ]);
  }

  // ================= SUBMIT =================

  Future<String?> _getEtablissementIdUtilisateur() async {
    try {
      final userRole = UserController.instance.userRole;
      final e =
          await _etablissementController.getEtablissementUtilisateurConnecte();

      if (userRole == 'Gérant') {
        if (e == null) {
          TLoaders.errorSnackBar(message: 'Aucun établissement associé.');
          return null;
        }
        if (e.statut != StatutEtablissement.approuve) {
          TLoaders.errorSnackBar(
              message:
                  'Accès refusé: votre établissement n\'est pas approuvé.');
          return null;
        }
      }

      return e?.id;
    } catch (_) {
      TLoaders.errorSnackBar(message: 'Erreur établissement');
      return null;
    }
  }

  Future<void> _guardAccess() async {
    final role = UserController.instance.userRole;
    if (role != 'Gérant') return;
    final etab =
        await _etablissementController.getEtablissementUtilisateurConnecte();
    if (etab == null || etab.statut != StatutEtablissement.approuve) {
      TLoaders.errorSnackBar(
          message:
              'Accès désactivé tant que votre établissement n\'est pas approuvé.');
      if (mounted) Get.back();
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final userRole = UserController.instance.userRole;
    String? etabId;

    // Si on modifie un produit et que l'utilisateur est Admin,
    // on préserve l'établissement original du produit
    if (_isEditing && userRole == 'Admin' && widget.produit != null) {
      etabId = widget.produit!.etablissementId;
    } else {
      // Sinon, on récupère l'établissement de l'utilisateur
      etabId = await _getEtablissementIdUtilisateur();
      if (etabId == null && userRole != 'Admin') {
        setState(() => _isLoading = false);
        return;
      }
    }

    // Pour les Admins en création, on doit avoir un établissement
    if (!_isEditing && etabId == null) {
      TLoaders.errorSnackBar(
          message: 'Veuillez sélectionner un établissement pour ce produit.');
      setState(() => _isLoading = false);
      return;
    }

    String? imageUrl;
    if (_selectedImage != null) {
      imageUrl = await _produitController.uploadProductImage(_selectedImage!);
    } else if (widget.produit?.imageUrl != null) {
      imageUrl = widget.produit!.imageUrl;
    }

    final produit = ProduitModel(
      id: _isEditing ? widget.produit!.id : '',
      name: _nomController.text.trim(),
      imageUrl: imageUrl ?? '',
      images: _images,
      categoryId: _selectedCategorieId!,
      sizesPrices: _productType == ProductType.variable ? _taillesPrix : [],
      supplements: _supplements,
      description: _descriptionController.text.trim(),
      preparationTime: int.tryParse(_tempsPreparationController.text) ?? 0,
      etablissementId: etabId ?? '',
      isStockable: _estStockable,
      stockQuantity:
          _estStockable ? int.tryParse(_quantiteStockController.text) ?? 0 : 0,
      price: _productType == ProductType.single
          ? double.tryParse(_prixController.text) ?? 0
          : 0,
      salePrice: _productType == ProductType.single
          ? double.tryParse(_prixPromoController.text) ?? 0
          : 0,
      isFeatured: _isFeatured,
      productType: _productType.name,
      createdAt: _isEditing ? widget.produit!.createdAt : DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final ok = _isEditing
        ? await _produitController.updateProduct(produit)
        : await _produitController.addProduct(produit);

    if (ok) {
      TLoaders.successSnackBar(
          message: _isEditing
              ? 'Produit modifié avec succès'
              : 'Produit ajouté avec succès');
      Get.back(result: true);
    }

    setState(() => _isLoading = false);
  }

  // ================= BUILD =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TAppBar(
          title:
              Text(_isEditing ? 'Modifier le produit' : 'Ajouter un produit')),
      body: FadeTransition(
        opacity: _fadeAnimation!,
        child: LayoutBuilder(builder: (context, constraints) {
          final width = constraints.maxWidth;
          final isMobile = width < 600;
          final isTablet = width >= 600 && width < 900;
          final isDesktop = width >= 900;

          // On large screens, show a centered column with max width
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
                          // Left column: images + sizes/types
                          Expanded(
                            flex: 5,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildImageSection(width),
                                const SizedBox(
                                    height: AppSizes.spaceBtwSections),
                                _buildProductTypeSection(),
                                const SizedBox(
                                    height: AppSizes.spaceBtwSections),
                                _buildTaillesSection(width),
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),
                          // Right column: basic info + stock + featured + submit
                          Expanded(
                            flex: 6,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildBasicInfoSection(width),
                                const SizedBox(
                                    height: AppSizes.spaceBtwSections),
                                _buildStockSection(),
                                const SizedBox(
                                    height: AppSizes.spaceBtwSections),
                                _buildFeaturedSection(),
                                const SizedBox(
                                    height: AppSizes.spaceBtwSections),
                                // Submit area
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed:
                                            _isLoading ? null : _submitForm,
                                        icon: Icon(_isEditing
                                            ? Iconsax.save_2
                                            : Iconsax.add_circle),
                                        label: Text(_isEditing
                                            ? 'Enregistrer'
                                            : 'Ajouter'),
                                        style: ElevatedButton.styleFrom(
                                          minimumSize:
                                              const Size.fromHeight(55),
                                          backgroundColor: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                // Small helper text
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
                          _buildBasicInfoSection(width),
                          const SizedBox(height: AppSizes.spaceBtwSections),
                          _buildProductTypeSection(),
                          const SizedBox(height: AppSizes.spaceBtwSections),
                          _buildTaillesSection(width),
                          const SizedBox(height: AppSizes.spaceBtwSections),
                          _buildStockSection(),
                          const SizedBox(height: AppSizes.spaceBtwSections),
                          _buildFeaturedSection(),
                          const SizedBox(height: AppSizes.spaceBtwSections),
                          ElevatedButton.icon(
                            onPressed: _isLoading ? null : _submitForm,
                            icon: Icon(_isEditing
                                ? Iconsax.save_2
                                : Iconsax.add_circle),
                            label: Text(_isEditing ? 'Enregistrer' : 'Ajouter'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size.fromHeight(55),
                              backgroundColor: AppColors.primary,
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
