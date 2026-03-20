import SwiftUI

struct EveningView: View {
    @EnvironmentObject var lm: LanguageManager
    @EnvironmentObject var userState: UserState
    @EnvironmentObject var storage: LocalStorageManager
    @State private var hadAlcohol = false
    @State private var hadCoffee = false
    @State private var exercised = false
    @State private var saved = false
    @State private var showPaywall = false

    var body: some View {
        ZStack {
            Color.lvBackground.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 24) {
                    Text(lm.t(en: "Evening check-in", sv: "Kvällskoll"))
                        .font(.title2.bold())
                        .foregroundColor(.lvTextPri)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)

                    VStack(spacing: 4) {
                        Text(lm.t(en: "Tonight's bedtime", sv: "Läggdags ikväll"))
                            .font(.subheadline)
                            .foregroundColor(.lvTextSec)
                        Text(formattedBedtime)
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(.lvTextPri)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.lvSurface)
                    .cornerRadius(16)
                    .padding(.horizontal)

                    if userState.isPremium {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(lm.t(en: "Log your day (optional)", sv: "Logga din dag (valfritt)"))
                                .font(.subheadline.bold())
                                .foregroundColor(.lvTextSec)
                                .padding(.horizontal)

                            CheckInButton(icon: "🍷", en: "Had alcohol today?", sv: "Drack alkohol idag?", isOn: $hadAlcohol)
                                .padding(.horizontal)
                            CheckInButton(icon: "☕", en: "Coffee after 2 PM?", sv: "Kaffe efter 14:00?", isOn: $hadCoffee)
                                .padding(.horizontal)
                            CheckInButton(icon: "🏃", en: "Exercised today?", sv: "Tränade idag?", isOn: $exercised)
                                .padding(.horizontal)
                        }

                        Button {
                            let checkin = EveningCheckin(
                                date: Calendar.current.startOfDay(for: Date()),
                                hadAlcohol: hadAlcohol,
                                hadCoffeeAfter2pm: hadCoffee,
                                exercised: exercised
                            )
                            storage.saveCheckin(checkin)
                            withAnimation { saved = true }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { saved = false }
                        } label: {
                            Text(saved
                                 ? lm.t(en: "Saved ✓", sv: "Sparat ✓")
                                 : lm.t(en: "Save", sv: "Spara"))
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(saved ? Color.lvTeal : Color.lvPurple)
                                .cornerRadius(16)
                                .animation(.easeInOut, value: saved)
                        }
                        .padding(.horizontal)
                    } else {
                        Button { showPaywall = true } label: {
                            HStack {
                                Image(systemName: "lock.fill")
                                Text(lm.t(en: "Unlock evening coaching", sv: "Lås upp kvällscoaching"))
                                    .font(.subheadline.bold())
                            }
                            .foregroundColor(.lvPurple)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.lvSurface)
                            .cornerRadius(16)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
        }
        .sheet(isPresented: $showPaywall) { PaywallView() }
        .onAppear { loadCheckin() }
    }

    private var formattedBedtime: String {
        let f = DateFormatter(); f.dateFormat = "HH:mm"
        return f.string(from: userState.profile.targetBedtime)
    }

    private func loadCheckin() {
        guard let c = storage.loadCheckin(for: Date()) else { return }
        hadAlcohol = c.hadAlcohol
        hadCoffee = c.hadCoffeeAfter2pm
        exercised = c.exercised
    }
}
