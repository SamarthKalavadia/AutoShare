## WEEK 1

**Team Id:** To be filled by team
**Week No / Date:** Week 1 / Date: To be filled
**Project Title:** AutoShare
**Members Present:** Samarth Kalavadia, [To be filled by team]

### Planned Tasks
* Conduct a comprehensive requirement analysis to definitively outline the core features, target audience, and primary use cases of the AutoShare platform.
* Evaluate and finalize the cross-platform mobile development framework and backend-as-a-service (BaaS) provider.
* Set up the initial development environment, establish Git version control, and define the foundational project architecture.
* Define the application's global state management approach and structural navigation routing strategy.

### Tasks Completed This Week
* Finalized the project scope and drafted the software requirement specification, focusing heavily on peer-to-peer ride sharing, driver-passenger algorithmic matching, and real-time communication.
* Selected Flutter as the frontend framework to ensure a native-like, 60 FPS experience on both iOS and Android from a single unified Dart codebase.
* Chosen Firebase as the primary backend ecosystem to leverage its highly scalable real-time database capabilities, secure authentication, and cross-platform push notifications.
* Initialized the Flutter project (`autoshare`) and established a highly scalable, feature-first folder architecture isolating business logic from UI (`lib/core`, `lib/features`, `lib/data`, `lib/services`, `lib/shared`).
* Configured `pubspec.yaml` with foundational dependencies including `flutter_riverpod` for robust, reactive state management and `go_router` for deep-linkable, declarative routing.
* Created the base `AppTheme` class defining the application's core color palette, Google Fonts typography, and initial light/dark mode `ThemeData` configurations.

### Commits Made
**Count:** 3
1. `Initial project setup with Flutter framework and SDK alignment`
2. `Configured pubspec.yaml with core dependencies, fonts, and assets`
3. `Created scalable feature-first folder structure and base app theme`

### Issues Created / Closed
* No formal issues tracked; initial architecture, package selection, and setup tasks were handled internally via team discussions.

### Milestone Status
**10% complete — On Track**

### Blockers / Challenges Faced
* Choosing the absolute right state management solution required extensive prototyping. After evaluating Provider, GetX, and BLoC, Riverpod was explicitly selected for its compile-time safety, strict unidirectionality, and superior provider composition capabilities, though it introduced a moderate initial learning curve for the team.

### Plan for Next Week
* Connect the Flutter application directly to the Firebase Console and configure platform-specific initialization scripts for Android and iOS.
* Implement the foundational Firebase Authentication module to handle secure user registration and login flows.
* Design, prototype, and build the initial animated Splash Screen and an engaging User Onboarding interface.

**Assessed By (Faculty):** __________________
**Marks Awarded (5 marks):** ______ / 5
**Faculty Remarks:** ______________________________

---

## WEEK 2

**Team Id:** To be filled by team
**Week No / Date:** Week 2 / Date: To be filled
**Project Title:** AutoShare
**Members Present:** Samarth Kalavadia, [To be filled by team]

### Planned Tasks
* Connect the Flutter application to the Firebase Console and configure platform-specific initialization.
* Implement the foundational Firebase Authentication module to handle secure user registration and login flows.
* Design, prototype, and build the initial animated Splash Screen and an engaging User Onboarding interface.

### Tasks Completed This Week
* Successfully registered both the Android and iOS application variants in the Firebase Console and generated the required `firebase_options.dart` file using the automated FlutterFire CLI.
* Initialized Firebase globally within the `main.dart` entry point and ensured `WidgetsFlutterBinding.ensureInitialized()` was properly configured to handle early asynchronous setup.
* Integrated the `firebase_auth` package and developed the core authentication repository logic to handle email/password sign-ups, logins, and persistent user sessions.
* Developed a visually engaging, animated Splash screen (`lib/features/splash`) that utilizes Riverpod's `ref.listen` to automatically route users to either the Home screen or the Login screen based on their cached authentication state.
* Created the multi-page Onboarding user interface (`lib/features/onboarding`) utilizing Flutter's `PageView` widget to guide new users through the app's core value propositions.
* Built the initial UI for the Login and SignUp pages utilizing highly customized, reusable `TextFormField` widgets and reactive Riverpod `StateNotifierProvider`s to seamlessly manage and display loading spinners during network requests.

