//
//  ViewController.swift
//  ARCube
//
//  Created by 张嘉夫 on 2017/7/9.
//  Copyright © 2017年 张嘉夫. All rights reserved.
//

import UIKit
import AudioToolbox
import Accelerate
import SceneKit
import ARKit

import CoreML
class ViewController: UIViewController,ARSessionDelegate , ARSCNViewDelegate{
    var vibrationManager_ground = VibrationManager()
    var vibrationManager_head = VibrationManager()
    var vibration_ground = false {
            didSet {
                if self.vibration_ground {
                    vibrationManager_ground.startVibrating()
                } else {
                    vibrationManager_ground.stopVibrating()
                }
            }
        }
    var vibration_head = false {
            didSet {
                if self.vibration_head {
                    vibrationManager_head.startVibrating()
                } else {
                    vibrationManager_head.stopVibrating()
                }
            }
        }
    @IBOutlet weak var stop_y:UILabel!
    @IBOutlet weak var stair:UILabel!
  var ground_warning_flag = false {
            didSet {
                if self.ground_warning_flag {
                  
                    stop_y.text = "stopy = 1"
                } else {
                    stop_y.text = "stopy = 0"
                   
                }
            }
        }
    
    var floors = [UUID:Plane]()
    @IBOutlet weak var delete: UIButton!
    @IBAction func deleteButtonTapped(_ sender: UIButton) {

//        self.sceneView.session.remove(anchor: ground.anchor)
//        self.sceneView.node(for: ground.anchor)?.removeFromParentNode()
//        self.ground = nil
//        self.flags["ground_flag"] = 0
        //        let configuration = sceneView.session.configuration as? ARWorldTrackingConfiguration
        //        sceneView.session.run(configuration!,options:[.resetTracking])
//
//        self.floors = [:]
        self.ground_warning_flag = true
        self.stair.text="stair:9"

        
        
        
        
    }
    @IBOutlet weak var ground_label: UILabel!
    @IBOutlet var sceneView: ARSCNView!
    var carpet: Carpet!
    let ground_detected_distance = Float(4)
    let ground_warning_distance = Float(0.25)

    let head_warning_distance = Float(0.05)
    let head_detected_distance = Float(1.2)
    var ground: Plane!
    
    var ground_flag = 0

    var planes = [UUID:Plane]() // 字典，存储场景中当前渲染的所有平面

    var lower_planes = [UUID:Plane]()
    var stairs=[UUID:Plane]()
    var frameCapturingStartTime = CACurrentMediaTime()
    let semaphore = DispatchSemaphore(value: 2)
    
    var flags: [String: Int] = [
        "ground_flag": 0,
        "env_report_flag": 0,
        "status_change_flag":0,
        "head_flag":0,
        "ground_gap":0
    ]
    var framesDone = 0

    var request: VNCoreMLRequest!
    var colors: [UIColor] = []
    var startTimes: [CFTimeInterval] = []
    
