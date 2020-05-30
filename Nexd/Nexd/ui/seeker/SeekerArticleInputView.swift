//
//  SeekerArticleInputView.swift
//  nexd
//
//  Created by Tobias Schröpf on 28.05.20.
//  Copyright © 2020 Tobias Schröpf. All rights reserved.
//

import Combine
import NexdClient
import SwiftUI

// TODO: - send correct locale for backend requests
// TODO: - check if automatic selection of unit works when a suggestion is accepted
// TODO: - order units, move "favorite" units to the top
// TODO: - check UI in english and german!

struct SeekerArticleInputView: View {
    @ObservedObject var viewModel: ViewModel

    var body: some View {
        ZStack {
            VStack {
                HStack(alignment: .top) {
                    VStack(spacing: 0) {
                        NexdUI.TextField(tag: 1,
                                         text: $viewModel.state.articleName,
                                         placeholder: R.string.localizable.seeker_item_selection_add_article_placeholer(),
                                         onChanged: { string in self.viewModel.articleNameChanged(text: string) },
                                         inputConfiguration: NexdUI.InputConfiguration(hasDone: true))

                        viewModel.state.suggestions.map { suggestions in
                            VStack {
                                ForEach(suggestions) { suggestion in
                                    NexdUI.Texts.defaultDark(text: Text(suggestion.name))
                                        .frame(maxWidth: .infinity, minHeight: 40)
                                        .contentShape(Rectangle())
                                        .onTapGesture { self.viewModel.suggestionAccepted(suggestion: suggestion) }
                                }
                            }
                        }
                    }
                    .background(Color.white)
                    .cornerRadius(10)

                    NexdUI.TextField(tag: 2,
                                     text: $viewModel.state.amount,
                                     placeholder: R.string.localizable.seeker_item_selection_article_amount_placeholer(),
                                     inputConfiguration: NexdUI.InputConfiguration(keyboardType: .numberPad, hasDone: true))

                    NexdUI.Buttons.darkButton(text: Text(viewModel.state.unit?.nameShort ?? "???")) {
                        self.viewModel.onUnitButtonTapped()
                    }
                    .frame(height: 48)
                }
                .padding(.top, 70)
                .padding([.leading, .trailing], 12)

                Spacer()
            }

            if self.viewModel.state.isUnitsPickerVisible {
                VStack {
                    Spacer()

                    VStack(spacing: 0) {
                        viewModel.itemSelectionViewState.units.map { units in
                            List(units) { unit in
                                NexdUI.Texts.defaultDark(text: Text("\(unit.name) (\(unit.nameShort))"))
                                    .frame(maxWidth: .infinity, minHeight: 40)
                                    .contentShape(Rectangle())
                                    .onTapGesture { self.viewModel.unitSelected(unit: unit) }
                            }
                            .frame(maxWidth: .infinity, maxHeight: 320)
                        }
                    }
                    .padding(8)
                    .background(Color.white)
                    .cornerRadius(10, corners: [.topLeft, .topRight])
                }
                .transition(.move(edge: .bottom))
                .contentShape(Rectangle())
                .onTapGesture { self.viewModel.dismissUnitPicker() }
            }
        }
        .dismissingKeyboard()
        .onAppear { self.viewModel.bind() }
        .onDisappear { self.viewModel.unbind() }
        .withModalButtons(
            onCancel: { self.viewModel.cancelButtonTapped() },
            onDone: { self.viewModel.doneButtonTapped() }
        )
    }
}

extension SeekerArticleInputView {
    class ViewModel: ObservableObject {
        class ViewState: ObservableObject {
            @Published var articleName: String?
            @Published var acceptedSuggestion: Article?
            @Published var suggestions: [Article]?

            @Published var amount: String?

            @Published var unit: ItemSelectionViewState.Unit?
            @Published var isUnitsPickerVisible: Bool = false

            func asItem() -> ItemSelectionViewState.Item {
                let articleName: String = self.articleName ?? ""
                let amount: String = self.amount ?? "0"
                return ItemSelectionViewState.Item(article: nil, name: articleName, amount: Int64(amount) ?? 0, unit: unit)
            }

            static func from(item: ItemSelectionViewState.Item?) -> ViewState {
                let state = ViewState()

                if let item = item {
                    state.articleName = item.name
                    state.amount = String(item.amount)
                    state.unit = item.unit
                }

                return state
            }
        }

