//
//  Plane.swift
//  ARCube
//
//  Created by 张嘉夫 on 2017/7/10.
//  Copyright © 2017年 张嘉夫. All rights reserved.
//Build input file cannot be found: '/Downloads/tron_grid.png'. Did you forget to declare this file as an output of a script phase or custom build rule which produces it?
import Accelerate

import UIKit
import SceneKit
import ARKit

class Plane: SCNNode {

    var anchor: ARPlaneAnchor!
    var planeGeometry: SCNPlane!
    var planeNode:SCNNode!
    var topLeft: simd_float3! //local coordinate of plane
    var topRight:simd_float3!
    var bottomLeft:simd_float3!
    var bottomRight:simd_float3!
    var node:SCNNode!
    var parent_node:SCNNode!
    init(anchor: ARPlaneAnchor,parent_node:SCNNode) {
        super.init()
        //self.simdTransform=anchor.transform
        self.anchor = anchor
        self.parent_node=parent_node
        planeGeometry = SCNPlane(width: CGFloat(anchor.extent.x), height: CGFloat(anchor.extent.z))
        //print("plane bouding box is ",planeGeometry.boundingBox)
        // 相比把网格视觉化为灰色平面，我更喜欢用科幻风的颜色来渲染
        let material = SCNMaterial()
        material.transparency = 0.4
        material.diffuse.contents = UIColor.green
        material.diffuse.contents = UIImage(named: "tron_grid.png")
        
        //material.lightingModel = .physicallyBased
        planeGeometry.materials = [material]
        
        planeNode = SCNNode(geometry: planeGeometry)
       //planeNode.position = SCNVector3Make(anchor.center.x, anchor.center.y, anchor.center.z)
        
        planeNode.transform = SCNMatrix4MakeRotation(Float(-.pi / 2.0), 1.0, 0.0, 0.0)
        
         //planeNode.position = SCNVector3Make(anchor.transform.columns.3.x, anchor.transform.columns.3.y, anchor.transform.columns.3.z)
      
        //print("plane position is ", planeNode.position)
        //print("plane position is",planeNode.position)
        // SceneKit 里的平面默认是垂直的，所以需要旋转90度来匹配 ARKit 中的平面
        //print("node transfor beofrem is", planeNode.transform)
        
        //print("node transfor after is", planeNode.transform)
        
        //print("plane position after rotate is ", planeNode.position)
        
        let img = UIImage(named: "swift")
        if anchor.alignment == .horizontal{
            print("this is horizontal",anchor.alignment)
            let img = UIImage(named: "swift")
            material.diffuse.contents = img
            
     
        }else if anchor.alignment == .vertical {
            print("Detected a vertical plane.")
            let img = UIImage(named: "swift")
            material.diffuse.contents = img
          
            
        }
        setTextureScale()
        self.addChildNode(planeNode)
        self.update_boundary()
        
        self.addnode(x:topLeft.x,y:topLeft.y,z:topLeft.z,node:self,color:UIColor.black)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    func update_boundary(){
        let width = self.planeGeometry.width
        let height = self.planeGeometry.height
        let center = simd_float3(self.position)
        self.bottomLeft = simd_float3( -Float(width) / 2,0, Float(height) / 2) + center
        self.bottomRight = simd_float3( Float(width) / 2,0,Float(height) / 2) + center
        self.topLeft = simd_float3( -Float(width) / 2, 0,-Float(height) / 2) + center
        self.topRight = simd_float3(Float(width) / 2,0,-Float(height) / 2) + center
        
    }
    func distanceToCamera(cameraPosition:SCNVector3) -> Float {
        let anchorPosition = SCNVector3Make(self.anchor.transform.columns.3.x, self.anchor.transform.columns.3.y, self.anchor.transform.columns.3.z)

        let distance = SCNVector3Make(anchorPosition.x - cameraPosition.x, anchorPosition.y - cameraPosition.y, anchorPosition.z - cameraPosition.z)
//        print("all node information is ",anchorPosition.x ,anchorPosition.y, anchorPosition.z)
//        print("all camera information is ",cameraPosition.x ,cameraPosition.y,  cameraPosition.z)
        return sqrtf(distance.x * distance.x + distance.y * distance.y + distance.z * distance.z)
    }
    func show_local_axis(at position: SCNVector3, in sceneView: SCNView) {
        let axisLength: CGFloat = 0.2
        
        // 创建坐标轴的几何体
        let xAxis = SCNNode(geometry: SCNBox(width: axisLength, height: 0.01, length: 0.01, chamferRadius: 0))
        let yAxis = SCNNode(geometry: SCNBox(width: 0.01, height: axisLength, length: 0.01, chamferRadius: 0))
        let zAxis = SCNNode(geometry: SCNBox(width: 0.01, height: 0.01, length: axisLength, chamferRadius: 0))
        
        // 设置坐标轴的颜色
        xAxis.geometry?.firstMaterial?.diffuse.contents = UIColor.red
        yAxis.geometry?.firstMaterial?.diffuse.contents = UIColor.green
        zAxis.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
        
        // 设置坐标轴的位置
        xAxis.position = position
        yAxis.position = position
        zAxis.position = position
        
        // 添加坐标轴节点到场景中
        sceneView.scene?.rootNode.addChildNode(xAxis)
        sceneView.scene?.rootNode.addChildNode(yAxis)
        sceneView.scene?.rootNode.addChildNode(zAxis)
    }
    func check_gap(point:CGPoint,sceneView:ARSCNView){
        
//
//        self.camFx = intrinsicMartix![0][0]
//        self.camFy = intrinsicMartix![1][1]
//        self.camOx = intrinsicMartix![0][2]
//        self.camOy = intrinsicMartix![1][2]
//        self.refWidth = Float(refenceDimension!.width)
//        self.refHeight = Float(refenceDimension!.height)
//        let coord = point
//        let viewContent = sceneView.bounds
//        let xRatio = Float(coord.x / viewContent.size.width)
//        let yRatio = Float(coord.y / viewContent.size.height)
//        self.depthPixelBuffer = sceneView.session.currentFrame?.sceneDepth?.depthMap
//        let realZ = getDepth(from: depthPixelBuffer!, atXRatio: xRatio, atYRatio: yRatio)
//        let realX = (xRatio * refWidth! - camOx!) * realZ / camFx!
//        let realY = (yRatio * refHeight! - camOy!) * realZ / camFy!
//        print("real z is ",realZ)
//        let frame = sceneView.session.currentFrame
//
//            // 获取深度信息
//        let depthMap = frame?.sceneDepth?.depthMap
//
//            // 获取场景中的二维坐标
//            let scenePoint = CGPoint(x: 0, y: 0)
//
//            // 将场景二维坐标转换为深度信息坐标
//            let depthPoint = frame.displayTransform(for: sceneView.interfaceOrientation).transform(scenePoint, in: sceneView.frame.size)
//
//            // 获取深度值
//            let depthValue = depthMap.depth(at: depthPoint)
        
        
    }
    func getDepth(from depthPixelBuffer: CVPixelBuffer, atXRatio: Float, atYRatio: Float) -> Float {
        
        CVPixelBufferLockBaseAddress(depthPixelBuffer, .readOnly)
        let depthWidth = CVPixelBufferGetWidth(depthPixelBuffer)
        let depthHeight = CVPixelBufferGetHeight(depthPixelBuffer)
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

    func update(anchor: ARPlaneAnchor) {
        // 随着用户移动，平面 plane 的 范围 extend 和 位置 location 可能会更新。
        // 需要更新 3D 几何体来匹配 plane 的新参数。
        planeGeometry.width = CGFloat(anchor.extent.x);
        planeGeometry.height = CGFloat(anchor.extent.z);
        
        // plane 刚创建时中心点 center 为 0,0,0，node transform 包含了变换参数。
        // plane 更新后变换没变但 center 更新了，所以需要更新 3D 几何体的位置
        self.position = SCNVector3Make(anchor.center.x, 0, anchor.center.z)
        self.update_boundary()

        

        setTextureScale()
    }
    func show_plane_center_pixel(sceneView:ARSCNView){
        let vector=SCNVector3(x:anchor.transform.columns.3.x,y:anchor.transform.columns.3.y,z:anchor.transform.columns.3.z)
        show_pixel_coord(vector: vector, sceneView: sceneView)
    }
    func show_pixel_coord(vector:SCNVector3, sceneView: ARSCNView){
      
        let viewport = sceneView.projectPoint(vector)
        print("coordinate of center in pixel format is",viewport)
        let screenPoint = CGPoint(x: CGFloat(viewport.x), y: CGFloat(viewport.y))
        let pointView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
        pointView.backgroundColor = .red
        pointView.center = screenPoint
        pointView.layer.cornerRadius = 5
        pointView.autoresizingMask = [.flexibleTopMargin, .flexibleBottomMargin, .flexibleLeftMargin, .flexibleRightMargin]
        // 将标记点视图添加到屏幕上
        sceneView.addSubview(pointView)
    }
    func show_view_edges(sceneView: ARSCNView){
       
        
        let startPoint = CGPoint(x: CGFloat(0), y: CGFloat(0))
    
        let endPoint = CGPoint(x: CGFloat(sceneView.bounds.width), y: CGFloat(0.0))
         // 要添加的点的数量
        create_line_pixel(startPoint: startPoint, endPoint: endPoint, sceneView: sceneView)

     
    }
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

    func show_view_bouds(sceneView: ARSCNView){
       
        
        
        //let screenPoint = CGPoint(x: CGFloat(sceneView.scene.rootNode.position.x ), y: CGFloat(sceneView.scene.rootNode.position.y))
        
        let screenPoint = CGPoint(x: CGFloat(0.0), y: CGFloat(0.0))
        print("root of sceneview is ",screenPoint)
          let pointView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
        
        
          pointView.backgroundColor = .red
          pointView.center = screenPoint
          pointView.layer.cornerRadius = 5
          pointView.autoresizingMask = [.flexibleTopMargin, .flexibleBottomMargin, .flexibleLeftMargin, .flexibleRightMargin]
          // 将标记点视图添加到屏幕上
          sceneView.addSubview(pointView)
    }
        
    func showPixelLine(from startVector: SCNVector3, to endVector: SCNVector3, in sceneView: ARSCNView) {
        let startViewport = sceneView.projectPoint(startVector)
        let endViewport = sceneView.projectPoint(endVector)
        print("start view in pixel is, ",startViewport)
        print("end view in pixrel is, ",endViewport)
        print("view width and height is",sceneView.bounds.width,sceneView.bounds.height)
        
        let startPoint = CGPoint(x: CGFloat(startViewport.x), y: CGFloat(startViewport.y))
        let endPoint = CGPoint(x: CGFloat(endViewport.x), y: CGFloat(endViewport.y))
        
        let lineView = UIView(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
        lineView.backgroundColor = .red
        lineView.layer.cornerRadius = 0.5
        lineView.autoresizingMask = [.flexibleTopMargin, .flexibleBottomMargin, .flexibleLeftMargin, .flexibleRightMargin]
        
        // Calculate line's frame
        let distance = CGPoint(x: endPoint.x - startPoint.x, y: endPoint.y - startPoint.y)
        let width = hypot(distance.x, distance.y)
        let angle = atan2(distance.y, distance.x)
        
        lineView.frame = CGRect(x: startPoint.x, y: startPoint.y, width: width, height: 1)
        lineView.transform = CGAffineTransform(rotationAngle: angle)
        
        // Add the line view to the screen
        sceneView.addSubview(lineView)
    }
    
    
    /// return plane corners in world coordinate system
    func get_edges(plane:Plane) -> [simd_float3] {
        

        let width = plane.planeGeometry.width
        let height = plane.planeGeometry.height
        let center = simd_float3(0,0,0)
        var topLeft = simd_float3(self.topLeft)
        var topRight = simd_float3(self.topRight)
        var bottomLeft = simd_float3(self.bottomLeft)
        var bottomRight = simd_float3(self.bottomRight)
        
        
        topLeft=plane.parent_node.simdConvertPosition(topLeft, to: nil)
        topRight=plane.parent_node.simdConvertPosition(topRight, to: nil)
        bottomLeft = plane.parent_node.simdConvertPosition(bottomLeft, to: nil)
        bottomRight=plane.parent_node.simdConvertPosition(bottomRight, to: nil)
        //print("plane boundary nodes in world coordinate is",topLeft,topRight,bottomLeft,bottomRight)

    // Return an array of corner points
        return [topLeft, topRight, bottomLeft, bottomRight]
        }


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
//
//    func show_edges_pixel(sceneView: ARSCNView){
//        let corners = self.get_edges()
//
//        let topLeft = corners[0]
//        let topRight = corners[1]
//        let bottomLeft = corners[2]
//        let bottomRight = corners[3]
//
//        let start = SCNVector3(x:topLeft.x,y:topLeft.y,z:topLeft.z)
//        let end = SCNVector3(x:topRight.x,y:topRight.y,z:topRight.z)
//        //show_pixel_coord(vector:vector,sceneView:sceneView)
//        //showPixelLine(from:start , to: end ,in: sceneView)
//
//        let startPoint=transfer_2d_3d(vector: start, sceneView: sceneView)
//        let endPoint=transfer_2d_3d(vector: end, sceneView: sceneView)
//        print("points is",startPoint,endPoint)
//        create_line_pixel(startPoint: startPoint, endPoint: endPoint, sceneView: sceneView)
//    }
    func show_center_pixel(sceneView: ARSCNView){
        let center = anchor.center
        let world_coord=self.convertPosition(SCNVector3(center), to: nil)
        show_pixel_coord(vector: world_coord, sceneView: sceneView)
        
        
        
    }
    func show_edges_world(rootnode:SCNNode,parent:SCNNode){
        let corners = self.get_edges(plane:self)
        let topLeft = corners[0]
        let topRight = corners[1]
        let bottomLeft = corners[2]
        let bottomRight = corners[3]
        // let vector = SCNVector3(x:topLeft.x,y:topLeft.y,z:topLeft.z)
      
        
         
        for node in corners{
            print("node x y z is ",node.x,node.y,node.z)
            let vector = SCNVector3(x:node.x,y:node.y,z:node.z)
            addnode(x:node.x,y:node.y,z:node.z,node:rootnode,color:UIColor.systemPink)
            //  let node=topRight(vector:vector,sceneView:sceneView)
        }
        
    }

    
    func setTextureScale() {
        let width = planeGeometry.width
        let height = planeGeometry.height
        
        // 平面的宽度/高度 width/height 更新时，我希望 tron grid material 覆盖整个平面，不断重复纹理。
        // 但如果网格小于 1 个单位，我不希望纹理挤在一起，所以这种情况下通过缩放更新纹理坐标并裁剪纹理
        let material = planeGeometry.materials.first
        material?.diffuse.contentsTransform = SCNMatrix4MakeScale(Float(width), Float(height), 1)
        material?.diffuse.wrapS = .repeat
        material?.diffuse.wrapT = .repeat
    }
    
    func addnode(x:Float32,y:Float32,z:Float32,node:SCNNode,color:UIColor){
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
