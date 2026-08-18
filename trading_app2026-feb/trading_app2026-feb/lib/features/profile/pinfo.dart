import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:postgres/postgres.dart';
import 'package:test_project/core/services/conn.dart'; // Import your database connection file

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  List<int> customerIds = []; // List of all available customer IDs

  @override
  void initState() {
    super.initState();
    fetchCustomerIds();
  }

  /// Fetch all available customer IDs from PostgreSQL
  Future<void> fetchCustomerIds() async {
    try {
      final db = DatabaseService();
      await db.connect(); // Ensure the connection is open

      List<List<dynamic>> results = await db.connection.query(
        'SELECT customer_id FROM customers',
      );

      print("Customer IDs Fetched: $results"); // Debugging output

      if (results.isNotEmpty) {
        setState(() {
          customerIds = results.map((row) => row[0] as int).toList();
        });
      } else {
        print("No customer IDs found.");
      }
    } catch (e) {
      print("Database Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Customer List"),
        backgroundColor: Colors.grey[900],
      ),
      body: customerIds.isEmpty
          ? const Center(child: CircularProgressIndicator(color: Colors.greenAccent))
          : ListView.builder(
              itemCount: customerIds.length,
              itemBuilder: (context, index) {
                return ProfileOption(
                  icon: Icons.person,
                  title: "Customer ID: ${customerIds[index]}",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfileInfoPage(customerId: customerIds[index]),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

/// Profile Option Widget
class ProfileOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const ProfileOption({Key? key, required this.icon, required this.title, required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white),
      onTap: onTap,
    );
  }
}

/// Profile Info Page (Displays Details of Selected Customer)
class ProfileInfoPage extends StatefulWidget {
  final int customerId;
  const ProfileInfoPage({Key? key, required this.customerId}) : super(key: key);

  @override
  _ProfileInfoPageState createState() => _ProfileInfoPageState();
}

class _ProfileInfoPageState extends State<ProfileInfoPage> {
  Map<String, dynamic>? customerData;

  @override
  void initState() {
    super.initState();
    fetchCustomerData();
  }

  /// Fetch customer data from PostgreSQL for the selected ID
  Future<void> fetchCustomerData() async {
    try {
      final db = DatabaseService();
      await db.connect();

      List<List<dynamic>> results = await db.connection.query(
        'SELECT name, email, phone, address, registered_date FROM customers WHERE customer_id = @id',
        substitutionValues: {'id': widget.customerId},
      );

      print("Query Result: $results"); // Debugging output

      if (results.isNotEmpty) {
        if (mounted) {
          setState(() {
            customerData = {
              "name": results[0][0] ?? "N/A",
              "email": results[0][1] ?? "N/A",
              "phone": results[0][2] ?? "N/A",
              "address": results[0][3] ?? "N/A",
              "registered_date": results[0][4]?.toString() ?? "N/A",
            };
          });
        }
      } else {
        print("No customer data found for ID ${widget.customerId}");
      }
    } catch (e) {
      print("Database Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("Profile Info - ID ${widget.customerId}"),
        backgroundColor: Colors.grey[900],
      ),
      body: customerData == null
          ? const Center(child: CircularProgressIndicator(color: Colors.greenAccent))
          : Padding(
              padding: const EdgeInsets.all(20),
              child: customerData!.isEmpty
                  ? const Center(child: Text("No Profile Data Found", style: TextStyle(color: Colors.white)))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Center(
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.grey,
                            child: Icon(Icons.person, size: 50, color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 20),
                        profileDetail("Name", customerData!["name"]),
                        profileDetail("Email", customerData!["email"]),
                        profileDetail("Phone", customerData!["phone"]),
                        profileDetail("Address", customerData!["address"]),
                        profileDetail("Registered Date", customerData!["registered_date"]),
                      ],
                    ),
            ),
    );
  }

  Widget profileDetail(String label, String value) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 16)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }
}
