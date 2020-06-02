//
//  HelperRequestOverviewView.swift
//  nexd
//
//  Created by Tobias Schröpf on 01.06.20.
//  Copyright © 2020 Tobias Schröpf. All rights reserved.
//

import Combine
import NexdClient
import RxSwift
import SwiftUI

struct OptionalView<Value, Content>: View where Content: View {
    var content: (Value) -> Content
    var value: Value

    init?(_ value: Value?, @ViewBuilder content: @escaping (Value) -> Content) {
        guard let value = value else { return nil }

        self.value = value
        self.content = content
    }

    var body: some View {
        content(value)
    }
}

extension Optional where Wrapped: View {
    func whenNil<T: View>(_ transform: () -> T) -> AnyView? {
        switch self {
        case .none:
            return AnyView(transform())
        case let .some(view):
            return AnyView(view)
        }
    }
}

struct HelperRequestOverviewView: View {
    @ObservedObject var viewModel: ViewModel

    var body: some View {
        VStack {
            NexdUI.Texts.title(text: R.string.localizable.helper_request_overview_screen_title.text)
                .padding(.top, 70)

            ScrollView {
                NexdUI.Texts.sectionHeader(text: R.string.localizable.helper_request_overview_heading_accepted_section.text)

                OptionalView(viewModel.helperWorkflowState.acceptedHelpRequests) { acceptedHelpRequests in
                    NexdUI.RequestList(items: acceptedHelpRequests) { request in
                        self.viewModel.onAcceptedHelpRequestTapped(item: request)
                    }
                }
                .whenNil {
                    NexdUI.Texts.detailsText(text: R.string.localizable.helper_request_overview_empty_accepted_requests_list_placeholder.text)
                        .padding([.top, .bottom], 20)
                }

                HStack {
                    VStack {
                        NexdUI.Texts.sectionHeader(text: R.string.localizable.helper_request_overview_heading_available_section.text)

                        OptionalView(viewModel.state.zipCode as String?) { zipCode in
                            NexdUI.Texts.filterButtonDetailsText(text: Text(R.string.localizable.helper_request_overview_filter_selected_zip(zipCode)))
                        }
                        .whenNil {
                            NexdUI.Texts.filterButtonDetailsText(text: R.string.localizable.helper_request_overview_filter_inactive.text)
                        }
                    }

                    Spacer()

                    R.image.chevron.image
                        .foregroundColor(R.color.darkButtonBorder.color)
                }
                .onTapGesture {
                    self.viewModel.onChangeZipCodePressed()
                }

                OptionalView(viewModel.helperWorkflowState.openHelpRequests as [HelpRequest]?) { openHelpRequests in
                    NexdUI.RequestList(items: openHelpRequests) { request in
                        self.viewModel.onOpenHelpRequestTapped(item: request)
                    }
                }
                .whenNil {
                    NexdUI.Texts.detailsText(text: R.string.localizable.helper_request_overview_empty_open_requests_list_placeholder.text)
                        .padding([.top, .bottom], 20)
                }

                Spacer()
            }

            NexdUI.Buttons.default(text: R.string.localizable.helper_request_overview_button_title_current_items_list.text) {
                log.debug("ZEFIX")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 0)
            .padding(.bottom, 40)
        }
        .padding([.leading, .trailing], 20)
        .onAppear { self.viewModel.bind() }
        .onDisappear { self.viewModel.unbind() }
        .withBackButton { self.viewModel.onBackButtonPressed() }
    }
}

extension HelperRequestOverviewView {
    class ViewModel: ObservableObject {
        class ViewState: ObservableObject {
            @Published var zipCode: String?
        }

        private let navigator: ScreenNavigating
        private let userService: UserService
        private let helpRequestsService: HelpRequestsService
        private let helpListsService: HelpListsService
        private var cancellableSet: Set<AnyCancellable>?

        fileprivate var state: ViewState = ViewState()
        fileprivate let helperWorkflowState: HelperWorkflowState = HelperWorkflowState()

        init(navigator: ScreenNavigating,
             userService: UserService,
             helpRequestsService: HelpRequestsService,
             helpListsService: HelpListsService) {
            self.navigator = navigator
            self.userService = userService
            self.helpRequestsService = helpRequestsService
            self.helpListsService = helpListsService
        }

        func onBackButtonPressed() {
            navigator.goBack()
        }

        func onChangeZipCodePressed() {
            navigator.changingHelperRequestFilterSettings(zipCode: state.zipCode) { [weak self] result in
                self?.state.zipCode = result?.zipCode
            }
        }

        func onAcceptedHelpRequestTapped(item: HelpRequest) {
            navigator.removingHelperRequest(request: item, in: helperWorkflowState) { [weak self] _ in
                self?.refreshOpenHelpRequests()
            }
        }

        func onOpenHelpRequestTapped(item: HelpRequest) {
            navigator.addingHelperRequest(request: item, in: helperWorkflowState) { [weak self] _ in
                self?.refreshOpenHelpRequests()
            }
        }

        func refreshOpenHelpRequests() {
            cancellableSet?.insert(
                state.$zipCode
                    .asObservable()
                    .flatMap { [weak self] zip -> Single<[HelpRequest]> in
                        guard let self = self else { return Single.never() }

                        guard let zip = zip else {
                            return self.helpRequestsService.openRequests(userId: "me", excludeUserId: true, status: [.pending])
                        }

                        return self.helpRequestsService.openRequests(userId: "me", excludeUserId: true, zipCode: [zip], status: [.pending])
                    }
                    .publisher
                    .map { requests -> [HelpRequest]? in requests }
                    .replaceError(with: nil)
                    .assign(to: \.filteredHelpRequests, on: helperWorkflowState)
            )
        }

        func bind() {
            var cancellableSet = Set<AnyCancellable>()

            userService
                .findMe()
                .map { user -> String? in user.zipCode }
                .publisher
                .replaceError(with: nil)
                .assign(to: \.zipCode, on: state)
                .store(in: &cancellableSet)

            helpListsService
                .activeHelpList()
                .map { list -> HelpList? in list }
                .publisher
                .replaceError(with: nil)
                .assign(to: \.helpList, on: helperWorkflowState)
                .store(in: &cancellableSet)

            state.objectWillChange
                .sink { [weak self] _ in self?.objectWillChange.send() }
                .store(in: &cancellableSet)

            helperWorkflowState.objectWillChange
                .sink { [weak self] _ in self?.objectWillChange.send() }
                .store(in: &cancellableSet)

            self.cancellableSet = cancellableSet

            refreshOpenHelpRequests()
        }

        func unbind() {
            cancellableSet = nil
        }
    }

    static func createScreen(viewModel: HelperRequestOverviewView.ViewModel) -> UIViewController {
        let screen = UIHostingController(rootView: HelperRequestOverviewView(viewModel: viewModel))
        screen.view.backgroundColor = R.color.nexdGreen()
        return screen
    }
}
