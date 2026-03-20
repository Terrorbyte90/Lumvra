import SwiftUI

enum OnboardingStep {
    case welcome, healthKit, notifications, loading
}

struct OnboardingContainerView: View {
    @State private var step: OnboardingStep = .welcome

    var body: some View {
        switch step {
        case .welcome:
            WelcomeView { step = .healthKit }
        case .healthKit:
            HealthKitPermissionView { step = .notifications }
        case .notifications:
            NotificationPermissionView { step = .loading }
        case .loading:
            LoadingDataView()
        }
    }
}
