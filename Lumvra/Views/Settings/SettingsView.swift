import SwiftUI
import RevenueCat

struct SettingsView: View {
    @EnvironmentObject var lm: LanguageManager
    @EnvironmentObject var userState: UserState
    @EnvironmentObject var storage: LocalStorageManager
    @EnvironmentObject var notificationManager: NotificationManager
    @State private var showDeleteAlert = false
    @State private var showPaywall = false

    var body: some View {
        ZStack {
            Color.lvBackground.ignoresSafeArea()
            List {
                Section(lm.t(en: "General", sv: "Allmänt")) {
                    Picker(lm.t(en: "Language", sv: "Språk"), selection: $lm.selectedLanguage) {
                        Text(lm.t(en: "System", sv: "System")).tag("system")
                        Text("English").tag("en")
                        Text("Svenska").tag("sv")
                    }
                    .onChange(of: lm.selectedLanguage) {
                        notificationManager.reschedule(profile: userState.profile, language: lm.resolvedLanguage)
                    }
                }
                .listRowBackground(Color.lvSurface)

                Section(lm.t(en: "Sleep goals", sv: "Sömnmål")) {
                    DatePicker(
                        lm.t(en: "Bedtime target", sv: "Läggdags-mål"),
                        selection: Binding(
                            get: { userState.profile.targetBedtime },
                            set: { userState.profile.targetBedtime = $0; save() }
                        ),
                        displayedComponents: .hourAndMinute
                    )
                    DatePicker(
                        lm.t(en: "Wake time target", sv: "Uppvakningsmål"),
                        selection: Binding(
                            get: { userState.profile.targetWakeTime },
                            set: { userState.profile.targetWakeTime = $0; save() }
                        ),
                        displayedComponents: .hourAndMinute
                    )
                    Stepper(
                        lm.t(
                            en: "Sleep goal: \(String(format: "%.1f", userState.profile.targetSleepHours))h",
                            sv: "Sömnmål: \(String(format: "%.1f", userState.profile.targetSleepHours))h"
                        ),
                        value: Binding(
                            get: { userState.profile.targetSleepHours },
                            set: { userState.profile.targetSleepHours = $0; save() }
                        ),
                        in: 5.0...10.0, step: 0.5
                    )
                    .foregroundColor(.lvTextPri)
                }
                .listRowBackground(Color.lvSurface)

                Section(lm.t(en: "Notifications", sv: "Notifikationer")) {
                    Toggle(
                        lm.t(en: "Morning reminder", sv: "Morgonpåminnelse"),
                        isOn: Binding(
                            get: { userState.profile.morningNotificationsEnabled },
                            set: { userState.profile.morningNotificationsEnabled = $0; save(); reschedule() }
                        )
                    )
                    Toggle(
                        lm.t(en: "Evening reminder", sv: "Kvällspåminnelse"),
                        isOn: Binding(
                            get: { userState.profile.eveningNotificationsEnabled },
                            set: { userState.profile.eveningNotificationsEnabled = $0; save(); reschedule() }
                        )
                    )
                }
                .listRowBackground(Color.lvSurface)

                Section(lm.t(en: "Track", sv: "Spåra")) {
                    Toggle(lm.t(en: "Alcohol", sv: "Alkohol"),
                           isOn: Binding(get: { userState.profile.alcoholTracking },
                                         set: { userState.profile.alcoholTracking = $0; save() }))
                    Toggle(lm.t(en: "Coffee", sv: "Kaffe"),
                           isOn: Binding(get: { userState.profile.coffeeTracking },
                                         set: { userState.profile.coffeeTracking = $0; save() }))
                    Toggle(lm.t(en: "Exercise", sv: "Träning"),
                           isOn: Binding(get: { userState.profile.exerciseTracking },
                                         set: { userState.profile.exerciseTracking = $0; save() }))
                }
                .listRowBackground(Color.lvSurface)

                Section(lm.t(en: "Account", sv: "Konto")) {
                    if userState.isPremium {
                        HStack {
                            Text(lm.t(en: "Subscription", sv: "Prenumeration"))
                                .foregroundColor(.lvTextPri)
                            Spacer()
                            Text(lm.t(en: "Active ✓", sv: "Aktiv ✓"))
                                .foregroundColor(.lvTeal)
                        }
                    } else {
                        Button { showPaywall = true } label: {
                            Text(lm.t(en: "Upgrade to Premium", sv: "Uppgradera till Premium"))
                                .foregroundColor(.lvPurple)
                        }
                    }
                    Button {
                        Task {
                            _ = try? await Purchases.shared.restorePurchases()
                            await userState.refreshPremiumStatus()
                        }
                    } label: {
                        Text(lm.t(en: "Restore purchases", sv: "Återställ köp"))
                            .foregroundColor(.lvTextSec)
                    }
                }
                .listRowBackground(Color.lvSurface)

                Section(lm.t(en: "Data & Privacy", sv: "Data och integritet")) {
                    Button(role: .destructive) { showDeleteAlert = true } label: {
                        Text(lm.t(en: "Delete my data", sv: "Radera mina data"))
                    }
                }
                .listRowBackground(Color.lvSurface)

                Section(lm.t(en: "About", sv: "Om appen")) {
                    HStack {
                        Text(lm.t(en: "Version", sv: "Version"))
                            .foregroundColor(.lvTextPri)
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                            .foregroundColor(.lvTextSec)
                    }
                }
                .listRowBackground(Color.lvSurface)
            }
            .scrollContentBackground(.hidden)
            .navigationTitle(lm.t(en: "Settings", sv: "Inställningar"))
        }
        .alert(
            lm.t(en: "Delete all data?", sv: "Radera all data?"),
            isPresented: $showDeleteAlert
        ) {
            Button(lm.t(en: "Delete", sv: "Radera"), role: .destructive) {
                storage.clearAll()
            }
            Button(lm.t(en: "Cancel", sv: "Avbryt"), role: .cancel) {}
        } message: {
            Text(lm.t(en: "This cannot be undone.", sv: "Detta kan inte ångras."))
        }
        .sheet(isPresented: $showPaywall) { PaywallView() }
    }

    private func save() { userState.saveProfile() }
    private func reschedule() {
        notificationManager.reschedule(profile: userState.profile, language: lm.resolvedLanguage)
    }
}
