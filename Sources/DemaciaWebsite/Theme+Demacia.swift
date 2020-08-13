//
//  Theme+Foundation.swift
//  
//
//  Created by Noam Alffasy on 09/08/2020.
//

import Foundation
import Publish
import Plot
import Files

extension Theme where Site == DemaciaWebsite {
    static var demacia: Self {
        Theme(htmlFactory: DemaciaHTMLFactory())
    }
    
    private struct DemaciaHTMLFactory: HTMLFactory {
        func makeIndexHTML(for index: Index, context: PublishingContext<DemaciaWebsite>) throws -> HTML {
            HTML(
                .lang(context.site.language),
                .head(for: index, on: context.site),
                .body(
                    .navbar(for: context, selectedSection: nil),
                    .section(.class("hero is-primary is-bold"),
                             .div(.class("hero-body px-0 py-0 is-block"),
                                  .slideshow(for: context)
                             )
                    ),
                    .section(.class("text container has-text-centered"), .contentBody(index.body)),
                    .footer(for: context.site),
                    .script(.src("/js/logoAnimation.js"))
                )
            )
        }
        
        func makeSectionHTML(for section: Section<DemaciaWebsite>, context: PublishingContext<DemaciaWebsite>) throws -> HTML {
            HTML(
                .lang(context.site.language),
                .head(for: section, on: context.site),
                .body(.class("has-navbar-fixed-top"),
                      .navbar(for: context, selectedSection: section.id),
                      .section(.class("text container has-text-centered"), .contentBody(section.body)),
                      .footer(for: context.site)
                )
            )
        }
        
        func makeItemHTML(for item: Item<DemaciaWebsite>, context: PublishingContext<DemaciaWebsite>) throws -> HTML {
            HTML(
                .lang(context.site.language),
                .head(for: item, on: context.site),
                .body(
                    .class("item-page"),
                    .header(for: context, selectedSection: item.sectionID),
                    .wrapper(
                        .article(
                            .div(
                                .class("content"),
                                .contentBody(item.body)
                            ),
                            .span("Tagged with: "),
                            .tagList(for: item, on: context.site)
                        )
                    ),
                    .footer(for: context.site)
                )
            )
        }
        
        func makePageHTML(for page: Page, context: PublishingContext<DemaciaWebsite>) throws -> HTML {
            HTML(
                .lang(context.site.language),
                .head(for: page, on: context.site),
                .body(
                    .header(for: context, selectedSection: nil),
                    .wrapper(.contentBody(page.body)),
                    .footer(for: context.site)
                )
            )
        }
        
        func makeTagListHTML(for page: TagListPage, context: PublishingContext<DemaciaWebsite>) throws -> HTML? {
            HTML(
                .lang(context.site.language),
                .head(for: page, on: context.site),
                .body(
                    .header(for: context, selectedSection: nil),
                    .wrapper(
                        .h1("Browse all tags"),
                        .ul(
                            .class("all-tags"),
                            .forEach(page.tags.sorted()) { tag in
                                .li(
                                    .class("tag"),
                                    .a(
                                        .href(context.site.path(for: tag)),
                                        .text(tag.string)
                                    )
                                )
                            }
                        )
                    ),
                    .footer(for: context.site)
                )
            )
        }
        
        func makeTagDetailsHTML(for page: TagDetailsPage, context: PublishingContext<DemaciaWebsite>) throws -> HTML? {
            HTML(
                .lang(context.site.language),
                .head(for: page, on: context.site),
                .body(
                    .header(for: context, selectedSection: nil),
                    .wrapper(
                        .h1(
                            "Tagged with ",
                            .span(.class("tag"), .text(page.tag.string))
                        ),
                        .a(
                            .class("browse-all"),
                            .text("Browse all tags"),
                            .href(context.site.tagListPath)
                        ),
                        .itemList(
                            for: context.items(
                                taggedWith: page.tag,
                                sortedBy: \.date,
                                order: .descending
                            ),
                            on: context.site
                        )
                    ),
                    .footer(for: context.site)
                )
            )
        }
    }
}

