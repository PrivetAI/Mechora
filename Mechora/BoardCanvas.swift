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
        _ = vm.refreshToken
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

        // dispenser cells
        for d in puzzle.dispensers {
            for a in d.molecule.atoms {
                let r = cellRect(d.anchor + a.offset, cell, origin).insetBy(dx: 2, dy: 2)
                ctx.stroke(Path(roundedRect: r, cornerRadius: 4),
                           with: .color(GearPalette.copper.opacity(0.9)),
                           style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
            }
        }

        // sink ghost (target shape at rotation 0) + count badge
        for sink in puzzle.sinks {
            for a in sink.target.atoms {
                let cellPos = sink.anchor + a.offset
                let r = cellRect(cellPos, cell, origin).insetBy(dx: 2, dy: 2)
                ctx.stroke(Path(roundedRect: r, cornerRadius: 4),
                           with: .color(GearPalette.verdigris.opacity(0.95)),
                           style: StrokeStyle(lineWidth: 1.6))
                // ghost atom
                let inset = cellRect(cellPos, cell, origin).insetBy(dx: cell * 0.26, dy: cell * 0.26)
                ctx.fill(Path(ellipseIn: inset), with: .color(GearPalette.element(a.element).opacity(0.22)))
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
