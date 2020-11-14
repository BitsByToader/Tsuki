//
//  SwipeReader.swift
//  Tsuki
//
//  Created by Tudor Ifrim on 11.11.2020.
//
import SwiftUI
import SDWebImage

struct SwipeReader: UIViewControllerRepresentable {
    var pages: [String]
    var contentIsRemote: Bool
    @Binding var currentPage: Int
    @Binding var currentChapter: Int
    var remainingChapters: Int
    
    let loadChapter: (Int) -> Void
    
    var controllers: [UIViewController] {
        var controllerArray: [UIViewController] = []
        
        for _ in pages {
            let image: UIImageView = UIImageView()
            image.translatesAutoresizingMaskIntoConstraints = false
            
//            if ( contentIsRemote ) {
//                image.load(url: URL(string: page)!)
//            } else {
//                image.image = UIImage(contentsOfFile: page)
//            }
            
            let controller = UIViewController()
            controller.view.addSubview(image)
            image.pinEdges(to: controller.view)
            
            controllerArray.append(controller)
        }
        
        #warning("Check here if there is a second page")
        if ( contentIsRemote ) {
            (controllerArray[pages.count-1].view!.subviews[0] as! UIImageView).load(url: URL(string: pages[pages.count-1])!)
            (controllerArray[0].view!.subviews[0] as! UIImageView).load(url: URL(string: pages[0])!)
            (controllerArray[1].view!.subviews[0] as! UIImageView).load(url: URL(string: pages[1])!)
        } else {
            (controllerArray[pages.count-1].view!.subviews[0] as! UIImageView).image = UIImage(contentsOfFile: pages[pages.count-1])
            (controllerArray[0].view!.subviews[0] as! UIImageView).image = UIImage(contentsOfFile: pages[0])
            (controllerArray[1].view!.subviews[0] as! UIImageView).image = UIImage(contentsOfFile: pages[1])
        }
        
        return controllerArray
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> UIPageViewController {
        let pageViewController = UIPageViewController(
            transitionStyle: .pageCurl,
            navigationOrientation: .horizontal)
        pageViewController.dataSource = context.coordinator
        pageViewController.delegate = context.coordinator
        
        return pageViewController
    }
    
    func updateUIViewController(_ pageViewController: UIPageViewController, context: Context) {
        pageViewController.setViewControllers([makeController(index: currentPage)], direction: .forward, animated: true)
    }
    
    func makeController(index: Int) -> UIViewController {
        let image: UIImageView = UIImageView()
        image.translatesAutoresizingMaskIntoConstraints = false
        
        if ( contentIsRemote ) {
            image.load(url: URL(string: pages[index])!)
        } else {
            image.image = UIImage(contentsOfFile: pages[index])
        }
        
        let controller = UIViewController()
        controller.view.addSubview(image)
        image.pinEdges(to: controller.view)
        
        return controller
    }
    
    class Coordinator: NSObject, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
        var parent: SwipeReader
        
        init(_ pageViewController: SwipeReader) {
            self.parent = pageViewController
        }
        
        func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
            parent.currentPage -= 1
            
            if parent.currentPage == -1 {
                parent.currentPage = parent.pages.count - 1
            }
            
            let image: UIImageView = UIImageView()
            image.translatesAutoresizingMaskIntoConstraints = false
            
            if ( parent.contentIsRemote ) {
                image.load(url: URL(string: parent.pages[parent.currentPage])!)
            } else {
                image.image = UIImage(contentsOfFile: parent.pages[parent.currentPage])
            }
            
            let controller = UIViewController()
            controller.view.addSubview(image)
            image.pinEdges(to: controller.view)
            
            return controller
        }
        
        func pageViewController( _ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
            parent.currentPage += 1
            
            if parent.currentPage == parent.pages.count {
                parent.currentPage = 0
            }
            
            let image: UIImageView = UIImageView()
            image.translatesAutoresizingMaskIntoConstraints = false
            
            if ( parent.contentIsRemote ) {
                image.load(url: URL(string: parent.pages[parent.currentPage])!)
            } else {
                image.image = UIImage(contentsOfFile: parent.pages[parent.currentPage])
            }
            
            let controller = UIViewController()
            controller.view.addSubview(image)
            image.pinEdges(to: controller.view)
            
            return controller
        }
        
        func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
            if completed,
                let visibleViewController = pageViewController.viewControllers?.first,
                let index = parent.controllers.firstIndex(of: visibleViewController)
            {
                parent.currentPage = index
            }
        }
    }
}

extension UIImageView {
    func load(url: URL) {
        DispatchQueue.global().async { [weak self] in
            if let data = try? Data(contentsOf: url) {
                if let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self?.image = image
                    }
                }
            }
        }
    }
}

extension UIView {
    func pinEdges(to other: UIView) {
        leadingAnchor.constraint(equalTo: other.leadingAnchor).isActive = true
        trailingAnchor.constraint(equalTo: other.trailingAnchor).isActive = true
        topAnchor.constraint(equalTo: other.topAnchor).isActive = true
        bottomAnchor.constraint(equalTo: other.bottomAnchor).isActive = true
    }
}
