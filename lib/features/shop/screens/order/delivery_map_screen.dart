import 'package:flutter/material.dart';
import '../../../../common/widgets/appbar/appbar.dart';
import '../../models/order_model.dart';
import 'delivery_map_view.dart';

class DeliveryMapScreen extends StatelessWidget {
  final OrderModel order;
  const DeliveryMapScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TAppBar(title: Text("Itinéraire de livraison")),
      body: DeliveryMapView(order: order),
    );
  }
}
