import Foundation
import SwiftUI
import SwiftUIIntrospect

typealias RefreshAction = (_ completion: @escaping () -> ()) -> ()
typealias AsyncRefreshAction = () async -> ()

struct RefresherConfig {
    /// Drag distance needed to trigger a refresh
    var refreshAt: CGFloat

    /// Max height of the spacer for the refresh spinner to sit while refreshing
    var headerShimMaxHeight: CGFloat

    /// Offset where the spinner stops moving after dragging
    var defaultSpinnerSpinnerStopPoint: CGFloat

    /// Off screen start point for the spinner (relative to the top of the screen)
    var defaultSpinnerOffScreenPoint: CGFloat

    /// How far you have to pull (from 0 - 1) for the spinner to start moving
    var defaultSpinnerPullClipPoint: CGFloat

    /// How far you have to pull (from 0 - 1) for the spinner to start becoming visible
    var systemSpinnerOpacityClipPoint: CGFloat

    /// How long to hold the spinner before dismissing
    var holdTime: DispatchTimeInterval

    /// How long to wait before allowing the next refresh
    var cooldown: DispatchTimeInterval

    /// How close to resting position the scrollview has to move to allow the next refresh
    var resetPoint: CGFloat

    /// Extra vertical offset to push the spinner below an overlay header
    var spinnerTopOffset: CGFloat

    init(
        refreshAt: CGFloat = 90,
        headerShimMaxHeight: CGFloat = 75,
        defaultSpinnerSpinnerStopPoint: CGFloat = -50,
        defaultSpinnerOffScreenPoint: CGFloat = -50,
        defaultSpinnerPullClipPoint: CGFloat = 0.1,
        systemSpinnerOpacityClipPoint: CGFloat = 0.2,
        holdTime: DispatchTimeInterval = .milliseconds(300),
        cooldown: DispatchTimeInterval = .milliseconds(500),
        resetPoint: CGFloat = 5,
        spinnerTopOffset: CGFloat = 0
    ) {
        self.refreshAt = refreshAt
        self.defaultSpinnerSpinnerStopPoint = defaultSpinnerSpinnerStopPoint
        self.headerShimMaxHeight = headerShimMaxHeight
        self.defaultSpinnerOffScreenPoint = defaultSpinnerOffScreenPoint
        self.defaultSpinnerPullClipPoint = defaultSpinnerPullClipPoint
        self.systemSpinnerOpacityClipPoint = systemSpinnerOpacityClipPoint
        self.holdTime = holdTime
        self.cooldown = cooldown
        self.resetPoint = resetPoint
        self.spinnerTopOffset = spinnerTopOffset
    }
}

enum RefresherStyle {
    case `default`
    case system
    case system2
    case overlay
}

enum RefreshMode {
    case notRefreshing
    case pulling
    case refreshing
}

struct RefresherState {
    var mode: RefreshMode = .notRefreshing
    var modeAnimated: RefreshMode = .notRefreshing
    var dragPosition: CGFloat = 0
    let style: RefresherStyle
}

struct RefreshableScrollView<Content: View, RefreshView: View>: View {
    let axes: Axis.Set
    let showsIndicators: Bool
    let content: Content
    let refreshAction: RefreshAction
    var refreshView: (Binding<RefresherState>) -> RefreshView

    @State private var headerInset: CGFloat = 1000000
    @State var state: RefresherState
    @State var distance: CGFloat = 0
    @State var rawDistance: CGFloat = 0
    @State var renderLock = false
    private let style: RefresherStyle
    private let config: RefresherConfig

    @State private var uiScrollView: UIScrollView?
    @State private var isRefresherVisible = true
    @State private var isFingerDown = false
    @State private var canRefresh = true

    init(
        axes: Axis.Set = .vertical,
        showsIndicators: Bool = true,
        refreshAction: @escaping RefreshAction,
        style: RefresherStyle,
        config: RefresherConfig,
        refreshView: @escaping (Binding<RefresherState>) -> RefreshView,
        content: Content
    ) {
        self.axes = axes
        self.showsIndicators = showsIndicators
        self.refreshAction = refreshAction
        self.refreshView = refreshView
        self.content = content
        self.style = style
        self.config = config
        self._state = .init(wrappedValue: RefresherState(style: style))
    }

