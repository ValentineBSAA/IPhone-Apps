import Foundation

/// A browsable, offline name-finding aid, NOT a verified list of current
/// package labels, drug interactions, indications or patient instructions.
/// Built from generic/brand-name references in MedlinePlus and FDA/NLM
/// labeling resources reviewed 2026-11-20. Every drug needs its own label.
struct PosiesMedicationReference: Identifiable, Equatable {
    let name: String
    let brands: [String]
    let category: String
    let cautionKey: String
    var id: String { name }
    var brandSummary: String { brands.joined(separator: ", ") }
    var caution: String {
        switch cautionKey {
        case "midodrine": return "Can raise blood pressure while lying down. Review individual timing and monitoring with your prescriber."
        case "fludrocortisone": return "May change blood pressure, fluid retention and potassium levels. Follow your clinician’s monitoring plan."
        case "pyridostigmine": return "Stomach upset, diarrhea and other effects can occur. Review your individual instructions and interactions."
        case "ivabradine": return "Can slow heart rate and has important pregnancy precautions. Check the current medication guide and your care plan."
        case "droxidopa": return "May raise blood pressure while lying down. Ask about monitoring and your individual instructions."
        case "beta": return "Can lower heart rate and blood pressure. Stopping suddenly may be risky; ask your prescriber before any change."
        case "bp": return "Can change blood pressure or cause dizziness. Review interactions and any clinician-requested monitoring."
        case "diuretic": return "Can affect fluid and electrolyte balance. Review kidney and potassium monitoring with your care team."
        case "potassium": return "May increase potassium levels. Kidney conditions, potassium products and other medicines can affect safety."
        case "statin": return "Review muscle-related symptoms, interactions and liver-related precautions in the current product label."
        case "heart": return "Requires careful individual monitoring and interaction review. Use only your exact prescribed product information."
        case "anticoag": return "Bleeding risk and interactions can be serious. Check your specific missed-dose and warning instructions."
        case "antiplatelet": return "May raise bleeding risk, including with some over-the-counter pain medicines. Review interactions."
        case "acetaminophen": return "Acetaminophen is present in many combination products. Taking too much can cause serious liver damage."
        case "nsaid": return "NSAIDs can carry stomach-bleeding, kidney and cardiovascular risks. Review interactions and the exact label."
        case "aspirin": return "May increase bleeding risk and interact with other blood thinners or pain relievers. Review your own label."
        case "sedating": return "May cause drowsiness, dizziness or impaired alertness. Check alcohol and interaction warnings."
        case "opioid": return "Can cause severe sedation and breathing problems, especially with certain other medicines or alcohol."
        case "topical": return "Check the exact product, application area and directions. Different formulations have different precautions."
        case "migraine": return "Check interactions and cardiovascular precautions for this exact migraine product and formulation."
        case "neurologic": return "Review dizziness, alertness, interactions and medicine-specific monitoring with your clinician."
        case "antiemetic": return "Some nausea medicines have heart-rhythm, movement-related or sedation precautions. Verify the exact product."
        case "allergy": return "Some allergy medicines cause drowsiness. Check the exact ingredient, other medications and label directions."
        case "montelukast": return "Has important mental-health warnings. Read the current FDA medication information before use."
        case "nasal": return "Check the exact spray ingredient, instructions and medicine-specific cautions on your product label."
        case "decongestant": return "Decongestants can affect heart rate or blood pressure. Ask about safety if you track palpitations or POTS symptoms."
        case "inhaler": return "Check your exact inhaler and technique. Some respiratory medicines may cause tremor or heart-rate changes."
        case "inhaledSteroid": return "Check inhaler-specific technique, precautions and interactions; use instructions from your own prescription."
        case "acid": return "Review product-specific timing, interactions and kidney-related precautions if relevant."
        case "antacid": return "Antacids can interfere with absorption of some medicines. Check timing and kidney-related precautions."
        case "gut": return "Read your exact label for possible interactions, dehydration and digestive side effects."
        case "antidepressant": return "Some products have serious interaction, mood and stopping precautions. Never change treatment based on this app."
        case "mental": return "Review sedation, heart-rate, mood and interaction warnings for your specific product."
        case "sleepRx": return "May impair alertness and next-day driving. Review the current Medication Guide and other sedating medicines."
        case "benzodiazepine": return "Can cause sedation and dependence; combining with opioids or alcohol can be dangerous."
        case "lithium": return "Requires clinician-guided monitoring and careful attention to fluid balance and interactions."
        case "stimulant": return "Can affect heart rate, blood pressure, sleep or appetite. Follow the monitoring plan from your prescriber."
        case "thyroid": return "Dose, timing and absorption instructions are product-specific; use your own label and monitoring plan."
        case "diabetes": return "Blood sugar and kidney-related precautions differ by product. Check current label and clinician guidance."
        case "insulin": return "Mix-ups or incorrect use can cause dangerous blood-sugar changes. Confirm the exact insulin and your own plan."
        case "glp1": return "May have digestive and dehydration-related precautions. Review the specific product label and care plan."
        case "steroid": return "May affect blood sugar, blood pressure, mood and infection risk. Ask before changing treatment."
        case "hormone": return "Hormone products and formulations differ. Review clot-related or other warnings for the exact product."
        case "infection": return "Allergies, interactions and completing the specific prescription need individual guidance."
        case "antifungal": return "Can interact with other medicines and may require liver or other monitoring; check the exact product."
        case "antiviral": return "Check kidney-related precautions, interactions and the exact directions from your own prescription."
        case "supplement": return "Supplements may interact with medicines. Check the ingredient, form and amount on your own label."
        case "electrolyte": return "Sodium and potassium products can be unsafe for some conditions or medicines. Follow clinician guidance."
        default: return "Review the exact active ingredients, current labeling and interactions with a pharmacist."
        }
    }
    var detailURL: URL {
        let raw: String
        switch name {
        case "Acetaminophen": raw = "https://medlineplus.gov/druginfo/meds/a681004.html"
        case "Ibuprofen": raw = "https://medlineplus.gov/druginfo/meds/a682159.html"
        case "Naproxen": raw = "https://medlineplus.gov/druginfo/meds/a681029.html"
        case "Midodrine": raw = "https://medlineplus.gov/druginfo/meds/a616030.html"
        case "Propranolol": raw = "https://medlineplus.gov/druginfo/meds/a682607.html"
        case "Metoprolol": raw = "https://medlineplus.gov/druginfo/meds/a682864.html"
        case "Ivabradine": raw = "https://medlineplus.gov/druginfo/meds/a615027.html"
        case "Fludrocortisone": raw = "https://medlineplus.gov/druginfo/meds/a682549.html"
        case "Pyridostigmine": raw = "https://medlineplus.gov/druginfo/meds/a682229.html"
        case "Droxidopa": raw = "https://medlineplus.gov/druginfo/meds/a614025.html"
        case "Apixaban": raw = "https://medlineplus.gov/druginfo/meds/a613032.html"
        case "Pseudoephedrine": raw = "https://medlineplus.gov/druginfo/meds/a682619.html"
        case "Diphenhydramine": raw = "https://medlineplus.gov/druginfo/meds/a682539.html"
        case "Spironolactone": raw = "https://medlineplus.gov/druginfo/meds/a682627.html"
        case "Sertraline": raw = "https://medlineplus.gov/druginfo/meds/a697048.html"
        case "Doxylamine": raw = "https://medlineplus.gov/druginfo/meds/a682537.html"
        case "Dimenhydrinate": raw = "https://medlineplus.gov/druginfo/meds/a607046.html"
        default: raw = "https://medlineplus.gov/druginformation.html"
        }
        return URL(string: raw)!
    }
    var hasDirectReference: Bool { detailURL.absoluteString != "https://medlineplus.gov/druginformation.html" }