    var setup_carpet = 0
    let voiceButtonSynthesizer = AVSpeechSynthesizer()
    let engine     = AVAudioEngine() // For Sound enable
    let playerNode = AVAudioPlayerNode() // Sound Player, for play control
    let monoFormat = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)
    var voiceUtterence = AVSpeechUtterance()
    let mylabel=UILabel()
    
    func textToSpeechFunc(_ speech_text: String){
        voiceUtterence = AVSpeechUtterance(string: speech_text)
        voiceUtterence.voice = AVSpeechSynthesisVoice(language: "zh-HK")


        voiceButtonSynthesizer.speak(voiceUtterence)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ground_label.text = "no ground"
        stop_y.text = "stopy = 0"
        stair.text = "stair:0"
        sceneView.session.delegate = self

        engine.attach(playerNode)
        engine.connect(playerNode, to: engine.mainMixerNode, format: monoFormat)
        try? engine.start()
        
        setupScene()
        
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupSession()
        
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        //sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    
    func setupScene() {
        // 设置 ARSCNViewDelegate——此协议会提供回调来处理新创建的几何体
        sceneView.delegate = self
        
        // 显示统计数据（statistics）如 fps 和 时长信息
        sceneView.showsStatistics = true
        sceneView.autoenablesDefaultLighting = true
        
        // 开启 debug 选项以查看世界原点并渲染所有 ARKit 正在追踪的特征点
        sceneView.debugOptions = [ARSCNDebugOptions.showWorldOrigin, ARSCNDebugOptions.showFeaturePoints,ARSCNDebugOptions.showBoundingBoxes]
    
        let scene = SCNScene()
        sceneView.scene = scene
    }
    
    func setupSession() {
        ground=nil
        //ground_flag = 0
        // 创建 session 配置（configuration）实例
        let configuration = ARWorldTrackingConfiguration()
        configuration.frameSemantics = .sceneDepth
       
        // 明确表示需要追踪水平面。设置后 scene 被检测到时就会调用 ARSCNViewDelegate 方法
        configuration.planeDetection = [.horizontal,.vertical ]
        

        sceneView.session.run(configuration)
        
        let ttsContent = "欢迎哂，唔該掃描吓周圍环境"
        self.textToSpeechFunc(ttsContent)
    
        


    }
    
    
    

    


    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {

        guard let anchor = anchor as? ARPlaneAnchor else {
            return
        }
        // really important,since node transfrom is nil if no anchor transform, so strange, if you know that , tell me
        let transform = anchor.transform
        node.simdTransform = transform

        let plane = Plane(anchor: anchor,parent_node: node)
        planes[anchor.identifier] = plane
        plane.node = node
        var plane_class=String(describing:plane.anchor.classification)
        
        if  plane_class=="wall" || plane_class=="floor"{


            //node.addChildNode(plane)

            if   plane_class=="floor"{
                floors[anchor.identifier] = plane
                update_ground(plane:plane,camera_position:sceneView.pointOfView?.position)
                
                

//                DispatchQueue.main.async {
//
//                    if   plane_class=="floor"{
//                        self.floor = plane
//    //                    self.test_distance(plane:plane,sceneview:self.sceneView,node:node)
////                        self.check_gap(camera_position: camera_position, plane: plane, sceneView:self.sceneView,node:node)
//                        var path = self.get_path(sceneView:self.sceneView,floor:plane,distance: 3.0)
//                        self.check_nodes_distance(node_list:path,sceneView:self.sceneView,node:node)
//
//                    }
//
//
//                    //plane.show_local_axis(at: node.position, in: self.sceneView)
//                    //plane.show_view_edges(sceneView: self.sceneView)
//                    //plane.show_view_bouds(sceneView: self.sceneView)
//                    //plane.show_plane_center_pixel(sceneView: self.sceneView)
//                    //plane.show_edges_pixel(sceneView: self.sceneView)
//                    //plane.show_edges_world(rootnode: self.sceneView.scene.rootNode,parent:node)
//
//
//
//
//                }
           
            }



  
        }
    }
    
    func check_ground(plane:Plane,camera_position:SCNVector3!) ->Bool{
        
        
        let corners = plane.get_edges(plane:plane)
        let minMaxValues = findMinMaxCoordinates(coordinates: corners)
        
        if camera_position.x > minMaxValues.minX && camera_position.x < minMaxValues.maxX && camera_position.z>minMaxValues.minZ && camera_position.z<minMaxValues.maxZ{

            return true
            
            
        }
        else{
            return false
        }
        
        
        
    }
//    func update_ground(plane:Plane,camera_position:SCNVector3!){
//        if flags["ground_flag"]==0{
//
//            if check_ground(plane: plane, camera_position: sceneView.pointOfView?.position)==true{
//                flags["ground_flag"] = 1
//                flags["status_change_flag"] = 1
//                self.ground=plane
//                DispatchQueue.main.async {
//                    self.ground_label.text="Detected ground"}
//                addplane(x: plane.anchor.transform.columns.3.x, y: plane.anchor.transform.columns.3.y, z: plane.anchor.transform.columns.3.z, node:self.sceneView.scene.rootNode, color: UIColor.red)
//                print("**********successfully initialize ground")
//
//            }
//        }
//        else{
//            if check_ground(plane: plane, camera_position: camera_position) == true{
//                print("**********successfully update ground")
//                DispatchQueue.main.async {
//                    self.ground_label.text="Detected ground"}
//                self.ground=plane
//                addplane(x: plane.anchor.transform.columns.3.x, y: plane.anchor.transform.columns.3.y, z: plane.anchor.transform.columns.3.z, node:self.sceneView.scene.rootNode, color: UIColor.red)
//            }
//        }
//    }
    func update_ground(plane:Plane,camera_position:SCNVector3!){
        if check_ground(plane: plane, camera_position: sceneView.pointOfView?.position)==true{
            
            
            if flags["ground_flag"]==0{
                flags["ground_flag"] = 1
                flags["status_change_flag"] = 1
                ////////////////////report
                self.ground=plane
                DispatchQueue.main.async {
                    var ttsContent = "成功检测地面"
                    self.textToSpeechFunc(ttsContent)
                    self.ground_label.text="Detected ground"}
                addplane(x: plane.anchor.transform.columns.3.x, y: plane.anchor.transform.columns.3.y, z: plane.anchor.transform.columns.3.z, node:self.sceneView.scene.rootNode, color: UIColor.red)
                
                print("**********successfully initialize ground")
                
            }
            
          
        }
        
    }
    func check_current_ground(camera_position:SCNVector3!){
   
        if self.ground == nil{
            self.flags["ground_flag"] = 0
            for (_,floor) in floors{
                if check_ground(plane: floor, camera_position: camera_position) == true{
                    
                    self.ground = floor
                    self.flags["ground_flag"] = 1
                    self.flags["status_change_flag"] = 1
                    DispatchQueue.main.async {
                        self.ground_label.text = "successfully detected ground"}
                    var ttsContent = "成功检测到地面"
                    self.textToSpeechFunc(ttsContent)
           
                    return
                }
            }
            DispatchQueue.main.async {
                self.ground_label.text = "Can't find ground"}
                
       
            return
        }
        else if check_ground(plane: self.ground, camera_position: camera_position) == false{
            
            if self.flags["ground_flag"] == 1{
                
                self.flags["ground_flag"] = 0
                self.flags["status_change_flag"] = 1
                DispatchQueue.main.async {
                    self.ground_label.text = "current ground is in wrong position"
                    
                    var ttsContent = "当前未检测到地面"
                    self.textToSpeechFunc(ttsContent)
                }
                
            }
            for (_,floor) in floors{
                if check_ground(plane: floor, camera_position: camera_position) == true{
                    
                    self.ground = floor
                    self.flags["ground_flag"] = 1
                    self.flags["status_change_flag"] = 1
                    DispatchQueue.main.async {
                        self.ground_label.text = "successfully detected ground"}
                    var ttsContent = "成功改变地面"
                    self.textToSpeechFunc(ttsContent)
           
                    return
                }
            }

            return
   
            
        }
        print("finish check current ground")
        return
        
    }
    
    func findMinMaxCoordinates(coordinates: [simd_float3]) -> (minX: Float, maxX: Float, minZ: Float, maxZ: Float) {
    // 确保数组不为空，否则返回默认值
    guard let firstCoord = coordinates.first else {
    return (minX: 0, maxX: 0, minZ: 0, maxZ: 0)
    }

    // 初始化最小值和最大值为数组的第一个元素的相应值
    var minX = firstCoord.x
    var maxX = firstCoord.x
    var minZ = firstCoord.z
    var maxZ = firstCoord.z

    // 遍历数组中的所有坐标
    for coord in coordinates.dropFirst() {
    if coord.x < minX {
    minX = coord.x
    } else if coord.x > maxX {
    maxX = coord.x
    }

    if coord.z < minZ {
    minZ = coord.z
    } else if coord.z > maxZ {
    maxZ = coord.z
    }
    }

    return (minX: minX, maxX: maxX, minZ: minZ, maxZ: maxZ)
    }
    func get_plane_equation(plane:Plane){
        
        let corners = plane.get_edges(plane:plane)
        var topLeft = SCNVector3(corners[0])
        var topRight = SCNVector3(corners[1])
        var bottomLeft = SCNVector3(corners[2])
        var bottomRight = SCNVector3(corners[3])
        
        
        
    }
    
    func vector_normalize(vector: SCNVector3) -> SCNVector3 {
        let length = sqrt(vector.x * vector.x + vector.y * vector.y + vector.z * vector.z)
        return SCNVector3(
            x: vector.x / length * 0.1,
            y: vector.y / length * 0.1 ,
            z: vector.z / length * 0.1
        )
    }
//    func check_gap(camera_position:simd_float3,plane:Plane,sceneView:ARSCNView,node:SCNNode){
//
//
//        let corners = plane.get_edges(plane:plane)
//        var topLeft = SCNVector3(corners[0])
//        var topRight = SCNVector3(corners[1])
//        var bottomLeft = SCNVector3(corners[2])
//        var bottomRight = SCNVector3(corners[3])
//
//
//
//        print("top left is ",topLeft)
//        print("top right is",topRight)
//        //show_pixel_coord(vector:topLeft, sceneView: sceneView)
//        //show_pixel_coord(vector:topRight, sceneView: sceneView)
//
//        var topLeft_gap = get_gap(point:topLeft,sceneView: sceneView)
//
//        var topRight_gap = get_gap(point:topRight,sceneView: sceneView)
//
//        var topLeft_gap_world = sceneView.unprojectPoint(topLeft_gap, ontoPlane: node.simdTransform)
//
//       // show_pixel_point(vector: topLeft_gap, sceneView: sceneView, color: UIColor.magenta)
//        //show_pixel_point(vector: topRight_gap, sceneView: sceneView, color: UIColor.magenta)
//
//
//        var topLeft_gap_vr = SCNVector3(Float(topLeft_gap_world!.x),topLeft_gap_world!.y,topLeft_gap_world!.z)
//        addplane(x: topLeft_gap_vr.x, y:topLeft_gap_vr.y, z: topLeft_gap_vr.z, node: sceneView.scene.rootNode, color: UIColor.white)
//        show_pixel_coord(vector: topLeft_gap_vr, sceneView: sceneView)
//        var distance_topLeft_vr = get_distance_world(sceneView: sceneView, point: topLeft_gap_vr)
//        show_point_distance(sceneView: sceneView, point: topLeft_gap_vr, distance:distance_topLeft_vr,color: UIColor.white)
//
//        var viewContent = self.sceneView.bounds.size
//
//
//        var distance_topleft_rl = constructDepthDistance(session: sceneView.session, x: Float(topLeft_gap.x), y: Float(topLeft_gap.y), viewContent: viewContent)
//        var show_dif = SCNVector3(0.1,0.1,0.1)
//        show_point_distance(sceneView: sceneView, point: subtractVectors(vector1: topLeft_gap_vr, vector2:show_dif), distance: distance_topleft_rl, color: UIColor.green)
//
//
//
//
//
//    }
    func subtractVectors(vector1: SCNVector3, vector2: SCNVector3) -> SCNVector3 {
        let result = SCNVector3(vector1.x - vector2.x, vector1.y - vector2.y, vector1.z - vector2.z)
        return result
    }
    func test_distance(plane:Plane,sceneview:ARSCNView,node:SCNNode){
        var center_rl = SCNVector3(x:plane.anchor.transform.columns.3.x,y:plane.anchor.transform.columns.3.y,z:plane.anchor.transform.columns.3.z)
        var center_pixel = transfer_2d_3d(vector: center_rl, sceneView: sceneview)
        var center = sceneView.unprojectPoint( center_pixel ,ontoPlane: node.simdTransform)

        
        
       
        var center_vr = SCNVector3(center!.x,center!.y,center!.z)
        
        

        addplane(x: center_vr.x, y:center_vr.y, z: center_vr.z, node: sceneView.scene.rootNode, color: UIColor.white)

        
        show_pixel_coord(vector: center_vr, sceneView: sceneView)
        var distance_center_vr = get_distance_world(sceneView: sceneView, point: center_vr)
        show_point_distance(sceneView: sceneView, point: center_vr, distance:distance_center_vr,color: UIColor.white)
        
        var viewContent = self.sceneView.bounds.size

        
        var distance_center_rl = constructDepthDistance(session: sceneView.session, x: Float(center_pixel.x), y: Float(center_pixel.y), viewContent: viewContent)
        var show_dif = SCNVector3(0.15,0.15,0.15)
        show_point_distance(sceneView: sceneView, point: subtractVectors(vector1: center_vr, vector2:show_dif), distance: distance_center_rl, color: UIColor.green)
        

        
        
        
    }
    func show_point_distance(sceneView: ARSCNView, point:SCNVector3, distance:Float,color:UIColor){
        var distance = (distance * 100).rounded() / 100
        let textGeometry = SCNText(string: "\(distance)", extrusionDepth: 0.05)
        textGeometry.firstMaterial?.diffuse.contents = color
        let textSize = 0.3// 文本大小
        textGeometry.font = UIFont.systemFont(ofSize: textSize)
        let textNode = SCNNode(geometry: textGeometry)
        textNode.scale = SCNVector3(textSize, textSize, textSize)
        
        textNode.position = point
        
        //textNode.rotation = SCNVector4(1, 0, 0, -Float.pi / 4.0)
        let billboardConstraint = SCNBillboardConstraint()
        billboardConstraint.freeAxes = .all // This makes the text face the camera regardless of the camera's orientation
        textNode.constraints = [billboardConstraint]
        sceneView.scene.rootNode.addChildNode(textNode)
    

//
//        addplane(x:plane.anchor.transform.columns.3.x,y:plane.anchor.transform.columns.3.y,z:plane.anchor.transform.columns.3.z,node:sceneView.scene.rootNode,color:UIColor.green)
    }
    func show_pixel_point(vector:CGPoint,sceneView:ARSCNView,color:UIColor){

        var viewport = vector
        var width=CGFloat(sceneView.bounds.width)
        var height=CGFloat(sceneView.bounds.height)
        if viewport.x<0{viewport.x=0}
        if viewport.x>width{viewport.x=width}
        if viewport.y<0{viewport.y=0}
        if viewport.y>height{viewport.y=height}
        
        
        
//        print("coordinate of center in pixel format is",viewport)
        let screenPoint = CGPoint(x: CGFloat(viewport.x), y: CGFloat(viewport.y))
        let pointView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
        pointView.backgroundColor = color
        pointView.center = screenPoint
        pointView.layer.cornerRadius = 5
        pointView.autoresizingMask = [.flexibleTopMargin, .flexibleBottomMargin, .flexibleLeftMargin, .flexibleRightMargin]
        // 将标记点视图添加到屏幕上
        sceneView.addSubview(pointView)
        
        
    }
    func get_gap(point:SCNVector3,sceneView:ARSCNView)->CGPoint{
        var startViewport=transfer_2d_3d(vector: point, sceneView: sceneView)
        startViewport.x = startViewport.x-0
        startViewport.y = startViewport.y-15

        
        var width=CGFloat(sceneView.bounds.width)
        var height=CGFloat(sceneView.bounds.height)
        
        if startViewport.x<0{startViewport.x=0}
        if startViewport.x>width{startViewport.x=width}
        if startViewport.y<0{startViewport.y=0}
        if startViewport.y>height{startViewport.y=height}
    
        return startViewport
    }
    func check_nodes_distance(node_list:[SCNVector3],sceneView:ARSCNView,type:String,show:Int)->[[Float]]{

        let viewContent = self.sceneView.bounds.size
        let show_dif = SCNVector3(0.1,0.1,0.1)
        var i = 0
        let length = node_list.count
        var dis_result = [Float](repeating: 0.0, count: length)

        // 使用这个长度创建一个浮点数向量，所有元素初始化为0.0
        var result = [Float](repeating: 0.0, count: length)

        for node in node_list{
            var node_pixel = sceneView.projectPoint(node)
            if node_pixel.x<0||node_pixel.x>Float(viewContent.width)||node_pixel.y<0||node_pixel.y>Float(viewContent.height){
                result[i] = -2
                //print("this is not in screen")
                continue
            }
            var distance_rl = constructDepthDistance(session: sceneView.session, x: node_pixel.x, y: node_pixel.y, viewContent: viewContent)
            var distance_vr = get_distance_world(sceneView: sceneView, point: node)
            if type == "ground"{
                
                if distance_rl>distance_vr+ground_warning_distance{
                    if show == 1{
                        //addplane(x: Float(node.x), y:Float(node.y), z: Float(node.z), node: sceneView.scene.rootNode, color: UIColor.white)
                        
                        //show_point_distance(sceneView: sceneView, point: node, distance:distance_vr,color: UIColor.white)
                        
                        //show_point_distance(sceneView: sceneView, point: subtractVectors(vector1: node, vector2:show_dif), distance: distance_rl, color: UIColor.green)
                        
                    }
                    
                    
                    result[i] = -1
                    dis_result[i] = distance_rl
                }
            }
            else if type == "head"{
                if distance_rl<distance_vr+head_warning_distance{
                    if show == 1{
                        addplane(x: Float(node.x), y:Float(node.y), z: Float(node.z), node: sceneView.scene.rootNode, color: UIColor.white)
                        
                        show_point_distance(sceneView: sceneView, point: node, distance:distance_vr,color: UIColor.white)
                        
                        show_point_distance(sceneView: sceneView, point: subtractVectors(vector1: node, vector2:show_dif), distance: distance_rl, color: UIColor.green)
                        
                    }
                    
                    result[i] = -1
                    dis_result[i] = distance_rl
                }
            }
            
            i = i+1
        }
        return [result,dis_result]
        //var topLeft_gap_world = sceneView.unprojectPoint(topLeft_gap, ontoPlane: node.simdTransform)
        
       // show_pixel_point(vector: topLeft_gap, sceneView: sceneView, color: UIColor.magenta)
        //show_pixel_point(vector: topRight_gap, sceneView: sceneView, color: UIColor.magenta)
        
        
//        var topLeft_gap_vr = SCNVector3(Float(topLeft_gap_world!.x),topLeft_gap_world!.y,topLeft_gap_world!.z)
//        addplane(x: topLeft_gap_vr.x, y:topLeft_gap_vr.y, z: topLeft_gap_vr.z, node: sceneView.scene.rootNode, color: UIColor.white)
//        show_pixel_coord(vector: topLeft_gap_vr, sceneView: sceneView)
//        var distance_topLeft_vr = get_distance_world(sceneView: sceneView, point: topLeft_gap_vr)
//        show_point_distance(sceneView: sceneView, point: topLeft_gap_vr, distance:distance_topLeft_vr,color: UIColor.white)
//
//
//
//
//        var distance_topleft_rl = constructDepthDistance(session: sceneView.session, x: Float(topLeft_gap.x), y: Float(topLeft_gap.y), viewContent: viewContent)
//        var show_dif = SCNVector3(0.1,0.1,0.1)
//        show_point_distance(sceneView: sceneView, point: subtractVectors(vector1: topLeft_gap_vr, vector2:show_dif), distance: distance_topleft_rl, color: UIColor.green)
//
//
//
        
        
        
        
    }
    func angleBetweenVectors(vectorA: SCNVector3, vectorB: SCNVector3) -> Float {
        // 计算两个向量的点积
        let dotProduct = vectorA.x * vectorB.x + vectorA.y * vectorB.y + vectorA.z * vectorB.z
        
        // 计算两个向量的模（长度）
        let magnitudeA = sqrt(vectorA.x * vectorA.x + vectorA.y * vectorA.y + vectorA.z * vectorA.z)
        let magnitudeB = sqrt(vectorB.x * vectorB.x + vectorB.y * vectorB.y + vectorB.z * vectorB.z)
        
        // 计算夹角的余弦值
        let cosAngle = dotProduct / (magnitudeA * magnitudeB)
        
        // 计算夹角（以弧度为单位）
        let angle = acos(cosAngle)
        
        // 将弧度转换为度数
        let angleInDegrees = angle * 180 / Float.pi
        
        return angleInDegrees
    }
    func check_camera_direction(sceneView:ARSCNView)->Bool{
        
        if let currentFrame = sceneView.session.currentFrame {
            // 获取摄像头的变换矩阵
            let cameraTransform = currentFrame.camera.transform
            
            // 从 4x4 矩阵中提取相机的朝向向量
            let cameraOrientation = SCNVector3(-cameraTransform.columns.2.x,
                                                -cameraTransform.columns.2.y,
                                                -cameraTransform.columns.2.z)
            
            
            let yAxis = SCNVector3(0, 1, 0)

            // 计算相机朝向向量与y轴之间的角度
            let angleWithYAxis = angleBetweenVectors(vectorA: cameraOrientation, vectorB: yAxis)

            // 检查角度是否在30度到150度之间
            if angleWithYAxis >= 30 && angleWithYAxis <= 150 {
                print("The camera orientation is between 30 and 150 degrees relative to the y-axis.")
                return true
            } else {
                print("The camera orientation is NOT between 30 and 150 degrees relative to the y-axis.")
                return false
            }
        }
        return false
    }
    func get_camera_direction(sceneView:ARSCNView)->SCNVector3{
       
            
            if let currentFrame = sceneView.session.currentFrame {
                // 获取摄像头的变换矩阵
                let cameraTransform = currentFrame.camera.transform
                
                // 从 4x4 矩阵中提取相机的朝向向量
                let cameraOrientation = SCNVector3(-cameraTransform.columns.2.x,
                                                    -cameraTransform.columns.2.y,
                                                    -cameraTransform.columns.2.z)
                
                
                let yAxis = SCNVector3(0, 1, 0)

                // 计算相机朝向向量与y轴之间的角度
                let angleWithYAxis = angleBetweenVectors(vectorA: cameraOrientation, vectorB: yAxis)

                // 检查角度是否在30度到150度之间
              return cameraOrientation
            }
        return SCNVector3(0,0,0)
     
        
        
    }
    // 获取待检查的点
    func get_path(sceneView:ARSCNView,ground:Plane?=nil,distance:Float,num_point:Float) -> [SCNVector3]{
        if let currentFrame = sceneView.session.currentFrame {
            // 获取摄像头的变换矩阵
            let cameraTransform = currentFrame.camera.transform

            // 从 4x4 矩阵中提取相机的朝向向量
            let cameraOrientation = SCNVector3(-cameraTransform.columns.2.x,
            -cameraTransform.columns.2.y,
            -cameraTransform.columns.2.z)
            // 从 4x4 矩阵中提取相机的位置向量
            let cameraPosition = SCNVector3(cameraTransform.columns.3.x,
            cameraTransform.columns.3.y,
            cameraTransform.columns.3.z)
            
            
            let normal_vector_right = vector_normalize(vector: SCNVector3(cameraTransform.columns.2.z,
                                           -cameraTransform.columns.2.y,
                                            -cameraTransform.columns.2.x
                                           ))
            
            var vector_length = sqrt(normal_vector_right.x * normal_vector_right.x + normal_vector_right.y * normal_vector_right.y + normal_vector_right.z * normal_vector_right.z)
 
            var path : [SCNVector3] = []
            
            
            if let ground = ground {
                var path_coor = SCNVector3(x: cameraPosition.x + distance * cameraOrientation.x,y: ground.anchor.transform.columns.3.y,z: cameraPosition.z + distance * cameraOrientation.z)
                for i in  Int (-num_point/2)..<Int (num_point/2){
                    var check_node = SCNVector3(x: path_coor.x + Float(i) * normal_vector_right.x,y: ground.anchor.transform.columns.3.y,z: path_coor.z + Float(i) * normal_vector_right.z)
                    //addplane(x: check_node.x, y: check_node.y, z:check_node.z, node: sceneView.scene.rootNode, color: UIColor.systemIndigo)
                    path.append(check_node)
                    
                    
                }
                return path
            }
            else{
                print("******************this is head detection")
                var path_coor = SCNVector3(x: cameraPosition.x + distance * cameraOrientation.x,y: cameraPosition.y,z: cameraPosition.z + distance * cameraOrientation.z)
                for i in Int (-num_point/2)..<Int (num_point/2){
                    var check_node = SCNVector3(x: path_coor.x + Float(i) * normal_vector_right.x,y: cameraPosition.y+0.2,z: path_coor.z + Float(i) * normal_vector_right.z)
                   // addplane(x: check_node.x, y: check_node.y, z:check_node.z, node: sceneView.scene.rootNode, color: UIColor.systemIndigo)
                    path.append(check_node)
                    
                    
                }
                return path
            }

            
        
    
        }
        else{
            print("no current frame detected")
            return [SCNVector3(0,0,0)]
        }
        
    }
    
    func get_distance_world(sceneView:ARSCNView,point:SCNVector3)-> Float{
        let cameraNode = sceneView.pointOfView
        let camera_position = cameraNode?.position

        
        var distance = sqrt(pow(point.x - camera_position!.x, 2) + pow(point.y - camera_position!.y, 2) + pow(point.z - camera_position!.z, 2))
        return distance
    }
    func createUIImage(from pixelBuffer: CVPixelBuffer) -> UIImage? {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext(options: nil)

        // 如果需要的话，这里可以添加一些图像处理，比如调整大小、裁剪等

        if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
        return UIImage(cgImage: cgImage)
        } else {
        return nil
        }
    }
    func constructDepthDistance(session: ARSession, x: Float, y: Float, viewContent: CGSize) -> Float {
        if let frame = session.currentFrame, let depthMap = frame.sceneDepth?.depthMap {
          
            
//            if let depthUIImage = createUIImage(from: depthMap) {
//                UIImageWriteToSavedPhotosAlbum(depthUIImage, nil, nil, nil)
//            } else {
//            print("无法从CVPixelBuffer创建UIImage。")
//            }
            
            let array_y = (Float(viewContent.width)  - x) * 192 / Float(viewContent.width)
            
            let array_x = (y ) * 256 / Float(viewContent.height)
            
            
            
            
            
            
            
            let width = CVPixelBufferGetWidth(depthMap)
            let height = CVPixelBufferGetHeight(depthMap)
            
            
            let row_index = (Float(viewContent.width)  - x) * Float(height) / Float(viewContent.width)
            let col_index = (y ) * Float(width) / Float(viewContent.height)
            
            
//            let x_index = Float(width) / Float(viewContent.width) * x
//            let y_index = Float(height) / Float(viewContent.height) * y
//
//
//            let x_ = (x / Float(viewContent.width)) * 192
//            let y_ = (y / Float(viewContent.height)) * 256
//
            
            let row_index_clamped = max(0, min(Int(height-1), Int(row_index.rounded())))
            let col_index_clamped = max(0, min(Int(width-1), Int(col_index.rounded())))
            
//            let x_ration = x / Float(viewContent.width)
//            let y_ration = y / Float(viewContent.height)
//            var depth = getDepth(from: depthMap, atXRatio: x_ration, atYRatio: y_ration)
//            print("x and y in ration is",x_ration,y_ration)
            
//            print("view content is ",viewContent)
//            print("depth map is ",width,height)
//            //
//
//
//            print("********depth data is", depthMap)
            CVPixelBufferLockBaseAddress(depthMap, CVPixelBufferLockFlags(rawValue: 0))
            
            defer {
                CVPixelBufferUnlockBaseAddress(depthMap, CVPixelBufferLockFlags(rawValue: 0))
            }
            
            if let baseAddress = CVPixelBufferGetBaseAddress(depthMap) {
                let floatBuffer = unsafeBitCast(
                    CVPixelBufferGetBaseAddress(depthMap),
                    to: UnsafeMutablePointer<Float32>.self
                )
//                var depthArray: [[Float]] = Array(repeating: Array(repeating: Float(-1), count: height), count: width)
//
//                for y in 0...height - 1 {
//                    print("height -1 and width -1is ",height-1,width-1)
//                    var distanceLine = [Float32]()
//
//                    for x in 0...width - 1 {
//                        let distanceAtXYPoint = floatBuffer[y * width + x]
//
//                        distanceLine.append(distanceAtXYPoint)
//                        print("*******depth array x y is",x,y)
//                        depthArray[x][y] = distanceAtXYPoint
//
//                    }
//                }
//
                
                
                //print(depthArray)
      
                let distanceAtXYPoint = floatBuffer[row_index_clamped * width + col_index_clamped]
//                return depthArray[x_index_clamped][y_index_clamped]
                return distanceAtXYPoint
            }
            else{return 0}
        
        }
        else {
            print("Can't find any depth")
            return 0
        }

    }
       
        
 
    /**
     使用给定 anchor 的数据更新 node 时调用。
     
     @param renderer 将会用于渲染 scene 的 renderer。
     @param node 更新后的 node。
     @param anchor 更新后的 anchor。
     */

    func getDepth(from depthPixelBuffer: CVPixelBuffer, atXRatio: Float, atYRatio: Float) -> Float {
        CVPixelBufferLockBaseAddress(depthPixelBuffer, .readOnly)
        let depthWidth = CVPixelBufferGetWidth(depthPixelBuffer)
        let depthHeight = CVPixelBufferGetHeight(depthPixelBuffer)
        print("depth data widht and height are",depthWidth,depthHeight)
        print("x y ratio are,",atXRatio,atYRatio)
        let rowData = CVPixelBufferGetBaseAddress(depthPixelBuffer)! + Int(atYRatio * Float(depthHeight)) *  CVPixelBufferGetBytesPerRow(depthPixelBuffer)
        var f16Pixel = rowData.assumingMemoryBound(to: UInt16.self)[Int(atXRatio * Float(depthWidth))]
        
        
        
        var f32Pixel = Float(0.0)
        var src = vImage_Buffer(data: &f16Pixel, height: 1, width: 1, rowBytes: 2)
        var dst = vImage_Buffer(data: &f32Pixel, height: 1, width: 1, rowBytes: 4)
        vImageConvert_Planar16FtoPlanarF(&src, &dst, 0)
        let depth = f32Pixel * 100
        CVPixelBufferUnlockBaseAddress(depthPixelBuffer, CVPixelBufferLockFlags(rawValue: 1))
        return depth
    }
    var frameCount: Int = 0
    let checkEveryFrame: UInt64 = 20
    var ini_ground : UInt64 = 0
    var ground_y = Float(0)
    

    func transfer_2d_3d(vector:SCNVector3,sceneView: ARSCNView)->CGPoint{
   
        var startViewport = sceneView.projectPoint(vector)
        var width=Float(sceneView.bounds.width)
        var height=Float(sceneView.bounds.height)
        
        if startViewport.x<0{startViewport.x=0}
        if startViewport.x>width{startViewport.x=width}
        if startViewport.y<0{startViewport.y=0}
        if startViewport.y>height{startViewport.y=height}
        
        
        let startPoint = CGPoint(x: CGFloat(startViewport.x), y: CGFloat(startViewport.y))
        return startPoint
        
        
    }
    