### Commits Made
**Count:** 4
1. `Connected Firebase to the project using FlutterFire CLI`
2. `Added Splash and Onboarding screens with dynamic GoRouter navigation`
3. `Implemented core Firebase Auth repository and session state tracking`
4. `Login and SignUp page UI initialized with custom text fields`

### Issues Created / Closed
* No formal issues tracked; UI responsiveness issues regarding viewport adjustments during keyboard appearance were handled via Flutter's `SafeArea` and `SingleChildScrollView`.

### Milestone Status
**20% complete — On Track**

### Blockers / Challenges Faced
* Encountered complex platform-specific configuration errors during Firebase Android initialization involving Gradle plugin version mismatches. This required meticulously updating the project-level and app-level `build.gradle` configurations to ensure strict compatibility with the `firebase_core` package requirements.

### Plan for Next Week
* Set up Cloud Firestore, design the NoSQL database schema for user profiles, and enforce security rules.
* Implement the User Profile feature, allowing authenticated users to upload, edit, and safely store their personal details.

**Assessed By (Faculty):** __________________
**Marks Awarded (5 marks):** ______ / 5
**Faculty Remarks:** ______________________________

---

## WEEK 3

**Team Id:** To be filled by team
**Week No / Date:** Week 3 / Date: To be filled
**Project Title:** AutoShare
**Members Present:** Samarth Kalavadia, [To be filled by team]

### Planned Tasks
* Set up Cloud Firestore, design the NoSQL database schema for user profiles, and enforce database security rules.
* Implement the User Profile feature, allowing authenticated users to upload, edit, and safely store their personal details.
* Ensure offline caching capabilities are enabled for a better user experience in low-network geographical areas.

### Tasks Completed This Week
* Integrated the `cloud_firestore` package and enabled offline persistence and unlimited cache size globally within `main.dart` to allow the app to function gracefully during network drops.
* Designed the NoSQL JSON-like schema for the `users` collection, determining optimal document structures (using the Firebase Auth UID as the document ID) for incredibly fast querying.
* Developed the Profile page interface (`lib/features/profile`) that binds directly to real-time updates from the user's Firestore document using a Riverpod `StreamProvider`, reflecting database changes instantly on the UI.
* Built the comprehensive Edit Profile functionality, allowing users to safely update their display name, contact information, and specific user preferences.
* Enhanced the user registration flow by adding specific demographic data capture, specifically implementing customized Gender selection radio buttons and dropdowns in the SignUp page.
* Implemented rigorous frontend form validation logic across the profile section to prevent empty submissions, malformed data entries, and SQL-injection-like NoSQL vulnerabilities.

### Commits Made
**Count:** 5
1. `Firestore initialization and users collection NoSQL schema planning`
2. `Gender option added in register page with complex state handling`
3. `Profile section UI constructed with real-time Firestore StreamProviders`
4. `Edit profile page updated with rigorous form validation logic`
5. `Integrated Shimmer package for smooth loading placeholders`

### Issues Created / Closed
* No formal issues tracked; data synchronization edge cases between the auth state and database state were handled during rigorous code reviews.

### Milestone Status
**30% complete — On Track**

### Blockers / Challenges Faced
* Configuring Cloud Firestore Security Rules proved highly challenging initially. Rules had to be strictly written using Firebase's custom syntax to ensure that users could only read and write to their own specific `users/{userId}` documents, actively preventing unauthorized mass data scraping.

### Plan for Next Week
* Integrate the Google Maps SDK API into the application.
* Implement robust geolocation services to fetch the user's current physical location.
* Develop the interactive Home dashboard featuring the real-time map and bottom navigation structure.

**Assessed By (Faculty):** __________________
**Marks Awarded (5 marks):** ______ / 5
**Faculty Remarks:** ______________________________

---

## WEEK 4

**Team Id:** To be filled by team
**Week No / Date:** Week 4 / Date: To be filled
**Project Title:** AutoShare
**Members Present:** Samarth Kalavadia, [To be filled by team]

### Planned Tasks
* Integrate the Google Maps SDK API into the application infrastructure.
* Implement robust geolocation services to fetch the user's current physical location safely.
* Develop the interactive Home dashboard featuring the real-time map interface and global bottom navigation.

