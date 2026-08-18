import 'package:flutter/material.dart';
import 'package:test_project/features/trading/topup.dart';

class BuyPage extends StatefulWidget {
  @override
  _BuyPageState createState() => _BuyPageState();
}

class _BuyPageState extends State<BuyPage> {
  int quantity = 1;
  double marketPrice = 189.10;
  double balance = 20.0;
  double estimatedCost = 189.10;

  void updateCost() {
    setState(() {
      estimatedCost = quantity * marketPrice;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("Market Order", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              // Navigate to settings page (if needed)
            },
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stock Information
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      "GOTO",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 10), // Space between text and logo
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "logo",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 10),
            Padding(
              padding: EdgeInsets.only(left: 5), // Shift text slightly to right
              child: Text(
                "Shares",
                style: TextStyle(color: Colors.green, fontSize: 16),
              ),
            ),

            // Order Type Selection
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OrderTypeButton(label: "Delivery", isSelected: true),
                OrderTypeButton(label: "Intraday", isSelected: false),
                OrderTypeButton(label: "MTF", isSelected: false),
              ],
            ),

            // Quantity Selector
            SizedBox(height: 20),
            Padding(
              padding: EdgeInsets.only(left: 5), // Shift text slightly to right
              child: Text("Quantity", style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.remove, color: Colors.white),
                  onPressed: () {
                    if (quantity > 1) {
                      setState(() {
                        quantity--;
                        updateCost();
                      });
                    }
                  },
                ),
                Text(
                  "$quantity",
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
                IconButton(
                  icon: Icon(Icons.add, color: Colors.white),
                  onPressed: () {
                    setState(() {
                      quantity++;
                      updateCost();
                    });
                  },
                ),
              ],
            ),

            // Market Price Input
            SizedBox(height: 20),
            Padding(
              padding: EdgeInsets.only(left: 5), // Shift text slightly to right
              child: Text("Market Price", style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
            TextField(
              style: TextStyle(color: Colors.white),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(),
                hintText: "$marketPrice",
                hintStyle: TextStyle(color: Colors.white),
              ),
            ),

            // Balance & Estimated Cost
            SizedBox(height: 20),
            Padding(
              padding: EdgeInsets.only(left: 5), // Shift text slightly to right
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Balance: \$${balance.toStringAsFixed(2)} available", style: TextStyle(color: Colors.redAccent)),
                  Text("Estimated Cost: \$${estimatedCost.toStringAsFixed(2)}", style: TextStyle(color: Colors.greenAccent)),
                ],
              ),
            ),

            // Buttons
            Spacer(),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Navigate to TopUpScreen when "ADD BALANCE" is clicked
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => TopUpScreen()),
                      );
                    },
                    child: Text("ADD BALANCE"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Place order logic here
                    },
                    child: Text("PLACE ORDER"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Order Type Button Widget
class OrderTypeButton extends StatelessWidget {
  final String label;
  final bool isSelected;

  OrderTypeButton({required this.label, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 20),
      decoration: BoxDecoration(
        color: isSelected ? Colors.green : Colors.grey[800],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(color: Colors.white),
      ),
    );
  }
}
