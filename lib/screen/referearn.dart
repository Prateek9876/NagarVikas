import 'package:NagarVikas/localization/app_localizations.dart';
import 'package:flutter/material.dart';

class ReferAndEarnPage extends StatelessWidget {
  final String referralCode = "NAGAR123";

  const ReferAndEarnPage({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.get('referearn') ?? "Refer & Earn"),
        backgroundColor: const Color.fromARGB(255, 4, 204, 240),
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 30),

            // Invite Friends Text
            Text(
              loc.get('inviteFriends') ?? "Invite Your Friends!",
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurpleAccent),
            ),
            SizedBox(height: 10),

            Text(
              loc.get("earnRewardsDescription")??"Earn rewards by referring your friends to NagarVikas. Share your referral code now!",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),

            SizedBox(height: 20),

            // Referral Code Display
            Container(
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.deepPurpleAccent.withAlpha((0.1 * 255).toInt()),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.deepPurpleAccent, width: 2),
              ),
              child: Text(
                referralCode,
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurpleAccent),
              ),
            ),

            SizedBox(height: 20),

            // Share Button
            ElevatedButton.icon(
              onPressed: () {
                // Show a confirmation message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                       loc.get("referralCodeCopied") ?? "Referral code copied! Share it with your friends."),
                    duration: Duration(seconds: 2),
                    backgroundColor: const Color.fromARGB(255, 7, 7, 7),
                  ),
                );
              },
              icon: Icon(Icons.share, color: Colors.white),
              label: Text(
                  loc.get("shareReferralCode") ?? "Share Referral Code",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                backgroundColor: const Color.fromARGB(255, 7, 230, 107),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