### Tasks Completed This Week
* Successfully integrated the `google_maps_flutter` SDK and strictly configured the necessary restricted API keys within the Google Cloud Platform Console for the Android environment.
* Added the `geolocator` and `permission_handler` dependencies to handle highly complex, OS-level runtime location permissions gracefully, including "Always Allow" and "Allow While Using" states.
* Implemented real-time GPS location fetching logic that accurately determines the user's latitude and longitude while actively handling 'permission denied' or 'location disabled' scenarios with user-friendly dialogs.
* Built the core Home screen (`lib/features/home`) which centers around a highly responsive, interactive `GoogleMap` widget and established the global `BottomNavigationBar`.
* Created custom graphical map markers utilizing Flutter's `BitmapDescriptor` and optimized the `GoogleMapController` camera initialization to smoothly animate and focus on the user's current location upon app startup.
* Resolved a major bug regarding location fetching delays by implementing a dedicated `AsyncLoading` state in the Riverpod provider, displaying a custom loading overlay until GPS lock is acquired.

### Commits Made
**Count:** 4
1. `Google Maps Api integrated with secure GCP API keys`
2. `location fix and GoogleMapController camera animation logic added`
3. `Added precise location permission handling via permission_handler`
4. `Built primary Home screen UI and global Bottom Navigation Bar`

### Issues Created / Closed
* No formal issues tracked; severe map rendering optimization bugs and memory leaks were identified and resolved during intensive development.

### Milestone Status
**40% complete — On Track**

### Blockers / Challenges Faced
* The integration of the Google Maps API required complex native setup steps, including modifying the Android `AndroidManifest.xml` with specific metadata tags, adding precise location permissions, and ensuring the API keys were cryptographically secured and restricted by package name in the Google Cloud Console to prevent quota theft.

### Plan for Next Week
* Develop the critical "Create Ride" module, allowing authenticated drivers to publish new routes.
* Implement complex, multi-variable form validation for ride parameters and connect the UI to the Firestore `rides` collection.

**Assessed By (Faculty):** __________________
**Marks Awarded (5 marks):** ______ / 5
**Faculty Remarks:** ______________________________

---

## WEEK 5

**Team Id:** To be filled by team
**Week No / Date:** Week 5 / Date: To be filled
**Project Title:** AutoShare
**Members Present:** Samarth Kalavadia, [To be filled by team]

### Planned Tasks
* Develop the critical "Create Ride" module, allowing authenticated drivers to publish new routes.
* Implement complex, multi-variable form validation for all ride parameters.
* Connect the Create Ride UI securely to the backend to generate verified records in the Firestore `rides` collection.

### Tasks Completed This Week
* Engineered the entire Create Ride interface, featuring highly intuitive input fields for source location, destination, departure time, estimated arrival, and available seat capacity.
* Implemented strict, regex-based frontend form validation to ensure that users cannot submit rides with illogical chronologies (e.g., past departure times) or zero/negative available seats.
* Created the backend repository service logic to push validated ride data securely to the new `rides` NoSQL collection in Cloud Firestore, generating unique Document IDs automatically.
* Linked the currently authenticated user's Firebase UID and profile data to the ride document upon creation to immutably establish the "Driver" relationship and ownership.
* Executed multiple iterative UI fixes on the Create Ride page to drastically improve the user experience, such as replacing raw text inputs with native Flutter `showDatePicker` and `showTimePicker` modal dialogs.
* Ensured that upon successful asynchronous ride creation, the app smoothly navigates the user back to the Home screen using GoRouter's `context.go()` method, clearing the form state entirely.

### Commits Made
**Count:** 8
1. `CreateRide page fixed with native Flutter date/time picker modals`
2. `Complex number and chronological validation applied to ride creation`
3. `create ride problem fix regarding asynchronous Firestore batch writes`

### Issues Created / Closed
* No formal issues tracked; UI state management bugs on the massive Create Ride form were squashed internally by moving to a specialized Riverpod form controller.

### Milestone Status
**50% complete — On Track**

### Blockers / Challenges Faced
* Managing the transient state of the highly complex Create Ride form while simultaneously preventing the UI from freezing during asynchronous database write operations over poor networks required entirely refactoring the Riverpod controllers to utilize `AsyncValue` pattern, decoupling UI from business logic.

### Plan for Next Week
* Develop the complex Ride Search engine to allow passengers to find available, non-expired rides.
* Create the detailed 'Ride Details' interface and implement the critical 'Join Ride' NoSQL transactional business logic.

**Assessed By (Faculty):** __________________
**Marks Awarded (5 marks):** ______ / 5
**Faculty Remarks:** ______________________________

---

## WEEK 6

