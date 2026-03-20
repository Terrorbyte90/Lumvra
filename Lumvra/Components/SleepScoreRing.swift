import SwiftUI

struct SleepScoreRing: View {
    let score: Int
    let size: CGFloat

    private var color: Color { Color.forScore(score) }
    private var progress: Double { Double(score) / 100.0 }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.lvSurface2, lineWidth: size * 0.08)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: size * 0.08, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 1.0), value: progress)
            VStack(spacing: 4) {
                Text("\(score)")
                    .font(.system(size: size * 0.3, weight: .bold, design: .rounded))
                    .foregroundColor(.lvTextPri)
                Text("Sleep Score")
                    .font(.system(size: size * 0.09))
                    .foregroundColor(.lvTextSec)
            }
        }
        .frame(width: size, height: size)
    }
}
