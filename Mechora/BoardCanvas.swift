import SwiftUI

struct BoardCanvas: View {
    @ObservedObject var vm: EditorViewModel
    let screenSize: CGSize          // parent-passed; never use the Canvas closure size for math
    let showCoords: Bool

    @State private var zoom: CGFloat = 1
    @State private var zoomAtStart: CGFloat = 1
    @State private var pan: CGSize = .zero
    @State private var panAtStart: CGSize = .zero

    private var boardW: Int { vm.puzzle.width }
    private var boardH: Int { vm.puzzle.height }

    private func layout() -> (cell: CGFloat, origin: CGPoint) {
        let pad: CGFloat = 8
        let availW = max(40, screenSize.width - pad * 2)
        let availH = max(40, screenSize.height - pad * 2)
        let base = min(availW / CGFloat(boardW), availH / CGFloat(boardH))
        let cell = base * zoom
        let bw = cell * CGFloat(boardW)
        let bh = cell * CGFloat(boardH)
        let ox = (screenSize.width - bw) / 2 + pan.width
        let oy = (screenSize.height - bh) / 2 + pan.height
        return (cell, CGPoint(x: ox, y: oy))
    }

    private func center(_ p: GridPos, _ cell: CGFloat, _ origin: CGPoint) -> CGPoint {
        CGPoint(x: origin.x + (CGFloat(p.x) + 0.5) * cell, y: origin.y + (CGFloat(p.y) + 0.5) * cell)
    }