//     func show_edges_pixel(sceneView: ARSCNView,plane:Plane,parent:SCNNode){
//         let corners = get_edges(plane: plane, parent: parent)
//
//         let topLeft = corners[0]
//         let topRight = corners[1]
//         let bottomLeft = corners[2]
//         let bottomRight = corners[3]
//
//         let start = SCNVector3(x:topLeft.x,y:topLeft.y,z:topLeft.z)
//         let end = SCNVector3(x:topRight.x,y:topRight.y,z:topRight.z)
//         //show_pixel_coord(vector:vector,sceneView:sceneView)
//         //showPixelLine(from:start , to: end ,in: sceneView)
//
//         let startPoint=transfer_2d_3d(vector: start, sceneView: sceneView)
//         let endPoint=transfer_2d_3d(vector: end, sceneView: sceneView)
//         print("points is",startPoint,endPoint)
//         create_line_pixel(startPoint: startPoint, endPoint: endPoint, sceneView: sceneView)
//     }
    func create_line_pixel(startPoint: CGPoint,endPoint: CGPoint,sceneView: ARSCNView){
        let numberOfPoints = 10
            
        let dx = (endPoint.x - startPoint.x) / CGFloat(numberOfPoints + 1)
        let dy = (endPoint.y - startPoint.y) / CGFloat(numberOfPoints + 1)
        for i in 1 ... numberOfPoints{
            let x = startPoint.x + CGFloat(i) * dx
            let y = startPoint.y + CGFloat(i) * dy
            let pointView = UIView(frame: CGRect(x: 0, y: 0, width: 7, height: 7))
            let screenPoint = CGPoint(x: CGFloat(x), y: CGFloat(y))
            pointView.backgroundColor = .purple
            
            pointView.center = screenPoint
            pointView.layer.cornerRadius = 5
            pointView.autoresizingMask = [.flexibleTopMargin, .flexibleBottomMargin, .flexibleLeftMargin, .flexibleRightMargin]
            sceneView.addSubview(pointView)
        }
    }

    func show_pixel_coord(vector:SCNVector3, sceneView: ARSCNView){
 
        var viewport = sceneView.projectPoint(vector)
        
        var width=Float(sceneView.bounds.width)
        var height=Float(sceneView.bounds.height)
        if viewport.x<0{viewport.x=0}
        if viewport.x>width{viewport.x=width}
        if viewport.y<0{viewport.y=0}
        if viewport.y>height{viewport.y=height}
        
        
        
//        print("coordinate of center in pixel format is",viewport)
        let screenPoint = CGPoint(x: CGFloat(viewport.x), y: CGFloat(viewport.y))
        let pointView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
        pointView.backgroundColor = .red
        pointView.center = screenPoint
        pointView.layer.cornerRadius = 5
        pointView.autoresizingMask = [.flexibleTopMargin, .flexibleBottomMargin, .flexibleLeftMargin, .flexibleRightMargin]
        // 将标记点视图添加到屏幕上
        sceneView.addSubview(pointView)
    }
    func show_center_pixel(sceneView: ARSCNView,node:SCNNode,anchor:ARPlaneAnchor){
        let center = anchor.center
        let world_coord=node.convertPosition(SCNVector3(0,0,0), to: nil)
        show_pixel_coord(vector: world_coord, sceneView: sceneView)
        
        
        
    }
    func show_plane_center(plane:Plane){
        let plane_class=String(describing:plane.anchor.classification)
        
        if plane_class=="wall"{
            let textGeometry = SCNText(string: "\(plane.anchor.classification.self)", extrusionDepth: 0.1)
            textGeometry.firstMaterial?.diffuse.contents = UIColor.white
            let textSize = 0.2 // 文本大小
            textGeometry.font = UIFont.systemFont(ofSize: textSize)
            let textNode = SCNNode(geometry: textGeometry)
            textNode.scale = SCNVector3(textSize, textSize, textSize)
            textNode.position = SCNVector3(0,0, 0)
            
            textNode.rotation = SCNVector4(1, 0, 0, -Float.pi / 2.0)
            plane.addChildNode(textNode)
        }
        else{
            let textGeometry = SCNText(string: "\(plane.anchor.classification.self)", extrusionDepth: 0.1)
            textGeometry.firstMaterial?.diffuse.contents = UIColor.white
            let textSize = 0.2 // 文本大小
            textGeometry.font = UIFont.systemFont(ofSize: textSize)
            let textNode = SCNNode(geometry: textGeometry)
            textNode.scale = SCNVector3(textSize, textSize, textSize)
            textNode.position = SCNVector3(0,0, 0)
           
            textNode.rotation = SCNVector4(1, 0, 0, -Float.pi / 4)//
            plane.addChildNode(textNode)
        }
//
//        addplane(x:plane.anchor.transform.columns.3.x,y:plane.anchor.transform.columns.3.y,z:plane.anchor.transform.columns.3.z,node:sceneView.scene.rootNode,color:UIColor.green)

        addplane(x:0,y:0,z:0,node:plane,color:UIColor.green)
    }
    func show_distance(plane:Plane,distance:Float){

        
        
            let textGeometry = SCNText(string: "\(distance)", extrusionDepth: 0.1)
            textGeometry.firstMaterial?.diffuse.contents = UIColor.black
            let textSize = 0.2 // 文本大小
            textGeometry.font = UIFont.systemFont(ofSize: textSize)
            let textNode = SCNNode(geometry: textGeometry)
            textNode.scale = SCNVector3(textSize, textSize, textSize)
            textNode.position = SCNVector3(0,0, 0)
            
            textNode.rotation = SCNVector4(1, 0, 0, -Float.pi / 2.0)
            plane.addChildNode(textNode)
        
 
//
//        addplane(x:plane.anchor.transform.columns.3.x,y:plane.anchor.transform.columns.3.y,z:plane.anchor.transform.columns.3.z,node:sceneView.scene.rootNode,color:UIColor.green)

        addplane(x:0,y:0,z:0,node:plane,color:UIColor.purple)
    }
    func sortPlanesByDistance(planes: [UUID: Plane], cameraPosition: SCNVector3) -> [Plane] {
        let sortedPlanes = planes.values.sorted { (plane1, plane2) -> Bool in
            let distance1 = plane1.distanceToCamera(cameraPosition: cameraPosition)
            let distance2 = plane2.distanceToCamera(cameraPosition: cameraPosition)
            return distance1 < distance2
        }
        return sortedPlanes
    }
    func checkLower(planes: [UUID: Plane], ground_y:Float) -> [UUID: Plane]? {
        var lowerPlanes: [UUID: Plane] = [:]
        
        for (id, plane) in planes {
            let planeHeight = plane.anchor.transform.columns.3.y
            
            if planeHeight < ground_y && plane.anchor.alignment == .horizontal {
                lowerPlanes[id] = plane
                print("there is a lower layer",plane.anchor.transform.columns.3.y)
                addplane(x: plane.anchor.transform.columns.3.x, y: plane.anchor.transform.columns.3.y, z: plane.anchor.transform.columns.3.z, node:sceneView.scene.rootNode , color: UIColor.magenta)
            }
        }
        
        return lowerPlanes.isEmpty ? nil : lowerPlanes
    }
    func lowestPlane(planes: [UUID: Plane]) -> Plane? {
        var lowestHeight: Float = Float.greatestFiniteMagnitude
        var ground: Plane?
        
        for (_, plane) in planes {
            let planeHeight = plane.anchor.transform.columns.3.y
            
            if planeHeight < lowestHeight && plane.anchor.alignment == .horizontal {
                lowestHeight = planeHeight
                
                ground = plane
            }
        }
        
        return ground
    }

     
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        // 如果多个独立平面被发现共属某个大平面，此时会合并它们，并移除这些 node
        self.planes.removeValue(forKey: anchor.identifier)
        
    }
    

    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let plane = planes[anchor.identifier] else {
            return
        }
        
        plane.update(anchor: anchor as! ARPlaneAnchor)
        
        var plane_class = String(describing:plane.anchor.classification)
