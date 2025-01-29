import 'package:eureka_app/popups/popUpDataModel.dart';
import 'package:flutter/material.dart';

class GenericPopup extends StatelessWidget {
  final PopupData popupData;

  const GenericPopup({Key? key, required this.popupData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.0),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        // mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        // mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 20,
          ),
          Align(
              alignment: Alignment.topLeft,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 30,
                ),
              )),
          //todo: add image
          // Icon(popupData.icon, size: 48, color: Colors.yellow),
          Spacer(),
          Text(
            popupData.title,
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          SizedBox(height: 8),
          Text(
            popupData.description,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.white70),
          ),
          Spacer(),

          if (popupData.onAction != null)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close popup
                popupData.onAction?.call();
              },
              child: Text("Okay"),
            ),
        ],
      ),
    );
  }
}
