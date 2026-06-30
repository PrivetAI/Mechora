import SwiftUI

struct MechoraLoadingScreen: View {
    @State private var spin = false
    @State private var pulse = false

    var body: some View {
        ZStack {
            GearBackdrop().ignoresSafeArea()
            VStack(spacing: 24) {
                ZStack {
                    GearCogShape(teeth: 12)
                        .fill(GearPalette.copper)
                        .frame(width: 92, height: 92)
                        .rotationEffect(.degrees(spin ? 360 : 0))
                        .animation(.linear(duration: 6).repeatForever(autoreverses: false), value: spin)
                    GearCogShape(teeth: 8)
                        .fill(GearPalette.verdigris)
                        .frame(width: 54, height: 54)
                        .offset(x: 64, y: 40)
                        .rotationEffect(.degrees(spin ? -360 : 0), anchor: .center)
                        .animation(.linear(duration: 4).repeatForever(autoreverses: false), value: spin)
                }
                Text("Mechora")
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .foregroundColor(GearPalette.ivory)
                Text("Warming the drafting room and calibrating the assembly engine.")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(GearPalette.haze)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 36)
                HStack(spacing: 10) {
                    ForEach(0..<4, id: \.self) { i in
                        Circle()
                            .fill(i.isMultiple(of: 2) ? GearPalette.copper : GearPalette.blueprint)
                            .frame(width: 12, height: 12)
                            .scaleEffect(pulse ? 1.0 : 0.5)
                            .animation(.easeInOut(duration: 0.7).repeatForever().delay(Double(i) * 0.12), value: pulse)
                    }
                }
            }
        }
        .onAppear { spin = true; pulse = true }
    }
}
