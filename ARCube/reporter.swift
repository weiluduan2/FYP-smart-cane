
import Foundation
import AVFoundation

import UIKit
import AudioToolbox
import Accelerate
import SceneKit
import ARKit
class Reporter {
    private var counter: Int = -1
    let voiceButtonSynthesizer = AVSpeechSynthesizer()
    let engine     = AVAudioEngine() // For Sound enable
    let playerNode = AVAudioPlayerNode() // Sound Player, for play control
    let monoFormat = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)
    var voiceUtterence = AVSpeechUtterance()
    var type : String
    var last_camera_direction = SCNVector3(0,0,1)
    // 开启counter
 
    init(type:String){
 
        self.type = type
    }
    // 更新counter的状态
    func updateCounter(status: Int, dis: Float, sceneView:ARSCNView) {
        
        var current_direction = get_camera_direction(sceneView: sceneView)
       
        
        // 如果status为1，继续计数
        if status == 0{
            resetCounter()
        }
        else if status == 1{
            counter += 1
            var direction_change = check_camera_direction(camera_direction: current_direction, last_direction:last_camera_direction)
//            if direction_change == true{
//                ///var direction_change = get_direction_change(camera_direction: current_direction, last_direction: last_camera_direction)
//
//                //report_direction(degree: direction_change)
//                
//            }
//            
            if counter % 10 == 0 || counter == 0||direction_change == true {
                report(dis:dis)
                self.counter = 0
//                if direction_change == true{
//                    resetCounter()
//                    
//                }
            }
            
            
        }
        self.last_camera_direction = current_direction
        
    
        
        
        
    }
    
    // 用于播报信息的函数
    func report_direction(degree:Float){
        let ttsContent = "角度改变" + String(degree)
       self.textToSpeechFunc(ttsContent)
    }
     func report(dis: Float) {
         if self.type == "head"{
             let ttsContent = "请小心，前方头顶" + String(dis) + "米处可能有障碍"
            self.textToSpeechFunc(ttsContent)
             
         }
         else{
             let ttsContent = "请小心，前方" + String(dis) + "米处可能有楼梯或坑洼"
            self.textToSpeechFunc(ttsContent)
         }
         
    }
    func get_camera_direction(sceneView:ARSCNView)->SCNVector3{
        if let currentFrame = sceneView.session.currentFrame {
            // 获取摄像头的变换矩阵
            let cameraTransform = currentFrame.camera.transform
            
            // 从 4x4 矩阵中提取相机的朝向向量
            let cameraOrientation = SCNVector3(-cameraTransform.columns.2.x,
                                                -cameraTransform.columns.2.y,
                                                -cameraTransform.columns.2.z)
         
            return cameraOrientation
            }
        
        return SCNVector3(0,0,0)
    }
    func textToSpeechFunc(_ speech_text: String){
        
        voiceUtterence = AVSpeechUtterance(string: speech_text)
        voiceUtterence.voice = AVSpeechSynthesisVoice(language: "zh-HK")
        voiceButtonSynthesizer.speak(voiceUtterence)
    }
    func get_direction_change(camera_direction:SCNVector3,last_direction: SCNVector3)->Float{
        

            // 获取摄像头的变换矩阵
        
            
            // 从 4x4 矩阵中提取相机的朝向向量
            let cameraOrientation = camera_direction
            
            
          

            // 计算相机朝向向量与y轴之间的角度
            let angleWithYAxis = angleBetweenVectors(vectorA: cameraOrientation, vectorB: last_direction)

            // 检查角度是否在30度到150度之间
            if angleWithYAxis >= 0 && angleWithYAxis <= 60 {
                
                return angleWithYAxis
            } else {
      
                return angleWithYAxis
            }
        
     
    }
    func check_camera_direction(camera_direction:SCNVector3,last_direction: SCNVector3)->Bool{
        

            // 获取摄像头的变换矩阵
        
            
            // 从 4x4 矩阵中提取相机的朝向向量
            let cameraOrientation = camera_direction
            
            
          

            // 计算相机朝向向量与y轴之间的角度
            let angleWithYAxis = angleBetweenVectors(vectorA: cameraOrientation, vectorB: last_direction)

            // 检查角度是否在30度到150度之间
            if angleWithYAxis >= 0 && angleWithYAxis <= 60 {
                
                return false
            } else {
      
                return true
            }
        
     
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
    // 重置counter的函数
    private func resetCounter() {
        counter = -1
    }
}
