import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({Key? key}) : super(key: key);

  @override
  _HelpSupportScreenState createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final List<FAQItem> _faqItems = [
    FAQItem(
      question: 'Comment fonctionne Scrolleo ?',
      answer: 'Scrolleo est une plateforme de streaming qui vous permet de regarder des films et séries en ligne. Vous pouvez acheter des pièces pour accéder au contenu ou souscrire à un abonnement Premium.',
    ),
    FAQItem(
      question: 'Comment acheter des pièces ?',
      answer: 'Allez dans votre profil > Mon Portefeuille et choisissez le pack de pièces qui vous convient. Plusieurs méthodes de paiement sont disponibles : Mobile Money, carte bancaire, Orange Money.',
    ),
    FAQItem(
      question: 'Comment annuler mon abonnement ?',
      answer: 'Allez dans votre profil > Mon Abonnement et cliquez sur "Annuler l\'abonnement". Vous continuerez à bénéficier des avantages jusqu\'à la fin de la période payée.',
    ),
    FAQItem(
      question: 'Comment télécharger du contenu ?',
      answer: 'Avec un abonnement Premium, vous pouvez télécharger du contenu pour le regarder hors ligne. Cliquez sur l\'icône de téléchargement sur la page du film ou de l\'épisode.',
    ),
    FAQItem(
      question: 'Comment signaler un problème ?',
      answer: 'Utilisez la fonction "Signaler un problème" dans cette page ou contactez notre support par email à support@scrolleo.com',
    ),
    FAQItem(
      question: 'Comment changer la qualité vidéo ?',
      answer: 'Allez dans Paramètres > Lecture > Qualité vidéo et choisissez entre Auto, HD ou 4K selon votre connexion internet.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < AppTheme.mobileBreakpoint;
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          'Aide & Support',
          style: TextStyle(
            fontSize: isMobile ? 18.0 : 20.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/profile'),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearchSection(isMobile),
            SizedBox(height: isMobile ? 24.0 : 32.0),
            _buildQuickActions(isMobile),
            SizedBox(height: isMobile ? 24.0 : 32.0),
            _buildFAQSection(isMobile),
            SizedBox(height: isMobile ? 24.0 : 32.0),
            _buildContactSection(isMobile),
            SizedBox(height: isMobile ? 24.0 : 32.0),
            _buildResourcesSection(isMobile),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchSection(bool isMobile) {
    return Card(
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16.0 : 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rechercher de l\'aide',
              style: TextStyle(
                color: Colors.white,
                fontSize: isMobile ? 18.0 : 20.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: isMobile ? 12.0 : 16.0),
            TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Tapez votre question...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[800],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.smallRadius),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 12.0 : 16.0,
                  vertical: isMobile ? 12.0 : 16.0,
                ),
              ),
              onChanged: (value) {
                // TODO: Implémenter la recherche
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(bool isMobile) {
    return Card(
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16.0 : 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Actions rapides',
              style: TextStyle(
                color: Colors.white,
                fontSize: isMobile ? 18.0 : 20.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: isMobile ? 16.0 : 20.0),
            _buildQuickActionItem(
              'Signaler un problème',
              Icons.report_problem,
              Colors.orange,
              () => _showReportProblemDialog(),
              isMobile,
            ),
            _buildQuickActionItem(
              'Demander un remboursement',
              Icons.money_off,
              Colors.red,
              () => _showRefundDialog(),
              isMobile,
            ),
            _buildQuickActionItem(
              'Suggérer une fonctionnalité',
              Icons.lightbulb,
              Colors.amber,
              () => _showFeatureRequestDialog(),
              isMobile,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionItem(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
    bool isMobile,
  ) {
    return Card(
      color: Colors.grey[800],
      margin: EdgeInsets.only(bottom: isMobile ? 8.0 : 12.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.smallRadius),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
        leading: Container(
          padding: EdgeInsets.all(isMobile ? 8.0 : 12.0),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(AppTheme.smallRadius),
          ),
          child: Icon(
            icon,
            color: color,
            size: isMobile ? 20.0 : 24.0,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: isMobile ? 14.0 : 16.0,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: Colors.grey[400],
          size: isMobile ? 16.0 : 18.0,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildFAQSection(bool isMobile) {
    return Card(
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16.0 : 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Questions fréquentes',
              style: TextStyle(
                color: Colors.white,
                fontSize: isMobile ? 18.0 : 20.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: isMobile ? 16.0 : 20.0),
            ..._faqItems.map((faq) => _buildFAQItem(faq, isMobile)),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem(FAQItem faq, bool isMobile) {
    return ExpansionTile(
      title: Text(
        faq.question,
        style: TextStyle(
          color: Colors.white,
          fontSize: isMobile ? 14.0 : 16.0,
          fontWeight: FontWeight.w500,
        ),
      ),
      iconColor: Colors.amber,
      collapsedIconColor: Colors.grey[400],
      children: [
        Padding(
          padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
          child: Text(
            faq.answer,
            style: TextStyle(
              color: Colors.grey[300],
              fontSize: isMobile ? 13.0 : 15.0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactSection(bool isMobile) {
    return Card(
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16.0 : 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nous contacter',
              style: TextStyle(
                color: Colors.white,
                fontSize: isMobile ? 18.0 : 20.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: isMobile ? 16.0 : 20.0),
            _buildContactItem(
              'Email',
              'scrolleo@brave-emg.com',
              Icons.email,
              () => _launchEmail(),
              isMobile,
            ),
            _buildContactItem(
              'Téléphone',
              '+229 0167591817',
              Icons.phone,
              () => _launchPhone(),
              isMobile,
            ),
            _buildContactItem(
              'WhatsApp',
              '+229 0167591817',
              Icons.message,
              () => _launchWhatsApp(),
              isMobile,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactItem(
    String title,
    String value,
    IconData icon,
    VoidCallback? onTap,
    bool isMobile,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 8.0 : 12.0,
        vertical: isMobile ? 4.0 : 8.0,
      ),
      leading: Icon(
        icon,
        color: Colors.amber,
        size: isMobile ? 20.0 : 24.0,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: Colors.white,
          fontSize: isMobile ? 14.0 : 16.0,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        value,
        style: TextStyle(
          color: Colors.grey[400],
          fontSize: isMobile ? 12.0 : 14.0,
        ),
      ),
      trailing: onTap != null
          ? Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey[400],
              size: isMobile ? 16.0 : 18.0,
            )
          : null,
      onTap: onTap,
    );
  }

  Widget _buildResourcesSection(bool isMobile) {
    return Card(
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16.0 : 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ressources',
              style: TextStyle(
                color: Colors.white,
                fontSize: isMobile ? 18.0 : 20.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: isMobile ? 16.0 : 20.0),
            _buildResourceItem(
              'Guide d\'utilisation',
              Icons.book,
              () => _launchGuide(),
              isMobile,
            ),
            _buildResourceItem(
              'Conditions d\'utilisation',
              Icons.description,
              () => _launchTerms(),
              isMobile,
            ),
            _buildResourceItem(
              'Politique de confidentialité',
              Icons.privacy_tip,
              () => _launchPrivacy(),
              isMobile,
            ),
            _buildResourceItem(
              'Blog',
              Icons.article,
              () => _launchBlog(),
              isMobile,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResourceItem(
    String title,
    IconData icon,
    VoidCallback onTap,
    bool isMobile,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 8.0 : 12.0,
        vertical: isMobile ? 4.0 : 8.0,
      ),
      leading: Icon(
        icon,
        color: Colors.amber,
        size: isMobile ? 20.0 : 24.0,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: Colors.white,
          fontSize: isMobile ? 14.0 : 16.0,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        color: Colors.grey[400],
        size: isMobile ? 16.0 : 18.0,
      ),
      onTap: onTap,
    );
  }

  void _showReportProblemDialog() {
    final TextEditingController controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Signaler un problème',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Décrivez le problème que vous rencontrez :',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 4,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Décrivez le problème...',
                hintStyle: TextStyle(color: Colors.grey),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.amber),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              Navigator.pop(context);
              _submitReport(controller.text);
            },
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
  }

  void _showRefundDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Demande de remboursement',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Pour demander un remboursement, veuillez nous contacter par email à scrolleo@brave-emg.com en précisant votre numéro de commande et la raison de votre demande.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              Navigator.pop(context);
              _launchEmail();
            },
            child: const Text('Contacter'),
          ),
        ],
      ),
    );
  }

  void _showFeatureRequestDialog() {
    final TextEditingController controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Suggérer une fonctionnalité',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Décrivez la fonctionnalité que vous aimeriez voir :',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 4,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Décrivez votre suggestion...',
                hintStyle: TextStyle(color: Colors.grey),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.amber),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              Navigator.pop(context);
              _submitFeatureRequest(controller.text);
            },
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
  }

  void _submitReport(String description) {
    // TODO: Implémenter l'envoi du rapport
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Rapport envoyé avec succès'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _submitFeatureRequest(String description) {
    // TODO: Implémenter l'envoi de la suggestion
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Suggestion envoyée avec succès'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'scrolleo@brave-emg.com',
      query: 'subject=Support Scrolleo',
    );
    
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  void _launchPhone() async {
    final Uri phoneUri = Uri.parse('tel:+2290167591817');
    
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  void _launchWhatsApp() async {
    final Uri whatsappUri = Uri.parse('https://wa.me/2290167591817');
    
    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri);
    }
  }

  void _launchGuide() async {
    final Uri guideUri = Uri.parse('https://scrolleo.com/guide');
    
    if (await canLaunchUrl(guideUri)) {
      await launchUrl(guideUri);
    }
  }

  void _launchTerms() async {
    final Uri termsUri = Uri.parse('https://scrolleo.com/terms');
    
    if (await canLaunchUrl(termsUri)) {
      await launchUrl(termsUri);
    }
  }

  void _launchPrivacy() async {
    final Uri privacyUri = Uri.parse('https://scrolleo.com/privacy');
    
    if (await canLaunchUrl(privacyUri)) {
      await launchUrl(privacyUri);
    }
  }

  void _launchBlog() async {
    final Uri blogUri = Uri.parse('https://scrolleo.com/blog');
    
    if (await canLaunchUrl(blogUri)) {
      await launchUrl(blogUri);
    }
  }
}

class FAQItem {
  final String question;
  final String answer;

  FAQItem({required this.question, required this.answer});
} 