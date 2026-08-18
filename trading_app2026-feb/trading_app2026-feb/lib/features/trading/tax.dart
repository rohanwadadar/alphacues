// import 'package:flutter/material.dart';

// class TaxCenter extends StatelessWidget {
//   const TaxCenter({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       appBar: AppBar(
//         backgroundColor: Colors.black,
//         title: const Text('Tax Center', style: TextStyle(color: Colors.white)),
//         iconTheme: const IconThemeData(color: Colors.white),
//         actions: [
//           TextButton(
//             onPressed: () {},
//             child: const Text('Help', style: TextStyle(color: Colors.green)),
//           )
//         ],
//       ),
//       body: SingleChildScrollView(
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               _buildTimelineSection(),
//               const SizedBox(height: 24),
//               _buildDocumentsSection(),
//               const SizedBox(height: 24),
//               const SectionTitle(title: 'Tax Forms'),
//               ProfileOption(
//                 icon: Icons.description_outlined,
//                 title: 'Tax Documents',
//                 onTap: () {},
//               ),
//               const SizedBox(height: 24),
//               _buildFAQSection(),
//             ],
//           ),
//         ),
//       ),
//       bottomNavigationBar: BottomNavigationBar(
//         backgroundColor: Colors.black,
//         unselectedItemColor: Colors.grey,
//         selectedItemColor: Colors.white,
//         type: BottomNavigationBarType.fixed,
//         items: const [
//           BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: ''),
//           BottomNavigationBarItem(icon: Icon(Icons.refresh), label: ''),
//           BottomNavigationBarItem(icon: Icon(Icons.alarm), label: ''),
//           BottomNavigationBarItem(icon: Icon(Icons.video_call), label: ''),
//           BottomNavigationBarItem(icon: Icon(Icons.person), label: ''),
//         ],
//         currentIndex: 4,
//       ),
//     );
//   }

//   Widget _buildTimelineSection() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           children: [
//             const Text(
//               'Timeline',
//               style: TextStyle(
//                 color: Colors.white,
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(width: 8),
//             Icon(Icons.info_outline, color: Colors.grey[400], size: 18),
//           ],
//         ),
//         const SizedBox(height: 16),
//         _buildTimelineItem(
//           date: 'February 18, 2025',
//           description: 'You don\'t have a Consolidated 1099 this year',
//           isCompleted: true,
//         ),
//         _buildTimelineItem(
//           date: 'April 15, 2025',
//           description: 'IRS tax filing deadline',
//           isCompleted: false,
//         ),
//         Container(
//           margin: const EdgeInsets.only(top: 16),
//           padding: const EdgeInsets.all(12),
//           decoration: BoxDecoration(
//             color: Colors.grey[900],
//             borderRadius: BorderRadius.circular(8),
//           ),
//           child: Row(
//             children: [
//               const Icon(Icons.access_time, color: Colors.white),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text(
//                       'Did you know you have until April 15 to contribute to an IRA for 2024?',
//                       style: TextStyle(color: Colors.white),
//                     ),
//                     TextButton(
//                       onPressed: () {},
//                       style: TextButton.styleFrom(
//                         padding: EdgeInsets.zero,
//                         alignment: Alignment.centerLeft,
//                       ),
//                       child: const Text(
//                         'Open an IRA',
//                         style: TextStyle(color: Colors.white, decoration: TextDecoration.underline),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildTimelineItem({
//     required String date,
//     required String description,
//     required bool isCompleted,
//   }) {
//     return Row(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Column(
//           children: [
//             Container(
//               width: 24,
//               height: 24,
//               decoration: BoxDecoration(
//                 color: isCompleted ? Colors.green : Colors.transparent,
//                 border: Border.all(
//                   color: isCompleted ? Colors.green : Colors.grey,
//                   width: 2,
//                 ),
//                 shape: BoxShape.circle,
//               ),
//               child: isCompleted
//                   ? const Icon(Icons.check, color: Colors.white, size: 16)
//                   : null,
//             ),
//             Container(
//               width: 2,
//               height: 30,
//               color: Colors.grey[600],
//             ),
//           ],
//         ),
//         const SizedBox(width: 16),
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 date,
//                 style: const TextStyle(
//                   color: Colors.white,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               const SizedBox(height: 4),
//               Text(
//                 description,
//                 style: TextStyle(
//                   color: Colors.grey[400],
//                   fontSize: 13,
//                 ),
//               ),
//               const SizedBox(height: 16),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildDocumentsSection() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           'Documents',
//           style: TextStyle(
//             color: Colors.white,
//             fontSize: 18,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         const SizedBox(height: 12),
//         Text(
//           'We\'ll email you once your 2024 tax documents are ready.',
//           style: TextStyle(color: Colors.grey[400]),
//         ),
//         const SizedBox(height: 12),
//         TextButton(
//           onPressed: () {},
//           style: TextButton.styleFrom(
//             padding: EdgeInsets.zero,
//             alignment: Alignment.centerLeft,
//           ),
//           child: const Text(
//             'View previous documents',
//             style: TextStyle(
//               color: Colors.white,
//               decoration: TextDecoration.underline,
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildFAQSection() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           'Frequently asked questions',
//           style: TextStyle(
//             color: Colors.white,
//             fontSize: 18,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         const SizedBox(height: 16),
//         _buildFAQItem('What is the cost basis and the IRS wash sale rule?'),
//         const Divider(color: Colors.grey),
//         _buildFAQItem('Why didn\'t I receive a Consolidated 1099?'),
//       ],
//     );
//   }

