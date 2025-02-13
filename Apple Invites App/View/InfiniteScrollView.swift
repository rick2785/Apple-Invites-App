//
//  InfiniteScrollView.swift
//  Apple Invites App
//
//  Created by RJ Hrabowskie on 2/12/25.
//

import SwiftUI

struct InfiniteScrollView<Content: View>: View {
    var spacing: CGFloat = 10
    @ViewBuilder var content: Content
    @State private var contentSize: CGSize = .zero
    
    var body: some View {
        GeometryReader {
            let size = $0.size
            
            ScrollView(.horizontal) {
                HStack(spacing: spacing) {
                    Group(subviews: content) { collection in
                        HStack(spacing: spacing) {
                            ForEach(collection) { view in
                                view
                            }
                        }
                        .onGeometryChange(for: CGSize.self) {
                            $0.size
                        } action: { newValue in
                            contentSize = .init(width: newValue.width + spacing, height: newValue.height)
                        }

                        let averageWidth = contentSize.width / CGFloat(collection.count)
                        let repeatingCount = contentSize.width > 0 ? Int((size.width / averageWidth).rounded()) + 1 : 1
                        
                        HStack(spacing: spacing) {
                            ForEach(0..<repeatingCount, id: \.self) { index in
                                let view = Array(collection)[index % collection.count]
                                
                                view
                            }
                        }
                    }
                }
                .background(InfiniteScrollHelper(contentSize: $contentSize, decelerationRate: .constant(.fast)))
            }
        }
    }
}

#Preview {
    ContentView()
}

fileprivate struct InfiniteScrollHelper: UIViewRepresentable {
    @Binding var contentSize: CGSize
    @Binding var decelerationRate: UIScrollView.DecelerationRate
    
    func makeCoordinator() -> Coordinator {
        Coordinator(decelerationRate: decelerationRate, contentSize: contentSize)
    }
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .clear
        
        DispatchQueue.main.async {
            if let scrollView = view.scrollView {
                context.coordinator.defaultDelegate = scrollView.delegate
                scrollView.decelerationRate = decelerationRate
                scrollView.delegate = context.coordinator
            }
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.decelerationRate = decelerationRate
        context.coordinator.contentSize = contentSize
    }
    
    class Coordinator: NSObject, UIScrollViewDelegate {
        var decelerationRate: UIScrollView.DecelerationRate
        var contentSize: CGSize
        
        init(decelerationRate: UIScrollView.DecelerationRate, contentSize: CGSize) {
            self.decelerationRate = decelerationRate
            self.contentSize = contentSize
        }
        
        weak var defaultDelegate: UIScrollViewDelegate?
        
        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            scrollView.decelerationRate = decelerationRate
            
            let minX = scrollView.contentOffset.x
            
            if minX > contentSize.width {
                scrollView.contentOffset.x -= contentSize.width
            }
            
            if minX < 0 {
                scrollView.contentOffset.x += contentSize.width
            }
            
            defaultDelegate?.scrollViewDidScroll?(scrollView)
        }
        
        func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
            defaultDelegate?.scrollViewDidEndDragging?(scrollView, willDecelerate: decelerate)
        }
        
        func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
            defaultDelegate?.scrollViewDidEndDecelerating?(scrollView)
        }
        
        func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
            defaultDelegate?.scrollViewWillBeginDragging?(scrollView)
        }
        
        func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
            defaultDelegate?.scrollViewWillEndDragging?(scrollView, withVelocity: velocity, targetContentOffset: targetContentOffset)
        }
    }
}

extension UIView {
    var scrollView: UIScrollView? {
        if let superview, superview is UIScrollView {
            return superview as? UIScrollView
        }
        
        return superview?.scrollView
    }
}
