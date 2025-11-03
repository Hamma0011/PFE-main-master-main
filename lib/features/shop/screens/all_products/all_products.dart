import 'package:caferesto/features/shop/controllers/product/all_products_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../common/widgets/appbar/appbar.dart';
import '../../../../common/widgets/products/sortable/sortable_products.dart';
import '../../../../common/widgets/shimmer/vertical_product_shimmer.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/helpers/cloud_helper_functions.dart';
import '../../models/produit_model.dart';

class AllProducts extends StatelessWidget {
  const AllProducts(
      {super.key, required this.title, this.query, this.futureMethod});

  final String title;
  final Query? query;
  final Future<List<ProduitModel>>? futureMethod;

  @override
  Widget build(BuildContext context) {
    Get.put(AllProductsController());
    return Scaffold(
      appBar: TAppBar(
        title: Text(title),
      ),
      body: SingleChildScrollView(
          child: Padding(
        padding: EdgeInsets.all(AppSizes.defaultSpace),
        child: FutureBuilder(
            future: futureMethod,
            builder: (context, snapshot) {
              const loader = TVerticalProductShimmer();
              final widget = TCloudHelperFunctions.checkMultiRecordState(
                snapshot: snapshot,
                loader: loader,
              );

              if (widget != null) return widget;

              /// Afficher les produits s'il sont disponibles
              final products = snapshot.data!;
              return TSortableProducts(products: products);
            }),
      )),
    );
  }
}
