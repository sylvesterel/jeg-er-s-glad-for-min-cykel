import Foundation

/// Udstyr man kan have derhjemme. Rækkefølgen er den, de vises i.
enum Equipment: String, CaseIterable, Identifiable {
    case pump, oil, cloth, brush, soap, hexKeys, wrench15, tireLevers, patchKit, gauge

    var id: Self { self }

    var title: String {
        switch self {
        case .pump: "Cykelpumpe"
        case .oil: "Kædeolie"
        case .cloth: "Klud"
        case .brush: "Tandbørste"
        case .soap: "Opvaskemiddel"
        case .hexKeys: "Unbrakonøgler"
        case .wrench15: "Skruenøgle 15 mm"
        case .tireLevers: "Dækjern"
        case .patchKit: "Lappegrej"
        case .gauge: "Trykmåler"
        }
    }

    var detail: String {
        switch self {
        case .pump: "Til at pumpe luft i dækkene."
        case .oil: "En lille flaske olie til kæden."
        case .cloth: "En gammel t-shirt er fin."
        case .brush: "En gammel en eller en lille børste."
        case .soap: "Med varmt vand. Fjerner fedtet snavs."
        case .hexKeys: "Sekskantede nøgler, som til møbler."
        case .wrench15: "Til møtrikkerne midt på hjulet."
        case .tireLevers: "Plastikspatler, der løfter dækket af."
        case .patchKit: "Lapper og lim til en punktering."
        case .gauge: "Eller en pumpe med måler på."
        }
    }

    var symbol: String {
        switch self {
        case .pump: "wind"
        case .oil: "drop"
        case .cloth: "tshirt"
        case .brush: "paintbrush"
        case .soap: "flask"
        case .hexKeys: "hexagon"
        case .wrench15: "wrench.adjustable"
        case .tireLevers: "screwdriver"
        case .patchKit: "bandage"
        case .gauge: "gauge.with.dots.needle.67percent"
        }
    }
}

enum RideFrequency: String, CaseIterable, Identifiable {
    case daily, weekly, rarely

    var id: Self { self }

    var title: String {
        switch self {
        case .daily: "Hver dag"
        case .weekly: "Et par gange om ugen"
        case .rarely: "Sjældnere"
        }
    }
}

enum MaintenanceInterval: Int, CaseIterable, Comparable, Identifiable {
    case weekly, monthly, halfYear

    var id: Self { self }
    static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }

    var title: String {
        switch self {
        case .weekly: "Hver uge"
        case .monthly: "Hver måned"
        case .halfYear: "Hvert halve år"
        }
    }

    /// Cykler man hver dag, skal det gøres oftere; cykler man sjældent, sjældnere.
    func adjusted(for frequency: RideFrequency) -> Self {
        switch frequency {
        case .daily: Self(rawValue: rawValue - 1) ?? self
        case .weekly: self
        case .rarely: Self(rawValue: rawValue + 1) ?? self
        }
    }
}

struct MaintenanceTask: Identifiable {
    let id: String
    let title: String
    let part: BikePart
    let minutes: Int
    /// Hvor ofte, når man cykler et par gange om ugen.
    let interval: MaintenanceInterval
    var equipment: Set<Equipment> = []
    /// Olie, sæbe og lignende i DKK.
    var consumablesCost = 0
    var drivetrains: Set<Drivetrain>? = nil
    var brakeTypes: Set<BrakeType>? = nil
    let steps: [GuideStep]

    func applies(to bike: Bike) -> Bool {
        (drivetrains?.contains(bike.drivetrain) ?? true) && (brakeTypes?.contains(bike.brakes) ?? true)
    }
}

enum MaintenanceCatalog {
    /// Typisk pris for et årligt eftersyn hos en cykelsmed.
    static let servicePrice = 600