extension Node where Context == HTML.DocumentContext {
    static func head(
        for location: Publish.Location,
        on site: DemaciaWebsite,
        titleSeparator: String = " | ",
        stylesheetPaths: [Path] = ["/styles.css"],
        rssFeedPath: Path? = .defaultForRSSFeed,
        rssFeedTitle: String? = nil
    ) -> Node {
        var title = location.title
        
        if title.isEmpty {
            title = site.name
        } else {
            title.append(titleSeparator + site.name)
        }
        
        var description = location.description
        
        if description.isEmpty {
            description = site.description
        }
        
        return .head(
            .encoding(.utf8),
            .siteName(site.name),
            .url(site.url(for: location)),
            .link(.rel(.preconnect), .href("https://fonts.gstatic.com")),
            .title(title),
            .description(description),
            .twitterCardType(location.imagePath == nil ? .summary : .summaryLargeImage),
            .forEach(stylesheetPaths, { .stylesheet($0) }),
            .meta(.name("viewport"), .content("initial-scale=1, viewport-fit=cover")),
            .base(.href(site.url.absoluteString)),
            .unwrap(site.favicon, { .favicon($0) }),
            .unwrap(location.imagePath ?? site.imagePath, { path in
                let url = site.url(for: path)
                return .socialImageLink(url)
            })
        )
    }
}

extension Node where Context == HTML.BodyContext {
    static func figure(_ nodes: Node...) -> Self {
        .element(named: "figure", nodes: nodes)
    }
    
    static func slideshow(for context: PublishingContext<DemaciaWebsite>) -> Node {
        .div(.class("slideshow"),
             .div(.class("slides"),
                  .forEach(slides) { slide in
                    let className = slides.firstIndex(of: slide) == 0 ? "slide active" : "slide"
                    
                    return .image(for: context, at: slide, widthPercentageOnPage: 100, class: className, alt: "Slideshow")
                  }
             ),
             .div(.class("controls"),
                  .forEach(slides) { slide in
                    .div(.class(slides.firstIndex(of: slide) == 0 ? "control active" : "control"))
                  }
             ),
             .script(.src("/js/slides.js"))
        )
    }
    
    static func wrapper(_ nodes: Node...) -> Node {
        .div(.class("wrapper"), .group(nodes))
    }
    
    static func header(
        for context: PublishingContext<DemaciaWebsite>,
        selectedSection: DemaciaWebsite.SectionID?
    ) -> Node {
        let sectionIDs = DemaciaWebsite.SectionID.allCases
        
        return .header(
            .wrapper(
                .a(.class("site-name"), .href("/"), .text(context.site.name)),
                .if(sectionIDs.count > 1,
                    .nav(
                        .ul(.forEach(sectionIDs) { section in
                            .li(.a(
                                .class(section == selectedSection ? "selected" : ""),
                                .href(context.sections[section].path),
                                .text(context.sections[section].title)
                            ))
                        })
                    )
                )
            )
        )
    }
    
    static func navbar(for context: PublishingContext<DemaciaWebsite>, selectedSection: DemaciaWebsite.SectionID?) -> Node {
        let sectionIDs = DemaciaWebsite.SectionID.allCases
        
        return .div(.class(selectedSection == nil ? "navbar is-fixed-top animate-start" : "navbar is-fixed-top"),
                    .a(.href("/"),
                       .div(.class("has-text-centered logo-outer"),
                            .figure(.logo()),
                            .h1(.class("title is-1"), .style("text-transform: uppercase;"), .text("Demacia")),
                            .h2(.class("subtitle is-2"), .text("Ness Ziona"))
                       )
                    ),
                    .div(.class("navbar-menu"), .id("navbar"),
                         .div(.class("navbar-start"),
                              .forEach(sectionIDs, { section in
                                .a(.class(section == selectedSection ? "navbar-item is-active" : "navbar-item"),
                                   .href(context.sections[section].path),
                                   .text(context.sections[section].title)
                                )
                              })
                         )
                    )
        )
    }
    
    static func image(for context: PublishingContext<DemaciaWebsite>, at filePath: String, widthPercentageOnPage: Int, class className: String = "", alt: String = "") -> Node {
        let fileExt = filePath.split(separator: ".").last!
        let fileNoExtPath = filePath.replacingOccurrences(of: "." + fileExt, with: "")
        let screenSizes = [768, 1024, 1216, 1408]
        let fileSizes = screenSizes.map { Int(round(Double($0 * widthPercentageOnPage) * 0.01)) }
        let srcset = screenSizes.enumerated().map { "\(fileNoExtPath)-\($1)px.webp \(fileSizes[$0])w" }.joined(separator: ", ")
        let sizes = screenSizes.enumerated().map { screenSizes.last == $1 ? "\(widthPercentageOnPage)vw": "(max-width: \($1)px) \(widthPercentageOnPage)vw" }.joined(separator: ", ")
        
        images.append(Image(path: filePath, width: widthPercentageOnPage))
        
        return .picture(.class(className),
                        .source(.srcset(srcset), .sizes(sizes), .type("image/webp")),
                        .img(.src(fileExt == "png" ? filePath : fileNoExtPath + ".jpg"), .alt(alt))
        )
    }
    
