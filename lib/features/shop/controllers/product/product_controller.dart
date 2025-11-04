import 'package:get/get.dart';

import '../../../../data/repositories/product/produit_repository.dart';
import '../../../../utils/popups/loaders.dart';
import '../../models/produit_model.dart';

enum ProduitFilter { all, stockables, nonStockables, rupture }

class ProductController extends GetxController {
  static ProductController get instance {
    try {
      return Get.find<ProductController>();
    } catch (e) {
      // If not found, create it (shouldn't happen with proper binding)
      return Get.put(ProductController(), permanent: true);
    }
  }

  final isLoading = false.obs;
  final produitRepository = ProduitRepository.instance;

  RxList<ProduitModel> featuredProducts = <ProduitModel>[].obs;
  @override
  void onInit() {
    fetchFeaturedProducts();
    super.onInit();
  }

  /// Product List

  /// Fetch Products
  void fetchFeaturedProducts() async {
    try {
      // Show loader while loading products
      isLoading.value = true;

      // Fetch products from an API or database
      final products = await produitRepository.getFeaturedProducts();
      // Assign products
      featuredProducts.assignAll(products);
    } catch (e) {
      // Handle error
      TLoaders.errorSnackBar(title: 'Erreur!', message: e.toString());
    } finally {
      // Hide loader after loading products
      isLoading.value = false;
    }
  }

  Future<List<ProduitModel>> fetchAllFeaturedProducts() async {
    try {
      // Fetch products from an API or database
      final products = await produitRepository.getAllFeaturedProducts();
      return products;
    } catch (e) {
      // Handle error
      TLoaders.errorSnackBar(title: 'Erreur!', message: e.toString());
      return [];
    }
  }

  /// get product price or price range for variations
  String getProductPrice(ProduitModel product) {
    double smallestPrice = double.infinity;
    double largestPrice = 0.0;

    //if no variations exist return the simple price or sale price
    if (product.isSingle) {
      return (product.salePrice > 0 ? product.salePrice : product.price)
          .toString();
    } else {
      //calculate the smallest and largest prices among variations
      for (var variation in product.sizesPrices) {
        final double priceToConsider = variation.price;
        if (priceToConsider < smallestPrice) smallestPrice = priceToConsider;
        if (priceToConsider > largestPrice) largestPrice = priceToConsider;
      }

      //if smallest and largest price are the same return a single price
      if (smallestPrice.isEqual(largestPrice)) {
        return largestPrice.toString();
      } else {
        //otherwise return A price range
        return '$smallestPrice - \$$largestPrice';
      }
    }
  }

  /// calculate discount percentage
  String? calculateSalePercentage(double originalPrice, double? salePrice) {
    if (salePrice == null || salePrice <= 0.0) return null;
    if (originalPrice <= 0) return null;

    double percentage = ((originalPrice - salePrice) / originalPrice) * 100;
    return percentage.toStringAsFixed(0);
  }

  /// -- check product stock status
  String getProductStockStatus(int stock, {bool isStockable = true}) {
    // Si le produit n'est pas stockable, toujours afficher "Disponible"
    if (!isStockable) {
      return 'Disponible';
    }
    // Si le produit est stockable, vérifier le stock
    return stock > 0 ? 'En Stock' : 'Hors Stock';
  }
}
