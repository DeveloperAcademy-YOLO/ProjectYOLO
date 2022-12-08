//
//  CardCreateViewController.swift
//  RollingPaper
//
//  Created by Yosep on 2022/10/05.
//

import AVFoundation
import Combine
import PencilKit
import PhotosUI
import IRSticker_swift
import SnapKit
import UIKit

class CardCreateViewController: UIViewController, UINavigationControllerDelegate, PKCanvasViewDelegate, PKToolPickerObserver {
    private let arrStickers: [String]
    private let backgroundImageName: [String]
    private let viewModel: CardViewModel
    private let toolPicker = PKToolPicker()
    private let input: PassthroughSubject<CardViewModel.Input, Never> = .init()
    
    private var stickerCount: Int = 0
    private var cancellables = Set<AnyCancellable>()
    private var backgroundImg: UIImage?
    
    private var animator: UIDynamicAnimator?
    private var selectedSticker: IRStickerView?
    private var isCanvasToolToggle: Bool = true
    
    private var isStickerToggle: Bool = false
    private var imageSticker: UIImage!
    
    private let imageShadowView: UIView = {
        let shadowUIView = UIView()
        shadowUIView.layer.shadowOffset = CGSize(width: 3, height: 3)
        shadowUIView.layer.shadowOpacity = 0.2
        shadowUIView.layer.shadowRadius = 30.0
        shadowUIView.backgroundColor = .systemBackground
        shadowUIView.layer.cornerRadius = 60
        shadowUIView.layer.shadowColor = UIColor.black.cgColor
        shadowUIView.translatesAutoresizingMaskIntoConstraints = false
        return shadowUIView
    }()
    
    lazy var rootUIImageView: UIImageView = {
        let theImageView = UIImageView()
        theImageView.isUserInteractionEnabled = true
        return theImageView
    }()
    
    lazy var canvasView: PKCanvasView = {
        let canvas = PKCanvasView(frame: .zero)
        canvas.delegate = self
        canvas.layer.masksToBounds = true
        canvas.layer.cornerRadius = 32
        canvas.contentMode = .scaleAspectFill
        canvas.isOpaque = false
        canvas.alwaysBounceVertical = true
        canvas.drawingPolicy = .anyInput
        canvas.translatesAutoresizingMaskIntoConstraints = true
        canvas.becomeFirstResponder()
        return canvas
    }()
    
    lazy var someImageView: UIImageView = {
        let theImageView = UIImageView()
        theImageView.translatesAutoresizingMaskIntoConstraints = false
        theImageView.layer.masksToBounds = true
        theImageView.layer.cornerRadius = 32
        theImageView.contentMode = .scaleAspectFill
        theImageView.image = backgroundImg
        let tapRecognizer = UITapGestureRecognizer.init(target: self, action: #selector(tapBackground(recognizer:)))
        tapRecognizer.numberOfTapsRequired = 1
        theImageView.addGestureRecognizer(tapRecognizer)
        return theImageView
    }()
    
    lazy var collectionView: UICollectionView = {
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 100)
        layout.itemSize = CGSize(width: 100, height: 80)
        layout.scrollDirection = .horizontal
        
        let setCollectionView: UICollectionView = UICollectionView(frame: self.view.frame, collectionViewLayout: layout)
        setCollectionView.dataSource = self
        setCollectionView.delegate = self
        setCollectionView.register(StickerCollectionViewCell.self, forCellWithReuseIdentifier: "StickerCollectionViewCell")
        setCollectionView.backgroundColor = .systemBackground
        setCollectionView.showsHorizontalScrollIndicator = false
        setCollectionView.translatesAutoresizingMaskIntoConstraints = false
        setCollectionView.layer.masksToBounds = true
        setCollectionView.layer.cornerRadius = 60
        return setCollectionView
    }()
    
    lazy var buttonLabel: UILabel = {
        let label = UILabel()
        label.backgroundColor = .systemBackground
        label.layer.masksToBounds = true
        label.layer.cornerRadius = 30
        label.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        return label
    }()
    