    static func itemList(for items: [Item<DemaciaWebsite>], on site: DemaciaWebsite) -> Node {
        .ul(
            .class("item-list"),
            .forEach(items) { item in
                .li(.article(
                    .h1(.a(
                        .href(item.path),
                        .text(item.title)
                    )),
                    .tagList(for: item, on: site),
                    .p(.text(item.description))
                ))
            }
        )
    }
    
    static func tagList(for item: Item<DemaciaWebsite>, on site: DemaciaWebsite) -> Node {
        .ul(.class("tag-list"), .forEach(item.tags) { tag in
            .li(.a(
                .href(site.path(for: tag)),
                .text(tag.string)
            ))
        })
    }
    
    static func footer(for site: DemaciaWebsite) -> Node {
        .footer(
            .p("Demacia FRC 2020"),
            .div(.class("social-media"),
                 .a(.href("https://www.youtube.com/c/Demacia5635"), .youtubeIcon()),
                 .a(.href("https://instagram.com/Demacia5635"), .instagramIcon()),
                 .a(.href("https://facebook.com/Demacia5635"), .facebookIcon()),
                 .a(.href("https://github.com/Demacia5635"), .githubIcon()),
                 .a(.href("https://www.thebluealliance.com/team/5635"), .blueAllianceIcon()),
                 .a(.href("mailto:demacia5635@gmail.com"), .mailIcon())
            )
        )
    }
    
