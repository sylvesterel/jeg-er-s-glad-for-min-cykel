import Foundation

/// Mock-reparationer. Priser er typiske danske 2025-priser i DKK.
/// Teksten er skrevet til en, der aldrig har repareret en cykel før.
extension Catalog {
    static let repairs: [Repair] = [

        // MARK: - Dæk og hjul

        Repair(
            id: "lap-slange",
            title: "Lap en punktering",
            summary: "Dækket er fladt, selv om du lige har pumpet det. Så er der hul i slangen (gummiringen inde i dækket), og det kan du lappe selv.",
            part: .tire,
            difficulty: .easy,
            minutes: 30,
            tools: [
                "Lappegrej (lapper, lim og sandpapir i en lille æske)",
                "2 dækjern (små plastikspatler)",
                "Cykelpumpe der passer til din ventil",
                "Skruenøgle 15 mm (kun hvis hjulet sidder fast med møtrikker)",
                "Kuglepen eller kridt",
            ],
            partsCost: 50,
            mechanicPrice: 249,
            steps: [
                GuideStep(
                    title: "Vend cyklen om",
                    detail: "Vend cyklen på hovedet, så den står på sadel og styr. Så kan hjulene dreje frit, og du har begge hænder fri.",
                    symbol: "arrow.uturn.down",
                    tip: "Læg en jakke eller et tæppe under, så sadel og styr ikke bliver ridset.",
                    animation: .flipBike
                ),
                GuideStep(
                    title: "Luk resten af luften ud",
                    detail: "Skru den lille hætte af ventilen (der hvor du pumper luft i). Tryk på spidsen af ventilen, til der ikke kommer mere luft ud.",
                    symbol: "wind",
                    tip: "Har du en almindelig cykelventil, kan du også skrue den rillede ring af og trække ventilen op.",
                    animation: .deflateTire
                ),
                GuideStep(
                    title: "Tag hjulet af",
                    detail: "Har du bremser, der klemmer om hjulets kant, så åbn dem først. Vip håndtaget i hjulets midte ud, eller drej møtrikkerne mod uret med 15 mm-nøglen. Løft hjulet ud.",
                    symbol: "wrench.adjustable",
                    tip: "Er det baghjulet, og sidder gearet inde i hjulets midte, er det besværligt at tage af. Lad det sidde, og træk kun slangen ud der, hvor hullet er.",
                    animation: .removeFrontWheel
                ),
                GuideStep(
                    title: "Lirk dækket af",
                    detail: "Sæt et dækjern ind under dækkets kant og vip det ned, så kanten løftes over fælgen (metalringen dækket sidder på). Sæt det andet dækjern ind 10 cm længere henne, og skub det rundt, til den ene side af dækket er fri. Træk slangen ud.",
                    symbol: "arrow.left.and.right",
                    tip: "De første 10 cm er altid stramme. Bagefter går det meget lettere.",
                    animation: .leverTire
                ),
                GuideStep(
                    title: "Find hullet",
                    detail: "Pump lidt luft i slangen, så den bliver rund. Før den langsomt forbi øret, og lyt efter en svag susen. Sæt en streg med kuglepen der, hvor luften kommer ud.",
                    symbol: "magnifyingglass",
                    tip: "Kan du ikke høre det, så hold slangen ned i en balje vand. Hullet er der, hvor der kommer bobler.",
                    animation: .spinWheel
                ),
                GuideStep(
                    title: "Find det, der stak hul",
                    detail: "Læg slangen ved siden af dækket med ventilen ud for ventilhullet. Nu kan du se, hvor i dækket hullet sidder. Find glasskåret, tornen eller stykket metal der, og fjern det.",
                    symbol: "hand.raised",
                    warning: "Mærk langsomt og forsigtigt på indersiden af dækket. Glasskår kan skære dig.",
                    animation: .spinWheel
                ),
                GuideStep(
                    title: "Slib og smør lim på",
                    detail: "Slib let omkring hullet med sandpapiret, til gummiet er mat. Smør et tyndt lag lim på, lidt større end lappen. Vent 3-5 minutter, til limen ikke længere klistrer.",
                    symbol: "drop",
                    tip: "Limen holder først, når den er tør. Venter du for kort tid, falder lappen af.",
                    animation: .inspect
                ),
                GuideStep(
                    title: "Tryk lappen fast",
                    detail: "Pil folien af bagsiden af lappen uden at røre limsiden. Læg lappen over hullet, og tryk hårdt i et minut, især på kanterne. Den tynde plastik på oversiden må gerne blive siddende.",
                    symbol: "bandage",
                    animation: .inspect
                ),
                GuideStep(
                    title: "Læg slangen tilbage",
                    detail: "Pump lige så meget luft i slangen, at den får form. Stik ventilen gennem hullet i fælgen, og læg resten af slangen ind i dækket. Tryk dækkets kant tilbage over fælgen med tommelfingrene.",
                    symbol: "arrow.triangle.2.circlepath",
                    tip: "Er det sidste stykke stramt, så klem dækket ind mod midten af fælgen hele vejen rundt. Så får du lidt ekstra plads.",
                    animation: .leverTire
                ),
                GuideStep(
                    title: "Pump dækket op",
                    detail: "Klem hele vejen rundt på dækket, så slangen ikke sidder i klemme under kanten. Pump op til det tryk, der står på siden af dækket.",
                    symbol: "speedometer",
                    animation: .pumpTire
                ),
                GuideStep(
                    title: "Sæt hjulet på igen",
                    detail: "Sæt hjulet tilbage, så det sidder lige i midten. Luk håndtaget, eller spænd møtrikkerne med uret, til de sidder stramt. Luk bremsen igen, hvis du åbnede den.",
                    symbol: "lock",
                    warning: "Prøv bremserne, før du kører ud i trafikken.",
                    animation: .tightenBolt
                ),
            ]
        ),

        Repair(
            id: "pump-daek",
            title: "Pump dækkene",
            summary: "Dækkene føles bløde, eller cyklen er tung at træde. For lidt luft giver også flere punkteringer, så tjek dem hver anden uge.",
            part: .tire,
            difficulty: .easy,
            minutes: 10,
            tools: ["Cykelpumpe med trykmåler (den lille urskive på pumpen)"],
            partsCost: 0,
            mechanicPrice: 100,
            steps: [
                GuideStep(
                    title: "Find tallet på dækket",
                    detail: "Kig på siden af dækket. Der står et tal med \"bar\" eller \"psi\", fx \"3,5-5 bar\". Det fortæller, hvor hårdt dækket skal pumpes.",
                    symbol: "magnifyingglass",
                    tip: "Kan du ikke finde tallet, så brug 4 bar på en bycykel og 6 bar på en racercykel.",
                    animation: .inspect
                ),
                GuideStep(
                    title: "Drej ventilen op",
                    detail: "Drej hjulet, til ventilen (der hvor du pumper luft i) sidder øverst. Skru den lille hætte af, og læg den et sikkert sted.",
                    symbol: "arrow.triangle.2.circlepath",
                    animation: .spinWheel
                ),
                GuideStep(
                    title: "Se hvilken ventil du har",
                    detail: "De fleste bycykler har en almindelig cykelventil. Er ventilen tynd med en lille møtrik i toppen, hedder den Presta. Ligner den ventilen på en bil, hedder den Schrader.",
                    symbol: "eye",
                    tip: "Har du Presta, så skru den lille møtrik i toppen et par omgange mod uret, før du pumper.",
                    animation: .inspect
                ),
                GuideStep(
                    title: "Sæt pumpen på",
                    detail: "Tryk pumpens mundstykke lige ned over ventilen. Vip det lille håndtag op, så mundstykket sidder fast. Det må ikke suse, når du pumper.",
                    symbol: "lock",
                    tip: "De fleste pumper passer til alle tre ventiler. Nogle har to huller i mundstykket – brug det, der passer.",
                    animation: .pumpTire
                ),
                GuideStep(
                    title: "Pump til tallet",
                    detail: "Pump med lange, rolige tag. Hold øje med viseren på pumpen, og stop, når den når tallet fra dækket.",
                    symbol: "speedometer",
                    animation: .pumpTire
                ),
                GuideStep(
                    title: "Tag pumpen af",
                    detail: "Vip håndtaget ned, og træk mundstykket lige af. Et kort pust er helt normalt. Skru hætten på igen.",
                    symbol: "checkmark.circle",
                    tip: "Husk også det andet hjul.",
                    animation: .inspect
                ),
                GuideStep(
                    title: "Kig dækket efter",
                    detail: "Drej hjulet langsomt, og kig på dækket hele vejen rundt. Se efter revner, glasskår og slidte pletter. Kan du se stof eller tråde under gummiet, skal dækket skiftes.",
                    symbol: "eye",
                    animation: .spinWheel
                ),
            ]
        ),

        Repair(
            id: "skift-daek",
            title: "Skift et slidt dæk",
            summary: "Dækket er glat, revnet, eller du kan se tråde gennem gummiet. Så er det tid til et nyt – og det kan du sagtens selv.",
            part: .tire,
            difficulty: .medium,
            minutes: 45,
            tools: [
                "Nyt dæk i samme størrelse",
                "Ny slange (anbefales, koster ca. 50 kr.)",
                "2 dækjern (små plastikspatler)",
                "Cykelpumpe der passer til din ventil",
                "Skruenøgle 15 mm (til møtrikkerne på hjulet)",
            ],
            partsCost: 300,
            mechanicPrice: 549,
            steps: [
                GuideStep(
                    title: "Find dækkets størrelse",
                    detail: "Kig på siden af det gamle dæk. Der står to tal, fx \"37-622\" eller \"700x35C\". Tag et billede af det, og vis det i butikken.",
                    symbol: "ruler",
                    tip: "Et dæk med punkteringsbeskyttelse koster 100-150 kr. mere, men sparer dig for mange punkteringer.",
                    animation: .inspect
                ),
                GuideStep(
                    title: "Vend cyklen om",
                    detail: "Vend cyklen på hovedet, så den står på sadel og styr. Så kan du nemt komme til hjulene.",
                    symbol: "arrow.uturn.down",
                    animation: .flipBike
                ),
                GuideStep(
                    title: "Luk luften ud",
                    detail: "Skru hætten af ventilen (der hvor du pumper luft i). Tryk på spidsen, til dækket er helt fladt.",
                    symbol: "wind",
                    animation: .deflateTire
                ),
                GuideStep(
                    title: "Tag hjulet af",
                    detail: "Drej møtrikkerne i hjulets midte mod uret med 15 mm-nøglen, og løft hjulet ud. Er det baghjulet, skal du måske først hægte gear- og bremsekablet af ved hjulets midte.",
                    symbol: "wrench.adjustable",
                    tip: "Tag billeder af hjulets midte fra begge sider, før du skiller noget ad. Så kan du se, hvordan alt skal sidde, når du samler igen.",
                    animation: .removeRearWheel
                ),
                GuideStep(
                    title: "Lirk det gamle dæk af",
                    detail: "Sæt et dækjern under dækkets kant, og vip kanten over fælgen (metalringen dækket sidder på). Skub det andet dækjern rundt, til den ene side er fri. Træk slangen ud, og tag resten af dækket af med hænderne.",
                    symbol: "arrow.left.and.right",
                    animation: .leverTire
                ),
                GuideStep(
                    title: "Tjek båndet i fælgen",
                    detail: "Inde i fælgen ligger et bånd, der dækker de små huller. Det skal dække alle huller og må ikke være flækket. Ellers kan hullernes kanter lave nye punkteringer.",
                    symbol: "circle.dashed",
                    animation: .spinWheel
                ),
                GuideStep(
                    title: "Sæt det nye dæk på",
                    detail: "Find pilen på siden af det nye dæk. Den skal pege den vej, hjulet drejer, når du kører fremad. Tryk den ene kant af dækket ind over fælgen hele vejen rundt.",
                    symbol: "arrow.triangle.2.circlepath",
                    animation: .leverTire
                ),
                GuideStep(
                    title: "Læg slangen i",
                    detail: "Pump lige nok luft i slangen til, at den får form. Stik ventilen gennem hullet i fælgen, og læg slangen ind i dækket. Tryk den sidste kant på med tommelfingrene: start ved ventilen, og slut på den modsatte side.",
                    symbol: "hand.raised",
                    tip: "Er det sidste stykke stramt, så klem dækket ind mod midten af fælgen hele vejen rundt. Så får du ekstra plads.",
                    animation: .leverTire
                ),
                GuideStep(
                    title: "Pump dækket op",
                    detail: "Pump til halvt tryk. Tjek, at den tynde linje på siden af dækket sidder lige langt fra fælgen hele vejen rundt. Pump så op til det tryk, der står på dækket.",
                    symbol: "speedometer",
                    animation: .pumpTire
                ),
                GuideStep(
                    title: "Sæt hjulet på",
                    detail: "Sæt hjulet i, så det sidder lige i midten mellem stellets to sider. Spænd møtrikkerne med uret, til de sidder stramt. Sæt kablerne på igen, som på dine billeder.",
                    symbol: "lock",
                    animation: .tightenBolt
                ),
                GuideStep(
                    title: "Prøv bremser og gear",
                    detail: "Vend cyklen om igen. Prøv bremserne og alle gear, mens du står stille.",
                    symbol: "checkmark.circle",
                    warning: "Prøv bremserne grundigt, før du kører ud i trafikken.",
                    animation: .squeezeBrake
                ),
            ]
        ),

        Repair(
            id: "ret-hjul",
            title: "Ret et hjul, der slingrer",
            summary: "Hjulet vipper fra side til side, når det drejer, eller det rammer bremsen. Små slag kan du rette selv, hvis du tager dig god tid.",
            part: .tire,
            difficulty: .hard,
            minutes: 60,
            tools: [
                "Egenøgle (lille nøgle til møtrikkerne på egerne) i den rigtige størrelse",
                "Kridt",
                "Evt. centreringsstativ (en holder til hjulet)",
            ],
            partsCost: 60,
            mechanicPrice: 250,
            steps: [
                GuideStep(
                    title: "Vend cyklen om",
                    detail: "Vend cyklen på hovedet, så den står på sadel og styr. Så kan hjulet dreje frit.",
                    symbol: "arrow.uturn.down",
                    animation: .flipBike
                ),
                GuideStep(
                    title: "Find det skæve sted",
                    detail: "Drej hjulet langsomt. Hold et stykke kridt helt tæt ved fælgen (metalringen dækket sidder på), uden at det rører. Der hvor fælgen rammer kridtet, slingrer hjulet.",
                    symbol: "eye",
                    animation: .spinWheel
                ),
                GuideStep(
                    title: "Mærk på egerne",
                    detail: "Klem to og to eger (de tynde metalpinde i hjulet) sammen hele vejen rundt. De skal føles nogenlunde lige stramme. Er en eger slap som spaghetti eller knækket, skal den skiftes først.",
                    symbol: "hand.raised",
                    warning: "Er en eger knækket i baghjulet, så tag cyklen til en mekaniker.",
                    animation: .inspect
                ),
                GuideStep(
                    title: "Forstå egenøglen",
                    detail: "Fælgen trækkes mod den side, hvor du strammer en eger. Kigger du ned på møtrikken fra dækket, strammer du ved at dreje med uret. Retningen forvirrer alle, så prøv en kvart omgang og se, hvad der sker.",
                    symbol: "arrow.clockwise",
                    animation: .inspect
                ),
                GuideStep(
                    title: "Stram egeren modsat slaget",
                    detail: "Midt i det skæve stykke: find en eger, der går til den modsatte side af hjulets midte. Stram den en kvart omgang.",
                    symbol: "wrench.adjustable",
                    animation: .tightenBolt
                ),
                GuideStep(
                    title: "Løsn naboegerne",
                    detail: "De to eger ved siden af går til samme side som slaget. Løsn dem hver en kvart omgang.",
                    symbol: "wrench.adjustable",
                    animation: .loosenBolt
                ),
                GuideStep(
                    title: "Drej og tjek igen",
                    detail: "Drej hjulet, og hold kridtet ved fælgen igen. Gentag de to forrige trin, til fælgen ikke rammer kridtet.",
                    symbol: "arrow.triangle.2.circlepath",
                    tip: "Mange små drejninger giver et meget bedre resultat end få store.",
                    animation: .spinWheel
                ),
                GuideStep(
                    title: "Lad egerne sætte sig",
                    detail: "Klem hårdt på egerne to og to hele vejen rundt. Små knæk er normale – det er egerne, der sætter sig. Tjek hjulet med kridtet igen bagefter.",
                    symbol: "hand.raised",
                    animation: .spinWheel
                ),
                GuideStep(
                    title: "Prøv bremserne",
                    detail: "Vend cyklen om igen. Drej hjulet, og tjek, at det ikke rammer bremser eller stel. Træk bremsen, og mærk, at den tager jævnt.",
                    symbol: "checkmark.circle",
                    warning: "Er fælgen bulet, eller slingrer hjulet stadig meget, så stop og få det tjekket. Et svagt hjul kan klappe sammen under kørsel.",
                    animation: .squeezeBrake
                ),
            ]
        ),

        // MARK: - Kæde

        Repair(
            id: "rens-smoer-kaede",
            title: "Rens og smør kæden",
            summary: "Kæden er sort, knirker eller larmer. Gør det en gang om måneden, oftere i regnvejr – så holder kæden dobbelt så længe.",
            part: .chain,
            difficulty: .easy,
            minutes: 20,
            tools: [
                "Kædeolie (fra cykelhandlen, ikke madolie)",
                "Affedtningsmiddel (opløser gammelt, snavset fedt)",
                "Gamle klude",
                "Evt. en gammel tandbørste",
            ],
            partsCost: 120,
            mechanicPrice: 250,
            steps: [
                GuideStep(
                    title: "Vend cyklen om",
                    detail: "Vend cyklen på hovedet, så den står på sadel og styr. Læg en avis under kæden, så du ikke sviner gulvet til.",
                    symbol: "arrow.uturn.down",
                    animation: .flipBike
                ),
                GuideStep(
                    title: "Tør det groveste af",
                    detail: "Hold en klud løst om den nederste del af kæden. Drej pedalen rundt med den anden hånd, så kæden løber gennem kluden. Flyt til et rent stykke klud, til der ikke kommer meget sort af.",
                    symbol: "hand.raised",
                    animation: .wipeChain
                ),
                GuideStep(
                    title: "Skrub den værste snavs væk",
                    detail: "Er kæden stadig sort og klistret, så kom affedtningsmiddel på en klud eller tandbørste. Skrub kæden og tandhjulene, og tør efter med en tør klud.",
                    symbol: "bubbles.and.sparkles",
                    warning: "Hold affedtningsmiddel og olie væk fra bremserne og fra hjulets kant.",
                    animation: .wipeChain
                ),
                GuideStep(
                    title: "Find et startled",
                    detail: "Kig efter et kædeled, der ser lidt anderledes ud end de andre, ofte i en anden farve. Det er dit startpunkt, så du ved, hvornår du er hele vejen rundt.",
                    symbol: "link",
                    tip: "Er alle led ens, så sæt et lille stykke tape på et af dem.",
                    animation: .turnPedals
                ),
                GuideStep(
                    title: "Giv hvert led en dråbe",
                    detail: "Drej pedalen langsomt. Giv hvert led én dråbe olie på den nederste del af kæden. Stop, når du er tilbage ved startleddet.",
                    symbol: "drop",
                    tip: "Vådolie holder bedst i regnvejr. Tørolie samler mindre snavs om sommeren.",
                    animation: .oilChain
                ),
                GuideStep(
                    title: "Lad olien trække ind",
                    detail: "Drej pedalerne rundt 15-20 gange. Skift gerne gear imens, hvis cyklen har gear. Så kommer olien helt ind i leddene.",
                    symbol: "arrow.triangle.2.circlepath",
                    animation: .turnPedals
                ),
                GuideStep(
                    title: "Tør overskuddet af",
                    detail: "Vent et par minutter. Tør så kæden af udvendigt med en ren klud. Olien skal sidde inde i leddene – udenpå samler den bare snavs.",
                    symbol: "checkmark.circle",
                    warning: "Har du fået olie på bremserne eller hjulets kant, så tør det af med sprit, før du kører.",
                    animation: .wipeChain
                ),
            ]
        ),

        Repair(
            id: "stram-kaede",
            title: "Stram en slap kæde",
            summary: "Kæden hopper af, eller den slår mod kædeskærmen, når du kører. På cykler uden gear ved baghjulet strammes kæden ved at flytte baghjulet lidt bagud.",
            part: .chain,
            difficulty: .medium,
            minutes: 25,
            tools: [
                "Skruenøgle 15 mm (til møtrikkerne på baghjulet)",
                "Skruenøgle 10 mm (til bremsearmen)",
                "Evt. unbrakonøgle (sekskantet nøgle)",
            ],
            partsCost: 0,
            mechanicPrice: 200,
            steps: [
                GuideStep(
                    title: "Vend cyklen om",
                    detail: "Vend cyklen på hovedet, så den står på sadel og styr. Så kan du dreje pedalerne med hånden.",
                    symbol: "arrow.uturn.down",
                    animation: .flipBike
                ),
                GuideStep(
                    title: "Mærk hvor slap kæden er",
                    detail: "Tryk kæden op og ned midt mellem pedalerne og baghjulet. Den må kun kunne flytte sig 1-1,5 cm. Drej pedalerne lidt, og mærk flere steder.",
                    symbol: "ruler",
                    tip: "Kæden er strammere nogle steder end andre. Mål der, hvor den er strammest.",
                    animation: .turnPedals
                ),
                GuideStep(
                    title: "Løsn bremsearmen",
                    detail: "Har du fodbremse eller rullebremse, går der en flad metalarm fra baghjulets midte frem langs stellet. Den holdes fast af en lille bøjle med en bolt. Løsn bolten et par omgange mod uret med 10 mm-nøglen.",
                    symbol: "lock.open",
                    animation: .loosenBolt
                ),
                GuideStep(
                    title: "Løsn baghjulet",
                    detail: "Løsn de store møtrikker på begge sider af baghjulets midte med 15 mm-nøglen. Drej mod uret en halv til en hel omgang. Hjulet skal kunne flyttes, men ikke falde ud.",
                    symbol: "wrench.adjustable",
                    animation: .loosenBolt
                ),
                GuideStep(
                    title: "Træk hjulet bagud",
                    detail: "Træk hjulet væk fra pedalerne, til kæden kun kan flytte sig 1-1,5 cm. Har cyklen små skruer bag hjulets aksel, så drej dem lige meget i begge sider.",
                    symbol: "arrow.left.and.right",
                    tip: "Kig langs hjulet bagfra. Det skal sidde lige i midten mellem stellets to rør.",
                    animation: .inspect
                ),
                GuideStep(
                    title: "Spænd hjulet fast",
                    detail: "Spænd møtrikkerne med uret, lidt ad gangen i hver side. De skal sidde rigtig stramt, så brug kræfter.",
                    symbol: "lock",
                    animation: .tightenBolt
                ),
                GuideStep(
                    title: "Spænd bremsearmen fast",
                    detail: "Spænd bolten i bremsearmens bøjle med uret igen, til den sidder stramt.",
                    symbol: "lock",
                    warning: "Glemmer du bremsearmen, virker bremsen ikke – og armen kan rive sig løs.",
                    animation: .tightenBolt
                ),
                GuideStep(
                    title: "Drej pedalerne",
                    detail: "Drej pedalerne rundt. Kæden må ikke være stram eller slap noget sted. Har cyklen gear, så prøv dem alle.",
                    symbol: "arrow.triangle.2.circlepath",
                    animation: .turnPedals
                ),
                GuideStep(
                    title: "Prøv bremserne",
                    detail: "Vend cyklen om igen. Tril den frem, og prøv alle bremser, også fodbremsen, hvis du har en.",
                    symbol: "checkmark.circle",
                    warning: "Prøv bremserne, før du kører ud i trafikken.",
                    animation: .squeezeBrake
                ),
            ],
            drivetrains: [.singleSpeed, .hubGear]
        ),

        Repair(
            id: "skift-kaede",
            title: "Skift en slidt kæde",
            summary: "Kæden hopper, når du træder hårdt, eller den har kørt 3.000-5.000 km. Skifter du den i tide, slipper du for at købe nye tandhjul.",
            part: .chain,
            difficulty: .medium,
            minutes: 30,
            tools: [
                "Ny kæde med samleled (et led, man kan klikke sammen)",
                "Kædeslidmåler (lille måleværktøj til kæden)",
                "Kædeskiller (værktøj der presser kæden fra hinanden)",
                "Samleledstang (tang til at åbne samleleddet)",
            ],
            partsCost: 220,
            mechanicPrice: 450,
            steps: [
                GuideStep(
                    title: "Mål om kæden er slidt",
                    detail: "Sæt kædeslidmålerens to små tapper ned i kæden. Falder den helt ned ved 0,5 eller 0,75, er kæden slidt. Kan den ikke komme ned, er kæden fin.",
                    symbol: "ruler",
                    tip: "Falder måleren ned ved 1, er tandhjulene ofte også slidte. Så skal de skiftes med, ellers hopper den nye kæde.",
                    animation: .inspect
                ),
                GuideStep(
                    title: "Køb den rigtige kæde",
                    detail: "Tæl tandhjulene ved baghjulet. Kæden skal passe til det tal, fx 9, 10 eller 11 gear. Tag gerne den gamle kæde med i butikken.",
                    symbol: "tag",
                    animation: .inspect
                ),
                GuideStep(
                    title: "Vend cyklen om",
                    detail: "Vend cyklen på hovedet, så den står på sadel og styr. Så kan du dreje pedalerne med hånden.",
                    symbol: "arrow.uturn.down",
                    animation: .flipBike
                ),
                GuideStep(
                    title: "Skift til de mindste tandhjul",
                    detail: "Drej pedalerne, og skift til det mindste tandhjul foran og bagpå. Så hænger kæden løst og er nem at arbejde med.",
                    symbol: "gearshape",
                    animation: .shiftGears
                ),
                GuideStep(
                    title: "Åbn den gamle kæde",
                    detail: "Find samleleddet (et led, der ser anderledes ud). Klem det sammen med samleledstangen, til det glider fra hinanden. Er der intet samleled, så pres en af de små pinde ud med kædeskilleren.",
                    symbol: "scissors",
                    tip: "Tag et billede af, hvordan kæden løber gennem armen under baghjulet, før du tager den af.",
                    animation: .removeChain
                ),
                GuideStep(
                    title: "Gør den nye kæde lige lang",
                    detail: "Læg den nye og den gamle kæde ved siden af hinanden. Tæl leddene, og gør den nye lige så lang med kædeskilleren. Begge ender skal være smalle led, så samleleddet passer.",
                    symbol: "ruler",
                    tip: "Den gamle kæde er strakt lidt. Tæl derfor led i stedet for at måle længden.",
                    animation: .inspect
                ),
                GuideStep(
                    title: "Læg den nye kæde på",
                    detail: "Læg kæden om det forreste tandhjul ved pedalerne og over det mindste tandhjul bagpå. Før den gennem de to små hjul på armen under baghjulet, præcis som på dit billede.",
                    symbol: "arrow.triangle.2.circlepath",
                    animation: .removeChain
                ),
                GuideStep(
                    title: "Klik samleleddet sammen",
                    detail: "Sæt samleleddet i kædens to ender. Drej pedalen, til leddet sidder øverst. Hold baghjulet fast, og tryk pedalen hårdt fremad, til du hører et klik.",
                    symbol: "link",
                    warning: "Tjek, at leddet er helt lukket på begge sider. Et halvt lukket led kan springe op, når du træder hårdt.",
                    animation: .turnPedals
                ),
                GuideStep(
                    title: "Prøv alle gear",
                    detail: "Drej pedalerne, og skift gennem alle gear et ad gangen. Kæden skal skifte roligt uden at hoppe.",
                    symbol: "gearshape.2",
                    animation: .shiftGears
                ),
                GuideStep(
                    title: "Prøvekør",
                    detail: "Vend cyklen om, og kør en kort tur et roligt sted. Træd hårdt i de gear, du bruger mest, og mærk efter, at kæden ikke hopper.",
                    symbol: "bicycle",
                    animation: .turnPedals
                ),
            ],
            drivetrains: [.derailleur]
        ),

        // MARK: - Gear

        Repair(
            id: "juster-bagskifter",
            title: "Få gearene til at skifte rent",
            summary: "Gearene skifter trægt, hopper, eller kæden rasler. Som regel skal gearkablet bare strammes en smule med en skrue, du kan dreje med fingrene.",
            part: .gears,
            difficulty: .medium,
            minutes: 30,
            tools: [
                "Lille stjerneskruetrækker (med et kryds i spidsen)",
                "Unbrakonøgle 5 mm (sekskantet nøgle)",
            ],
            partsCost: 0,
            mechanicPrice: 250,
            steps: [
                GuideStep(
                    title: "Tjek at geararmen hænger lige",
                    detail: "Gå om bag cyklen, og kig på armen med de to små hjul under baghjulets tandhjul. Den skal hænge lodret ned. Er den bøjet ind mod hjulet, fx efter et styrt, skal en mekaniker rette den.",
                    symbol: "eye",
                    animation: .inspect
                ),
                GuideStep(
                    title: "Vend cyklen om",
                    detail: "Vend cyklen på hovedet, så den står på sadel og styr. Så kan baghjulet dreje frit, mens du drejer pedalerne med hånden.",
                    symbol: "arrow.uturn.down",
                    animation: .flipBike
                ),
                GuideStep(
                    title: "Skift til mindste tandhjul",
                    detail: "Drej pedalerne fremad, og skift til det mindste tandhjul bagpå. Det er det yderste, længst væk fra hjulet.",
                    symbol: "gearshape",
                    animation: .shiftGears
                ),
                GuideStep(
                    title: "Find justerskruen",
                    detail: "Følg gearkablet fra gearhåndtaget på styret. Der hvor kablet går ind i håndtaget eller i armen ved baghjulet, sidder en lille rund skrue med riller. Den kan du dreje med fingrene.",
                    symbol: "magnifyingglass",
                    animation: .inspect
                ),
                GuideStep(
                    title: "Stram kablet lidt",
                    detail: "Skift ét gear op, mens du drejer pedalerne. Hopper kæden ikke med det samme op på næste tandhjul, så drej justerskruen en kvart omgang mod uret. Prøv igen, til kæden skifter med det samme.",
                    symbol: "arrow.counterclockwise",
                    tip: "Rasler kæden mod det næste større tandhjul, er kablet for stramt. Drej så en kvart omgang med uret i stedet.",
                    animation: .adjustCable
                ),
                GuideStep(
                    title: "Prøv alle gear",
                    detail: "Skift et gear ad gangen hele vejen op og ned igen. Juster en kvart omgang ad gangen, til alle gear skifter præcist og kører stille.",
                    symbol: "arrow.triangle.2.circlepath",
                    animation: .shiftGears
                ),
                GuideStep(
                    title: "Tjek det største tandhjul",
                    detail: "Skift til det største tandhjul. Kæden må ikke kunne gå forbi det og ind i egerne (de tynde metalpinde i hjulet). Gør den det, så skru skruen mærket L en kvart omgang med uret ad gangen.",
                    symbol: "screwdriver",
                    warning: "Ryger kæden ind i egerne under kørsel, kan baghjulet låse. Er du i tvivl, så lad en mekaniker gøre det.",
                    animation: .tightenBolt
                ),
                GuideStep(
                    title: "Prøvekør",
                    detail: "Vend cyklen om, og kør en kort tur et roligt sted. Skift gennem alle gear, mens du træder.",
                    symbol: "bicycle",
                    animation: .turnPedals
                ),
            ],
            drivetrains: [.derailleur]
        ),

        Repair(
            id: "juster-navgear",
            title: "Juster gear, der springer",
            summary: "Pedalerne slipper pludselig, eller gearet hopper, når du træder. Gearkablet har strakt sig, og du skal stramme det, til to små streger ved baghjulet står ud for hinanden.",
            part: .gears,
            difficulty: .hard,
            minutes: 20,
            tools: ["Intet værktøj – kun fingrene", "Evt. lommelygte (eller telefonens lys)"],
            partsCost: 0,
            mechanicPrice: 250,
            steps: [
                GuideStep(
                    title: "Find mærket på baghjulet",
                    detail: "Kig på midten af baghjulet, i siden hvor kablet kommer ind. Står der Shimano Nexus eller Alfine, er der et lille vindue med streger. Står der Sturmey-Archer, stikker der en lille kæde ud af akslen.",
                    symbol: "magnifyingglass",
                    animation: .inspect
                ),
                GuideStep(
                    title: "Vend cyklen om",
                    detail: "Vend cyklen på hovedet, så den står på sadel og styr. Så kan du dreje pedalerne med hånden, mens du skifter gear.",
                    symbol: "arrow.uturn.down",
                    animation: .flipBike
                ),
                GuideStep(
                    title: "Skift op og ned én gang",
                    detail: "Drej pedalerne, og skift helt op i det højeste gear og ned igen. Så lægger kablet sig rigtigt.",
                    symbol: "arrow.up.and.down",
                    animation: .shiftGears
                ),
                GuideStep(
                    title: "Skift til justeringsgearet",
                    detail: "Har du Shimano med 7 eller 8 gear, så skift til 4. gear. Har du Shimano med 3 gear eller Sturmey-Archer, så skift til 2. gear.",
                    symbol: "gearshape.2",
                    animation: .shiftGears
                ),
                GuideStep(
                    title: "Find de to streger",
                    detail: "Lys ind i vinduet ved baghjulets midte, ofte nedefra. Du ser to små gule eller røde streger. På Sturmey-Archer skal enden af den lille kæde flugte med enden af akslen.",
                    symbol: "eye",
                    tip: "Er vinduet svært at se ind i, så tag et billede med telefonen og zoom ind.",
                    animation: .inspect
                ),
                GuideStep(
                    title: "Drej justerskruen",
                    detail: "Find den lille rillede skrue, hvor kablet går ind i gearhåndtaget på styret. Drej den lidt ad gangen, og kig i vinduet efter hver drejning. Stop, når de to streger står lige ud for hinanden.",
                    symbol: "arrow.clockwise",
                    animation: .adjustCable
                ),
                GuideStep(
                    title: "Tjek stregerne igen",
                    detail: "Skift op i det højeste gear og tilbage til justeringsgearet. Stregerne skal stadig stå ud for hinanden. Gør de ikke det, så juster igen.",
                    symbol: "arrow.triangle.2.circlepath",
                    animation: .shiftGears
                ),
                GuideStep(
                    title: "Prøvekør",
                    detail: "Vend cyklen om, og kør en tur et stille sted. Træd hårdt i alle gear, mens du står op i pedalerne. Springer det stadig, er kablet eller gearet slidt, og så skal cyklen til en mekaniker.",
                    symbol: "bicycle",
                    warning: "Et gear, der springer, kan få foden til at glide af pedalen. Prøv det et stille sted, før du kører i trafikken.",
                    animation: .turnPedals
                ),
            ],
            drivetrains: [.hubGear]
        ),

        Repair(
            id: "navgear-service",
            title: "Gear der larmer eller springer",
            summary: "Gearet larmer, eller det springer, selv om du har justeret det. Så skal gearet inde i baghjulet have ny olie eller nye dele – det klarer en mekaniker.",
            part: .gears,
            difficulty: .mechanic,
            minutes: 90,
            tools: [],
            partsCost: 200,
            mechanicPrice: 1_100,
            steps: [
                GuideStep(
                    title: "Læg mærke til problemet",
                    detail: "Mærk efter, i hvilke gear det sker. Sker det, når du træder hårdt, når det er koldt, eller hele tiden? Find mærket på baghjulets midte, fx Shimano Nexus 7.",
                    symbol: "eye",
                    animation: .shiftGears
                ),
                GuideStep(
                    title: "Det skal du fortælle mekanikeren",
                    detail: "Fortæl mærket på gearet, og hvornår problemet sker. Sig også, om du selv har prøvet at justere det. Spørg om prisen på et oliebad, før de skifter dele.",
                    symbol: "text.bubble",
                    tip: "Et Shimano-gear i baghjulet har godt af et oliebad cirka hver 5.000 km eller hvert andet år.",
                    animation: .inspect
                ),
            ],
            drivetrains: [.hubGear]
        ),

        // MARK: - Bremser

        Repair(
            id: "skift-faelgbremseklodser",
            title: "Skift slidte bremseklodser",
            summary: "Bremserne hviner, eller du skal trække hårdt i håndtaget for at stoppe. Gummiklodserne, der klemmer om hjulet, er slidte – nye er billige og hurtige at sætte på.",
            part: .brakes,
            difficulty: .medium,
            minutes: 30,
            tools: [
                "Nye bremseklodser (tag en gammel med i butikken)",
                "Unbrakonøgle 4 og 5 mm (sekskantede nøgler)",
                "Klud og sprit",
            ],
            partsCost: 120,
            mechanicPrice: 300,
            steps: [
                GuideStep(
                    title: "Tjek om klodserne er slidte",
                    detail: "Kig på gummiklodserne, der klemmer om fælgen (metalringen dækket sidder på). De har små riller. Er rillerne næsten væk, eller kan du se metal, skal de skiftes.",
                    symbol: "eye",
                    animation: .inspect
                ),
                GuideStep(
                    title: "Åbn bremsen",
                    detail: "Klem bremsearmene sammen ved hjulet med den ene hånd. Hægt kablets ende af med den anden, eller vip det lille håndtag på bremsen op. Så får du mere plads.",
                    symbol: "lock.open",
                    animation: .adjustCable
                ),
                GuideStep(
                    title: "Skru den gamle klods af",
                    detail: "Drej bolten bag klodsen mod uret med unbrakonøglen. Tag klodsen af. Læg de små buede skiver på bordet i den rækkefølge, de sad.",
                    symbol: "wrench.adjustable",
                    tip: "Tag et billede, før du skruer af. Så ved du præcis, hvordan skiverne skal sidde.",
                    animation: .loosenBolt
                ),
                GuideStep(
                    title: "Sæt den nye klods i",
                    detail: "Sæt den nye klods i med skiverne i samme rækkefølge. Se efter en pil eller \"L\" og \"R\" på klodsen. Pilen skal pege den vej, hjulet drejer, når du kører fremad.",
                    symbol: "arrow.left.and.right",
                    animation: .replaceBrakePads
                ),
                GuideStep(
                    title: "Ret klodsen ind",
                    detail: "Spænd bolten let, så klodsen lige kan flyttes. Klem bremsen med hånden, så klodsen ligger mod fælgen. Den skal ramme midt på metalkanten – aldrig dækket.",
                    symbol: "hand.raised",
                    warning: "En klods, der rammer dækket, kan slide hul i det og få dækket til at sprænge.",
                    animation: .squeezeBrake
                ),
                GuideStep(
                    title: "Spænd klodsen fast",
                    detail: "Hold bremsen klemt, og spænd bolten med uret. Det skal føles stramt, men du skal ikke hænge på nøglen.",
                    symbol: "lock",
                    animation: .tightenBolt
                ),
                GuideStep(
                    title: "Gør det samme i den anden side",
                    detail: "Skift klodsen i den anden side af hjulet på samme måde. Er klodserne på det andet hjul også slidte, så skift dem bagefter.",
                    symbol: "arrow.triangle.2.circlepath",
                    animation: .replaceBrakePads
                ),
                GuideStep(
                    title: "Luk bremsen og juster",
                    detail: "Hægt kablet på igen. Drej den lille rillede skrue ved håndtaget, til klodserne står 1-2 mm fra fælgen. Håndtaget må ikke kunne trækkes helt ind til styret.",
                    symbol: "arrow.clockwise",
                    animation: .adjustCable
                ),
                GuideStep(
                    title: "Prøv bremsen",
                    detail: "Tør fælgen af med sprit. Træk hårdt i håndtaget, og skub cyklen frem. Hjulet skal stå helt stille.",
                    symbol: "checkmark.circle",
                    warning: "Prøv bremserne, før du kører ud i trafikken.",
                    animation: .squeezeBrake
                ),
            ],
            brakeTypes: [.rim]
        ),

        Repair(
            id: "skift-skivebremseklodser",
            title: "Skift klodser i skivebremsen",
            summary: "Bremsen hyler metallisk, eller den bremser dårligere end før. Bremsen ved metalskiven i hjulets midte har små klodser, der slides – de er hurtige at skifte.",
            part: .brakes,
            difficulty: .medium,
            minutes: 30,
            tools: [
                "Nye klodser til din bremsemodel",
                "Unbrakonøgle eller Torx T25 (stjerneformet nøgle)",
                "Dækjern i plastik (lille plastikspatel)",
                "Tang",
                "Sprit og ren klud",
            ],
            partsCost: 180,
            mechanicPrice: 350,
            steps: [
                GuideStep(
                    title: "Tjek klodserne",
                    detail: "Lys ned i bremsen ved metalskiven med en lommelygte. Du ser to klodser, en på hver side af skiven. Er der under 1 mm belægning tilbage på dem, skal de skiftes.",
                    symbol: "eye",
                    animation: .inspect
                ),
                GuideStep(
                    title: "Vend cyklen om",
                    detail: "Vend cyklen på hovedet, så den står på sadel og styr. Så er det nemt at tage hjulet af.",
                    symbol: "arrow.uturn.down",
                    animation: .flipBike
                ),
                GuideStep(
                    title: "Tag hjulet af",
                    detail: "Løsn håndtaget eller akslen i hjulets midte, og løft hjulet ud. Skiven glider ud mellem klodserne.",
                    symbol: "wrench.adjustable",
                    warning: "Tryk ikke på bremsehåndtaget, mens hjulet er ude. Så klemmer klodserne sammen og er svære at få fra hinanden igen.",
                    animation: .removeFrontWheel
                ),
                GuideStep(
                    title: "Fjern sikringen",
                    detail: "Klodserne holdes på plads af en lille split, clips eller bolt. Ret splitten ud med tangen og træk den ud, eller skru bolten af.",
                    symbol: "lock.open",
                    animation: .loosenBolt
                ),
                GuideStep(
                    title: "Tag de gamle klodser ud",
                    detail: "Træk klodserne og den lille fjeder imellem dem ud af bremsen. De kommer typisk ud opad eller nedad. Læg mærke til, hvordan fjederen vender.",
                    symbol: "hand.raised",
                    animation: .replaceBrakePads
                ),
                GuideStep(
                    title: "Skub stemplerne tilbage",
                    detail: "Inde i bremsen sidder to runde stempler, der skubber klodserne ud. Sæt plastikdækjernet ind imellem dem, og pres dem forsigtigt helt tilbage. Så er der plads til de tykkere nye klodser.",
                    symbol: "arrow.left.and.right",
                    tip: "Brug aldrig en skruetrækker. Den kan ridse stemplerne, så bremsen begynder at lække.",
                    animation: .inspect
                ),
                GuideStep(
                    title: "Sæt de nye klodser i",
                    detail: "Sæt de nye klodser sammen med fjederen, og skub dem på plads. Sæt splitten eller bolten i igen.",
                    symbol: "link",
                    warning: "Rør ikke klodsernes belægning eller skiven med fingrene. Fedt fra huden gør bremsen meget svagere.",
                    animation: .replaceBrakePads
                ),
                GuideStep(
                    title: "Sæt hjulet på",
                    detail: "Sæt hjulet i, så skiven glider ind mellem klodserne. Luk håndtaget, eller spænd akslen med uret, til den sidder stramt.",
                    symbol: "lock",
                    animation: .tightenBolt
                ),
                GuideStep(
                    title: "Pump bremsehåndtaget",
                    detail: "Vend cyklen om. Træk bremsehåndtaget 10-15 gange, til klodserne ligger an, og håndtaget føles fast.",
                    symbol: "hand.raised",
                    animation: .squeezeBrake
                ),
                GuideStep(
                    title: "Kør klodserne til",
                    detail: "Find et stille sted. Kør op i fart, og brems jævnt ned til gåtempo. Gør det 15-20 gange, så bremser klodserne fuldt ud.",
                    symbol: "bicycle",
                    warning: "Nye klodser bremser dårligt de første minutter. Prøv bremserne, før du kører ud i trafikken.",
                    animation: .squeezeBrake
                ),
            ],
            brakeTypes: [.disc]
        ),

        Repair(
            id: "udluft-hydrauliske-bremser",
            title: "Bremsen føles blød",
            summary: "Bremsehåndtaget føles blødt, eller det kan trækkes helt ind til styret. Så er der luft i bremsens olie, og en mekaniker skal lufte den ud.",
            part: .brakes,
            difficulty: .mechanic,
            minutes: 45,
            tools: [],
            partsCost: 100,
            mechanicPrice: 450,
            steps: [
                GuideStep(
                    title: "Lad cyklen stå",
                    detail: "Træk i bremsehåndtaget. Kan det trækkes helt ind til styret, så kør ikke på cyklen. Se efter olie på metalskiven eller klodserne.",
                    symbol: "exclamationmark.triangle",
                    warning: "En blød bremse kan svigte helt uden varsel.",
                    animation: .squeezeBrake
                ),
                GuideStep(
                    title: "Det skal du fortælle mekanikeren",
                    detail: "Fortæl, om det er for- eller bagbremsen, og om den er blevet blød pludselig eller langsomt. Nævn mærket på bremsen, fx Shimano eller SRAM. Sig også, hvis du har set olie på skiven.",
                    symbol: "text.bubble",
                    animation: .inspect
                ),
            ],
            brakeTypes: [.disc]
        ),

        Repair(
            id: "juster-rullebremse",
            title: "Stram og smør bremsen",
            summary: "Du skal trække bremsehåndtaget langt ind, eller bremsen hviner. Bremsen inde i hjulets midte skal strammes lidt og have fedt en gang om året.",
            part: .brakes,
            difficulty: .easy,
            minutes: 15,
            tools: ["Rullebremsefedt fra Shimano (en lille tube fra cykelhandlen)", "Klud"],
            partsCost: 70,
            mechanicPrice: 200,
            steps: [
                GuideStep(
                    title: "Mærk på håndtaget",
                    detail: "Træk i bremsehåndtaget. Bremsen skal tage fat, når du har trukket cirka en tredjedel. Kan du trække det næsten ind til styret, skal kablet strammes.",
                    symbol: "hand.raised",
                    animation: .squeezeBrake
                ),
                GuideStep(
                    title: "Løsn den lille møtrik",
                    detail: "Hvor kablet går ind i håndtaget, sidder en rillet skrue med en tynd møtrik. Drej møtrikken et par omgange væk fra håndtaget med fingrene.",
                    symbol: "lock.open",
                    animation: .loosenBolt
                ),
                GuideStep(
                    title: "Stram kablet",
                    detail: "Drej den rillede skrue mod uret, så den kommer lidt ud af håndtaget. Mærk på håndtaget efter hver omgang. Stop, når bremsen tager fat efter en tredjedel.",
                    symbol: "arrow.counterclockwise",
                    animation: .adjustCable
                ),
                GuideStep(
                    title: "Lås skruen",
                    detail: "Drej den tynde møtrik tilbage mod håndtaget, til den sidder fast. Så kan skruen ikke dreje sig løs.",
                    symbol: "lock",
                    animation: .tightenBolt
                ),
                GuideStep(
                    title: "Tjek at hjulet kører frit",
                    detail: "Løft hjulet, og drej det rundt. Det skal snurre frit og må ikke bremse, når du ikke trækker i håndtaget.",
                    symbol: "arrow.triangle.2.circlepath",
                    animation: .spinWheel
                ),
                GuideStep(
                    title: "Find hullet til fedt",
                    detail: "Kig på bremsen ved hjulets midte, i siden hvor kablet kommer ind. Der sidder en lille gummiprop. Tag den af.",
                    symbol: "magnifyingglass",
                    animation: .inspect
                ),
                GuideStep(
                    title: "Fyld fedt i",
                    detail: "Sæt tuben i hullet, og pres fedt ind, til der ikke kan være mere. Sæt proppen på igen, og tør det overskydende fedt af.",
                    symbol: "drop",
                    warning: "Brug kun det særlige rullebremsefedt. Almindelig olie eller fedt kan få bremsen til at holde op med at bremse.",
                    animation: .inspect
                ),
                GuideStep(
                    title: "Prøv bremsen",
                    detail: "Kør en kort tur et roligt sted, og brems hårdt et par gange. Så fordeler fedtet sig, og bremsen tager jævnt.",
                    symbol: "checkmark.circle",
                    warning: "Prøv bremserne, før du kører ud i trafikken.",
                    animation: .squeezeBrake
                ),
            ],
            brakeTypes: [.roller]
        ),

        Repair(
            id: "skift-rullebremse",
            title: "Bremsen bremser for dårligt",
            summary: "Bremsen hviner stadig efter smøring, eller den stopper dig for langsomt. Så er bremsen inde i hjulets midte slidt og skal skiftes af en mekaniker.",
            part: .brakes,
            difficulty: .mechanic,
            minutes: 60,
            tools: [],
            partsCost: 350,
            mechanicPrice: 800,
            steps: [
                GuideStep(
                    title: "Mærk hvad der er galt",
                    detail: "Træk i bremsen, mens du triller cyklen. Læg mærke til, om den hviner, bremser svagt eller bliver ved med at bremse, når du slipper.",
                    symbol: "hand.raised",
                    animation: .squeezeBrake
                ),
                GuideStep(
                    title: "Det skal du fortælle mekanikeren",
                    detail: "Fortæl, om det er for- eller bagbremsen, og hvad du har mærket. Spørg, om de kan prøve at smøre den først.",
                    symbol: "text.bubble",
                    tip: "Smøring løser tit problemet for en brøkdel af prisen.",
                    animation: .inspect
                ),
            ],
            brakeTypes: [.roller]
        ),

        Repair(
            id: "tjek-fodbremse",
            title: "Tjek fodbremsen",
            summary: "Du bremser ved at træde baglæns, og bremsen føles svag eller ujævn. Den virker kun, når kæden er stram, og en metalarm ved baghjulet er spændt fast.",
            part: .brakes,
            difficulty: .easy,
            minutes: 10,
            tools: ["Skruenøgle 10 mm"],
            partsCost: 0,
            mechanicPrice: 200,
            steps: [
                GuideStep(
                    title: "Prøv bremsen",
                    detail: "Træk cyklen fremad, og træd pedalen baglæns. Baghjulet skal stoppe jævnt uden ryk. Pedalen må ikke kunne gå langt tilbage, før den bremser.",
                    symbol: "hand.raised",
                    animation: .turnPedals
                ),
                GuideStep(
                    title: "Find bremsearmen",
                    detail: "Kig på venstre side af baghjulets midte, set fra sadlen. En flad metalarm går derfra frem langs stellet. Den holdes fast af en lille bøjle med en bolt.",
                    symbol: "magnifyingglass",
                    animation: .inspect
                ),
                GuideStep(
                    title: "Spænd bremsearmen",
                    detail: "Tag fat i armen, og prøv at rokke den. Sidder den løst, så spænd bolten med uret med 10 mm-nøglen, til den sidder stramt.",
                    symbol: "wrench.adjustable",
                    warning: "En løs bremsearm kan rive sig løs, når du bremser. Så har du ingen bremse.",
                    animation: .tightenBolt
                ),
                GuideStep(
                    title: "Tjek kæden",
                    detail: "Tryk kæden op og ned midt mellem pedalerne og baghjulet. Den må kun flytte sig 1-1,5 cm. Er den mere slap, så følg guiden \"Stram en slap kæde\".",
                    symbol: "link",
                    warning: "Hopper kæden af, virker fodbremsen ikke.",
                    animation: .inspect
                ),
                GuideStep(
                    title: "Hvis det ikke hjælper",
                    detail: "Bremser den stadig svagt, i ryk eller hviner, er bremsen inde i hjulet slidt. Så skal cyklen til en mekaniker.",
                    symbol: "exclamationmark.triangle",
                    animation: .inspect
                ),
            ],
            brakeTypes: [.coaster]
        ),

        // MARK: - Lys

        Repair(
            id: "skift-lygte-batteri",
            title: "Få lyset til at virke",
            summary: "Lygten er død eller lyser svagt. Uden lys risikerer du en bøde på 700 kr. og at blive overset, og det tager fem minutter at fikse.",
            part: .lights,
            difficulty: .easy,
            minutes: 10,
            tools: [
                "Nye batterier eller ny lygte",
                "Lille stjerneskruetrækker (med et kryds i spidsen)",
                "Evt. USB-kabel",
            ],
            partsCost: 150,
            mechanicPrice: 250,
            steps: [
                GuideStep(
                    title: "Se hvilken lygte du har",
                    detail: "Har lygten et låg til batterier, et USB-stik eller en ledning? En ledning betyder, at lygten får strøm fra cyklen selv – fra forhjulet eller fra elcyklens batteri.",
                    symbol: "lightbulb",
                    animation: .inspect
                ),
                GuideStep(
                    title: "Skift batterier eller lad op",
                    detail: "Har lygten et USB-stik, så lad den op, til den lille lampe lyser grønt. Har den batterier, så åbn låget, og sæt nye i. Vend plus og minus, som tegningen inde i lygten viser.",
                    symbol: "battery.100",
                    animation: .switchLight
                ),
                GuideStep(
                    title: "Tjek ledningen til forhjulet",
                    detail: "Har lygten en ledning, så følg den ned til midten af forhjulet. Tryk stikket helt på, og se efter, om ledningen er klemt over. Løft forhjulet, og drej det hurtigt – nu skal lygten lyse.",
                    symbol: "bolt",
                    animation: .spinWheel
                ),
                GuideStep(
                    title: "Sæt lygterne rigtigt",
                    detail: "Hvidt eller gult lys foran, rødt lys bagpå. Vip forlygten lidt nedad, så lyset rammer vejen 5-10 meter foran dig. Så blænder du ikke dem, der kommer imod dig.",
                    symbol: "flashlight.on.fill",
                    tip: "Husk også reflekser: hvid foran, rød bagpå og gule i pedalerne og hjulene.",
                    animation: .tightenBolt
                ),
                GuideStep(
                    title: "Tænd og tjek",
                    detail: "Tænd begge lygter, og gå et par meter væk. Lyset skal kunne ses tydeligt, også når det er mørkt.",
                    symbol: "checkmark.circle",
                    animation: .switchLight
                ),
            ]
        ),

        // MARK: - Sadel

        Repair(
            id: "juster-sadelhoejde",
            title: "Sæt sadlen i den rigtige højde",
            summary: "Knæene gør ondt, eller det føles tungt at træde. En sadel i den rigtige højde skåner dine knæ og giver mere fart for de samme kræfter.",
            part: .saddle,
            difficulty: .easy,
            minutes: 10,
            tools: ["Unbrakonøgle 4-6 mm (sekskantet nøgle) eller skruenøgle 13 mm – det afhænger af din cykel"],
            partsCost: 0,
            mechanicPrice: 100,
            steps: [
                GuideStep(
                    title: "Sæt dig på cyklen",
                    detail: "Stil cyklen ved en væg, og sæt dig på sadlen med en hånd mod væggen. Drej pedalen, til den er helt nede.",
                    symbol: "bicycle",
                    animation: .turnPedals
                ),
                GuideStep(
                    title: "Mål med hælen",
                    detail: "Sæt hælen på den nederste pedal. Benet skal være næsten helt strakt. Når du så kører med forfoden på pedalen, er knæet en lille smule bøjet.",
                    symbol: "ruler",
                    animation: .inspect
                ),
                GuideStep(
                    title: "Løsn sadlen",
                    detail: "Find klemmen, hvor røret under sadlen går ned i cyklen. Vip håndtaget op, eller drej bolten mod uret med nøglen.",
                    symbol: "lock.open",
                    animation: .loosenBolt
                ),
                GuideStep(
                    title: "Flyt sadlen",
                    detail: "Træk sadlen op, eller skub den ned. Drej den, så spidsen peger lige frem langs cyklen.",
                    symbol: "arrow.up.and.down",
                    warning: "Træk aldrig røret længere op end stregen mærket \"MIN\" eller \"STOP\". Så kan det knække eller ødelægge cyklen.",
                    animation: .moveSaddle
                ),
                GuideStep(
                    title: "Spænd sadlen fast",
                    detail: "Luk håndtaget, eller drej bolten med uret. Det skal føles stramt, men ikke umuligt. Prøv at vride sadlen – den må ikke kunne dreje.",
                    symbol: "lock",
                    animation: .tightenBolt
                ),
                GuideStep(
                    title: "Prøvekør",
                    detail: "Kør en tur. Vipper hoften fra side til side, sidder sadlen for højt. Føles lårene tunge, sidder den for lavt.",
                    symbol: "checkmark.circle",
                    tip: "Juster en halv centimeter ad gangen.",
                    animation: .moveSaddle
                ),
            ]
        ),

        // MARK: - Styr

        Repair(
            id: "stram-styr",
            title: "Stram et løst styr",
            summary: "Styret kan drejes, uden at forhjulet drejer med, eller det klonker, når du bremser. Det er hurtigt at fikse og vigtigt for din sikkerhed.",
            part: .handlebar,
            difficulty: .easy,
            minutes: 15,
            tools: [
                "Unbrakonøgle 4, 5 og 6 mm (sekskantede nøgler)",
                "Evt. momentnøgle (en nøgle, der viser hvor hårdt du spænder)",
            ],
            partsCost: 0,
            mechanicPrice: 150,
            steps: [
                GuideStep(
                    title: "Prøv at dreje styret",
                    detail: "Stil dig foran cyklen, og klem forhjulet fast mellem knæene. Prøv at dreje styret. Kan det drejes, uden at hjulet følger med, er styret løst.",
                    symbol: "hand.raised",
                    animation: .alignHandlebar
                ),
                GuideStep(
                    title: "Mærk efter klonk",
                    detail: "Træk forbremsen, og vip cyklen frem og tilbage. Mærker du et lille klonk ved styret, er lejet løst – den del, der lader styret dreje.",
                    symbol: "hand.raised",
                    animation: .squeezeBrake
                ),
                GuideStep(
                    title: "Find boltene",
                    detail: "Se på stykket, der holder styret fast til cyklen. Nyere cykler har to bolte på bagsiden og én i toppen. Ældre bycykler har kun én bolt i toppen.",
                    symbol: "magnifyingglass",
                    animation: .inspect
                ),
                GuideStep(
                    title: "Løsn boltene",
                    detail: "Nyere cykler: løsn de to bolte på bagsiden et par omgange mod uret. Ældre bycykler: løsn bolten i toppen et par omgange, og slå let på den med håndfladen, så den slipper.",
                    symbol: "lock.open",
                    animation: .loosenBolt
                ),
                GuideStep(
                    title: "Ret styret lige",
                    detail: "Stil dig foran cyklen igen med hjulet mellem knæene. Drej styret, så det står helt lige på tværs af forhjulet.",
                    symbol: "arrow.left.and.right",
                    animation: .alignHandlebar
                ),
                GuideStep(
                    title: "Fjern klonket",
                    detail: "Kun nyere cykler, og kun hvis det klonkede: stram bolten i toppen en kvart omgang ad gangen, til klonket er væk. Styret skal stadig kunne dreje let.",
                    symbol: "arrow.clockwise",
                    tip: "Bolten i toppen holder ikke styret fast. Det gør boltene på bagsiden.",
                    animation: .tightenBolt
                ),
                GuideStep(
                    title: "Spænd styret fast",
                    detail: "Spænd boltene på bagsiden lidt ad gangen, skiftevis den ene og den anden. De skal sidde stramt, men du skal ikke hænge på nøglen. På ældre cykler spænder du bolten i toppen godt fast.",
                    symbol: "lock",
                    warning: "Er styret eller forgaflen af kulfiber (carbon), skal du bruge en momentnøgle. For hårdt spændte bolte kan knække det.",
                    animation: .tightenBolt
                ),
                GuideStep(
                    title: "Tjek igen",
                    detail: "Klem forhjulet mellem knæene igen, og prøv at dreje styret. Det må ikke kunne flytte sig, og der må ikke være noget klonk.",
                    symbol: "checkmark.circle",
                    animation: .alignHandlebar
                ),
            ]
        ),

        // MARK: - Pedaler

        Repair(
            id: "skift-pedaler",
            title: "Skift pedalerne",
            summary: "Pedalerne knirker, slingrer eller er slidt glatte. Nye pedaler er hurtige at sætte på – du skal bare vide, at venstre pedal skrues den modsatte vej.",
            part: .pedals,
            difficulty: .medium,
            minutes: 20,
            tools: [
                "Pedalnøgle 15 mm (en lang, tynd skruenøgle) eller unbrakonøgle 6 eller 8 mm",
                "Lidt fedt fra cykelhandlen",
                "Klud",
            ],
            partsCost: 200,
            mechanicPrice: 350,
            steps: [
                GuideStep(
                    title: "Find højre og venstre",
                    detail: "Set fra sadlen sidder højre pedal i samme side som kæden. På pedalernes aksel står der R (højre) og L (venstre). Det er vigtigt, fordi de skrues hver sin vej.",
                    symbol: "magnifyingglass",
                    animation: .inspect
                ),
                GuideStep(
                    title: "Sæt nøglen på",
                    detail: "Sæt nøglen på den flade del af akslen, lige der hvor pedalen sidder fast i armen. Drej pedalen, så nøglen peger opad.",
                    symbol: "wrench.adjustable",
                    animation: .turnPedals
                ),
                GuideStep(
                    title: "Løsn pedalen",
                    detail: "Skub nøglen bagud mod baghjulet. Det løsner både højre og venstre pedal. De sidder ofte meget fast, så brug kroppen, og hold fast i armen med den anden hånd.",
                    symbol: "arrow.counterclockwise",
                    warning: "Pas på kæden og tandhjulet, hvis nøglen pludselig slipper. De kan give grimme rifter.",
                    animation: .unscrewPedal
                ),
                GuideStep(
                    title: "Skru pedalen helt af",
                    detail: "Når den har sluppet, kan du dreje resten med hånden. Gør det samme på den anden side.",
                    symbol: "arrow.counterclockwise",
                    animation: .unscrewPedal
                ),
                GuideStep(
                    title: "Smør skruegangen",
                    detail: "Tør hullet i armen af med en klud. Smør et tyndt lag fedt på skruegangen på de nye pedaler. Så sætter de sig ikke fast og knirker ikke.",
                    symbol: "drop",
                    animation: .inspect
                ),
                GuideStep(
                    title: "Skru de nye i med hånden",
                    detail: "Sæt R-pedalen i højre side og L-pedalen i venstre. Skru dem i med fingrene ved at dreje dem mod cyklens forende.",
                    symbol: "arrow.clockwise",
                    tip: "Går det tungt fra starten, sidder pedalen skævt eller i den forkerte side. Skru den ud, og prøv igen.",
                    animation: .tightenBolt
                ),
                GuideStep(
                    title: "Spænd med nøglen",
                    detail: "Spænd begge pedaler godt med nøglen. Det skal føles stramt, men du behøver ikke bruge alle dine kræfter.",
                    symbol: "lock",
                    animation: .tightenBolt
                ),
                GuideStep(
                    title: "Prøvekør",
                    detail: "Kør en tur, og mærk efter, at pedalerne drejer frit og ikke knirker.",
                    symbol: "checkmark.circle",
                    animation: .turnPedals
                ),
            ]
        ),

        // MARK: - Stel

        Repair(
            id: "revne-i-stel",
            title: "Mistanke om revne i stellet",
            summary: "Du har set en mærkelig streg i lakken, eller cyklen knirker et nyt sted. En revne i stellet (cyklens rør) kan ikke lappes – parker cyklen, og få den tjekket.",
            part: .frame,
            difficulty: .mechanic,
            minutes: 30,
            tools: [],
            partsCost: 0,
            mechanicPrice: 350,
            steps: [
                GuideStep(
                    title: "Her skal du kigge",
                    detail: "Revner kommer oftest der, hvor rørene er svejset sammen: ved styret, ved pedalerne og under sadlen. Kig efter fine streger, rust i en lige linje eller lak, der skaller af. Nye knirkelyde kan også være et tegn.",
                    symbol: "magnifyingglass",
                    warning: "Kør ikke på cyklen, hvis du tror, den har en revne. Et stel kan knække pludselig under kørsel.",
                    animation: .inspect
                ),
                GuideStep(
                    title: "Det skal du fortælle mekanikeren",
                    detail: "Vis præcis, hvor revnen er. Fortæl, om cyklen har været væltet eller påkørt. Spørg, om stellet er dækket af garanti – mange mærker giver 5-10 år.",
                    symbol: "text.bubble",
                    tip: "Tag billeder af revnen og find kvitteringen for cyklen, før du tager den ind.",
                    animation: .inspect
                ),
            ]
        ),
    ]
}
