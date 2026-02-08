import Foundation
import SwiftUI

extension ScrollView {
    func refresher<RefreshView>(style: RefresherStyle = .default,
                                config: RefresherConfig = RefresherConfig(),
                                refreshView: @escaping (Binding<RefresherState>) -> RefreshView,
                                action: @escaping RefreshAction) -> RefreshableScrollView<Content, RefreshView> {
        RefreshableScrollView(axes: axes,
                              showsIndicators: showsIndicators,
                              refreshAction: action,
                              style: style,
                              config: config,
                              refreshView: refreshView,
                              content: content)
    }

    func refresher(style: RefresherStyle = .default,
                   config: RefresherConfig = RefresherConfig(),
                   action: @escaping RefreshAction) -> some View {
        RefreshableScrollView(axes: axes,
                              showsIndicators: showsIndicators,
                              refreshAction: action,
                              style: style,
                              config: config,
                              refreshView: DefaultRefreshView.init,
                              content: content)
    }

    func refresher<RefreshView>(style: RefresherStyle = .default,
                                config: RefresherConfig = RefresherConfig(),
                                refreshView: @escaping (Binding<RefresherState>) -> RefreshView,
                                action: @escaping AsyncRefreshAction) -> RefreshableScrollView<Content, RefreshView> {
        RefreshableScrollView(axes: axes,
                              showsIndicators: showsIndicators,
                              refreshAction: { done in
                                  Task { @MainActor in
                                      await action()
                                      done()
                                  }
                              },
                              style: style,
                              config: config,
                              refreshView: refreshView,
                              content: content)
    }

    func refresher(style: RefresherStyle = .default,
                   config: RefresherConfig = RefresherConfig(),
                   action: @escaping AsyncRefreshAction) -> some View {
        RefreshableScrollView(axes: axes,
                              showsIndicators: showsIndicators,
                              refreshAction: { done in
                                  Task { @MainActor in
                                      await action()
                                      done()
                                  }
                              },
                              style: style,
                              config: config,
                              refreshView: DefaultRefreshView.init,
                              content: content)
    }
}