    static func logo() -> Node {
        .svg(.viewbox("0 0 1510.89 1530.445"), .xmlns("http://www.w3.org/2000/svg"),
             .title("The Demacia logo"),
             .path(.fillRule(.evenOdd), .fill("rgb(53, 54, 58)"),
                   .d("M737.000,1470.000 L1452.000,1220.000 L740.000,962.000 L24.000,1223.000 L737.000,1470.000 Z")),
             .path(.fillRule(.evenOdd), .fill("rgb(0, 113, 188)"),
                   .d("M1467.500,1217.500 L1467.500,1228.000 L1091.977,1228.000 L1208.276,1328.096 L1200.935,1335.904 L1075.565,1228.000 L883.630,1228.000 L935.078,1336.717 L943.967,1355.500 L1091.090,1355.500 L1091.090,1366.000 L948.936,1366.000 L965.899,1401.846 L955.887,1406.154 L936.885,1366.000 L745.524,1366.000 L745.524,1486.000 L743.000,1486.000 L734.546,1486.000 L732.500,1486.000 L732.500,1366.000 L550.557,1366.000 L520.788,1432.154 L511.212,1427.846 L539.043,1366.000 L402.000,1366.000 L402.000,1355.500 L543.768,1355.500 L593.737,1244.457 L601.143,1228.000 L416.663,1228.000 L284.510,1346.904 L277.490,1339.096 L400.965,1228.000 L38.000,1228.000 L38.000,1217.500 L412.635,1217.500 L482.099,1155.000 L373.000,1155.000 L373.000,1144.500 L493.769,1144.500 L554.342,1090.000 L551.000,1090.000 L551.000,1079.500 L566.012,1079.500 L666.490,989.096 L673.510,996.904 L581.711,1079.500 L667.968,1079.500 L727.212,947.846 L732.500,950.225 L732.500,945.000 L734.546,945.000 L743.000,945.000 L745.524,945.000 L745.524,950.225 L751.053,947.846 L813.356,1079.500 L903.027,1079.500 L807.061,996.904 L814.401,989.096 L919.439,1079.500 L935.298,1079.500 L935.298,1090.000 L931.638,1090.000 L994.961,1144.500 L1121.412,1144.500 L1121.412,1155.000 L1007.160,1155.000 L1079.777,1217.500 L1467.500,1217.500 ZM428.333,1217.500 L605.868,1217.500 L633.993,1155.000 L497.798,1155.000 L428.333,1217.500 ZM570.041,1090.000 L552.402,1105.870 L509.468,1144.500 L638.718,1144.500 L663.243,1090.000 L570.041,1090.000 ZM732.500,961.682 L724.576,979.290 L679.482,1079.500 L732.500,1079.500 L732.500,961.682 ZM732.500,1090.000 L674.757,1090.000 L650.232,1144.500 L732.500,1144.500 L732.500,1090.000 ZM732.500,1155.000 L645.507,1155.000 L624.968,1200.643 L617.382,1217.500 L732.500,1217.500 L732.500,1155.000 ZM732.500,1228.000 L612.657,1228.000 L555.282,1355.500 L732.500,1355.500 L732.500,1228.000 ZM745.524,1355.500 L931.916,1355.500 L878.301,1242.203 L871.579,1228.000 L745.524,1228.000 L745.524,1355.500 ZM745.524,1217.500 L866.611,1217.500 L837.034,1155.000 L745.524,1155.000 L745.524,1217.500 ZM745.524,1144.500 L832.065,1144.500 L831.602,1143.521 L806.274,1090.000 L745.524,1090.000 L745.524,1144.500 ZM745.524,961.628 L745.524,1079.500 L801.305,1079.500 L745.524,961.628 ZM944.063,1114.819 L915.226,1090.000 L818.324,1090.000 L832.733,1120.447 L844.115,1144.500 L978.548,1144.500 L944.063,1114.819 ZM990.748,1155.000 L849.084,1155.000 L878.661,1217.500 L1063.365,1217.500 L990.748,1155.000 Z")),
             .path(.fillRule(.evenOdd), .fill("rgb(255, 255, 255)"),
                   .d("M739.469,1508.395 L0.469,1251.395 L0.469,440.395 L91.778,408.653 C96.892,420.869 102.446,434.265 106.591,444.600 L39.000,468.000 L38.000,1222.000 L738.000,1466.000 L1438.000,1222.000 L1438.000,466.000 L1367.648,441.917 L1386.226,406.751 L1478.469,438.395 L1479.469,1251.395 L739.469,1508.395 ZM696.337,198.488 L696.669,240.314 L293.434,379.915 L242.580,356.229 L696.337,198.488 ZM1194.656,382.697 L775.637,239.255 L768.353,194.784 L1238.047,355.916 L1194.656,382.697 Z")),
             .path(.fillRule(.evenOdd), .fill("rgb(53, 54, 58)"),
                   .d("M432.000,382.000 L432.000,455.323 L390.000,435.000 L322.000,413.000 L248.000,359.000 L192.000,324.946 L192.000,226.000 L430.000,146.000 L430.000,273.000 L619.000,460.000 L543.000,471.000 L432.000,382.000 ZM266.883,704.765 L286.440,743.880 L38.000,738.000 L38.000,713.000 C38.000,713.000 124.076,700.209 266.883,704.765 ZM432.000,882.677 L432.000,1131.000 L377.000,1127.000 L376.201,822.413 C392.795,840.414 419.558,869.406 432.000,882.677 Z")),
             .path(.fillRule(.evenOdd), .fill("rgb(28, 80, 99)"),
                   .d("M281.565,734.129 L292.000,755.000 L362.000,807.000 C362.000,807.000 368.167,813.700 377.000,823.280 C377.000,945.535 377.000,1152.631 377.000,1176.000 C245.667,1246.000 38.000,1221.000 38.000,1221.000 L38.000,737.000 C38.000,737.000 167.058,730.894 281.565,734.129 Z")),
             .path(.fillRule(.evenOdd), .fill("rgb(0, 113, 188)"),
                   .d("M598.000,863.000 L536.000,801.000 C536.000,801.000 512.000,706.875 510.000,673.000 C508.000,639.125 516.000,579.000 516.000,579.000 L476.000,519.000 L452.000,465.000 L432.000,455.323 L432.000,380.000 L621.000,533.000 L621.000,872.628 L598.000,863.000 ZM438.000,889.000 C443.503,894.589 553.119,910.472 621.000,919.840 L621.000,1071.000 L432.000,1131.000 L432.000,882.677 C434.844,885.710 436.946,887.930 438.000,889.000 Z")),
             .path(.fillRule(.evenOdd), .fill("rgb(22, 192, 218)"),
                   .d("M430.000,147.000 L616.000,365.000 L616.000,459.000 L430.000,274.000 L430.000,147.000 ZM187.950,561.555 L170.000,581.000 L204.000,617.000 L258.000,687.000 L269.611,710.222 C166.367,707.590 38.000,713.000 38.000,713.000 L38.000,570.000 C38.000,570.000 107.714,546.020 187.950,561.555 ZM134.000,1189.000 L82.000,1188.000 L82.000,769.000 L134.000,767.000 L134.000,1189.000 ZM227.000,1184.000 L175.000,1189.000 L174.000,770.000 L227.000,769.000 L227.000,1184.000 ZM318.000,1166.000 L269.000,1179.000 L269.000,773.000 L318.000,780.000 L318.000,1166.000 Z")),
             .path(.fillRule(.evenOdd), .fill("rgb(28, 80, 99)"),
                   .d("M978.000,513.000 L956.000,631.000 L960.000,741.000 L914.000,817.000 L852.000,861.089 L852.000,349.000 L1002.000,115.000 L1002.000,493.267 L978.000,513.000 ZM1002.000,883.891 L1002.000,1165.000 L852.000,1102.000 L852.000,920.219 L1002.000,883.891 Z")),
             .path(.fillRule(.evenOdd), .fill("rgb(53, 54, 58)"),
                   .d("M1188.000,1223.000 L1188.000,721.308 L1252.000,677.000 L1196.000,679.000 L1332.000,551.000 L1266.000,573.000 L1380.000,405.000 L1298.000,419.000 L1385.705,259.377 L1438.000,268.000 L1438.000,1215.000 L1188.000,1223.000 ZM1370.000,259.000 L1310.000,317.000 L1214.000,379.000 L1188.000,389.685 L1188.000,227.000 L1037.000,336.000 L1037.000,464.489 L1002.000,493.267 L1002.000,115.000 L1250.000,202.000 L1250.000,237.000 L1372.328,257.171 L1370.000,259.000 ZM1037.000,875.414 L1037.000,1164.000 L1002.000,1165.000 L1002.000,883.891 L1037.000,875.414 Z")),
             .path(.fillRule(.evenOdd), .fill("rgb(0, 113, 188)"),
                   .d("M1068.000,439.000 L1037.000,464.489 L1037.000,335.000 L1188.000,226.000 L1188.000,389.685 L1068.000,439.000 ZM1080.000,865.000 L1074.000,833.000 L1170.000,769.000 L1148.000,749.000 L1188.000,721.308 L1188.000,1224.000 L1037.000,1172.000 L1037.000,875.414 L1080.000,865.000 Z")),
             .path(.fillRule(.evenOdd), .fill("rgb(24, 192, 219)"),
                   .d("M1038.000,392.000 L1188.000,302.000 L1188.000,349.000 L1038.000,435.000 L1038.000,392.000 Z")),
             .path(.fillRule(.evenOdd), .fill("rgb(255, 255, 255)"),
                   .d("M1332.226,403.424 C1332.226,403.424 1361.729,401.949 1420.737,322.536 C1437.015,404.899 1319.508,532.642 1319.508,532.642 C1319.508,532.642 1326.376,537.305 1376.990,500.083 C1391.233,547.819 1275.761,644.562 1275.761,644.562 C1275.761,644.562 1282.629,650.370 1304.757,634.896 C1287.715,681.742 1215.736,741.221 1215.736,741.221 C1215.736,741.221 1215.736,741.688 1226.928,745.800 C1194.462,800.034 1116.034,833.810 1116.034,833.810 C1116.034,833.810 1116.288,833.937 1125.699,840.932 C1058.044,951.708 782.845,947.257 782.845,947.257 C782.845,947.257 778.368,963.791 781.827,966.080 C813.659,987.147 913.475,969.667 916.629,969.641 C929.760,969.535 926.135,995.471 921.716,997.113 C864.336,1018.430 803.446,1005.761 783.862,1015.936 C764.278,1026.110 763.006,1117.427 763.006,1129.891 C763.006,1141.315 779.030,1154.056 775.723,1159.906 C766.976,1175.384 737.063,1181.273 737.063,1181.273 C737.063,1181.277 737.063,1181.277 737.063,1181.277 C737.063,1181.277 707.147,1175.388 698.399,1159.910 C695.093,1154.060 711.118,1141.319 711.118,1129.895 C711.118,1117.431 709.846,1026.114 690.260,1015.939 C670.673,1005.765 609.779,1018.434 552.393,997.116 C547.974,995.475 544.348,969.539 557.481,969.645 C560.635,969.670 660.460,987.151 692.294,966.083 C695.754,963.794 691.277,947.260 691.277,947.260 C691.277,947.260 416.053,951.712 348.391,840.935 C357.803,833.940 358.057,833.813 358.057,833.813 C358.057,833.813 279.622,800.036 247.154,745.802 C258.346,741.690 258.346,741.224 258.346,741.224 C258.346,741.224 186.360,681.744 169.318,634.899 C191.447,650.373 198.315,644.565 198.315,644.565 C198.315,644.565 82.833,547.821 97.078,500.085 C147.697,537.307 154.564,532.644 154.564,532.644 C154.564,532.644 37.047,404.900 53.327,322.537 C112.340,401.951 141.846,403.426 141.846,403.426 C141.846,403.426 35.012,251.263 38.065,155.673 C105.217,295.625 373.828,402.408 373.828,402.408 C380.346,406.676 546.846,449.445 537.640,631.338 C536.752,648.879 507.116,838.849 690.260,872.477 C716.205,623.995 630.724,140.191 737.063,0.001 C843.392,140.190 757.919,623.992 783.862,872.474 C966.989,838.846 937.356,648.877 936.468,631.335 C927.263,449.443 1093.747,406.674 1100.265,402.407 C1100.265,402.407 1368.851,295.624 1435.997,155.672 C1439.050,251.262 1332.226,403.424 1332.226,403.424 ZM492.363,681.193 C496.687,625.878 491.954,599.320 492.363,591.148 C497.337,491.600 352.461,440.563 352.461,440.563 C352.461,440.563 220.191,386.383 136.759,323.554 C187.123,419.959 314.306,506.189 314.306,506.189 C314.306,506.189 220.700,515.347 136.250,445.650 C144.898,479.735 312.271,600.305 312.271,600.305 C312.271,600.305 265.977,609.971 195.772,587.078 C193.737,600.305 353.987,689.333 353.987,689.333 C353.987,689.333 340.252,701.543 271.064,696.455 C301.079,729.014 385.529,762.591 385.529,762.591 C385.529,762.591 367.273,775.512 339.743,779.379 C389.599,817.025 467.944,836.865 467.944,836.865 C467.944,836.865 459.041,847.412 432.332,853.654 C509.914,902.120 638.369,904.018 638.369,904.018 C512.712,853.145 488.018,736.764 492.363,681.193 ZM737.063,103.146 C737.063,103.146 737.063,103.146 737.063,103.146 C737.063,103.146 700.689,147.431 737.063,750.635 C737.063,750.634 737.063,750.634 737.063,750.633 C773.434,147.430 737.063,103.146 737.063,103.146 ZM1121.630,440.561 C1121.630,440.561 976.767,491.598 981.741,591.146 C982.149,599.318 977.417,625.876 981.741,681.191 C986.085,736.761 961.393,853.142 835.748,904.015 C835.748,904.015 964.191,902.117 1041.766,853.651 C1015.060,847.409 1006.158,836.863 1006.158,836.863 C1006.158,836.863 1084.495,817.022 1134.347,779.376 C1106.820,775.509 1088.565,762.588 1088.565,762.588 C1088.565,762.588 1173.007,729.012 1203.019,696.453 C1133.838,701.540 1120.104,689.331 1120.104,689.331 C1120.104,689.331 1280.340,600.303 1278.305,587.076 C1208.106,609.969 1161.816,600.303 1161.816,600.303 C1161.816,600.303 1329.174,479.734 1337.821,445.649 C1253.379,515.345 1159.781,506.188 1159.781,506.188 C1159.781,506.188 1286.952,419.958 1337.313,323.553 C1253.888,386.382 1121.630,440.561 1121.630,440.561 Z"))
        )
    }
}

