import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// Título de la aplicación
  ///
  /// In es, this message translates to:
  /// **'LŌME'**
  String get appTitle;

  /// No description provided for @save.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get cancel;

  /// No description provided for @accept.
  ///
  /// In es, this message translates to:
  /// **'Aceptar'**
  String get accept;

  /// No description provided for @delete.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In es, this message translates to:
  /// **'Editar'**
  String get edit;

  /// No description provided for @close.
  ///
  /// In es, this message translates to:
  /// **'Cerrar'**
  String get close;

  /// No description provided for @confirm.
  ///
  /// In es, this message translates to:
  /// **'Confirmar'**
  String get confirm;

  /// No description provided for @search.
  ///
  /// In es, this message translates to:
  /// **'Buscar'**
  String get search;

  /// No description provided for @loading.
  ///
  /// In es, this message translates to:
  /// **'Cargando...'**
  String get loading;

  /// No description provided for @retry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get retry;

  /// No description provided for @back.
  ///
  /// In es, this message translates to:
  /// **'Volver'**
  String get back;

  /// No description provided for @next.
  ///
  /// In es, this message translates to:
  /// **'Siguiente'**
  String get next;

  /// No description provided for @done.
  ///
  /// In es, this message translates to:
  /// **'Hecho'**
  String get done;

  /// No description provided for @seeAll.
  ///
  /// In es, this message translates to:
  /// **'Ver todo'**
  String get seeAll;

  /// No description provided for @noResults.
  ///
  /// In es, this message translates to:
  /// **'Sin resultados'**
  String get noResults;

  /// No description provided for @errorGeneric.
  ///
  /// In es, this message translates to:
  /// **'Ha ocurrido un error. Inténtalo de nuevo.'**
  String get errorGeneric;

  /// No description provided for @connectionError.
  ///
  /// In es, this message translates to:
  /// **'Error de conexión. Verifica tu internet.'**
  String get connectionError;

  /// No description provided for @sessionExpired.
  ///
  /// In es, this message translates to:
  /// **'Sesión expirada. Inicia sesión nuevamente.'**
  String get sessionExpired;

  /// No description provided for @create.
  ///
  /// In es, this message translates to:
  /// **'Crear'**
  String get create;

  /// No description provided for @all.
  ///
  /// In es, this message translates to:
  /// **'Todos'**
  String get all;

  /// No description provided for @no.
  ///
  /// In es, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @yes.
  ///
  /// In es, this message translates to:
  /// **'Sí'**
  String get yes;

  /// No description provided for @total.
  ///
  /// In es, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @subtotal.
  ///
  /// In es, this message translates to:
  /// **'Subtotal'**
  String get subtotal;

  /// No description provided for @taxes.
  ///
  /// In es, this message translates to:
  /// **'Impuestos'**
  String get taxes;

  /// No description provided for @discount.
  ///
  /// In es, this message translates to:
  /// **'Descuento'**
  String get discount;

  /// No description provided for @active.
  ///
  /// In es, this message translates to:
  /// **'Activo'**
  String get active;

  /// No description provided for @inactive.
  ///
  /// In es, this message translates to:
  /// **'Inactivo'**
  String get inactive;

  /// No description provided for @details.
  ///
  /// In es, this message translates to:
  /// **'Detalles'**
  String get details;

  /// No description provided for @today.
  ///
  /// In es, this message translates to:
  /// **'Hoy'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In es, this message translates to:
  /// **'Ayer'**
  String get yesterday;

  /// No description provided for @deselect.
  ///
  /// In es, this message translates to:
  /// **'Deseleccionar'**
  String get deselect;

  /// No description provided for @saveChanges.
  ///
  /// In es, this message translates to:
  /// **'Guardar cambios'**
  String get saveChanges;

  /// No description provided for @actions.
  ///
  /// In es, this message translates to:
  /// **'Acciones'**
  String get actions;

  /// No description provided for @login.
  ///
  /// In es, this message translates to:
  /// **'Iniciar sesión'**
  String get login;

  /// No description provided for @register.
  ///
  /// In es, this message translates to:
  /// **'Registrarse'**
  String get register;

  /// No description provided for @logout.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get logout;

  /// No description provided for @email.
  ///
  /// In es, this message translates to:
  /// **'Correo electrónico'**
  String get email;

  /// No description provided for @password.
  ///
  /// In es, this message translates to:
  /// **'Contraseña'**
  String get password;

  /// No description provided for @forgotPassword.
  ///
  /// In es, this message translates to:
  /// **'¿Olvidaste tu contraseña?'**
  String get forgotPassword;

  /// No description provided for @resetPassword.
  ///
  /// In es, this message translates to:
  /// **'Restablecer contraseña'**
  String get resetPassword;

  /// No description provided for @createAccount.
  ///
  /// In es, this message translates to:
  /// **'Crear cuenta'**
  String get createAccount;

  /// No description provided for @fullName.
  ///
  /// In es, this message translates to:
  /// **'Nombre completo'**
  String get fullName;

  /// No description provided for @phone.
  ///
  /// In es, this message translates to:
  /// **'Teléfono'**
  String get phone;

  /// No description provided for @splashTagline.
  ///
  /// In es, this message translates to:
  /// **'Tu restaurante, simplificado'**
  String get splashTagline;

  /// No description provided for @platformTagline.
  ///
  /// In es, this message translates to:
  /// **'PLATAFORMA PARA RESTAURANTES'**
  String get platformTagline;

  /// No description provided for @welcomeTitle.
  ///
  /// In es, this message translates to:
  /// **'Bienvenido a LŌME'**
  String get welcomeTitle;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In es, this message translates to:
  /// **'La plataforma todo-en-uno para gestionar tu restaurante'**
  String get welcomeSubtitle;

  /// No description provided for @welcomeLoginButton.
  ///
  /// In es, this message translates to:
  /// **'Iniciar sesión'**
  String get welcomeLoginButton;

  /// No description provided for @welcomeRegisterButton.
  ///
  /// In es, this message translates to:
  /// **'Crear cuenta'**
  String get welcomeRegisterButton;

  /// No description provided for @welcomeExploreButton.
  ///
  /// In es, this message translates to:
  /// **'Explorar marketplace'**
  String get welcomeExploreButton;

  /// No description provided for @loginTitle.
  ///
  /// In es, this message translates to:
  /// **'Bienvenido de nuevo'**
  String get loginTitle;

  /// No description provided for @loginEmailHint.
  ///
  /// In es, this message translates to:
  /// **'tu@email.com'**
  String get loginEmailHint;

  /// No description provided for @loginPasswordHint.
  ///
  /// In es, this message translates to:
  /// **'Tu contraseña'**
  String get loginPasswordHint;

  /// No description provided for @loginButton.
  ///
  /// In es, this message translates to:
  /// **'Iniciar sesión'**
  String get loginButton;

  /// No description provided for @loginNoAccount.
  ///
  /// In es, this message translates to:
  /// **'¿No tienes cuenta?'**
  String get loginNoAccount;

  /// No description provided for @loginRegisterLink.
  ///
  /// In es, this message translates to:
  /// **'Regístrate'**
  String get loginRegisterLink;

  /// No description provided for @loginWithGoogle.
  ///
  /// In es, this message translates to:
  /// **'Continuar con Google'**
  String get loginWithGoogle;

  /// No description provided for @loginWithApple.
  ///
  /// In es, this message translates to:
  /// **'Continuar con Apple'**
  String get loginWithApple;

  /// No description provided for @loginErrorInvalidEmail.
  ///
  /// In es, this message translates to:
  /// **'El correo electrónico no es válido'**
  String get loginErrorInvalidEmail;

  /// No description provided for @loginErrorWrongPassword.
  ///
  /// In es, this message translates to:
  /// **'Contraseña incorrecta'**
  String get loginErrorWrongPassword;

  /// No description provided for @loginErrorGeneric.
  ///
  /// In es, this message translates to:
  /// **'Error al iniciar sesión. Inténtalo de nuevo.'**
  String get loginErrorGeneric;

  /// No description provided for @loginSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Gestiona tu restaurante desde cualquier lugar'**
  String get loginSubtitle;

  /// No description provided for @registerTitle.
  ///
  /// In es, this message translates to:
  /// **'Crea tu cuenta'**
  String get registerTitle;

  /// No description provided for @registerNameHint.
  ///
  /// In es, this message translates to:
  /// **'Tu nombre completo'**
  String get registerNameHint;

  /// No description provided for @registerEmailHint.
  ///
  /// In es, this message translates to:
  /// **'tu@email.com'**
  String get registerEmailHint;

  /// No description provided for @registerPasswordHint.
  ///
  /// In es, this message translates to:
  /// **'Crea una contraseña'**
  String get registerPasswordHint;

  /// No description provided for @registerConfirmPasswordHint.
  ///
  /// In es, this message translates to:
  /// **'Confirma tu contraseña'**
  String get registerConfirmPasswordHint;

  /// No description provided for @registerPhoneHint.
  ///
  /// In es, this message translates to:
  /// **'+34 600 000 000'**
  String get registerPhoneHint;

  /// No description provided for @registerAcceptTerms.
  ///
  /// In es, this message translates to:
  /// **'Acepto los'**
  String get registerAcceptTerms;

  /// No description provided for @registerTermsLink.
  ///
  /// In es, this message translates to:
  /// **'Términos y condiciones'**
  String get registerTermsLink;

  /// No description provided for @registerPrivacyLink.
  ///
  /// In es, this message translates to:
  /// **'Política de privacidad'**
  String get registerPrivacyLink;

  /// No description provided for @registerButton.
  ///
  /// In es, this message translates to:
  /// **'Crear cuenta'**
  String get registerButton;

  /// No description provided for @registerHaveAccount.
  ///
  /// In es, this message translates to:
  /// **'¿Ya tienes cuenta?'**
  String get registerHaveAccount;

  /// No description provided for @registerLoginLink.
  ///
  /// In es, this message translates to:
  /// **'Inicia sesión'**
  String get registerLoginLink;

  /// No description provided for @registerPasswordLength.
  ///
  /// In es, this message translates to:
  /// **'Mínimo 8 caracteres'**
  String get registerPasswordLength;

  /// No description provided for @registerPasswordUppercase.
  ///
  /// In es, this message translates to:
  /// **'Una letra mayúscula'**
  String get registerPasswordUppercase;

  /// No description provided for @registerPasswordNumber.
  ///
  /// In es, this message translates to:
  /// **'Un número'**
  String get registerPasswordNumber;

  /// No description provided for @registerPasswordSpecial.
  ///
  /// In es, this message translates to:
  /// **'Un carácter especial (!@#\$...)'**
  String get registerPasswordSpecial;

  /// No description provided for @registerPasswordMatch.
  ///
  /// In es, this message translates to:
  /// **'Las contraseñas coinciden'**
  String get registerPasswordMatch;

  /// No description provided for @registerErrorEmailInUse.
  ///
  /// In es, this message translates to:
  /// **'Este correo ya está registrado'**
  String get registerErrorEmailInUse;

  /// No description provided for @registerSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Únete a LOME y empieza a gestionar tu negocio'**
  String get registerSubtitle;

  /// No description provided for @registerAccountTypeCustomer.
  ///
  /// In es, this message translates to:
  /// **'Cliente'**
  String get registerAccountTypeCustomer;

  /// No description provided for @registerAccountTypeCustomerDesc.
  ///
  /// In es, this message translates to:
  /// **'Pide comida a domicilio'**
  String get registerAccountTypeCustomerDesc;

  /// No description provided for @registerAccountTypeRestaurant.
  ///
  /// In es, this message translates to:
  /// **'Restaurante'**
  String get registerAccountTypeRestaurant;

  /// No description provided for @registerAccountTypeRestaurantDesc.
  ///
  /// In es, this message translates to:
  /// **'Gestiona tu negocio'**
  String get registerAccountTypeRestaurantDesc;

  /// No description provided for @registerRestaurantNameLabel.
  ///
  /// In es, this message translates to:
  /// **'Nombre del restaurante'**
  String get registerRestaurantNameLabel;

  /// No description provided for @registerRestaurantNameHint.
  ///
  /// In es, this message translates to:
  /// **'Mi Restaurante'**
  String get registerRestaurantNameHint;

  /// No description provided for @registerPhoneLabel.
  ///
  /// In es, this message translates to:
  /// **'Teléfono (opcional)'**
  String get registerPhoneLabel;

  /// No description provided for @registerConfirmPasswordLabel.
  ///
  /// In es, this message translates to:
  /// **'Confirmar contraseña'**
  String get registerConfirmPasswordLabel;

  /// No description provided for @registerCreateRestaurantButton.
  ///
  /// In es, this message translates to:
  /// **'Crear restaurante'**
  String get registerCreateRestaurantButton;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In es, this message translates to:
  /// **'Recuperar contraseña'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Introduce tu email y te enviaremos un enlace para restablecer tu contraseña'**
  String get forgotPasswordSubtitle;

  /// No description provided for @forgotPasswordEmailHint.
  ///
  /// In es, this message translates to:
  /// **'tu@email.com'**
  String get forgotPasswordEmailHint;

  /// No description provided for @forgotPasswordSendButton.
  ///
  /// In es, this message translates to:
  /// **'Enviar enlace'**
  String get forgotPasswordSendButton;

  /// No description provided for @forgotPasswordSent.
  ///
  /// In es, this message translates to:
  /// **'Email enviado. Revisa tu bandeja de entrada.'**
  String get forgotPasswordSent;

  /// No description provided for @forgotPasswordBackToLogin.
  ///
  /// In es, this message translates to:
  /// **'Volver al inicio de sesión'**
  String get forgotPasswordBackToLogin;

  /// No description provided for @forgotPasswordSentTitle.
  ///
  /// In es, this message translates to:
  /// **'¡Email enviado!'**
  String get forgotPasswordSentTitle;

  /// No description provided for @forgotPasswordSentDesc.
  ///
  /// In es, this message translates to:
  /// **'Hemos enviado las instrucciones a'**
  String get forgotPasswordSentDesc;

  /// No description provided for @forgotPasswordSentInstructions.
  ///
  /// In es, this message translates to:
  /// **'Revisa tu bandeja de entrada y sigue las instrucciones del email para restablecer tu contraseña.'**
  String get forgotPasswordSentInstructions;

  /// No description provided for @forgotPasswordResend.
  ///
  /// In es, this message translates to:
  /// **'¿No recibiste el email? Reenviar'**
  String get forgotPasswordResend;

  /// No description provided for @forgotPasswordResendWait.
  ///
  /// In es, this message translates to:
  /// **'Podrás reenviar en'**
  String get forgotPasswordResendWait;

  /// No description provided for @resetPasswordTitle.
  ///
  /// In es, this message translates to:
  /// **'Nueva contraseña'**
  String get resetPasswordTitle;

  /// No description provided for @resetPasswordSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Introduce tu nueva contraseña'**
  String get resetPasswordSubtitle;

  /// No description provided for @resetPasswordNewHint.
  ///
  /// In es, this message translates to:
  /// **'Nueva contraseña'**
  String get resetPasswordNewHint;

  /// No description provided for @resetPasswordConfirmHint.
  ///
  /// In es, this message translates to:
  /// **'Confirmar nueva contraseña'**
  String get resetPasswordConfirmHint;

  /// No description provided for @resetPasswordButton.
  ///
  /// In es, this message translates to:
  /// **'Restablecer contraseña'**
  String get resetPasswordButton;

  /// No description provided for @resetPasswordSuccess.
  ///
  /// In es, this message translates to:
  /// **'Contraseña restablecida correctamente'**
  String get resetPasswordSuccess;

  /// No description provided for @resetPasswordConfirmLabel.
  ///
  /// In es, this message translates to:
  /// **'Confirmar contraseña'**
  String get resetPasswordConfirmLabel;

  /// No description provided for @passwordRequirementsTitle.
  ///
  /// In es, this message translates to:
  /// **'Requisitos de contraseña'**
  String get passwordRequirementsTitle;

  /// No description provided for @resetPasswordSuccessMessage.
  ///
  /// In es, this message translates to:
  /// **'Tu contraseña se ha restablecido correctamente.\nYa puedes iniciar sesión con tu nueva contraseña.'**
  String get resetPasswordSuccessMessage;

  /// No description provided for @emailVerificationTitle.
  ///
  /// In es, this message translates to:
  /// **'Verifica tu email'**
  String get emailVerificationTitle;

  /// No description provided for @emailVerificationSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Hemos enviado un enlace de verificación a tu correo electrónico'**
  String get emailVerificationSubtitle;

  /// No description provided for @emailVerificationResend.
  ///
  /// In es, this message translates to:
  /// **'Reenviar email'**
  String get emailVerificationResend;

  /// No description provided for @emailVerificationResent.
  ///
  /// In es, this message translates to:
  /// **'Email reenviado'**
  String get emailVerificationResent;

  /// No description provided for @emailVerificationCheckEmail.
  ///
  /// In es, this message translates to:
  /// **'Revisa tu bandeja de entrada'**
  String get emailVerificationCheckEmail;

  /// No description provided for @emailVerificationBackToLogin.
  ///
  /// In es, this message translates to:
  /// **'Volver al inicio de sesión'**
  String get emailVerificationBackToLogin;

  /// No description provided for @emailVerificationSentTo.
  ///
  /// In es, this message translates to:
  /// **'Hemos enviado un enlace de verificación a'**
  String get emailVerificationSentTo;

  /// No description provided for @emailVerificationStep1.
  ///
  /// In es, this message translates to:
  /// **'Abre tu bandeja de entrada'**
  String get emailVerificationStep1;

  /// No description provided for @emailVerificationStep2.
  ///
  /// In es, this message translates to:
  /// **'Busca el email de LŌME'**
  String get emailVerificationStep2;

  /// No description provided for @emailVerificationStep3.
  ///
  /// In es, this message translates to:
  /// **'Haz clic en el enlace de verificación'**
  String get emailVerificationStep3;

  /// No description provided for @emailVerificationConfirm.
  ///
  /// In es, this message translates to:
  /// **'Ya verifiqué mi email'**
  String get emailVerificationConfirm;

  /// No description provided for @emailVerificationResendCountdown.
  ///
  /// In es, this message translates to:
  /// **'Reenviar en {seconds}s'**
  String emailVerificationResendCountdown(int seconds);

  /// No description provided for @emailVerificationNotReceived.
  ///
  /// In es, this message translates to:
  /// **'¿No recibiste el email? Reenviar'**
  String get emailVerificationNotReceived;

  /// No description provided for @emailVerificationSpamNote.
  ///
  /// In es, this message translates to:
  /// **'Si no encuentras el email, revisa tu carpeta de spam.'**
  String get emailVerificationSpamNote;

  /// No description provided for @emailVerificationSnackbar.
  ///
  /// In es, this message translates to:
  /// **'Email de verificación reenviado'**
  String get emailVerificationSnackbar;

  /// No description provided for @profile.
  ///
  /// In es, this message translates to:
  /// **'Perfil'**
  String get profile;

  /// No description provided for @editProfile.
  ///
  /// In es, this message translates to:
  /// **'Editar perfil'**
  String get editProfile;

  /// No description provided for @changePassword.
  ///
  /// In es, this message translates to:
  /// **'Cambiar contraseña'**
  String get changePassword;

  /// No description provided for @deleteAccount.
  ///
  /// In es, this message translates to:
  /// **'Eliminar cuenta'**
  String get deleteAccount;

  /// No description provided for @profileUpdated.
  ///
  /// In es, this message translates to:
  /// **'Perfil actualizado correctamente'**
  String get profileUpdated;

  /// No description provided for @passwordChanged.
  ///
  /// In es, this message translates to:
  /// **'Contraseña actualizada correctamente'**
  String get passwordChanged;

  /// No description provided for @accountDeleted.
  ///
  /// In es, this message translates to:
  /// **'Cuenta eliminada correctamente'**
  String get accountDeleted;

  /// No description provided for @editProfilePhotoChange.
  ///
  /// In es, this message translates to:
  /// **'Cambiar foto de perfil'**
  String get editProfilePhotoChange;

  /// No description provided for @editProfilePhotoGallery.
  ///
  /// In es, this message translates to:
  /// **'Elegir de la galería'**
  String get editProfilePhotoGallery;

  /// No description provided for @editProfilePhotoCamera.
  ///
  /// In es, this message translates to:
  /// **'Tomar una foto'**
  String get editProfilePhotoCamera;

  /// No description provided for @editProfileNameHint.
  ///
  /// In es, this message translates to:
  /// **'Tu nombre'**
  String get editProfileNameHint;

  /// No description provided for @editProfileEmailNote.
  ///
  /// In es, this message translates to:
  /// **'El email se gestiona desde la configuración de tu cuenta'**
  String get editProfileEmailNote;

  /// No description provided for @editProfilePhoneHint.
  ///
  /// In es, this message translates to:
  /// **'Tu teléfono'**
  String get editProfilePhoneHint;

  /// No description provided for @editProfileNewPasswordHint.
  ///
  /// In es, this message translates to:
  /// **'Nueva contraseña'**
  String get editProfileNewPasswordHint;

  /// No description provided for @editProfileDeleteButton.
  ///
  /// In es, this message translates to:
  /// **'ELIMINAR'**
  String get editProfileDeleteButton;

  /// No description provided for @editProfileDeleteConfirmTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar tu cuenta?'**
  String get editProfileDeleteConfirmTitle;

  /// No description provided for @editProfileDeleteConfirmSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Esta acción es irreversible. Se eliminarán todos tus datos.'**
  String get editProfileDeleteConfirmSubtitle;

  /// No description provided for @home.
  ///
  /// In es, this message translates to:
  /// **'Inicio'**
  String get home;

  /// No description provided for @orders.
  ///
  /// In es, this message translates to:
  /// **'Pedidos'**
  String get orders;

  /// No description provided for @tables.
  ///
  /// In es, this message translates to:
  /// **'Mesas'**
  String get tables;

  /// No description provided for @menu.
  ///
  /// In es, this message translates to:
  /// **'Menú'**
  String get menu;

  /// No description provided for @reservations.
  ///
  /// In es, this message translates to:
  /// **'Reservaciones'**
  String get reservations;

  /// No description provided for @settings.
  ///
  /// In es, this message translates to:
  /// **'Configuración'**
  String get settings;

  /// No description provided for @notifications.
  ///
  /// In es, this message translates to:
  /// **'Notificaciones'**
  String get notifications;

  /// No description provided for @dashboard.
  ///
  /// In es, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @shellMore.
  ///
  /// In es, this message translates to:
  /// **'Más'**
  String get shellMore;

  /// No description provided for @orderStatus_pending.
  ///
  /// In es, this message translates to:
  /// **'Pendiente'**
  String get orderStatus_pending;

  /// No description provided for @orderStatus_preparing.
  ///
  /// In es, this message translates to:
  /// **'En preparación'**
  String get orderStatus_preparing;

  /// No description provided for @orderStatus_ready.
  ///
  /// In es, this message translates to:
  /// **'Listo'**
  String get orderStatus_ready;

  /// No description provided for @orderStatus_delivered.
  ///
  /// In es, this message translates to:
  /// **'Entregado'**
  String get orderStatus_delivered;

  /// No description provided for @orderStatus_cancelled.
  ///
  /// In es, this message translates to:
  /// **'Cancelado'**
  String get orderStatus_cancelled;

  /// No description provided for @tableStatus_available.
  ///
  /// In es, this message translates to:
  /// **'Disponible'**
  String get tableStatus_available;

  /// No description provided for @tableStatus_occupied.
  ///
  /// In es, this message translates to:
  /// **'Ocupada'**
  String get tableStatus_occupied;

  /// No description provided for @tableStatus_reserved.
  ///
  /// In es, this message translates to:
  /// **'Reservada'**
  String get tableStatus_reserved;

  /// No description provided for @marketplace.
  ///
  /// In es, this message translates to:
  /// **'Marketplace'**
  String get marketplace;

  /// No description provided for @restaurants.
  ///
  /// In es, this message translates to:
  /// **'Restaurantes'**
  String get restaurants;

  /// No description provided for @favorites.
  ///
  /// In es, this message translates to:
  /// **'Favoritos'**
  String get favorites;

  /// No description provided for @promotions.
  ///
  /// In es, this message translates to:
  /// **'Promociones'**
  String get promotions;

  /// No description provided for @reviews.
  ///
  /// In es, this message translates to:
  /// **'Reseñas'**
  String get reviews;

  /// No description provided for @cart.
  ///
  /// In es, this message translates to:
  /// **'Carrito'**
  String get cart;

  /// No description provided for @checkout.
  ///
  /// In es, this message translates to:
  /// **'Pagar'**
  String get checkout;

  /// No description provided for @deliveryAddress.
  ///
  /// In es, this message translates to:
  /// **'Dirección de entrega'**
  String get deliveryAddress;

  /// No description provided for @trackOrder.
  ///
  /// In es, this message translates to:
  /// **'Rastrear pedido'**
  String get trackOrder;

  /// No description provided for @marketplaceHomeSearchHint.
  ///
  /// In es, this message translates to:
  /// **'¿Qué te apetece hoy?'**
  String get marketplaceHomeSearchHint;

  /// No description provided for @marketplaceHomeFeatured.
  ///
  /// In es, this message translates to:
  /// **'Destacados'**
  String get marketplaceHomeFeatured;

  /// No description provided for @marketplaceHomeNearby.
  ///
  /// In es, this message translates to:
  /// **'Cerca de ti'**
  String get marketplaceHomeNearby;

  /// No description provided for @marketplaceHomePopular.
  ///
  /// In es, this message translates to:
  /// **'Populares'**
  String get marketplaceHomePopular;

  /// No description provided for @marketplaceHomeCategories.
  ///
  /// In es, this message translates to:
  /// **'Categorías'**
  String get marketplaceHomeCategories;

  /// No description provided for @marketplaceHomeDeliveryTime.
  ///
  /// In es, this message translates to:
  /// **'{minutes} min'**
  String marketplaceHomeDeliveryTime(String minutes);

  /// No description provided for @marketplaceHomeMinOrder.
  ///
  /// In es, this message translates to:
  /// **'Pedido mín. {amount}'**
  String marketplaceHomeMinOrder(String amount);

  /// No description provided for @marketplaceHomeFreeDelivery.
  ///
  /// In es, this message translates to:
  /// **'Envío gratis'**
  String get marketplaceHomeFreeDelivery;

  /// No description provided for @marketplaceHomeNoRestaurants.
  ///
  /// In es, this message translates to:
  /// **'No hay restaurantes disponibles'**
  String get marketplaceHomeNoRestaurants;

  /// No description provided for @marketplaceHomeNoRestaurantsSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Prueba cambiando los filtros o tu ubicación'**
  String get marketplaceHomeNoRestaurantsSubtitle;

  /// No description provided for @marketplaceSearchHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar restaurantes o platos...'**
  String get marketplaceSearchHint;

  /// No description provided for @marketplaceSearchEmpty.
  ///
  /// In es, this message translates to:
  /// **'No encontramos resultados'**
  String get marketplaceSearchEmpty;

  /// No description provided for @marketplaceSearchRecent.
  ///
  /// In es, this message translates to:
  /// **'Búsquedas recientes'**
  String get marketplaceSearchRecent;

  /// No description provided for @marketplaceSearchRestaurantsSection.
  ///
  /// In es, this message translates to:
  /// **'{count} Restaurantes'**
  String marketplaceSearchRestaurantsSection(int count);

  /// No description provided for @marketplaceSearchDishesSection.
  ///
  /// In es, this message translates to:
  /// **'{count} Platos'**
  String marketplaceSearchDishesSection(int count);

  /// No description provided for @marketplaceCartEmpty.
  ///
  /// In es, this message translates to:
  /// **'Tu carrito está vacío'**
  String get marketplaceCartEmpty;

  /// No description provided for @marketplaceCartEmptySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Añade platos de un restaurante para empezar'**
  String get marketplaceCartEmptySubtitle;

  /// No description provided for @marketplaceCartItemCount.
  ///
  /// In es, this message translates to:
  /// **'{count} productos'**
  String marketplaceCartItemCount(int count);

  /// No description provided for @marketplaceCartDeliveryFee.
  ///
  /// In es, this message translates to:
  /// **'Gastos de envío'**
  String get marketplaceCartDeliveryFee;

  /// No description provided for @marketplaceCartServiceFee.
  ///
  /// In es, this message translates to:
  /// **'Tarifa de servicio'**
  String get marketplaceCartServiceFee;

  /// No description provided for @marketplaceCartClearAll.
  ///
  /// In es, this message translates to:
  /// **'Vaciar carrito'**
  String get marketplaceCartClearAll;

  /// No description provided for @marketplaceCheckoutTitle.
  ///
  /// In es, this message translates to:
  /// **'Confirmar pedido'**
  String get marketplaceCheckoutTitle;

  /// No description provided for @marketplaceCheckoutDeliveryAddress.
  ///
  /// In es, this message translates to:
  /// **'Dirección de entrega'**
  String get marketplaceCheckoutDeliveryAddress;

  /// No description provided for @marketplaceCheckoutAddAddress.
  ///
  /// In es, this message translates to:
  /// **'Añadir dirección'**
  String get marketplaceCheckoutAddAddress;

  /// No description provided for @marketplaceCheckoutPaymentMethod.
  ///
  /// In es, this message translates to:
  /// **'Método de pago'**
  String get marketplaceCheckoutPaymentMethod;

  /// No description provided for @marketplaceCheckoutAddPayment.
  ///
  /// In es, this message translates to:
  /// **'Añadir método de pago'**
  String get marketplaceCheckoutAddPayment;

  /// No description provided for @marketplaceCheckoutOrderSummary.
  ///
  /// In es, this message translates to:
  /// **'Resumen del pedido'**
  String get marketplaceCheckoutOrderSummary;

  /// No description provided for @marketplaceCheckoutPlaceOrder.
  ///
  /// In es, this message translates to:
  /// **'Realizar pedido'**
  String get marketplaceCheckoutPlaceOrder;

  /// No description provided for @marketplaceCheckoutSchedule.
  ///
  /// In es, this message translates to:
  /// **'Programar entrega'**
  String get marketplaceCheckoutSchedule;

  /// No description provided for @marketplaceCheckoutNow.
  ///
  /// In es, this message translates to:
  /// **'Lo antes posible'**
  String get marketplaceCheckoutNow;

  /// No description provided for @marketplaceCheckoutNotes.
  ///
  /// In es, this message translates to:
  /// **'Notas para el restaurante'**
  String get marketplaceCheckoutNotes;

  /// No description provided for @marketplaceCheckoutNotesHint.
  ///
  /// In es, this message translates to:
  /// **'Instrucciones especiales, alergias...'**
  String get marketplaceCheckoutNotesHint;

  /// No description provided for @marketplaceCheckoutPromoCode.
  ///
  /// In es, this message translates to:
  /// **'Código promocional'**
  String get marketplaceCheckoutPromoCode;

  /// No description provided for @marketplaceCheckoutApply.
  ///
  /// In es, this message translates to:
  /// **'Aplicar'**
  String get marketplaceCheckoutApply;

  /// No description provided for @marketplaceCheckoutDeliveryEstimate.
  ///
  /// In es, this message translates to:
  /// **'Entrega estimada: {time}'**
  String marketplaceCheckoutDeliveryEstimate(String time);

  /// No description provided for @marketplaceFavoritesEmpty.
  ///
  /// In es, this message translates to:
  /// **'No tienes favoritos aún'**
  String get marketplaceFavoritesEmpty;

  /// No description provided for @marketplaceFavoritesEmptySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Guarda tus restaurantes favoritos para acceder rápido'**
  String get marketplaceFavoritesEmptySubtitle;

  /// No description provided for @marketplaceRestaurantMenuSearchHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar en el menú...'**
  String get marketplaceRestaurantMenuSearchHint;

  /// No description provided for @marketplaceRestaurantMenuEmpty.
  ///
  /// In es, this message translates to:
  /// **'Este restaurante aún no tiene menú'**
  String get marketplaceRestaurantMenuEmpty;

  /// No description provided for @marketplaceRestaurantMenuAddToCart.
  ///
  /// In es, this message translates to:
  /// **'Añadir al carrito'**
  String get marketplaceRestaurantMenuAddToCart;

  /// No description provided for @marketplaceCustomerOrdersTitle.
  ///
  /// In es, this message translates to:
  /// **'Mis pedidos'**
  String get marketplaceCustomerOrdersTitle;

  /// No description provided for @marketplaceCustomerOrdersEmpty.
  ///
  /// In es, this message translates to:
  /// **'Aún no has hecho ningún pedido'**
  String get marketplaceCustomerOrdersEmpty;

  /// No description provided for @marketplaceCustomerOrdersActive.
  ///
  /// In es, this message translates to:
  /// **'Activos'**
  String get marketplaceCustomerOrdersActive;

  /// No description provided for @marketplaceCustomerOrdersPast.
  ///
  /// In es, this message translates to:
  /// **'Anteriores'**
  String get marketplaceCustomerOrdersPast;

  /// No description provided for @marketplaceCustomerOrdersReorder.
  ///
  /// In es, this message translates to:
  /// **'Repetir pedido'**
  String get marketplaceCustomerOrdersReorder;

  /// No description provided for @marketplaceOrderTrackingEstimated.
  ///
  /// In es, this message translates to:
  /// **'Tiempo estimado'**
  String get marketplaceOrderTrackingEstimated;

  /// No description provided for @marketplaceOrderTrackingDriver.
  ///
  /// In es, this message translates to:
  /// **'Tu repartidor'**
  String get marketplaceOrderTrackingDriver;

  /// No description provided for @marketplaceOrderTrackingContact.
  ///
  /// In es, this message translates to:
  /// **'Contactar'**
  String get marketplaceOrderTrackingContact;

  /// No description provided for @marketplaceOrderTrackingOrderPlaced.
  ///
  /// In es, this message translates to:
  /// **'Pedido realizado'**
  String get marketplaceOrderTrackingOrderPlaced;

  /// No description provided for @marketplaceOrderTrackingPreparing.
  ///
  /// In es, this message translates to:
  /// **'Preparando'**
  String get marketplaceOrderTrackingPreparing;

  /// No description provided for @marketplaceOrderTrackingOnTheWay.
  ///
  /// In es, this message translates to:
  /// **'En camino'**
  String get marketplaceOrderTrackingOnTheWay;

  /// No description provided for @marketplaceOrderTrackingDelivered.
  ///
  /// In es, this message translates to:
  /// **'Entregado'**
  String get marketplaceOrderTrackingDelivered;

  /// No description provided for @marketplaceOrderTrackingOrderNumber.
  ///
  /// In es, this message translates to:
  /// **'Pedido #{number}'**
  String marketplaceOrderTrackingOrderNumber(String number);

  /// No description provided for @marketplaceOrderTrackingHelp.
  ///
  /// In es, this message translates to:
  /// **'¿Necesitas ayuda?'**
  String get marketplaceOrderTrackingHelp;

  /// No description provided for @marketplaceOrderTrackingCancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar pedido'**
  String get marketplaceOrderTrackingCancel;

  /// No description provided for @marketplaceOrderTrackingRate.
  ///
  /// In es, this message translates to:
  /// **'Calificar pedido'**
  String get marketplaceOrderTrackingRate;

  /// No description provided for @marketplaceProfileEditProfile.
  ///
  /// In es, this message translates to:
  /// **'Editar perfil'**
  String get marketplaceProfileEditProfile;

  /// No description provided for @marketplaceProfileAddresses.
  ///
  /// In es, this message translates to:
  /// **'Mis direcciones'**
  String get marketplaceProfileAddresses;

  /// No description provided for @marketplaceProfilePaymentMethods.
  ///
  /// In es, this message translates to:
  /// **'Métodos de pago'**
  String get marketplaceProfilePaymentMethods;

  /// No description provided for @marketplaceProfileOrderHistory.
  ///
  /// In es, this message translates to:
  /// **'Historial de pedidos'**
  String get marketplaceProfileOrderHistory;

  /// No description provided for @marketplaceProfileHelp.
  ///
  /// In es, this message translates to:
  /// **'Ayuda y soporte'**
  String get marketplaceProfileHelp;

  /// No description provided for @marketplaceProfileAbout.
  ///
  /// In es, this message translates to:
  /// **'Acerca de LŌME'**
  String get marketplaceProfileAbout;

  /// No description provided for @marketplaceProfileSignOut.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get marketplaceProfileSignOut;

  /// No description provided for @admin.
  ///
  /// In es, this message translates to:
  /// **'Administración'**
  String get admin;

  /// No description provided for @incidents.
  ///
  /// In es, this message translates to:
  /// **'Incidencias'**
  String get incidents;

  /// No description provided for @subscriptions.
  ///
  /// In es, this message translates to:
  /// **'Suscripciones'**
  String get subscriptions;

  /// No description provided for @moderation.
  ///
  /// In es, this message translates to:
  /// **'Moderación'**
  String get moderation;

  /// No description provided for @audit.
  ///
  /// In es, this message translates to:
  /// **'Auditoría'**
  String get audit;

  /// No description provided for @monitoring.
  ///
  /// In es, this message translates to:
  /// **'Monitoreo'**
  String get monitoring;

  /// No description provided for @analytics.
  ///
  /// In es, this message translates to:
  /// **'Analíticas'**
  String get analytics;

  /// No description provided for @adminDashboardTitle.
  ///
  /// In es, this message translates to:
  /// **'Panel de administración'**
  String get adminDashboardTitle;

  /// No description provided for @adminDashboardActiveRestaurants.
  ///
  /// In es, this message translates to:
  /// **'Restaurantes activos'**
  String get adminDashboardActiveRestaurants;

  /// No description provided for @adminDashboardPendingTenants.
  ///
  /// In es, this message translates to:
  /// **'Tenants pendientes'**
  String get adminDashboardPendingTenants;

  /// No description provided for @adminDashboardMonthlyRevenue.
  ///
  /// In es, this message translates to:
  /// **'Ingresos mensuales'**
  String get adminDashboardMonthlyRevenue;

  /// No description provided for @adminDashboardActiveIncidents.
  ///
  /// In es, this message translates to:
  /// **'Incidencias activas'**
  String get adminDashboardActiveIncidents;

  /// No description provided for @adminDashboardPendingCount.
  ///
  /// In es, this message translates to:
  /// **'{count} pendientes'**
  String adminDashboardPendingCount(int count);

  /// No description provided for @adminDashboardRecentActivity.
  ///
  /// In es, this message translates to:
  /// **'Actividad reciente'**
  String get adminDashboardRecentActivity;

  /// No description provided for @adminDashboardEmptyActivity.
  ///
  /// In es, this message translates to:
  /// **'Sin actividad reciente'**
  String get adminDashboardEmptyActivity;

  /// No description provided for @adminDashboardQuickActions.
  ///
  /// In es, this message translates to:
  /// **'Acciones rápidas'**
  String get adminDashboardQuickActions;

  /// No description provided for @adminDashboardReviewTenants.
  ///
  /// In es, this message translates to:
  /// **'Revisar tenants'**
  String get adminDashboardReviewTenants;

  /// No description provided for @adminDashboardManageIncidents.
  ///
  /// In es, this message translates to:
  /// **'Gestionar incidencias'**
  String get adminDashboardManageIncidents;

  /// No description provided for @adminDashboardViewAnalytics.
  ///
  /// In es, this message translates to:
  /// **'Ver analíticas'**
  String get adminDashboardViewAnalytics;

  /// No description provided for @adminDashboardSystemMonitoring.
  ///
  /// In es, this message translates to:
  /// **'Monitoreo del sistema'**
  String get adminDashboardSystemMonitoring;

  /// No description provided for @adminRestaurantsTitle.
  ///
  /// In es, this message translates to:
  /// **'Restaurantes'**
  String get adminRestaurantsTitle;

  /// No description provided for @adminRestaurantsSearchHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar restaurantes...'**
  String get adminRestaurantsSearchHint;

  /// No description provided for @adminRestaurantsFilterAll.
  ///
  /// In es, this message translates to:
  /// **'Todos'**
  String get adminRestaurantsFilterAll;

  /// No description provided for @adminRestaurantsFilterActive.
  ///
  /// In es, this message translates to:
  /// **'Activos'**
  String get adminRestaurantsFilterActive;

  /// No description provided for @adminRestaurantsFilterPending.
  ///
  /// In es, this message translates to:
  /// **'Pendientes'**
  String get adminRestaurantsFilterPending;

  /// No description provided for @adminRestaurantsFilterSuspended.
  ///
  /// In es, this message translates to:
  /// **'Suspendidos'**
  String get adminRestaurantsFilterSuspended;

  /// No description provided for @adminRestaurantsEmpty.
  ///
  /// In es, this message translates to:
  /// **'No hay restaurantes'**
  String get adminRestaurantsEmpty;

  /// No description provided for @adminRestaurantsOwner.
  ///
  /// In es, this message translates to:
  /// **'Propietario: {name}'**
  String adminRestaurantsOwner(String name);

  /// No description provided for @adminRestaurantsCreated.
  ///
  /// In es, this message translates to:
  /// **'Creado: {date}'**
  String adminRestaurantsCreated(String date);

  /// No description provided for @adminRestaurantDetailBackButton.
  ///
  /// In es, this message translates to:
  /// **'Restaurantes'**
  String get adminRestaurantDetailBackButton;

  /// No description provided for @adminRestaurantDetailTabInfo.
  ///
  /// In es, this message translates to:
  /// **'Información'**
  String get adminRestaurantDetailTabInfo;

  /// No description provided for @adminRestaurantDetailTabActivity.
  ///
  /// In es, this message translates to:
  /// **'Actividad'**
  String get adminRestaurantDetailTabActivity;

  /// No description provided for @adminRestaurantDetailTabSubscription.
  ///
  /// In es, this message translates to:
  /// **'Suscripción'**
  String get adminRestaurantDetailTabSubscription;

  /// No description provided for @adminRestaurantDetailOwner.
  ///
  /// In es, this message translates to:
  /// **'Propietario'**
  String get adminRestaurantDetailOwner;

  /// No description provided for @adminRestaurantDetailEmail.
  ///
  /// In es, this message translates to:
  /// **'Email'**
  String get adminRestaurantDetailEmail;

  /// No description provided for @adminRestaurantDetailPhone.
  ///
  /// In es, this message translates to:
  /// **'Teléfono'**
  String get adminRestaurantDetailPhone;

  /// No description provided for @adminRestaurantDetailAddress.
  ///
  /// In es, this message translates to:
  /// **'Dirección'**
  String get adminRestaurantDetailAddress;

  /// No description provided for @adminRestaurantDetailCreated.
  ///
  /// In es, this message translates to:
  /// **'Fecha de creación'**
  String get adminRestaurantDetailCreated;

  /// No description provided for @adminRestaurantDetailPlan.
  ///
  /// In es, this message translates to:
  /// **'Plan'**
  String get adminRestaurantDetailPlan;

  /// No description provided for @adminRestaurantDetailStatus.
  ///
  /// In es, this message translates to:
  /// **'Estado'**
  String get adminRestaurantDetailStatus;

  /// No description provided for @adminRestaurantDetailSuspend.
  ///
  /// In es, this message translates to:
  /// **'Suspender'**
  String get adminRestaurantDetailSuspend;

  /// No description provided for @adminRestaurantDetailRestore.
  ///
  /// In es, this message translates to:
  /// **'Restaurar'**
  String get adminRestaurantDetailRestore;

  /// No description provided for @adminRestaurantDetailApprove.
  ///
  /// In es, this message translates to:
  /// **'Aprobar'**
  String get adminRestaurantDetailApprove;

  /// No description provided for @adminRestaurantDetailReject.
  ///
  /// In es, this message translates to:
  /// **'Rechazar'**
  String get adminRestaurantDetailReject;

  /// No description provided for @adminRestaurantDetailRejectTitle.
  ///
  /// In es, this message translates to:
  /// **'Rechazar restaurante'**
  String get adminRestaurantDetailRejectTitle;

  /// No description provided for @adminRestaurantDetailRejectReason.
  ///
  /// In es, this message translates to:
  /// **'Motivo del rechazo'**
  String get adminRestaurantDetailRejectReason;

  /// No description provided for @adminRestaurantDetailRejectButton.
  ///
  /// In es, this message translates to:
  /// **'Confirmar rechazo'**
  String get adminRestaurantDetailRejectButton;

  /// No description provided for @adminAnalyticsTitle.
  ///
  /// In es, this message translates to:
  /// **'Analíticas'**
  String get adminAnalyticsTitle;

  /// No description provided for @adminAnalyticsTotalRevenue.
  ///
  /// In es, this message translates to:
  /// **'Ingresos totales'**
  String get adminAnalyticsTotalRevenue;

  /// No description provided for @adminAnalyticsActiveRestaurants.
  ///
  /// In es, this message translates to:
  /// **'Restaurantes activos'**
  String get adminAnalyticsActiveRestaurants;

  /// No description provided for @adminAnalyticsTotalOrders.
  ///
  /// In es, this message translates to:
  /// **'Pedidos totales'**
  String get adminAnalyticsTotalOrders;

  /// No description provided for @adminAnalyticsAvgTicket.
  ///
  /// In es, this message translates to:
  /// **'Ticket medio'**
  String get adminAnalyticsAvgTicket;

  /// No description provided for @adminAnalyticsRevenueChart.
  ///
  /// In es, this message translates to:
  /// **'Gráfico de ingresos'**
  String get adminAnalyticsRevenueChart;

  /// No description provided for @adminAnalyticsTopRestaurants.
  ///
  /// In es, this message translates to:
  /// **'Top restaurantes'**
  String get adminAnalyticsTopRestaurants;

  /// No description provided for @adminAnalyticsRevenueByPlan.
  ///
  /// In es, this message translates to:
  /// **'Ingresos por plan'**
  String get adminAnalyticsRevenueByPlan;

  /// No description provided for @adminAnalyticsPeriodMonth.
  ///
  /// In es, this message translates to:
  /// **'Mes'**
  String get adminAnalyticsPeriodMonth;

  /// No description provided for @adminAnalyticsPeriodQuarter.
  ///
  /// In es, this message translates to:
  /// **'Trimestre'**
  String get adminAnalyticsPeriodQuarter;

  /// No description provided for @adminAnalyticsPeriodYear.
  ///
  /// In es, this message translates to:
  /// **'Año'**
  String get adminAnalyticsPeriodYear;

  /// No description provided for @adminIncidentsTitle.
  ///
  /// In es, this message translates to:
  /// **'Incidencias'**
  String get adminIncidentsTitle;

  /// No description provided for @adminIncidentsSearchHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar incidencias...'**
  String get adminIncidentsSearchHint;

  /// No description provided for @adminIncidentsFilterAll.
  ///
  /// In es, this message translates to:
  /// **'Todas'**
  String get adminIncidentsFilterAll;

  /// No description provided for @adminIncidentsFilterOpen.
  ///
  /// In es, this message translates to:
  /// **'Abiertas'**
  String get adminIncidentsFilterOpen;

  /// No description provided for @adminIncidentsFilterInProgress.
  ///
  /// In es, this message translates to:
  /// **'En progreso'**
  String get adminIncidentsFilterInProgress;

  /// No description provided for @adminIncidentsFilterResolved.
  ///
  /// In es, this message translates to:
  /// **'Resueltas'**
  String get adminIncidentsFilterResolved;

  /// No description provided for @adminIncidentsEmpty.
  ///
  /// In es, this message translates to:
  /// **'No hay incidencias'**
  String get adminIncidentsEmpty;

  /// No description provided for @adminIncidentsCreated.
  ///
  /// In es, this message translates to:
  /// **'Creada: {date}'**
  String adminIncidentsCreated(String date);

  /// No description provided for @adminIncidentsBy.
  ///
  /// In es, this message translates to:
  /// **'Por: {name}'**
  String adminIncidentsBy(String name);

  /// No description provided for @adminIncidentsRestaurant.
  ///
  /// In es, this message translates to:
  /// **'Restaurante: {name}'**
  String adminIncidentsRestaurant(String name);

  /// No description provided for @adminIncidentDetailDescription.
  ///
  /// In es, this message translates to:
  /// **'Descripción'**
  String get adminIncidentDetailDescription;

  /// No description provided for @adminIncidentDetailReporter.
  ///
  /// In es, this message translates to:
  /// **'Reportado por'**
  String get adminIncidentDetailReporter;

  /// No description provided for @adminIncidentDetailRestaurant.
  ///
  /// In es, this message translates to:
  /// **'Restaurante'**
  String get adminIncidentDetailRestaurant;

  /// No description provided for @adminIncidentDetailCreated.
  ///
  /// In es, this message translates to:
  /// **'Fecha de creación'**
  String get adminIncidentDetailCreated;

  /// No description provided for @adminIncidentDetailPriority.
  ///
  /// In es, this message translates to:
  /// **'Prioridad'**
  String get adminIncidentDetailPriority;

  /// No description provided for @adminIncidentDetailTimeline.
  ///
  /// In es, this message translates to:
  /// **'Línea de tiempo'**
  String get adminIncidentDetailTimeline;

  /// No description provided for @adminIncidentDetailAddComment.
  ///
  /// In es, this message translates to:
  /// **'Añadir comentario'**
  String get adminIncidentDetailAddComment;

  /// No description provided for @adminIncidentDetailCommentHint.
  ///
  /// In es, this message translates to:
  /// **'Escribe un comentario...'**
  String get adminIncidentDetailCommentHint;

  /// No description provided for @adminIncidentDetailSend.
  ///
  /// In es, this message translates to:
  /// **'Enviar'**
  String get adminIncidentDetailSend;

  /// No description provided for @adminIncidentDetailResolve.
  ///
  /// In es, this message translates to:
  /// **'Resolver'**
  String get adminIncidentDetailResolve;

  /// No description provided for @adminIncidentDetailReopen.
  ///
  /// In es, this message translates to:
  /// **'Reabrir'**
  String get adminIncidentDetailReopen;

  /// No description provided for @adminIncidentDetailAssign.
  ///
  /// In es, this message translates to:
  /// **'Asignar'**
  String get adminIncidentDetailAssign;

  /// No description provided for @adminIncidentDetailPriorityLow.
  ///
  /// In es, this message translates to:
  /// **'Baja'**
  String get adminIncidentDetailPriorityLow;

  /// No description provided for @adminIncidentDetailPriorityMedium.
  ///
  /// In es, this message translates to:
  /// **'Media'**
  String get adminIncidentDetailPriorityMedium;

  /// No description provided for @adminIncidentDetailPriorityHigh.
  ///
  /// In es, this message translates to:
  /// **'Alta'**
  String get adminIncidentDetailPriorityHigh;

  /// No description provided for @adminIncidentDetailPriorityCritical.
  ///
  /// In es, this message translates to:
  /// **'Crítica'**
  String get adminIncidentDetailPriorityCritical;

  /// No description provided for @adminIncidentDetailTitle.
  ///
  /// In es, this message translates to:
  /// **'Detalle Incidencia'**
  String get adminIncidentDetailTitle;

  /// No description provided for @adminIncidentDetailNotFound.
  ///
  /// In es, this message translates to:
  /// **'Incidencia no encontrada'**
  String get adminIncidentDetailNotFound;

  /// No description provided for @adminIncidentDetailStatusOpen.
  ///
  /// In es, this message translates to:
  /// **'Abierta'**
  String get adminIncidentDetailStatusOpen;

  /// No description provided for @adminIncidentDetailStatusInProgress.
  ///
  /// In es, this message translates to:
  /// **'En curso'**
  String get adminIncidentDetailStatusInProgress;

  /// No description provided for @adminIncidentDetailStatusResolved.
  ///
  /// In es, this message translates to:
  /// **'Resuelta'**
  String get adminIncidentDetailStatusResolved;

  /// No description provided for @adminIncidentDetailStatusClosed.
  ///
  /// In es, this message translates to:
  /// **'Cerrada'**
  String get adminIncidentDetailStatusClosed;

  /// No description provided for @adminIncidentDetailAssignedTo.
  ///
  /// In es, this message translates to:
  /// **'Asignado a'**
  String get adminIncidentDetailAssignedTo;

  /// No description provided for @adminIncidentDetailCategory.
  ///
  /// In es, this message translates to:
  /// **'Categoría'**
  String get adminIncidentDetailCategory;

  /// No description provided for @adminIncidentDetailResolution.
  ///
  /// In es, this message translates to:
  /// **'Resolución'**
  String get adminIncidentDetailResolution;

  /// No description provided for @adminIncidentDetailMarkInProgress.
  ///
  /// In es, this message translates to:
  /// **'Marcar En Curso'**
  String get adminIncidentDetailMarkInProgress;

  /// No description provided for @adminIncidentDetailResolveIncident.
  ///
  /// In es, this message translates to:
  /// **'Resolver Incidencia'**
  String get adminIncidentDetailResolveIncident;

  /// No description provided for @adminIncidentDetailCloseWithoutResolve.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sin Resolver'**
  String get adminIncidentDetailCloseWithoutResolve;

  /// No description provided for @adminIncidentDetailResolveHint.
  ///
  /// In es, this message translates to:
  /// **'Describe la resolución...'**
  String get adminIncidentDetailResolveHint;

  /// No description provided for @adminModerationTabReviews.
  ///
  /// In es, this message translates to:
  /// **'Reseñas'**
  String get adminModerationTabReviews;

  /// No description provided for @adminModerationTabReports.
  ///
  /// In es, this message translates to:
  /// **'Reportes'**
  String get adminModerationTabReports;

  /// No description provided for @adminModerationTabContent.
  ///
  /// In es, this message translates to:
  /// **'Contenido'**
  String get adminModerationTabContent;

  /// No description provided for @adminModerationEmpty.
  ///
  /// In es, this message translates to:
  /// **'Sin contenido pendiente de moderación'**
  String get adminModerationEmpty;

  /// No description provided for @adminModerationApprove.
  ///
  /// In es, this message translates to:
  /// **'Aprobar'**
  String get adminModerationApprove;

  /// No description provided for @adminModerationReject.
  ///
  /// In es, this message translates to:
  /// **'Rechazar'**
  String get adminModerationReject;

  /// No description provided for @adminModerationFlag.
  ///
  /// In es, this message translates to:
  /// **'Marcar'**
  String get adminModerationFlag;

  /// No description provided for @adminModerationReported.
  ///
  /// In es, this message translates to:
  /// **'Reportado por: {name}'**
  String adminModerationReported(String name);

  /// No description provided for @adminModerationReason.
  ///
  /// In es, this message translates to:
  /// **'Motivo: {reason}'**
  String adminModerationReason(String reason);

  /// No description provided for @adminModerationTitle.
  ///
  /// In es, this message translates to:
  /// **'Moderación'**
  String get adminModerationTitle;

  /// No description provided for @adminModerationFlaggedReviewsTab.
  ///
  /// In es, this message translates to:
  /// **'Reseñas Flaggeadas'**
  String get adminModerationFlaggedReviewsTab;

  /// No description provided for @adminModerationNoReviews.
  ///
  /// In es, this message translates to:
  /// **'Sin reseñas pendientes'**
  String get adminModerationNoReviews;

  /// No description provided for @adminModerationAllReviewed.
  ///
  /// In es, this message translates to:
  /// **'Todas las reseñas flaggeadas han sido revisadas'**
  String get adminModerationAllReviewed;

  /// No description provided for @adminModerationUser.
  ///
  /// In es, this message translates to:
  /// **'Usuario'**
  String get adminModerationUser;

  /// No description provided for @adminModerationReviewApproved.
  ///
  /// In es, this message translates to:
  /// **'Reseña aprobada'**
  String get adminModerationReviewApproved;

  /// No description provided for @adminModerationReviewRejected.
  ///
  /// In es, this message translates to:
  /// **'Reseña rechazada'**
  String get adminModerationReviewRejected;

  /// No description provided for @adminSubscriptionsTitle.
  ///
  /// In es, this message translates to:
  /// **'Suscripciones'**
  String get adminSubscriptionsTitle;

  /// No description provided for @adminSubscriptionsSearchHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar suscripciones...'**
  String get adminSubscriptionsSearchHint;

  /// No description provided for @adminSubscriptionsTabAll.
  ///
  /// In es, this message translates to:
  /// **'Todas'**
  String get adminSubscriptionsTabAll;

  /// No description provided for @adminSubscriptionsTabActive.
  ///
  /// In es, this message translates to:
  /// **'Activas'**
  String get adminSubscriptionsTabActive;

  /// No description provided for @adminSubscriptionsTabTrial.
  ///
  /// In es, this message translates to:
  /// **'Prueba'**
  String get adminSubscriptionsTabTrial;

  /// No description provided for @adminSubscriptionsTabExpired.
  ///
  /// In es, this message translates to:
  /// **'Expiradas'**
  String get adminSubscriptionsTabExpired;

  /// No description provided for @adminSubscriptionsEmpty.
  ///
  /// In es, this message translates to:
  /// **'No hay suscripciones'**
  String get adminSubscriptionsEmpty;

  /// No description provided for @adminSubscriptionsCurrentPlan.
  ///
  /// In es, this message translates to:
  /// **'Plan actual'**
  String get adminSubscriptionsCurrentPlan;

  /// No description provided for @adminSubscriptionsNextBilling.
  ///
  /// In es, this message translates to:
  /// **'Próxima facturación'**
  String get adminSubscriptionsNextBilling;

  /// No description provided for @adminSubscriptionsRevenue.
  ///
  /// In es, this message translates to:
  /// **'Ingresos'**
  String get adminSubscriptionsRevenue;

  /// No description provided for @adminSubscriptionsChangePlan.
  ///
  /// In es, this message translates to:
  /// **'Cambiar plan'**
  String get adminSubscriptionsChangePlan;

  /// No description provided for @adminSubscriptionsCancelSubscription.
  ///
  /// In es, this message translates to:
  /// **'Cancelar suscripción'**
  String get adminSubscriptionsCancelSubscription;

  /// No description provided for @adminSubscriptionsExtendTrial.
  ///
  /// In es, this message translates to:
  /// **'Extender período de prueba'**
  String get adminSubscriptionsExtendTrial;

  /// No description provided for @adminSubscriptionsTrialDaysLeft.
  ///
  /// In es, this message translates to:
  /// **'{days} días restantes de prueba'**
  String adminSubscriptionsTrialDaysLeft(int days);

  /// No description provided for @adminSubscriptionsExpiredSince.
  ///
  /// In es, this message translates to:
  /// **'Expirada desde {date}'**
  String adminSubscriptionsExpiredSince(String date);

  /// No description provided for @adminSubscriptionsPlanBasic.
  ///
  /// In es, this message translates to:
  /// **'Básico'**
  String get adminSubscriptionsPlanBasic;

  /// No description provided for @adminSubscriptionsPlanPro.
  ///
  /// In es, this message translates to:
  /// **'Profesional'**
  String get adminSubscriptionsPlanPro;

  /// No description provided for @adminSubscriptionsPlanEnterprise.
  ///
  /// In es, this message translates to:
  /// **'Enterprise'**
  String get adminSubscriptionsPlanEnterprise;

  /// No description provided for @adminSubscriptionsBillingTitle.
  ///
  /// In es, this message translates to:
  /// **'Suscripciones & Facturación'**
  String get adminSubscriptionsBillingTitle;

  /// No description provided for @adminSubscriptionsTabSubscriptions.
  ///
  /// In es, this message translates to:
  /// **'Suscripciones'**
  String get adminSubscriptionsTabSubscriptions;

  /// No description provided for @adminSubscriptionsTabInvoices.
  ///
  /// In es, this message translates to:
  /// **'Facturas'**
  String get adminSubscriptionsTabInvoices;

  /// No description provided for @adminSubscriptionsMrr.
  ///
  /// In es, this message translates to:
  /// **'MRR'**
  String get adminSubscriptionsMrr;

  /// No description provided for @adminSubscriptionsActiveLabel.
  ///
  /// In es, this message translates to:
  /// **'Activas'**
  String get adminSubscriptionsActiveLabel;

  /// No description provided for @adminSubscriptionsPastDue.
  ///
  /// In es, this message translates to:
  /// **'Vencidas'**
  String get adminSubscriptionsPastDue;

  /// No description provided for @adminSubscriptionsCancelledLabel.
  ///
  /// In es, this message translates to:
  /// **'Canceladas'**
  String get adminSubscriptionsCancelledLabel;

  /// No description provided for @adminSubscriptionsNoSubscriptions.
  ///
  /// In es, this message translates to:
  /// **'Sin suscripciones'**
  String get adminSubscriptionsNoSubscriptions;

  /// No description provided for @adminSubscriptionsAllFilter.
  ///
  /// In es, this message translates to:
  /// **'Todas'**
  String get adminSubscriptionsAllFilter;

  /// No description provided for @adminSubscriptionsPeriodDates.
  ///
  /// In es, this message translates to:
  /// **'Período: {start} - {end}'**
  String adminSubscriptionsPeriodDates(String start, String end);

  /// No description provided for @adminSubscriptionsRenewalDate.
  ///
  /// In es, this message translates to:
  /// **'Renovación: {date}'**
  String adminSubscriptionsRenewalDate(String date);

  /// No description provided for @adminSubscriptionsReactivate.
  ///
  /// In es, this message translates to:
  /// **'Reactivar'**
  String get adminSubscriptionsReactivate;

  /// No description provided for @adminSubscriptionsBillingMonthly.
  ///
  /// In es, this message translates to:
  /// **'mes'**
  String get adminSubscriptionsBillingMonthly;

  /// No description provided for @adminSubscriptionsBillingYearly.
  ///
  /// In es, this message translates to:
  /// **'año'**
  String get adminSubscriptionsBillingYearly;

  /// No description provided for @adminSubscriptionsInvoicedLabel.
  ///
  /// In es, this message translates to:
  /// **'Facturado'**
  String get adminSubscriptionsInvoicedLabel;

  /// No description provided for @adminSubscriptionsPendingLabel.
  ///
  /// In es, this message translates to:
  /// **'Pendientes'**
  String get adminSubscriptionsPendingLabel;

  /// No description provided for @adminSubscriptionsOverdueLabel.
  ///
  /// In es, this message translates to:
  /// **'Vencidas'**
  String get adminSubscriptionsOverdueLabel;

  /// No description provided for @adminSubscriptionsPaidFilter.
  ///
  /// In es, this message translates to:
  /// **'Pagadas'**
  String get adminSubscriptionsPaidFilter;

  /// No description provided for @adminSubscriptionsNoInvoices.
  ///
  /// In es, this message translates to:
  /// **'Sin facturas'**
  String get adminSubscriptionsNoInvoices;

  /// No description provided for @adminSubscriptionsSubtotalAmount.
  ///
  /// In es, this message translates to:
  /// **'Subtotal: {amount}'**
  String adminSubscriptionsSubtotalAmount(String amount);

  /// No description provided for @adminSubscriptionsTaxAmount.
  ///
  /// In es, this message translates to:
  /// **'IVA: {amount}'**
  String adminSubscriptionsTaxAmount(String amount);

  /// No description provided for @adminSubscriptionsDueDate.
  ///
  /// In es, this message translates to:
  /// **'Vence: {date}'**
  String adminSubscriptionsDueDate(String date);

  /// No description provided for @adminSubscriptionsMarkPaid.
  ///
  /// In es, this message translates to:
  /// **'Marcar como Pagada'**
  String get adminSubscriptionsMarkPaid;

  /// No description provided for @adminSubscriptionsInvoicePaid.
  ///
  /// In es, this message translates to:
  /// **'Factura marcada como pagada'**
  String get adminSubscriptionsInvoicePaid;

  /// No description provided for @adminSubscriptionsPaidDate.
  ///
  /// In es, this message translates to:
  /// **'Pagada el {date}'**
  String adminSubscriptionsPaidDate(String date);

  /// No description provided for @adminSubscriptionsPlanFree.
  ///
  /// In es, this message translates to:
  /// **'Free'**
  String get adminSubscriptionsPlanFree;

  /// No description provided for @adminSubscriptionsStatusActive.
  ///
  /// In es, this message translates to:
  /// **'Activa'**
  String get adminSubscriptionsStatusActive;

  /// No description provided for @adminSubscriptionsStatusPastDue.
  ///
  /// In es, this message translates to:
  /// **'Vencida'**
  String get adminSubscriptionsStatusPastDue;

  /// No description provided for @adminSubscriptionsStatusCancelled.
  ///
  /// In es, this message translates to:
  /// **'Cancelada'**
  String get adminSubscriptionsStatusCancelled;

  /// No description provided for @adminSubscriptionsStatusTrialing.
  ///
  /// In es, this message translates to:
  /// **'Prueba'**
  String get adminSubscriptionsStatusTrialing;

  /// No description provided for @adminSubscriptionsInvoiceStatusPending.
  ///
  /// In es, this message translates to:
  /// **'Pendiente'**
  String get adminSubscriptionsInvoiceStatusPending;

  /// No description provided for @adminSubscriptionsInvoiceStatusPaid.
  ///
  /// In es, this message translates to:
  /// **'Pagada'**
  String get adminSubscriptionsInvoiceStatusPaid;

  /// No description provided for @adminSubscriptionsInvoiceStatusOverdue.
  ///
  /// In es, this message translates to:
  /// **'Vencida'**
  String get adminSubscriptionsInvoiceStatusOverdue;

  /// No description provided for @adminSubscriptionsInvoiceStatusCancelled.
  ///
  /// In es, this message translates to:
  /// **'Cancelada'**
  String get adminSubscriptionsInvoiceStatusCancelled;

  /// No description provided for @adminSubscriptionsInvoiceStatusRefunded.
  ///
  /// In es, this message translates to:
  /// **'Reembolsada'**
  String get adminSubscriptionsInvoiceStatusRefunded;

  /// No description provided for @adminAuditTitle.
  ///
  /// In es, this message translates to:
  /// **'Registro de auditoría'**
  String get adminAuditTitle;

  /// No description provided for @adminAuditSearchHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar en auditoría...'**
  String get adminAuditSearchHint;

  /// No description provided for @adminAuditFilterAll.
  ///
  /// In es, this message translates to:
  /// **'Todos'**
  String get adminAuditFilterAll;

  /// No description provided for @adminAuditFilterAuth.
  ///
  /// In es, this message translates to:
  /// **'Autenticación'**
  String get adminAuditFilterAuth;

  /// No description provided for @adminAuditFilterData.
  ///
  /// In es, this message translates to:
  /// **'Datos'**
  String get adminAuditFilterData;

  /// No description provided for @adminAuditFilterAdmin.
  ///
  /// In es, this message translates to:
  /// **'Admin'**
  String get adminAuditFilterAdmin;

  /// No description provided for @adminAuditFilterSystem.
  ///
  /// In es, this message translates to:
  /// **'Sistema'**
  String get adminAuditFilterSystem;

  /// No description provided for @adminAuditEmpty.
  ///
  /// In es, this message translates to:
  /// **'Sin registros de auditoría'**
  String get adminAuditEmpty;

  /// No description provided for @adminAuditDetails.
  ///
  /// In es, this message translates to:
  /// **'Detalles'**
  String get adminAuditDetails;

  /// No description provided for @adminAuditUser.
  ///
  /// In es, this message translates to:
  /// **'Usuario'**
  String get adminAuditUser;

  /// No description provided for @adminAuditAction.
  ///
  /// In es, this message translates to:
  /// **'Acción'**
  String get adminAuditAction;

  /// No description provided for @adminAuditTimestamp.
  ///
  /// In es, this message translates to:
  /// **'Fecha y hora'**
  String get adminAuditTimestamp;

  /// No description provided for @adminAuditIpAddress.
  ///
  /// In es, this message translates to:
  /// **'Dirección IP'**
  String get adminAuditIpAddress;

  /// No description provided for @adminAuditScreenTitle.
  ///
  /// In es, this message translates to:
  /// **'Auditoría'**
  String get adminAuditScreenTitle;

  /// No description provided for @adminAuditTotalEvents.
  ///
  /// In es, this message translates to:
  /// **'Total Eventos'**
  String get adminAuditTotalEvents;

  /// No description provided for @adminAuditActiveUsers.
  ///
  /// In es, this message translates to:
  /// **'Usuarios Activos'**
  String get adminAuditActiveUsers;

  /// No description provided for @adminAuditByAction.
  ///
  /// In es, this message translates to:
  /// **'Por Acción'**
  String get adminAuditByAction;

  /// No description provided for @adminAuditByEntity.
  ///
  /// In es, this message translates to:
  /// **'Por Entidad'**
  String get adminAuditByEntity;

  /// No description provided for @adminAuditEventLog.
  ///
  /// In es, this message translates to:
  /// **'Registro de Eventos'**
  String get adminAuditEventLog;

  /// No description provided for @adminAuditActionLabel.
  ///
  /// In es, this message translates to:
  /// **'Acción'**
  String get adminAuditActionLabel;

  /// No description provided for @adminAuditNoEvents.
  ///
  /// In es, this message translates to:
  /// **'Sin eventos de auditoría'**
  String get adminAuditNoEvents;

  /// No description provided for @adminAuditAllFilter.
  ///
  /// In es, this message translates to:
  /// **'Todas'**
  String get adminAuditAllFilter;

  /// No description provided for @adminAuditCreation.
  ///
  /// In es, this message translates to:
  /// **'Creación'**
  String get adminAuditCreation;

  /// No description provided for @adminAuditUpdate.
  ///
  /// In es, this message translates to:
  /// **'Actualización'**
  String get adminAuditUpdate;

  /// No description provided for @adminAuditDeletion.
  ///
  /// In es, this message translates to:
  /// **'Eliminación'**
  String get adminAuditDeletion;

  /// No description provided for @adminAuditSystemLabel.
  ///
  /// In es, this message translates to:
  /// **'Sistema'**
  String get adminAuditSystemLabel;

  /// No description provided for @adminMonitoringTitle.
  ///
  /// In es, this message translates to:
  /// **'Monitoreo del sistema'**
  String get adminMonitoringTitle;

  /// No description provided for @adminMonitoringSystemHealth.
  ///
  /// In es, this message translates to:
  /// **'Salud del sistema'**
  String get adminMonitoringSystemHealth;

  /// No description provided for @adminMonitoringHealthy.
  ///
  /// In es, this message translates to:
  /// **'Saludable'**
  String get adminMonitoringHealthy;

  /// No description provided for @adminMonitoringDegraded.
  ///
  /// In es, this message translates to:
  /// **'Degradado'**
  String get adminMonitoringDegraded;

  /// No description provided for @adminMonitoringDown.
  ///
  /// In es, this message translates to:
  /// **'Caído'**
  String get adminMonitoringDown;

  /// No description provided for @adminMonitoringApiLatency.
  ///
  /// In es, this message translates to:
  /// **'Latencia API'**
  String get adminMonitoringApiLatency;

  /// No description provided for @adminMonitoringDbConnections.
  ///
  /// In es, this message translates to:
  /// **'Conexiones BD'**
  String get adminMonitoringDbConnections;

  /// No description provided for @adminMonitoringActiveUsers.
  ///
  /// In es, this message translates to:
  /// **'Usuarios activos'**
  String get adminMonitoringActiveUsers;

  /// No description provided for @adminMonitoringServerLoad.
  ///
  /// In es, this message translates to:
  /// **'Carga del servidor'**
  String get adminMonitoringServerLoad;

  /// No description provided for @adminMonitoringAlerts.
  ///
  /// In es, this message translates to:
  /// **'Alertas'**
  String get adminMonitoringAlerts;

  /// No description provided for @adminMonitoringNoAlerts.
  ///
  /// In es, this message translates to:
  /// **'Sin alertas'**
  String get adminMonitoringNoAlerts;

  /// No description provided for @adminMonitoringServices.
  ///
  /// In es, this message translates to:
  /// **'Servicios'**
  String get adminMonitoringServices;

  /// No description provided for @adminMonitoringRefresh.
  ///
  /// In es, this message translates to:
  /// **'Actualizar'**
  String get adminMonitoringRefresh;

  /// No description provided for @adminMonitoringLastChecked.
  ///
  /// In es, this message translates to:
  /// **'Última comprobación: {time}'**
  String adminMonitoringLastChecked(String time);

  /// No description provided for @adminMonitoringUptime.
  ///
  /// In es, this message translates to:
  /// **'Uptime: {percent}%'**
  String adminMonitoringUptime(String percent);

  /// No description provided for @adminMonitoringErrorRate.
  ///
  /// In es, this message translates to:
  /// **'Tasa de error'**
  String get adminMonitoringErrorRate;

  /// No description provided for @adminMonitoringCpuUsage.
  ///
  /// In es, this message translates to:
  /// **'Uso de CPU'**
  String get adminMonitoringCpuUsage;

  /// No description provided for @adminMonitoringMemoryUsage.
  ///
  /// In es, this message translates to:
  /// **'Uso de memoria'**
  String get adminMonitoringMemoryUsage;

  /// No description provided for @adminMonitoringScreenTitle.
  ///
  /// In es, this message translates to:
  /// **'Monitorización'**
  String get adminMonitoringScreenTitle;

  /// No description provided for @adminMonitoringErrors.
  ///
  /// In es, this message translates to:
  /// **'Errores'**
  String get adminMonitoringErrors;

  /// No description provided for @adminMonitoringTotalLabel.
  ///
  /// In es, this message translates to:
  /// **'Total'**
  String get adminMonitoringTotalLabel;

  /// No description provided for @adminMonitoringCriticalLabel.
  ///
  /// In es, this message translates to:
  /// **'Críticos'**
  String get adminMonitoringCriticalLabel;

  /// No description provided for @adminMonitoringErrorsKpi.
  ///
  /// In es, this message translates to:
  /// **'Errores'**
  String get adminMonitoringErrorsKpi;

  /// No description provided for @adminMonitoringWarningsLabel.
  ///
  /// In es, this message translates to:
  /// **'Warnings'**
  String get adminMonitoringWarningsLabel;

  /// No description provided for @adminMonitoringErrorsBySource.
  ///
  /// In es, this message translates to:
  /// **'Errores por Fuente'**
  String get adminMonitoringErrorsBySource;

  /// No description provided for @adminMonitoringApiPerformance.
  ///
  /// In es, this message translates to:
  /// **'API / Rendimiento'**
  String get adminMonitoringApiPerformance;

  /// No description provided for @adminMonitoringRequests.
  ///
  /// In es, this message translates to:
  /// **'Peticiones'**
  String get adminMonitoringRequests;

  /// No description provided for @adminMonitoringAvgResponse.
  ///
  /// In es, this message translates to:
  /// **'Avg Response'**
  String get adminMonitoringAvgResponse;

  /// No description provided for @adminMonitoringP95Response.
  ///
  /// In es, this message translates to:
  /// **'P95 Response'**
  String get adminMonitoringP95Response;

  /// No description provided for @adminMonitoringTopEndpoints.
  ///
  /// In es, this message translates to:
  /// **'Top Endpoints'**
  String get adminMonitoringTopEndpoints;

  /// No description provided for @adminMonitoringHitsCount.
  ///
  /// In es, this message translates to:
  /// **'{count} hits'**
  String adminMonitoringHitsCount(String count);

  /// No description provided for @adminMonitoringSlowEndpoints.
  ///
  /// In es, this message translates to:
  /// **'Endpoints Lentos (>1s)'**
  String get adminMonitoringSlowEndpoints;

  /// No description provided for @adminMonitoringRecentCritical.
  ///
  /// In es, this message translates to:
  /// **'Errores Críticos Recientes'**
  String get adminMonitoringRecentCritical;

  /// No description provided for @adminMonitoringNoCritical.
  ///
  /// In es, this message translates to:
  /// **'Sin errores críticos'**
  String get adminMonitoringNoCritical;

  /// No description provided for @adminMonitoringErrorLog.
  ///
  /// In es, this message translates to:
  /// **'Log de Errores'**
  String get adminMonitoringErrorLog;

  /// No description provided for @adminMonitoringSeverity.
  ///
  /// In es, this message translates to:
  /// **'Severidad'**
  String get adminMonitoringSeverity;

  /// No description provided for @adminMonitoringAllSeverities.
  ///
  /// In es, this message translates to:
  /// **'Todas'**
  String get adminMonitoringAllSeverities;

  /// No description provided for @adminMonitoringNoErrors.
  ///
  /// In es, this message translates to:
  /// **'Sin errores registrados'**
  String get adminMonitoringNoErrors;

  /// No description provided for @restaurantDashboardTitle.
  ///
  /// In es, this message translates to:
  /// **'Dashboard'**
  String get restaurantDashboardTitle;

  /// No description provided for @restaurantDashboardTodayRevenue.
  ///
  /// In es, this message translates to:
  /// **'Ingresos de hoy'**
  String get restaurantDashboardTodayRevenue;

  /// No description provided for @restaurantDashboardActiveOrders.
  ///
  /// In es, this message translates to:
  /// **'Pedidos activos'**
  String get restaurantDashboardActiveOrders;

  /// No description provided for @restaurantDashboardOccupiedTables.
  ///
  /// In es, this message translates to:
  /// **'Mesas ocupadas'**
  String get restaurantDashboardOccupiedTables;

  /// No description provided for @restaurantDashboardTodayOrders.
  ///
  /// In es, this message translates to:
  /// **'Pedidos hoy'**
  String get restaurantDashboardTodayOrders;

  /// No description provided for @restaurantDashboardRecentOrders.
  ///
  /// In es, this message translates to:
  /// **'Pedidos recientes'**
  String get restaurantDashboardRecentOrders;

  /// No description provided for @restaurantDashboardNoOrders.
  ///
  /// In es, this message translates to:
  /// **'Sin pedidos recientes'**
  String get restaurantDashboardNoOrders;

  /// No description provided for @restaurantDashboardViewAll.
  ///
  /// In es, this message translates to:
  /// **'Ver todos'**
  String get restaurantDashboardViewAll;

  /// No description provided for @restaurantDashboardQuickActions.
  ///
  /// In es, this message translates to:
  /// **'Acciones rápidas'**
  String get restaurantDashboardQuickActions;

  /// No description provided for @restaurantDashboardNewOrder.
  ///
  /// In es, this message translates to:
  /// **'Nuevo pedido'**
  String get restaurantDashboardNewOrder;

  /// No description provided for @restaurantDashboardManageTables.
  ///
  /// In es, this message translates to:
  /// **'Gestionar mesas'**
  String get restaurantDashboardManageTables;

  /// No description provided for @restaurantDashboardViewMenu.
  ///
  /// In es, this message translates to:
  /// **'Ver menú'**
  String get restaurantDashboardViewMenu;

  /// No description provided for @restaurantDashboardKitchen.
  ///
  /// In es, this message translates to:
  /// **'Cocina'**
  String get restaurantDashboardKitchen;

  /// No description provided for @tablesTitle.
  ///
  /// In es, this message translates to:
  /// **'Mesas'**
  String get tablesTitle;

  /// No description provided for @tablesEmpty.
  ///
  /// In es, this message translates to:
  /// **'Sin mesas configuradas'**
  String get tablesEmpty;

  /// No description provided for @tablesEmptySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Configura las mesas de tu restaurante desde el editor'**
  String get tablesEmptySubtitle;

  /// No description provided for @tablesEditLayout.
  ///
  /// In es, this message translates to:
  /// **'Editar disposición'**
  String get tablesEditLayout;

  /// No description provided for @tablesFilterAll.
  ///
  /// In es, this message translates to:
  /// **'Todas'**
  String get tablesFilterAll;

  /// No description provided for @tablesFilterAvailable.
  ///
  /// In es, this message translates to:
  /// **'Disponibles'**
  String get tablesFilterAvailable;

  /// No description provided for @tablesFilterOccupied.
  ///
  /// In es, this message translates to:
  /// **'Ocupadas'**
  String get tablesFilterOccupied;

  /// No description provided for @tablesFilterReserved.
  ///
  /// In es, this message translates to:
  /// **'Reservadas'**
  String get tablesFilterReserved;

  /// No description provided for @tablesOpenSession.
  ///
  /// In es, this message translates to:
  /// **'Abrir sesión'**
  String get tablesOpenSession;

  /// No description provided for @tablesViewOrder.
  ///
  /// In es, this message translates to:
  /// **'Ver pedido'**
  String get tablesViewOrder;

  /// No description provided for @tablesCloseSession.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get tablesCloseSession;

  /// No description provided for @tablesCapacity.
  ///
  /// In es, this message translates to:
  /// **'{count} personas'**
  String tablesCapacity(int count);

  /// No description provided for @tablesZone.
  ///
  /// In es, this message translates to:
  /// **'Zona: {zone}'**
  String tablesZone(String zone);

  /// No description provided for @tableEditorTitle.
  ///
  /// In es, this message translates to:
  /// **'Editor de mesas'**
  String get tableEditorTitle;

  /// No description provided for @tableEditorNewTable.
  ///
  /// In es, this message translates to:
  /// **'Nueva mesa'**
  String get tableEditorNewTable;

  /// No description provided for @tableEditorEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Empieza a diseñar tu restaurante'**
  String get tableEditorEmptyTitle;

  /// No description provided for @tableEditorAddTable.
  ///
  /// In es, this message translates to:
  /// **'Añadir mesa'**
  String get tableEditorAddTable;

  /// No description provided for @tableEditorNumberLabel.
  ///
  /// In es, this message translates to:
  /// **'Número de mesa'**
  String get tableEditorNumberLabel;

  /// No description provided for @tableEditorNameLabel.
  ///
  /// In es, this message translates to:
  /// **'Nombre (opcional)'**
  String get tableEditorNameLabel;

  /// No description provided for @tableEditorNameHint.
  ///
  /// In es, this message translates to:
  /// **'Terraza 1'**
  String get tableEditorNameHint;

  /// No description provided for @tableEditorCapacityLabel.
  ///
  /// In es, this message translates to:
  /// **'Capacidad'**
  String get tableEditorCapacityLabel;

  /// No description provided for @tableEditorZoneLabel.
  ///
  /// In es, this message translates to:
  /// **'Zona (opcional)'**
  String get tableEditorZoneLabel;

  /// No description provided for @tableEditorZoneHint.
  ///
  /// In es, this message translates to:
  /// **'Interior, Terraza...'**
  String get tableEditorZoneHint;

  /// No description provided for @tableEditorShapeLabel.
  ///
  /// In es, this message translates to:
  /// **'Forma:'**
  String get tableEditorShapeLabel;

  /// No description provided for @tableEditorEditTitle.
  ///
  /// In es, this message translates to:
  /// **'Editar {name}'**
  String tableEditorEditTitle(String name);

  /// No description provided for @tableEditorDeleteTitle.
  ///
  /// In es, this message translates to:
  /// **'Eliminar mesa'**
  String get tableEditorDeleteTitle;

  /// No description provided for @tableEditorDeleteConfirm.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar {name}? Esta acción se puede revertir desde la base de datos.'**
  String tableEditorDeleteConfirm(String name);

  /// No description provided for @tableEditorShapeAndCapacity.
  ///
  /// In es, this message translates to:
  /// **'{shape} · {count} personas'**
  String tableEditorShapeAndCapacity(String shape, int count);

  /// No description provided for @tableStatsTitle.
  ///
  /// In es, this message translates to:
  /// **'Estadísticas de mesas'**
  String get tableStatsTitle;

  /// No description provided for @tableStatsNoData.
  ///
  /// In es, this message translates to:
  /// **'Sin datos'**
  String get tableStatsNoData;

  /// No description provided for @tableStatsTotalRevenue.
  ///
  /// In es, this message translates to:
  /// **'Ingresos totales'**
  String get tableStatsTotalRevenue;

  /// No description provided for @tableStatsSessions.
  ///
  /// In es, this message translates to:
  /// **'Sesiones'**
  String get tableStatsSessions;

  /// No description provided for @tableStatsOrders.
  ///
  /// In es, this message translates to:
  /// **'Pedidos'**
  String get tableStatsOrders;

  /// No description provided for @tableStatsAvgTicket.
  ///
  /// In es, this message translates to:
  /// **'Ticket medio'**
  String get tableStatsAvgTicket;

  /// No description provided for @tableStatsRanking.
  ///
  /// In es, this message translates to:
  /// **'Ranking por ingresos'**
  String get tableStatsRanking;

  /// No description provided for @tableStatsOrderCount.
  ///
  /// In es, this message translates to:
  /// **'{count} pedidos'**
  String tableStatsOrderCount(int count);

  /// No description provided for @tableStatsAvgGuests.
  ///
  /// In es, this message translates to:
  /// **'{avg} media'**
  String tableStatsAvgGuests(String avg);

  /// No description provided for @tableStatsTicketAvg.
  ///
  /// In es, this message translates to:
  /// **'{amount} €/ticket'**
  String tableStatsTicketAvg(String amount);

  /// No description provided for @tableHistoryTitle.
  ///
  /// In es, this message translates to:
  /// **'Historial – {name}'**
  String tableHistoryTitle(String name);

  /// No description provided for @tableHistoryEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Sin historial'**
  String get tableHistoryEmptyTitle;

  /// No description provided for @tableHistoryEmptySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay pedidos completados para esta mesa'**
  String get tableHistoryEmptySubtitle;

  /// No description provided for @tableHistorySessions.
  ///
  /// In es, this message translates to:
  /// **'Sesiones'**
  String get tableHistorySessions;

  /// No description provided for @tableHistoryRevenue.
  ///
  /// In es, this message translates to:
  /// **'Ingresos'**
  String get tableHistoryRevenue;

  /// No description provided for @tableHistoryAvgTicket.
  ///
  /// In es, this message translates to:
  /// **'Ticket medio'**
  String get tableHistoryAvgTicket;

  /// No description provided for @tableHistoryAvgDuration.
  ///
  /// In es, this message translates to:
  /// **'Duración media'**
  String get tableHistoryAvgDuration;

  /// No description provided for @ordersTitle.
  ///
  /// In es, this message translates to:
  /// **'Pedidos'**
  String get ordersTitle;

  /// No description provided for @ordersEmpty.
  ///
  /// In es, this message translates to:
  /// **'Sin pedidos'**
  String get ordersEmpty;

  /// No description provided for @ordersEmptySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Los pedidos nuevos aparecerán aquí'**
  String get ordersEmptySubtitle;

  /// No description provided for @ordersFilterAll.
  ///
  /// In es, this message translates to:
  /// **'Todos'**
  String get ordersFilterAll;

  /// No description provided for @ordersFilterPending.
  ///
  /// In es, this message translates to:
  /// **'Pendientes'**
  String get ordersFilterPending;

  /// No description provided for @ordersFilterPreparing.
  ///
  /// In es, this message translates to:
  /// **'En preparación'**
  String get ordersFilterPreparing;

  /// No description provided for @ordersFilterReady.
  ///
  /// In es, this message translates to:
  /// **'Listos'**
  String get ordersFilterReady;

  /// No description provided for @ordersFilterDelivered.
  ///
  /// In es, this message translates to:
  /// **'Entregados'**
  String get ordersFilterDelivered;

  /// No description provided for @ordersItemCountAndType.
  ///
  /// In es, this message translates to:
  /// **'{count} productos · {type}'**
  String ordersItemCountAndType(int count, String type);

  /// No description provided for @ordersTabActive.
  ///
  /// In es, this message translates to:
  /// **'Activos'**
  String get ordersTabActive;

  /// No description provided for @ordersTabInKitchen.
  ///
  /// In es, this message translates to:
  /// **'En cocina'**
  String get ordersTabInKitchen;

  /// No description provided for @ordersTabReady.
  ///
  /// In es, this message translates to:
  /// **'Listos'**
  String get ordersTabReady;

  /// No description provided for @ordersTabHistory.
  ///
  /// In es, this message translates to:
  /// **'Historial'**
  String get ordersTabHistory;

  /// No description provided for @ordersEmptyActive.
  ///
  /// In es, this message translates to:
  /// **'Sin pedidos activos'**
  String get ordersEmptyActive;

  /// No description provided for @ordersEmptyActiveSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Los nuevos pedidos aparecerán aquí'**
  String get ordersEmptyActiveSubtitle;

  /// No description provided for @ordersEmptyKitchen.
  ///
  /// In es, this message translates to:
  /// **'Cocina vacía'**
  String get ordersEmptyKitchen;

  /// No description provided for @ordersEmptyKitchenSubtitle.
  ///
  /// In es, this message translates to:
  /// **'No hay pedidos en preparación'**
  String get ordersEmptyKitchenSubtitle;

  /// No description provided for @ordersEmptyReady.
  ///
  /// In es, this message translates to:
  /// **'Sin pedidos listos'**
  String get ordersEmptyReady;

  /// No description provided for @ordersEmptyReadySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Los pedidos listos para servir aparecerán aquí'**
  String get ordersEmptyReadySubtitle;

  /// No description provided for @ordersEmptyHistory.
  ///
  /// In es, this message translates to:
  /// **'Sin historial'**
  String get ordersEmptyHistory;

  /// No description provided for @ordersEmptyHistorySubtitle.
  ///
  /// In es, this message translates to:
  /// **'El historial de pedidos se mostrará aquí'**
  String get ordersEmptyHistorySubtitle;

  /// No description provided for @tableOrderPrintTooltip.
  ///
  /// In es, this message translates to:
  /// **'Imprimir ticket'**
  String get tableOrderPrintTooltip;

  /// No description provided for @tableOrderEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Sin pedido activo'**
  String get tableOrderEmptyTitle;

  /// No description provided for @tableOrderEmptySubtitle.
  ///
  /// In es, this message translates to:
  /// **'No hay un pedido activo para esta mesa'**
  String get tableOrderEmptySubtitle;

  /// No description provided for @tableOrderProductCount.
  ///
  /// In es, this message translates to:
  /// **'Productos ({count})'**
  String tableOrderProductCount(int count);

  /// No description provided for @tableOrderAddButton.
  ///
  /// In es, this message translates to:
  /// **'Añadir'**
  String get tableOrderAddButton;

  /// No description provided for @tableOrderAddProducts.
  ///
  /// In es, this message translates to:
  /// **'Añade productos al pedido'**
  String get tableOrderAddProducts;

  /// No description provided for @tableOrderViewMenu.
  ///
  /// In es, this message translates to:
  /// **'Ver menú'**
  String get tableOrderViewMenu;

  /// No description provided for @tableOrderAddNotesHint.
  ///
  /// In es, this message translates to:
  /// **'Toca para añadir notas'**
  String get tableOrderAddNotesHint;

  /// No description provided for @tableOrderNotesTitle.
  ///
  /// In es, this message translates to:
  /// **'Notas — {name}'**
  String tableOrderNotesTitle(String name);

  /// No description provided for @quickNoteNoOnion.
  ///
  /// In es, this message translates to:
  /// **'Sin cebolla'**
  String get quickNoteNoOnion;

  /// No description provided for @quickNoteExtraCheese.
  ///
  /// In es, this message translates to:
  /// **'Extra queso'**
  String get quickNoteExtraCheese;

  /// No description provided for @quickNoteGlutenFree.
  ///
  /// In es, this message translates to:
  /// **'Sin gluten'**
  String get quickNoteGlutenFree;

  /// No description provided for @quickNoteRare.
  ///
  /// In es, this message translates to:
  /// **'Poco hecho'**
  String get quickNoteRare;

  /// No description provided for @quickNoteWellDone.
  ///
  /// In es, this message translates to:
  /// **'Muy hecho'**
  String get quickNoteWellDone;

  /// No description provided for @quickNoteNoSalt.
  ///
  /// In es, this message translates to:
  /// **'Sin sal'**
  String get quickNoteNoSalt;

  /// No description provided for @quickNoteNoSpicy.
  ///
  /// In es, this message translates to:
  /// **'Sin picante'**
  String get quickNoteNoSpicy;

  /// No description provided for @quickNoteNoDairy.
  ///
  /// In es, this message translates to:
  /// **'Sin lácteos'**
  String get quickNoteNoDairy;

  /// No description provided for @quickNoteCustomHint.
  ///
  /// In es, this message translates to:
  /// **'Nota personalizada...'**
  String get quickNoteCustomHint;

  /// No description provided for @tableOrderSaveNotes.
  ///
  /// In es, this message translates to:
  /// **'Guardar notas'**
  String get tableOrderSaveNotes;

  /// No description provided for @tableOrderSendToKitchen.
  ///
  /// In es, this message translates to:
  /// **'Enviar a cocina'**
  String get tableOrderSendToKitchen;

  /// No description provided for @tableOrderInKitchen.
  ///
  /// In es, this message translates to:
  /// **'En cocina...'**
  String get tableOrderInKitchen;

  /// No description provided for @tableOrderMarkServed.
  ///
  /// In es, this message translates to:
  /// **'Marcar servido'**
  String get tableOrderMarkServed;

  /// No description provided for @tableOrderPayment.
  ///
  /// In es, this message translates to:
  /// **'Cobrar'**
  String get tableOrderPayment;

  /// No description provided for @tableOrderPaymentDialogTitle.
  ///
  /// In es, this message translates to:
  /// **'Cobrar pedido'**
  String get tableOrderPaymentDialogTitle;

  /// No description provided for @paymentMethod.
  ///
  /// In es, this message translates to:
  /// **'Método de pago'**
  String get paymentMethod;

  /// No description provided for @paymentCash.
  ///
  /// In es, this message translates to:
  /// **'Efectivo'**
  String get paymentCash;

  /// No description provided for @paymentCard.
  ///
  /// In es, this message translates to:
  /// **'Tarjeta'**
  String get paymentCard;

  /// No description provided for @tableOrderConfirmPayment.
  ///
  /// In es, this message translates to:
  /// **'Confirmar pago'**
  String get tableOrderConfirmPayment;

  /// No description provided for @tableOrderCancelTitle.
  ///
  /// In es, this message translates to:
  /// **'Cancelar pedido'**
  String get tableOrderCancelTitle;

  /// No description provided for @orderNumberLabel.
  ///
  /// In es, this message translates to:
  /// **'Pedido #{number}'**
  String orderNumberLabel(String number);

  /// No description provided for @tableOrderCancelReason.
  ///
  /// In es, this message translates to:
  /// **'Motivo de cancelación:'**
  String get tableOrderCancelReason;

  /// No description provided for @cancelReasonClientLeaving.
  ///
  /// In es, this message translates to:
  /// **'Cliente se marcha'**
  String get cancelReasonClientLeaving;

  /// No description provided for @cancelReasonOrderError.
  ///
  /// In es, this message translates to:
  /// **'Error en el pedido'**
  String get cancelReasonOrderError;

  /// No description provided for @cancelReasonKitchenIssue.
  ///
  /// In es, this message translates to:
  /// **'Problema en cocina'**
  String get cancelReasonKitchenIssue;

  /// No description provided for @cancelReasonOutOfStock.
  ///
  /// In es, this message translates to:
  /// **'Fuera de stock'**
  String get cancelReasonOutOfStock;

  /// No description provided for @cancelReasonDuplicate.
  ///
  /// In es, this message translates to:
  /// **'Pedido duplicado'**
  String get cancelReasonDuplicate;

  /// No description provided for @cancelReasonOtherHint.
  ///
  /// In es, this message translates to:
  /// **'Otro motivo...'**
  String get cancelReasonOtherHint;

  /// No description provided for @tableOrderConfirmCancel.
  ///
  /// In es, this message translates to:
  /// **'Confirmar cancelación'**
  String get tableOrderConfirmCancel;

  /// No description provided for @tableOrderPickerTitle.
  ///
  /// In es, this message translates to:
  /// **'Añadir al pedido'**
  String get tableOrderPickerTitle;

  /// No description provided for @tableOrderPickerSearchHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar plato...'**
  String get tableOrderPickerSearchHint;

  /// No description provided for @tableOrderPickerAll.
  ///
  /// In es, this message translates to:
  /// **'Todo'**
  String get tableOrderPickerAll;

  /// No description provided for @tableOrderPickerEmpty.
  ///
  /// In es, this message translates to:
  /// **'Sin platos'**
  String get tableOrderPickerEmpty;

  /// No description provided for @tableOrderPickerEmptySubtitle.
  ///
  /// In es, this message translates to:
  /// **'No hay platos disponibles'**
  String get tableOrderPickerEmptySubtitle;

  /// No description provided for @tableOrderDefaultTitle.
  ///
  /// In es, this message translates to:
  /// **'Pedido'**
  String get tableOrderDefaultTitle;

  /// No description provided for @tableOrderItemAdded.
  ///
  /// In es, this message translates to:
  /// **'{name} añadido'**
  String tableOrderItemAdded(String name);

  /// No description provided for @tableOrderSpecialNotes.
  ///
  /// In es, this message translates to:
  /// **'Notas especiales'**
  String get tableOrderSpecialNotes;

  /// No description provided for @tableOrderAddWithPrice.
  ///
  /// In es, this message translates to:
  /// **'Añadir — €{price}'**
  String tableOrderAddWithPrice(String price);

  /// No description provided for @tableOrderWriteCustomNote.
  ///
  /// In es, this message translates to:
  /// **'Escribir nota personalizada...'**
  String get tableOrderWriteCustomNote;

  /// No description provided for @orderHistoryTitle.
  ///
  /// In es, this message translates to:
  /// **'Historial de pedidos'**
  String get orderHistoryTitle;

  /// No description provided for @orderHistoryClearFilters.
  ///
  /// In es, this message translates to:
  /// **'Limpiar filtros'**
  String get orderHistoryClearFilters;

  /// No description provided for @orderHistorySearchHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar por nº pedido o camarero...'**
  String get orderHistorySearchHint;

  /// No description provided for @orderHistoryFilterDate.
  ///
  /// In es, this message translates to:
  /// **'Fecha'**
  String get orderHistoryFilterDate;

  /// No description provided for @orderHistoryFilterWaiter.
  ///
  /// In es, this message translates to:
  /// **'Camarero'**
  String get orderHistoryFilterWaiter;

  /// No description provided for @orderHistoryFilterStatus.
  ///
  /// In es, this message translates to:
  /// **'Estado'**
  String get orderHistoryFilterStatus;

  /// No description provided for @orderHistoryEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Sin resultados'**
  String get orderHistoryEmptyTitle;

  /// No description provided for @orderHistoryEmptySubtitle.
  ///
  /// In es, this message translates to:
  /// **'No hay pedidos que coincidan con los filtros'**
  String get orderHistoryEmptySubtitle;

  /// No description provided for @orderHistorySelectWaiter.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar camarero'**
  String get orderHistorySelectWaiter;

  /// No description provided for @orderHistoryFilterByStatus.
  ///
  /// In es, this message translates to:
  /// **'Filtrar por estado'**
  String get orderHistoryFilterByStatus;

  /// No description provided for @orderHistoryFilterFrom.
  ///
  /// In es, this message translates to:
  /// **'Desde {date}'**
  String orderHistoryFilterFrom(String date);

  /// No description provided for @orderHistoryFilterTo.
  ///
  /// In es, this message translates to:
  /// **'Hasta {date}'**
  String orderHistoryFilterTo(String date);

  /// No description provided for @orderDetailWaiter.
  ///
  /// In es, this message translates to:
  /// **'Camarero: {name}'**
  String orderDetailWaiter(String name);

  /// No description provided for @orderDetailPrintTicket.
  ///
  /// In es, this message translates to:
  /// **'Imprimir ticket'**
  String get orderDetailPrintTicket;

  /// No description provided for @ticketPreviewTitle.
  ///
  /// In es, this message translates to:
  /// **'Ticket #{number}'**
  String ticketPreviewTitle(String number);

  /// No description provided for @ticketPreviewKitchenTab.
  ///
  /// In es, this message translates to:
  /// **'Cocina'**
  String get ticketPreviewKitchenTab;

  /// No description provided for @ticketPreviewClientTab.
  ///
  /// In es, this message translates to:
  /// **'Cliente'**
  String get ticketPreviewClientTab;

  /// No description provided for @ticketPreviewPrintButton.
  ///
  /// In es, this message translates to:
  /// **'Imprimir ticket de {label}'**
  String ticketPreviewPrintButton(String label);

  /// No description provided for @menuManagementTitle.
  ///
  /// In es, this message translates to:
  /// **'Menú'**
  String get menuManagementTitle;

  /// No description provided for @menuManagementSearchHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar platos...'**
  String get menuManagementSearchHint;

  /// No description provided for @menuManagementEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Menú vacío'**
  String get menuManagementEmptyTitle;

  /// No description provided for @menuManagementEmptySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Añade categorías y platos a tu menú'**
  String get menuManagementEmptySubtitle;

  /// No description provided for @menuManagementCreateCategory.
  ///
  /// In es, this message translates to:
  /// **'Crear categoría'**
  String get menuManagementCreateCategory;

  /// No description provided for @inventoryTitle.
  ///
  /// In es, this message translates to:
  /// **'Inventario'**
  String get inventoryTitle;

  /// No description provided for @inventorySearchHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar en inventario...'**
  String get inventorySearchHint;

  /// No description provided for @inventoryEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Inventario vacío'**
  String get inventoryEmptyTitle;

  /// No description provided for @inventoryEmptySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Añade tus productos e ingredientes'**
  String get inventoryEmptySubtitle;

  /// No description provided for @inventoryAddProduct.
  ///
  /// In es, this message translates to:
  /// **'Añadir producto'**
  String get inventoryAddProduct;

  /// No description provided for @inventoryEditProduct.
  ///
  /// In es, this message translates to:
  /// **'Editar producto'**
  String get inventoryEditProduct;

  /// No description provided for @inventoryName.
  ///
  /// In es, this message translates to:
  /// **'Nombre del producto'**
  String get inventoryName;

  /// No description provided for @inventoryNameHint.
  ///
  /// In es, this message translates to:
  /// **'Ej: Tomates cherry'**
  String get inventoryNameHint;

  /// No description provided for @inventoryUnit.
  ///
  /// In es, this message translates to:
  /// **'Unidad'**
  String get inventoryUnit;

  /// No description provided for @inventoryUnitHint.
  ///
  /// In es, this message translates to:
  /// **'Ej: kg, litros, unidades'**
  String get inventoryUnitHint;

  /// No description provided for @inventoryCurrentStock.
  ///
  /// In es, this message translates to:
  /// **'Stock actual'**
  String get inventoryCurrentStock;

  /// No description provided for @inventoryMinimumStock.
  ///
  /// In es, this message translates to:
  /// **'Stock mínimo'**
  String get inventoryMinimumStock;

  /// No description provided for @inventoryCostPerUnit.
  ///
  /// In es, this message translates to:
  /// **'Coste por unidad'**
  String get inventoryCostPerUnit;

  /// No description provided for @inventoryCategory.
  ///
  /// In es, this message translates to:
  /// **'Categoría'**
  String get inventoryCategory;

  /// No description provided for @inventoryCategoryHint.
  ///
  /// In es, this message translates to:
  /// **'Ej: Verduras, Carnes, Bebidas'**
  String get inventoryCategoryHint;

  /// No description provided for @inventorySupplier.
  ///
  /// In es, this message translates to:
  /// **'Proveedor'**
  String get inventorySupplier;

  /// No description provided for @inventorySupplierHint.
  ///
  /// In es, this message translates to:
  /// **'Ej: Distribuciones García'**
  String get inventorySupplierHint;

  /// No description provided for @inventoryDescription.
  ///
  /// In es, this message translates to:
  /// **'Descripción'**
  String get inventoryDescription;

  /// No description provided for @inventorySku.
  ///
  /// In es, this message translates to:
  /// **'SKU / Código'**
  String get inventorySku;

  /// No description provided for @inventoryLowStock.
  ///
  /// In es, this message translates to:
  /// **'Stock bajo'**
  String get inventoryLowStock;

  /// No description provided for @inventoryOutOfStock.
  ///
  /// In es, this message translates to:
  /// **'Agotado'**
  String get inventoryOutOfStock;

  /// No description provided for @inventoryInStock.
  ///
  /// In es, this message translates to:
  /// **'En stock'**
  String get inventoryInStock;

  /// No description provided for @inventoryItems.
  ///
  /// In es, this message translates to:
  /// **'{count} productos'**
  String inventoryItems(Object count);

  /// No description provided for @inventoryDeleteConfirm.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar este producto del inventario?'**
  String get inventoryDeleteConfirm;

  /// No description provided for @inventoryAdjustStock.
  ///
  /// In es, this message translates to:
  /// **'Ajustar stock'**
  String get inventoryAdjustStock;

  /// No description provided for @inventoryErrorCreate.
  ///
  /// In es, this message translates to:
  /// **'Error al crear producto: {error}'**
  String inventoryErrorCreate(Object error);

  /// No description provided for @kitchenTitle.
  ///
  /// In es, this message translates to:
  /// **'Cocina'**
  String get kitchenTitle;

  /// No description provided for @kitchenStatPending.
  ///
  /// In es, this message translates to:
  /// **'Pendientes'**
  String get kitchenStatPending;

  /// No description provided for @kitchenStatPreparing.
  ///
  /// In es, this message translates to:
  /// **'En preparación'**
  String get kitchenStatPreparing;

  /// No description provided for @kitchenStatReady.
  ///
  /// In es, this message translates to:
  /// **'Listos'**
  String get kitchenStatReady;

  /// No description provided for @kitchenEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Sin pedidos en cocina'**
  String get kitchenEmptyTitle;

  /// No description provided for @kitchenEmptySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Los pedidos nuevos aparecerán automáticamente'**
  String get kitchenEmptySubtitle;

  /// No description provided for @kitchenStartPreparing.
  ///
  /// In es, this message translates to:
  /// **'Empezar a preparar'**
  String get kitchenStartPreparing;

  /// No description provided for @kitchenAllReady.
  ///
  /// In es, this message translates to:
  /// **'Todo listo'**
  String get kitchenAllReady;

  /// No description provided for @kitchenReadyToServe.
  ///
  /// In es, this message translates to:
  /// **'✓ Listo para servir'**
  String get kitchenReadyToServe;

  /// No description provided for @employeesTitle.
  ///
  /// In es, this message translates to:
  /// **'Empleados'**
  String get employeesTitle;

  /// No description provided for @employeesTabTeam.
  ///
  /// In es, this message translates to:
  /// **'Equipo'**
  String get employeesTabTeam;

  /// No description provided for @employeesTabInvitations.
  ///
  /// In es, this message translates to:
  /// **'Invitaciones'**
  String get employeesTabInvitations;

  /// No description provided for @employeesInviteButton.
  ///
  /// In es, this message translates to:
  /// **'Invitar'**
  String get employeesInviteButton;

  /// No description provided for @employeesLoadError.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar empleados'**
  String get employeesLoadError;

  /// No description provided for @employeesEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Sin empleados'**
  String get employeesEmptyTitle;

  /// No description provided for @employeesEmptySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Invita a tu equipo para que puedan acceder al sistema'**
  String get employeesEmptySubtitle;

  /// No description provided for @employeesChangeRole.
  ///
  /// In es, this message translates to:
  /// **'Cambiar rol'**
  String get employeesChangeRole;

  /// No description provided for @employeesChangeRoleDialogTitle.
  ///
  /// In es, this message translates to:
  /// **'Cambiar rol'**
  String get employeesChangeRoleDialogTitle;

  /// No description provided for @employeesRemoveTitle.
  ///
  /// In es, this message translates to:
  /// **'Eliminar empleado'**
  String get employeesRemoveTitle;

  /// No description provided for @employeesRemoveConfirm.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro de que quieres eliminar a {name} del restaurante?\n\nPerderá el acceso inmediatamente.'**
  String employeesRemoveConfirm(String name);

  /// No description provided for @invitationsEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Sin invitaciones'**
  String get invitationsEmptyTitle;

  /// No description provided for @invitationsEmptySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Las invitaciones que envíes aparecerán aquí'**
  String get invitationsEmptySubtitle;

  /// No description provided for @invitationsResend.
  ///
  /// In es, this message translates to:
  /// **'Reenviar'**
  String get invitationsResend;

  /// No description provided for @invitationsCancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get invitationsCancel;

  /// No description provided for @invitationsCancelDialogTitle.
  ///
  /// In es, this message translates to:
  /// **'Cancelar invitación'**
  String get invitationsCancelDialogTitle;

  /// No description provided for @invitationsCancelConfirm.
  ///
  /// In es, this message translates to:
  /// **'¿Cancelar la invitación enviada a {email}?'**
  String invitationsCancelConfirm(String email);

  /// No description provided for @invitationsCancelButton.
  ///
  /// In es, this message translates to:
  /// **'Cancelar invitación'**
  String get invitationsCancelButton;

  /// No description provided for @invitationSent.
  ///
  /// In es, this message translates to:
  /// **'Enviada {date}'**
  String invitationSent(String date);

  /// No description provided for @invitationSentExpires.
  ///
  /// In es, this message translates to:
  /// **'Enviada {created} · Expira {expires}'**
  String invitationSentExpires(String created, String expires);

  /// No description provided for @invitationAccepted.
  ///
  /// In es, this message translates to:
  /// **'Aceptada'**
  String get invitationAccepted;

  /// No description provided for @inviteEmployeeTitle.
  ///
  /// In es, this message translates to:
  /// **'Invitar empleado'**
  String get inviteEmployeeTitle;

  /// No description provided for @inviteEmployeeSent.
  ///
  /// In es, this message translates to:
  /// **'Invitación enviada a {email}'**
  String inviteEmployeeSent(String email);

  /// No description provided for @inviteEmployeeHeading.
  ///
  /// In es, this message translates to:
  /// **'Invita a un nuevo miembro'**
  String get inviteEmployeeHeading;

  /// No description provided for @inviteEmployeeSubheading.
  ///
  /// In es, this message translates to:
  /// **'Introduce su email y elige el rol que tendrá en tu restaurante.'**
  String get inviteEmployeeSubheading;

  /// No description provided for @inviteEmployeeEmailLabel.
  ///
  /// In es, this message translates to:
  /// **'Email del empleado'**
  String get inviteEmployeeEmailLabel;

  /// No description provided for @inviteEmployeeEmailHint.
  ///
  /// In es, this message translates to:
  /// **'empleado@ejemplo.com'**
  String get inviteEmployeeEmailHint;

  /// No description provided for @inviteEmployeeRoleLabel.
  ///
  /// In es, this message translates to:
  /// **'Rol'**
  String get inviteEmployeeRoleLabel;

  /// No description provided for @roleManager.
  ///
  /// In es, this message translates to:
  /// **'Gerente'**
  String get roleManager;

  /// No description provided for @roleManagerDesc.
  ///
  /// In es, this message translates to:
  /// **'Gestiona empleados, menú, inventario y analíticas'**
  String get roleManagerDesc;

  /// No description provided for @roleWaiter.
  ///
  /// In es, this message translates to:
  /// **'Mesero'**
  String get roleWaiter;

  /// No description provided for @roleWaiterDesc.
  ///
  /// In es, this message translates to:
  /// **'Crea pedidos, gestiona mesas y atiende clientes'**
  String get roleWaiterDesc;

  /// No description provided for @roleKitchen.
  ///
  /// In es, this message translates to:
  /// **'Cocina'**
  String get roleKitchen;

  /// No description provided for @roleKitchenDesc.
  ///
  /// In es, this message translates to:
  /// **'Ve pedidos, pantalla de cocina e inventario'**
  String get roleKitchenDesc;

  /// No description provided for @roleViewer.
  ///
  /// In es, this message translates to:
  /// **'Observador'**
  String get roleViewer;

  /// No description provided for @roleViewerDesc.
  ///
  /// In es, this message translates to:
  /// **'Solo puede ver menú, pedidos y mesas'**
  String get roleViewerDesc;

  /// No description provided for @inviteEmployeeSendButton.
  ///
  /// In es, this message translates to:
  /// **'Enviar invitación'**
  String get inviteEmployeeSendButton;

  /// No description provided for @inviteEmployeeInfoNote.
  ///
  /// In es, this message translates to:
  /// **'El empleado recibirá un email con un enlace para unirse. La invitación expira en 7 días.'**
  String get inviteEmployeeInfoNote;

  /// No description provided for @restaurantAnalyticsTitle.
  ///
  /// In es, this message translates to:
  /// **'Analíticas'**
  String get restaurantAnalyticsTitle;

  /// No description provided for @restaurantAnalyticsRevenue.
  ///
  /// In es, this message translates to:
  /// **'Ingresos'**
  String get restaurantAnalyticsRevenue;

  /// No description provided for @restaurantAnalyticsCompleted.
  ///
  /// In es, this message translates to:
  /// **'{count} completados'**
  String restaurantAnalyticsCompleted(int count);

  /// No description provided for @restaurantAnalyticsOrders.
  ///
  /// In es, this message translates to:
  /// **'Pedidos'**
  String get restaurantAnalyticsOrders;

  /// No description provided for @restaurantAnalyticsCancelled.
  ///
  /// In es, this message translates to:
  /// **'{count} cancelados'**
  String restaurantAnalyticsCancelled(int count);

  /// No description provided for @restaurantAnalyticsAvgTicket.
  ///
  /// In es, this message translates to:
  /// **'Ticket medio'**
  String get restaurantAnalyticsAvgTicket;

  /// No description provided for @restaurantAnalyticsPrepTime.
  ///
  /// In es, this message translates to:
  /// **'Tiempo prep.'**
  String get restaurantAnalyticsPrepTime;

  /// No description provided for @restaurantAnalyticsOrdersByHour.
  ///
  /// In es, this message translates to:
  /// **'Pedidos por hora'**
  String get restaurantAnalyticsOrdersByHour;

  /// No description provided for @restaurantAnalyticsNoData.
  ///
  /// In es, this message translates to:
  /// **'Sin datos'**
  String get restaurantAnalyticsNoData;

  /// No description provided for @restaurantAnalyticsTopDishes.
  ///
  /// In es, this message translates to:
  /// **'Platos más vendidos'**
  String get restaurantAnalyticsTopDishes;

  /// No description provided for @periodToday.
  ///
  /// In es, this message translates to:
  /// **'Hoy'**
  String get periodToday;

  /// No description provided for @periodWeek.
  ///
  /// In es, this message translates to:
  /// **'Semana'**
  String get periodWeek;

  /// No description provided for @periodMonth.
  ///
  /// In es, this message translates to:
  /// **'Mes'**
  String get periodMonth;

  /// No description provided for @periodCustom.
  ///
  /// In es, this message translates to:
  /// **'Rango'**
  String get periodCustom;

  /// No description provided for @restaurantAnalyticsUnitsSold.
  ///
  /// In es, this message translates to:
  /// **'{count} uds'**
  String restaurantAnalyticsUnitsSold(int count);

  /// No description provided for @settingsTitle.
  ///
  /// In es, this message translates to:
  /// **'Configuración'**
  String get settingsTitle;

  /// No description provided for @settingsSectionRestaurant.
  ///
  /// In es, this message translates to:
  /// **'Restaurante'**
  String get settingsSectionRestaurant;

  /// No description provided for @settingsRestaurantData.
  ///
  /// In es, this message translates to:
  /// **'Datos del restaurante'**
  String get settingsRestaurantData;

  /// No description provided for @settingsRestaurantDataSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Nombre, dirección, horario'**
  String get settingsRestaurantDataSubtitle;

  /// No description provided for @settingsHours.
  ///
  /// In es, this message translates to:
  /// **'Horario'**
  String get settingsHours;

  /// No description provided for @settingsHoursSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Horas de apertura y cierre'**
  String get settingsHoursSubtitle;

  /// No description provided for @settingsCustomRoles.
  ///
  /// In es, this message translates to:
  /// **'Roles personalizados'**
  String get settingsCustomRoles;

  /// No description provided for @settingsCustomRolesSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Permisos por rol de equipo'**
  String get settingsCustomRolesSubtitle;

  /// No description provided for @settingsActivityLogs.
  ///
  /// In es, this message translates to:
  /// **'Registro de actividad'**
  String get settingsActivityLogs;

  /// No description provided for @settingsActivityLogsSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Historial de acciones'**
  String get settingsActivityLogsSubtitle;

  /// No description provided for @settingsAppearance.
  ///
  /// In es, this message translates to:
  /// **'Apariencia'**
  String get settingsAppearance;

  /// No description provided for @settingsAppearanceSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Logo, colores, tema'**
  String get settingsAppearanceSubtitle;

  /// No description provided for @settingsMarketplace.
  ///
  /// In es, this message translates to:
  /// **'Marketplace'**
  String get settingsMarketplace;

  /// No description provided for @settingsMarketplaceSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Visibilidad, delivery, comisiones'**
  String get settingsMarketplaceSubtitle;

  /// No description provided for @settingsSectionSystem.
  ///
  /// In es, this message translates to:
  /// **'Sistema'**
  String get settingsSectionSystem;

  /// No description provided for @settingsNotificationsSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Alertas, sonidos'**
  String get settingsNotificationsSubtitle;

  /// No description provided for @pushNotConfigured.
  ///
  /// In es, this message translates to:
  /// **'Firebase no configurado. Ejecuta flutterfire configure para habilitar push notifications.'**
  String get pushNotConfigured;

  /// No description provided for @pushEnable.
  ///
  /// In es, this message translates to:
  /// **'Notificaciones push'**
  String get pushEnable;

  /// No description provided for @pushEnableSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Recibe alertas cuando no estés en la app'**
  String get pushEnableSubtitle;

  /// No description provided for @pushCategories.
  ///
  /// In es, this message translates to:
  /// **'CATEGORÍAS'**
  String get pushCategories;

  /// No description provided for @pushOrders.
  ///
  /// In es, this message translates to:
  /// **'Pedidos'**
  String get pushOrders;

  /// No description provided for @pushOrdersSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Nuevos pedidos, actualizaciones y entregas'**
  String get pushOrdersSubtitle;

  /// No description provided for @pushReviews.
  ///
  /// In es, this message translates to:
  /// **'Reseñas'**
  String get pushReviews;

  /// No description provided for @pushReviewsSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Nuevas valoraciones de clientes'**
  String get pushReviewsSubtitle;

  /// No description provided for @pushStock.
  ///
  /// In es, this message translates to:
  /// **'Inventario'**
  String get pushStock;

  /// No description provided for @pushStockSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Alertas de stock bajo'**
  String get pushStockSubtitle;

  /// No description provided for @pushSystem.
  ///
  /// In es, this message translates to:
  /// **'Sistema'**
  String get pushSystem;

  /// No description provided for @pushSystemSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Mensajes del administrador e incidencias'**
  String get pushSystemSubtitle;

  /// No description provided for @pushFooterNote.
  ///
  /// In es, this message translates to:
  /// **'Las notificaciones push se envían a este dispositivo. Puedes desactivar categorías específicas sin perder las notificaciones dentro de la app.'**
  String get pushFooterNote;

  /// No description provided for @settingsPrinting.
  ///
  /// In es, this message translates to:
  /// **'Impresión'**
  String get settingsPrinting;

  /// No description provided for @settingsPrintingSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Tickets, impresoras'**
  String get settingsPrintingSubtitle;

  /// No description provided for @settingsPayments.
  ///
  /// In es, this message translates to:
  /// **'Pagos'**
  String get settingsPayments;

  /// No description provided for @settingsPaymentsSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Métodos de pago, propinas'**
  String get settingsPaymentsSubtitle;

  /// No description provided for @settingsSectionAccount.
  ///
  /// In es, this message translates to:
  /// **'Cuenta'**
  String get settingsSectionAccount;

  /// No description provided for @settingsMyProfile.
  ///
  /// In es, this message translates to:
  /// **'Mi perfil'**
  String get settingsMyProfile;

  /// No description provided for @settingsMyProfileSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Datos personales'**
  String get settingsMyProfileSubtitle;

  /// No description provided for @settingsSecurity.
  ///
  /// In es, this message translates to:
  /// **'Seguridad'**
  String get settingsSecurity;

  /// No description provided for @settingsSecuritySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Contraseña, sesiones'**
  String get settingsSecuritySubtitle;

  /// No description provided for @settingsSignOut.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get settingsSignOut;

  /// No description provided for @settingsSignOutSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Salir de la cuenta'**
  String get settingsSignOutSubtitle;

  /// No description provided for @settingsAppVersion.
  ///
  /// In es, this message translates to:
  /// **'LOME v1.0.0'**
  String get settingsAppVersion;

  /// No description provided for @settingsTagline.
  ///
  /// In es, this message translates to:
  /// **'Tu restaurante, simplificado'**
  String get settingsTagline;

  /// No description provided for @restaurantSettingsTitle.
  ///
  /// In es, this message translates to:
  /// **'Datos del restaurante'**
  String get restaurantSettingsTitle;

  /// No description provided for @restaurantSettingsBasicInfo.
  ///
  /// In es, this message translates to:
  /// **'Información básica'**
  String get restaurantSettingsBasicInfo;

  /// No description provided for @restaurantSettingsNameLabel.
  ///
  /// In es, this message translates to:
  /// **'Nombre del restaurante'**
  String get restaurantSettingsNameLabel;

  /// No description provided for @restaurantSettingsDescLabel.
  ///
  /// In es, this message translates to:
  /// **'Descripción'**
  String get restaurantSettingsDescLabel;

  /// No description provided for @restaurantSettingsDescHint.
  ///
  /// In es, this message translates to:
  /// **'Ej: Cocina mediterránea de autor...'**
  String get restaurantSettingsDescHint;

  /// No description provided for @restaurantSettingsContact.
  ///
  /// In es, this message translates to:
  /// **'Contacto'**
  String get restaurantSettingsContact;

  /// No description provided for @restaurantSettingsPhoneLabel.
  ///
  /// In es, this message translates to:
  /// **'Teléfono'**
  String get restaurantSettingsPhoneLabel;

  /// No description provided for @restaurantSettingsPhoneHint.
  ///
  /// In es, this message translates to:
  /// **'+34 600 000 000'**
  String get restaurantSettingsPhoneHint;

  /// No description provided for @restaurantSettingsEmailLabel.
  ///
  /// In es, this message translates to:
  /// **'Email de contacto'**
  String get restaurantSettingsEmailLabel;

  /// No description provided for @restaurantSettingsEmailHint.
  ///
  /// In es, this message translates to:
  /// **'restaurante@email.com'**
  String get restaurantSettingsEmailHint;

  /// No description provided for @restaurantSettingsWebLabel.
  ///
  /// In es, this message translates to:
  /// **'Sitio web'**
  String get restaurantSettingsWebLabel;

  /// No description provided for @restaurantSettingsWebHint.
  ///
  /// In es, this message translates to:
  /// **'https://mirestaurante.com'**
  String get restaurantSettingsWebHint;

  /// No description provided for @restaurantSettingsAddressSection.
  ///
  /// In es, this message translates to:
  /// **'Dirección'**
  String get restaurantSettingsAddressSection;

  /// No description provided for @restaurantSettingsAddressLabel.
  ///
  /// In es, this message translates to:
  /// **'Dirección'**
  String get restaurantSettingsAddressLabel;

  /// No description provided for @restaurantSettingsAddressHint.
  ///
  /// In es, this message translates to:
  /// **'Calle Principal 123'**
  String get restaurantSettingsAddressHint;

  /// No description provided for @restaurantSettingsAddress2Label.
  ///
  /// In es, this message translates to:
  /// **'Dirección (línea 2)'**
  String get restaurantSettingsAddress2Label;

  /// No description provided for @restaurantSettingsAddress2Hint.
  ///
  /// In es, this message translates to:
  /// **'Piso, local...'**
  String get restaurantSettingsAddress2Hint;

  /// No description provided for @restaurantSettingsCityLabel.
  ///
  /// In es, this message translates to:
  /// **'Ciudad'**
  String get restaurantSettingsCityLabel;

  /// No description provided for @restaurantSettingsStateLabel.
  ///
  /// In es, this message translates to:
  /// **'Provincia'**
  String get restaurantSettingsStateLabel;

  /// No description provided for @restaurantSettingsPostalLabel.
  ///
  /// In es, this message translates to:
  /// **'Código postal'**
  String get restaurantSettingsPostalLabel;

  /// No description provided for @restaurantSettingsPostalHint.
  ///
  /// In es, this message translates to:
  /// **'28001'**
  String get restaurantSettingsPostalHint;

  /// No description provided for @restaurantSettingsCuisine.
  ///
  /// In es, this message translates to:
  /// **'Tipos de cocina'**
  String get restaurantSettingsCuisine;

  /// No description provided for @restaurantSettingsChangeLogo.
  ///
  /// In es, this message translates to:
  /// **'Toca para cambiar el logo'**
  String get restaurantSettingsChangeLogo;

  /// No description provided for @cuisineMediterranean.
  ///
  /// In es, this message translates to:
  /// **'Mediterránea'**
  String get cuisineMediterranean;

  /// No description provided for @cuisineItalian.
  ///
  /// In es, this message translates to:
  /// **'Italiana'**
  String get cuisineItalian;

  /// No description provided for @cuisineJapanese.
  ///
  /// In es, this message translates to:
  /// **'Japonesa'**
  String get cuisineJapanese;

  /// No description provided for @cuisineMexican.
  ///
  /// In es, this message translates to:
  /// **'Mexicana'**
  String get cuisineMexican;

  /// No description provided for @cuisineAmerican.
  ///
  /// In es, this message translates to:
  /// **'Americana'**
  String get cuisineAmerican;

  /// No description provided for @cuisineChinese.
  ///
  /// In es, this message translates to:
  /// **'China'**
  String get cuisineChinese;

  /// No description provided for @cuisineIndian.
  ///
  /// In es, this message translates to:
  /// **'India'**
  String get cuisineIndian;

  /// No description provided for @cuisineThai.
  ///
  /// In es, this message translates to:
  /// **'Tailandesa'**
  String get cuisineThai;

  /// No description provided for @cuisineFrench.
  ///
  /// In es, this message translates to:
  /// **'Francesa'**
  String get cuisineFrench;

  /// No description provided for @cuisineSpanish.
  ///
  /// In es, this message translates to:
  /// **'Española'**
  String get cuisineSpanish;

  /// No description provided for @cuisinePeruvian.
  ///
  /// In es, this message translates to:
  /// **'Peruana'**
  String get cuisinePeruvian;

  /// No description provided for @cuisineArabic.
  ///
  /// In es, this message translates to:
  /// **'Árabe'**
  String get cuisineArabic;

  /// No description provided for @cuisineVegan.
  ///
  /// In es, this message translates to:
  /// **'Vegana'**
  String get cuisineVegan;

  /// No description provided for @cuisineFusion.
  ///
  /// In es, this message translates to:
  /// **'Fusión'**
  String get cuisineFusion;

  /// No description provided for @cuisineOther.
  ///
  /// In es, this message translates to:
  /// **'Otro'**
  String get cuisineOther;

  /// No description provided for @restaurantHoursTitle.
  ///
  /// In es, this message translates to:
  /// **'Horario de apertura'**
  String get restaurantHoursTitle;

  /// No description provided for @restaurantHoursAddSlot.
  ///
  /// In es, this message translates to:
  /// **'Añadir franja'**
  String get restaurantHoursAddSlot;

  /// No description provided for @restaurantHoursClosed.
  ///
  /// In es, this message translates to:
  /// **'Cerrado'**
  String get restaurantHoursClosed;

  /// No description provided for @restaurantHoursEditTitle.
  ///
  /// In es, this message translates to:
  /// **'Editar horario — {day}'**
  String restaurantHoursEditTitle(String day);

  /// No description provided for @restaurantHoursNewTitle.
  ///
  /// In es, this message translates to:
  /// **'Nuevo horario — {day}'**
  String restaurantHoursNewTitle(String day);

  /// No description provided for @restaurantHoursOpenLabel.
  ///
  /// In es, this message translates to:
  /// **'Apertura'**
  String get restaurantHoursOpenLabel;

  /// No description provided for @restaurantHoursCloseLabel.
  ///
  /// In es, this message translates to:
  /// **'Cierre'**
  String get restaurantHoursCloseLabel;

  /// No description provided for @restaurantHoursValidation.
  ///
  /// In es, this message translates to:
  /// **'La hora de cierre debe ser posterior a la de apertura'**
  String get restaurantHoursValidation;

  /// No description provided for @customRolesTitle.
  ///
  /// In es, this message translates to:
  /// **'Roles personalizados'**
  String get customRolesTitle;

  /// No description provided for @customRolesDeleteTitle.
  ///
  /// In es, this message translates to:
  /// **'Eliminar rol'**
  String get customRolesDeleteTitle;

  /// No description provided for @customRolesDeleteConfirm.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar el rol \"{name}\"? Los empleados asignados perderán estos permisos.'**
  String customRolesDeleteConfirm(String name);

  /// No description provided for @customRolesInactive.
  ///
  /// In es, this message translates to:
  /// **'Inactivo'**
  String get customRolesInactive;

  /// No description provided for @customRolesPermCount.
  ///
  /// In es, this message translates to:
  /// **'{count} permisos'**
  String customRolesPermCount(int count);

  /// No description provided for @customRolesEditTitle.
  ///
  /// In es, this message translates to:
  /// **'Editar rol'**
  String get customRolesEditTitle;

  /// No description provided for @customRolesNewTitle.
  ///
  /// In es, this message translates to:
  /// **'Nuevo rol'**
  String get customRolesNewTitle;

  /// No description provided for @customRolesNameLabel.
  ///
  /// In es, this message translates to:
  /// **'Nombre del rol'**
  String get customRolesNameLabel;

  /// No description provided for @customRolesNameHint.
  ///
  /// In es, this message translates to:
  /// **'Ej: Encargado de barra'**
  String get customRolesNameHint;

  /// No description provided for @customRolesDescLabel.
  ///
  /// In es, this message translates to:
  /// **'Descripción (opcional)'**
  String get customRolesDescLabel;

  /// No description provided for @customRolesDescHint.
  ///
  /// In es, this message translates to:
  /// **'Breve descripción del rol...'**
  String get customRolesDescHint;

  /// No description provided for @customRolesPermissions.
  ///
  /// In es, this message translates to:
  /// **'Permisos'**
  String get customRolesPermissions;

  /// No description provided for @customRolesMinPerm.
  ///
  /// In es, this message translates to:
  /// **'Selecciona al menos un permiso'**
  String get customRolesMinPerm;

  /// No description provided for @customRolesSaveButton.
  ///
  /// In es, this message translates to:
  /// **'Guardar cambios'**
  String get customRolesSaveButton;

  /// No description provided for @customRolesCreateButton.
  ///
  /// In es, this message translates to:
  /// **'Crear rol'**
  String get customRolesCreateButton;

  /// No description provided for @customRolesEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Sin roles personalizados'**
  String get customRolesEmptyTitle;

  /// No description provided for @customRolesEmptySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Crea roles adaptados a tu negocio con permisos específicos.'**
  String get customRolesEmptySubtitle;

  /// No description provided for @customRolesCreateFirst.
  ///
  /// In es, this message translates to:
  /// **'Crear primer rol'**
  String get customRolesCreateFirst;

  /// No description provided for @activityLogsTitle.
  ///
  /// In es, this message translates to:
  /// **'Actividad'**
  String get activityLogsTitle;

  /// No description provided for @activityLogsFilterAll.
  ///
  /// In es, this message translates to:
  /// **'Todos'**
  String get activityLogsFilterAll;

  /// No description provided for @activityLogsFilterOrders.
  ///
  /// In es, this message translates to:
  /// **'Pedidos'**
  String get activityLogsFilterOrders;

  /// No description provided for @activityLogsFilterMenu.
  ///
  /// In es, this message translates to:
  /// **'Menú'**
  String get activityLogsFilterMenu;

  /// No description provided for @activityLogsFilterInventory.
  ///
  /// In es, this message translates to:
  /// **'Inventario'**
  String get activityLogsFilterInventory;

  /// No description provided for @activityLogsFilterTables.
  ///
  /// In es, this message translates to:
  /// **'Mesas'**
  String get activityLogsFilterTables;

  /// No description provided for @activityLogsFilterTeam.
  ///
  /// In es, this message translates to:
  /// **'Equipo'**
  String get activityLogsFilterTeam;

  /// No description provided for @activityLogsFilterSettings.
  ///
  /// In es, this message translates to:
  /// **'Config.'**
  String get activityLogsFilterSettings;

  /// No description provided for @activityLogsEmpty.
  ///
  /// In es, this message translates to:
  /// **'Sin actividad registrada'**
  String get activityLogsEmpty;

  /// No description provided for @itemCount.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =0{Sin elementos} =1{1 elemento} other{{count} elementos}}'**
  String itemCount(int count);

  /// No description provided for @currency.
  ///
  /// In es, this message translates to:
  /// **'{amount}'**
  String currency(String amount);

  /// No description provided for @greeting.
  ///
  /// In es, this message translates to:
  /// **'Hola, {name}'**
  String greeting(String name);

  /// No description provided for @lastUpdated.
  ///
  /// In es, this message translates to:
  /// **'Última actualización: {date}'**
  String lastUpdated(String date);

  /// No description provided for @statusPending.
  ///
  /// In es, this message translates to:
  /// **'Pendiente'**
  String get statusPending;

  /// No description provided for @statusSuspended.
  ///
  /// In es, this message translates to:
  /// **'Suspendido'**
  String get statusSuspended;

  /// No description provided for @adminStatThisMonth.
  ///
  /// In es, this message translates to:
  /// **'{value} este mes'**
  String adminStatThisMonth(String value);

  /// No description provided for @adminStatToday.
  ///
  /// In es, this message translates to:
  /// **'{value} hoy'**
  String adminStatToday(String value);

  /// No description provided for @adminStatTotal.
  ///
  /// In es, this message translates to:
  /// **'{value} total'**
  String adminStatTotal(String value);

  /// No description provided for @adminDashboardGeneralSummary.
  ///
  /// In es, this message translates to:
  /// **'Resumen general'**
  String get adminDashboardGeneralSummary;

  /// No description provided for @adminDashboardPlatformStatus.
  ///
  /// In es, this message translates to:
  /// **'Estado actual de la plataforma LŌME'**
  String get adminDashboardPlatformStatus;

  /// No description provided for @adminDashboardUsers.
  ///
  /// In es, this message translates to:
  /// **'Usuarios'**
  String get adminDashboardUsers;

  /// No description provided for @adminDashboardActiveRegistered.
  ///
  /// In es, this message translates to:
  /// **'Registrados activos'**
  String get adminDashboardActiveRegistered;

  /// No description provided for @adminDashboardTodayOrders.
  ///
  /// In es, this message translates to:
  /// **'Pedidos hoy'**
  String get adminDashboardTodayOrders;

  /// No description provided for @adminDashboardMonthVolume.
  ///
  /// In es, this message translates to:
  /// **'Volumen mes'**
  String get adminDashboardMonthVolume;

  /// No description provided for @adminDashboardRecentRestaurants.
  ///
  /// In es, this message translates to:
  /// **'Restaurantes recientes'**
  String get adminDashboardRecentRestaurants;

  /// No description provided for @adminDashboardSystemAlerts.
  ///
  /// In es, this message translates to:
  /// **'Alertas del sistema'**
  String get adminDashboardSystemAlerts;

  /// No description provided for @adminDashboardRegisteredInfo.
  ///
  /// In es, this message translates to:
  /// **'Registrado: {date} · {orders} pedidos'**
  String adminDashboardRegisteredInfo(String date, int orders);

  /// No description provided for @adminRestaurantsOrderCount.
  ///
  /// In es, this message translates to:
  /// **'{count} pedidos'**
  String adminRestaurantsOrderCount(int count);

  /// No description provided for @adminRestaurantsViewDetail.
  ///
  /// In es, this message translates to:
  /// **'Ver detalle'**
  String get adminRestaurantsViewDetail;

  /// No description provided for @adminRestaurantsActivate.
  ///
  /// In es, this message translates to:
  /// **'Activar'**
  String get adminRestaurantsActivate;

  /// No description provided for @adminRestaurantDetailTitle.
  ///
  /// In es, this message translates to:
  /// **'Detalle restaurante'**
  String get adminRestaurantDetailTitle;

  /// No description provided for @adminRestaurantDetailNotFound.
  ///
  /// In es, this message translates to:
  /// **'Restaurante no encontrado'**
  String get adminRestaurantDetailNotFound;

  /// No description provided for @adminRestaurantDetailRegistered.
  ///
  /// In es, this message translates to:
  /// **'Registrado: {date}'**
  String adminRestaurantDetailRegistered(String date);

  /// No description provided for @adminRestaurantDetailStatsError.
  ///
  /// In es, this message translates to:
  /// **'Error cargando estadísticas'**
  String get adminRestaurantDetailStatsError;

  /// No description provided for @adminRestaurantDetailStatistics.
  ///
  /// In es, this message translates to:
  /// **'Estadísticas'**
  String get adminRestaurantDetailStatistics;

  /// No description provided for @adminRestaurantDetailTotalOrders.
  ///
  /// In es, this message translates to:
  /// **'Pedidos totales'**
  String get adminRestaurantDetailTotalOrders;

  /// No description provided for @adminRestaurantDetailEmployees.
  ///
  /// In es, this message translates to:
  /// **'Empleados'**
  String get adminRestaurantDetailEmployees;

  /// No description provided for @adminRestaurantDetailMenuItems.
  ///
  /// In es, this message translates to:
  /// **'{count} ítems menú'**
  String adminRestaurantDetailMenuItems(int count);

  /// No description provided for @adminRestaurantDetailRating.
  ///
  /// In es, this message translates to:
  /// **'Rating'**
  String get adminRestaurantDetailRating;

  /// No description provided for @adminRestaurantDetailReviewCount.
  ///
  /// In es, this message translates to:
  /// **'{count} reseñas'**
  String adminRestaurantDetailReviewCount(int count);

  /// No description provided for @adminRestaurantDetailOpenIncidents.
  ///
  /// In es, this message translates to:
  /// **'{count} incidencias abiertas'**
  String adminRestaurantDetailOpenIncidents(int count);

  /// No description provided for @adminRestaurantDetailCuisine.
  ///
  /// In es, this message translates to:
  /// **'Cocina'**
  String get adminRestaurantDetailCuisine;

  /// No description provided for @adminRestaurantDetailApproveRestaurant.
  ///
  /// In es, this message translates to:
  /// **'Aprobar restaurante'**
  String get adminRestaurantDetailApproveRestaurant;

  /// No description provided for @adminRestaurantDetailSuspendRestaurant.
  ///
  /// In es, this message translates to:
  /// **'Suspender restaurante'**
  String get adminRestaurantDetailSuspendRestaurant;

  /// No description provided for @adminRestaurantDetailReactivateRestaurant.
  ///
  /// In es, this message translates to:
  /// **'Reactivar restaurante'**
  String get adminRestaurantDetailReactivateRestaurant;

  /// No description provided for @adminRestaurantDetailStatusUpdated.
  ///
  /// In es, this message translates to:
  /// **'Estado actualizado a {status}'**
  String adminRestaurantDetailStatusUpdated(String status);

  /// No description provided for @adminAnalyticsMonthRevenue.
  ///
  /// In es, this message translates to:
  /// **'Ingresos mes'**
  String get adminAnalyticsMonthRevenue;

  /// No description provided for @adminAnalyticsMonthOrders.
  ///
  /// In es, this message translates to:
  /// **'Pedidos mes'**
  String get adminAnalyticsMonthOrders;

  /// No description provided for @adminAnalyticsActiveUsers.
  ///
  /// In es, this message translates to:
  /// **'Usuarios activos'**
  String get adminAnalyticsActiveUsers;

  /// No description provided for @adminAnalyticsAvgRating.
  ///
  /// In es, this message translates to:
  /// **'Rating medio: {rating}'**
  String adminAnalyticsAvgRating(String rating);

  /// No description provided for @adminAnalyticsPlatformMetrics.
  ///
  /// In es, this message translates to:
  /// **'Métricas de plataforma'**
  String get adminAnalyticsPlatformMetrics;

  /// No description provided for @adminAnalyticsOpenIncidents.
  ///
  /// In es, this message translates to:
  /// **'Incidencias abiertas'**
  String get adminAnalyticsOpenIncidents;

  /// No description provided for @adminAnalyticsIncidentsInProgress.
  ///
  /// In es, this message translates to:
  /// **'Incidencias en curso'**
  String get adminAnalyticsIncidentsInProgress;

  /// No description provided for @adminAnalyticsFlaggedReviews.
  ///
  /// In es, this message translates to:
  /// **'Reseñas flaggeadas'**
  String get adminAnalyticsFlaggedReviews;

  /// No description provided for @adminAnalyticsPendingRestaurants.
  ///
  /// In es, this message translates to:
  /// **'Restaurantes pendientes'**
  String get adminAnalyticsPendingRestaurants;

  /// No description provided for @adminAnalyticsSuspendedRestaurants.
  ///
  /// In es, this message translates to:
  /// **'Restaurantes suspendidos'**
  String get adminAnalyticsSuspendedRestaurants;

  /// No description provided for @adminAnalyticsNoRestaurantData.
  ///
  /// In es, this message translates to:
  /// **'Sin datos de restaurantes'**
  String get adminAnalyticsNoRestaurantData;

  /// No description provided for @adminIncidentsFilterClosed.
  ///
  /// In es, this message translates to:
  /// **'Cerradas'**
  String get adminIncidentsFilterClosed;

  /// No description provided for @adminIncidentsPriorityCritical.
  ///
  /// In es, this message translates to:
  /// **'Críticas'**
  String get adminIncidentsPriorityCritical;

  /// No description provided for @adminIncidentsPriorityHigh.
  ///
  /// In es, this message translates to:
  /// **'Altas'**
  String get adminIncidentsPriorityHigh;

  /// No description provided for @adminIncidentsPriorityMedium.
  ///
  /// In es, this message translates to:
  /// **'Medias'**
  String get adminIncidentsPriorityMedium;

  /// No description provided for @adminIncidentsPriorityLow.
  ///
  /// In es, this message translates to:
  /// **'Bajas'**
  String get adminIncidentsPriorityLow;

  /// No description provided for @adminIncidentsEmptySubtitle.
  ///
  /// In es, this message translates to:
  /// **'No se encontraron incidencias en esta categoría'**
  String get adminIncidentsEmptySubtitle;

  /// No description provided for @marketplaceHomeDelivery.
  ///
  /// In es, this message translates to:
  /// **'Delivery'**
  String get marketplaceHomeDelivery;

  /// No description provided for @marketplaceHomeClearFilters.
  ///
  /// In es, this message translates to:
  /// **'Limpiar'**
  String get marketplaceHomeClearFilters;

  /// No description provided for @marketplaceHomeResults.
  ///
  /// In es, this message translates to:
  /// **'Resultados'**
  String get marketplaceHomeResults;

  /// No description provided for @marketplaceHomePromotions.
  ///
  /// In es, this message translates to:
  /// **'Ofertas y promociones'**
  String get marketplaceHomePromotions;

  /// No description provided for @marketplaceHomeRecommended.
  ///
  /// In es, this message translates to:
  /// **'Recomendados para ti'**
  String get marketplaceHomeRecommended;

  /// No description provided for @marketplaceSearchPageHint.
  ///
  /// In es, this message translates to:
  /// **'Restaurantes, platos, cocinas...'**
  String get marketplaceSearchPageHint;

  /// No description provided for @marketplaceSearchPrompt.
  ///
  /// In es, this message translates to:
  /// **'Busca restaurantes o platos'**
  String get marketplaceSearchPrompt;

  /// No description provided for @marketplaceRestaurantNotFound.
  ///
  /// In es, this message translates to:
  /// **'Restaurante no encontrado'**
  String get marketplaceRestaurantNotFound;

  /// No description provided for @marketplaceRestaurantMenuUnavailable.
  ///
  /// In es, this message translates to:
  /// **'Menú no disponible'**
  String get marketplaceRestaurantMenuUnavailable;

  /// No description provided for @marketplaceRestaurantMenuCategoryEmpty.
  ///
  /// In es, this message translates to:
  /// **'No hay platos en esta categoría'**
  String get marketplaceRestaurantMenuCategoryEmpty;

  /// No description provided for @marketplaceRestaurantMenuViewCart.
  ///
  /// In es, this message translates to:
  /// **'Ver carrito ({count})'**
  String marketplaceRestaurantMenuViewCart(int count);

  /// No description provided for @marketplaceRestaurantMenuOffers.
  ///
  /// In es, this message translates to:
  /// **'Ofertas disponibles'**
  String get marketplaceRestaurantMenuOffers;

  /// No description provided for @marketplaceRestaurantMenuReviewsCount.
  ///
  /// In es, this message translates to:
  /// **'Valoraciones ({count})'**
  String marketplaceRestaurantMenuReviewsCount(int count);

  /// No description provided for @marketplaceRestaurantMenuNotesHint.
  ///
  /// In es, this message translates to:
  /// **'Notas (sin cebolla, extra salsa...)'**
  String get marketplaceRestaurantMenuNotesHint;

  /// No description provided for @marketplaceRestaurantMenuAddedToCart.
  ///
  /// In es, this message translates to:
  /// **'{name} añadido al carrito'**
  String marketplaceRestaurantMenuAddedToCart(String name);

  /// No description provided for @marketplaceRestaurantMenuAddPriceButton.
  ///
  /// In es, this message translates to:
  /// **'Añadir · €{price}'**
  String marketplaceRestaurantMenuAddPriceButton(String price);

  /// No description provided for @marketplaceRestaurantMenuMinOrder.
  ///
  /// In es, this message translates to:
  /// **'Mín. €{amount}'**
  String marketplaceRestaurantMenuMinOrder(String amount);

  /// No description provided for @marketplaceRestaurantMenuPromotionUntil.
  ///
  /// In es, this message translates to:
  /// **'Hasta {date}'**
  String marketplaceRestaurantMenuPromotionUntil(String date);

  /// No description provided for @marketplaceCartTitle.
  ///
  /// In es, this message translates to:
  /// **'Mi carrito'**
  String get marketplaceCartTitle;

  /// No description provided for @marketplaceCartClearConfirm.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar todos los platos del carrito?'**
  String get marketplaceCartClearConfirm;

  /// No description provided for @marketplaceCartClearButton.
  ///
  /// In es, this message translates to:
  /// **'Vaciar'**
  String get marketplaceCartClearButton;

  /// No description provided for @marketplaceCartSubtotalAmount.
  ///
  /// In es, this message translates to:
  /// **'Subtotal: €{amount}'**
  String marketplaceCartSubtotalAmount(String amount);

  /// No description provided for @marketplaceCartCheckout.
  ///
  /// In es, this message translates to:
  /// **'Tramitar pedido'**
  String get marketplaceCartCheckout;

  /// No description provided for @marketplaceCheckoutStepAddress.
  ///
  /// In es, this message translates to:
  /// **'Dirección'**
  String get marketplaceCheckoutStepAddress;

  /// No description provided for @marketplaceCheckoutStepPayment.
  ///
  /// In es, this message translates to:
  /// **'Pago'**
  String get marketplaceCheckoutStepPayment;

  /// No description provided for @marketplaceCheckoutStepConfirm.
  ///
  /// In es, this message translates to:
  /// **'Confirmar'**
  String get marketplaceCheckoutStepConfirm;

  /// No description provided for @marketplaceCheckoutNoAddresses.
  ///
  /// In es, this message translates to:
  /// **'No tienes direcciones guardadas'**
  String get marketplaceCheckoutNoAddresses;

  /// No description provided for @marketplaceCheckoutNewAddress.
  ///
  /// In es, this message translates to:
  /// **'Nueva dirección'**
  String get marketplaceCheckoutNewAddress;

  /// No description provided for @marketplaceCheckoutLabelField.
  ///
  /// In es, this message translates to:
  /// **'Etiqueta'**
  String get marketplaceCheckoutLabelField;

  /// No description provided for @marketplaceCheckoutLabelHint.
  ///
  /// In es, this message translates to:
  /// **'Casa, Trabajo...'**
  String get marketplaceCheckoutLabelHint;

  /// No description provided for @marketplaceCheckoutAddressField.
  ///
  /// In es, this message translates to:
  /// **'Dirección'**
  String get marketplaceCheckoutAddressField;

  /// No description provided for @marketplaceCheckoutAddressHint.
  ///
  /// In es, this message translates to:
  /// **'Calle, número, piso...'**
  String get marketplaceCheckoutAddressHint;

  /// No description provided for @marketplaceCheckoutPostalCode.
  ///
  /// In es, this message translates to:
  /// **'Código postal'**
  String get marketplaceCheckoutPostalCode;

  /// No description provided for @marketplaceCheckoutCity.
  ///
  /// In es, this message translates to:
  /// **'Ciudad'**
  String get marketplaceCheckoutCity;

  /// No description provided for @marketplaceCheckoutCityHint.
  ///
  /// In es, this message translates to:
  /// **'Madrid'**
  String get marketplaceCheckoutCityHint;

  /// No description provided for @marketplaceCheckoutInstructions.
  ///
  /// In es, this message translates to:
  /// **'Instrucciones (opcional)'**
  String get marketplaceCheckoutInstructions;

  /// No description provided for @marketplaceCheckoutInstructionsHint.
  ///
  /// In es, this message translates to:
  /// **'Portero, timbre, etc.'**
  String get marketplaceCheckoutInstructionsHint;

  /// No description provided for @marketplaceCheckoutDeliveryNotes.
  ///
  /// In es, this message translates to:
  /// **'Notas de entrega (opcional)'**
  String get marketplaceCheckoutDeliveryNotes;

  /// No description provided for @marketplaceCheckoutDeliveryNotesHint.
  ///
  /// In es, this message translates to:
  /// **'Instrucciones para el repartidor...'**
  String get marketplaceCheckoutDeliveryNotesHint;

  /// No description provided for @marketplaceCheckoutFillRequired.
  ///
  /// In es, this message translates to:
  /// **'Rellena los campos obligatorios'**
  String get marketplaceCheckoutFillRequired;

  /// No description provided for @marketplaceCheckoutSelectPayment.
  ///
  /// In es, this message translates to:
  /// **'Selecciona cómo pagar'**
  String get marketplaceCheckoutSelectPayment;

  /// No description provided for @marketplaceCheckoutPaymentCashInfo.
  ///
  /// In es, this message translates to:
  /// **'Pagarás al recibir tu pedido.'**
  String get marketplaceCheckoutPaymentCashInfo;

  /// No description provided for @marketplaceCheckoutPaymentCardInfo.
  ///
  /// In es, this message translates to:
  /// **'Tu tarjeta se cargará al confirmar.'**
  String get marketplaceCheckoutPaymentCardInfo;

  /// No description provided for @marketplaceCheckoutPaymentOnlineInfo.
  ///
  /// In es, this message translates to:
  /// **'Serás redirigido para completar el pago.'**
  String get marketplaceCheckoutPaymentOnlineInfo;

  /// No description provided for @marketplaceCheckoutPaymentSelectInfo.
  ///
  /// In es, this message translates to:
  /// **'Selecciona un método de pago para continuar.'**
  String get marketplaceCheckoutPaymentSelectInfo;

  /// No description provided for @marketplaceCheckoutPaymentCardSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Visa, Mastercard, etc.'**
  String get marketplaceCheckoutPaymentCardSubtitle;

  /// No description provided for @marketplaceCheckoutPaymentOnlineSubtitle.
  ///
  /// In es, this message translates to:
  /// **'PayPal, Bizum, etc.'**
  String get marketplaceCheckoutPaymentOnlineSubtitle;

  /// No description provided for @marketplaceCheckoutPaymentCashSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Paga al recibir tu pedido'**
  String get marketplaceCheckoutPaymentCashSubtitle;

  /// No description provided for @marketplaceCheckoutDeliveryTo.
  ///
  /// In es, this message translates to:
  /// **'Entrega en'**
  String get marketplaceCheckoutDeliveryTo;

  /// No description provided for @marketplaceCheckoutPaymentSummaryLabel.
  ///
  /// In es, this message translates to:
  /// **'Pago'**
  String get marketplaceCheckoutPaymentSummaryLabel;

  /// No description provided for @marketplaceCheckoutVat.
  ///
  /// In es, this message translates to:
  /// **'IVA (10%)'**
  String get marketplaceCheckoutVat;

  /// No description provided for @marketplaceCheckoutOrderPlaced.
  ///
  /// In es, this message translates to:
  /// **'¡Pedido realizado!'**
  String get marketplaceCheckoutOrderPlaced;

  /// No description provided for @marketplaceCheckoutOrderOnItsWay.
  ///
  /// In es, this message translates to:
  /// **'Tu pedido está en camino'**
  String get marketplaceCheckoutOrderOnItsWay;

  /// No description provided for @marketplaceCheckoutBackToHome.
  ///
  /// In es, this message translates to:
  /// **'Volver al inicio'**
  String get marketplaceCheckoutBackToHome;

  /// No description provided for @marketplaceCheckoutConfirmWithTotal.
  ///
  /// In es, this message translates to:
  /// **'Confirmar pedido · €{amount}'**
  String marketplaceCheckoutConfirmWithTotal(String amount);

  /// No description provided for @marketplaceCheckoutContinue.
  ///
  /// In es, this message translates to:
  /// **'Continuar'**
  String get marketplaceCheckoutContinue;

  /// No description provided for @marketplaceCheckoutErrorLoadingAddresses.
  ///
  /// In es, this message translates to:
  /// **'Error cargando direcciones: {error}'**
  String marketplaceCheckoutErrorLoadingAddresses(String error);

  /// No description provided for @marketplaceCheckoutAddressDefaultBadge.
  ///
  /// In es, this message translates to:
  /// **'Predeterminada'**
  String get marketplaceCheckoutAddressDefaultBadge;

  /// No description provided for @marketplaceOrderTrackingScreenTitle.
  ///
  /// In es, this message translates to:
  /// **'Seguimiento'**
  String get marketplaceOrderTrackingScreenTitle;

  /// No description provided for @marketplaceOrderTrackingNotFound.
  ///
  /// In es, this message translates to:
  /// **'Pedido no encontrado'**
  String get marketplaceOrderTrackingNotFound;

  /// No description provided for @marketplaceOrderTrackingStatus.
  ///
  /// In es, this message translates to:
  /// **'Estado del pedido'**
  String get marketplaceOrderTrackingStatus;

  /// No description provided for @marketplaceOrderTrackingDetailsTitle.
  ///
  /// In es, this message translates to:
  /// **'Detalle del pedido'**
  String get marketplaceOrderTrackingDetailsTitle;

  /// No description provided for @marketplaceOrderTrackingStepReceived.
  ///
  /// In es, this message translates to:
  /// **'Pedido recibido'**
  String get marketplaceOrderTrackingStepReceived;

  /// No description provided for @marketplaceOrderTrackingStepReceivedSub.
  ///
  /// In es, this message translates to:
  /// **'Tu pedido ha sido registrado'**
  String get marketplaceOrderTrackingStepReceivedSub;

  /// No description provided for @marketplaceOrderTrackingStepPreparing.
  ///
  /// In es, this message translates to:
  /// **'En preparación'**
  String get marketplaceOrderTrackingStepPreparing;

  /// No description provided for @marketplaceOrderTrackingStepPreparingSub.
  ///
  /// In es, this message translates to:
  /// **'El restaurante prepara tu pedido'**
  String get marketplaceOrderTrackingStepPreparingSub;

  /// No description provided for @marketplaceOrderTrackingStepReady.
  ///
  /// In es, this message translates to:
  /// **'Listo'**
  String get marketplaceOrderTrackingStepReady;

  /// No description provided for @marketplaceOrderTrackingStepReadySub.
  ///
  /// In es, this message translates to:
  /// **'Tu pedido está listo para enviar'**
  String get marketplaceOrderTrackingStepReadySub;

  /// No description provided for @marketplaceOrderTrackingStepOnTheWay.
  ///
  /// In es, this message translates to:
  /// **'En camino'**
  String get marketplaceOrderTrackingStepOnTheWay;

  /// No description provided for @marketplaceOrderTrackingStepOnTheWaySub.
  ///
  /// In es, this message translates to:
  /// **'Tu pedido va hacia ti'**
  String get marketplaceOrderTrackingStepOnTheWaySub;

  /// No description provided for @marketplaceOrderTrackingStepDelivered.
  ///
  /// In es, this message translates to:
  /// **'Entregado'**
  String get marketplaceOrderTrackingStepDelivered;

  /// No description provided for @marketplaceOrderTrackingStepDeliveredSub.
  ///
  /// In es, this message translates to:
  /// **'¡Disfruta tu comida!'**
  String get marketplaceOrderTrackingStepDeliveredSub;

  /// No description provided for @marketplaceOrderTrackingCancelledTitle.
  ///
  /// In es, this message translates to:
  /// **'Pedido cancelado'**
  String get marketplaceOrderTrackingCancelledTitle;

  /// No description provided for @marketplaceOrderTrackingReviewTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Cómo fue tu experiencia?'**
  String get marketplaceOrderTrackingReviewTitle;

  /// No description provided for @marketplaceOrderTrackingReviewHint.
  ///
  /// In es, this message translates to:
  /// **'Cuéntanos más (opcional)'**
  String get marketplaceOrderTrackingReviewHint;

  /// No description provided for @marketplaceOrderTrackingReviewSubmit.
  ///
  /// In es, this message translates to:
  /// **'Enviar valoración'**
  String get marketplaceOrderTrackingReviewSubmit;

  /// No description provided for @marketplaceOrderTrackingReviewThanks.
  ///
  /// In es, this message translates to:
  /// **'¡Gracias por tu valoración!'**
  String get marketplaceOrderTrackingReviewThanks;

  /// No description provided for @marketplaceOrderTrackingReviewSent.
  ///
  /// In es, this message translates to:
  /// **'¡Valoración enviada!'**
  String get marketplaceOrderTrackingReviewSent;

  /// No description provided for @marketplaceOrderTrackingReviewError.
  ///
  /// In es, this message translates to:
  /// **'Error al enviar: {error}'**
  String marketplaceOrderTrackingReviewError(String error);

  /// No description provided for @marketplaceOrderTrackingVat.
  ///
  /// In es, this message translates to:
  /// **'IVA'**
  String get marketplaceOrderTrackingVat;

  /// No description provided for @marketplaceOrderTrackingDeliveryFee.
  ///
  /// In es, this message translates to:
  /// **'Envío'**
  String get marketplaceOrderTrackingDeliveryFee;

  /// No description provided for @marketplaceOrderTrackingPaymentUndefined.
  ///
  /// In es, this message translates to:
  /// **'Sin definir'**
  String get marketplaceOrderTrackingPaymentUndefined;

  /// No description provided for @marketplaceOrderTrackingPaidLabel.
  ///
  /// In es, this message translates to:
  /// **'Pagado'**
  String get marketplaceOrderTrackingPaidLabel;

  /// No description provided for @marketplaceOrderTrackingPendingPayment.
  ///
  /// In es, this message translates to:
  /// **'Pendiente de pago'**
  String get marketplaceOrderTrackingPendingPayment;

  /// No description provided for @marketplaceCustomerOrdersSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Aquí verás el historial de tus pedidos'**
  String get marketplaceCustomerOrdersSubtitle;

  /// No description provided for @marketplaceCustomerOrdersMoreItems.
  ///
  /// In es, this message translates to:
  /// **'+{count} más'**
  String marketplaceCustomerOrdersMoreItems(int count);

  /// No description provided for @marketplaceCustomerOrdersDefaultRestaurant.
  ///
  /// In es, this message translates to:
  /// **'Restaurante'**
  String get marketplaceCustomerOrdersDefaultRestaurant;

  /// No description provided for @marketplaceFavoritesTitle.
  ///
  /// In es, this message translates to:
  /// **'Mis favoritos'**
  String get marketplaceFavoritesTitle;

  /// No description provided for @marketplaceProfileTitle.
  ///
  /// In es, this message translates to:
  /// **'Mi perfil'**
  String get marketplaceProfileTitle;

  /// No description provided for @marketplaceProfileUser.
  ///
  /// In es, this message translates to:
  /// **'Usuario'**
  String get marketplaceProfileUser;

  /// No description provided for @checkoutAddressHome.
  ///
  /// In es, this message translates to:
  /// **'Casa'**
  String get checkoutAddressHome;

  /// No description provided for @checkoutAddressWork.
  ///
  /// In es, this message translates to:
  /// **'Trabajo'**
  String get checkoutAddressWork;

  /// No description provided for @dashboardAlerts.
  ///
  /// In es, this message translates to:
  /// **'Alertas'**
  String get dashboardAlerts;

  /// No description provided for @dashboardTopSellingToday.
  ///
  /// In es, this message translates to:
  /// **'Más vendidos hoy'**
  String get dashboardTopSellingToday;

  /// No description provided for @dashboardLowStock.
  ///
  /// In es, this message translates to:
  /// **'Stock bajo'**
  String get dashboardLowStock;

  /// No description provided for @dashboardPendingCount.
  ///
  /// In es, this message translates to:
  /// **'{count} pendientes'**
  String dashboardPendingCount(int count);

  /// No description provided for @dashboardOccupancyPercent.
  ///
  /// In es, this message translates to:
  /// **'{percent}% ocupación'**
  String dashboardOccupancyPercent(String percent);

  /// No description provided for @dashboardAllOk.
  ///
  /// In es, this message translates to:
  /// **'Todo OK'**
  String get dashboardAllOk;

  /// No description provided for @dashboardIngredients.
  ///
  /// In es, this message translates to:
  /// **'ingredientes'**
  String get dashboardIngredients;

  /// No description provided for @dashboardEmployees.
  ///
  /// In es, this message translates to:
  /// **'Empleados'**
  String get dashboardEmployees;

  /// No description provided for @dashboardInvite.
  ///
  /// In es, this message translates to:
  /// **'Invitar'**
  String get dashboardInvite;

  /// No description provided for @tablesStatusFree.
  ///
  /// In es, this message translates to:
  /// **'Libre'**
  String get tablesStatusFree;

  /// No description provided for @tablesStatusWaitingFood.
  ///
  /// In es, this message translates to:
  /// **'Esperando comida'**
  String get tablesStatusWaitingFood;

  /// No description provided for @tablesStatusWaitingPayment.
  ///
  /// In es, this message translates to:
  /// **'Esperando pago'**
  String get tablesStatusWaitingPayment;

  /// No description provided for @tablesStatusMaintenance.
  ///
  /// In es, this message translates to:
  /// **'Mantenimiento'**
  String get tablesStatusMaintenance;

  /// No description provided for @tablesOpenEditor.
  ///
  /// In es, this message translates to:
  /// **'Abrir editor'**
  String get tablesOpenEditor;

  /// No description provided for @tablesWaiter.
  ///
  /// In es, this message translates to:
  /// **'Camarero'**
  String get tablesWaiter;

  /// No description provided for @tablesHistory.
  ///
  /// In es, this message translates to:
  /// **'Historial'**
  String get tablesHistory;

  /// No description provided for @tablesOpenTable.
  ///
  /// In es, this message translates to:
  /// **'Abrir mesa'**
  String get tablesOpenTable;

  /// No description provided for @tablesReserveTable.
  ///
  /// In es, this message translates to:
  /// **'Reservar mesa'**
  String get tablesReserveTable;

  /// No description provided for @tablesClientArrived.
  ///
  /// In es, this message translates to:
  /// **'Cliente llegó'**
  String get tablesClientArrived;

  /// No description provided for @tablesCancelReservation.
  ///
  /// In es, this message translates to:
  /// **'Cancelar reserva'**
  String get tablesCancelReservation;

  /// No description provided for @tablesChangeStatus.
  ///
  /// In es, this message translates to:
  /// **'Cambiar estado'**
  String get tablesChangeStatus;

  /// No description provided for @tablesGuestCountTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Cuántos comensales?'**
  String get tablesGuestCountTitle;

  /// No description provided for @tablesAssignedWaiter.
  ///
  /// In es, this message translates to:
  /// **'Camarero asignado'**
  String get tablesAssignedWaiter;

  /// No description provided for @tablesErrorOpenTable.
  ///
  /// In es, this message translates to:
  /// **'Error al abrir mesa: {error}'**
  String tablesErrorOpenTable(String error);

  /// No description provided for @tablesTableSingular.
  ///
  /// In es, this message translates to:
  /// **'Mesa'**
  String get tablesTableSingular;

  /// No description provided for @tablesStatistics.
  ///
  /// In es, this message translates to:
  /// **'Estadísticas'**
  String get tablesStatistics;

  /// No description provided for @roleOwner.
  ///
  /// In es, this message translates to:
  /// **'Propietario'**
  String get roleOwner;

  /// No description provided for @invitationStatusExpired.
  ///
  /// In es, this message translates to:
  /// **'Expirada'**
  String get invitationStatusExpired;

  /// No description provided for @invitationStatusPending.
  ///
  /// In es, this message translates to:
  /// **'Pendiente'**
  String get invitationStatusPending;

  /// No description provided for @invitationStatusRejected.
  ///
  /// In es, this message translates to:
  /// **'Rechazada'**
  String get invitationStatusRejected;

  /// No description provided for @invitationStatusCancelled.
  ///
  /// In es, this message translates to:
  /// **'Cancelada'**
  String get invitationStatusCancelled;

  /// No description provided for @invitationAcceptedDate.
  ///
  /// In es, this message translates to:
  /// **'Aceptada {date}'**
  String invitationAcceptedDate(String date);

  /// No description provided for @timeInDays.
  ///
  /// In es, this message translates to:
  /// **'en {count}d'**
  String timeInDays(int count);

  /// No description provided for @timeInHours.
  ///
  /// In es, this message translates to:
  /// **'en {count}h'**
  String timeInHours(int count);

  /// No description provided for @timeInMinutes.
  ///
  /// In es, this message translates to:
  /// **'en {count}min'**
  String timeInMinutes(int count);

  /// No description provided for @timeAgoDays.
  ///
  /// In es, this message translates to:
  /// **'hace {count}d'**
  String timeAgoDays(int count);

  /// No description provided for @timeAgoHours.
  ///
  /// In es, this message translates to:
  /// **'hace {count}h'**
  String timeAgoHours(int count);

  /// No description provided for @timeAgoMinutes.
  ///
  /// In es, this message translates to:
  /// **'hace {count}min'**
  String timeAgoMinutes(int count);

  /// No description provided for @timeNow.
  ///
  /// In es, this message translates to:
  /// **'ahora'**
  String get timeNow;

  /// No description provided for @editProfileNewPasswordDesc.
  ///
  /// In es, this message translates to:
  /// **'Establece una nueva contraseña para tu cuenta.'**
  String get editProfileNewPasswordDesc;

  /// No description provided for @editProfileDangerZone.
  ///
  /// In es, this message translates to:
  /// **'Zona de peligro'**
  String get editProfileDangerZone;

  /// No description provided for @editProfileDangerZoneDesc.
  ///
  /// In es, this message translates to:
  /// **'Eliminar tu cuenta es una acción irreversible. Todos tus datos personales serán anonimizados y no podrás recuperar el acceso.'**
  String get editProfileDangerZoneDesc;

  /// No description provided for @editProfileDeleteMyAccount.
  ///
  /// In es, this message translates to:
  /// **'Eliminar mi cuenta'**
  String get editProfileDeleteMyAccount;

  /// No description provided for @editProfileDeleteDialogDesc.
  ///
  /// In es, this message translates to:
  /// **'Esta acción eliminará permanentemente tu cuenta y anonimizará todos tus datos personales.'**
  String get editProfileDeleteDialogDesc;

  /// No description provided for @editProfileDeleteTypePrefix.
  ///
  /// In es, this message translates to:
  /// **'Escribe '**
  String get editProfileDeleteTypePrefix;

  /// No description provided for @editProfileDeleteTypeSuffix.
  ///
  /// In es, this message translates to:
  /// **' para confirmar:'**
  String get editProfileDeleteTypeSuffix;

  /// No description provided for @editProfilePhotoChangeShort.
  ///
  /// In es, this message translates to:
  /// **'Cambiar foto'**
  String get editProfilePhotoChangeShort;

  /// No description provided for @editProfileConfirmPasswordHint.
  ///
  /// In es, this message translates to:
  /// **'Repite la contraseña'**
  String get editProfileConfirmPasswordHint;

  /// No description provided for @shellMonitor.
  ///
  /// In es, this message translates to:
  /// **'Monitor'**
  String get shellMonitor;

  /// No description provided for @kitchen.
  ///
  /// In es, this message translates to:
  /// **'Cocina'**
  String get kitchen;

  /// No description provided for @inventory.
  ///
  /// In es, this message translates to:
  /// **'Inventario'**
  String get inventory;

  /// No description provided for @menuCategoriesTab.
  ///
  /// In es, this message translates to:
  /// **'Categorías'**
  String get menuCategoriesTab;

  /// No description provided for @menuItemsTab.
  ///
  /// In es, this message translates to:
  /// **'Platos'**
  String get menuItemsTab;

  /// No description provided for @menuCreateCategory.
  ///
  /// In es, this message translates to:
  /// **'Crear categoría'**
  String get menuCreateCategory;

  /// No description provided for @menuEditCategory.
  ///
  /// In es, this message translates to:
  /// **'Editar categoría'**
  String get menuEditCategory;

  /// No description provided for @menuCategoryName.
  ///
  /// In es, this message translates to:
  /// **'Nombre de la categoría'**
  String get menuCategoryName;

  /// No description provided for @menuCategoryNameRequired.
  ///
  /// In es, this message translates to:
  /// **'El nombre es obligatorio'**
  String get menuCategoryNameRequired;

  /// No description provided for @menuCategoryDescription.
  ///
  /// In es, this message translates to:
  /// **'Descripción'**
  String get menuCategoryDescription;

  /// No description provided for @menuCreateItem.
  ///
  /// In es, this message translates to:
  /// **'Crear plato'**
  String get menuCreateItem;

  /// No description provided for @menuEditItem.
  ///
  /// In es, this message translates to:
  /// **'Editar plato'**
  String get menuEditItem;

  /// No description provided for @menuItemName.
  ///
  /// In es, this message translates to:
  /// **'Nombre del plato'**
  String get menuItemName;

  /// No description provided for @menuItemNameRequired.
  ///
  /// In es, this message translates to:
  /// **'El nombre es obligatorio'**
  String get menuItemNameRequired;

  /// No description provided for @menuItemPrice.
  ///
  /// In es, this message translates to:
  /// **'Precio (€)'**
  String get menuItemPrice;

  /// No description provided for @menuItemPriceRequired.
  ///
  /// In es, this message translates to:
  /// **'El precio es obligatorio'**
  String get menuItemPriceRequired;

  /// No description provided for @menuItemCategory.
  ///
  /// In es, this message translates to:
  /// **'Categoría'**
  String get menuItemCategory;

  /// No description provided for @menuItemDescription.
  ///
  /// In es, this message translates to:
  /// **'Descripción'**
  String get menuItemDescription;

  /// No description provided for @menuItemPrepTime.
  ///
  /// In es, this message translates to:
  /// **'Tiempo de preparación (min)'**
  String get menuItemPrepTime;

  /// No description provided for @menuItemImage.
  ///
  /// In es, this message translates to:
  /// **'Imagen del plato'**
  String get menuItemImage;

  /// No description provided for @menuItemImageHint.
  ///
  /// In es, this message translates to:
  /// **'Toca para añadir una foto'**
  String get menuItemImageHint;

  /// No description provided for @menuItemImageChange.
  ///
  /// In es, this message translates to:
  /// **'Cambiar imagen'**
  String get menuItemImageChange;

  /// No description provided for @menuItemImageRemove.
  ///
  /// In es, this message translates to:
  /// **'Eliminar imagen'**
  String get menuItemImageRemove;

  /// No description provided for @menuItemImageError.
  ///
  /// In es, this message translates to:
  /// **'Error al subir la imagen'**
  String get menuItemImageError;

  /// No description provided for @menuAllergens.
  ///
  /// In es, this message translates to:
  /// **'Alérgenos (separados por coma)'**
  String get menuAllergens;

  /// No description provided for @menuTags.
  ///
  /// In es, this message translates to:
  /// **'Etiquetas (separadas por coma)'**
  String get menuTags;

  /// No description provided for @menuFeatured.
  ///
  /// In es, this message translates to:
  /// **'Destacado'**
  String get menuFeatured;

  /// No description provided for @menuDeleteConfirm.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get menuDeleteConfirm;

  /// No description provided for @menuDeleteCategoryConfirm.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro de que quieres eliminar esta categoría? Los platos asociados perderán su categoría.'**
  String get menuDeleteCategoryConfirm;

  /// No description provided for @menuAllCategories.
  ///
  /// In es, this message translates to:
  /// **'Todas'**
  String get menuAllCategories;

  /// No description provided for @menuAvailable.
  ///
  /// In es, this message translates to:
  /// **'Disponible'**
  String get menuAvailable;

  /// No description provided for @menuUnavailable.
  ///
  /// In es, this message translates to:
  /// **'No disponible'**
  String get menuUnavailable;

  /// No description provided for @invTemplTitle.
  ///
  /// In es, this message translates to:
  /// **'Plantilla de invitación'**
  String get invTemplTitle;

  /// No description provided for @invTemplPresets.
  ///
  /// In es, this message translates to:
  /// **'Plantillas predeterminadas'**
  String get invTemplPresets;

  /// No description provided for @invTemplPreview.
  ///
  /// In es, this message translates to:
  /// **'Vista previa'**
  String get invTemplPreview;

  /// No description provided for @invTemplColors.
  ///
  /// In es, this message translates to:
  /// **'Colores'**
  String get invTemplColors;

  /// No description provided for @invTemplTexts.
  ///
  /// In es, this message translates to:
  /// **'Textos personalizados'**
  String get invTemplTexts;

  /// No description provided for @invTemplDisplayOptions.
  ///
  /// In es, this message translates to:
  /// **'Opciones de visualización'**
  String get invTemplDisplayOptions;

  /// No description provided for @invTemplPrimaryColor.
  ///
  /// In es, this message translates to:
  /// **'Color principal'**
  String get invTemplPrimaryColor;

  /// No description provided for @invTemplSecondaryColor.
  ///
  /// In es, this message translates to:
  /// **'Color secundario'**
  String get invTemplSecondaryColor;

  /// No description provided for @invTemplButtonColor.
  ///
  /// In es, this message translates to:
  /// **'Color del botón'**
  String get invTemplButtonColor;

  /// No description provided for @invTemplAccentColor.
  ///
  /// In es, this message translates to:
  /// **'Color de acento'**
  String get invTemplAccentColor;

  /// No description provided for @invTemplBgColor.
  ///
  /// In es, this message translates to:
  /// **'Color de fondo'**
  String get invTemplBgColor;

  /// No description provided for @invTemplTextColor.
  ///
  /// In es, this message translates to:
  /// **'Color de texto'**
  String get invTemplTextColor;

  /// No description provided for @invTemplShowLogo.
  ///
  /// In es, this message translates to:
  /// **'Mostrar logotipo'**
  String get invTemplShowLogo;

  /// No description provided for @invTemplShowLogoDesc.
  ///
  /// In es, this message translates to:
  /// **'Incluye el logo del restaurante en el email'**
  String get invTemplShowLogoDesc;

  /// No description provided for @invTemplShowRestInfo.
  ///
  /// In es, this message translates to:
  /// **'Mostrar info del restaurante'**
  String get invTemplShowRestInfo;

  /// No description provided for @invTemplShowRestInfoDesc.
  ///
  /// In es, this message translates to:
  /// **'Muestra el nombre del restaurante en la cabecera'**
  String get invTemplShowRestInfoDesc;

  /// No description provided for @invTemplSubjectLine.
  ///
  /// In es, this message translates to:
  /// **'Asunto del email'**
  String get invTemplSubjectLine;

  /// No description provided for @invTemplHeaderText.
  ///
  /// In es, this message translates to:
  /// **'Texto de cabecera'**
  String get invTemplHeaderText;

  /// No description provided for @invTemplBodyText.
  ///
  /// In es, this message translates to:
  /// **'Texto del cuerpo'**
  String get invTemplBodyText;

  /// No description provided for @invTemplButtonText.
  ///
  /// In es, this message translates to:
  /// **'Texto del botón'**
  String get invTemplButtonText;

  /// No description provided for @invTemplFooterText.
  ///
  /// In es, this message translates to:
  /// **'Texto del pie'**
  String get invTemplFooterText;

  /// No description provided for @invTemplDeclineText.
  ///
  /// In es, this message translates to:
  /// **'Texto de declinar'**
  String get invTemplDeclineText;

  /// No description provided for @invTemplVariablesHint.
  ///
  /// In es, this message translates to:
  /// **'Usa estas variables en tus textos: restaurant, inviter, role, email, expire_date (envueltas entre llaves)'**
  String get invTemplVariablesHint;

  /// No description provided for @invTemplSaved.
  ///
  /// In es, this message translates to:
  /// **'Plantilla guardada correctamente'**
  String get invTemplSaved;

  /// No description provided for @invTemplNoTenant.
  ///
  /// In es, this message translates to:
  /// **'Selecciona un restaurante primero'**
  String get invTemplNoTenant;

  /// No description provided for @pageNotFound.
  ///
  /// In es, this message translates to:
  /// **'Página no encontrada: {path}'**
  String pageNotFound(String path);

  /// No description provided for @errorBackHome.
  ///
  /// In es, this message translates to:
  /// **'Volver al inicio'**
  String get errorBackHome;

  /// No description provided for @digitalMenuAll.
  ///
  /// In es, this message translates to:
  /// **'Todos'**
  String get digitalMenuAll;

  /// No description provided for @remove.
  ///
  /// In es, this message translates to:
  /// **'Quitar'**
  String get remove;

  /// No description provided for @apply.
  ///
  /// In es, this message translates to:
  /// **'Aplicar'**
  String get apply;

  /// No description provided for @orderLabel.
  ///
  /// In es, this message translates to:
  /// **'Pedido #{orderNumber}'**
  String orderLabel(String orderNumber);

  /// No description provided for @orderOnItsWay.
  ///
  /// In es, this message translates to:
  /// **'Tu pedido está en camino'**
  String get orderOnItsWay;

  /// No description provided for @changeTo.
  ///
  /// In es, this message translates to:
  /// **'Cambiar a:'**
  String get changeTo;

  /// No description provided for @refundTitle.
  ///
  /// In es, this message translates to:
  /// **'Reembolso'**
  String get refundTitle;

  /// No description provided for @refundReasonLabel.
  ///
  /// In es, this message translates to:
  /// **'Motivo del reembolso'**
  String get refundReasonLabel;

  /// No description provided for @refundReasonHint.
  ///
  /// In es, this message translates to:
  /// **'Describe el motivo del reembolso...'**
  String get refundReasonHint;

  /// No description provided for @refundConfirm.
  ///
  /// In es, this message translates to:
  /// **'Confirmar reembolso'**
  String get refundConfirm;

  /// No description provided for @refundSuccess.
  ///
  /// In es, this message translates to:
  /// **'Reembolso procesado correctamente'**
  String get refundSuccess;

  /// No description provided for @refundStatusLabel.
  ///
  /// In es, this message translates to:
  /// **'Reembolsado'**
  String get refundStatusLabel;

  /// No description provided for @cancelOrderButton.
  ///
  /// In es, this message translates to:
  /// **'Cancelar pedido'**
  String get cancelOrderButton;

  /// No description provided for @cancelOrderConfirmMessage.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro de que quieres cancelar este pedido?'**
  String get cancelOrderConfirmMessage;

  /// No description provided for @requestRefund.
  ///
  /// In es, this message translates to:
  /// **'Solicitar reembolso'**
  String get requestRefund;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
