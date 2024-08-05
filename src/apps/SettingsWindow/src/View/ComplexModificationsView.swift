import SwiftUI

enum ComplexModificationsSheetView: String {
  case assets
  case fileImport
}

struct ComplexModificationsView: View {
  @ObservedObject private var contentViewStates = ContentViewStates.shared
  @ObservedObject private var settings = LibKrbn.Settings.shared
  @State private var moveDisabled: Bool = true
  @State private var showingEditSheet = false
  @State private var hoverRuleIndex: Int?
  @State private var editingRule: LibKrbn.ComplexModificationsRule?

  var body: some View {
    VStack(alignment: .leading, spacing: 12.0) {
      HStack {
        Button(
          action: {
            contentViewStates.complexModificationsViewSheetView =
              ComplexModificationsSheetView.assets
            contentViewStates.complexModificationsViewSheetPresented = true
          },
          label: {
            AccentColorIconLabel(title: "Add predefined rule", systemImage: "plus.circle.fill")
          })

        Button(
          action: {
            var buffer = [Int8](repeating: 0, count: 32 * 1024)
            libkrbn_core_configuration_get_new_complex_modifications_rule_json_string(
              &buffer, buffer.count)

            editingRule = LibKrbn.ComplexModificationsRule(
              index: -1,
              description: "Edit the following setting and press the Save button.",
              enabled: true,
              jsonString: String(cString: buffer)
            )
            showingEditSheet = true
          },
          label: {
            AccentColorIconLabel(title: "Add your own rule", systemImage: "sparkles")
          })

        Spacer()

        if settings.complexModificationsRules.count > 1 {
          HStack {
            Text("You can reorder list by dragging")
            Image(systemName: "arrow.up.arrow.down.square.fill")
              .resizable(resizingMode: .stretch)
              .frame(width: 16.0, height: 16.0)
            Text("icon")
          }
        }
      }

      List {
        ForEach($settings.complexModificationsRules) { $complexModificationRule in
          HStack(alignment: .center, spacing: 0) {
            if settings.complexModificationsRules.count > 1 {
              Image(systemName: "arrow.up.arrow.down.square.fill")
                .resizable(resizingMode: .stretch)
                .frame(width: 16.0, height: 16.0)
                .onHover { hovering in
                  moveDisabled = !hovering
                }
                .contextMenu {
                  Section(header: Text("Position")) {
                    Button {
                      settings.moveComplexModificationsRule(complexModificationRule.index, 0)
                    } label: {
                      Label("Move item to top", systemImage: "arrow.up.to.line")
                    }

                    Button {
                      settings.moveComplexModificationsRule(
                        complexModificationRule.index, settings.complexModificationsRules.count)
                    } label: {
                      Label("Move item to bottom", systemImage: "arrow.down.to.line")
                    }
                  }
                }
            }

            Text(complexModificationRule.description)
              .padding(.leading, 6.0)
              .if(hoverRuleIndex == complexModificationRule.index) {
                $0.font(.body.weight(.bold))
              }
              .if(!complexModificationRule.enabled) {
                $0.foregroundColor(.gray)
              }

            Spacer()

            HStack(alignment: .center, spacing: 10) {
              Toggle(isOn: $complexModificationRule.enabled) {
                Text(complexModificationRule.enabled ? "" : "disabled")
              }
              .switchToggleStyle()
              .padding(.horizontal, 10.0)
              .scaledToFit()

              Button(
                action: {
                  editingRule = complexModificationRule
                  showingEditSheet = true
                },
                label: {
                  Label("Edit", systemImage: "pencil.circle.fill")
                })

              Button(
                role: .destructive,
                action: {
                  settings.removeComplexModificationsRule(complexModificationRule)
                },
                label: {
                  Image(systemName: "trash")
                    .buttonLabelStyle()
                }
              )
              .deleteButtonStyle()
              .frame(width: 60)
            }
            .onHover { hovering in
              if hovering {
                hoverRuleIndex = complexModificationRule.index
              } else {
                if hoverRuleIndex == complexModificationRule.index {
                  hoverRuleIndex = nil
                }
              }
            }
          }
          .padding(.vertical, 5.0)
          .moveDisabled(moveDisabled)
        }
        .onMove { indices, destination in
          if let first = indices.first {
            settings.moveComplexModificationsRule(first, destination)
          }
        }
      }
      .background(Color(NSColor.textBackgroundColor))
    }
    .padding()
    .sheet(isPresented: $contentViewStates.complexModificationsViewSheetPresented) {
      if let sheetView = contentViewStates.complexModificationsViewSheetView {
        switch sheetView {
        case ComplexModificationsSheetView.assets:
          ComplexModificationsAssetsView()
        case ComplexModificationsSheetView.fileImport:
          ComplexModificationsFileImportView()
        }
      }
    }
    .sheet(isPresented: $showingEditSheet) {
      ComplexModificationsEditView(rule: $editingRule, showing: $showingEditSheet)
    }
  }
}

struct ComplexModificationsView_Previews: PreviewProvider {
  static var previews: some View {
    ComplexModificationsView()
  }
}
