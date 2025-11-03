import 'package:caferesto/common/widgets/appbar/appbar.dart';
import 'package:caferesto/utils/constants/sizes.dart';
import 'package:flutter/material.dart';

import '../../../../common/widgets/products/ratings/rating_indicator.dart';
import 'widgets/progress_indicator_and_rating.dart';
import 'widgets/user_review_card.dart';

class ProductReviewsScreen extends StatelessWidget {
  const ProductReviewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(

        /// Appbar
        appBar: TAppBar(
          title: Text('Avis et Notes'),
        ),

        /// Body
        ///
        body: SingleChildScrollView(
          child: Padding(
              padding: EdgeInsets.all(AppSizes.defaultSpace),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      "Ratings and reviews are verfied and are from pople who use the same type of device that you use"),
                  const SizedBox(
                    height: AppSizes.spaceBtwItems,
                  ),

                  /// Overall Product Ratings
                  TOverallProductRating(),
                  TRatingBarIndicator(
                    rating: 3.5,
                  ),
                  Text(
                    "12,611",
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(
                    height: AppSizes.spaceBtwSections,
                  ),

                  /// User Reviews List
                  const UserReviewCard(),
                  const UserReviewCard(),
                ],
              )),
        ));
  }
}

class TOverallProductRating extends StatelessWidget {
  const TOverallProductRating({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Text(
            '4.8',
            style: Theme.of(context).textTheme.displayLarge,
          ),
        ),
        Expanded(
          flex: 7,
          child: Column(
            children: [
              TRatingProgressIndicator(text: '5', value: 1.0),
              TRatingProgressIndicator(text: '4', value: 0.8),
              TRatingProgressIndicator(text: '3', value: 0.6),
              TRatingProgressIndicator(text: '2', value: 0.4),
              TRatingProgressIndicator(text: '1', value: 0.2),
            ],
          ),
        )
      ],
    );
  }
}