    lazy var introWordingLabel: UILabel = {
        let label = UILabel()
        
        let attributedString = NSMutableAttributedString(string: "")
        let cameraImageAttachment = NSTextAttachment()
        let paletteImageAttachment = NSTextAttachment()
        cameraImageAttachment.image = UIImage(systemName: "camera.fill")
        paletteImageAttachment.image = UIImage(systemName: "paintpalette.fill")
        cameraImageAttachment.bounds = CGRect(x: 0, y: -10, width: 50, height: 40)
        paletteImageAttachment.bounds = CGRect(x: 0, y: -10, width: 45, height: 40)
        attributedString.append(NSAttributedString(attachment: cameraImageAttachment))
        attributedString.append(NSAttributedString(string: "와  "))
        attributedString.append(NSAttributedString(attachment: paletteImageAttachment))
        attributedString.append(NSAttributedString(string: "을 눌러 배경을 채워주세요."))
        
        label.attributedText = attributedString
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 30)
        label.textColor = .lightGray
        return label
    }()
    
    lazy var cameraOnButton: UIButton = {
        let button = UIButton()
        button.setUIImage(systemName: "camera.fill")
        button.tintColor = .black
        return button
    }()
    
    lazy var cameraOffButton: UIButton = {
        let button = UIButton()
        button.setUIImage(systemName: "camera.fill")
        button.tintColor = UIColor(red: 217, green: 217, blue: 217)
        button.addTarget(self, action: #selector(importImage(_:)), for: .touchUpInside)
        return button
    }()
    
    lazy var backgroundOnButton: UIButton = {
        let button = UIButton()
        button.setUIImage(systemName: "paintpalette.fill")
        button.tintColor = .black
        return button
    }()
    
    lazy var backgroundOffButton: UIButton = {
        let button = UIButton()
        button.setUIImage(systemName: "paintpalette.fill")
        button.tintColor = UIColor(red: 217, green: 217, blue: 217)
        button.addTarget(self, action: #selector(setPopOverView(_:)), for: .touchUpInside)
        return button
    }()
    
    lazy var divider: UILabel = {
        let label = UILabel()
        label.backgroundColor = UIColor(red: 217, green: 217, blue: 217)
        return label
    }()
    
    lazy var pencilOnButton: UIButton = {
        let button = UIButton()
        button.setUIImage(systemName: "pencil.and.outline")
        button.tintColor = .black
        return button
    }()
    
    lazy var pencilOffButton: UIButton = {
        let button = UIButton()
        button.setUIImage(systemName: "pencil.and.outline")
        button.tintColor = UIColor(red: 217, green: 217, blue: 217)
        button.addTarget(self, action: #selector(togglebutton(_:)), for: .touchUpInside)
        return button
    }()
    
    lazy var stickerOnButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "StickerToggleOn"), for: .normal)
        button.setImage(UIImage(named: "StickerToggleOn"), for: .highlighted)
        return button
    }()
    
    lazy var stickerOffButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "StickerToggleOff"), for: .normal)
        button.setImage(UIImage(named: "StickerToggleOff"), for: .highlighted)
        button.addTarget(self, action: #selector(togglebutton(_:)), for: .touchUpInside)
        return button
    }()
    
    init(viewModel: CardViewModel, arrStickers: [String], backgroundImageName: [String]) {
        self.viewModel = viewModel
        self.arrStickers = arrStickers
        self.backgroundImageName = backgroundImageName
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGray6
        
        view.addSubview(rootUIImageView)
        rootUIImageViewConstraints()
        
        introWordingAppear()
        
        rootUIImageView.addSubview(someImageView)
        someImageViewConstraints()
        
        rootUIImageView.addSubview(canvasView)
        canvasViewConstraints()
        
        view.addSubview(buttonLabel)
        buttonLabelConstraints()
        
        cameraOffButtonAppear()
        backgroundOffButtonAppear()
        
        dividerAppear()
        
        pencilButtonOn()
        canvasViewInteractionEnabled()
        toolPickerAppear()
        
        stickerButtonOff()
        stickerCollectionViewDisappear()
        
        checkCameraPermission()
        
        input.send(.viewDidLoad)
        bind()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.navigationController?.isNavigationBarHidden = false
    }
    
    private func bind() {
        let output = viewModel.transform(input: input.eraseToAnyPublisher())
        output
            .sink(receiveValue: { [weak self] event in
                guard let self = self else {return}
                switch event {
                case .getRecentCardBackgroundImgSuccess(let background):
                    DispatchQueue.main.async(execute: {
                        self.someImageView.image = UIImage(named: "\(background ?? "Rectangle")")
                        self.introWordingDisAppear()
                        
                        print("get background ImgSuccess")
                    })
                case .getRecentCardBackgroundImgFail:
                    DispatchQueue.main.async(execute: {
                        self.someImageView.image = UIImage(named: "Rectangle")
                    })
                case .getRecentCardResultImgSuccess(_):
                    DispatchQueue.main.async(execute: {
                        
                    })
                case .getRecentCardResultImgFail:
                    DispatchQueue.main.async(execute: {
                        self.someImageView.image = UIImage(named: "Rectangle")
                        print("getRecentCardResultImgFail")
                    })
                case .popToWrittenPaper: break
                }
            })
            .store(in: &cancellables)
    }
    
    func resultImageSend() {
        disableEditSticker()
        guard let image = self.mergeImages(imageView: self.rootUIImageView) else { return }
        self.input.send(.setCardResultImg(result: image))
    }
    
    private func canvasViewInteractionDisabled() {
        rootUIImageView.addSubview(someImageView)
        someImageView.isUserInteractionEnabled = true
        someImageViewConstraints()
        
        rootUIImageView.addSubview(canvasView)
        canvasView.isUserInteractionEnabled = false
        canvasViewConstraints()
    }
    
    private func canvasViewInteractionEnabled() {
        rootUIImageView.addSubview(someImageView)
        someImageViewConstraints()
        
        rootUIImageView.addSubview(canvasView)
        canvasView.isUserInteractionEnabled = true
        canvasViewConstraints()
    }
    
    private func toolPickerAppear() {
        toolPicker.addObserver(canvasView)
        toolPicker.setVisible(true, forFirstResponder: canvasView)
    }
    
    private func toolPickerDisappear() {
        toolPicker.addObserver(canvasView)
        toolPicker.setVisible(false, forFirstResponder: canvasView)
    }
    
    private func cameraOnButtonAppear() {
        cameraOnButton.isHidden = false
        view.addSubview(cameraOnButton)
        cameraOnButtonConstraints()
    }
    
    private func cameraOffButtonAppear() {
        cameraOnButton.isHidden = true
        view.addSubview(cameraOffButton)
        cameraOffButtonConstraints()
    }
    
    private func backgroundOnButtonAppear() {
        backgroundOnButton.isHidden = false
        view.addSubview(backgroundOnButton)
        backgroundOnButtonConstraints()
    }
    
    private func backgroundOffButtonAppear() {
        backgroundOnButton.isHidden = true
        view.addSubview(backgroundOffButton)
        backgroundOffButtonConstraints()
    }
    
    private func introWordingAppear() {
        introWordingLabel.frame = CGRect(x: 0, y: 0, width: self.view.bounds.width * 0.80, height: self.view.bounds.height * 0.80)
        view.addSubview(introWordingLabel)
        introWordingLabel.addDashedBorder()
        introWordingLabelConstraints()
    }
    
    private func introWordingDisAppear() {
        introWordingLabel.isHidden = true
    }
    
    private func dividerAppear() {
        view.addSubview(divider)
        dividerConstraints()
    }
    
    private func pencilButtonOn() {
        pencilOnButton.isHidden = false
        view.addSubview(pencilOnButton)
        pencilOnButtonConstraints()
    }
    
    private func pencilButtonOff() {
        pencilOnButton.isHidden = true
        view.addSubview(pencilOffButton)
        pencilOffButtonConstraints()
    }
    
    private func stickerButtonOn() {
        stickerOnButton.isHidden = false
        view.addSubview(stickerOnButton)
        stickerOnButtonConstraints()
    }
    
    private func stickerButtonOff() {
        stickerOnButton.isHidden = true
        view.addSubview(stickerOffButton)
        stickerOffButtonConstraints()
    }
    
    private func stickerCollectionViewAppear() {
        view.addSubview(imageShadowView)
        imageShadowViewConstraints()
        imageShadowView.animateShowingUP()
        
        view.addSubview(collectionView)
        collectionViewConstraints()
        collectionView.animateShowingUP()
    }
    
    private func stickerCollectionViewDisappear() {
        imageShadowView.isHidden = true
        view.addSubview(imageShadowView)
        imageShadowViewConstraints()
        
        collectionView.isHidden = true
    }
    
    @objc func setPopOverView(_ sender: UIButton) {
        self.backgroundOnButtonAppear()
        
        let controller = BackgroundButtonViewController(viewModel: viewModel, backgroundImageName: backgroundImageName)
        controller.modalPresentationStyle = UIModalPresentationStyle.popover
        controller.preferredContentSize = CGSize(width: 128, height: 400)
        controller.presentationController?.delegate = self
        let popover = controller.popoverPresentationController
        popover?.sourceView = sender
        popover?.sourceRect = CGRect(x: 25, y: 0, width: 50, height: 50)
        present(controller, animated: true)
    }
    
    private func disableEditSticker() {
        if selectedSticker != nil {
            selectedSticker!.enabledControl = false
            selectedSticker!.enabledBorder = false
            selectedSticker = nil
        }
    }
    
    private func toggleAction() {
        self.isCanvasToolToggle.toggle()
        self.isStickerToggle.toggle()
        
        if isCanvasToolToggle == true && isStickerToggle == false {
            print("sticker button off")
            stickerButtonOff()
            disableEditSticker()
            stickerCollectionViewDisappear()
            
            pencilButtonOn()
            toolPickerAppear()
            
            canvasViewInteractionEnabled()
        } else {
            print("sticker button On")
            stickerButtonOn()
            stickerCollectionViewAppear()
            pencilButtonOff()
            toolPickerDisappear()
            
            canvasViewInteractionDisabled()
        }
    }
    
    @objc func togglebutton(_ gesture: UITapGestureRecognizer) {
        self.isCanvasToolToggle.toggle()
        self.isStickerToggle.toggle()
        
        if isCanvasToolToggle == true && isStickerToggle == false {
            print("sticker button off")
            stickerButtonOff()
            disableEditSticker()
            stickerCollectionViewDisappear()
            
            pencilButtonOn()
            toolPickerAppear()
            
            canvasViewInteractionEnabled()
        } else {
            print("sticker button On")
            stickerButtonOn()
            stickerCollectionViewAppear()
            pencilButtonOff()
            toolPickerDisappear()
            
            canvasViewInteractionDisabled()
        }
    }
    
    @objc func tapBackground(recognizer: UITapGestureRecognizer) {
        disableEditSticker()
    }
    
    @objc func importImage(_ gesture: UITapGestureRecognizer) {
        self.cameraOnButtonAppear()
        
        var alertStyle = UIAlertController.Style.actionSheet
        if UIDevice.current.userInterfaceIdiom == .pad {
            alertStyle = UIAlertController.Style.alert
        }
        let actionSheet = UIAlertController(title: "사진 가져오기", message: nil, preferredStyle: alertStyle)
        
        let cameraAction = UIAlertAction(title: "카메라", style: .default) { _ in
            DispatchQueue.main.async(execute: {
                self.cameraImagePicker()
            })
        }
        
        let libraryAction = UIAlertAction(title: "사진 앨범", style: .default) { _ in
            DispatchQueue.main.async(execute: {
                self.addLibraryImage()
                self.cameraOffButtonAppear()
            })
        }
        
        let cancelAction = UIAlertAction(title: "취소", style: .cancel) { _ in
            DispatchQueue.main.async(execute: {
                self.cameraOffButtonAppear()
            })
        }
        
        actionSheet.addAction(cameraAction)
        actionSheet.addAction(libraryAction)
        actionSheet.addAction(cancelAction)
        
        present(actionSheet, animated: false, completion: nil)
    }
}

