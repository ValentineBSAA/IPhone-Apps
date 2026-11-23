import SwiftUI

struct RecipeLibraryView: View {
    @EnvironmentObject private var kitchen: KitchenStore
    @State private var isAdding = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                PageHeading(eyebrow: "YOUR RECIPE BOOK", title: "Something delicious.", subtitle: "Your own recipes, saved privately on this iPhone.")
                HStack {
                    Text("\(kitchen.recipes.count) saved recipes")
                        .font(.headline).foregroundColor(CrispPalette.cream)
                    Spacer()
                    Button { isAdding = true } label: { Label("New", systemImage: "plus") }
                        .buttonStyle(.borderedProminent)
                        .tint(CrispPalette.gold)
                        .foregroundColor(CrispPalette.background)
                }
                if kitchen.recipes.isEmpty {
                    CrispCard {
                        Image(systemName: "book.closed").font(.largeTitle).foregroundColor(CrispPalette.gold)
                        Text("Your cookbook starts here").font(.title3.bold()).foregroundColor(CrispPalette.cream)
                        Text("Add your own recipe or use a suggested preset on the Kitchen tab. Nothing is sent to the air fryer.")
                            .font(.subheadline).foregroundColor(CrispPalette.muted)
                    }
                }
                ForEach(kitchen.recipes) { recipe in
                    CrispCard {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(recipe.title).font(.title3.bold()).foregroundColor(CrispPalette.cream)
                                Label("\(recipe.temperatureF)°F   ·   \(recipe.minutes) min", systemImage: "thermometer.medium")
                                    .font(.subheadline).foregroundColor(CrispPalette.gold)
                                if !recipe.notes.isEmpty { Text(recipe.notes).font(.footnote).foregroundColor(CrispPalette.muted) }
                            }
                            Spacer()
                            Button(role: .destructive) { kitchen.removeRecipe(recipe.id) } label: {
                                Image(systemName: "trash").padding(6)
                            }
                            .accessibilityLabel("Delete " + recipe.title)
                        }
                    }
                }
            }
            .padding(20)
        }
        .background(CrispPalette.background)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $isAdding) { AddRecipeSheet() }
    }
}

private struct AddRecipeSheet: View {
    @EnvironmentObject private var kitchen: KitchenStore
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var temperature = 375
    @State private var minutes = 15
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Recipe") {
                    TextField("Name", text: $title)
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(2...5)
                }
                Section("Suggested settings") {
                    Stepper("Temperature: \(temperature)°F", value: $temperature, in: 175...400, step: 5)
                    Stepper("Duration: \(minutes) minutes", value: $minutes, in: 1...60)
                    Text("Planning values only. Use your appliance's safety instructions.")
                        .font(.caption)
                }
            }
            .navigationTitle("New Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        kitchen.addRecipe(SavedRecipe(title: title, temperatureF: temperature, minutes: minutes, notes: notes))
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
