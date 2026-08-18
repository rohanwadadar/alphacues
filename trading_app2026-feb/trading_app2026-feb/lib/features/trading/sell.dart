import 'package:flutter/material.dart';

class SellPage extends StatefulWidget {
  @override
  _SellPageState createState() => _SellPageState();
}

class _SellPageState extends State<SellPage> {
  int quantity = 1;
  double marketPrice = 189.10;
  double availableShares = 20.0;
  double estimatedEarnings = 189.10;

  void updateEarnings() {
    setState(() {
      estimatedEarnings = quantity * marketPrice;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("Market Sell Order", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.white),
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
                Text(
                  "GOTO",
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "LOGO ",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            Text(
              "Shares",
              style: TextStyle(color: Colors.redAccent, fontSize: 16),
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
            Text("Quantity", style: TextStyle(color: Colors.white, fontSize: 16)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.remove, color: Colors.white),
                  onPressed: () {
                    if (quantity > 1) {
                      setState(() {
                        quantity--;
                        updateEarnings();
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
                    if (quantity < availableShares) {
                      setState(() {
                        quantity++;
                        updateEarnings();
                      });
                    }
                  },
                ),
              ],
            ),

            // Market Price Input
            SizedBox(height: 20),
            Text("Market Price", style: TextStyle(color: Colors.white, fontSize: 16)),
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

            // Available Shares & Estimated Earnings
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Available Shares: ${availableShares.toInt()} ", style: TextStyle(color: Colors.redAccent)),
                Text("Estimated Earnings: \$${estimatedEarnings.toStringAsFixed(2)}", style: TextStyle(color: Colors.greenAccent)),
              ],
            ),

            // Buttons
            Spacer(),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Cancel logic here
                    },
                    child: Text("CANCEL"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Sell order logic here
                    },
                    child: Text("SELL ORDER"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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
        color: isSelected ? Colors.red : Colors.grey[800],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(color: Colors.white),
      ),
    );
  }
}