        private let navigator: ScreenNavigating
        private let articlesService: ArticlesService
        private let onDone: ((ItemSelectionViewState.Item) -> Void)?
        private let onCancel: (() -> Void)?

        @Published var itemSelectionViewState: ItemSelectionViewState

        private var cancellableSet = Set<AnyCancellable>()

        var state: ViewState

        private var articleNameInput = PassthroughSubject<String?, Never>()

        init(navigator: ScreenNavigating,
             articlesService: ArticlesService,
             itemSelectionViewState: ItemSelectionViewState,
             item: ItemSelectionViewState.Item?,
             onDone: ((ItemSelectionViewState.Item) -> Void)? = nil,
             onCancel: (() -> Void)? = nil) {
            self.navigator = navigator
            self.articlesService = articlesService
            state = ViewState.from(item: item)
            self.itemSelectionViewState = itemSelectionViewState
            self.onDone = onDone
            self.onCancel = onCancel
        }

        func cancelButtonTapped() {
            onCancel?()
        }

        func doneButtonTapped() {
            onDone?(state.asItem())
        }

        func articleNameChanged(text: String?) {
            state.acceptedSuggestion = nil
            articleNameInput.send(text)
        }

        func suggestionAccepted(suggestion: Article) {
            state.articleName = suggestion.name
            state.acceptedSuggestion = suggestion
            state.suggestions = nil

            if let unitId = suggestion.unitIdOrder?.first {
                state.unit = itemSelectionViewState.units?.first { $0.id == unitId }
            }
        }

        func onUnitButtonTapped() {
            UIApplication.shared.endEditing()
            state.isUnitsPickerVisible = true
        }

        func unitSelected(unit: ItemSelectionViewState.Unit) {
            state.unit = unit
            dismissUnitPicker()
        }

        func dismissUnitPicker() {
            state.isUnitsPickerVisible = false
        }

        func bind() {
            var cancellableSet = Set<AnyCancellable>()

            state.objectWillChange
                .sink { [weak self] in
                    self?.objectWillChange.send()
                }
                .store(in: &cancellableSet)

            articleNameInput
                .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
                .eraseToAnyPublisher()
                .flatMap { [weak self] inputText -> AnyPublisher<[Article]?, Never> in
                    guard let self = self, let inputText = inputText, !inputText.isEmpty else {
                        return Just<[Article]?>(nil).eraseToAnyPublisher()
                    }

                    return self.articlesService.allArticles(limit: 5,
                                                            startsWith: inputText,
                                                            language: self.itemSelectionViewState.language,
                                                            onlyVerified: false)
                        .map { articles -> [Article]? in articles }
                        .publisher
                        .replaceError(with: nil)
                        .eraseToAnyPublisher()
                }
                .assign(to: \.suggestions, on: state)
                .store(in: &cancellableSet)

            self.cancellableSet = cancellableSet
        }

        func unbind() {
            cancellableSet = Set<AnyCancellable>()
        }
    }

    static func createScreen(viewModel: SeekerArticleInputView.ViewModel) -> UIViewController {
        let screen = UIHostingController(rootView: SeekerArticleInputView(viewModel: viewModel))
        screen.view.backgroundColor = R.color.nexdGreen()
        return screen
    }
}

#if DEBUG
    struct SeekerArticleInputView_Previews: PreviewProvider {
        static var previews: some View {
            let viewModel = SeekerArticleInputView.ViewModel(navigator: PreviewNavigator(),
                                                             articlesService: ArticlesService(),
                                                             itemSelectionViewState: ItemSelectionViewState(),
                                                             item: nil)
            return Group {
                SeekerArticleInputView(viewModel: viewModel)
                    .background(R.color.nexdGreen.color)
                    .environment(\.locale, .init(identifier: "de"))

                SeekerArticleInputView(viewModel: viewModel)
                    .background(R.color.nexdGreen.color)
                    .environment(\.colorScheme, .light)
                    .environment(\.locale, .init(identifier: "en"))

                SeekerArticleInputView(viewModel: viewModel)
                    .background(R.color.nexdGreen.color)
                    .environment(\.colorScheme, .dark)
                    .environment(\.locale, .init(identifier: "en"))
            }
            .previewLayout(.sizeThatFits)
        }
    }
#endif