extension CardCreateViewController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        self.backgroundOffButtonAppear()
    }
}

extension CardCreateViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func mergeImages(imageView: UIImageView) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(imageView.frame.size, false, 0.0)
        imageView.superview!.layer.render(in: UIGraphicsGetCurrentContext()!)
        let renderer = UIGraphicsImageRenderer(size: imageView.frame.size)
        let image = renderer.image(actions: { _ in
            imageView.drawHierarchy(in: imageView.bounds, afterScreenUpdates: true)
        })
        UIGraphicsEndImageContext()
        return image
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.arrStickers.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let aCell = collectionView.dequeueReusableCell(withReuseIdentifier: "StickerCollectionViewCell", for: indexPath) as? StickerCollectionViewCell else {return UICollectionViewCell()}
        
        let image = UIImage(named: self.arrStickers[indexPath.item])
        let targetSize = CGSize(width: 80, height: 80)
        
        let scaledImage = image?.scalePreservingAspectRatio(targetSize: targetSize)
        aCell.myImage.image = scaledImage
        
        return aCell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("Click Collection cell \(indexPath.item)")
        if let cell = collectionView.cellForItem(at: indexPath) as? StickerCollectionViewCell {
            guard let cellSticker = cell.myImage.image else { return }
            if let imageSticker = UIImage(named: self.arrStickers[indexPath.item]) {
                if stickerCount > 14 {
                    print("sticker over")
                    let alert = UIAlertController(title: "잠깐! 스티커가 많아요.", message: "스티커는 15개까지 추가할 수 있어요.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "확인", style: .default, handler: { (_: UIAlertAction) in
                        alert.dismiss(animated: true, completion: nil)
                    }))
                    present(alert, animated: true)
                } else {
                    stickerCount += 1
                    
                    let stickerView = IRStickerView(frame: CGRect.init(x: 0, y: 0, width: cellSticker.size.width, height: cellSticker.size.height), contentImage: imageSticker)
                    stickerView.center = someImageView.center
                    stickerView.stickerMinScale = 0.5
                    stickerView.stickerMaxScale = 3.0
                    stickerView.enabledControl = false
                    stickerView.enabledBorder = false
                    stickerView.tag = stickerCount
                    stickerView.delegate = self
                    
                    self.someImageView.addSubview(stickerView)
                }
            } else {
                print("Sticker not loaded")
            }
        }
    }
}

