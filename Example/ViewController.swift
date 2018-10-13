//
//  ViewController.swift
//  Example
//
//  Created by Lasha Efremidze on 4/13/17.
//  Copyright © 2017 efremidze. All rights reserved.
//

import UIKit
import MapKit
import Cluster

class ViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    let manager = ClusterManager()
    
    let region = (center: CLLocationCoordinate2D(latitude: 37.787994, longitude: -122.407437), delta: 0.1)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // When zoom level is quite close to the pins, disable clustering in order to show individual pins and allow the user to interact with them via callouts.
        manager.delegate = self
        mapView.region = .init(center: region.center, span: .init(latitudeDelta: region.delta, longitudeDelta: region.delta))
        manager.maxZoomLevel = 17
        manager.minCountForClustering = 3
        manager.clusterPosition = .nearCenter
        addAnnotations()
    }
    
    @IBAction func addAnnotations(_ sender: UIButton? = nil) {
        // Add annotations to the manager.
        let annotations: [Annotation] = (0..<100000).map { i in
            let annotation = Annotation()
            annotation.coordinate = CLLocationCoordinate2D(latitude: region.center.latitude + drand48() * region.delta - region.delta / 2, longitude: region.center.longitude + drand48() * region.delta - region.delta / 2)
            return annotation
        }
        manager.add(annotations)
        manager.reload(mapView: mapView)
    }
    
    @IBAction func removeAnnotations(_ sender: UIButton? = nil) {
        manager.removeAll()
        manager.reload(mapView: mapView)
    }
    
    @IBAction func valueChanged(_ sender: UISegmentedControl) {
        removeAnnotations()
        addAnnotations()
    }
    
}

extension ViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let annotation = annotation as? ClusterAnnotation {
            let index = segmentedControl.selectedSegmentIndex
            let identifier = "Cluster\(index)"
            let annotationView: MKAnnotationView
            if let existingView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) {
                annotationView = existingView
            } else {
                annotationView = Selection(rawValue: index)!.annotationView(annotation: annotation, reuseIdentifier: identifier)
            }
            annotationView.annotation = annotation
            return annotationView
        } else {
            let identifier = "Pin"
            let annotationView: MKPinAnnotationView
            if let existingView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKPinAnnotationView {
                annotationView = existingView
            } else {
                annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView.pinTintColor = .annotation
            }
            annotationView.annotation = annotation
            return annotationView
        }
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        manager.reload(mapView: mapView) { finished in
            print(finished)
        }
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let annotation = view.annotation else { return }
        
        if let cluster = annotation as? ClusterAnnotation {
            var zoomRect = MKMapRectNull
            for annotation in cluster.annotations {
                let annotationPoint = MKMapPointForCoordinate(annotation.coordinate)
                let pointRect = MKMapRectMake(annotationPoint.x, annotationPoint.y, 0, 0)
                if MKMapRectIsNull(zoomRect) {
                    zoomRect = pointRect
                } else {
                    zoomRect = MKMapRectUnion(zoomRect, pointRect)
                }
            }
            mapView.setVisibleMapRect(zoomRect, animated: true)
        }
    }
    
    func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
        views.forEach { $0.alpha = 0 }
        UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: [], animations: { 
            views.forEach { $0.alpha = 1 }
        }, completion: nil)
    }
    
//    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
//        let view = MKPolylineRenderer(overlay: overlay)
//        if overlay is MKBasePolyline {
//            view.strokeColor = .blue
//        } else {
//            view.strokeColor = .red
//        }
//        return view
//    }

}

extension ViewController: ClusterManagerDelegate {}

extension ViewController {
    enum Selection: Int {
        case count, imageCount, image
        
        func annotationView(annotation: MKAnnotation?, reuseIdentifier: String?) -> MKAnnotationView {
            switch self {
            case .count:
                let annotationView = CountClusterAnnotationView(annotation: annotation, reuseIdentifier: reuseIdentifier)
                annotationView.countLabel.backgroundColor = .annotation
                return annotationView
            case .imageCount:
                let annotationView = ImageCountClusterAnnotationView(annotation: annotation, reuseIdentifier: reuseIdentifier)
                annotationView.countLabel.textColor = .annotation
                annotationView.image = .annotation2
                return annotationView
            case .image:
                let annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: reuseIdentifier)
                annotationView.image = .annotation
                return annotationView
            }
        }
    }
}