**Team Id:** To be filled by team
**Week No / Date:** Week 6 / Date: To be filled
**Project Title:** AutoShare
**Members Present:** Samarth Kalavadia, [To be filled by team]

### Planned Tasks
* Develop the complex Ride Search engine to allow passengers to find available, non-expired rides.
* Create the detailed 'Ride Details' interface to visually present comprehensive information about a specific route.
* Implement the critical 'Join Ride' NoSQL transactional business logic.

### Tasks Completed This Week
* Built the dynamic Search interface (`lib/features/search`), allowing users to input desired origins and destinations with debounced text fields to optimize API calls.
* Implemented a highly robust querying algorithm utilizing Firestore's `where()`, `orderBy()`, and `limit()` clauses to filter active rides based on location string matching and seat availability, ensuring expired or completely full rides are automatically excluded from the `ListView.builder`.
* Created the highly detailed 'Ride Details' page (`lib/features/ride_details`), which utilizes Flutter's `Hero` widget for smooth image transitions and visually presents the route map, driver information, timing, and exactly how much capacity remains.
* Engineered the critical 'Join Ride' core functionality. When a passenger taps the button, it triggers an immediate backend array update, pushing their UID into the ride's passenger list.
* Addressed and fixed severe, race-condition bugs relating to the 'Join Ride' button state, utilizing Riverpod to ensure the button UI correctly toggles from "Join" to "Requested" instantly across the UI without requiring a reload.
* Refined the UI components for the modular ride cards used in search results to make them highly scannable, visually appealing, and properly constrained within a `Card` widget with elevated shadows.

### Commits Made
**Count:** 5
1. `Added search functionality with complex Firestore querying for active rides`
2. `join ride button fix to reflect immediate state changes via Riverpod`
3. `Created Ride Details page with Hero animations and driver route info`

### Issues Created / Closed
* No formal issues tracked; complex NoSQL database query limits and optimizations were managed collaboratively.

### Milestone Status
**60% complete — On Track**

### Blockers / Challenges Faced
* Handling backend database concurrency was a major, highly critical hurdle. When multiple users attempted to join the exact same ride simultaneously, the seat capacity could theoretically fall below zero. This was flawlessly resolved by implementing Cloud Firestore Transactions (`FirebaseFirestore.instance.runTransaction()`) to ensure absolutely atomic reads and writes on the specific ride document.

### Plan for Next Week
* Implement the "My Rides" tracking dashboard, separating data streams for both drivers and passengers.
* Build the Requests management module, enabling drivers to directly approve or definitively reject passenger join requests.

**Assessed By (Faculty):** __________________
**Marks Awarded (5 marks):** ______ / 5
**Faculty Remarks:** ______________________________

---

## WEEK 7

**Team Id:** To be filled by team
**Week No / Date:** Week 7 / Date: To be filled
**Project Title:** AutoShare
**Members Present:** Samarth Kalavadia, [To be filled by team]

### Planned Tasks
* Implement the "My Rides" tracking dashboard, separating data streams for both drivers and passengers.
* Build the Requests management module, enabling drivers to directly approve or definitively reject passenger join requests.
* Implement robust, cascading ride cancellation logic.

### Tasks Completed This Week
* Developed the highly comprehensive 'My Rides' section (`lib/features/my_rides`) utilizing Flutter's `DefaultTabController` and `TabBarView` to cleanly separate "Rides I've Created" (Driver perspective) and "Rides I've Joined" (Passenger perspective).
* Utilized specialized Firestore `StreamProviders` to ensure the complex lists inside 'My Rides' are populated and updated in absolute real-time, instantly reflecting capacity changes or cancellations without requiring the user to execute a manual pull-to-refresh.
* Engineered the complex 'Requests' module (`lib/features/requests`), providing drivers with an intuitive interface to review pending passenger profiles (fetching their display names and ratings) and definitively Accept or Reject them via database array manipulation.
* Developed heavily cascaded ride cancellation logic. If a driver completely cancels a ride, all joined passengers have their statuses updated simultaneously and the ride document is marked inactive. If a passenger cancels, their specific seat is successfully and atomically returned to the available pool.
* Fixed several critical, edge-case bugs relating to validation during simultaneous ride creation and cancellation, ensuring NoSQL database consistency is maintained at all times.

### Commits Made
**Count:** 6
1. `Fix Create Ride validation and cascading Ride cancellation logic`
2. `cancel ride bug fixes ensuring atomic database integrity`
3. `Added My Rides section with DefaultTabController and real-time Streams`
4. `Implemented Ride Requests accept/reject database array manipulation`