extension Node where Context == HTML.AnchorContext {
    
    static func youtubeIcon() -> Node {
        .svg(.viewbox("0 0 24 24"), .xmlns("http://www.w3.org/2000/svg"),
             .title("Go to our YouTube channel"),
             .path(
                .d("M23.495 6.205a3.007 3.007 0 0 0-2.088-2.088c-1.87-.501-9.396-.501-9.396-.501s-7.507-.01-9.396.501A3.007 3.007 0 0 0 .527 6.205a31.247 31.247 0 0 0-.522 5.805 31.247 31.247 0 0 0 .522 5.783 3.007 3.007 0 0 0 2.088 2.088c1.868.502 9.396.502 9.396.502s7.506 0 9.396-.502a3.007 3.007 0 0 0 2.088-2.088 31.247 31.247 0 0 0 .5-5.783 31.247 31.247 0 0 0-.5-5.805zM9.609 15.601V8.408l6.264 3.602z"),
                .fill("#fff")
             )
        )
    }
    
    static func instagramIcon() -> Node {
        .svg(.viewbox("0 0 24 24"), .xmlns("http://www.w3.org/2000/svg"),
             .title("Go to our Instagram page"),
             .path(
                .d("M12 0C8.74 0 8.333.015 7.053.072 5.775.132 4.905.333 4.14.63c-.789.306-1.459.717-2.126 1.384S.935 3.35.63 4.14C.333 4.905.131 5.775.072 7.053.012 8.333 0 8.74 0 12s.015 3.667.072 4.947c.06 1.277.261 2.148.558 2.913.306.788.717 1.459 1.384 2.126.667.666 1.336 1.079 2.126 1.384.766.296 1.636.499 2.913.558C8.333 23.988 8.74 24 12 24s3.667-.015 4.947-.072c1.277-.06 2.148-.262 2.913-.558.788-.306 1.459-.718 2.126-1.384.666-.667 1.079-1.335 1.384-2.126.296-.765.499-1.636.558-2.913.06-1.28.072-1.687.072-4.947s-.015-3.667-.072-4.947c-.06-1.277-.262-2.149-.558-2.913-.306-.789-.718-1.459-1.384-2.126C21.319 1.347 20.651.935 19.86.63c-.765-.297-1.636-.499-2.913-.558C15.667.012 15.26 0 12 0zm0 2.16c3.203 0 3.585.016 4.85.071 1.17.055 1.805.249 2.227.415.562.217.96.477 1.382.896.419.42.679.819.896 1.381.164.422.36 1.057.413 2.227.057 1.266.07 1.646.07 4.85s-.015 3.585-.074 4.85c-.061 1.17-.256 1.805-.421 2.227-.224.562-.479.96-.899 1.382-.419.419-.824.679-1.38.896-.42.164-1.065.36-2.235.413-1.274.057-1.649.07-4.859.07-3.211 0-3.586-.015-4.859-.074-1.171-.061-1.816-.256-2.236-.421-.569-.224-.96-.479-1.379-.899-.421-.419-.69-.824-.9-1.38-.165-.42-.359-1.065-.42-2.235-.045-1.26-.061-1.649-.061-4.844 0-3.196.016-3.586.061-4.861.061-1.17.255-1.814.42-2.234.21-.57.479-.96.9-1.381.419-.419.81-.689 1.379-.898.42-.166 1.051-.361 2.221-.421 1.275-.045 1.65-.06 4.859-.06l.045.03zm0 3.678c-3.405 0-6.162 2.76-6.162 6.162 0 3.405 2.76 6.162 6.162 6.162 3.405 0 6.162-2.76 6.162-6.162 0-3.405-2.76-6.162-6.162-6.162zM12 16c-2.21 0-4-1.79-4-4s1.79-4 4-4 4 1.79 4 4-1.79 4-4 4zm7.846-10.405c0 .795-.646 1.44-1.44 1.44-.795 0-1.44-.646-1.44-1.44 0-.794.646-1.439 1.44-1.439.793-.001 1.44.645 1.44 1.439z"),
                .fill("#fff")
             )
        )
    }
    