    /// DailyMed is an up-to-date FDA-submitted label search, not a guarantee
    /// that every result is the same formulation as the person's own package.
    var dailyMedSearchURL: URL {
        var components = URLComponents(string: "https://dailymed.nlm.nih.gov/dailymed/search.cfm")!
        components.queryItems = [
            URLQueryItem(name: "labeltype", value: "all"),
            URLQueryItem(name: "query", value: name)
        ]
        return components.url!
    }

    /// A library name fills a DRAFT profile only. Never infer strength,
    /// administration, schedule, dose, treatment indication or intake status.
    var draftProfile: PosiesMedicationProfile {
        PosiesMedicationProfile(name: name, schedule: "Not set")
    }
}

enum PosiesMedicationCatalog {
    static let reviewedOn = "November 20, 2026"
    private static let rows = """
        Midodrine|ProAmatine|Autonomic & circulation|midodrine
        Fludrocortisone|Florinef|Autonomic & circulation|fludrocortisone
        Pyridostigmine|Mestinon|Autonomic & circulation|pyridostigmine
        Ivabradine|Corlanor|Autonomic & circulation|ivabradine
        Propranolol|Inderal|Autonomic & circulation|beta
        Metoprolol|Lopressor, Toprol-XL|Autonomic & circulation|beta
        Bisoprolol|Zebeta|Autonomic & circulation|beta
        Atenolol|Tenormin|Autonomic & circulation|beta
        Clonidine|Catapres|Autonomic & circulation|bp
        Guanfacine|Intuniv, Tenex|Autonomic & circulation|bp
        Droxidopa|Northera|Autonomic & circulation|droxidopa
        Desmopressin|DDAVP|Autonomic & circulation|electrolyte
        Lisinopril|Zestril, Prinivil|Heart & blood pressure|bp
        Losartan|Cozaar|Heart & blood pressure|bp
        Valsartan|Diovan|Heart & blood pressure|bp
        Amlodipine|Norvasc|Heart & blood pressure|bp
        Diltiazem|Cardizem|Heart & blood pressure|bp
        Verapamil|Calan|Heart & blood pressure|bp
        Carvedilol|Coreg|Heart & blood pressure|beta
        Hydrochlorothiazide|Microzide|Heart & blood pressure|diuretic
        Furosemide|Lasix|Heart & blood pressure|diuretic
        Spironolactone|Aldactone|Heart & blood pressure|potassium
        Eplerenone|Inspra|Heart & blood pressure|potassium
        Hydralazine|Apresoline|Heart & blood pressure|bp
        Atorvastatin|Lipitor|Heart & blood pressure|statin
        Rosuvastatin|Crestor|Heart & blood pressure|statin
        Simvastatin|Zocor|Heart & blood pressure|statin
        Ezetimibe|Zetia|Heart & blood pressure|statin
        Apixaban|Eliquis|Heart & blood pressure|anticoag
        Rivaroxaban|Xarelto|Heart & blood pressure|anticoag
        Warfarin|Coumadin, Jantoven|Heart & blood pressure|anticoag
        Clopidogrel|Plavix|Heart & blood pressure|antiplatelet
        Digoxin|Lanoxin|Heart & blood pressure|heart
        Acetaminophen|Tylenol|Pain & fever|acetaminophen
        Ibuprofen|Advil, Motrin|Pain & fever|nsaid
        Naproxen|Aleve|Pain & fever|nsaid
        Aspirin|Bayer Aspirin|Pain & fever|aspirin
        Celecoxib|Celebrex|Pain & fever|nsaid
        Meloxicam|Mobic|Pain & fever|nsaid
        Diclofenac|Voltaren|Pain & fever|nsaid
        Gabapentin|Neurontin|Pain & fever|sedating
        Pregabalin|Lyrica|Pain & fever|sedating
        Cyclobenzaprine|Flexeril|Pain & fever|sedating
        Baclofen|Lioresal|Pain & fever|sedating
        Tramadol|Ultram|Pain & fever|opioid
        Lidocaine topical|Lidoderm|Pain & fever|topical
        Sumatriptan|Imitrex|Migraine & nausea|migraine
        Rizatriptan|Maxalt|Migraine & nausea|migraine
        Eletriptan|Relpax|Migraine & nausea|migraine
        Topiramate|Topamax|Migraine & nausea|neurologic
        Amitriptyline|Elavil|Migraine & nausea|antidepressant
        Nortriptyline|Pamelor|Migraine & nausea|antidepressant
        Rimegepant|Nurtec ODT|Migraine & nausea|migraine
        Ubrogepant|Ubrelvy|Migraine & nausea|migraine
        Erenumab|Aimovig|Migraine & nausea|migraine
        Ondansetron|Zofran|Migraine & nausea|antiemetic
        Metoclopramide|Reglan|Migraine & nausea|antiemetic
        Promethazine|Phenergan|Migraine & nausea|sedating
        Prochlorperazine|Compazine|Migraine & nausea|antiemetic
        Meclizine|Antivert, Bonine|Migraine & nausea|sedating
        Dimenhydrinate|Dramamine|Migraine & nausea|sedating
        Cetirizine|Zyrtec|Allergies & breathing|allergy
        Levocetirizine|Xyzal|Allergies & breathing|allergy
        Loratadine|Claritin|Allergies & breathing|allergy
        Fexofenadine|Allegra|Allergies & breathing|allergy
        Diphenhydramine|Benadryl|Allergies & breathing|sedating
        Hydroxyzine|Atarax, Vistaril|Allergies & breathing|sedating
        Montelukast|Singulair|Allergies & breathing|montelukast
        Fluticasone nasal|Flonase|Allergies & breathing|nasal
        Azelastine nasal|Astepro|Allergies & breathing|nasal
        Pseudoephedrine|Sudafed|Allergies & breathing|decongestant
        Phenylephrine oral|Sudafed PE|Allergies & breathing|decongestant
        Albuterol|Ventolin, ProAir|Allergies & breathing|inhaler
        Budesonide inhaled|Pulmicort|Allergies & breathing|inhaledSteroid
        Fluticasone inhaled|Flovent|Allergies & breathing|inhaledSteroid
        Ipratropium|Atrovent|Allergies & breathing|inhaler
        Tiotropium|Spiriva|Allergies & breathing|inhaler
        Famotidine|Pepcid|Stomach & digestion|acid
        Omeprazole|Prilosec|Stomach & digestion|acid
        Esomeprazole|Nexium|Stomach & digestion|acid
        Pantoprazole|Protonix|Stomach & digestion|acid
        Lansoprazole|Prevacid|Stomach & digestion|acid
        Calcium carbonate antacid|Tums|Stomach & digestion|antacid
        Simethicone|Gas-X|Stomach & digestion|gut
        Loperamide|Imodium|Stomach & digestion|gut
        Polyethylene glycol 3350|MiraLAX|Stomach & digestion|gut
        Senna|Senokot|Stomach & digestion|gut
        Docusate|Colace|Stomach & digestion|gut
        Bisacodyl|Dulcolax|Stomach & digestion|gut
        Linaclotide|Linzess|Stomach & digestion|gut
        Dicyclomine|Bentyl|Stomach & digestion|gut
        Sucralfate|Carafate|Stomach & digestion|acid
        Sertraline|Zoloft|Mood & sleep|antidepressant
        Fluoxetine|Prozac|Mood & sleep|antidepressant
        Escitalopram|Lexapro|Mood & sleep|antidepressant
        Citalopram|Celexa|Mood & sleep|antidepressant
        Paroxetine|Paxil|Mood & sleep|antidepressant
        Venlafaxine|Effexor XR|Mood & sleep|antidepressant
        Desvenlafaxine|Pristiq|Mood & sleep|antidepressant
        Duloxetine|Cymbalta|Mood & sleep|antidepressant
        Bupropion|Wellbutrin|Mood & sleep|antidepressant
        Mirtazapine|Remeron|Mood & sleep|antidepressant
        Buspirone|BuSpar|Mood & sleep|mental
        Trazodone|Desyrel|Mood & sleep|sedating
        Doxylamine|Unisom SleepTabs|Mood & sleep|sedating
        Zolpidem|Ambien|Mood & sleep|sleepRx
        Lorazepam|Ativan|Mood & sleep|benzodiazepine
        Clonazepam|Klonopin|Mood & sleep|benzodiazepine
        Alprazolam|Xanax|Mood & sleep|benzodiazepine
        Quetiapine|Seroquel|Mood & sleep|mental
        Lamotrigine|Lamictal|Mood & sleep|neurologic
        Lithium|Lithobid|Mood & sleep|lithium
        Methylphenidate|Ritalin, Concerta|Focus & attention|stimulant
        Amphetamine/dextroamphetamine|Adderall|Focus & attention|stimulant
        Lisdexamfetamine|Vyvanse|Focus & attention|stimulant
        Atomoxetine|Strattera|Focus & attention|stimulant
        Levothyroxine|Synthroid, Levoxyl|Hormones & diabetes|thyroid
        Liothyronine|Cytomel|Hormones & diabetes|thyroid
        Metformin|Glucophage|Hormones & diabetes|diabetes
        Insulin glargine|Lantus|Hormones & diabetes|insulin
        Insulin lispro|Humalog|Hormones & diabetes|insulin
        Semaglutide|Ozempic, Wegovy|Hormones & diabetes|glp1
        Tirzepatide|Mounjaro, Zepbound|Hormones & diabetes|glp1
        Empagliflozin|Jardiance|Hormones & diabetes|diabetes
        Glipizide|Glucotrol|Hormones & diabetes|diabetes
        Prednisone|Rayos|Hormones & diabetes|steroid
        Methylprednisolone|Medrol|Hormones & diabetes|steroid
        Estradiol|Estrace|Hormones & diabetes|hormone
        Progesterone|Prometrium|Hormones & diabetes|hormone
        Ethinyl estradiol/levonorgestrel|Aviane, Alesse|Hormones & diabetes|hormone
        Norethindrone||Hormones & diabetes|hormone
        Amoxicillin|Amoxil|Infections|infection
        Amoxicillin/clavulanate|Augmentin|Infections|infection
        Azithromycin|Zithromax|Infections|infection
        Doxycycline|Vibramycin|Infections|infection
        Cephalexin|Keflex|Infections|infection
        Clindamycin|Cleocin|Infections|infection
        Nitrofurantoin|Macrobid|Infections|infection
        Trimethoprim/sulfamethoxazole|Bactrim|Infections|infection
        Metronidazole|Flagyl|Infections|infection
        Fluconazole|Diflucan|Infections|antifungal
        Valacyclovir|Valtrex|Infections|antiviral
        Acyclovir|Zovirax|Infections|antiviral
        Ferrous sulfate (iron)||Vitamins & supplements|supplement
        Vitamin D3 (cholecalciferol)||Vitamins & supplements|supplement
        Vitamin B12 (cyanocobalamin)||Vitamins & supplements|supplement
        Magnesium glycinate||Vitamins & supplements|supplement
        Magnesium oxide||Vitamins & supplements|supplement
        Potassium chloride|Klor-Con|Vitamins & supplements|electrolyte
        Sodium chloride tablets||Vitamins & supplements|electrolyte
        Oral rehydration salts||Vitamins & supplements|electrolyte
        Folic acid||Vitamins & supplements|supplement
        Multivitamin||Vitamins & supplements|supplement
        Zinc||Vitamins & supplements|supplement
        Vitamin C (ascorbic acid)||Vitamins & supplements|supplement
        Omega-3 fish oil||Vitamins & supplements|supplement
        Coenzyme Q10||Vitamins & supplements|supplement
        Vitamin B6 (pyridoxine)||Vitamins & supplements|supplement
        Melatonin||Vitamins & supplements|supplement
        """
    static let all: [PosiesMedicationReference] = rows.split(whereSeparator: \.isNewline).compactMap { row in
        let parts = row.split(separator: "|", omittingEmptySubsequences: false).map(String.init)
        guard parts.count == 4 else { return nil }
        let brands = parts[1].split(separator: ",").map {
            String($0).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return PosiesMedicationReference(name: parts[0], brands: brands,
                                         category: parts[2], cautionKey: parts[3])
    }.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }

    static var categories: [String] {
        Array(Set(all.map(\.category))).sorted()
    }
    static func find(_ query: String) -> PosiesMedicationReference? {
        let term = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !term.isEmpty else { return nil }
        return all.first {
            $0.name.compare(term, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame ||
            $0.brands.contains { brand in brand.compare(term, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame }
        }
    }
    static func search(_ query: String, category: String = "All") -> [PosiesMedicationReference] {
        let term = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return all.filter { item in
            (category == "All" || item.category == category) &&
            (term.isEmpty || item.name.localizedStandardContains(term) ||
             item.brands.contains { $0.localizedStandardContains(term) })
        }
    }
}
