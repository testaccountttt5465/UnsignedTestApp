
import SwiftUI

struct ContentView: View {
    @State private var tapped = false

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: tapped ? "checkmark.circle.fill" : "iphone.gen3")
                .font(.system(size: 58))
                .foregroundStyle(tapped ? .green : .blue)

            Text("It works!")
                .font(.largeTitle.bold())

            Text(tapped
                 ? "The button works. Your test app is running."
                 : "This is a tiny iOS test app.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            Button(tapped ? "Reset test" : "Tap to test") {
                tapped.toggle()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