    static func facebookIcon() -> Node {
        .svg(.viewbox("0 0 24 24"), .xmlns("http://www.w3.org/2000/svg"),
             .title("Go to our Facebook page"),
             .path(
                .d("M23.9981 11.9991C23.9981 5.37216 18.626 0 11.9991 0C5.37216 0 0 5.37216 0 11.9991C0 17.9882 4.38789 22.9522 10.1242 23.8524V15.4676H7.07758V11.9991H10.1242V9.35553C10.1242 6.34826 11.9156 4.68714 14.6564 4.68714C15.9692 4.68714 17.3424 4.92149 17.3424 4.92149V7.87439H15.8294C14.3388 7.87439 13.8739 8.79933 13.8739 9.74824V11.9991H17.2018L16.6698 15.4676H13.8739V23.8524C19.6103 22.9522 23.9981 17.9882 23.9981 11.9991Z"),
                .fill("#fff")
             )
        )
    }
    
    static func githubIcon() -> Node {
        .svg(.viewbox("0 0 24 24"), .xmlns("http://www.w3.org/2000/svg"),
             .title("Go to our GitHub page"),
             .path(
                .d("M12 .297c-6.63 0-12 5.373-12 12 0 5.303 3.438 9.8 8.205 11.385.6.113.82-.258.82-.577 0-.285-.01-1.04-.015-2.04-3.338.724-4.042-1.61-4.042-1.61C4.422 18.07 3.633 17.7 3.633 17.7c-1.087-.744.084-.729.084-.729 1.205.084 1.838 1.236 1.838 1.236 1.07 1.835 2.809 1.305 3.495.998.108-.776.417-1.305.76-1.605-2.665-.3-5.466-1.332-5.466-5.93 0-1.31.465-2.38 1.235-3.22-.135-.303-.54-1.523.105-3.176 0 0 1.005-.322 3.3 1.23.96-.267 1.98-.399 3-.405 1.02.006 2.04.138 3 .405 2.28-1.552 3.285-1.23 3.285-1.23.645 1.653.24 2.873.12 3.176.765.84 1.23 1.91 1.23 3.22 0 4.61-2.805 5.625-5.475 5.92.42.36.81 1.096.81 2.22 0 1.606-.015 2.896-.015 3.286 0 .315.21.69.825.57C20.565 22.092 24 17.592 24 12.297c0-6.627-5.373-12-12-12"),
                .fill("#fff")
             )
        )
    }
    