    /// I den rækkefølge, de giver mening at gøre: vask først, olie efter rens, tjek til sidst.
    static let tasks: [MaintenanceTask] = [
        MaintenanceTask(
            id: "vask", title: "Vask cyklen", part: .frame, minutes: 15, interval: .monthly,
            equipment: [.cloth, .soap], consumablesCost: 5,
            steps: [
                GuideStep(
                    title: "Gør en spand klar",
                    detail: "Fyld en spand med varmt vand og lidt opvaskemiddel. Dyp kluden, og vrid den, så den ikke drypper.",
                    symbol: "drop",
                    tip: "Brug aldrig en højtryksrenser. Den presser vand ind i hjulenes lejer, og så ruster de.",
                    animation: .inspect, part: .frame
                ),
                GuideStep(
                    title: "Tør stellet af",
                    detail: "Tør stellet af oppefra og ned: styr, stang, sadel og til sidst de lave rør ved pedalerne. Skyl kluden, når den bliver sort.",
                    symbol: "hand.raised",
                    animation: .inspect, part: .frame
                ),
                GuideStep(
                    title: "Tør hjulene af",
                    detail: "Løft hjulet lidt, og drej det langsomt rundt, mens du tørrer fælgen af (metalringen dækket sidder på). Gør det samme med det andet hjul.",
                    symbol: "arrow.clockwise",
                    animation: .spinWheel, part: .tire
                ),
            ]
        ),
        MaintenanceTask(
            id: "rens-kaede", title: "Rens kæden", part: .chain, minutes: 15, interval: .monthly,
            equipment: [.brush, .soap, .cloth], consumablesCost: 5,
            steps: [
                GuideStep(
                    title: "Skrub kæden",
                    detail: "Dyp tandbørsten i det varme sæbevand. Skrub kæden ovenfra, mens du langsomt drejer pedalen baglæns med den anden hånd.",
                    symbol: "paintbrush",
                    tip: "Læg avispapir under. Det sorte snavs drypper.",
                    animation: .turnPedals, part: .chain
                ),
                GuideStep(
                    title: "Tør kæden tør",
                    detail: "Hold kluden om kæden, og drej pedalen baglæns 10 gange. Kæden glider gennem kluden. Bliv ved, til der ikke kommer mere sort på kluden.",
                    symbol: "hand.raised",
                    animation: .wipeChain, part: .chain
                ),
            ]
        ),
        MaintenanceTask(
            id: "smoer-kaede", title: "Smør kæden", part: .chain, minutes: 5, interval: .monthly,
            equipment: [.oil, .cloth], consumablesCost: 10,
            steps: [
                GuideStep(
                    title: "Dryp olie på kæden",
                    detail: "Hold flasken over kæden der, hvor den løber ind på det bageste tandhjul. Drej pedalen langsomt baglæns, og giv én lille dråbe på hvert led.",
                    symbol: "drop",
                    tip: "Én omgang er nok. Mere olie samler bare snavs.",
                    animation: .oilChain, part: .chain
                ),
                GuideStep(
                    title: "Lad olien trække ind",
                    detail: "Drej pedalerne baglæns 10 gange, så olien kommer ind i alle led. Vent et par minutter.",
                    symbol: "arrow.counterclockwise",
                    animation: .turnPedals, part: .chain
                ),
                GuideStep(
                    title: "Tør den overskydende olie af",
                    detail: "Hold kluden løst om kæden, og drej pedalen baglæns et par gange. Kæden skal føles let fedtet, ikke våd.",
                    symbol: "hand.raised",
                    animation: .wipeChain, part: .chain
                ),
            ]
        ),
        MaintenanceTask(
            id: "pump", title: "Pump dækkene", part: .tire, minutes: 5, interval: .weekly,
            equipment: [.pump],
            steps: [
                GuideStep(
                    title: "Find det rigtige tryk",
                    detail: "Kig på siden af dækket. Der står et tal med småt, fx \"3-5 bar\". Det er, hvor hårdt dækket skal pumpes.",
                    symbol: "magnifyingglass",
                    animation: .spinWheel, part: .tire
                ),
                GuideStep(
                    title: "Pump dækket",
                    detail: "Skru den lille hætte af ventilen (der hvor du pumper luft i). Sæt pumpen på, og pump. Tryk på dækket med tommelfingeren. Det skal føles hårdt og kun give en lille smule efter.",
                    symbol: "wind",
                    tip: "Har du en trykmåler, så pump til det tal, der står på dækket.",
                    animation: .pumpTire, part: .tire
                ),
                GuideStep(
                    title: "Gør det samme bagpå",
                    detail: "Tag pumpen af, og skru hætten på igen. Pump baghjulet på samme måde.",
                    symbol: "arrow.clockwise",
                    animation: .pumpTire, part: .tire
                ),
            ]
        ),
        MaintenanceTask(
            id: "daek-slid", title: "Tjek dækkene for glas og slid", part: .tire, minutes: 5, interval: .monthly,
            steps: [
                GuideStep(
                    title: "Kig dækket efter",
                    detail: "Løft hjulet, og drej det langsomt rundt. Kig efter glasskår, små sten og revner i gummiet.",
                    symbol: "magnifyingglass",
                    warning: "Pil glasskår ud med en fingernegl eller en tændstik, ikke med fingrene.",
                    animation: .spinWheel, part: .tire
                ),
                GuideStep(
                    title: "Mærk efter slid",
                    detail: "Er dækket blevet fladt på midten, eller kan du se stof under gummiet, så er det slidt op. Så er det tid til et nyt dæk.",
                    symbol: "hand.raised",
                    animation: .inspect, part: .tire
                ),
            ]
        ),
        MaintenanceTask(
            id: "bremser", title: "Tjek bremserne", part: .brakes, minutes: 3, interval: .weekly,
            brakeTypes: [.rim, .roller, .disc],
            steps: [
                GuideStep(
                    title: "Klem bremsegrebene",
                    detail: "Klem hårdt i begge bremsegreb på styret. De skal stoppe, før de rører styret.",
                    symbol: "hand.raised",
                    animation: .squeezeBrake, part: .brakes
                ),
                GuideStep(
                    title: "Skub cyklen frem",
                    detail: "Hold bremserne inde, og prøv at skubbe cyklen frem. Hjulene må ikke dreje.",
                    symbol: "arrow.right",
                    warning: "Kan du klemme grebet helt ind til styret, eller drejer hjulet stadig, så cykl ikke på den. Få bremsen spændt hos en cykelsmed.",
                    animation: .squeezeBrake, part: .brakes
                ),
            ]
        ),
        MaintenanceTask(
            id: "fodbremse", title: "Tjek fodbremsen", part: .brakes, minutes: 2, interval: .weekly,
            brakeTypes: [.coaster],
            steps: [
                GuideStep(
                    title: "Træd baglæns",
                    detail: "Sæt dig på cyklen, og træd pedalerne en lille smule baglæns. Bremsen skal tage fat, før pedalen har drejet en kvart omgang.",
                    symbol: "arrow.counterclockwise",
                    animation: .turnPedals, part: .pedals
                ),
                GuideStep(
                    title: "Prøv at skubbe",
                    detail: "Hold pedalen bremset, og prøv at skubbe cyklen frem. Baghjulet må ikke dreje.",
                    symbol: "arrow.right",
                    warning: "Drejer baghjulet, så cykl ikke på den. Få den tjekket hos en cykelsmed.",
                    animation: .spinWheel, part: .brakes
                ),
            ]
        ),
        MaintenanceTask(
            id: "lygter", title: "Tjek lygterne", part: .lights, minutes: 2, interval: .weekly,
            steps: [
                GuideStep(
                    title: "Tænd for lygterne",
                    detail: "Tænd for- og baglygten. For skal lyse hvidt, bag skal lyse rødt. Hold en hånd foran, så du kan se, om de lyser kraftigt.",
                    symbol: "flashlight.on.fill",
                    tip: "Lyser de svagt, så skift batterierne eller oplad dem.",
                    animation: .switchLight, part: .lights
                ),
            ]
        ),
        MaintenanceTask(
            id: "gear", title: "Tjek gearskiftet", part: .gears, minutes: 10, interval: .monthly,
            drivetrains: [.derailleur],
            steps: [
                GuideStep(
                    title: "Skift gennem alle gear",
                    detail: "Løft baghjulet, og drej pedalen med hånden. Klik gearet op og ned ét trin ad gangen. Kæden skal hoppe med det samme og køre stille.",
                    symbol: "gearshape.2",
                    animation: .shiftGears, part: .gears
                ),
                GuideStep(
                    title: "Juster, hvis det rasler",
                    detail: "Rasler kæden, eller hopper den for sent, så find den lille rillede skrue der, hvor kablet går ind i gearskifteren på styret. Drej den en halv omgang mod uret, og prøv igen.",
                    symbol: "arrow.counterclockwise",
                    tip: "Blev det værre, så drej den samme vej tilbage, og en halv omgang mere.",
                    animation: .adjustCable, part: .gears
                ),
            ]
        ),
        MaintenanceTask(
            id: "navgear", title: "Tjek navgearet", part: .gears, minutes: 5, interval: .halfYear,
            drivetrains: [.hubGear],
            steps: [
                GuideStep(
                    title: "Skift gennem alle gear",
                    detail: "Løft baghjulet, og drej pedalen med hånden. Skift gennem alle gear. Hvert gear skal tage fat med det samme, uden at pedalen glider.",
                    symbol: "gearshape.2",
                    animation: .shiftGears, part: .gears
                ),
                GuideStep(
                    title: "Juster kablet",
                    detail: "Glider et gear, så sæt gearet i midten. Find den lille rillede skrue ved gearskifteren på styret. Drej den lidt ad gangen, til gearet tager fat.",
                    symbol: "arrow.clockwise",
                    tip: "Nogle navgear har to små gule streger ved baghjulet. Står de ud for hinanden, sidder gearet rigtigt.",
                    animation: .adjustCable, part: .gears
                ),
            ]
        ),
        MaintenanceTask(
            id: "skruer", title: "Tjek at skruerne sidder fast", part: .handlebar, minutes: 5, interval: .halfYear,
            equipment: [.hexKeys],
            steps: [
                GuideStep(
                    title: "Tjek styret",
                    detail: "Stil dig foran cyklen, og hold forhjulet fast mellem knæene. Prøv at dreje styret. Kan det dreje, så stram skruerne midt på styret med unbrakonøglen (den sekskantede nøgle). Drej med uret.",
                    symbol: "arrow.left.and.right",
                    tip: "Det skal føles stramt, men du skal ikke tvinge den.",
                    animation: .tightenBolt, part: .handlebar
                ),
                GuideStep(
                    title: "Tjek sadlen",
                    detail: "Tag fat i sadlen, og prøv at dreje og vippe den. Sidder den løst, så stram skruen under sadlen med uret.",
                    symbol: "chair",
                    animation: .tightenBolt, part: .saddle
                ),
            ]
        ),
        MaintenanceTask(
            id: "hjul-fast", title: "Tjek at hjulene sidder fast", part: .tire, minutes: 5, interval: .halfYear,
            equipment: [.wrench15],
            steps: [
                GuideStep(
                    title: "Rusk i hjulet",
                    detail: "Løft forhjulet, og rusk det fra side til side. Det må ikke klonke eller flytte sig. Gør det samme med baghjulet.",
                    symbol: "arrow.left.and.right",
                    animation: .spinWheel, part: .tire
                ),
                GuideStep(
                    title: "Stram møtrikkerne",
                    detail: "Sidder hjulet løst, så sæt skruenøglen på møtrikken midt på hjulet. Drej med uret, på begge sider, til det føles stramt.",
                    symbol: "wrench.adjustable",
                    tip: "Har hjulet et lille håndtag i stedet for møtrikker, så åbn det, og luk det igen med et fast tryk.",
                    animation: .tightenBolt, part: .tire
                ),
            ]
        ),
    ]
}