    var body: some View {
        // Explicitly read every published value the board depends on so SwiftUI
        // always re-evaluates this view (and rebuilds the Canvas with a fresh
        // draw closure) when the sim advances OR is reset. refreshToken is bumped
        // on every tick and on reset; phase/simTick/selectedArmId cover the rest.
        let token = vm.refreshToken
        let phase = vm.phase
        let tick = vm.simTick
        let selected = vm.selectedArmId
        _ = (token, phase, tick, selected)
        let lay = layout()
        return Canvas { ctx, _ in
            draw(ctx: &ctx, cell: lay.cell, origin: lay.origin)
        }
        .frame(width: screenSize.width, height: screenSize.height)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { v in
                    pan = CGSize(width: panAtStart.width + v.translation.width,
                                 height: panAtStart.height + v.translation.height)
                }
                .onEnded { v in
                    let dist = hypot(v.translation.width, v.translation.height)
                    if dist < 8 {
                        pan = panAtStart
                        handleTap(at: v.startLocation)
                    } else {
                        panAtStart = pan
                    }
                }
        )
        .simultaneousGesture(
            MagnificationGesture()
                .onChanged { scale in zoom = min(2.6, max(0.6, zoomAtStart * scale)) }
                .onEnded { _ in zoomAtStart = zoom }
        )
    }

    private func handleTap(at point: CGPoint) {
        let lay = layout()
        guard lay.cell > 0 else { return }
        let x = Int(floor((point.x - lay.origin.x) / lay.cell))
        let y = Int(floor((point.y - lay.origin.y) / lay.cell))
        guard x >= 0, x < boardW, y >= 0, y < boardH else { return }
        vm.tapCell(GridPos(x: x, y: y))
    }

    private func draw(ctx: inout GraphicsContext, cell: CGFloat, origin: CGPoint) {
        let puzzle = vm.puzzle
        // board background
        let boardRect = CGRect(x: origin.x, y: origin.y, width: cell * CGFloat(boardW), height: cell * CGFloat(boardH))
        ctx.fill(Path(roundedRect: boardRect, cornerRadius: 6), with: .color(GearPalette.navyDeep))

        // grid
        for gx in 0...boardW {
            var p = Path()
            p.move(to: CGPoint(x: origin.x + CGFloat(gx) * cell, y: origin.y))
            p.addLine(to: CGPoint(x: origin.x + CGFloat(gx) * cell, y: origin.y + cell * CGFloat(boardH)))
            ctx.stroke(p, with: .color(GearPalette.blueprint.opacity(0.18)), lineWidth: 1)
        }
        for gy in 0...boardH {
            var p = Path()
            p.move(to: CGPoint(x: origin.x, y: origin.y + CGFloat(gy) * cell))
            p.addLine(to: CGPoint(x: origin.x + cell * CGFloat(boardW), y: origin.y + CGFloat(gy) * cell))
            ctx.stroke(p, with: .color(GearPalette.blueprint.opacity(0.18)), lineWidth: 1)
        }

        // walls
        for w in puzzle.walls {
            let r = cellRect(w, cell, origin).insetBy(dx: 1, dy: 1)
            ctx.fill(Path(r), with: .color(GearPalette.haze.opacity(0.35)))
        }

        // dispenser (INPUT) cells — filled copper tint + dashed edge + an "IN" tag
        // so the atom source reads clearly, not as abstract decoration.
        for d in puzzle.dispensers {
            for a in d.molecule.atoms {
                let full = cellRect(d.anchor + a.offset, cell, origin)
                ctx.fill(Path(roundedRect: full.insetBy(dx: 1.5, dy: 1.5), cornerRadius: 5),
                         with: .color(GearPalette.copper.opacity(0.16)))
                ctx.stroke(Path(roundedRect: full.insetBy(dx: 2, dy: 2), cornerRadius: 4),
                           with: .color(GearPalette.copper.opacity(0.95)),
                           style: StrokeStyle(lineWidth: 1.6, dash: [4, 3]))
            }
            if cell > 18, let first = d.molecule.atoms.first {
                let r = cellRect(d.anchor + first.offset, cell, origin)
                let t = Text("IN").font(.system(size: min(11, cell * 0.3), weight: .black, design: .rounded))
                    .foregroundColor(GearPalette.copperBright)
                ctx.draw(t, at: CGPoint(x: r.minX + 3, y: r.minY + 2), anchor: .topLeading)
            }
        }

        // sink (OUTPUT) cells — green tint fill + ghost target atom + an "OUT" tag.
        for sink in puzzle.sinks {
            for a in sink.target.atoms {
                let cellPos = sink.anchor + a.offset
                let full = cellRect(cellPos, cell, origin)
                ctx.fill(Path(roundedRect: full.insetBy(dx: 1.5, dy: 1.5), cornerRadius: 5),
                         with: .color(GearPalette.verdigris.opacity(0.14)))
                ctx.stroke(Path(roundedRect: full.insetBy(dx: 2, dy: 2), cornerRadius: 4),
                           with: .color(GearPalette.verdigris.opacity(0.95)),
                           style: StrokeStyle(lineWidth: 1.8))
                let inset = full.insetBy(dx: cell * 0.26, dy: cell * 0.26)
                ctx.fill(Path(ellipseIn: inset), with: .color(GearPalette.element(a.element).opacity(0.28)))
            }
            if cell > 18, let first = sink.target.atoms.first {
                let r = cellRect(sink.anchor + first.offset, cell, origin)
                let t = Text("OUT").font(.system(size: min(11, cell * 0.3), weight: .black, design: .rounded))
                    .foregroundColor(GearPalette.verdigris)
                ctx.draw(t, at: CGPoint(x: r.minX + 3, y: r.minY + 2), anchor: .topLeading)
            }
        }

        // bonders
        for b in vm.solution.bonders {
            let c = center(b, cell, origin)
            let rad = cell * 0.34
            let ring = CGRect(x: c.x - rad, y: c.y - rad, width: rad * 2, height: rad * 2)
            ctx.stroke(Path(ellipseIn: ring), with: .color(GearPalette.gold.opacity(0.85)),
                       style: StrokeStyle(lineWidth: 2, dash: [3, 2]))
        }
        // bonder links (adjacent bonders)
        let bset = Set(vm.solution.bonders)
        for b in vm.solution.bonders {
            for nb in [GridPos(x: b.x + 1, y: b.y), GridPos(x: b.x, y: b.y + 1)] where bset.contains(nb) {
                var p = Path()
                p.move(to: center(b, cell, origin)); p.addLine(to: center(nb, cell, origin))
                ctx.stroke(p, with: .color(GearPalette.gold.opacity(0.5)), lineWidth: 2)
            }
        }

        // bonds between atoms
        for (a, b) in vm.renderBonds() {
            var p = Path()
            p.move(to: center(a, cell, origin)); p.addLine(to: center(b, cell, origin))
            ctx.stroke(p, with: .color(GearPalette.copperBright), lineWidth: max(2, cell * 0.12))
        }

        // atoms
        for (pos, element, preview) in vm.renderAtoms() {
            let r = cellRect(pos, cell, origin).insetBy(dx: cell * 0.16, dy: cell * 0.16)
            let color = GearPalette.element(element)
            ctx.fill(Path(ellipseIn: r), with: .color(preview ? color.opacity(0.55) : color))
            ctx.stroke(Path(ellipseIn: r), with: .color(Color.black.opacity(0.25)), lineWidth: 1)
            if cell > 22 {
                let t = Text(element.symbol)
                    .font(.system(size: cell * 0.34, weight: .black, design: .rounded))
                    .foregroundColor(GearPalette.navyDeep)
                ctx.draw(t, at: center(pos, cell, origin))
            }
        }

        // arms
        for arm in vm.renderArms() {
            let pc = center(arm.pivot, cell, origin)
            let tc = center(arm.tip, cell, origin)
            let selected = arm.id == vm.selectedArmId
            let armColor = selected ? GearPalette.copperBright : GearPalette.ivory.opacity(0.85)
            var beam = Path()
            beam.move(to: pc); beam.addLine(to: tc)
            ctx.stroke(beam, with: .color(armColor), lineWidth: max(3, cell * 0.14))
            // hub
            let hubR = cell * 0.22
            let hub = CGRect(x: pc.x - hubR, y: pc.y - hubR, width: hubR * 2, height: hubR * 2)
            ctx.fill(Path(ellipseIn: hub), with: .color(selected ? GearPalette.copper : GearPalette.panelLift))
            ctx.stroke(Path(ellipseIn: hub), with: .color(armColor), lineWidth: 2)
            // gripper
            let gripR = cell * 0.16
            let grip = CGRect(x: tc.x - gripR, y: tc.y - gripR, width: gripR * 2, height: gripR * 2)
            ctx.stroke(Path(ellipseIn: grip), with: .color(arm.holding ? GearPalette.gold : armColor),
                       style: StrokeStyle(lineWidth: 2.5))
            if selected {
                let sel = cellRect(arm.pivot, cell, origin).insetBy(dx: 1, dy: 1)
                ctx.stroke(Path(roundedRect: sel, cornerRadius: 5),
                           with: .color(GearPalette.copperBright), style: StrokeStyle(lineWidth: 2, dash: [4, 3]))
            }
            // Editing: highlight the cell the gripper acts on (where Grab/Drop lands),
            // so the arm's reach/facing is concrete before you ever press Run.
            if selected && !vm.isSimActive {
                let tgt = cellRect(arm.tip, cell, origin).insetBy(dx: cell * 0.16, dy: cell * 0.16)
                ctx.stroke(Path(roundedRect: tgt, cornerRadius: 5),
                           with: .color(GearPalette.gold.opacity(0.9)),
                           style: StrokeStyle(lineWidth: 2, dash: [3, 3]))
            }
            // Running: float the current instruction beside the arm so its motion is
            // legible against the program tape.
            if let ins = arm.currentInstruction, cell > 16 {
                let fsize = min(12, cell * 0.34)
                let label = Text(ins.shortLabel)
                    .font(.system(size: fsize, weight: .black, design: .rounded))
                    .foregroundColor(GearPalette.navyDeep)
                let lp = CGPoint(x: tc.x, y: tc.y - cell * 0.62)
                let approxW = CGFloat(ins.shortLabel.count) * fsize * 0.64 + 8
                let bg = CGRect(x: lp.x - approxW / 2, y: lp.y - fsize * 0.75,
                                width: approxW, height: fsize * 1.5)
                ctx.fill(Path(roundedRect: bg, cornerRadius: 5), with: .color(GearPalette.gold.opacity(0.92)))
                ctx.draw(label, at: lp, anchor: .center)
            }
        }

        // coordinates overlay
        if showCoords && cell > 20 {
            for x in 0..<boardW {
                let t = Text("\(x)").font(.system(size: 9, weight: .bold)).foregroundColor(GearPalette.haze.opacity(0.7))
                ctx.draw(t, at: CGPoint(x: origin.x + (CGFloat(x) + 0.5) * cell, y: origin.y - 7))
            }
            for y in 0..<boardH {
                let t = Text("\(y)").font(.system(size: 9, weight: .bold)).foregroundColor(GearPalette.haze.opacity(0.7))
                ctx.draw(t, at: CGPoint(x: origin.x - 8, y: origin.y + (CGFloat(y) + 0.5) * cell))
            }
        }
    }

    private func cellRect(_ p: GridPos, _ cell: CGFloat, _ origin: CGPoint) -> CGRect {
        CGRect(x: origin.x + CGFloat(p.x) * cell, y: origin.y + CGFloat(p.y) * cell, width: cell, height: cell)
    }
}
