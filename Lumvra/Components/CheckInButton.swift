import SwiftUI

struct CheckInButton: View {
    @EnvironmentObject var lm: LanguageManager
    let icon: String
    let en: String
    let sv: String
    @Binding var isOn: Bool

    var body: some View {
        Button { isOn.toggle() } label: {
            HStack {
                Text(icon)
                Text(lm.t(en: en, sv: sv))
                    .foregroundColor(.lvTextPri)
                Spacer()
                Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isOn ? .lvTeal : .lvTextTert)
            }
            .padding()
            .background(Color.lvSurface)
            .cornerRadius(12)
        }
    }
}