//   Widget _buildFAQItem(String question) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8.0),
//       child: Row(
//         children: [
//           Expanded(
//             child: Text(
//               question,
//               style: const TextStyle(color: Colors.white),
//             ),
//           ),
//           const Icon(
//             Icons.expand_more,
//             color: Colors.grey,
//           ),
//         ],
//       ),
//     );
//   }
// }

// class SectionTitle extends StatelessWidget {
//   final String title;

//   const SectionTitle({Key? key, required this.title}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8.0),
//       child: Text(
//         title,
//         style: const TextStyle(
//           color: Colors.white,
//           fontSize: 18,
//           fontWeight: FontWeight.bold,
//         ),
//       ),
//     );
//   }
// }

// class ProfileOption extends StatelessWidget {
//   final IconData icon;
//   final String title;
//   final VoidCallback onTap;

//   const ProfileOption({
//     Key? key,
//     required this.icon,
//     required this.title,
//     required this.onTap,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return InkWell(
//       onTap: onTap,
//       child: Container(
//         padding: const EdgeInsets.symmetric(vertical: 12.0),
//         child: Row(
//           children: [
//             Icon(icon, color: Colors.white),
//             const SizedBox(width: 16),
//             Text(
//               title,
//               style: const TextStyle(color: Colors.white),
//             ),
//             const Spacer(),
//             const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
//           ],
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';

class TaxCenter extends StatelessWidget {
  const TaxCenter({Key? key}) : super(key: key);

  final Color _primaryColor = const Color.fromARGB(255, 114, 70, 192);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Tax Center', style: TextStyle(color: Colors.black)),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          TextButton(
            onPressed: () {},
            child: Text('Help', style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold)),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTimelineSection(),
              const SizedBox(height: 24),
              _buildDocumentsSection(),
              const SizedBox(height: 24),
              _buildTaxFormsSection(),
              const SizedBox(height: 24),
              _buildFAQSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Timeline',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.info_outline, color: Colors.grey[600], size: 20),
            ],
          ),
          const SizedBox(height: 20),
          _buildTimelineItem(
            date: 'February 18, 2025',
            description: 'You don\'t have a Consolidated 1099 this year',
            isCompleted: true,
          ),
          _buildTimelineItem(
            date: 'April 15, 2025',
            description: 'IRS tax filing deadline',
            isCompleted: false,
            isLast: true,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _primaryColor.withOpacity(0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.access_time, color: _primaryColor, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Did you know you have until April 15 to contribute to an IRA for 2024?',
                        style: TextStyle(color: Colors.black, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Open an IRA',
                          style: TextStyle(
                            color: _primaryColor,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem({
    required String date,
    required String description,
    required bool isCompleted,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isCompleted ? _primaryColor : Colors.transparent,
                border: Border.all(
                  color: isCompleted ? _primaryColor : Colors.grey[400]!,
                  width: 2.5,
                ),
                shape: BoxShape.circle,
              ),
              child: isCompleted
                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                  : null,
            ),
            if (!isLast)
              Container(
                width: 2.5,
                height: 40,
                color: Colors.grey[300],
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                date,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              if (!isLast) const SizedBox(height: 20),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.folder_outlined, color: _primaryColor, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Documents',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'We\'ll email you once your 2024 tax documents are ready.',
                  style: TextStyle(color: Colors.grey[700], fontSize: 14),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'View previous documents',
                    style: TextStyle(
                      color: _primaryColor,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaxFormsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tax Forms',
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () {},
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.description_outlined,
                      color: _primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Tax Documents',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.help_outline, color: _primaryColor, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Frequently Asked Questions',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildFAQItem('What is the cost basis and the IRS wash sale rule?'),
          Divider(color: Colors.grey[300], height: 1),
          _buildFAQItem('Why didn\'t I receive a Consolidated 1099?'),
          Divider(color: Colors.grey[300], height: 1),
          _buildFAQItem('When will I receive my tax documents?'),
          Divider(color: Colors.grey[300], height: 1),
          _buildFAQItem('How do I report cryptocurrency on my taxes?'),
        ],
      ),
    );
  }

  Widget _buildFAQItem(String question) {
    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Row(
          children: [
            Expanded(
              child: Text(
                question,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                ),
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down,
              color: Colors.grey[600],
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;

  const SectionTitle({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class ProfileOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color primaryColor;

  const ProfileOption({
    Key? key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.primaryColor = const Color.fromARGB(255, 114, 70, 192),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, color: primaryColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
          ],
        ),
      ),
    );
  }
}