extension CardCreateViewController: IRStickerViewDelegate {
    private func ir_StickerView(stickerView: IRStickerView, imageForRightTopControl recommendedSize: CGSize) -> UIImage? {
        if stickerView.tag == 1 {
            return UIImage.init(named: "Sticker_Close")
        }
        return nil
    }
    
    func ir_StickerView(stickerView: IRStickerView, imageForLeftBottomControl recommendedSize: CGSize) -> UIImage? {
        if stickerView.tag == 1 || stickerView.tag == 2 {
            return UIImage.init(named: "Sticker_Flip")
        }
        return nil
    }
    
    func ir_StickerViewDidTapContentView(stickerView: IRStickerView) {
        NSLog("Tap[%zd] ContentView", stickerView.tag)
        if let selectedSticker = selectedSticker {
            selectedSticker.enabledBorder = false
            selectedSticker.enabledControl = false
        }
        selectedSticker = stickerView
        selectedSticker!.enabledBorder = true
        selectedSticker!.enabledControl = true
    }
    
    func ir_StickerViewDidTapLeftTopControl(stickerView: IRStickerView) {
        NSLog("Tap[%zd] DeleteControl", stickerView.tag)
        stickerView.removeFromSuperview()
        for subView in view.subviews {
            if subView.isKind(of: IRStickerView.self) {
                guard let sticker = subView as? IRStickerView else { fatalError("error") }
                sticker.performTapOperation()
                break
            }
        }
        stickerCount -= 1
    }
    