### Issues Created / Closed
* No formal issues tracked; deep business logic flaws regarding seat capacity mathematics were identified via manual testing and resolved.

### Milestone Status
**70% complete — On Track**

### Blockers / Challenges Faced
* Synchronizing the application's global state precisely between the "My Rides" dashboard, the deeply nested "Requests" module, and the actual Firestore backend caused severe data desynchronization delays and "ghost" UI artifacts. This was ultimately mitigated by strictly enforcing a single source of truth using Riverpod's reactive caching and actively disposing of unused providers.

### Plan for Next Week
* Integrate Firebase Cloud Messaging (FCM) to introduce real-time push notifications across the ecosystem.
* Implement an in-app Chat feature utilizing Firestore to allow direct, secure communication between matched drivers and passengers.

**Assessed By (Faculty):** __________________
**Marks Awarded (5 marks):** ______ / 5
**Faculty Remarks:** ______________________________

---

## WEEK 8

**Team Id:** To be filled by team
**Week No / Date:** Week 8 / Date: To be filled
**Project Title:** AutoShare
**Members Present:** Samarth Kalavadia, [To be filled by team]

### Planned Tasks
* Integrate Firebase Cloud Messaging (FCM) to introduce remote, real-time push notifications across the ecosystem.
* Implement an in-app Chat feature utilizing Firestore to allow direct, secure communication between matched drivers and passengers.
* Integrate robust application crash monitoring and analytics.

### Tasks Completed This Week
* Successfully integrated Firebase Cloud Messaging (FCM) alongside the `flutter_local_notifications` package to handle precise local alerts and notification channels.
* Engineered a dedicated, highly robust `NotificationService` singleton class to seamlessly intercept, parse, and display background, fully terminated, and active foreground push notifications, utilizing device registration tokens.
* Developed the highly anticipated in-app 'Chat' module (`lib/features/chat`), creating dynamic, isolated chat rooms for every active ride document.
* Utilized continuous Firestore snapshot listeners wrapped in Riverpod `StreamProvider`s to create a fluid, real-time messaging interface (similar to WhatsApp), allowing passengers and drivers to coordinate pickup locations effortlessly with timestamp ordering.
* Integrated Firebase Crashlytics globally directly in `main.dart`, successfully capturing all uncaught asynchronous and synchronous framework errors, fatal exceptions, and stack traces to heavily improve application monitoring and production stability.
* Updated backend logic to trigger targeted FCM notifications automatically to specific device tokens when a ride request is officially accepted or rejected.

### Commits Made
**Count:** 4
1. `Integrated Firebase Cloud Messaging for remote device alerts`
2. `Added Chat UI and real-time ordered Firestore listener for messages`
3. `Configured Notification singleton service and Firebase Crashlytics`

### Issues Created / Closed
* No formal issues tracked; deeply hidden JSON notification payload parsing bugs were caught and fixed during extensive background-state testing.

### Milestone Status
**80% complete — On Track**

### Blockers / Challenges Faced
* Configuring the Apple Push Notification service (APNs) and ensuring reliable background execution for data-only notifications on modern Android versions (handling Doze mode) required extensive documentation review, certificate generation, and complex modifications to native platform manifest files.

### Plan for Next Week
* Implement remaining supplementary modules including the centralized Driver Directory and the post-ride Ratings system.
* Implement a globally persistent Dark Mode theme architecture.
* Perform a massive, comprehensive polish of the user interface and user experience.

**Assessed By (Faculty):** __________________
**Marks Awarded (5 marks):** ______ / 5
**Faculty Remarks:** ______________________________

---

## WEEK 9

**Team Id:** To be filled by team
**Week No / Date:** Week 9 / Date: To be filled
**Project Title:** AutoShare
**Members Present:** Samarth Kalavadia, [To be filled by team]

### Planned Tasks
* Implement remaining supplementary modules including the centralized Driver Directory and the post-ride Ratings system.
* Implement a globally persistent Dark Mode theme architecture across all application routes.
* Perform a massive, comprehensive polish of the user interface and user experience.

