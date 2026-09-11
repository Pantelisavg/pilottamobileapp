# Πιλόττα (Pilotta)

Ένα Flutter app για να παίζεις Πιλόττα (Παλαριστή) στο Android — τοπικά
εναντίον bots, online με φίλους, ή offline μέσω Bluetooth/τοπικού δικτύου.

## Δομή του repo

```
lib/                    Το Flutter app
  controllers/           Οδηγούν το παιχνίδι από την πλευρά του UI
  screens/                Οθόνες (menu, τοπικό παιχνίδι, online lobby, Bluetooth lobby, τραπέζι)
  widgets/                Επαναχρησιμοποιήσιμα widgets (χαρτιά, bidding panel, ...)
  bluetooth/              Nearby Connections (Bluetooth/Wi-Fi) integration
packages/
  pilotta_engine/         Καθαρός Dart κανόνες παιχνιδιού (χαρτιά, δημοπρασία,
                           τεχνάσματα, δηλώσεις, σκοράρισμα) — καμία εξάρτηση
                           από Flutter, ώστε να τρέχει παντού (mobile, web, server)
  pilotta_protocol/        Πρωτόκολλο δικτύου (JSON messages) + PilottaRoom, η
                           μία υλοποίηση της ροής του παιχνιδιού που μοιράζονται
                           το τοπικό παιχνίδι, ο online server, και ο Bluetooth host
server/                  Ο online multiplayer server (Dart + WebSocket)
```

## Τι λειτουργεί σήμερα

- **Πλήρης μηχανή κανόνων** για την Παλαριστή (δημοπρασία 80+, Καπότο,
  Κόντρα/Ρεκόντρα, σκάλες/καρέ, μπελότ, στρογγυλοποίηση /10) — 50+ unit tests.
- **Τοπικό παιχνίδι** εναντίον 3 bots στην ίδια συσκευή.
- **Online παιχνίδι**: δημιουργία/συμμετοχή σε δωμάτιο με 4-ψήφιο κωδικό,
  μέσω ενός Dart WebSocket server (`server/`) που πρέπει να τρέχει κάπου
  προσβάσιμο (δες `server/README.md`).
- **Bluetooth/τοπικό δίκτυο**: μία συσκευή φιλοξενεί το τραπέζι, οι άλλες το
  βρίσκουν κοντά τους και συνδέονται χωρίς internet (Android only, μέσω
  Nearby Connections).
- Σε κάθε λειτουργία, κενές θέσεις γεμίζουν αυτόματα με bots όταν ξεκινάει
  το παιχνίδι, και μία αποσύνδεση δεν "παγώνει" το τραπέζι — το bot
  αναλαμβάνει προσωρινά τη θέση μέχρι να επανασυνδεθείς με το ίδιο όνομα.

## Τρέχοντας το app

Χρειάζεσαι το Flutter SDK και το Android SDK εγκατεστημένα (δες
https://docs.flutter.dev/get-started/install). Αυτό το session δεν είχε
πρόσβαση σε πραγματικό Android SDK/emulator, οπότε ο κώδικας δεν έχει
δοκιμαστεί σε πραγματική συσκευή — μόνο μέσω `flutter analyze`, `flutter test`
(συμπεριλαμβανομένων πραγματικών WebSocket integration tests) και έλεγχο web
build. Πριν το παίξεις σε τηλέφωνο, τρέξε:

```bash
flutter pub get
flutter run          # σε συνδεδεμένη συσκευή/emulator
```

## Τρέχοντας τα tests

```bash
flutter test                              # UI + controllers
(cd packages/pilotta_engine && dart test) # κανόνες παιχνιδιού
(cd packages/pilotta_protocol && dart test) # πρωτόκολλο + PilottaRoom
(cd server && dart test)                  # online server (πραγματικό WebSocket)
```

## Online server

Δες [`server/README.md`](server/README.md) για το πώς τρέχεις/κάνεις deploy
τον server, και τι διεύθυνση να βάλεις στην οθόνη "Online Παιχνίδι".

## Τι μένει / γνωστοί περιορισμοί

- **Bluetooth mode δεν έχει δοκιμαστεί σε πραγματικές συσκευές** — το
  `nearby_connections` plugin χρειάζεται πραγματικό Android hardware, μη
  διαθέσιμο σε αυτό το sandboxed περιβάλλον. Η λογική δρομολόγησης μηνυμάτων
  είναι καλυμμένη με tests (mocked platform channel), αλλά το ίδιο το pairing
  θέλει επαλήθευση σε 2+ πραγματικά τηλέφωνα.
- Ο online server κρατάει τα δωμάτια στη μνήμη (χωρίς database) — ένα restart
  χάνει τα παιχνίδια σε εξέλιξη. Μια χαρά για δοκιμές/μικρή κλίμακα.
- Δεν υπάρχει ακόμα εικονίδιο/branding εκτός του βασικού Flutter placeholder.
- iOS: το `pilotta_engine`/`pilotta_protocol` είναι ήδη cross-platform, αλλά
  το Bluetooth mode (`nearby_connections`) είναι Android-only plugin, οπότε
  αυτό το κουμπί κρύβεται αυτόματα σε iOS.