    func ir_StickerViewDidTapLeftBottomControl(stickerView: IRStickerView) {
        NSLog("Tap[%zd] LeftBottomControl", stickerView.tag)
        let targetOrientation = (stickerView.contentImage?.imageOrientation == UIImage.Orientation.up ? UIImage.Orientation.upMirrored : UIImage.Orientation.up)
        let invertImage = UIImage.init(cgImage: (stickerView.contentImage?.cgImage)!, scale: 1.0, orientation: targetOrientation)
        stickerView.contentImage = invertImage
    }
    
    func ir_StickerViewDidTapRightTopControl(stickerView: IRStickerView) {
        NSLog("Tap[%zd] RightTopControl", stickerView.tag)
        animator?.removeAllBehaviors()
        let snapbehavior = UISnapBehavior.init(item: stickerView, snapTo: view.center)
        snapbehavior.damping = 0.65
        animator?.addBehavior(snapbehavior)
    }
}

extension UIButton {
    func setUIImage(systemName: String) {
        contentHorizontalAlignment = .fill
        contentVerticalAlignment = .fill
        imageView?.contentMode = .scaleAspectFit
        setImage(UIImage(systemName: systemName), for: .normal)
    }
}

extension UIView {
    func fadeOut(duration: TimeInterval = 1.0, delay: TimeInterval = 0.0, completion: @escaping (Bool) -> Void = {(finished: Bool) -> Void in }) {
        self.alpha = 1.0
        UIView.animate(withDuration: duration, delay: delay, options: UIView.AnimationOptions.transitionFlipFromBottom, animations: {
            self.isHidden = true
            self.alpha = 0.0
        }, completion: completion)
    }
    
