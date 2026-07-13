// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Pingüino Congelado';

  @override
  String get welcomeMsg => '¡Mantente fresco!';

  @override
  String get subWelcome => 'Estado actual de tu congelador.';

  @override
  String get tabHome => 'Inicio';

  @override
  String get tabInventory => 'El Témpano';

  @override
  String get tabIntake => 'Portal de Entrada';

  @override
  String get tabTips => 'Consejos';

  @override
  String get capacityTitle => 'Capacidad del Congelador';

  @override
  String get statusOptimal => 'Óptimo';

  @override
  String get statusFull => 'Lleno';

  @override
  String get lblExpiring => 'POR VENCER';

  @override
  String get lblTotal => 'TOTAL';

  @override
  String get invSub => 'Tus activos congelados.';

  @override
  String get btnFilter => 'Filtrar';

  @override
  String get intakeSub => 'Registra nuevas provisiones para el congelador.';

  @override
  String get toggleBarcode => 'Código de Barras';

  @override
  String get toggleManual => 'Manual';

  @override
  String get toggleVision => 'Visión';

  @override
  String get formName => 'Nombre del Artículo';

  @override
  String get hintName => 'ej., Hamburguesas, Arvejas';

  @override
  String get formQty => 'Cantidad';

  @override
  String get formZone => 'Zona de Almacenamiento';

  @override
  String get hintZone => 'Congelación Profunda (Abajo)';

  @override
  String get btnAdd => 'Agregar al Congelador';

  @override
  String get tipsSpotlight => 'DESTACADO DE LA SEMANA';

  @override
  String get tipsTitle1 => 'Domina la Congelación Profunda';

  @override
  String get tipsBody1 =>
      'Descubre formas ecológicas de conservar tus alimentos frescos y reducir el desperdicio con nuestras estrategias de cocina aprobadas por el pingüino.';

  @override
  String get tipsTitle2 => 'Escaldado 101';

  @override
  String get tipsBody2 =>
      'Un hervor rápido seguido de un baño de hielo detiene las enzimas, preservando colores brillantes y sabor.';

  @override
  String get settings => 'Configuración';

  @override
  String get settingsThemeHeader => 'TEMA';

  @override
  String get settingsLanguageHeader => 'IDIOMA';

  @override
  String get themeNameGlacier => 'Ártico';

  @override
  String get themeNameKitchen => 'Claro';

  @override
  String get themeNameOcean => 'Oscuro';

  @override
  String get loginTitle => 'Iniciar Sesión';

  @override
  String get registerTitle => 'Crear Cuenta';

  @override
  String get loginEmailLabel => 'Correo Electrónico';

  @override
  String get loginPasswordLabel => 'Contraseña';

  @override
  String get switchToRegister => '¿No tienes cuenta? Regístrate';

  @override
  String get switchToLogin => '¿Ya tienes cuenta? Inicia sesión';

  @override
  String get logoutButton => 'Cerrar Sesión';

  @override
  String get loginErrorEmptyFields =>
      'El correo y la contraseña son requeridos.';

  @override
  String get loginErrorInvalid => 'Correo o contraseña incorrectos.';

  @override
  String get registerSuccess => '¡Cuenta creada! Por favor inicia sesión.';

  @override
  String get loadingTagline => 'Mantente fresco, mantente inteligente.';

  @override
  String get loadingMessage => 'Organizando tu congelador…';

  @override
  String get loadingQuote1 =>
      'Ningún fragmento olvidado, ningún alimento desperdiciado.';

  @override
  String get loadingQuote2 => 'Domina tu congelador.';

  @override
  String get loadingQuote3 => 'Deja de adivinar. Empieza a enfriar.';

  @override
  String get loadingQuote4 => 'Una cara amable para un espacio organizado.';

  @override
  String get loadingQuote5 => 'Almacenamiento frío, visión clara.';

  @override
  String get tabColdStorage => 'Almacenamiento Frío';

  @override
  String get tabHomeStandard => 'Inicio';

  @override
  String get tabHomeArctic => 'Campamento Base';

  @override
  String get tabConsumeStandard => 'Festín';

  @override
  String get tabConsumeArctic => 'Raciones';

  @override
  String get tabCommunityStandard => 'Consejos Frescos';

  @override
  String get tabCommunityArctic => 'El Grupo';

  @override
  String get consumePageSub => 'Nutre tu cuerpo, rastrea tu ingesta.';

  @override
  String get consumeSectionSubtract => 'Registrar lo que Comiste';

  @override
  String get consumeSubtractHint =>
      'Selecciona un artículo de tu inventario para marcar como consumido.';

  @override
  String get consumeMarkEaten => 'Marcar como Comido';

  @override
  String get consumeSectionCalorie => 'Contador de Calorías y Macros';

  @override
  String get consumeCalorieHint => 'Rastrea tu ingesta nutricional diaria.';

  @override
  String get consumeFieldCalories => 'Calorías';

  @override
  String get consumeFieldProtein => 'Proteína (g)';

  @override
  String get consumeFieldCarbs => 'Carbohidratos (g)';

  @override
  String get consumeFieldFat => 'Grasa (g)';

  @override
  String get consumeLogMacros => 'Registrar Macros';

  @override
  String get consumeSectionPhoto => 'Fotografía tu Comida';

  @override
  String get consumePhotoHint =>
      'Sube una foto para registrar visualmente lo que comiste.';

  @override
  String get consumePhotoBtn => 'Subir Foto';

  @override
  String get inventoryEmpty =>
      'Tu congelador está vacío.\n¡Toca + para escanear un código o usar Visión!';

  @override
  String get inventoryLoadError => 'No se pudo cargar el inventario.';

  @override
  String get insightsTitle => 'Perspectivas del Despensero';

  @override
  String get insightsLoadError => 'No se pudieron cargar las perspectivas.';

  @override
  String get insightsRetry => 'Reintentar';

  @override
  String get insightsHighPriorityTitle => 'Alerta de Alta Prioridad';

  @override
  String get insightsHealthTitle => 'Salud del Despensero';

  @override
  String get insightsItemsLabel => 'artículos';

  @override
  String get insightsSafe => 'Seguro';

  @override
  String get insightsUseSoon => 'Usar Pronto';

  @override
  String get insightsExpired => 'Vencido';

  @override
  String get insightsDays7Plus => '≥ 7 días';

  @override
  String get insightsDays1to6 => '1–6 días';

  @override
  String get insightsPastDate => 'Fecha pasada';

  @override
  String get insightsReadyToCook => 'Listo para Cocinar';

  @override
  String get insightsZones => 'Zonas';

  @override
  String get insightsTopPicks => 'Más Populares';

  @override
  String get insightsShoppingList => 'Lista de Compras';

  @override
  String get insightsShoppingSub =>
      'Ingredientes faltantes para tus recetas guardadas.';

  @override
  String get insightsBuyBtn => 'Comprar';
}
