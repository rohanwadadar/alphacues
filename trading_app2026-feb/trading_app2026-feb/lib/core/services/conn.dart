import 'package:postgres/postgres.dart';

class DatabaseService {
  late PostgreSQLConnection connection;

  Future<void> connect() async {
    print("Attempting to connect to PostgreSQL...");

    connection = PostgreSQLConnection(
      'localhost',  // Or use your IP address if connecting remotely
      5432,  // Make sure this matches your database port
      'PortfolioDB',
      username: 'rohan',
      password: '1234',
    );

    try {
      await connection.open();
      print("✅ Connected to PostgreSQL Database");

      // Run a test query
      var result = await connection.query("SELECT * FROM customers;");
      print("Customers: $result"); // Print results to check connection
    } catch (e) {
      print("❌ Database connection error: $e");
    }
  }

  Future<void> close() async {
    await connection.close();
  }
}
