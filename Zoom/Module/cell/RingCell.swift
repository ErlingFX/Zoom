//
//  RingCell.swift
//  Zoom
//
//  Created by Александр Назаров on 08.09.2021.
//

import UIKit

protocol RingCellDelegate: AnyObject {
    func zooming(started: Bool)
}

class RingCell: UICollectionViewCell, UIGestureRecognizerDelegate {
    weak var delegate: RingCellDelegate?
    
    // the hotel is lazily instantiated in a UIImageView
    var ringBackgroundView: UIView = {
        var bckview = UIView()
        bckview.backgroundColor = #colorLiteral(red: 0.7540688515, green: 0.7540867925, blue: 0.7540771365, alpha: 0.4003518212)
        return bckview
    }()
    
    var ringImageView: UIImageView = {
        var ringImageCell = UIImageView()
        ringImageCell.contentMode = .scaleAspectFill
        ringImageCell.clipsToBounds = true
        ringImageCell.isUserInteractionEnabled = true
        return ringImageCell
    }()

   
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        // set up the pinch gesture
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(self.pinch(sender:)))
        // this class is the delegate
        pinch.delegate = self
        // add the gesture to hotelImageView
        self.ringImageView.addGestureRecognizer(pinch)
        // add the imageview to the UICollectionView
        addSubview(ringBackgroundView)
        addSubview(ringImageView)
        // we are taking care of the constraints
        ringImageView.translatesAutoresizingMaskIntoConstraints = false
        ringBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        // pin the image to the whole collectionview - it is the same size as the container
        ringImageView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        ringBackgroundView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        
        ringImageView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        ringBackgroundView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        
        ringImageView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        ringBackgroundView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        
        ringImageView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        ringBackgroundView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
       
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // the view that will be overlayed, giving a back transparent look
    var overlayView: UIView!
    
    // a property representing the maximum alpha value of the background
    let maxOverlayAlpha: CGFloat = 0.8
    // a property representing the minimum alpha value of the background
    let minOverlayAlpha: CGFloat = 0.4
    
    // the initial center of the pinch
    var initialCenter: CGPoint?
    // the view to be added to the Window
    var windowImageView: UIImageView?
    // the origin of the source imageview (in the Window coordinate space)
    var startingRect = CGRect.zero
    
    // the function called when the user pinches the collection view cell
    @objc func pinch(sender: UIPinchGestureRecognizer) {
        if sender.state == .began {
            // the current scale is the aspect ratio
            let currentScale = self.ringImageView.frame.size.width / self.ringImageView.bounds.size.width
            // the new scale of the current `UIPinchGestureRecognizer`
            let newScale = currentScale * sender.scale
            
            // if we are really zooming
            if newScale > 1 {
                // if we don't have a current window, do nothing
                guard let currentWindow = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) else {return}
                
                // inform listeners that we are zooming, to stop them scrolling the UICollectionView
                self.delegate?.zooming(started: true)
                
                // setup the overlay to be the same size as the window
                overlayView = UIView.init(
                    frame: CGRect(
                        x: 0,
                        y: 0,
                        width: (currentWindow.frame.size.width),
                        height: (currentWindow.frame.size.height)
                    )
                )
                
                // set the view of the overlay as black
                overlayView.backgroundColor = UIColor.black
                
                // set the minimum alpha for the overlay
                overlayView.alpha = CGFloat(minOverlayAlpha)
                
                // add the subview to the overlay
                currentWindow.addSubview(overlayView)
                
                // set the center of the pinch, so we can calculate the later transformation
                initialCenter = sender.location(in: currentWindow)
                
                // set the window Image view to be a new UIImageView instance
                windowImageView = UIImageView.init(image: self.ringImageView.image)
                
                // set the contentMode to be the same as the original ImageView
                windowImageView!.contentMode = .scaleAspectFill
                
                // Do not let it flow over the image bounds
                windowImageView!.clipsToBounds = true
                
                // since the to view is nil, this converts to the base window coordinates.
                // so where is the origin of the imageview, in the main window
                let point = self.ringImageView.convert(
                    ringImageView.frame.origin,
                    to: nil
                )
                
                // the location of the imageview, with the origin in the Window's coordinate space
                startingRect = CGRect(
                    x: point.x,
                    y: point.y,
                    width: ringImageView.frame.size.width,
                    height: ringImageView.frame.size.height
                )
                
                // set the frame for the image to be added to the window
                windowImageView?.frame = startingRect
                
                // add the image to the Window, so it will be in front of the navigation controller
                currentWindow.addSubview(windowImageView!)
                
                // hide the original image
                ringImageView.isHidden = true
            }
        } else if sender.state == .changed {
            // if we don't have a current window, do nothing. Ensure the initialCenter has been set
            guard let currentWindow = UIApplication.shared.windows.first(where: { $0.isKeyWindow }),
                  let initialCenter = initialCenter,
                  let windowImageWidth = windowImageView?.frame.size.width
            else { return }
            
            // Calculate new image scale.
            let currentScale = windowImageWidth / startingRect.size.width
            
            // the new scale of the current `UIPinchGestureRecognizer`
            let newScale = currentScale * sender.scale
            
            // Calculate new overlay alpha, so there is a nice animated transition effect
            overlayView.alpha = minOverlayAlpha + (newScale - 1) < maxOverlayAlpha ? minOverlayAlpha + (newScale - 1) : maxOverlayAlpha
            
            // calculate the center of the pinch
            let pinchCenter = CGPoint(
                x: sender.location(in: currentWindow).x - (currentWindow.bounds.midX),
                y: sender.location(in: currentWindow).y - (currentWindow.bounds.midY)
            )
            
            // calculate the difference between the inital centerX and new centerX
            let centerXDif = initialCenter.x - sender.location(in: currentWindow).x
            // calculate the difference between the intial centerY and the new centerY
            let centerYDif = initialCenter.y - sender.location(in: currentWindow).y
            
            // calculate the zoomscale
            let zoomScale = (newScale * windowImageWidth >= ringImageView.frame.width) ? newScale : currentScale
            
            // transform scaled by the zoom scale
            let transform = currentWindow.transform
                .translatedBy(x: pinchCenter.x, y: pinchCenter.y)
                .scaledBy(x: zoomScale, y: zoomScale)
                .translatedBy(x: -centerXDif, y: -centerYDif)
            
            // apply the transformation
            windowImageView?.transform = transform
            
            // Reset the scale
            sender.scale = 1
        } else if sender.state == .ended || sender.state == .failed || sender.state == .cancelled {
            guard let windowImageView = self.windowImageView else { return }
            
            // animate the change when the pinch has finished
            UIView.animate(withDuration: 0.3, animations: {
                // make the transformation go back to the original
                windowImageView.transform = CGAffineTransform.identity
            }, completion: { _ in
                
                // remove the imageview from the superview
                windowImageView.removeFromSuperview()
                
                // remove the overlayview
                self.overlayView.removeFromSuperview()
                
                // make the original view reappear
                self.ringImageView.isHidden = false
                
                // tell the collectionview that we have stopped
                self.delegate?.zooming(started: false)
            })
        }
    }
    
    // This is the function to setup the CollectionViewCell
    func setupCell(image: String) {
        // set the appropriate image, if we can form a UIImage
        if let image : UIImage = UIImage(named: image) {
            ringImageView.image = image
        }
    }
}
    
   

