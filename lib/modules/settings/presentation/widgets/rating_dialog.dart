import 'package:flutter/material.dart';
import 'dart:io';

import '../../../../core/theme/app_theme.dart';

class RatingDialog extends StatefulWidget {
  final Function(int) onRatingSubmitted;

  const RatingDialog({
    super.key,
    required this.onRatingSubmitted,
  });

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  int _rating = 0;

  String get _storeName =>
      Platform.isAndroid ? 'Google Play Store' : 'App Store';

  String _getRatingText() {
    switch (_rating) {
      case 1:
        return 'Hate it';
      case 2:
        return 'Dislike it';
      case 3:
        return "It's Ok";
      case 4:
        return 'Like it';
      case 5:
        return 'Love it';
      default:
        return 'Rate us';
    }
  }

  Widget _getImage() {
    switch (_rating) {
      case 1:
        return Image.asset(
            'assets/logo/face-with-steam-from-nose.512x472.png'); // replace with your image
      case 2:
        return Image.asset(
            'assets/logo/smirking-face.512x493.png'); // replace with your image
      case 3:
        return Image.asset(
            'assets/logo/neutral-face.512x493.png'); // replace with your image
      case 4:
        return Image.asset(
            'assets/logo/smiling-face-with-smiling-eyes.512x512.png'); // replace with your image
      case 5:
        return Image.asset(
            'assets/logo/face-blowing-a-kiss.512x493.png'); // replace with your image
      default:
        return Image.asset(
            'assets/logo/face_holding_back_tears_emoji.png'); // replace with your image
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xff1d1d1d),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          SizedBox(
            width: 300,
            height: 350,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  // const SizedBox(height: 10), // Space for emoji
                  Text(
                    _getRatingText(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'If you like QuickZip, please give us five stars on the $_storeName',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppTheme.primaryGrey),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        onPressed: () {
                          setState(() {
                            _rating = index + 1;
                          });
                        },
                        icon: Image(
                          image: AssetImage(
                            index < _rating
                                ? 'assets/icons/rating_star_unselected_icn.png'
                                : 'assets/icons/rating_stars_selected_icn.png',
                          ),
                          width: 32,
                          height: 32,
                          fit: BoxFit.contain,
                        ),
                        iconSize: 32,
                        padding: EdgeInsets.zero,
                      );
                    }),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: 170,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        // backgroundColor: Colors.transparent,
                        side: const BorderSide(
                            color: AppTheme.primaryGreen, width: 1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        minimumSize: const Size(double.infinity, 45),
                      ),
                      onPressed: () {
                        widget.onRatingSubmitted(_rating);
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Submit',
                        style: TextStyle(color: AppTheme.primaryGreen),
                      ),
                    ),
                  ),
                  // const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Exit',
                      style: TextStyle(color: AppTheme.primaryGrey),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: -50,
            child: Container(
              padding: const EdgeInsets.all(8),
              height: 100,
              width: 100,
              // decoration: BoxDecoration(
              //   color: const Color(0xff1d1d1d),
              //   shape: BoxShape.circle,
              //   border: Border.all(color: const Color(0xff1d1d1d), width: 2),
              // ),
              child: _getImage(),
            ),
          ),
        ],
      ),
    );
  }
}
