import 'package:caferesto/common/widgets/appbar/appbar.dart';
import 'package:caferesto/utils/constants/sizes.dart';
import 'package:flutter/material.dart';

import '../../controllers/product/order_controller.dart';
import 'widgets/order_list.dart';

class OrderScreen extends StatelessWidget {
  const OrderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final orderController = OrderController.instance;

    return Scaffold(
      appBar: TAppBar(
        title: Row(
          children: [
            Text(
              ' Mes commandes',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => orderController.recupererCommandesUtilisateur(),
        child: const Padding(
          padding: EdgeInsets.all(AppSizes.defaultSpace),
          child: TOrderListItems(),
        ),
      ),
    );
  }
}
