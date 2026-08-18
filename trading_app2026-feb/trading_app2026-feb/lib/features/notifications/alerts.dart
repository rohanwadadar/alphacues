import 'package:flutter/material.dart';

class StockAlertsScreen extends StatefulWidget {
  final String? stockSymbol;
  
  const StockAlertsScreen({Key? key, this.stockSymbol}) : super(key: key);

  @override
  State<StockAlertsScreen> createState() => _StockAlertsScreenState();
}

class _StockAlertsScreenState extends State<StockAlertsScreen> {
  List<StockAlert> alerts = [
    StockAlert(
      id: '1',
      stockSymbol: 'AAPL',
      alertType: AlertType.priceAbove,
      targetPrice: 19.00,
      isActive: true,
      createdAt: DateTime.now().subtract(Duration(days: 2)),
    ),
    StockAlert(
      id: '2',
      stockSymbol: 'TSLA',
      alertType: AlertType.priceBelow,
      targetPrice: 150.00,
      isActive: false,
      createdAt: DateTime.now().subtract(Duration(days: 5)),
    ),
  ];

  void _showAddAlertBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddAlertBottomSheet(
        stockSymbol: widget.stockSymbol ?? 'AAPL',
        onAlertAdded: (alert) {
          setState(() {
            alerts.insert(0, alert);
          });
        },
      ),
    );
  }

  void _showEditAlertDialog(StockAlert alert) {
    showDialog(
      context: context,
      builder: (context) => EditAlertDialog(
        alert: alert,
        onAlertUpdated: (updatedAlert) {
          setState(() {
            final index = alerts.indexWhere((a) => a.id == updatedAlert.id);
            if (index != -1) {
              alerts[index] = updatedAlert;
            }
          });
        },
      ),
    );
  }

  void _deleteAlert(String id) {
    setState(() {
      alerts.removeWhere((alert) => alert.id == id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Alert deleted'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _toggleAlert(String id) {
    setState(() {
      final index = alerts.indexWhere((alert) => alert.id == id);
      if (index != -1) {
        alerts[index].isActive = !alerts[index].isActive;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Custom Alerts',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
           icon: Icon(Icons.notifications_active_rounded, color: Color.fromARGB(255, 112, 97, 243)),
            onPressed: () {
              // Edit options functionality
            },
          ),
        ],
      ),
      body: alerts.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: alerts.length,
              itemBuilder: (context, index) {
                return _buildAlertCard(alerts[index]);
              },
            ),
      bottomNavigationBar: _buildBottomAddButton(),
    );
  }
Widget _buildBottomAddButton() {
  return Container(
    color: Colors.transparent, // keeps layout clean
    child: SizedBox(
      width: double.infinity,   // keeps layout inside SizedBox
      height: 90,               // gives space to float upward
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            bottom: 20,  // moves the button upward from absolute bottom
            child: SizedBox(
              width: 160,   // small button size
              height: 42,
              child: ElevatedButton(
                onPressed: _showAddAlertBottomSheet,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF7061F3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Add Alerts',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}


  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 100,
            color: Colors.grey.shade300,
          ),
          SizedBox(height: 24),
          Text(
            'No alerts yet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Create your first alert to get notified\nabout price movements',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard(StockAlert alert) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Color(0xFF7061F3)
         // width: 1,
        ),
        boxShadow: [
         
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Color(0xFF7061F3).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      alert.stockSymbol,
                      style: TextStyle(
                        color: Color(0xFF7061F3),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: alert.isActive 
                          ? Colors.green.withOpacity(0.1) 
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      alert.isActive ? 'Active' : 'Paused',
                      style: TextStyle(
                        color: alert.isActive ? Colors.green : Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.edit_outlined, color: Color(0xFF7061F3)),
                    onPressed: () => _showEditAlertDialog(alert),
                  ),
                  Switch(
                    value: alert.isActive,
                    onChanged: (value) => _toggleAlert(alert.id),
                    activeColor: Color(0xFF7061F3),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: const Color.fromARGB(255, 228, 22, 22)),
                    onPressed: () => _deleteAlert(alert.id),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Icon(
                alert.alertType == AlertType.priceAbove
                    ? Icons.trending_up
                    : Icons.trending_down,
                color: alert.alertType == AlertType.priceAbove
                    ? const Color.fromARGB(255, 0, 0, 0)
                    : const Color.fromARGB(255, 0, 0, 0),
                size: 20,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  alert.getAlertDescription(),
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Target: \$${alert.targetPrice.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              Text(
                _getTimeAgo(alert.createdAt),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inMinutes}m ago';
    }
  }
}

// Edit Alert Dialog
class EditAlertDialog extends StatefulWidget {
  final StockAlert alert;
  final Function(StockAlert) onAlertUpdated;

  const EditAlertDialog({
    Key? key,
    required this.alert,
    required this.onAlertUpdated,
  }) : super(key: key);

  @override
  State<EditAlertDialog> createState() => _EditAlertDialogState();
}

class _EditAlertDialogState extends State<EditAlertDialog> {
  late TextEditingController _priceController;
  late AlertType selectedAlertType;

  @override
  void initState() {
    super.initState();
    _priceController = TextEditingController(
      text: widget.alert.targetPrice.toStringAsFixed(2)
    );
    selectedAlertType = widget.alert.alertType;
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  void _updateAlert() {
    if (_priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter price'),
          backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        ),
      );
      return;
    }

    final updatedAlert = StockAlert(
      id: widget.alert.id,
      stockSymbol: widget.alert.stockSymbol,
      alertType: selectedAlertType,
      targetPrice: double.parse(_priceController.text),
      isActive: widget.alert.isActive,
      createdAt: widget.alert.createdAt,
    );

    widget.onAlertUpdated(updatedAlert);
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Alert updated successfully'),
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Edit Alert',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.black),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              'Stock: ${widget.alert.stockSymbol}',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Alert Type',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildAlertTypeChip(
                    AlertType.priceAbove,
                    'Price Above',
                    Icons.trending_up,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildAlertTypeChip(
                    AlertType.priceBelow,
                    'Price Below',
                    Icons.trending_down,
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Target Price',
                hintText: '\$0.00',
                prefixIcon: Icon(Icons.attach_money, color: Color(0xFF7061F3)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Color(0xFF7061F3), width: 2),
                ),
                labelStyle: TextStyle(color: Colors.black),
                hintStyle: TextStyle(color: Colors.grey),
              ),
              style: TextStyle(color: Colors.black),
            ),
            SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _updateAlert,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF7061F3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Update Alert',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertTypeChip(AlertType type, String label, IconData icon) {
    final isSelected = selectedAlertType == type;
    final color = type == AlertType.priceAbove ? Colors.green : Colors.red;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedAlertType = type;
        });
      },
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? color : Colors.grey,
              size: 20,
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : Colors.black,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Add Alert Bottom Sheet
class AddAlertBottomSheet extends StatefulWidget {
  final String stockSymbol;
  final Function(StockAlert) onAlertAdded;

  const AddAlertBottomSheet({
    Key? key,
    required this.stockSymbol,
    required this.onAlertAdded,
  }) : super(key: key);

  @override
  State<AddAlertBottomSheet> createState() => _AddAlertBottomSheetState();
}

class _AddAlertBottomSheetState extends State<AddAlertBottomSheet> {
  AlertType? selectedAlertType;
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _stockController.text = widget.stockSymbol;
  }

  @override
  void dispose() {
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  void _addAlert() {
    if (selectedAlertType == null || _priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select alert type and enter price'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final alert = StockAlert(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      stockSymbol: _stockController.text.toUpperCase(),
      alertType: selectedAlertType!,
      targetPrice: double.parse(_priceController.text),
      isActive: true,
      createdAt: DateTime.now(),
    );

    widget.onAlertAdded(alert);
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Alert created successfully'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Create Custom Alert',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.black),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                'You\'ll get a notification for each alert\nwhenever the condition matches.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              SizedBox(height: 24),
              
              // Stock Symbol Input
              TextField(
                controller: _stockController,
                decoration: InputDecoration(
                  labelText: 'Stock Symbol',
                  hintText: 'e.g., AAPL',
                  prefixIcon: Icon(Icons.search, color: Color(0xFF7061F3)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Color(0xFF7061F3), width: 2),
                  ),
                  labelStyle: TextStyle(color: Colors.black),
                  hintStyle: TextStyle(color: Colors.grey),
                ),
                style: TextStyle(color: Colors.black),
                textCapitalization: TextCapitalization.characters,
              ),
              SizedBox(height: 20),
              
              Text(
                'Select alert type',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 16),
              
              _buildAlertTypeOption(
                AlertType.priceAbove,
                'Price moves above',
                Icons.trending_up,
                Colors.green,
              ),
              SizedBox(height: 12),
              _buildAlertTypeOption(
                AlertType.priceBelow,
                'Price moves below',
                Icons.trending_down,
                Colors.red,
              ),
              
              if (selectedAlertType != null) ...[
                SizedBox(height: 24),
                TextField(
                  controller: _priceController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Target Price',
                    hintText: '\$0.00',
                    prefixIcon: Icon(Icons.attach_money, color: Color(0xFF7061F3)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Color(0xFF7061F3), width: 2),
                    ),
                    labelStyle: TextStyle(color: Colors.black),
                    hintStyle: TextStyle(color: Colors.grey),
                  ),
                  style: TextStyle(color: Colors.black),
                ),
              ],
              
              SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _addAlert,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF7061F3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Add Alert',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlertTypeOption(
    AlertType type,
    String title,
    IconData icon,
    Color color,
  ) {
    final isSelected = selectedAlertType == type;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedAlertType = type;
        });
      },
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? color.withOpacity(0.1) 
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: color, size: 24)
            else
              Icon(Icons.arrow_forward_ios, 
                color: Colors.grey.shade400, 
                size: 16,
              ),
          ],
        ),
      ),
    );
  }
}

// Alert Model
enum AlertType {
  priceAbove,
  priceBelow,
  aiAlert,
}

class StockAlert {
  final String id;
  final String stockSymbol;
  final AlertType alertType;
  final double targetPrice;
  bool isActive;
  final DateTime createdAt;

  StockAlert({
    required this.id,
    required this.stockSymbol,
    required this.alertType,
    required this.targetPrice,
    required this.isActive,
    required this.createdAt,
  });

  String getAlertDescription() {
    switch (alertType) {
      case AlertType.priceAbove:
        return 'Price moves above \$${targetPrice.toStringAsFixed(2)}';
      case AlertType.priceBelow:
        return 'Price moves below \$${targetPrice.toStringAsFixed(2)}';
      case AlertType.aiAlert:
        return 'AI-powered alert monitoring';
    }
  }
}
