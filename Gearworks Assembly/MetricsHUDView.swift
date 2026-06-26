import SwiftUI

struct MetricsHUDView: View {
    @ObservedObject var vm: EditorViewModel

    var body: some View {
        GearCard {
            VStack(alignment: .leading, spacing: 10) {
                statusBanner
                HStack(spacing: 8) {
                    chip(title: "Cycles", value: "\(vm.simTick)", accent: GearPalette.blueprint)
                    chip(title: "Cost", value: "\(vm.solution.cost)", accent: GearPalette.copper)
                    chip(title: "Area", value: "\(vm.solution.area)", accent: GearPalette.verdigris)
                    chip(title: "Instr", value: "\(vm.solution.instructionCount)", accent: GearPalette.gold)
                }
                deliveryRow
            }
        }
    }

    private var statusBanner: some View {
        HStack(spacing: 8) {
            statusDot
            Text(statusMessage)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(statusColor)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
    }

    private var statusDot: some View {
        Circle().fill(statusColor).frame(width: 10, height: 10)
    }

    private var statusMessage: String {
        switch vm.phase {
        case .idle: return vm.statusText
        case .running: return "Running…"
        case .paused: return "Paused at cycle \(vm.simTick)."
        case .solved: return vm.statusText
        case .failed(let r): return r
        }
    }

    private var statusColor: Color {
        switch vm.phase {
        case .solved: return GearPalette.verdigris
        case .failed: return GearPalette.alert
        case .running: return GearPalette.gold
        default: return GearPalette.haze
        }
    }

    private func chip(title: String, value: String, accent: Color) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.system(size: 17, weight: .black, design: .rounded)).foregroundColor(GearPalette.ivory)
            Text(title).font(.system(size: 10, weight: .bold)).foregroundColor(accent)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 10).fill(GearPalette.navyDeep))
    }

    private var deliveryRow: some View {
        HStack(spacing: 10) {
            ForEach(Array(vm.puzzle.sinks.enumerated()), id: \.offset) { idx, sink in
                let done = idx < vm.delivered.count ? vm.delivered[idx] : 0
                HStack(spacing: 5) {
                    if let a = sink.target.atoms.first { AtomNodeView(element: a.element, size: 18) }
                    Text("\(done)/\(sink.required)")
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundColor(done >= sink.required ? GearPalette.verdigris : GearPalette.ivory)
                }
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(RoundedRectangle(cornerRadius: 9).fill(GearPalette.navyDeep))
            }
            Spacer()
        }
    }
}
