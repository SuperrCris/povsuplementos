import 'package:flutter/material.dart';

class BotonesBusqueda extends StatefulWidget {
  final Function(int)? onSelectionChanged;
  
  const BotonesBusqueda({
    super.key,
    this.onSelectionChanged,
  });

  @override
  _BotonesBusquedaState createState() => _BotonesBusquedaState();
}

class _BotonesBusquedaState extends State<BotonesBusqueda> with SingleTickerProviderStateMixin {
  late AnimationController _animacionControlador;
  late Animation<double> _animacion;
  
  @override
  void initState() {
    super.initState();

    _animacionControlador = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _animacion = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animacionControlador,
      curve: Curves.easeInOut,
    ));

    _animacionControlador.forward();
  }

  @override
  void dispose() {
    _animacionControlador.dispose();
    super.dispose();
  }

  int criterio = 0; 
  
  final etiquetas = [
    "Todos",
    "Solo snacks", 
    "Solo suplementos"
  ];

  void _selectButton(int index) {
    if (criterio != index) {
      setState(() {
        criterio = index;
      });
      
      _animacionControlador.reset();
      _animacionControlador.forward();
      
      widget.onSelectionChanged?.call(criterio);
    }
  }

  Widget _buildButton(int index) {
    final theme = Theme.of(context);
    final isSelected = criterio == index;
    final isDark = theme.brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: _animacion,
      builder: (context, child) {
        return Transform.scale(
          scale: isSelected ? (0.95 + 0.05 * _animacion.value) : 1.0,
            child: GestureDetector(
              onTap: () => _selectButton(index),
              child: AnimatedContainer(
                duration: Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected 
                    ? (isDark ? Colors.blue.shade600 : Colors.blue.shade500)
                    : Colors.transparent,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    width: 2,
                    color: isDark ? Colors.blue.shade400 : Colors.blue.shade600,
                  ),
                ),
                child: Text(
                  etiquetas[index],
                  style: TextStyle(
                    color: isSelected 
                      ? Colors.white
                      : (isDark ? Colors.blue.shade300 : Colors.blue.shade700),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
       
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          for (int i = 0; i < etiquetas.length; i++) 
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 2),
                child: _buildButton(i),
              ),
            ),
        ],
      ),
    );
  }
}
