// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get cancel => 'Annuler';

  @override
  String get confirm => 'Confirmer';

  @override
  String get tryAgain => 'Réessayer';

  @override
  String get delete => 'Supprimer';

  @override
  String get optional => '(facultatif)';

  @override
  String get yourDataSafe => 'Vos données sont en sécurité';

  @override
  String get tabHome => 'Accueil';

  @override
  String get tabRoute => 'Itinéraire';

  @override
  String get tabLogin => 'Connexion';

  @override
  String get tabMyTrips => 'Mes trajets';

  @override
  String get tabChat => 'Messages';

  @override
  String get tabProfile => 'Profil';

  @override
  String get welcomeTagline => 'Voyagez entre villes,\nensemble.';

  @override
  String get welcomeCreateAccount => 'Créer un compte';

  @override
  String get welcomeSignIn => 'Se connecter';

  @override
  String get registerTitle => 'Créez votre compte';

  @override
  String get registerSubtitle =>
      'Entrez votre nom et numéro de téléphone pour commencer.';

  @override
  String get registerFirstName => 'Prénom *';

  @override
  String get registerFirstNameHint => 'ex. Michel';

  @override
  String get registerLastName => 'Nom de famille';

  @override
  String get registerLastNameHint => 'ex. Dupont';

  @override
  String get registerPhoneNumber => 'Numéro de téléphone *';

  @override
  String get registerContinue => 'Continuer';

  @override
  String get registerTermsPrefix => 'En continuant, vous acceptez nos ';

  @override
  String get registerTermsLink => 'Conditions et Politique de confidentialité.';

  @override
  String get registerAlreadyHaveAccount => 'Déjà un compte ? ';

  @override
  String get registerErrorFirstName => 'Veuillez entrer votre prénom.';

  @override
  String get registerErrorPhone =>
      'Entrez un numéro camerounais valide à 9 chiffres.';

  @override
  String get registerErrorServer =>
      'Impossible de joindre le serveur. Vérifiez votre connexion et réessayez.';

  @override
  String get registerAccountExistsTitle => 'Compte existant';

  @override
  String get registerAccountExistsBody =>
      'Un compte existe déjà pour ce numéro.\n\nVeuillez vous connecter à la place.';

  @override
  String get loginTitle => 'Se connecter';

  @override
  String get loginSubtitle =>
      'Entrez votre numéro de téléphone pour vous connecter.';

  @override
  String get loginPhoneHint => '6 75 12 34 56';

  @override
  String get loginSendCode => 'Envoyer le code';

  @override
  String get loginNoAccountLink => 'Pas de compte ? Créez-en un';

  @override
  String get loginNoAccountTitle => 'Aucun compte trouvé';

  @override
  String get loginNoAccountBody =>
      'Aucun compte n\'existe pour ce numéro.\n\nVeuillez d\'abord créer un compte.';

  @override
  String get loginErrorPhone =>
      'Entrez un numéro camerounais valide à 9 chiffres.';

  @override
  String get loginErrorServer => 'Impossible de joindre le serveur. Réessayez.';

  @override
  String get otpSignInTitle => 'Connexion à HolaRide';

  @override
  String get otpVerifyTitle => 'Vérifiez votre numéro';

  @override
  String get otpSentTo => 'Nous avons envoyé un code à 6 chiffres au ';

  @override
  String get otpWrongNumber => 'Mauvais numéro ? Retourner';

  @override
  String otpDevMode(String code) {
    return 'MODE DEV — votre code est $code';
  }

  @override
  String get otpVerifying => 'Vérification…';

  @override
  String otpResendIn(String countdown) {
    return 'Renvoyer le code dans $countdown';
  }

  @override
  String get otpResend => 'Renvoyer le code';

  @override
  String get otpResending => 'Envoi en cours…';

  @override
  String get otpErrorVerify =>
      'Échec de la vérification. Vérifiez le code et réessayez.';

  @override
  String get otpErrorResend => 'Impossible de renvoyer le code. Réessayez.';

  @override
  String get otpAccountExistsTitle => 'Compte existant';

  @override
  String get otpAccountExistsBody =>
      'Un compte existe déjà pour ce numéro.\n\nVeuillez vous connecter à la place.';

  @override
  String get otpNoAccountTitle => 'Aucun compte trouvé';

  @override
  String get otpNoAccountBody =>
      'Aucun compte trouvé pour ce numéro.\n\nVeuillez d\'abord créer un compte.';

  @override
  String get otpCreateAccount => 'Créer un compte';

  @override
  String get nameEntryTitle => 'Comment doit-on\nvous appeler ?';

  @override
  String get nameEntrySubtitle => 'Ce nom sera visible sur votre profil';

  @override
  String get nameEntryHint => 'ex. Michel Kamga';

  @override
  String get nameEntryError => 'Dites-nous comment vous appeler.';

  @override
  String get nameEntrySaveError =>
      'Impossible de sauvegarder votre nom. Réessayez.';

  @override
  String get homeGetStarted => 'Commencer';

  @override
  String get homeMaybeLater => 'Plus tard';

  @override
  String get homeJoinTitle => 'Rejoignez HolaRide';

  @override
  String get homeJoinBody =>
      'Créez un compte pour réserver des trajets, chatter avec les conducteurs et voyager en toute sécurité.';

  @override
  String get homeHeroTitle => 'Des trajets sur votre route';

  @override
  String get homeHeroBody =>
      'HolaRide vous connecte avec des conducteurs vérifiés faisant le même trajet.';

  @override
  String get homeFindRide => 'Trouver un trajet';

  @override
  String get homeRideShare => 'Covoiturage';

  @override
  String get homeAvailableTrips => 'Trajets disponibles';

  @override
  String get homeSeeAll => 'Voir tout';

  @override
  String get homeNoTrips => 'Aucun trajet disponible';

  @override
  String get homeNoTripsHint =>
      'Essayez un autre itinéraire ou vérifiez plus tard.';

  @override
  String get homeExploreRoutes => 'Explorer les routes populaires';

  @override
  String get homeShareRideTitle => 'Partagez votre trajet, réduisez les coûts';

  @override
  String get homeShareRideBody => 'Partagez votre tarif et voyagez ensemble.';

  @override
  String get homeRiderCount => 'Utilisateurs actifs';

  @override
  String get homeTripHours => 'Heures de trajet effectuées';

  @override
  String homeHelloName(String name) {
    return 'Bonjour $name 👋';
  }

  @override
  String get homeHello => 'Bonjour 👋';

  @override
  String get homePerSeat => 'par siège';

  @override
  String homeSeatsLeft(int count) {
    return '$count restant';
  }

  @override
  String get homeLoadError => 'Impossible de charger les trajets à proximité.';

  @override
  String get searchTitle => 'Trouver un trajet';

  @override
  String get searchFrom => 'Au départ de';

  @override
  String get searchTo => 'À destination de';

  @override
  String get searchDate => 'Date de départ';

  @override
  String get searchChange => 'Modifier';

  @override
  String searchToday(int day, String month) {
    return 'Aujourd\'hui, $day $month';
  }

  @override
  String searchTomorrow(int day, String month) {
    return 'Demain, $day $month';
  }

  @override
  String get searchButton => 'Rechercher des trajets';

  @override
  String get searchErrorRoute =>
      'Veuillez sélectionner le départ et la destination.';

  @override
  String get searchErrorSameCity =>
      'Le départ et la destination doivent être des villes différentes.';

  @override
  String get searchCityFrom => 'Ville ou point de prise en charge';

  @override
  String get searchCityTo => 'Ville ou point de dépose';

  @override
  String get searchPickerHint =>
      'Rechercher une ville ou un point de prise en charge';

  @override
  String get searchPopularCities => 'Villes populaires';

  @override
  String get searchNoMatch => 'Aucun lieu correspondant.';

  @override
  String get searchSortTime => 'Trier par heure';

  @override
  String get searchSortPrice => 'Trier par prix';

  @override
  String get searchTimeLabel => 'Heure';

  @override
  String get searchPriceLabel => 'Prix';

  @override
  String get searchNoResults =>
      'Aucun trajet sur cet itinéraire et cette date. Essayez une autre date ou soyez parmi les premiers à le demander.';

  @override
  String get searchLoadError =>
      'Impossible de charger les trajets. Tirez vers le bas pour réessayer.';

  @override
  String get bookingsTitle => 'Mes trajets';

  @override
  String get bookingsAll => 'Tous';

  @override
  String get bookingsUpcoming => 'À venir';

  @override
  String get bookingsPast => 'Passés';

  @override
  String get bookingsLoginPrompt => 'Connectez-vous pour voir vos réservations';

  @override
  String get bookingsLoginHint =>
      'Vos demandes de trajet et votre historique apparaîtront ici une fois connecté.';

  @override
  String get bookingsLoginSignup => 'Se connecter / S\'inscrire';

  @override
  String get bookingsEmpty => 'Aucune réservation pour l\'instant.';

  @override
  String get bookingsLoadError => 'Impossible de charger vos réservations.';

  @override
  String get bookingsTripFallback => 'Trajet';

  @override
  String get bookingsChat => 'Chat';

  @override
  String get bookingsTrack => 'Suivre';

  @override
  String bookingsRatePassenger(String name) {
    return 'Évaluer $name';
  }

  @override
  String bookingsSeatSingular(int count) {
    return '$count siège';
  }

  @override
  String bookingsSeatPlural(int count) {
    return '$count sièges';
  }

  @override
  String get bookingStatusWaiting => 'En attente';

  @override
  String get bookingStatusAwaitingPayment => 'En attente de paiement';

  @override
  String get bookingStatusPaid => 'Payé';

  @override
  String get bookingStatusDeclined => 'Refusée';

  @override
  String get bookingStatusCancelled => 'Annulée';

  @override
  String get bookingStatusCompleted => 'Terminée';

  @override
  String get bookingStatusNoShow => 'Absence';

  @override
  String get bookingStatusUnknown => 'Inconnu';

  @override
  String get chatInboxTitle => 'Messages';

  @override
  String get chatInboxEmpty => 'Aucune conversation';

  @override
  String get chatInboxEmptyHint =>
      'Les chats s\'ouvrent automatiquement dès qu\'une réservation est payée ou pour tout trajet que vous publiez.';

  @override
  String get chatInboxDeleteTitle => 'Supprimer la conversation ?';

  @override
  String get chatInboxDeleteBody =>
      'Ceci supprime la conversation de votre liste. Le trajet et votre réservation ne sont pas affectés.';

  @override
  String get chatInboxDelete => 'Supprimer';

  @override
  String get chatInboxDriver => 'Conducteur';

  @override
  String get chatInboxPassenger => 'Passager';

  @override
  String get chatTripTitle => 'Chat du trajet';

  @override
  String get chatDeleteChat => 'Supprimer la conversation';

  @override
  String get chatNoMessages => 'Aucun message — dites bonjour !';

  @override
  String get chatDeletedByYou => 'Vous avez supprimé ce message';

  @override
  String get chatDeleted => 'Ce message a été supprimé';

  @override
  String get chatSharedLocation => 'Position partagée · Appuyer pour ouvrir';

  @override
  String get chatTypePlaceholder => 'Écrire un message...';

  @override
  String get chatShareLocation => 'Partager la position';

  @override
  String get chatReadOnlyCancelled =>
      'Trajet annulé — la conversation est désormais en lecture seule.';

  @override
  String get chatReadOnlyCompleted =>
      'Trajet terminé — la conversation est désormais en lecture seule.';

  @override
  String get chatSendError => 'Le message n\'a pas été envoyé. Réessayez.';

  @override
  String get chatLocationError =>
      'Impossible d\'obtenir votre position. Vérifiez les permissions et réessayez.';

  @override
  String get chatMapsError =>
      'Impossible d\'ouvrir Maps. Assurez-vous que Google Maps est installé.';

  @override
  String get chatDeleteMsgTitle => 'Supprimer ce message ?';

  @override
  String get chatDeleteMsgBody =>
      'Ceci le supprime pour tout le monde dans cette conversation — impossible à annuler.';

  @override
  String get chatDeleteMsgError =>
      'Impossible de supprimer ce message. Réessayez.';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsMarkRead => 'Tout marquer comme lu';

  @override
  String get notificationsEmpty => 'Aucune notification';

  @override
  String get notificationsEmptyHint =>
      'Vous verrez les mises à jour ici quand quelque chose se passe.';

  @override
  String get notificationsJustNow => 'À l\'instant';

  @override
  String notificationsMinsAgo(int n) {
    return 'il y a $n min';
  }

  @override
  String notificationsHoursAgo(int n) {
    return 'il y a $n h';
  }

  @override
  String get notificationsYesterday => 'Hier';

  @override
  String notificationsDaysAgo(int n) {
    return 'il y a $n j';
  }

  @override
  String get profileTitle => 'Profil';

  @override
  String get profileGuestTitle => 'Vous naviguez en tant qu\'invité';

  @override
  String get profileGuestBody =>
      'Connectez-vous ou inscrivez-vous pour réserver des trajets, publier des covoiturages et gérer votre compte.';

  @override
  String get profileLoginSignup => 'Connexion / Inscription';

  @override
  String get profileAccount => 'Compte';

  @override
  String get profileBecomeDriver => 'Devenir conducteur';

  @override
  String get profileMyVehicle => 'Mon véhicule';

  @override
  String get profileSwitchToDriver => 'Passer en mode conducteur';

  @override
  String get profileSwitchToPassenger => 'Passer en mode passager';

  @override
  String get profilePayoutHistory => 'Historique des paiements';

  @override
  String get profileSupport => 'Assistance';

  @override
  String get profileHelpSupport => 'Aide & Assistance';

  @override
  String get profileTermsPrivacy => 'Conditions & Confidentialité';

  @override
  String get profileLogout => 'Se déconnecter';

  @override
  String get profileLogoutTitle => 'Se déconnecter ?';

  @override
  String get profileLogoutBody =>
      'Vous devrez vérifier votre numéro de téléphone à nouveau pour vous reconnecter.';

  @override
  String get profileVersion => 'HolaRide v1.0.0';

  @override
  String get profileLanguage => 'Langue';

  @override
  String get editProfileTitle => 'Modifier le profil';

  @override
  String get editProfileName => 'Nom';

  @override
  String get editProfileNameHint => 'Votre nom';

  @override
  String get editProfilePhone => 'Numéro de téléphone';

  @override
  String get editProfileSave => 'Enregistrer les modifications';

  @override
  String get editProfileErrorName => 'Entrez un nom.';

  @override
  String get editProfileSaveError =>
      'Impossible de sauvegarder vos modifications. Réessayez.';

  @override
  String get driverMyTripsUpcoming => 'À venir';

  @override
  String get driverMyTripsPast => 'Passés';

  @override
  String get driverMyTripsCreate => 'Créer un nouveau trajet';

  @override
  String get driverMyTripsEmpty => 'Aucun trajet pour l\'instant.';

  @override
  String driverRatePassengers(int count) {
    return 'Évaluer $count passagers';
  }

  @override
  String driverRateOne(String name) {
    return 'Évaluer $name';
  }

  @override
  String get tripMgmtCancelTitle => 'Annuler ce trajet ?';

  @override
  String get tripMgmtCancelBody =>
      'Chaque passager ayant déjà payé sera notifié et remboursé selon votre politique d\'annulation.';

  @override
  String get tripMgmtCancelled => 'Trajet annulé.';

  @override
  String get tripMgmtCompleteTitle => 'Marquer le trajet comme terminé ?';

  @override
  String get tripMgmtCompleteBody =>
      'Ceci clôture le trajet une fois que tout le monde est arrivé.';

  @override
  String get tripMgmtCompleted => 'Trajet marqué comme terminé !';

  @override
  String get tripMgmtNoShowTitle => 'Qui n\'est pas venu ?';

  @override
  String tripMgmtNoShowBody(String name) {
    return 'Marquer $name comme absent ?';
  }

  @override
  String get tripMgmtNoShowDetail =>
      'Cela affecte leur dossier et peut entraîner des frais selon votre politique.';

  @override
  String tripMgmtRequests(int count) {
    return 'Demandes ($count)';
  }

  @override
  String tripMgmtBookings(int count) {
    return 'Réservations ($count)';
  }

  @override
  String get tripMgmtActions => 'Actions du trajet';

  @override
  String get tripMgmtNoRequests => 'Aucune nouvelle demande.';

  @override
  String get tripMgmtNoPassengers => 'Aucun passager confirmé pour l\'instant.';

  @override
  String get tripMgmtActingOn => 'Agir sur ce trajet';

  @override
  String get tripMgmtMarkComplete => 'Marquer comme terminé';

  @override
  String get tripMgmtMarkNoShow => 'Marquer absent';

  @override
  String get tripMgmtCancelBtn => 'Annuler le trajet';

  @override
  String get tripMgmtLoadError =>
      'Impossible de charger les demandes pour ce trajet.';

  @override
  String get tripMgmtAcceptError => 'Impossible d\'accepter cette demande.';

  @override
  String get tripMgmtRejectError => 'Impossible de refuser cette demande.';

  @override
  String get tripMgmtGenericError => 'Une erreur s\'est produite. Réessayez.';

  @override
  String get createTripTitle => 'Créer un trajet';

  @override
  String get createTripFrom => 'De';

  @override
  String get createTripTo => 'Vers';

  @override
  String get createTripDate => 'Date';

  @override
  String get createTripDeparture => 'Heure de départ';

  @override
  String get createTripSeats => 'Sièges disponibles';

  @override
  String createTripSeatsHint(int max) {
    return 'Jusqu\'à $max — la capacité enregistrée de votre véhicule';
  }

  @override
  String get createTripPrice => 'Prix par siège';

  @override
  String get createTripPriceHint =>
      'Choisissez \"De\" et \"Vers\" pour voir le prix';

  @override
  String get createTripPriceNote =>
      'Défini par HolaRide selon votre itinéraire et catégorie de véhicule — les conducteurs ne fixent pas les prix.';

  @override
  String get createTripPublish => 'Publier le trajet';

  @override
  String get createTripSelectLocation => 'Sélectionner un lieu';

  @override
  String get createTripLocationHint =>
      'Choisissez votre point de départ et d\'arrivée.';

  @override
  String get createTripNoVehicle =>
      'Aucun véhicule approuvé trouvé — vérifiez Mon véhicule dans le Profil.';

  @override
  String get createTripNoPriceError =>
      'Impossible de charger un prix pour cet itinéraire.';

  @override
  String get createTripPublishError =>
      'Impossible de publier ce trajet. Réessayez.';

  @override
  String get createTripLeavingFrom => 'Au départ de';

  @override
  String get createTripGoingTo => 'À destination de';

  @override
  String get vehicleRegTitle => 'Ajouter votre véhicule';

  @override
  String get vehicleRegSubtitle =>
      'Parlez-nous de votre voiture — c\'est ce qui sera examiné avant que vous puissiez publier des trajets.';

  @override
  String get vehicleRegDetails => 'Détails du véhicule';

  @override
  String get vehicleRegBrand => 'Marque';

  @override
  String get vehicleRegModel => 'Modèle';

  @override
  String get vehicleRegYear => 'Année (facultatif)';

  @override
  String get vehicleRegColor => 'Couleur (facultatif)';

  @override
  String get vehicleRegPlate => 'Numéro d\'immatriculation';

  @override
  String get vehicleRegSeats => 'Nombre de sièges';

  @override
  String get vehicleRegSubmit => 'Soumettre pour examen';

  @override
  String get vehicleRegValidationError =>
      'Remplissez la marque, le modèle, la plaque et les sièges.';

  @override
  String get vehicleRegSubmitError =>
      'Impossible de soumettre votre véhicule. Réessayez.';

  @override
  String get vehicleRegBrandHint => 'ex. Toyota';

  @override
  String get vehicleRegModelHint => 'ex. Corolla';

  @override
  String get vehicleRegYearHint => 'ex. 2018';

  @override
  String get vehicleRegColorHint => 'ex. Argent';

  @override
  String get vehicleRegPlateHint => 'ex. CMR-123-AA';

  @override
  String get vehicleStatusNoVehicle =>
      'Vous n\'avez pas encore ajouté de véhicule.';

  @override
  String get vehicleStatusAdd => 'Ajouter votre véhicule';

  @override
  String get vehicleStatusPhotos => 'Photos';

  @override
  String get vehicleStatusAddPhotos => 'Ajouter des photos';

  @override
  String get vehicleStatusUploading => 'Téléchargement...';

  @override
  String get vehicleStatusNoPhotos =>
      'Aucune photo — ajoutez-en pour que les passagers reconnaissent votre voiture.';

  @override
  String get vehicleStatusPhotoError =>
      'Certaines photos n\'ont pas été téléchargées. Réessayez.';

  @override
  String get vehicleStatusFirstTrip => 'Créez votre premier trajet';

  @override
  String get vehicleStatusStatusLabel => 'Statut';

  @override
  String get vehicleStatusPending =>
      'Nous vérifions vos documents et votre véhicule. Vous serez notifié dès l\'approbation.';

  @override
  String get vehicleStatusApproved =>
      'Votre véhicule est approuvé — vous pouvez publier des trajets maintenant.';

  @override
  String get vehicleStatusRejected =>
      'Votre soumission a été rejetée. Contactez le support ou soumettez un nouveau véhicule.';

  @override
  String get vehicleStatusUnavailable => 'Statut indisponible pour l\'instant.';

  @override
  String get vehicleStatusLoadError =>
      'Impossible de charger le statut de votre véhicule.';

  @override
  String get payoutTitle => 'Historique des versements';

  @override
  String get payoutTotal => 'Total versé';

  @override
  String get payoutNote =>
      'Envoyé automatiquement sur votre Mobile Money après chaque trajet complété.';

  @override
  String get payoutHistory => 'Historique';

  @override
  String get payoutEmpty => 'Aucun versement pour l\'instant.';

  @override
  String get payoutPaid => 'Payé';

  @override
  String get payoutPending => 'En attente';

  @override
  String get payoutLoadError => 'Impossible de charger vos versements.';

  @override
  String get tripDetailBook => 'Réserver un siège';

  @override
  String get tripDetailNoSeats => 'Plus de sièges disponibles';

  @override
  String get tripDetailNoReviews => 'Aucun avis sur ce conducteur';

  @override
  String get tripDetailReview => 'avis';

  @override
  String get tripDetailReviews => 'avis sur ce conducteur';

  @override
  String get tripDetailVehicleCategory => 'Catégorie de véhicule';

  @override
  String get tripDetailSeat => 'siège';

  @override
  String get tripDetailSeatsAvailable => 'sièges disponibles';

  @override
  String get bookingRequestTitle => 'Demander un siège';

  @override
  String get bookingRequestStep => 'Étape 1 sur 2';

  @override
  String get bookingRequestSeats => 'Sièges';

  @override
  String get bookingRequestPayment => 'Option de paiement';

  @override
  String get bookingRequestPayFull => 'Paiement intégral';

  @override
  String get bookingRequestPayDeposit => 'Acompte de 80 %';

  @override
  String bookingRequestDepositHint(String deposit, String remaining) {
    return 'Payez $deposit maintenant, $remaining avant le trajet';
  }

  @override
  String get bookingRequestDueNow => 'Dû maintenant';

  @override
  String get bookingRequestTotal => 'Total';

  @override
  String get bookingRequestRemaining => 'Reste avant le trajet';

  @override
  String get bookingRequestContinue => 'Continuer';

  @override
  String get bookingRequestDeparture => 'Point de départ';

  @override
  String get bookingRequestDropoff => 'Point de dépose';

  @override
  String bookingRequestSeatsAvailable(int count) {
    return '$count sièges disponibles';
  }

  @override
  String get waitingTitle => 'En attente du conducteur';

  @override
  String get waitingBody =>
      'Votre demande a été envoyée au conducteur.\nVous serez notifié dès qu\'il répond.';

  @override
  String get waitingDeclinedTitle => 'Demande refusée';

  @override
  String get waitingDeclinedBody =>
      'Le conducteur n\'a pas pu accepter votre demande cette fois. Vous pouvez chercher un autre trajet.';

  @override
  String get waitingBackHome => 'Retour à l\'accueil';

  @override
  String get waitingNote =>
      'Cette demande peut prendre du temps. Nous vous notifierons immédiatement.';

  @override
  String get waitingWithdraw => 'Retirer la demande';

  @override
  String get waitingSeatsRequested => 'Sièges demandés';

  @override
  String get waitingPricePerSeat => 'Prix par siège';

  @override
  String get rateTripTitle => 'Évaluer ce trajet';

  @override
  String get rateTripDriverQuestion => 'Comment s\'est passé votre trajet ?';

  @override
  String get rateTripPassengerQuestion =>
      'Comment était chaque passager de ce trajet ?';

  @override
  String get rateTripNote =>
      'Votre évaluation aide à maintenir la confiance sur HolaRide.';

  @override
  String get rateTripThanksDriver =>
      'Merci — vous avez évalué votre conducteur.';

  @override
  String rateTripThanksPassenger(String name) {
    return 'Merci — vous avez évalué $name.';
  }

  @override
  String get rateTripYourDriver => 'Votre conducteur';

  @override
  String get rateTripStarError => 'Appuyez d\'abord sur une étoile.';

  @override
  String get rateTripSubmitError =>
      'Impossible de soumettre cette évaluation. Réessayez.';

  @override
  String get rateTripDriverComment =>
      'Des commentaires sur le trajet ? (facultatif)';

  @override
  String get rateTripPassengerComment =>
      'Des commentaires sur ce passager ? (facultatif)';

  @override
  String get rateTripSubmit => 'Soumettre l\'évaluation';

  @override
  String get paymentTitle => 'Paiement';

  @override
  String get paymentAutoDetected =>
      'Détecté automatiquement depuis votre numéro';

  @override
  String get paymentAmountDue => 'Montant dû';

  @override
  String get paymentFees => 'Frais : 2 % inclus';

  @override
  String get paymentPhone => 'Téléphone';

  @override
  String paymentPrompt(String operator, String phone) {
    return 'Vous recevrez une invite $operator sur $phone. Confirmez pour finaliser le paiement.';
  }

  @override
  String paymentPay(String amount) {
    return 'Payer $amount';
  }

  @override
  String get paymentSimulate => 'Simuler (dev uniquement)';

  @override
  String get paymentConnecting => 'Connexion au Mobile Money...';

  @override
  String get paymentPleaseWait => 'Veuillez patienter';

  @override
  String get paymentCheckPhone => 'Vérifiez votre téléphone';

  @override
  String paymentSentTo(String operator, String phone) {
    return 'Une demande de paiement $operator a été envoyée à\n$phone';
  }

  @override
  String get paymentToConfirm => 'pour confirmer';

  @override
  String paymentOpenApp(String operator) {
    return 'Ouvrez $operator sur votre téléphone';
  }

  @override
  String paymentOrDial(String ussd) {
    return 'ou composez le $ussd pour approuver la demande';
  }

  @override
  String get paymentCancelBtn => 'Annuler le paiement';

  @override
  String get paymentConfirmed => 'Paiement confirmé !';

  @override
  String get paymentSeatsSecured =>
      'Votre siège est réservé.\nLe conducteur a été notifié.';

  @override
  String get paymentBackHome => 'Retour à l\'accueil';

  @override
  String get paymentFailed => 'Paiement échoué';

  @override
  String get paymentInsufficientBalance => 'Solde insuffisant';

  @override
  String paymentInsufficientMsg(String operator, String amount) {
    return 'Votre solde $operator est trop faible pour $amount.';
  }

  @override
  String paymentTopUp(String operator) {
    return 'Recharger $operator';
  }

  @override
  String paymentDial(String ussd) {
    return 'Composez le $ussd sur votre téléphone, puis réessayez.';
  }

  @override
  String get paymentTryAgain => 'Réessayer';

  @override
  String get paymentGoHome => 'Retour à l\'accueil';

  @override
  String get paymentTimeout => 'Paiement expiré. Veuillez réessayer.';

  @override
  String get rebookTitle => 'Trajet annulé';

  @override
  String get rebookBody =>
      'Le conducteur a annulé ce trajet.\nVoulez-vous trouver un autre trajet ?';

  @override
  String get rebookOriginal => 'Trajet original';

  @override
  String get rebookFind => 'Trouver un autre trajet';

  @override
  String get rebookGoBookings => 'Aller à Mes trajets';

  @override
  String get cancelTripTitle => 'Annuler ce trajet ?';

  @override
  String get cancelTripBody =>
      'Êtes-vous sûr de vouloir annuler ce trajet ? Selon la proximité du départ, des frais d\'annulation peuvent s\'appliquer. Cette action est irréversible.';

  @override
  String get withdrawTitle => 'Annuler cette demande ?';

  @override
  String get withdrawBody =>
      'Êtes-vous sûr de vouloir retirer cette demande ? Cette action est irréversible.';

  @override
  String get cancelTripBtn => 'Annuler le trajet';

  @override
  String get withdrawBtn => 'Retirer la demande';

  @override
  String get keepTripBtn => 'Garder le trajet';

  @override
  String get keepRequestBtn => 'Garder la demande';

  @override
  String get cancelError =>
      'Impossible de terminer cela pour l\'instant. Réessayez.';

  @override
  String get helpTitle => 'Aide & Assistance';

  @override
  String get helpQ1 => 'Comment fonctionne le paiement ?';

  @override
  String get helpA1 =>
      'Vous payez via Mobile Money une fois qu\'un conducteur accepte votre demande — soit le tarif complet, soit un acompte de 20 % avec le reste dû avant le trajet.';

  @override
  String get helpQ2 => 'Que faire si mon conducteur annule ?';

  @override
  String get helpA2 =>
      'Vous serez notifié immédiatement et pourrez chercher un autre trajet en un tap depuis votre réservation.';

  @override
  String get helpQ3 => 'Comment devenir conducteur ?';

  @override
  String get helpA3 =>
      'Allez dans Profil → Devenir conducteur, ajoutez les détails de votre véhicule et des photos, et HolaRide les examinera et les approuvera.';

  @override
  String get helpContactNote =>
      'Le contact d\'assistance direct n\'est pas encore configuré — ajoutez un e-mail ou numéro de téléphone réel avant le lancement.';

  @override
  String get helpEmail => 'Contacter par e-mail';

  @override
  String get helpCall => 'Appeler l\'assistance';

  @override
  String get termsTitle => 'Conditions & Confidentialité';

  @override
  String get termsBody =>
      'Cet écran est un espace réservé. Les vraies Conditions d\'utilisation et la Politique de confidentialité — idéalement révisées par un juriste familier avec le droit camerounais — doivent remplacer ce texte avant le lancement.';

  @override
  String get termsNote =>
      'Au minimum, votre politique réelle doit couvrir : les données collectées par HolaRide, la gestion des transactions Mobile Money, la politique d\'annulation, la responsabilité des conducteurs, et la suppression des données.';

  @override
  String get widgetSeatsLeft => 'sièges restants';

  @override
  String get welcomeTaglinePrefix => 'Voyagez entre les villes,\n';

  @override
  String get welcomeTaglineAccent => 'ensemble.';

  @override
  String get welcomeSubtitle =>
      'Trajets confortables, abordables\net sûrs à travers le Cameroun.';

  @override
  String get liveTripConsentTitle => 'Partager votre position';

  @override
  String get liveTripConsentBody =>
      'Pendant ce trajet, le conducteur pourra voir votre position en direct. Vous pouvez désactiver le partage à tout moment depuis l\'écran de suivi.';

  @override
  String get liveTripConsentDecline => 'Suivre sans partager';

  @override
  String get liveTripConsentAccept => 'Partager';

  @override
  String get liveTripEndedTitle => 'Trajet terminé';

  @override
  String get liveTripEndedBody =>
      'Le partage de position a été arrêté automatiquement.';

  @override
  String get liveTripBack => 'Retour';

  @override
  String get liveTripSharingSubtitle => 'Partage de votre position en direct';

  @override
  String get liveTripFollowingSubtitle => 'Suivi de votre conducteur';

  @override
  String get liveTripMeMarker => 'Moi';

  @override
  String get liveTripLive => 'En direct';

  @override
  String liveTripUpdatedAgo(int secs) {
    return 'Mis à jour il y a ${secs}s';
  }

  @override
  String liveTripLastSeenAgo(int mins) {
    return 'Vu il y a ${mins}min';
  }

  @override
  String get liveTripWaitingSignal => 'En attente du signal...';

  @override
  String get liveTripDriverSeesPosition => 'Le conducteur voit votre position';

  @override
  String get liveTripSharingOff => 'Partage désactivé';

  @override
  String get liveTripSharingYourPosition => 'Vous partagez votre position';

  @override
  String get liveTripNoPassengerYet =>
      'Aucune position de passager reçue pour l\'instant.';

  @override
  String liveTripPassengerVisible(int count) {
    return '$count passager visible sur la carte.';
  }

  @override
  String liveTripPassengersVisible(int count) {
    return '$count passagers visibles sur la carte.';
  }

  @override
  String liveTripRouteLabel(String km, String mins) {
    return '$km km · $mins min';
  }

  @override
  String get liveTripPermServiceDisabled =>
      'Les services de localisation sont désactivés sur cet appareil.';

  @override
  String get liveTripPermDenied =>
      'L\'autorisation de localisation a été refusée.';

  @override
  String get liveTripPermDeniedForever =>
      'L\'autorisation de localisation est définitivement refusée — activez-la dans les réglages de votre téléphone.';

  @override
  String get onboardingSkip => 'Passer';

  @override
  String get onboardingNext => 'Suivant';

  @override
  String get onboardingLetsGo => 'C\'est parti !';

  @override
  String get onboardingBrandName => 'HolaRide';

  @override
  String get onboardingTagline => 'Partagez le trajet. Allez plus loin.';

  @override
  String get onboardingPage1TitleLine1 => 'Voyage intercité,\n';

  @override
  String get onboardingPage1TitleAccent => 'plus malin ';

  @override
  String get onboardingPage1TitleSuffix => 'ensemble';

  @override
  String get onboardingPage1Body =>
      'Réservez un siège ou proposez un trajet vers\nvos villes préférées au Cameroun.\nSûr, abordable et fiable.';

  @override
  String get onboardingPage2TitlePrefix => 'Trouvez le bon trajet\npour ';

  @override
  String get onboardingPage2TitleAccent => 'votre voyage';

  @override
  String get onboardingPage2Body =>
      'Recherchez des trajets entre villes, comparez les options,\nconsultez les profils des conducteurs et réservez votre siège\nen quelques clics.';

  @override
  String get onboardingPage3TitlePrefix => 'Voyagez en toute ';

  @override
  String get onboardingPage3TitleAccent => 'tranquillité\n';

  @override
  String get onboardingPage3TitleSuffix => 'd\'esprit';

  @override
  String get onboardingPage3Body =>
      'Suivi du trajet en direct, paiements sécurisés et\nassistance 24h/24 — nous vous accompagnons\nà chaque étape.';

  @override
  String get onboardingFeatSafeTitle => 'Sûr et fiable';

  @override
  String get onboardingFeatSafeSub =>
      'Conducteurs vérifiés\n& paiements sécurisés';

  @override
  String get onboardingFeatShareTitle => 'Trouvez ou partagez';

  @override
  String get onboardingFeatShareSub =>
      'Choisissez votre trajet\nou proposez des sièges';

  @override
  String get onboardingFeatAffordableTitle => 'Abordable';

  @override
  String get onboardingFeatAffordableSub =>
      'Meilleurs prix\npour chaque trajet';

  @override
  String get onboardingFeatRoutesTitle => 'De nombreux itinéraires';

  @override
  String get onboardingFeatRoutesSub => 'À travers le Cameroun';

  @override
  String get onboardingFeatPricesTitle => 'Excellents prix';

  @override
  String get onboardingFeatPricesSub => 'Sans frais cachés';

  @override
  String get onboardingFeatBookingTitle => 'Réservation rapide';

  @override
  String get onboardingFeatBookingSub => 'En quelques clics';

  @override
  String get onboardingFeatPaymentsTitle => 'Paiements sécurisés';

  @override
  String get onboardingFeatPaymentsSub => 'Votre argent est protégé';

  @override
  String get onboardingFeatTrackingTitle => 'Suivi du trajet en direct';

  @override
  String get onboardingFeatTrackingSub => 'Suivez votre trajet en temps réel';

  @override
  String get onboardingFeatSupportTitle => 'Assistance 24h/24';

  @override
  String get onboardingFeatSupportSub => 'Nous sommes là pour vous aider';

  @override
  String get onboardingFooterTagline =>
      'Bâtir un Cameroun connecté, un trajet à la fois.';

  @override
  String get searchHeroTitlePrefix => 'Trouver ';

  @override
  String get searchHeroTitleAccent => 'votre trajet';

  @override
  String get searchHeroSubtitle =>
      'Trouvez des trajets confortables\nentre les villes.';

  @override
  String get searchQuickRoutesTitle => 'Itinéraires rapides';

  @override
  String get searchQuickRoutesHint =>
      'Appuyez sur un itinéraire pour remplir votre recherche instantanément.';

  @override
  String get searchTrustPaymentsTitle => 'Paiements sécurisés';

  @override
  String get searchTrustPaymentsSubtitle => 'Vos données sont protégées';

  @override
  String get searchTrustCommunityTitle => 'Communauté de confiance';

  @override
  String get searchTrustCommunitySubtitle => 'Conducteurs vérifiés';

  @override
  String get searchTrustSupportTitle => 'Assistance 24/7';

  @override
  String get searchTrustSupportSubtitle => 'Nous sommes là pour vous';

  @override
  String get searchResultsPassengerSingular => 'passager';

  @override
  String get searchResultsPassengerPlural => 'passagers';

  @override
  String get homeJoinPopupBody =>
      'Connectez-vous pour réserver des trajets et rencontrer des conducteurs vérifiés.';

  @override
  String get homeHeroTravelSmarterTitle =>
      'Voyagez plus intelligemment,\nÉconomisez plus';

  @override
  String get homeHeroTravelSmarterBody =>
      'Partagez les frais avec d\'autres voyageurs qui vont dans votre direction.';

  @override
  String get homeHeroSafeTitle => 'Sûr &\nFiable';

  @override
  String get homeHeroSafeBody =>
      'Tous les conducteurs sont vérifiés. Votre sécurité est notre priorité.';

  @override
  String get homeHeroCameroonTitle => 'À travers\nle Cameroun';

  @override
  String get homeHeroCameroonBody =>
      'Yaoundé, Douala, Bafoussam et d\'autres destinations.';

  @override
  String get homeFindRideSubtitle =>
      'Recherchez des trajets vers votre destination';

  @override
  String get homeOfferRide => 'Proposer un trajet';

  @override
  String get homeOfferRideSubtitle =>
      'Publiez votre trajet et remplissez vos sièges vides';

  @override
  String get homeRideTogetherTitle => 'Voyagez ensemble, économisez plus';

  @override
  String get homeRideTogetherBody =>
      'Partagez votre trajet, divisez\nles frais et réduisez les coûts.';

  @override
  String get homeLearnMore => 'En savoir plus';

  @override
  String get homeHappyRiders => 'Utilisateurs satisfaits\nde HolaRide';

  @override
  String homeTripsAvailableSingular(int count) {
    return '$count trajet disponible';
  }

  @override
  String homeTripsAvailablePlural(int count) {
    return '$count trajets disponibles';
  }

  @override
  String get splashTagline => 'Voyagez ensemble.\nÉconomisez plus.';

  @override
  String get splashTagSafe => 'Sûr';

  @override
  String get splashTagAffordable => 'Abordable';

  @override
  String get splashTagReliable => 'Fiable';

  @override
  String get splashFooter => 'Reliant les villes à travers le Cameroun 🇨🇲';

  @override
  String get paymentChangeNumberTitle => 'Payer avec un autre numéro';

  @override
  String get paymentChangeNumberBody =>
      'L\'invite Mobile Money sera envoyée à ce numéro.';

  @override
  String get paymentChangeNumberHint => '675 123 456';

  @override
  String get paymentChangeNumberError =>
      'Entrez un numéro valide à 9 chiffres commençant par 6.';

  @override
  String get paymentUseThisNumber => 'Utiliser ce numéro';

  @override
  String get paymentUserCancelled =>
      'Vous avez annulé le paiement sur votre téléphone.';

  @override
  String get paymentFailedGeneric =>
      'Le paiement a échoué. Veuillez réessayer.';

  @override
  String get paymentProviderUnreachable =>
      'Impossible de joindre le fournisseur de paiement. Réessayez.';

  @override
  String get paymentCloseBtn => 'Fermer';

  @override
  String get payRemainingTitle => 'Payer le solde restant';

  @override
  String get payRemainingDepositPaid => 'Acompte de 20 % payé';

  @override
  String get payRemainingBalanceLabel => 'Solde restant';

  @override
  String get payRemainingMomoNumber => 'Numéro Mobile Money';

  @override
  String get payRemainingAutoDetectNote =>
      'MTN ou Orange Money est détecté automatiquement — vous recevrez une invite USSD sur ce numéro.';

  @override
  String get payRemainingCheckPhoneNote =>
      'Vérifiez votre téléphone — confirmez l\'invite Mobile Money pour terminer.';

  @override
  String get payRemainingWaitingLabel => 'En attente de confirmation...';

  @override
  String get payRemainingDevNote =>
      'Visible uniquement en mode debug. Contourne le vrai Mobile Money — fonctionne uniquement si PAYMENT_DEV_MODE est activé côté serveur.';

  @override
  String get payRemainingSimulateError => 'Impossible de simuler le paiement.';

  @override
  String get payRemainingFailedMsg =>
      'Le paiement a échoué. Vérifiez votre solde Mobile Money et réessayez.';

  @override
  String get payRemainingExpiredMsg =>
      'La demande de paiement a expiré avant confirmation. Réessayez.';

  @override
  String get payRemainingStillWaitingMsg =>
      'En attente de confirmation — vérifiez votre téléphone, puis réessayez si rien ne s\'est passé.';

  @override
  String get payRemainingGenericError =>
      'Le paiement n\'a pas pu être finalisé. Réessayez.';

  @override
  String get tripDetailAppBarTitle => 'Détails du trajet';

  @override
  String get tripDetailLoadError => 'Impossible de charger ce trajet.';

  @override
  String get tripDetailTotalPriceLabel => 'Prix total (1 siège)';

  @override
  String get tripDetailNoHiddenFees => 'Aucun frais caché';

  @override
  String get tripDetailSecureBooking => 'Réservation sécurisée';

  @override
  String get tripDetailVerifiedTrip => 'Trajet vérifié';

  @override
  String get tripDetailSafeReliableTrusted => 'Sûr • Fiable • De confiance';

  @override
  String get tripDetailDepartureTag => 'Départ';

  @override
  String get tripDetailArrivalTag => 'Arrivée';

  @override
  String get tripDetailPromoTitle => 'Voyage abordable, sûr et fiable';

  @override
  String get tripDetailPromoBody =>
      'Réservez en toute confiance et profitez de votre voyage.';

  @override
  String tripDetailSeatsLeftSingular(int count) {
    return '$count siège restant';
  }

  @override
  String tripDetailSeatsLeftPlural(int count) {
    return '$count sièges restants';
  }

  @override
  String get tripDetailLuggageLabel => 'Bagages';

  @override
  String get tripDetailLuggageValue => '1 bagage par passager';

  @override
  String get tripDetailVerifiedDriverBadge => 'Conducteur vérifié';

  @override
  String get tripDetailIdVerified => 'Identité vérifiée';

  @override
  String get tripDetailPhoneVerified => 'Téléphone vérifié';

  @override
  String get tripDetailBackgroundChecked => 'Vérification des antécédents';

  @override
  String tripDetailTripsCompleted(int count) {
    return '$count trajets effectués';
  }

  @override
  String tripDetailReviewCountBare(int count) {
    return '$count avis';
  }

  @override
  String tripDetailReviewCountBarePlural(int count) {
    return '$count avis';
  }

  @override
  String get tripDetailDriverProfileSoon =>
      'Profil du conducteur bientôt disponible';

  @override
  String get tripDetailKnowMoreDriver => 'En savoir plus sur le conducteur';

  @override
  String get safetyPriorityTitle => 'Votre sécurité est notre priorité';

  @override
  String get safetyPriorityBody =>
      'SOS, partage de position en direct et chat intégré disponibles.';

  @override
  String get learnMore => 'En savoir plus';

  @override
  String get bookingRequestSafeSecureTrusted => 'Sûr · Sécurisé · De confiance';

  @override
  String get bookingRequestSeatsQuestion =>
      'De combien de sièges avez-vous besoin ?';

  @override
  String get bookingRequestSentHeading =>
      'Votre demande sera envoyée au conducteur';

  @override
  String get bookingRequestNotPayingYet => 'Vous ne payez pas encore';

  @override
  String get bookingRequestSentBody =>
      'Votre demande sera envoyée au conducteur. Vous ne paierez qu\'après acceptation de votre demande.';

  @override
  String bookingRequestPayFullSubtitle(String amount) {
    return 'Payez $amount maintenant.';
  }

  @override
  String get bookingRequestPayBalanceTag => 'Payer le solde avant le trajet';

  @override
  String get bookingRequestTotalToPay => 'Total à payer';

  @override
  String get bookingRequestPaidAfterAccept =>
      '(payé après acceptation du conducteur)';

  @override
  String get cancellationWindowNote =>
      'Vous pouvez annuler gratuitement jusqu\'à 2 heures avant le départ.';

  @override
  String get bookingRequestSendButton => 'Envoyer la demande au conducteur';

  @override
  String get bookingRequestSendSubtext =>
      'Le conducteur doit accepter avant confirmation de la réservation';

  @override
  String get bookingRequestSendError =>
      'Impossible d\'envoyer votre demande. Réessayez.';

  @override
  String get waitingWhatsNext => 'Que se passe-t-il ensuite ?';

  @override
  String get waitingStepRequestSent => 'Demande envoyée';

  @override
  String get waitingStepDriverNotified => 'Conducteur notifié';

  @override
  String get waitingStepDriverResponds => 'Le conducteur répond';

  @override
  String get waitingNotifyHeading => 'Nous vous notifierons immédiatement';

  @override
  String get waitingNotifyBody =>
      'Vous pouvez continuer à utiliser l\'application.\nNous vous préviendrons dès que le conducteur accepte.';

  @override
  String get waitingGoHomeButton => 'Retour à l\'accueil';

  @override
  String get orDivider => 'ou';

  @override
  String get waitingResponseTimeBanner =>
      'La plupart des conducteurs répondent en 5 à 10 minutes.';

  @override
  String get chatHideChatBody =>
      'Ceci le supprime uniquement de votre propre liste — l\'autre partie conserve sa conversation normalement. Si un nouveau message arrive plus tard, il réapparaîtra dans votre liste.';

  @override
  String get chatHideChatError =>
      'Impossible de supprimer cette conversation. Réessayez.';

  @override
  String get driverFlowLoginReason =>
      'Connectez-vous pour publier un trajet en tant que conducteur.';

  @override
  String get payoutRowLabel => 'Versement';

  @override
  String get tripMgmtStartTitle => 'Démarrer ce trajet ?';

  @override
  String get tripMgmtStartBody =>
      'Le trajet sera marqué comme en cours. Vos passagers ayant payé pourront suivre votre position en direct jusqu\'à ce que vous le marquiez comme terminé.';

  @override
  String get tripMgmtNotYet => 'Pas encore';

  @override
  String get tripMgmtStartBtn => 'Démarrer le trajet';

  @override
  String get tripMgmtStarting => 'Démarrage...';

  @override
  String get tripMgmtStartedMsg =>
      'Trajet démarré — les passagers peuvent maintenant vous suivre.';

  @override
  String get tripMgmtStartError =>
      'Impossible de démarrer le trajet. Réessayez.';

  @override
  String get tripMgmtInProgressBanner =>
      'Trajet en cours — appuyez pour ouvrir la carte en direct.';

  @override
  String get tripMgmtAcceptTooltip => 'Accepter';

  @override
  String get tripMgmtRejectTooltip => 'Refuser';

  @override
  String get tripMgmtNoShowFallbackName => 'ce passager';

  @override
  String get tripMgmtDoneFallback => 'Terminé.';
}
