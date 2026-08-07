# Provider Graph — Mecha Connect

> The 9 root providers, constructed once in `frontend/lib/app_wiring.dart`
> (`buildRootProviders()`). Order matters and is frozen.

## Root Provider Order

| Order | Provider | Constructed with |
|---|---|---|
| 1 | `ThemeProvider` | `ChangeNotifierProvider(create)` |
| 2 | `LocationProvider` | injectable or default |
| 3 | `AuthProvider` | `AuthService(AuthRepository())` |
| 4 | `HomeProvider` | `HomeRepository()` |
| 5 | `MechanicProvider` | default (repository injectable since 1.9b) |
| 6 | `AiProvider` | default (owns ONE `AiRepository`) |
| 7 | `ProfileProvider` | `ProfileRepository(SharedPreferencesNotificationSettingsStore)` |
| 8 | `FuelProvider` | `FuelProvider(locationProvider: location)` |
| 9 | `MarketplaceProvider` | injectable or default |

## Injection Points (for tests)

`LocationProvider`, `FuelProvider`, `MarketplaceProvider`, and
`ProfileProvider` accept injected dependencies. Everything else is created in
place.

## Non-Provider Singletons

- `orderStore` — `OrderStore extends ChangeNotifier`; the Orders tab and
  Marketplace both reach it. `addMarketplaceOrder()` calls `orderStore.notify()`
  after inserting into `ordersList`.
- `ordersList` — seeded global in-memory order list (Parts/Mechanic/Fuel/AI
  seeded entries + Marketplace inserts).

## Wiring (entry)

1. `main.dart`: `ensureInitialized()` → best-effort `.env` load → create
   `LocationProvider`, `FuelProvider`, `MarketplaceProvider` → `runApp(
   MultiProvider(providers: buildRootProviders(...), child: MyApp()))`.
2. `MyApp` → `DevicePreview(enabled: kDebugMode)` → `MaterialApp` with
   `AppTheme.light`/`AppTheme.dark`, `themeMode: themeProvider.themeMode`,
   `initialRoute: '/'` → `SplashScreen`.

## Rules (frozen)

- No second wiring path; the runtime regression test uses the exact production
  graph.
- AI module shares exactly ONE `AiRepository` across `AiProvider`,
  `AiService`, and `DiagnosisService` (triple-repo bug fixed in 1.9b).
- No dev flags remain in the gateway; `MyApp` takes no navigator observers.
