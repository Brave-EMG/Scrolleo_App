import 'dart:html' as html;

void openFeexpayFormWeb(String htmlContent) {
  // Crée un div temporaire pour parser le HTML du formulaire
  final tempDiv = html.DivElement();
  tempDiv.setInnerHtml(htmlContent, treeSanitizer: html.NodeTreeSanitizer.trusted);

  // Récupère le formulaire
  final form = tempDiv.querySelector('form') as html.FormElement?;
  if (form != null) {
    html.document.body?.append(form);
    form.submit();
    form.remove();
  }
} 