//        if plane_class=="floor"{
//            node.addChildNode(plane)
//            update_ground(plane: plane, camera_position: sceneView.pointOfView?.position)
//            
//        }
   
        
        
//        if  plane_class=="wall" || plane_class=="floor"{
            
            //plane.show_edges_world(rootnode: sceneView.scene.rootNode, parent: node)}
        
        
    }


    var check_current_ground_frame = 50
    var check_head_frame = 50
    var check_ground_frame = 60
    var delet_frame = 500
    var report_head = 500
    var head_reporter = Reporter(type:"head")
    var check_carpet_frame = 20
    var carpet_counter = 20
    var ground_reporter = Reporter(type:"ground")
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        if setup_carpet == 0 {
            carpet = Carpet(sceneView: sceneView,ground:ground,stop_y: ground_warning_flag)
            
            setup_carpet = 1
        }
        else{
            DispatchQueue.main.async {
                self.carpet.update_carpet(ground:self.ground,stop_y:self.ground_warning_flag)
              
            }
            
            
        }
        
        if Int(frameCount) % check_current_ground_frame == 0{
            self.check_current_ground(camera_position: self.sceneView.pointOfView?.position)
            
        }
        frameCount += 1
//        if Int(frameCount) % delet_frame == 0{
//            for (uuid,plane) in floors{
//                session.remove(anchor: plane.anchor)
//
//
//
//            }
//            DispatchQueue.main.async {
//
//
//                self.ground_label.text = "Clear all floors"
//            }
//
//        }
        if frameCount >= 100000{
            frameCount = 0
        }
       // if ground_flag==0 {return}