### Tasks Completed This Week
* Fully implemented a highly dynamic, visually pleasing Dark Mode utilizing the structured `AppTheme` class and a Riverpod `settingsProvider`. Ensured that explicit user theme preferences persist perfectly across app restarts using the `shared_preferences` local storage package.
* Developed the comprehensive 'Driver Directory' (`lib/features/driver_directory`), an administrative/exploratory view allowing users to safely browse a list of highly rated active drivers within the AutoShare ecosystem.
* Introduced the database foundation and UI dialogs for the 'Ratings' module (`lib/features/ratings`), enabling basic but effective post-ride 5-star feedback and calculating aggregate driver scores.
* Conducted a massive, focused UI polish phase across the entire codebase. Replaced generic Material buttons with highly customized interactive components, resolved deep-rooted layout flickering issues caused by unconstrained `ListView`s, and added smooth `Hero` transitions between startup screens.
* Refactored several data fetching directories and extracted repetitive UI code into specialized, reusable widget classes (`lib/core/widgets`) to drastically improve code modularity and maintainability.

### Commits Made
**Count:** 7
1. `Dark mode changes and shared_preferences theme persistence implementation`
2. `Driver Directory button change and full module integration`
3. `StartUp transitions added and layout flickering fixed via constraints`
4. `Refactored core widgets and extracted reusable UI components`

### Issues Created / Closed
* No formal issues tracked; extensive internal UI consistency audits resulted in numerous minor layout, padding, and alignment fixes.

### Milestone Status
**90% complete — On Track**

### Blockers / Challenges Faced
* Ensuring the entire application UI updated dynamically and instantly without any dropped frames or UI tearing when users toggled rapidly between Light and Dark modes required careful, surgical refactoring of multiple Riverpod theme consumers deeply nested across complex widget trees.

### Plan for Next Week
* Conduct final, aggressive end-to-end user acceptance testing across all primary and secondary application flows.
* Fix any outstanding authentication edge-case anomalies and minor UI alignment bugs.
* Finalize the application visual assets (high-res app icon) and prepare the entire codebase for final compilation, presentation, and grading submission.

**Assessed By (Faculty):** __________________
**Marks Awarded (5 marks):** ______ / 5
**Faculty Remarks:** ______________________________

---

## WEEK 10

**Team Id:** To be filled by team
**Week No / Date:** Week 10 / Date: To be filled
**Project Title:** AutoShare
**Members Present:** Samarth Kalavadia, [To be filled by team]

### Planned Tasks
* Conduct final, aggressive end-to-end user acceptance testing across all primary and secondary application flows.
* Fix any outstanding authentication edge-case anomalies and minor UI alignment bugs.
* Finalize the application visual assets (high-res app icon) and prepare the entire codebase for final compilation, presentation, and grading submission.

### Tasks Completed This Week
* Conducted exhaustive, aggressive end-to-end testing of the entire application logic, extensively simulating real-world driver and passenger concurrent interactions on both physical devices (Android/iOS) and software emulators.
* Identified and completely fixed final edge-case bugs regarding Google Authentication logic token refresh cycles, and addressed severe state synchronization delays during the user logout process to ensure secure session termination.
* Cleared all remaining Dart analyzer and IDE warnings, systematically removed all unused imports/variables, and executed precise, pixel-perfect minor UI alignments across various diverse device screen sizes and aspect ratios.
* Generated and applied the official, high-resolution branding `appicon.png` utilizing the automated `flutter_launcher_icons` package to inject the icons across Android, iOS, Web, MacOS, and Windows target configurations.
* Completed a highly thorough codebase cleanup, formatted all Dart files according to standard linting rules, and committed the absolute final, production-ready project source files securely to the repository.

### Commits Made
**Count:** 9
1. `Google auth token refresh fix and complete logout state resolution`
2. `Updated AutoShare bug fixes, cleared lints, and resolved Warning UI fixings`
3. `App icon changed globally across platforms and final project source files added`

### Issues Created / Closed
* No formal issues tracked; the final rigorous quality assurance checklist was completed successfully with zero severe or moderate bugs remaining in the release candidate.

### Milestone Status
**100% complete — On Track**

### Blockers / Challenges Faced
* No major blocker encountered during the final week. A few minor GoRouter navigation stack edge-cases were discovered during aggressive, rapid back-button testing, which were successfully and permanently resolved by modifying route popping logic before the final compilation build.

### Plan for Next Week
* Project development lifecycle officially concluded. Prepare the final live demonstration, presentation slides, and comprehensive project report documentation for the final faculty assessment.

**Assessed By (Faculty):** __________________
**Marks Awarded (5 marks):** ______ / 5
**Faculty Remarks:** ______________________________
