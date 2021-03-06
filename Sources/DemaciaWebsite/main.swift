import Foundation
import Publish
import Plot
import SassPublishPlugin

// This type acts as the configuration for your website.
struct DemaciaWebsite: Website {
    enum SectionID: String, WebsiteSectionID {
        // Add the sections that you want your website to contain here:
        case about
        case robots
        case sponsorship
    }
    struct ItemMetadata: WebsiteItemMetadata {
        // Add any site-specific metadata that you want to use here.
    }
    // Update these properties to configure your website:
    var url = URL(string: "https://demacia5635.github.io/")!
    var name = "Demacia"
    var description = "The Demacia#5635 FRC team website"
    var language: Language { .english }
    var imagePath: Path? { "logos/logo.png" }
    var favicon: Favicon? { .init(path: "favicon.png") }
}

// This will generate your website using the built-in Foundation theme:
try DemaciaWebsite().publish(using: [
    .installPlugin(.prepareImagesForOptimization),
    .addMarkdownFiles(),
    .addSlides(),
    .copyResources(),
    .generateHTML(withTheme: .demacia),
    .generateSiteMap(),
    .installPlugin(
        .compileSass(
            sassFilePath: "Sources/sass/styles.sass",
            cssFilePath: "styles.css",
            compressed: true
        )
    ),
    .inlineCSS(),
    .removeUnusedCSS(whitelist: ["*fast*", "*animate*", "*control*"]),
    .optimizeImages(),
    .uglifyJS(),
    .deploy(using: .gitHubPages("Demacia5635/demacia5635.github.io", source: .ghPages, useSSH: false))
])
