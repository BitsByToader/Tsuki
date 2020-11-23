//
//  SwipeReader.swift
//  Tsuki
//
//  Created by Tudor Ifrim on 11.11.2020.
//
import SwiftUI
import SDWebImage

struct SwipeReader: UIViewControllerRepresentable {
    @State var fancyAnimations: Bool
    @State var readerOrientation: ReaderSettings.ReaderOrientation.RawValue
    
    @Binding var pages: [String]
    var contentIsRemote: Bool
    @Binding var currentPage: Int
    @Binding var currentChapter: Int
    var remainingChapters: Int
    
    let loadChapter: (Int) -> Void
    
    let controllers: [UIViewController] = []
    var pageBeforeTransition: Int = 0
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> UIPageViewController {
        let pageViewController = UIPageViewController(transitionStyle: fancyAnimations ? .pageCurl : .scroll, navigationOrientation: readerOrientation == "Horizontal" ? .horizontal : .vertical)
        
        pageViewController.dataSource = context.coordinator
        pageViewController.delegate = context.coordinator
        
        pageViewController.setViewControllers([makeController(index: currentPage)], direction: .forward, animated: true)
        
        //Go through all of the Gestures used by the UIPageViewController and disable the tap gesture.
        //This hack works because UIPageViewController used the tap to move between pages and doesn't do
        //anything more fancy than that.
        for gesture in pageViewController.gestureRecognizers {
            if gesture.isKind(of: UITapGestureRecognizer.classForCoder()) {
                gesture.isEnabled = false
            }
        }
        
        return pageViewController
    }
    
    func updateUIViewController(_ pageViewController: UIPageViewController, context: Context) {
        //stub function
        //blank for now
    }
    
    func makeController(index: Int) -> UIViewController {
        let image: UIImageView = UIImageView()
        image.translatesAutoresizingMaskIntoConstraints = false
        
        if ( contentIsRemote ) {
            image.load(url: URL(string: pages[index])!)
        } else {
            image.image = UIImage(contentsOfFile: pages[index])
        }
        
        let scrollView: UIScrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        scrollView.bouncesZoom = true
        scrollView.bounces = true
        scrollView.addSubview(image)
        
        let controller = UIViewController()
        controller.view.addSubview(scrollView)
        
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: controller.view.safeAreaLayoutGuide.leadingAnchor),
            scrollView.topAnchor.constraint(equalTo: controller.view.safeAreaLayoutGuide.topAnchor),
            scrollView.trailingAnchor.constraint(equalTo: controller.view.safeAreaLayoutGuide.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: controller.view.bottomAnchor),
            
            image.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            image.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            image.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            image.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            image.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])
        
        return controller
    }
    
    class Coordinator: NSObject, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
        var parent: SwipeReader
        
        init(_ pageViewController: SwipeReader) {
            self.parent = pageViewController
        }
        
        func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
            parent.pageBeforeTransition = parent.currentPage
            parent.currentPage -= 1
            
            if parent.currentPage == -1 {
                parent.currentPage = parent.pages.count - 1
            }
            
            return parent.makeController(index: parent.currentPage)
        }
        
        func pageViewController( _ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
            parent.pageBeforeTransition = parent.currentPage
            parent.currentPage += 1
            
            if parent.currentPage == parent.pages.count {
                parent.currentPage = 0
            }
            
            if (parent.currentPage == parent.pages.count - 2 && parent.currentChapter + 1 != parent.remainingChapters) {
                parent.currentChapter += 1
                parent.loadChapter(parent.currentChapter)
            }
            
            return parent.makeController(index: parent.currentPage)
        }
        
        func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
            //So apparently, if the user beings a swipe but doesn't finish it (the page remains the same) the viewControllerAfter/Before will be called, but the
            //reverse function of it won't (viewControllerBefore/After). Thus, the currentPage will  start being out of sync and needs to be reverted if the
            //transition did finish but not complete
            if finished && !completed {
                parent.currentPage = parent.pageBeforeTransition
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