    func animateShowingUP() {
        UIView.animateKeyframes(withDuration: 0.7, delay: 0) { [weak self] in
            guard let height = self?.bounds.height else {
                return
            }
            self?.alpha = 1
            self?.center.y = -height/4
            self?.isHidden = false
        }
    }
    
    func addDashedBorder() {
        let color = UIColor.gray.cgColor
        
        let shapeLayer: CAShapeLayer = CAShapeLayer()
        let frameSize = self.frame.size
        let shapeRect = CGRect(x: 0, y: 0, width: frameSize.width, height: frameSize.height)
        
        shapeLayer.bounds = shapeRect
        shapeLayer.position = CGPoint(x: frameSize.width/2, y: frameSize.height/2)
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.strokeColor = color
        shapeLayer.lineWidth = 2
        shapeLayer.lineJoin = CAShapeLayerLineJoin.round
        shapeLayer.lineDashPattern = [10, 15]
        shapeLayer.path = UIBezierPath(roundedRect: shapeRect, cornerRadius: 27).cgPath
        
        self.layer.addSublayer(shapeLayer)
    }
}

extension CardCreateViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true, completion: nil)
        let itemProvider = results.first?.itemProvider
        if let itemProvider = itemProvider,
           
            itemProvider.canLoadObject(ofClass: UIImage.self) {
            itemProvider.loadObject(ofClass: UIImage.self) { image, _ in
                DispatchQueue.main.sync {
                    let alert = UIAlertController(title: "사진을 어떤 용도로 쓰시겠어요?", message: "", preferredStyle: .alert)
                    
                    alert.addAction(UIAlertAction(title: "배경", style: .default, handler: { (_: UIAlertAction) in
                        self.introWordingDisAppear()
                        self.someImageView.image = image as? UIImage
                    }))
                    alert.addAction(UIAlertAction(title: "스티커", style: .default, handler: { (_: UIAlertAction) in
                        
                        if self.stickerOnButton.isHidden == true {
                            self.toggleAction()
                        }
                        
                        if let imageSticker = image as? UIImage {
                            if self.stickerCount > 14 {
                                print("sticker over")
                                let alert = UIAlertController(title: "잠깐! 스티커가 많아요.", message: "스티커는 15개까지 추가할 수 있어요.", preferredStyle: .alert)
                                alert.addAction(UIAlertAction(title: "확인", style: .default, handler: { (_: UIAlertAction) in
                                    alert.dismiss(animated: true, completion: nil)
                                }))
                                self.present(alert, animated: true)
                            } else {
                                self.stickerCount += 1
                                
                                let stickerView = IRStickerView(frame: CGRect.init(x: 0, y: 0, width: 200, height: 200), contentImage: imageSticker)
                                stickerView.center = self.someImageView.center
                                stickerView.stickerMinScale = 0.5
                                stickerView.stickerMaxScale = 3.0
                                stickerView.enabledControl = false
                                stickerView.enabledBorder = false
                                stickerView.tag = self.stickerCount
                                stickerView.delegate = self
                                
                                self.someImageView.addSubview(stickerView)
                            }
                        } else {
                            print("Sticker not loaded")
                        }
                    }))
                    self.present(alert, animated: true)
                }
            }
        }
    }
    private func addLibraryImage() {
        var configuration = PHPickerConfiguration()
        configuration.selectionLimit = 1
        configuration.filter = .images
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        self.present(picker, animated: true, completion: nil)
    }
}

extension CardCreateViewController: UIImagePickerControllerDelegate {
    
