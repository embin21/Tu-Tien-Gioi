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
        let root = SCNNode()
        let robe = SCNCapsule(capRadius: 0.30, height: 0.78)
        robe.firstMaterial = material(UIColor(red: 0.16, green: 0.34, blue: 0.72, alpha: 1), roughness: 0.62)
        let body = SCNNode(geometry: robe); body.name = "body"; body.position.y = 0.48; root.addChildNode(body)

        let head = SCNSphere(radius: 0.29); head.firstMaterial = material(UIColor(red: 1, green: 0.78, blue: 0.64, alpha: 1))
        let headNode = SCNNode(geometry: head); headNode.name = "head"; headNode.position.y = 1.05; root.addChildNode(headNode)
        let hair = SCNSphere(radius: 0.31); hair.firstMaterial = material(UIColor(white: 0.10, alpha: 1))
        let hairNode = SCNNode(geometry: hair); hairNode.position = SCNVector3(0, 1.20, -0.045); hairNode.scale = SCNVector3(1, 0.72, 1); root.addChildNode(hairNode)

        for side in [-1, 1] {
            let eye = SCNSphere(radius: 0.035); eye.firstMaterial = material(.black)
            let eyeNode = SCNNode(geometry: eye); eyeNode.position = SCNVector3(Float(side) * 0.105, 1.07, 0.265); root.addChildNode(eyeNode)
            let sleeve = SCNCapsule(capRadius: 0.105, height: 0.48); sleeve.firstMaterial = material(UIColor(red: 0.12, green: 0.28, blue: 0.62, alpha: 1))
            let arm = SCNNode(geometry: sleeve); arm.position = SCNVector3(Float(side) * 0.34, 0.55, 0); arm.eulerAngles.z = Float(side) * -0.22; root.addChildNode(arm)
            let hand = SCNSphere(radius: 0.095); hand.firstMaterial = material(UIColor(red: 1, green: 0.78, blue: 0.64, alpha: 1))
            let handNode = SCNNode(geometry: hand); handNode.position = SCNVector3(Float(side) * 0.38, 0.30, 0.02); root.addChildNode(handNode)
            let leg = SCNCapsule(capRadius: 0.12, height: 0.42); leg.firstMaterial = material(UIColor(red: 0.12, green: 0.16, blue: 0.28, alpha: 1))
            let legNode = SCNNode(geometry: leg); legNode.position = SCNVector3(Float(side) * 0.15, 0.10, 0); root.addChildNode(legNode)
            let boot = SCNBox(width: 0.22, height: 0.13, length: 0.30, chamferRadius: 0.05); boot.firstMaterial = material(UIColor(red: 0.34, green: 0.18, blue: 0.10, alpha: 1))
            let bootNode = SCNNode(geometry: boot); bootNode.position = SCNVector3(Float(side) * 0.15, -0.10, 0.06); root.addChildNode(bootNode)
        }
        let collar = SCNTorus(ringRadius: 0.19, pipeRadius: 0.05); collar.firstMaterial = material(.systemYellow)
        let collarNode = SCNNode(geometry: collar); collarNode.position.y = 0.79; collarNode.eulerAngles.x = .pi / 2; root.addChildNode(collarNode)
        let belt = SCNTorus(ringRadius: 0.30, pipeRadius: 0.045); belt.firstMaterial = material(.systemYellow)
        let beltNode = SCNNode(geometry: belt); beltNode.position.y = 0.55; beltNode.eulerAngles.x = .pi / 2; root.addChildNode(beltNode)
        let sword = SCNBox(width: 0.055, height: 0.78, length: 0.09, chamferRadius: 0.02); sword.firstMaterial = material(.cyan, roughness: 0.25, emission: .cyan)
        let swordNode = SCNNode(geometry: sword); swordNode.position = SCNVector3(0.47, 0.48, -0.05); root.addChildNode(swordNode)

        let aura = SCNTorus(ringRadius: 0.52, pipeRadius: 0.025); aura.firstMaterial = material(.cyan, roughness: 0.3, emission: .cyan)
        let auraNode = SCNNode(geometry: aura); auraNode.name = "cosmeticAura"; auraNode.eulerAngles.x = -.pi / 2; auraNode.position.y = 0.03; root.addChildNode(auraNode)
        let crown = SCNPyramid(width: 0.48, height: 0.30, length: 0.38); crown.firstMaterial = material(.systemYellow, roughness: 0.35, emission: .yellow)
        let crownNode = SCNNode(geometry: crown); crownNode.name = "cosmeticHat"; crownNode.position = SCNVector3(0, 1.48, 0); crownNode.isHidden = true; root.addChildNode(crownNode)
        let mask = SCNBox(width: 0.38, height: 0.16, length: 0.08, chamferRadius: 0.06); mask.firstMaterial = material(.black)
        let maskNode = SCNNode(geometry: mask); maskNode.name = "cosmeticMask"; maskNode.position = SCNVector3(0, 0.99, 0.27); maskNode.isHidden = true; root.addChildNode(maskNode)

        let wingsRoot = SCNNode(); wingsRoot.name = "cosmeticWings"; wingsRoot.isHidden = true; root.addChildNode(wingsRoot)
        for side in [-1, 1] {
            let wingGeo = SCNPlane(width: 0.62, height: 0.86); wingGeo.firstMaterial = material(.cyan, roughness: 0.35, emission: .cyan)
            let wing = SCNNode(geometry: wingGeo); wing.name = "wing_\(side)"
            wing.position = SCNVector3(Float(side) * 0.34, 0.88, -0.28)
            wing.eulerAngles.y = Float(side) * -0.35
            wing.eulerAngles.z = Float(side) * -0.18
            wingsRoot.addChildNode(wing)
            wing.runAction(.repeatForever(.autoreverses(.rotateBy(x: 0, y: 0, z: Float(side) * 0.62, duration: 0.42))), forKey: "wingFlap")
        }

        let mountRoot = SCNNode(); mountRoot.name = "cosmeticMount"; mountRoot.isHidden = true; root.addChildNode(mountRoot)
        let mountBody = SCNSphere(radius: 0.48); mountBody.firstMaterial = material(UIColor(red: 0.62, green: 0.52, blue: 0.36, alpha: 1))
        let mountBodyNode = SCNNode(geometry: mountBody); mountBodyNode.position = SCNVector3(0, 0.30, 0.16); mountBodyNode.scale = SCNVector3(1.3, 0.8, 1.55); mountRoot.addChildNode(mountBodyNode)
        let mountHead = SCNSphere(radius: 0.23); mountHead.firstMaterial = material(UIColor(red: 0.72, green: 0.60, blue: 0.43, alpha: 1))
        let mountHeadNode = SCNNode(geometry: mountHead); mountHeadNode.position = SCNVector3(0, 0.58, 0.70); mountRoot.addChildNode(mountHeadNode)
        for side in [-1, 1] {
            let legGeo = SCNCapsule(capRadius: 0.09, height: 0.45); legGeo.firstMaterial = material(UIColor(red: 0.38, green: 0.30, blue: 0.22, alpha: 1))
            let legNode = SCNNode(geometry: legGeo); legNode.position = SCNVector3(Float(side) * 0.28, 0.04, Float(side) * 0.12); mountRoot.addChildNode(legNode)
        }
        mountRoot.runAction(.repeatForever(.sequence([.moveBy(x: 0, y: 0.045, z: 0, duration: 0.35), .moveBy(x: 0, y: -0.045, z: 0, duration: 0.35)])), forKey: "mountIdle")

        let petRoot = SCNNode(); petRoot.name = "petRoot"
        let petBody = SCNSphere(radius: 0.19); petBody.firstMaterial = material(.systemOrange, roughness: 0.5, emission: .orange)
        let petBodyNode = SCNNode(geometry: petBody); petBodyNode.name = "petBody"; petRoot.addChildNode(petBodyNode)
        let petHead = SCNSphere(radius: 0.13); petHead.firstMaterial = material(.systemOrange)
        let petHeadNode = SCNNode(geometry: petHead); petHeadNode.position = SCNVector3(0, 0.12, 0.19); petRoot.addChildNode(petHeadNode)
        petRoot.position = SCNVector3(0.95, 0.30, 0.65); root.addChildNode(petRoot)
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
