import 'package:flutter/material.dart';

class widgetConexiones extends StatefulWidget {
  const widgetConexiones({super.key});

  @override
  State<widgetConexiones> createState() => _WidgetConexionesState();
  
}

class _WidgetConexionesState extends State<widgetConexiones> {
  @override
  Widget build(BuildContext context) {
    return  Row(
        children: [
          SizedBox(
            width: 30,
            height: 30,
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white
                  ),
                  child: Center(
                    child: Icon(  
                  Icons.backup_sharp, 
            color: Theme.of(context).primaryColor,
          ),
        ),
      ),  
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Icon( 
                  Icons.offline_bolt,
                  size: 12,
                  color: Colors.red,)),
                  ],
            ),
          ),
        ],
      
    );
  }
}