    private func checkCameraPermission() {
        AVCaptureDevice.requestAccess(for: .video, completionHandler: { (granted: Bool) in
            if granted {
                print("Camera: 권한 허용")
            } else {
                print("Camera: 권한 거부")
            }
        })
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true)
            let alert = UIAlertController(title: "사진을 어떤 용도로 쓰시겠어요?", message: "", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "배경", style: .default, handler: { (_: UIAlertAction) in
                if let pickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
                    self.introWordingDisAppear()
                    self.someImageView.image = pickedImage
                }
            }))
            alert.addAction(UIAlertAction(title: "스티커", style: .default, handler: { (_: UIAlertAction) in
                if self.stickerOnButton.isHidden == true {
                    self.toggleAction()
                }
                
                if let pickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
                    if self.stickerCount > 14 {
                        print("sticker over")
                        let alert = UIAlertController(title: "잠깐! 스티커가 많아요.", message: "스티커는 15개까지 추가할 수 있어요.", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "확인", style: .default, handler: { (_: UIAlertAction) in
                            alert.dismiss(animated: true, completion: nil)
                        }))
                        self.present(alert, animated: true)
                    } else {
                        self.stickerCount += 1
                        let stickerView = IRStickerView(frame: CGRect.init(x: 0, y: 0, width: 250, height: 200), contentImage: pickedImage)
                        stickerView.center = self.someImageView.center
                        stickerView.stickerMinScale = 0.5
                        stickerView.stickerMaxScale = 3.0
                        stickerView.enabledControl = false
                        stickerView.enabledBorder = false
                        stickerView.tag = self.stickerCount
                        stickerView.delegate = self
                        
                        self.someImageView.addSubview(stickerView)
                    }
                } else {
                    print("Sticker not loaded")
                }
            }))
            self.present(alert, animated: true)
    }
    
    private func cameraImagePicker() {
        cameraOffButtonAppear()
        
        let pushVC = CameraCustomPickerController()
        pushVC.delegate = self
        pushVC.sourceType = .camera
        pushVC.cameraFlashMode = .off
        pushVC.cameraDevice = .front
        pushVC.modalPresentationStyle = .overFullScreen
        present(pushVC, animated: true)
    }
}

extension UIImage {
    func scalePreservingAspectRatio(targetSize: CGSize) -> UIImage {
        // Determine the scale factor that preserves aspect ratio
        let widthRatio = targetSize.width / size.width
        let heightRatio = targetSize.height / size.height
        
        let scaleFactor = min(widthRatio, heightRatio)
        
        // Compute the new image size that preserves aspect ratio
        let scaledImageSize = CGSize(
            width: size.width * scaleFactor,
            height: size.height * scaleFactor
        )
        
        // Draw and return the resized UIImage
        let renderer = UIGraphicsImageRenderer(
            size: scaledImageSize
        )
        let scaledImage = renderer.image { _ in
            self.draw(in: CGRect(
                origin: .zero,
                size: scaledImageSize
            ))
        }
        return scaledImage
    }
}

extension CardCreateViewController {
    private func rootUIImageViewConstraints() {
        rootUIImageView.snp.makeConstraints({ make in
            make.width.equalTo(self.view.bounds.width * 0.80)
            make.height.equalTo(self.view.bounds.height * 0.80)
            make.top.equalTo(self.view.snp.top).offset(60)
            make.centerX.equalTo(self.view)
            make.bottom.equalTo(self.view.snp.bottom).offset(-self.view.bounds.height * 0.10)
        })
    }
    
    private func someImageViewConstraints() {
        someImageView.snp.makeConstraints({ make in
            make.width.equalTo(self.view.bounds.width * 0.80)
            make.height.equalTo(self.view.bounds.height * 0.80)
            make.top.equalTo(self.view.snp.top).offset(60)
            make.centerX.equalTo(self.view)
            make.bottom.equalTo(self.view.snp.bottom).offset(-self.view.bounds.height * 0.10)
        })
    }
    
    private func canvasViewConstraints() {
        canvasView.snp.makeConstraints({ make in
            make.width.equalTo(self.view.bounds.width * 0.80)
            make.height.equalTo(self.view.bounds.height * 0.80)
            make.top.equalTo(self.view.snp.top).offset(60)
            make.centerX.equalTo(self.view)
            make.bottom.equalTo(self.view.snp.bottom).offset(-self.view.bounds.height * 0.10)
        })
    }
    
