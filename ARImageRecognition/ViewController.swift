//
//  ViewController.swift
//  ARImageRecognition
//
//  Created by cloudZon Infosoft on 23/08/18.
//  Copyright © 2018 MB. All rights reserved.
//

import UIKit
import ARKit

//https://www.appcoda.com/arkit-image-recognition/
//https://hackernoon.com/playing-videos-in-augmented-reality-using-arkit-7df3db3795b7
//https://gist.github.com/jsturgis/3b19447b304616f18657

struct MovieData:Codable {
    var description = String()
    var subtitle = String()
    var movie = String()
    var thumb = String()
    var title = String()
}

class ViewController: UIViewController {

    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var label: UILabel!
    
    var movieData = [MovieData]()
    var imageToRecognise = Set<ARReferenceImage>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.movieData = self.readJson()!
        self.loadImagesFromLink()
        
        self.configureLighting()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}


extension ViewController {
    
    @IBAction func resetButtonAction(_ sender: UIBarButtonItem) {
        self.resetTrackingConfiguration()
    }
    
    @IBAction func clearAction(_ sender: UIBarButtonItem) {
        // ME
        sceneView.scene.rootNode.enumerateChildNodes { (node, stop) in
            if node.name != nil {
                
                DispatchQueue.global(qos: .background).async {
                    // Do some background work
                    self.sceneView.session.pause()
                    node.removeFromParentNode()
                    DispatchQueue.main.async {
                        // Update the UI to indicate the work has been completed
                        self.resetTrackingConfiguration()
                    }
                }
            }
        }
    }
    
    private func configureLighting() {
        sceneView.autoenablesDefaultLighting = true
        sceneView.automaticallyUpdatesLighting = true
    }
    
    private func resetTrackingConfiguration() {
        sceneView.delegate = self
        
        self.configureLighting()
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.detectionImages = imageToRecognise
        let options: ARSession.RunOptions = [.resetTracking, .removeExistingAnchors]
        self.sceneView.session.run(configuration, options: options)
    }
    
    private func readJson() -> [MovieData]? {
        do {
            if let file = Bundle.main.url(forResource: "MovieData", withExtension: "json") {
                let data = try Data(contentsOf: file)
                let cource = try JSONDecoder().decode([MovieData].self, from: data)
                return cource
            } else {
                print("no file")
            }
        } catch {
            print(error.localizedDescription)
        }
        return nil
    }
    
    func loadImagesFromLink() {
        
        for (movieIndex, movie) in movieData.enumerated() {
            URLSession.shared.dataTask(with: URL(string: movie.thumb)!) { (data, response, error) in
                if error != nil {
                    print(error)
                    return
                }
                
                DispatchQueue.main.async(execute: { () -> Void in
                    let image = UIImage(data: data!)!
                    let referenceImage = ARReferenceImage(image.cgImage!, orientation: .up, physicalWidth: CGFloat(0.1))
                    referenceImage.name = "\(movieIndex)"
                    self.imageToRecognise.insert(referenceImage)
                    
                    if self.imageToRecognise.count >= self.movieData.count {
                        self.resetTrackingConfiguration()
                    }
                })
                }.resume()
            
        }
    }
}

extension ViewController: ARSCNViewDelegate {
    
    // https://stackoverflow.com/questions/51266352/how-to-play-local-video-when-image-is-recognized-using-arkit-in-swift
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        
        guard let imageAnchor = anchor as? ARImageAnchor else { return }
        
        let referenceImage = imageAnchor.referenceImage
        
        let width = CGFloat(referenceImage.physicalSize.width)
        let height = CGFloat(referenceImage.physicalSize.height)
        
        let videoHolder = SCNNode()
        let videoHolderGeometry = SCNPlane(width: width, height: height)
        videoHolder.transform = SCNMatrix4MakeRotation(-Float.pi / 2, 1, 0, 0)
        videoHolder.geometry = videoHolderGeometry
        videoHolder.name = referenceImage.name
        
        let movie = movieData[Int(referenceImage.name!)!]
        setupVideoOnNode(videoHolder, fromURL: URL(string:movie.movie)!)
        node.addChildNode(videoHolder)
    }
    
    func setupVideoOnNode(_ node: SCNNode, fromURL url: URL){
        
        var videoPlayerNode: SKVideoNode!
        
        let videoPlayer = AVPlayer(url: url)
        videoPlayerNode = SKVideoNode(avPlayer: videoPlayer)
        videoPlayerNode.yScale = -1
        
        let spriteKitScene = SKScene(size: CGSize(width: 600, height: 300))
        spriteKitScene.scaleMode = .aspectFit
        videoPlayerNode.position = CGPoint(x: spriteKitScene.size.width/2, y: spriteKitScene.size.height/2)
        videoPlayerNode.size = spriteKitScene.size
        spriteKitScene.addChild(videoPlayerNode)
        
        node.geometry?.firstMaterial?.diffuse.contents = spriteKitScene
        
        videoPlayerNode.play()
        videoPlayer.volume = 2
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touchLocation = touches.first?.location(in: sceneView),
            let hitNode = sceneView?.hitTest(touchLocation, options: nil).first?.node,
            let nodeName = hitNode.name else { return }
        
        for (index, node) in hitNode.childNodes.enumerated() {
            
        }
        
        print(nodeName)
    }
}
