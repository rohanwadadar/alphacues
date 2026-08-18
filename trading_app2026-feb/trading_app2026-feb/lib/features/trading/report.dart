import 'package:flutter/material.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  _ReportPageState createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  String? selectedOption;
  final Color _primaryColor = const Color.fromARGB(255, 114, 70, 192);

  // For the "Reports" subpage
  String selectedAccount = "Individual Brokerage";
  DateTime startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime endDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: _primaryColor),
          onPressed: () {
            if (selectedOption == null) {
              Navigator.pop(context);
            } else {
              setState(() => selectedOption = null);
            }
          },
        ),
        title: Text(
          selectedOption == null ? 'Reports and Statements' : selectedOption!,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _buildCurrentView(),
        ),
      ),
    );
  }

  Widget _buildCurrentView() {
    if (selectedOption == null) {
      return _buildMainMenu();
    } else if (selectedOption == "Reports") {
      return _buildReportsSubPage();
    } else {
      // Handles all statement lists (Individual, Futures, etc.)
      return _buildStatementsListSubPage(selectedOption!);
    }
  }

  /// **Main Menu View**
  Widget _buildMainMenu() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(
          "Account activity reports",
          "Generate and download custom CSV files for your individual or retirement account activity.",
        ),
        _buildSectionCard([
          _buildMenuTile("Reports"),
        ]),
        const SizedBox(height: 24),
        _buildHeader(
          "Monthly statements",
          "PDF statements are available within the first 2 weeks of the following month.",
        ),
        _buildSectionCard([
          _buildMenuTile("Individual"),
          _buildDivider(),
          _buildMenuTile("Futures & event contracts"),
        ]),
        const SizedBox(height: 24),
        _buildHeader(
          "Daily statements",
          "PDF statements are available within 1 business day after market close.",
        ),
        _buildSectionCard([
          _buildMenuTile("Futures daily"),
        ]),
      ],
    );
  }

  /// **Subpage 1: Custom CSV Reports Generator**
  Widget _buildReportsSubPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader("Select Account", "Choose which account to run the report for."),
        _buildSectionCard([
          _buildDropdownTile("Account", selectedAccount, (val) {
            setState(() => selectedAccount = val!);
          }, ["Individual Brokerage", "Retirement (IRA)", "Joint Account"]),
        ]),
        const SizedBox(height: 24),
        _buildHeader("Date Range", "The CSV will include all activity between these dates."),
        _buildSectionCard([
          _buildDateTile("Start Date", startDate, (date) => setState(() => startDate = date)),
          _buildDivider(),
          _buildDateTile("End Date", endDate, (date) => setState(() => endDate = date)),
        ]),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Report is being generated. You will receive an email shortly.")),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text("Generate CSV Report", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        )
      ],
    );
  }

  /// **Subpage 2: List of PDF Statements**
  Widget _buildStatementsListSubPage(String sectionName) {
    // Mock list of months
    final months = [
      "January 2026", "December 2025", "November 2025", "October 2025", "September 2025"
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(sectionName, "Tap a month to view or download the PDF statement."),
        _buildSectionCard(
          months.map((month) {
            return Column(
              children: [
                ListTile(
                  leading: Icon(Icons.picture_as_pdf_outlined, color: _primaryColor),
                  title: Text(month, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                  trailing: Icon(Icons.download_outlined, color: _primaryColor, size: 20),
                  onTap: () {
                    // Open PDF logic
                  },
                ),
                if (month != months.last) _buildDivider(),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  // --- HELPER UI COMPONENTS ---

  Widget _buildHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text(title, style: TextStyle(color: _primaryColor, fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(width: 4),
          Icon(Icons.info_outline, size: 16, color: Colors.grey[400]),
        ]),
        const SizedBox(height: 6),
        Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 13, height: 1.4)),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildSectionCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildMenuTile(String title) {
    return ListTile(
      title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
      trailing: Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 14),
      onTap: () => setState(() => selectedOption = title),
    );
  }

  Widget _buildDropdownTile(String label, String value, Function(String?) onChanged, List<String> items) {
    return ListTile(
      title: Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
      trailing: DropdownButton<String>(
        value: value,
        underline: const SizedBox(),
        icon: Icon(Icons.keyboard_arrow_down, color: _primaryColor),
        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDateTile(String label, DateTime date, Function(DateTime) onPick) {
    return ListTile(
      title: Text(label, style: const TextStyle(fontSize: 15)),
      trailing: Text(
        "${date.month}/${date.day}/${date.year}",
        style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold),
      ),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (picked != null) onPick(picked);
      },
    );
  }

  Widget _buildDivider() => Divider(color: Colors.grey[300], height: 1, indent: 16, endIndent: 16);
}