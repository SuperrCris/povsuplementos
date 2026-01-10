import 'package:flutter/material.dart';

class Busquedasucursales extends StatefulWidget {
  Busquedasucursales({super.key});
  @override
  State<Busquedasucursales> createState() => _BusquedasucursalesState();
}

class _BusquedasucursalesState extends State<Busquedasucursales> {
  final String label = "Usuario";
  int sucursalActual = 3;
  bool _isHovering = false;

  void _showUserDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: SingleChildScrollView(
            child: Container(
              width: 320,
              padding: EdgeInsets.all(24),
              child: Row(
                spacing: 10,
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          sucursalActual = 1;
                        });
                        Navigator.pop(context);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.store, color: Colors.white),
                              SizedBox(height: 4),
                              Text(
                                'BODY 1',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          sucursalActual = 2;
                        });
                        Navigator.pop(context);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.store, color: Colors.white),
                              SizedBox(height: 4),
                              Text(
                                'BODY 2',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          sucursalActual = 3;
                        });
                        Navigator.pop(context);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.store, color: Colors.white),
                              SizedBox(height: 4),
                              Text(
                                'BODY 3',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() {
          _isHovering = true;
        });
      },
      onExit: (_) {
        setState(() {
          _isHovering = false;
        });
      },
      
      child: GestureDetector(
        onTap: () => _showUserDialog(context),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 160),
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _isHovering
                ? Theme.of(context).primaryColor.withOpacity(0.08)
                : Colors.transparent,
            border: Border.all(
                color: Theme.of(context).primaryColor, width: 2),
            borderRadius: BorderRadius.circular(45),
          ),
          child: Text(
            "...en BODY $sucursalActual",
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class BotonConReaccion extends StatefulWidget {
  final VoidCallback? onLoginSuccess;

  const BotonConReaccion({super.key, this.onLoginSuccess});

  @override
  State<BotonConReaccion> createState() => _EstadoBotonConReaccion();
}

class _EstadoBotonConReaccion extends State<BotonConReaccion> {
  bool isLoading = false;

  void _handleAction() async {
    setState(() {
      isLoading = true;
    });

    // Simular alguna acción
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      setState(() {
        isLoading = false;
      });
      
      if (widget.onLoginSuccess != null) {
        widget.onLoginSuccess!();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : _handleAction,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 2,
              ),
            )
          : const Text('Confirmar', style: TextStyle(color: Colors.white)),
    );
  }
}