    static func blueAllianceIcon() -> Node {
        .svg(.viewbox("0 0 512 512"), .xmlns("http://www.w3.org/2000/svg"),
             .title("Go to our The Blue Alliance page"),
             .path(
                .d("M399.181+5.99999C409.025+5.99999+417.079+14.1528+417.079+24.1174L417.079+114.705C417.079+124.669+409.025+132.822+399.181+132.822L380.636+132.822L380.636+382.093C380.636+449.933+325.186+505.216+256.731+505.992L256.729+506L256.001+505.998C255.758+505.999+255.515+506+255.271+506L255.271+505.988L254.659+505.983C186.485+504.887+131.364+449.731+131.364+382.093L131.364+132.822L112.819+132.822C102.975+132.822+94.9213+124.669+94.9213+114.705L94.9213+24.1174C94.9213+14.1528+102.975+5.99999+112.819+5.99999L399.181+5.99999ZM243.609+382.093L158.228+382.093C158.228+431.38+195.475+472.229+243.609+478.589L243.609+382.093ZM353.772+382.093L269.848+382.093L269.849+478.385C317.275+471.402+353.772+430.881+353.772+382.093ZM243.609+256.729L157.603+256.729L157.603+355.854L243.609+355.854L243.609+256.729ZM354.397+256.729L269.848+256.729L269.848+355.854L354.397+355.854L354.397+256.729ZM243.609+132.822L157.603+132.822L157.603+230.49L243.609+230.49L243.609+132.822ZM354.397+132.822L269.848+132.822L269.848+230.49L354.397+230.49L354.397+132.822Z"),
                .fill("#fff"), 
                .fillRule(.nonZero)
             )
        )
    }
    
    static func mailIcon() -> Node {
        .svg(.viewbox("0 0 180 180"), .xmlns("https://www.w3.org/20000/svg"),
             .title("Send us a mail"),
             .path(.d("M11.59+37.3942C11.59+37.3942+66.3584+104.209+90.1385+104.209C113.919+104.209+168.41+37.4147+168.41+37.4147"), .fill("none"), .stroke("#fff"), .strokeWidth(18)),
             .path(.d("M21.7744+25.8155L158.226+25.8155C163.982+25.8155+168.648+30.3655+168.648+35.9782L168.648+135.466C168.648+141.078+163.982+145.628+158.226+145.628L21.7744+145.628C16.0181+145.628+11.3517+141.078+11.3517+135.466L11.3517+35.9782C11.3517+30.3655+16.0181+25.8155+21.7744+25.8155Z"), .fill("none"), .stroke("#fff"), .strokeWidth(18))
        )
    }
}
