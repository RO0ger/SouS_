import Foundation

// Model for an ingredient within a static recipe
struct IngredientData: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let quantity: String
}

// Model for a complete static recipe
struct StaticRecipe: Identifiable {
    let id = UUID()
    let name: String
    let detailImageName: String // For the image in the detail view (SF Symbol or asset)
    let duration: String
    let servings: String
    let isMealPrepFriendly: Bool
    let ingredients: [IngredientData]
    let instructions: [String] // Instructions will be processed for italics in the View

    // Sample Data (to be replaced or expanded by actual data source)
    // We'll populate this properly in HomePageView or a dedicated data provider
}

// Example data (can be moved to a dedicated data file or view model later)
// This is just for conceptual structure; actual data will be initialized in HomePageView.
/*
extension StaticRecipe {
    static let quickPasta = StaticRecipe(
        name: "Quick Garlic Basil Tomato Pasta",
        detailImageName: "fork.knife.circle.fill", // Placeholder SF Symbol
        duration: "20 min",
        servings: "2 servings",
        isMealPrepFriendly: true,
        ingredients: [
            .init(name: "Pasta (any shape)", quantity: "200g"),
            .init(name: "Olive oil", quantity: "2 tablespoons"),
            .init(name: "Garlic", quantity: "2 cloves, minced"),
            .init(name: "Red pepper flakes (optional)", quantity: "½ teaspoon"),
            .init(name: "Canned crushed tomatoes", quantity: "400g"),
            .init(name: "Dried oregano", quantity: "1 teaspoon"),
            .init(name: "Fresh basil leaves", quantity: "A small handful, torn"),
            .init(name: "Parmesan cheese", quantity: "For grating"),
            .init(name: "Salt", quantity: "To taste"),
            .init(name: "Black pepper", quantity: "To taste")
        ],
        instructions: [
            "_Get a pot of salted water boiling like a tiny, enthusiastic jacuzzi for your pasta._",
            "_Once it's bubbling away, toss in your pasta and cook it according to the package directions – aim for "al dente," which is Italian for "to the tooth" (not "to the roof of your mouth")._",
            "_While the pasta is doing its thing, heat the olive oil in a pan over medium heat. Add the minced garlic and red pepper flakes (if you're feeling a little spicy!) and cook for about 30 seconds until fragrant – it should smell amazing, not burnt._",
            "_Pour in the crushed tomatoes and stir in the oregano, salt, and pepper. Let this simmer gently for a few minutes, allowing the flavors to get to know each other._",
            "_Once the pasta is cooked, scoop out about a cup of the pasta water (this starchy liquid is your secret weapon for a saucy masterpiece!) and then drain the rest of the water._",
            "_Add the drained pasta to the tomato sauce. Toss it all together, adding a little of that reserved pasta water if the sauce seems too thick. You want it nice and luscious._",
            "_Serve it up with a generous sprinkle of fresh basil and a grating of Parmesan cheese. Enjoy your speedy and scrumptious pasta creation!_"
        ]
    )

    static let freshSalad = StaticRecipe(
        name: "Fresh Veggie Tossed Salad",
        detailImageName: "leaf.circle.fill", // Placeholder SF Symbol
        duration: "15 min",
        servings: "2 servings",
        isMealPrepFriendly: false,
        ingredients: [
            .init(name: "Mixed salad greens (such as romaine, spinach, butter lettuce)", quantity: "5 cups"),
            .init(name: "Cucumber", quantity: "½, thinly sliced"),
            .init(name: "Cherry tomatoes", quantity: "1 cup, halved"),
            .init(name: "Red onion", quantity: "¼, thinly sliced"),
            .init(name: "Bell pepper (any color)", quantity: "½, thinly sliced"),
            .init(name: "Olive oil", quantity: "3 tablespoons"),
            .init(name: "Red wine vinegar", quantity: "1 tablespoon"),
            .init(name: "Dijon mustard", quantity: "1 teaspoon"),
            .init(name: "Honey or maple syrup", quantity: "½ teaspoon (optional, for a touch of sweetness)"),
            .init(name: "Salt", quantity: "To taste"),
            .init(name: "Black pepper", quantity: "To taste")
        ],
        instructions: [
            "_Give those lovely greens a good wash and spin them dry – nobody likes a soggy salad! Think of it as a refreshing spa day for your lettuce._",
            "_In a large bowl, gently combine the mixed greens, sliced cucumber, halved cherry tomatoes, thinly sliced red onion, and bell pepper. Toss them lightly, like they're slow dancing._",
            "_Now, let's whisk up a zesty vinaigrette! In a small bowl or jar, combine the olive oil, red wine vinegar, Dijon mustard, and honey (if using). Whisk or shake it vigorously until it looks nicely emulsified – that means it's all blended together and not separated like stubborn siblings._",
            "_Season your vinaigrette with salt and pepper to your liking. Give it a little taste and adjust as needed – it should be bright and zippy!_",
            "_Just before you're ready to serve, drizzle that delicious vinaigrette over your salad. Start with a little and add more as needed – you want to coat the greens, not drown them._",
            "_Toss everything together gently so that all those lovely greens and veggies are dressed in their flavorful best._",
            "_Serve immediately and enjoy the crisp, fresh goodness! Feel free to add some protein like grilled chicken or chickpeas if you want to make it a more substantial meal._"
        ]
    )

    static let simpleOmelet = StaticRecipe(
        name: "Healthy Spinach Sunrise Omelet",
        detailImageName: "sunrise.circle.fill", // Placeholder SF Symbol
        duration: "10 min",
        servings: "1 serving",
        isMealPrepFriendly: true,
        ingredients: [
            .init(name: "Eggs", quantity: "2 large"),
            .init(name: "Spinach", quantity: "½ cup, roughly chopped"),
            .init(name: "Cherry tomatoes", quantity: "¼ cup, halved"),
            .init(name: "Feta cheese", quantity: "2 tablespoons, crumbled (optional, for a bit of flavor)"),
            .init(name: "Olive oil or cooking spray", quantity: "1 teaspoon or a few sprays"),
            .init(name: "Salt", quantity: "To taste"),
            .init(name: "Black pepper", quantity: "To taste")
        ],
        instructions: [
            "_Crack those eggs into a bowl and whisk them gently with a fork until the yolks and whites are just combined. Don't over-whisk – you're not trying to make a meringue here!_",
            "_Stir in the chopped spinach and halved cherry tomatoes into the egg mixture. If you're feeling a bit cheesy, sprinkle in the crumbled feta too._",
            "_Season your egg mixture with a pinch of salt and pepper. Remember, you can always add more later, but you can't take it away!_",
            "_Heat a non-stick skillet over medium-low heat. Add the olive oil or spray it lightly with cooking spray. You want the pan to be hot enough that the egg doesn't stick, but not so hot that it cooks too quickly and becomes rubbery._",
            "_Pour the egg mixture into the hot skillet. Let it cook undisturbed for a minute or two, until the edges start to set._",
            "_As the edges set, gently push the cooked egg towards the center of the pan, tilting the pan so the uncooked egg flows underneath._",
            "_Repeat this a few times until most of the egg is set but the top is still a little wet._",
            "_Now for the fancy part (optional)! You can either fold the omelet in half or simply slide it onto a plate. Serve it immediately and enjoy your healthy and delicious creation!_"
        ]
    )
}
*/ 
// End of file comment to nudge Xcode - v2 