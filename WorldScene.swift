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
    var isMounted: Bool

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
        if let pet = player.childNode(withName: "petRoot", recursively: true) {
            pet.removeFromParentNode()
            scene.rootNode.addChildNode(pet)
            context.coordinator.petNode = pet
        }
        context.coordinator.monster = monster
        context.coordinator.applyAppearance(outfit: outfit, headwear: headwear, auraStyle: auraStyle, wings: wings, mount: mount, pet: pet, mounted: isMounted)
        return view
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        guard let player = context.coordinator.player else { return }
        context.coordinator.applyAppearance(outfit: outfit, headwear: headwear, auraStyle: auraStyle, wings: wings, mount: mount, pet: pet, mounted: isMounted)
        if attackPulse != context.coordinator.lastAttackPulse {
            context.coordinator.lastAttackPulse = attackPulse
            if let monster = context.coordinator.monster {
                monster.runAction(.sequence([.scale(to: 1.12, duration: 0.08), .scale(to: 1.0, duration: 0.12)]), forKey: "hit")
                monster.childNode(withName: "body", recursively: true)?.geometry?.firstMaterial?.emission.contents = UIColor.red
                monster.runAction(.sequence([.wait(duration: 0.16), .run { node in node.childNode(withName: "body", recursively: true)?.geometry?.firstMaterial?.emission.contents = UIColor.black }]), forKey: "flash")
            }
            context.coordinator.body?.runAction(.sequence([.rotateBy(x: 0, y: 0, z: -0.75, duration: 0.08), .rotateBy(x: 0, y: 0, z: 1.25, duration: 0.12), .rotateBy(x: 0, y: 0, z: -0.5, duration: 0.08)]), forKey: "swordSwing")
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
        var petNode: SCNNode?
        var isWalking = false
        var isMounted = false
        var monster: SCNNode?
        var lastAttackPulse = 0
        var lastMonsterHit = Date.distantPast
        var lootShown = false
        var lastAppearance = ""

        func applyAppearance(outfit: String, headwear: String, auraStyle: String, wings: String, mount: String, pet: String, mounted: Bool) {
            let key = [outfit, headwear, auraStyle, wings, mount, pet, String(mounted)].joined(separator: "|")
            guard key != lastAppearance, let player = player else { return }
            lastAppearance = key
            let colors: [String: UIColor] = [
                "Tiên Y Thanh Vân": UIColor(red: 0.25, green: 0.68, blue: 0.92, alpha: 1),
                "Chiến Bào Xích Viêm": UIColor(red: 0.82, green: 0.16, blue: 0.08, alpha: 1),
                "Dạ Hành Huyền Ảnh": UIColor(red: 0.16, green: 0.12, blue: 0.28, alpha: 1),
                "Long Thần Đế Bào": UIColor(red: 0.86, green: 0.62, blue: 0.12, alpha: 1),
                "Phượng Vũ Tiên Y": UIColor(red: 0.72, green: 0.20, blue: 0.38, alpha: 1)
            ]
            player.childNode(withName: "body", recursively: true)?.geometry?.firstMaterial?.diffuse.contents = colors[outfit] ?? UIColor.systemBlue
            player.childNode(withName: "cosmeticHat", recursively: true)?.isHidden = headwear == "Không đội mũ"
            player.childNode(withName: "cosmeticMask", recursively: true)?.isHidden = headwear != "Mặt Nạ U Minh"
            player.childNode(withName: "cosmeticAura", recursively: true)?.isHidden = auraStyle == "Không có hào quang"
            let wingRoot = player.childNode(withName: "cosmeticWings", recursively: true)
            wingRoot?.isHidden = wings == "Chưa có cánh"
            player.childNode(withName: "cosmeticMount", recursively: true)?.isHidden = mount == "Chưa có thú cưỡi" || !mounted
            player.childNode(withName: "body", recursively: true)?.position.y = mounted ? 0.78 : 0.48
            player.childNode(withName: "head", recursively: true)?.position.y = mounted ? 1.34 : 1.05
            player.childNode(withName: "cosmeticHat", recursively: true)?.position.y = mounted ? 1.72 : 1.48
            player.childNode(withName: "cosmeticHat", recursively: true)?.geometry?.firstMaterial?.diffuse.contents = headwear == "Vương Miện Thiên Đế" ? UIColor.systemYellow : UIColor.cyan
            player.childNode(withName: "cosmeticAura", recursively: true)?.geometry?.firstMaterial?.emission.contents = auraStyle == "Tinh Hà Quang Hoàn" ? UIColor.systemPurple : UIColor.systemYellow
            wingRoot?.childNodes.forEach { $0.geometry?.firstMaterial?.diffuse.contents = wings == "Cửu Thiên Thần Dực" ? UIColor.systemYellow : UIColor.systemCyan }
            if let petNode = petNode {
                petNode.isHidden = pet == "Chưa có pet"
                petNode.childNode(withName: "petBody", recursively: true)?.geometry?.firstMaterial?.diffuse.contents = pet.contains("Hồ") ? UIColor.systemOrange : UIColor.systemCyan
            }
            isMounted = mounted
        }

        func updatePetFollow() {
            guard let player = player, let petNode = petNode, !petNode.isHidden else { return }
            let target = SCNVector3(player.position.x + 0.95, 0.30, player.position.z + 0.65)
            let dx = target.x - petNode.position.x
            let dz = target.z - petNode.position.z
            let distance = hypot(dx, dz)
            if distance > 0.30 {
                let step = min(0.075, distance)
                petNode.position.x += dx / max(distance, 0.001) * step
                petNode.position.z += dz / max(distance, 0.001) * step
                petNode.eulerAngles.y = atan2(-dx, -dz)
                petNode.position.y = 0.30 + (isWalking ? 0.08 : 0.02)
            }
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
        // Procedural chibi xianxia hero built from real SceneKit 3D geometry.
        let root = SCNNode()
        let skin = UIColor(red: 1.0, green: 0.78, blue: 0.66, alpha: 1)
        let navy = UIColor(red: 0.075, green: 0.16, blue: 0.36, alpha: 1)
        let blue = UIColor(red: 0.12, green: 0.34, blue: 0.72, alpha: 1)
        let gold = UIColor(red: 1.0, green: 0.70, blue: 0.20, alpha: 1)
        let paleGold = UIColor(red: 1.0, green: 0.86, blue: 0.48, alpha: 1)
        let cyan = UIColor(red: 0.22, green: 0.84, blue: 1.0, alpha: 1)
        let hairColor = UIColor(red: 0.055, green: 0.065, blue: 0.12, alpha: 1)

        func sphere(_ name: String, _ radius: CGFloat, _ color: UIColor,
                    _ position: SCNVector3, _ scale: SCNVector3 = SCNVector3(1, 1, 1)) -> SCNNode {
            let g = SCNSphere(radius: radius)
            g.segmentCount = 24
            g.firstMaterial = material(color, roughness: 0.48)
            let n = SCNNode(geometry: g); n.name = name; n.position = position; n.scale = scale
            root.addChildNode(n); return n
        }
        func box(_ name: String, _ size: (CGFloat, CGFloat, CGFloat), _ color: UIColor,
                 _ position: SCNVector3, _ bevel: CGFloat = 0.04) -> SCNNode {
            let g = SCNBox(width: size.0, height: size.1, length: size.2, chamferRadius: bevel)
            g.firstMaterial = material(color, roughness: 0.42)
            let n = SCNNode(geometry: g); n.name = name; n.position = position
            root.addChildNode(n); return n
        }
        func capsule(_ name: String, _ radius: CGFloat, _ height: CGFloat, _ color: UIColor,
                     _ position: SCNVector3, _ rotation: SCNVector3 = SCNVector3(0, 0, 0)) -> SCNNode {
            let g = SCNCapsule(capRadius: radius, height: height)
            g.firstMaterial = material(color, roughness: 0.55)
            let n = SCNNode(geometry: g); n.name = name; n.position = position; n.eulerAngles = rotation
            root.addChildNode(n); return n
        }

        // Robe silhouette, layered skirt panels and embroidered trim.
        let body = capsule("body", 0.30, 0.82, blue, SCNVector3(0, 0.51, 0))
        body.scale = SCNVector3(1.08, 1.0, 0.88)
        let skirt = sphere("robeSkirt", 0.36, navy, SCNVector3(0, 0.25, 0), SCNVector3(1.0, 0.75, 0.82))
        skirt.eulerAngles.z = .pi
        for side in [-1, 1] {
            let panel = box("robePanel_\(side)", (0.22, 0.48, 0.055), side == -1 ? blue : navy,
                            SCNVector3(Float(side) * 0.16, 0.30, 0.22), 0.035)
            panel.eulerAngles.z = Float(side) * -0.12
            box("goldHem_\(side)", (0.22, 0.045, 0.065), gold,
                SCNVector3(Float(side) * 0.16, 0.075, 0.23), 0.018)
        }
        // Large chibi head and face.
        let headNode = sphere("head", 0.32, skin, SCNVector3(0, 1.10, 0.035), SCNVector3(1.0, 1.02, 0.88))
        _ = headNode
        sphere("earL", 0.075, skin, SCNVector3(-0.30, 1.08, 0.02))
        sphere("earR", 0.075, skin, SCNVector3(0.30, 1.08, 0.02))
        // Hair cap, side locks and swept fringe.
        sphere("hairCap", 0.335, hairColor, SCNVector3(0, 1.27, -0.035), SCNVector3(1.02, 0.72, 0.92))
        for side in [-1, 1] {
            sphere("hairLock_\(side)", 0.12, hairColor,
                   SCNVector3(Float(side) * 0.255, 1.10, 0.08), SCNVector3(0.78, 1.55, 0.72))
            let bang = sphere("bang_\(side)", 0.16, hairColor,
                             SCNVector3(Float(side) * 0.12, 1.28, 0.235), SCNVector3(0.9, 0.72, 0.55))
            bang.eulerAngles.z = Float(side) * -0.28
        }
        // Big expressive eyes with irises and highlights.
        for side in [-1, 1] {
            sphere("eyeWhite_\(side)", 0.067, .white, SCNVector3(Float(side) * 0.125, 1.105, 0.309), SCNVector3(0.88, 1.15, 0.48))
            sphere("iris_\(side)", 0.040, UIColor(red: 0.12, green: 0.36, blue: 0.72, alpha: 1),
                   SCNVector3(Float(side) * 0.125, 1.105, 0.345), SCNVector3(0.9, 1.0, 0.55))
            sphere("pupil_\(side)", 0.021, .black, SCNVector3(Float(side) * 0.125, 1.105, 0.365))
            sphere("eyeSpark_\(side)", 0.010, .white, SCNVector3(Float(side) * 0.11, 1.125, 0.377))
            let brow = capsule("brow_\(side)", 0.018, 0.13, hairColor,
                               SCNVector3(Float(side) * 0.125, 1.205, 0.315),
                               SCNVector3(0, 0, Float(side) * -0.16))
            brow.scale = SCNVector3(1, 0.8, 1)
        }
        sphere("nose", 0.022, skin, SCNVector3(0, 1.045, 0.355))
        // Topknot, gold hair ornament and forehead jewel.
        capsule("topKnot", 0.075, 0.22, hairColor, SCNVector3(0, 1.52, -0.02))
        let hairPin = SCNCone(topRadius: 0.015, bottomRadius: 0.075, height: 0.22)
        hairPin.firstMaterial = material(gold, roughness: 0.28, emission: gold)
        let pin = SCNNode(geometry: hairPin); pin.position = SCNVector3(0, 1.52, 0.02); root.addChildNode(pin)
        sphere("foreheadJewel", 0.045, cyan, SCNVector3(0, 1.235, 0.327))

        // Arms, cuffs, shoulder guards, gloves and boots.
        for side in [-1, 1] {
            capsule("sleeve_\(side)", 0.115, 0.48, navy,
                    SCNVector3(Float(side) * 0.34, 0.58, 0.005),
                    SCNVector3(0, 0, Float(side) * -0.30))
            capsule("cuff_\(side)", 0.12, 0.12, gold,
                    SCNVector3(Float(side) * 0.405, 0.34, 0.025),
                    SCNVector3(0, 0, Float(side) * -0.30))
            sphere("hand_\(side)", 0.09, skin, SCNVector3(Float(side) * 0.43, 0.245, 0.08))
            let shoulder = sphere("shoulderArmor_\(side)", 0.16, gold,
                                  SCNVector3(Float(side) * 0.30, 0.79, 0.015),
                                  SCNVector3(1.0, 0.72, 0.9))
            shoulder.eulerAngles.z = Float(side) * -0.18
            sphere("shoulderGem_\(side)", 0.045, cyan, SCNVector3(Float(side) * 0.30, 0.80, 0.145))
            capsule("leg_\(side)", 0.105, 0.36, UIColor(red: 0.10, green: 0.13, blue: 0.22, alpha: 1),
                    SCNVector3(Float(side) * 0.15, 0.03, 0))
            box("boot_\(side)", (0.22, 0.14, 0.30), UIColor(red: 0.30, green: 0.17, blue: 0.11, alpha: 1),
                SCNVector3(Float(side) * 0.15, -0.16, 0.07), 0.055)
            box("bootGold_\(side)", (0.22, 0.035, 0.31), gold,
                SCNVector3(Float(side) * 0.15, -0.105, 0.07), 0.018)
        }
        // Collar, sash, belt plate and flowing back ribbons.
        let collar = SCNTorus(ringRadius: 0.19, pipeRadius: 0.045)
        collar.firstMaterial = material(paleGold)
        let collarNode = SCNNode(geometry: collar); collarNode.position.y = 0.83
        collarNode.eulerAngles.x = .pi / 2; root.addChildNode(collarNode)
        let belt = SCNTorus(ringRadius: 0.30, pipeRadius: 0.035)
        belt.firstMaterial = material(gold)
        let beltNode = SCNNode(geometry: belt); beltNode.position.y = 0.53
        beltNode.eulerAngles.x = .pi / 2; root.addChildNode(beltNode)
        box("beltPlate", (0.16, 0.18, 0.07), paleGold, SCNVector3(0, 0.53, 0.30), 0.035)
        sphere("beltGem", 0.045, cyan, SCNVector3(0, 0.54, 0.35))
        for side in [-1, 1] {
            let ribbon = box("backRibbon_\(side)", (0.12, 0.68, 0.035), blue,
                             SCNVector3(Float(side) * 0.19, 0.45, -0.25), 0.025)
            ribbon.eulerAngles.z = Float(side) * 0.18
        }
        // A stylized 3D spirit sword with blade, guard, grip and pommel.
        let blade = SCNBox(width: 0.075, height: 0.72, length: 0.035, chamferRadius: 0.018)
        blade.firstMaterial = material(cyan, roughness: 0.22, emission: cyan)
        let sword = SCNNode(geometry: blade); sword.name = "spiritSword"
        sword.position = SCNVector3(0.51, 0.55, 0.02); sword.eulerAngles.z = -0.22; root.addChildNode(sword)
        box("swordGuard", (0.28, 0.055, 0.08), gold, SCNVector3(0.51, 0.18, 0.02), 0.025)
        capsule("swordGrip", 0.035, 0.23, navy, SCNVector3(0.51, 0.04, 0.02))
        sphere("swordPommel", 0.055, paleGold, SCNVector3(0.51, -0.09, 0.02))

        let aura = SCNTorus(ringRadius: 0.52, pipeRadius: 0.025)
        aura.firstMaterial = material(cyan, roughness: 0.3, emission: cyan)
        let auraNode = SCNNode(geometry: aura); auraNode.name = "cosmeticAura"
        auraNode.eulerAngles.x = -.pi / 2; auraNode.position.y = 0.03; root.addChildNode(auraNode)
        let crown = SCNPyramid(width: 0.48, height: 0.30, length: 0.38)
        crown.firstMaterial = material(gold, roughness: 0.3, emission: gold)
        let crownNode = SCNNode(geometry: crown); crownNode.name = "cosmeticHat"
        crownNode.position = SCNVector3(0, 1.52, 0); crownNode.isHidden = true; root.addChildNode(crownNode)
        let mask = SCNBox(width: 0.38, height: 0.16, length: 0.08, chamferRadius: 0.06)
        mask.firstMaterial = material(navy)
        let maskNode = SCNNode(geometry: mask); maskNode.name = "cosmeticMask"
        maskNode.position = SCNVector3(0, 1.02, 0.28); maskNode.isHidden = true; root.addChildNode(maskNode)

        // Layered feather-like wing meshes, animated at the root.
        let wingsRoot = SCNNode(); wingsRoot.name = "cosmeticWings"
        wingsRoot.isHidden = true; root.addChildNode(wingsRoot)
        for side in [-1, 1] {
            let wingPivot = SCNNode(); wingPivot.name = "wingPivot_\(side)"
            wingPivot.position = SCNVector3(Float(side) * 0.27, 0.88, -0.22)
            wingsRoot.addChildNode(wingPivot)
            for feather in 0..<5 {
                let length = CGFloat(0.48 - Double(feather) * 0.045)
                let featherGeo = SCNSphere(radius: length * 0.5)
                featherGeo.firstMaterial = material(feather % 2 == 0 ? cyan : UIColor(red: 0.48, green: 0.58, blue: 1, alpha: 1),
                                                    roughness: 0.3, emission: cyan)
                let f = SCNNode(geometry: featherGeo)
                f.scale = SCNVector3(0.38, 1.0, 0.16)
                f.position = SCNVector3(Float(side) * (0.18 + Float(feather) * 0.075),
                                        0.20 + Float(feather) * 0.055, -0.02)
                f.eulerAngles.z = Float(side) * -0.42
                wingPivot.addChildNode(f)
            }
            wingPivot.runAction(.repeatForever(.sequence([
                .rotateBy(x: 0, y: 0, z: Float(side) * 0.18, duration: 0.42),
                .rotateBy(x: 0, y: 0, z: Float(side) * -0.18, duration: 0.42)
            ])), forKey: "wingFlap")
        }

        // Stylized qilin mount with four legs and golden horn.
        let mountRoot = SCNNode(); mountRoot.name = "cosmeticMount"
        mountRoot.isHidden = true; root.addChildNode(mountRoot)
        func mountPart(_ geometry: SCNGeometry, _ position: SCNVector3, _ name: String) {
            let n = SCNNode(geometry: geometry); n.name = name; n.position = position; mountRoot.addChildNode(n)
        }
        let mountBody = SCNSphere(radius: 0.48)
        mountBody.firstMaterial = material(UIColor(red: 0.72, green: 0.78, blue: 0.88, alpha: 1))
        let mb = SCNNode(geometry: mountBody); mb.position = SCNVector3(0, 0.32, 0.12)
        mb.scale = SCNVector3(1.25, 0.82, 1.55); mountRoot.addChildNode(mb)
        let mountHead = SCNSphere(radius: 0.25)
        mountHead.firstMaterial = material(UIColor(red: 0.82, green: 0.86, blue: 0.94, alpha: 1))
        mountPart(mountHead, SCNVector3(0, 0.62, 0.66), "qilinHead")
        let horn = SCNCone(topRadius: 0.015, bottomRadius: 0.09, height: 0.32)
        horn.firstMaterial = material(gold, roughness: 0.25, emission: gold)
        mountPart(horn, SCNVector3(0, 0.89, 0.69), "qilinHorn")
        for side in [-1, 1] {
            let ear = SCNCone(topRadius: 0.01, bottomRadius: 0.10, height: 0.24)
            ear.firstMaterial = material(UIColor.white)
            mountPart(ear, SCNVector3(Float(side) * 0.20, 0.78, 0.62), "qilinEar_\(side)")
            let eye = SCNSphere(radius: 0.035); eye.firstMaterial = material(navy, roughness: 0.2, emission: cyan)
            mountPart(eye, SCNVector3(Float(side) * 0.14, 0.65, 0.88), "qilinEye_\(side)")
            for front in [-1, 1] {
                let leg = SCNCapsule(capRadius: 0.085, height: 0.42)
                leg.firstMaterial = material(UIColor(red: 0.60, green: 0.66, blue: 0.76, alpha: 1))
                mountPart(leg, SCNVector3(Float(side) * 0.27, 0.08, Float(front) * 0.27), "qilinLeg_\(side)_\(front)")
                let hoof = SCNCylinder(radius: 0.09, height: 0.10)
                hoof.firstMaterial = material(gold)
                mountPart(hoof, SCNVector3(Float(side) * 0.27, -0.16, Float(front) * 0.27), "qilinHoof_\(side)_\(front)")
            }
        }
        mountRoot.runAction(.repeatForever(.sequence([
            .moveBy(x: 0, y: 0.045, z: 0, duration: 0.35),
            .moveBy(x: 0, y: -0.045, z: 0, duration: 0.35)
        ])), forKey: "mountIdle")

        // Little fox spirit pet with ears, eyes and a fan of tails.
        let petRoot = SCNNode(); petRoot.name = "petRoot"
        let petBody = SCNSphere(radius: 0.19)
        petBody.firstMaterial = material(UIColor(red: 0.94, green: 0.91, blue: 1, alpha: 1), roughness: 0.42)
        let petBodyNode = SCNNode(geometry: petBody); petBodyNode.name = "petBody"
        petBodyNode.scale = SCNVector3(1.0, 0.9, 1.2); petRoot.addChildNode(petBodyNode)
        let petHead = SCNSphere(radius: 0.15)
        petHead.firstMaterial = material(UIColor(red: 0.97, green: 0.95, blue: 1, alpha: 1))
        let petHeadNode = SCNNode(geometry: petHead); petHeadNode.position = SCNVector3(0, 0.14, 0.18); petRoot.addChildNode(petHeadNode)
        for side in [-1, 1] {
            let earGeo = SCNCone(topRadius: 0.01, bottomRadius: 0.075, height: 0.20)
            earGeo.firstMaterial = material(UIColor(red: 0.97, green: 0.95, blue: 1, alpha: 1))
            let ear = SCNNode(geometry: earGeo); ear.position = SCNVector3(Float(side) * 0.10, 0.29, 0.17); petRoot.addChildNode(ear)
            let eyeGeo = SCNSphere(radius: 0.018); eyeGeo.firstMaterial = material(navy)
            let eye = SCNNode(geometry: eyeGeo); eye.position = SCNVector3(Float(side) * 0.06, 0.15, 0.315); petRoot.addChildNode(eye)
            let tailGeo = SCNSphere(radius: 0.12)
            tailGeo.firstMaterial = material(cyan, roughness: 0.28, emission: cyan)
            let tail = SCNNode(geometry: tailGeo); tail.scale = SCNVector3(0.55, 0.65, 1.7)
            tail.position = SCNVector3(Float(side) * (0.10 + Float(side) * 0.035), 0.12, -0.20)
            tail.eulerAngles.x = -0.35; petRoot.addChildNode(tail)
        }
        petRoot.position = SCNVector3(0.95, 0.30, 0.65)
        root.addChildNode(petRoot)
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
