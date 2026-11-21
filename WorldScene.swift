import SwiftUI
import SceneKit

struct WorldSceneView: UIViewRepresentable {
    @Binding var moveX: CGFloat
    @Binding var moveY: CGFloat
    @Binding var attackPulse: Int
    @Binding var monsterHitPulse: Int
    @Binding var monsterDefeated: Bool
    var outfit: String
    var headwear: String
    var auraStyle: String
    var wings: String
    var mount: String
    var pet: String

    func makeUIView(context: Context) -> SCNView {
        let view = SCNView()
        let scene = SCNScene()
        view.scene = scene
        view.backgroundColor = UIColor(red: 0.08, green: 0.12, blue: 0.19, alpha: 1)
        view.allowsCameraControl = false
        view.antialiasingMode = .multisampling4X
        view.preferredFramesPerSecond = 60

        scene.rootNode.addChildNode(makeGround())
        addWorld(to: scene.rootNode)
        let monster = makeMonster()
        monster.name = "monster"
        monster.position = SCNVector3(2.2, 0, -1.8)
        scene.rootNode.addChildNode(monster)
        monster.runAction(.repeatForever(.sequence([.moveBy(x: 0, y: 0.10, z: 0, duration: 0.8), .moveBy(x: 0, y: -0.10, z: 0, duration: 0.8)])))

        let player = makePlayer()
        player.name = "player"
        player.position = SCNVector3(0, 0.65, 0)
        scene.rootNode.addChildNode(player)

        let camera = SCNCamera()
        camera.fieldOfView = 48
        let cameraNode = SCNNode()
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(0, 18, 14)
        cameraNode.eulerAngles = SCNVector3(-0.90, 0, 0)
        scene.rootNode.addChildNode(cameraNode)

        let ambient = SCNNode()
        ambient.light = SCNLight()
        ambient.light?.type = .ambient
        ambient.light?.color = UIColor(red: 0.64, green: 0.70, blue: 0.92, alpha: 1)
        scene.rootNode.addChildNode(ambient)

        let sun = SCNNode()
        sun.light = SCNLight()
        sun.light?.type = .omni
        sun.light?.intensity = 1350
        sun.light?.color = UIColor(red: 1.0, green: 0.78, blue: 0.55, alpha: 1)
        sun.position = SCNVector3(-4, 12, 6)
        scene.rootNode.addChildNode(sun)

        context.coordinator.scene = scene
        context.coordinator.player = player
        context.coordinator.body = player.childNode(withName: "body", recursively: true)
        context.coordinator.head = player.childNode(withName: "head", recursively: true)
        context.coordinator.monster = monster
        context.coordinator.applyAppearance(outfit: outfit, headwear: headwear, auraStyle: auraStyle, wings: wings, mount: mount, pet: pet)
        return view
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        guard let player = context.coordinator.player else { return }
        context.coordinator.applyAppearance(outfit: outfit, headwear: headwear, auraStyle: auraStyle, wings: wings, mount: mount, pet: pet)
        if attackPulse != context.coordinator.lastAttackPulse {
            context.coordinator.lastAttackPulse = attackPulse
            if let monster = context.coordinator.monster {
                monster.runAction(.sequence([.scale(to: 1.12, duration: 0.08), .scale(to: 1.0, duration: 0.12)]), forKey: "hit")
                monster.childNode(withName: "body", recursively: true)?.geometry?.firstMaterial?.emission.contents = UIColor.red
                monster.runAction(.sequence([.wait(duration: 0.16), .run { node in node.childNode(withName: "body", recursively: true)?.geometry?.firstMaterial?.emission.contents = UIColor.black }]), forKey: "flash")
            }
        }

        let input = hypot(moveX, moveY)
        if let monster = context.coordinator.monster, !monsterDefeated {
            let dx = player.position.x - monster.position.x
            let dz = player.position.z - monster.position.z
            let distance = hypot(dx, dz)
            if distance > 1.25 {
                let step: Float = 0.018
                monster.position.x += dx / max(distance, 0.001) * step
                monster.position.z += dz / max(distance, 0.001) * step
                monster.eulerAngles.y = atan2(dx, dz)
            } else if Date().timeIntervalSince(context.coordinator.lastMonsterHit) > 1.8 {
                context.coordinator.lastMonsterHit = Date()
                DispatchQueue.main.async { monsterHitPulse += 1 }
                monster.runAction(.sequence([.moveBy(x: 0, y: 0, z: 0.18, duration: 0.12), .moveBy(x: 0, y: 0, z: -0.18, duration: 0.12)]))
            }
        }
        if monsterDefeated && !context.coordinator.lootShown {
            context.coordinator.lootShown = true
            if let scene = context.coordinator.scene {
                let loot = SCNSphere(radius: 0.20)
                loot.firstMaterial = material(.cyan, roughness: 0.25, emission: .cyan)
                let drop = SCNNode(geometry: loot)
                drop.name = "lootDrop"
                drop.position = SCNVector3(2.2, 0.28, -1.8)
                scene.rootNode.addChildNode(drop)
                drop.runAction(.repeatForever(.sequence([.moveBy(x: 0, y: 0.16, z: 0, duration: 0.5), .moveBy(x: 0, y: -0.16, z: 0, duration: 0.5)])))
            }
        } else if !monsterDefeated && context.coordinator.lootShown {
            context.coordinator.scene?.rootNode.childNode(withName: "lootDrop", recursively: true)?.removeFromParentNode()
            context.coordinator.lootShown = false
        }
        if attackPulse != context.coordinator.lastAttackPulse {
            context.coordinator.lastAttackPulse = attackPulse
            if let body = context.coordinator.body {
                body.runAction(.sequence([.rotateBy(x: 0, y: 0, z: -0.75, duration: 0.08), .rotateBy(x: 0, y: 0, z: 1.25, duration: 0.12), .rotateBy(x: 0, y: 0, z: -0.5, duration: 0.08)]), forKey: "swordSwing")
            }
        }
        if input > 0.08 {
            let speed: Float = 0.105
            player.position.x += Float(moveX) * speed
            player.position.z += Float(moveY) * speed
            player.position.x = max(-7.5, min(7.5, player.position.x))
            player.position.z = max(-7.5, min(7.5, player.position.z))
            player.eulerAngles.y = atan2(Float(moveX), Float(moveY))
            if !context.coordinator.isWalking {
                context.coordinator.isWalking = true
                let bob = SCNAction.sequence([
                    .moveBy(x: 0, y: 0.07, z: 0, duration: 0.12),
                    .moveBy(x: 0, y: -0.07, z: 0, duration: 0.12)
                ])
                context.coordinator.body?.runAction(.repeatForever(bob), forKey: "walk")
            }
        } else if context.coordinator.isWalking {
            context.coordinator.isWalking = false
            context.coordinator.body?.removeAction(forKey: "walk")
            context.coordinator.body?.position.y = 0.48
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator {
        var scene: SCNScene?
        var player: SCNNode?
        var body: SCNNode?
        var head: SCNNode?
        var isWalking = false
        var monster: SCNNode?
        var lastAttackPulse = 0
        var lastMonsterHit = Date.distantPast
        var lootShown = false
        var lastAppearance = ""
        func applyAppearance(outfit: String, headwear: String, auraStyle: String, wings: String, mount: String, pet: String) {
            let key = [outfit, headwear, auraStyle, wings, mount, pet].joined(separator: "|")
            guard key != lastAppearance, let player = player else { return }
            lastAppearance = key
            let body = player.childNode(withName: "body", recursively: true)
            let colors: [String: UIColor] = [
                "Tiên Y Thanh Vân": UIColor(red: 0.25, green: 0.68, blue: 0.92, alpha: 1),
                "Chiến Bào Xích Viêm": UIColor(red: 0.82, green: 0.16, blue: 0.08, alpha: 1),
                "Dạ Hành Huyền Ảnh": UIColor(red: 0.16, green: 0.12, blue: 0.28, alpha: 1),
                "Long Thần Đế Bào": UIColor(red: 0.86, green: 0.62, blue: 0.12, alpha: 1),
                "Phượng Vũ Tiên Y": UIColor(red: 0.72, green: 0.20, blue: 0.38, alpha: 1)
            ]
            body?.geometry?.firstMaterial?.diffuse.contents = colors[outfit] ?? UIColor(red: 0.16, green: 0.34, blue: 0.72, alpha: 1)
            player.childNode(withName: "cosmeticHat", recursively: true)?.isHidden = headwear == "Không đội mũ"
            player.childNode(withName: "cosmeticMask", recursively: true)?.isHidden = headwear != "Mặt Nạ U Minh"
            player.childNode(withName: "cosmeticAura", recursively: true)?.isHidden = auraStyle == "Không có hào quang"
            player.childNode(withName: "cosmeticWings", recursively: true)?.isHidden = wings == "Chưa có cánh"
            player.childNode(withName: "cosmeticMount", recursively: true)?.isHidden = mount == "Chưa có thú cưỡi"
            player.childNode(withName: "cosmeticPet", recursively: true)?.isHidden = pet == "Chưa có pet"
            player.childNode(withName: "cosmeticHat", recursively: true)?.geometry?.firstMaterial?.diffuse.contents = headwear == "Vương Miện Thiên Đế" ? UIColor.systemYellow : UIColor.cyan
            player.childNode(withName: "cosmeticAura", recursively: true)?.geometry?.firstMaterial?.emission.contents = auraStyle == "Tinh Hà Quang Hoàn" ? UIColor.systemPurple : UIColor.systemYellow
            player.childNode(withName: "cosmeticWings", recursively: true)?.geometry?.firstMaterial?.diffuse.contents = wings == "Cửu Thiên Thần Dực" ? UIColor.systemYellow : UIColor.systemCyan
        }
    }

    private func material(_ color: UIColor, roughness: CGFloat = 0.85, emission: UIColor? = nil) -> SCNMaterial {
        let m = SCNMaterial()
        m.diffuse.contents = color
        m.roughness.contents = roughness
        if let emission { m.emission.contents = emission }
        return m
    }

    private func makeGround() -> SCNNode {
        let plane = SCNPlane(width: 30, height: 30)
        plane.firstMaterial = material(UIColor(red: 0.22, green: 0.28, blue: 0.25, alpha: 1))
        let node = SCNNode(geometry: plane)
        node.eulerAngles.x = -.pi / 2
        node.position.y = -0.08

        // Stone path running through the cultivation village.
        for i in -5...5 {
            let tile = SCNBox(width: 1.65, height: 0.06, length: 1.45, chamferRadius: 0.05)
            tile.firstMaterial = material(UIColor(red: 0.48, green: 0.48, blue: 0.46, alpha: 1))
            let t = SCNNode(geometry: tile)
            t.position = SCNVector3(Float(i) * 1.7, -0.015, 0)
            node.addChildNode(t)
        }
        return node
    }

    private func makePlayer() -> SCNNode {
        let root = SCNNode()

        let robe = SCNCapsule(capRadius: 0.32, height: 0.78)
        robe.firstMaterial = material(UIColor(red: 0.16, green: 0.34, blue: 0.72, alpha: 1), roughness: 0.62)
        let body = SCNNode(geometry: robe)
        body.name = "body"
        body.position.y = 0.48
        root.addChildNode(body)

        let head = SCNSphere(radius: 0.30)
        head.firstMaterial = material(UIColor(red: 1.0, green: 0.78, blue: 0.62, alpha: 1))
        let headNode = SCNNode(geometry: head)
        headNode.name = "head"
        headNode.position.y = 1.05
        root.addChildNode(headNode)

        let hair = SCNSphere(radius: 0.31)
        hair.firstMaterial = material(UIColor(white: 0.12, alpha: 1))
        let hairNode = SCNNode(geometry: hair)
        hairNode.position = SCNVector3(0, 1.20, -0.04)
        root.addChildNode(hairNode)

        let belt = SCNTorus(ringRadius: 0.30, pipeRadius: 0.045)
        belt.firstMaterial = material(UIColor(red: 0.92, green: 0.68, blue: 0.20, alpha: 1), roughness: 0.4)
        let beltNode = SCNNode(geometry: belt)
        beltNode.position.y = 0.55
        beltNode.eulerAngles.x = .pi / 2
        root.addChildNode(beltNode)

        let aura = SCNTorus(ringRadius: 0.52, pipeRadius: 0.025)
        aura.firstMaterial = material(.cyan, roughness: 0.3, emission: .cyan)
        let auraNode = SCNNode(geometry: aura)
        auraNode.eulerAngles.x = -.pi / 2
        auraNode.position.y = 0.03
        root.addChildNode(auraNode)

        let crown = SCNPyramid(width: 0.48, height: 0.30, length: 0.38)
        crown.firstMaterial = material(.systemYellow, roughness: 0.35, emission: .yellow)
        let crownNode = SCNNode(geometry: crown)
        crownNode.name = "cosmeticHat"
        crownNode.position = SCNVector3(0, 1.48, 0)
        crownNode.isHidden = true
        root.addChildNode(crownNode)

        let mask = SCNBox(width: 0.38, height: 0.16, length: 0.08, chamferRadius: 0.06)
        mask.firstMaterial = material(.black, roughness: 0.4)
        let maskNode = SCNNode(geometry: mask)
        maskNode.name = "cosmeticMask"
        maskNode.position = SCNVector3(0, 0.99, 0.27)
        maskNode.isHidden = true
        root.addChildNode(maskNode)

        let wingGeometry = SCNPlane(width: 0.68, height: 0.90)
        wingGeometry.firstMaterial = material(.cyan, roughness: 0.4, emission: .cyan)
        let wingNode = SCNNode(geometry: wingGeometry)
        wingNode.name = "cosmeticWings"
        wingNode.position = SCNVector3(0, 0.88, -0.28)
        wingNode.isHidden = true
        root.addChildNode(wingNode)

        let mountGeometry = SCNSphere(radius: 0.48)
        mountGeometry.firstMaterial = material(UIColor(red: 0.62, green: 0.52, blue: 0.36, alpha: 1))
        let mountNode = SCNNode(geometry: mountGeometry)
        mountNode.name = "cosmeticMount"
        mountNode.scale = SCNVector3(1.25, 0.65, 1.45)
        mountNode.position = SCNVector3(0, 0.30, 0.15)
        mountNode.isHidden = true
        root.addChildNode(mountNode)

        let petGeometry = SCNSphere(radius: 0.20)
        petGeometry.firstMaterial = material(.systemOrange, roughness: 0.5, emission: .orange)
        let petNode = SCNNode(geometry: petGeometry)
        petNode.name = "cosmeticPet"
        petNode.position = SCNVector3(0.85, 0.32, 0.45)
        petNode.isHidden = true
        root.addChildNode(petNode)
        return root
    }


    private func makeMonster() -> SCNNode {
        let root = SCNNode()
        let red = UIColor(red: 0.72, green: 0.16, blue: 0.12, alpha: 1)
        let dark = UIColor(red: 0.22, green: 0.10, blue: 0.10, alpha: 1)
        let gold = UIColor(red: 1.0, green: 0.72, blue: 0.22, alpha: 1)
        let body = SCNSphere(radius: 0.52)
        body.firstMaterial = material(red, roughness: 0.72)
        let bodyNode = SCNNode(geometry: body)
        bodyNode.name = "body"
        bodyNode.scale = SCNVector3(1.0, 0.92, 0.78)
        bodyNode.position.y = 0.58
        root.addChildNode(bodyNode)
        let head = SCNSphere(radius: 0.36)
        head.firstMaterial = material(red)
        let headNode = SCNNode(geometry: head)
        headNode.name = "head"
        headNode.position = SCNVector3(0, 1.18, 0.22)
        root.addChildNode(headNode)
        for side in [-1, 1] {
            let horn = SCNCone(topRadius: 0.015, bottomRadius: 0.12, height: 0.48)
            horn.firstMaterial = material(gold, roughness: 0.35, emission: gold)
            let h = SCNNode(geometry: horn)
            h.position = SCNVector3(Float(side) * 0.27, 1.48, 0.18)
            h.eulerAngles.z = Float(side) * -0.55
            root.addChildNode(h)
            let eye = SCNSphere(radius: 0.055)
            eye.firstMaterial = material(.yellow, roughness: 0.25, emission: .yellow)
            let e = SCNNode(geometry: eye)
            e.position = SCNVector3(Float(side) * 0.15, 1.22, 0.53)
            root.addChildNode(e)
            let leg = SCNCapsule(capRadius: 0.10, height: 0.42)
            leg.firstMaterial = material(dark)
            let l = SCNNode(geometry: leg)
            l.position = SCNVector3(Float(side) * 0.25, 0.20, 0)
            root.addChildNode(l)
        }
        let snout = SCNSphere(radius: 0.13)
        snout.firstMaterial = material(UIColor(red: 0.95, green: 0.48, blue: 0.38, alpha: 1))
        let snoutNode = SCNNode(geometry: snout)
        snoutNode.position = SCNVector3(0, 1.08, 0.52)
        root.addChildNode(snoutNode)
        let ring = SCNTorus(ringRadius: 0.62, pipeRadius: 0.025)
        ring.firstMaterial = material(.orange, roughness: 0.3, emission: .orange)
        let aura = SCNNode(geometry: ring)
        aura.eulerAngles.x = -.pi / 2
        aura.position.y = 0.035
        root.addChildNode(aura)
        return root
    }

    private func addWorld(to root: SCNNode) {
        // Outer rocks and cliffs.
        for x in -3...3 {
            for z in -3...3 where abs(x) == 3 || abs(z) == 3 {
                let rock = SCNBox(width: 1.2, height: 1.5, length: 1.2, chamferRadius: 0.12)
                rock.firstMaterial = material(UIColor(red: 0.30, green: 0.31, blue: 0.38, alpha: 1))
                let node = SCNNode(geometry: rock)
                node.position = SCNVector3(Float(x) * 2.5, 0.72, Float(z) * 2.5)
                root.addChildNode(node)
            }
        }

        // Pine trees, trunks and leafy crowns.
        for i in 0..<8 {
            let x = Float((i % 4) * 4 - 6)
            let z = Float((i / 4) * 10 - 5)
            let trunk = SCNCylinder(radius: 0.13, height: 1.1)
            trunk.firstMaterial = material(UIColor(red: 0.30, green: 0.18, blue: 0.10, alpha: 1))
            let trunkNode = SCNNode(geometry: trunk)
            trunkNode.position = SCNVector3(x, 0.55, z)
            root.addChildNode(trunkNode)

            let crown = SCNSphere(radius: 0.72)
            crown.firstMaterial = material(UIColor(red: 0.16, green: 0.42, blue: 0.30, alpha: 1))
            let crownNode = SCNNode(geometry: crown)
            crownNode.position = SCNVector3(x, 1.35, z)
            root.addChildNode(crownNode)
        }

        // Cultivation gate and two lantern pillars.
        for side in [-1, 1] {
            let pillar = SCNBox(width: 0.38, height: 3.0, length: 0.38, chamferRadius: 0.05)
            pillar.firstMaterial = material(UIColor(red: 0.48, green: 0.24, blue: 0.16, alpha: 1))
            let p = SCNNode(geometry: pillar)
            p.position = SCNVector3(Float(side) * 3.2, 1.5, -7.0)
            root.addChildNode(p)

            let lamp = SCNSphere(radius: 0.20)
            lamp.firstMaterial = material(.orange, roughness: 0.25, emission: .orange)
            let l = SCNNode(geometry: lamp)
            l.position = SCNVector3(Float(side) * 3.2, 2.2, -7.0)
            root.addChildNode(l)
        }
        let beam = SCNBox(width: 7.0, height: 0.42, length: 0.45, chamferRadius: 0.08)
        beam.firstMaterial = material(UIColor(red: 0.50, green: 0.25, blue: 0.16, alpha: 1))
        let beamNode = SCNNode(geometry: beam)
        beamNode.position = SCNVector3(0, 3.0, -7.0)
        root.addChildNode(beamNode)

        // Floating cultivation crystals as landmarks.
        for i in 0..<4 {
            let crystal = SCNPyramid(width: 0.55, height: 0.9, length: 0.55)
            crystal.firstMaterial = material(UIColor(red: 0.22, green: 0.78, blue: 0.88, alpha: 1), roughness: 0.25, emission: UIColor(red: 0.08, green: 0.35, blue: 0.50, alpha: 1))
            let c = SCNNode(geometry: crystal)
            c.position = SCNVector3(Float(i * 3 - 5), 0.55, 5.8)
            c.eulerAngles.y = Float(i) * 0.7
            root.addChildNode(c)
        }
    }
}