    private func introWordingLabelConstraints() {
        introWordingLabel.snp.makeConstraints({ make in
            make.width.equalTo(self.view.bounds.width * 0.80)
            make.height.equalTo(self.view.bounds.height * 0.80)
            make.top.equalTo(self.view.snp.top).offset(60)
            make.centerX.equalTo(self.view)
        })
    }
    
    private func imageShadowViewConstraints() {
        imageShadowView.snp.makeConstraints({ make in
            make.width.equalTo(740)
            make.height.equalTo(120)
            make.centerX.equalTo(self.view)
            make.bottom.equalTo(self.view.snp.bottom).offset(-20)
        })
    }
    
    private func collectionViewConstraints() {
        collectionView.snp.makeConstraints({ make in
            make.width.equalTo(740)
            make.height.equalTo(120)
            make.centerX.equalTo(self.view)
            make.bottom.equalTo(self.view.snp.bottom).offset(-20)
        })
    }
    
    private func buttonLabelConstraints() {
        buttonLabel.snp.makeConstraints({ make in
            make.width.equalTo(90)
            make.height.equalTo(450)
            make.leading.equalTo(self.view)
            make.centerY.equalTo(self.view)
        })
    }
    
    private func cameraOnButtonConstraints() {
        cameraOnButton.snp.makeConstraints({ make in
            make.width.equalTo(50)
            make.height.equalTo(50)
            make.leading.equalTo(buttonLabel.snp.leading).offset(25)
            make.top.equalTo(buttonLabel.snp.top).offset(20)
        })
    }
    
    private func cameraOffButtonConstraints() {
        cameraOffButton.snp.makeConstraints({ make in
            make.width.equalTo(50)
            make.height.equalTo(50)
            make.leading.equalTo(buttonLabel.snp.leading).offset(25)
            make.top.equalTo(buttonLabel.snp.top).offset(20)
        })
    }
    
    private func backgroundOnButtonConstraints() {
        backgroundOnButton.snp.makeConstraints({ make in
            make.width.equalTo(50)
            make.height.equalTo(50)
            make.leading.equalTo(buttonLabel.snp.leading).offset(25)
            make.top.equalTo(buttonLabel.snp.top).offset(85)
        })
    }
    
    private func backgroundOffButtonConstraints() {
        backgroundOffButton.snp.makeConstraints({ make in
            make.width.equalTo(50)
            make.height.equalTo(50)
            make.leading.equalTo(buttonLabel.snp.leading).offset(25)
            make.top.equalTo(buttonLabel.snp.top).offset(85)
        })
    }
    
    private func dividerConstraints() {
        divider.snp.makeConstraints({ make in
            make.width.equalTo(65)
            make.height.equalTo(1)
            make.centerX.equalTo(buttonLabel.snp.centerX)
            make.top.equalTo(buttonLabel.snp.top).offset(150)
        })
    }
    
    private func pencilOnButtonConstraints() {
        pencilOnButton.snp.makeConstraints({ make in
            make.width.equalTo(50)
            make.height.equalTo(50)
            make.leading.equalTo(buttonLabel.snp.leading).offset(25)
            make.top.equalTo(divider.snp.bottom).offset(20)
        })
    }
    
    private func pencilOffButtonConstraints() {
        pencilOffButton.snp.makeConstraints({ make in
            make.width.equalTo(50)
            make.height.equalTo(50)
            make.leading.equalTo(buttonLabel.snp.leading).offset(25)
            make.top.equalTo(divider.snp.bottom).offset(20)
        })
    }
    
    private func stickerOnButtonConstraints() {
        stickerOnButton.snp.makeConstraints({ make in
            make.width.equalTo(80.7)
            make.height.equalTo(63.76)
            make.leading.equalTo(buttonLabel.snp.leading).offset(10)
            make.top.equalTo(divider.snp.bottom).offset(90)
            make.bottom.equalTo(buttonLabel.snp.bottom).offset(-20)
        })
    }
    
    private func stickerOffButtonConstraints() {
        stickerOffButton.snp.makeConstraints({ make in
            make.width.equalTo(80.7)
            make.height.equalTo(63.76)
            make.leading.equalTo(buttonLabel.snp.leading).offset(10)
            make.top.equalTo(divider.snp.bottom).offset(90)
            make.bottom.equalTo(buttonLabel.snp.bottom).offset(-20)
        })
    }
}
