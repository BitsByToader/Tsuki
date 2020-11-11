//
//  SwipeReader.swift
//  Tsuki
//
//  Created by Tudor Ifrim on 11.11.2020.
//
import SwiftUI

struct SwipeReader: UIViewControllerRepresentable {
    var pages: [String]
    var contentIsRemote: Bool
    @Binding var currentPage: Int
    @Binding var currentChapter: Int
    var remainingChapters: Int
    
    let loadChapter: (Int) -> Void
    
    var controllers: [UIViewController] {
        var controllerArray: [UIViewController] = []
        
        for page in pages {
            let image: UIImageView = UIImageView()
            image.image = UIImage(contentsOfFile: page)
            image.translatesAutoresizingMaskIntoConstraints = false
            
            let controller = UIViewController()
            controller.view.addSubview(image)
            image.pinEdges(to: controller.view)
            
            controllerArray.append(controller)
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
        
//        (controllers[currentPage].view.subviews[0] as! UIImageView ).load(url: URL(string:pages[currentPage])!)
        
        pageViewController.setViewControllers(
            [controllers[currentPage]], direction: .forward, animated: true)
    }
    
    class Coordinator: NSObject, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
        var parent: SwipeReader
        
        init(_ pageViewController: SwipeReader) {
            self.parent = pageViewController
        }
        
        func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
            if parent.currentPage == 0 {
                parent.currentPage = parent.controllers.count - 1
                return parent.controllers.last
            }
            
            parent.currentPage -= 1
            
            return parent.controllers[parent.currentPage]
        }
        
        func pageViewController( _ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
            if parent.currentPage + 1 == parent.controllers.count {
                parent.currentPage = 0
                return parent.controllers.first
            }
            
            parent.currentPage += 1
            
            return parent.controllers[parent.currentPage]
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
