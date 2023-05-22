import 'package:fclash/service/clash_service.dart';
import 'package:flutter/material.dart';
import 'package:kommon/kommon.dart';

class OPTContainer extends StatefulWidget {
  String text;
  String position;
  bool selected;
  OPTContainer(
      {Key? key,
      required this.text,
      required this.position,
      required this.selected})
      : super(key: key);

  @override
  State<OPTContainer> createState() => _OPTContainerState();
}

class _OPTContainerState extends State<OPTContainer> {
  final nomalColor = Colors.white;
  final selectedColor = Color.fromRGBO(92, 191, 249, 1);
  final selectedStyle = TextStyle(color: Colors.white, fontSize: 12);
  final nomalStyle = TextStyle(color: Colors.grey, fontSize: 12);

  @override
  Widget build(BuildContext context) {
    Color containerColor = widget.selected ? selectedColor : nomalColor;
    BoxDecoration middle = BoxDecoration(
      color: containerColor,
      border: Border(
        top: BorderSide(color: Colors.grey.shade300, width: 1),
        bottom: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
    );

    return Container(
      height: 40,
      width: 70,
      decoration: widget.position == "middle"
          ? middle
          : BoxDecoration(
              color: containerColor,
              border: Border.all(width: 1, color: Colors.grey.shade300),
              borderRadius: widget.position == "right"
                  ? const BorderRadius.only(
                      topRight: Radius.circular(6.0),
                      bottomRight: Radius.circular(6.0),
                    )
                  : const BorderRadius.only(
                      topLeft: Radius.circular(6.0),
                      bottomLeft: Radius.circular(6.0),
                    ),
            ),
      child: Center(
        child: Text(
          widget.text.tr,
          style: widget.selected ? selectedStyle : nomalStyle,
        ),
      ),
    );
  }
}