//        if frameCount % check_carpet_frame == 0{
//            DispatchQueue.main.async{
//                self.carpet.drop()
//            }
//   
//        }
        // check head obstacle
        if frameCount % check_head_frame == 0{
            if check_camera_direction(sceneView: sceneView) == true{
                DispatchQueue.main.async {
                    
                    var path = self.get_path(sceneView:self.sceneView,ground:nil,distance: self.head_detected_distance,num_point: 4)
                    var head_result = self.check_nodes_distance(node_list:path,sceneView:self.sceneView,type:"head",show:1)
                    print("check result is ",head_result)
                    var head_warning =  head_result[0].filter { $0 == -1 }.count
                    if head_warning>0{
                        let nonZeroNumbers = head_result[1].filter { $0 != 0 }
                        
                        // 计算非零元素的个数
                        let count = Float(nonZeroNumbers.count)
                        
                        // 确保非零元素的个数不为零来避免除以零的错误
                        
                        // 使用 reduce 方法累加筛选出的非零元素
                        let sum = nonZeroNumbers.reduce(0, +)
                        // 计算平均数
                        let average = sum / count
                        
                        var warning_position = average
                        warning_position = (warning_position * 10).rounded() / 10
                        
                        
                       
                        self.head_reporter.updateCounter(status: 1, dis: warning_position,sceneView: self.sceneView)
                        
                        self.vibrationManager_head.updateVibrationInterval(0.5 * Double(warning_position))
                        self.vibration_head = true
                        

                    }
                    else{
                        self.vibration_head = false
                        self.head_reporter.updateCounter(status: 0, dis: 0.00,sceneView: self.sceneView)
                    }
                    
                    
                }
            }
            else{
                self.vibration_head = false
                self.head_reporter.updateCounter(status: 0, dis: 0.00,sceneView: self.sceneView )
            }
                
            
            
            
        }
        // check whether ground is wrong
        if ground_warning_flag {
            DispatchQueue.main.async{
                self.carpet.drop()
                var num_stair = self.carpet.count_stairs()
                self.stair.text = "stairs: \(num_stair)"
            }
            
        }
        else{
            DispatchQueue.main.async{
                self.carpet.reset_stairs()
                self.stair.text = "stairs:0"}
            
        }
        if frameCount % check_ground_frame == 0{

            DispatchQueue.main.async {
                self.check_current_ground(camera_position:self.sceneView.pointOfView?.position)
   
                if self.flags["ground_flag"]==1{
                    
                    var path = self.get_path(sceneView:self.sceneView,ground:self.ground,distance: self.ground_detected_distance,num_point: 16)
                    var ground_result = self.check_nodes_distance(node_list:path,sceneView:self.sceneView,type:"ground",show:0)
                    
                    var ground_warning =  ground_result[0].filter { $0 == -1 }.count
                   
                    if ground_warning>0{
                        
                        var warning_position = self.get_warning_position(sceneView: self.sceneView, ground:self.ground,distance: self.ground_detected_distance, num_point: 8)
                        
                        
    
                        self.ground_reporter.updateCounter(status: 1, dis: warning_position,sceneView: self.sceneView)
                        
                        self.vibrationManager_ground.updateVibrationInterval(0.1 * Double(warning_position))
                        self.vibration_ground = true
                        self.ground_warning_flag = true
                    }
                    else{
                        self.ground_warning_flag = false
                        self.vibration_ground = false
                        self.ground_reporter.updateCounter(status: 0, dis: 0.00,sceneView: self.sceneView)
                    }
                }
                else{
                    self.ground_warning_flag = false
                    self.vibration_ground = false
                    self.ground_reporter.updateCounter(status: 0, dis: 0.00,sceneView: self.sceneView)
                }
            }
            
        }
        else{
            //self.vibration_ground = false
            //self.ground_warning_flag = 0
            self.ground_reporter.updateCounter(status: 0, dis: 0.00,sceneView: self.sceneView)
        }
            
        
        
        
        

    }
    

    func get_warning_position(sceneView:ARSCNView,ground:Plane?=nil,distance:Float,num_point:Float)->Float{
       
            var far_distance = distance
            var near_distance = Float(0)
            


            
            for i in 0...8{
                
                
                var middle = (far_distance + near_distance) / 2
                var path = get_path(sceneView:sceneView,ground:ground,distance: middle,num_point: num_point)
               
                var result = check_nodes_distance(node_list:path,sceneView:sceneView,type:"ground",show:0)
                if i == 7{
                    result = check_nodes_distance(node_list:path,sceneView:sceneView,type:"ground",show:1)
                }
                
                var warning =  result[0].filter { $0 == -1 }.count
                
                if warning > 0{
                    far_distance = middle
                    
                }
                else{
                    near_distance = middle
                }
                if far_distance<=near_distance{
                    break
                }
                

                
                
            }
            var warning_posi = (far_distance+near_distance)/2
            warning_posi = (warning_posi * 10).rounded() / 10
            return warning_posi
        
       
        

        
     
        
    }

    func vibrateFunc(_ inputIntent: Float){
        // let minValueForHaptic: Float = inputIntent
        let feedbackGenerator: UIImpactFeedbackGenerator = UIImpactFeedbackGenerator(style: .heavy)
        let intensity: CGFloat = CGFloat(1.0 - inputIntent)
        feedbackGenerator.impactOccurred(intensity: intensity * 1.1)
    }
    
    func addplane(x:Float32,y:Float32,z:Float32,node:SCNNode,color:UIColor){
        let plane1 = SCNPlane(width: 0.3, height: 0.1)
        let planeNode = SCNNode(geometry: plane1)
        //guard let cameraNode = sceneView.pointOfView else {
            //return
        //}

        let position = SCNVector3(x: 0, y: 0, z: 0)
        //let cameraPosition = cameraNode.position
        //let planeCenterInCameraSpace = sceneView.scene.rootNode.convertPosition(position , to: cameraNode)
        //planeNode.position = planeCenterInCameraSpace
        planeNode.position=position
        //print("position of world is *****",sceneView.scene.rootNode.position)
        //print("position of camera is *****",cameraNode.position)
        //print("position of plane is *****",planeNode.position)
     
        planeNode.eulerAngles=SCNVector3(0 ,Float.pi / 4, Float.pi / 4)
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.blue.withAlphaComponent(0.5) // Blue with some transparency
        let img = UIImage(named: "fabric")
        material.diffuse.contents = img
        material.lightingModel = .physicallyBased
        plane1.materials = [material]// Adjust the position as needed
        let plane2 = SCNPlane(width: 0.2, height: 0.23)
        let planeNode2 = SCNNode(geometry: plane2)
        planeNode2.position = SCNVector3(x: 0, y: 0.6, z: 0)
        plane2.materials = [material]
        
        
        let sphere = SCNSphere(radius: 0.02)
        let materia_sph = SCNMaterial()
        materia_sph.diffuse.contents = color
        sphere.materials = [materia_sph]

            // Create a node for the sphere and position it at the center of the plane
        let centerNode = SCNNode(geometry: sphere)
        centerNode.position = SCNVector3(x,y,z)

        node.addChildNode(centerNode)
        //sceneView.scene.rootNode.addChildNode(centerNode2)
        
        
    }
}