    private var refreshHeaderOffset: CGFloat {
        switch state.style {
        case .default, .system:
            if case .refreshing = state.modeAnimated {
                return config.headerShimMaxHeight * (1 - state.dragPosition)
            }
        case .system2:
            switch state.modeAnimated {
            case .pulling:
                return config.headerShimMaxHeight * (state.dragPosition)
            case .refreshing:
                return config.headerShimMaxHeight
            default: break
            }
        default: break
        }
        return 0
    }

    private var isTracking: Bool {
        guard let scrollView = uiScrollView else {
            // Fallback when introspect can't find the scroll view:
            // assume finger is down when content is being pulled
            return distance > 0
        }
        return scrollView.isTracking
    }

    private var showRefreshControls: Bool {
        return isFingerDown || isRefresherVisible
    }

    @ViewBuilder
    private var refreshSpinner: some View {
        if style == .default || style == .overlay {
            RefreshSpinnerView(offScreenPoint: config.defaultSpinnerOffScreenPoint,
                               pullClipPoint: config.defaultSpinnerPullClipPoint,
                               mode: state.modeAnimated,
                               stopPoint: config.defaultSpinnerSpinnerStopPoint,
                               refreshHoldPoint: config.headerShimMaxHeight / 2 + config.spinnerTopOffset,
                               refreshView: refreshView($state),
                               headerInset: $headerInset,
                               refreshAt: config.refreshAt)
            .opacity(showRefreshControls ? 1 : 0)
        }
    }

    @ViewBuilder
    private var systemStyleRefreshSpinner: some View {
        if style == .system {
            SystemStyleRefreshSpinner(opacityClipPoint: config.systemSpinnerOpacityClipPoint,
                                     state: state,
                                     position: distance,
                                     refreshHoldPoint: config.headerShimMaxHeight / 2 + config.spinnerTopOffset,
                                     refreshView: refreshView($state))
            .opacity(showRefreshControls ? 1 : 0)
        }
    }

    @ViewBuilder
    private var system2StyleRefreshSpinner: some View {
        if style == .system2 {
            System2StyleRefreshSpinner(opacityClipPoint: config.systemSpinnerOpacityClipPoint,
                                      state: state,
                                      refreshHoldPoint: config.headerShimMaxHeight / 2 + config.spinnerTopOffset,
                                      refreshView: refreshView($state))
            .opacity(showRefreshControls ? 1 : 0)
        }
    }

    var body: some View {
        GeometryReader { globalGeometry in
            ScrollView(axes, showsIndicators: showsIndicators) {
                ZStack(alignment: .top) {
                    OffsetReader { val in
                        offsetChanged(val)
                    }
                    systemStyleRefreshSpinner
                    system2StyleRefreshSpinner

                    VStack(spacing: 0) {
                        content
                            .renderLocked(with: $renderLock)
                            .offset(y: refreshHeaderOffset)
                    }
                    refreshSpinner
                }
            }
            .introspect(.scrollView, on: .iOS(.v14, .v15, .v16, .v17, .v18)) { scrollView in
                DispatchQueue.main.async {
                    uiScrollView = scrollView
                }
            }
            .onChange(of: globalGeometry.frame(in: .global)) { val in
                headerInset = val.minY
            }
            .onAppear {
                DispatchQueue.main.async {
                    headerInset = globalGeometry.frame(in: .global).minY
                }
            }
        }
    }

    private func offsetChanged(_ val: CGFloat) {
        isFingerDown = isTracking
        distance = val - headerInset
        state.dragPosition = normalize(from: 0, to: config.refreshAt, by: distance)

        if canRefresh, !isFingerDown, distance <= 0 {
            renderLock = false
        }

        guard canRefresh else {
            canRefresh = distance <= config.resetPoint && !isFingerDown && state.mode != .refreshing
            return
        }
        guard distance > 0, showRefreshControls else {
            isRefresherVisible = false
            return
        }

        isRefresherVisible = true

        if distance >= config.refreshAt, !renderLock {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            renderLock = true
            canRefresh = false
            set(mode: .refreshing)

            refreshAction {
                DispatchQueue.main.asyncAfter(deadline: .now() + config.holdTime) {
                    set(mode: .notRefreshing)
                    self.renderLock = false

                    DispatchQueue.main.asyncAfter(deadline: .now() + config.cooldown) {
                        self.canRefresh = !isFingerDown
                        self.isRefresherVisible = false
                    }
                }
            }
        } else if distance > 0, state.mode != .refreshing {
            set(mode: .pulling)
        }
    }

    func set(mode: RefreshMode) {
        state.mode = mode
        withAnimation {
            state.modeAnimated = mode
        }
    }
}
