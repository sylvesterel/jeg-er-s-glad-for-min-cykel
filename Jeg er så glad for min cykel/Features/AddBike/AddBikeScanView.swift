import SwiftUI

/// Falsk 3D-scanning i en mørk "kamera"-visning. Intet rigtigt kamera, så ingen tilladelse.
struct AddBikeScanView: View {
    let model: AddBikeViewModel
    let add: (Bike) -> Void

    var body: some View {
        VStack(spacing: 0) {
            Text("Gå langsomt rundt om cyklen")
                .font(.headline)
                .foregroundStyle(.white)
                .opacity(model.scanFound ? 0 : 1)

            ZStack {
                ViewfinderCorners()
                    .stroke(.white.opacity(0.9), style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                BikeScanView(bike: model.scanBike, progress: model.scanProgress)
                    .padding(16)
            }
            .padding(24)
            .frame(maxHeight: .infinity)

            if model.scanFound {
                BikeResultCard(bike: model.scanBike, badge: "97 % match", add: { add(model.scanBike) }) {
                    Button("Ikke den rigtige? Scan igen", action: model.rescan)
                }
                .padding(.horizontal, 12)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            } else {
                progress
                    .transition(.opacity)
            }
        }
        .animation(.spring(duration: 0.5, bounce: 0.15), value: model.scanFound)
        .background { CameraBackdrop() }
        .environment(\.colorScheme, .dark)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task(id: model.scanAttempt) { await model.scan() }
        .sensoryFeedback(.impact(weight: .light), trigger: model.scanStep)
        .sensoryFeedback(trigger: model.scanFound) { _, found in found ? .success : nil }
    }

    private var progress: some View {
        VStack(spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text(model.scanStatus)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.7))
                    .contentTransition(.opacity)
                    .animation(.easeInOut, value: model.scanStep)
                Spacer()
                Text("\(Int(model.scanProgress * 100)) %")
                    .font(.system(size: 34, weight: .semibold, design: .rounded).monospacedDigit())
                    .foregroundStyle(.white)
                    .contentTransition(.numericText(value: model.scanProgress))
            }
            ProgressView(value: model.scanProgress)
                .tint(.accentColor)
        }
        .padding(.horizontal, 28)
        .padding(.bottom, 24)
    }
}

/// Mørk, sløret "rum"-baggrund der driver lidt, som et kamera i hånden.
private struct CameraBackdrop: View {
    @State private var drift = false

    var body: some View {
        ZStack {
            Color(white: 0.05)
            Circle()
                .fill(Color(white: 0.24))
                .frame(width: 380)
                .offset(x: -150, y: -280)
                .blur(radius: 90)
            Rectangle()
                .fill(Color(white: 0.14))
                .frame(width: 140, height: 700)
                .offset(x: 170, y: -60)
                .blur(radius: 50)
            Ellipse()
                .fill(Color(red: 0.24, green: 0.2, blue: 0.16))
                .frame(width: 560, height: 260)
                .offset(y: 360)
                .blur(radius: 80)
        }
        .offset(x: drift ? 14 : -14, y: drift ? -8 : 8)
        .scaleEffect(1.15)
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) { drift = true }
        }
    }
}

#Preview {
    NavigationStack {
        AddBikeScanView(model: AddBikeViewModel(), add: { _ in })
    }
    .environment(Garage())
}
