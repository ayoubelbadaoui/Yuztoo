/** Copy shared by every lead form. Page-specific labels live in each <page>Content.js. */

export const FORM_COPY = {
  name: { label: 'Nom et prénom', autoComplete: 'name' },
  email: { label: 'E-mail', autoComplete: 'email' },
  phone: { label: 'Téléphone', hint: 'facultatif', autoComplete: 'tel' },
  optional: 'facultatif',
  consentLead: 'J’accepte que YuzToo utilise ces informations pour me recontacter. ',
  consentLink: { label: 'Politique de confidentialité', href: '/confidentialite' },
  honeypot: 'Laissez ce champ vide',
  sending: 'Envoi…',
  errors: {
    name: 'Indiquez votre nom (2 caractères minimum).',
    email: 'Indiquez une adresse e-mail valide.',
    consent: 'Cochez la case pour que nous puissions vous répondre.',
    rate_limited: 'Trop de demandes envoyées. Réessayez dans une heure, ou appelez-nous.',
    invalid: 'Un champ n’est pas valide. Vérifiez le formulaire.',
    server: 'L’envoi a échoué de notre côté. Réessayez, ou écrivez-nous directement.',
    network: 'Connexion impossible. Vérifiez votre réseau et réessayez.',
  },
  fallbackLead: 'Vous préférez écrire ? ',
}
