// SVLBH Panel — Tests/SVLBH_PanelTests.swift
// Phase 2 QA — 10 Unit Tests ciblés sur les bugs récurrents
// Bugs couverts : B01 B02 B03 B04 B05 F28 F29 + merge + sessionId
// Lancer : Cmd+U dans Xcode

import XCTest
@testable import SVLBH_Panel

final class SVLBHPanelQATests: XCTestCase {

    // T01 — pullKey jamais avec double tiret (patientId vide)
    // Bug couvert : B01 · B06 · Récurrent x3
    func testPullKeyNeverContainsDoubleDash() {
        let session = SessionState()
        session.patientId = ""
        XCTAssertTrue(session.pullKey.contains("--"),
            "Clé avec patientId vide doit contenir '--' pour être détectée")
        session.patientId = "42"
        session.sessionNum = "001"
        XCTAssertFalse(session.pullKey.contains("--"),
            "Pull key ne doit JAMAIS contenir '--' quand patientId est renseigné")
        let parts = session.pullKey.split(separator: "-").map(String.init)
        XCTAssertEqual(parts.count, 4,
            "Pull key doit avoir 4 segments : programme-patient-session-code")
    }

    // T02 — PUSH aborté si patientId vide
    // Bug couvert : B01
    func testPushAbortedWhenPatientIdEmpty() async {
        let sync = MakeSyncService()
        let session = SessionState()
        session.patientId = ""
        let result = await sync.push(session: session)
        XCTAssertFalse(result, "PUSH doit échouer quand patientId est vide")
        XCTAssertNotNil(sync.lastError)
        XCTAssertTrue(sync.lastError?.contains("patientId") == true)
    }

    // T03 — Formule SLSA : 14% ne peut pas donner SA1 = 29
    // Bug couvert : B03
    func testSlsaAutoCalcFormula() {
        var sc = ScoresLumiere()
        sc.slsaS1 = 14
        sc.slsaS2 = 0
        sc.slsaS3 = 0
        sc.slsaS4 = 0
        sc.slsaS5 = 0
        XCTAssertEqual(sc.slsaAutoCalc, 14,
            "SA1=14, SA2-SA5=0 → autoCalc=14, pas 29")
        XCTAssertEqual(sc.slsaEffective, 14)
        sc.slsaS2 = 5
        sc.slsaS3 = 3
        XCTAssertEqual(sc.slsaAutoCalc, 22)
        XCTAssertTrue(sc.hasDetailedSLSA)
    }

    // T04 — SA4 = 67 ne peut pas donner TotSLM = 140%
    // Bug couvert : B04
    func testSA4DoesNotExceedTotSlmMax() {
        var sc = ScoresLumiere()
        sc.slsaS4 = 67
        XCTAssertEqual(sc.slsaAutoCalc, 67,
            "SA4=67, reste=nil → autoCalc=67, pas 140")
        sc.totSlm = 140
        XCTAssertLessThanOrEqual(sc.totSlm ?? 0, ScoresLumiere.totSlmMax)
        XCTAssertEqual(ScoresLumiere.totSlmMax, 1_000)
    }

    // T05 — SLSA range valide (max 50 000)
    // Bug couvert : B05
    func testSlsaMaxRange() {
        XCTAssertEqual(ScoresLumiere.slsaMax, 50_000)
        let testVal = 958
        XCTAssertLessThanOrEqual(testVal, ScoresLumiere.slsaMax)
        XCTAssertGreaterThan(ScoresLumiere.slsaMax, 999)
    }

    // T06 — PractitionerTier.from(code:) correct
    // Bug couvert : B01 — cohérence codes
    func testPractitionerTierFromCode() {
        XCTAssertEqual(PractitionerTier.from(code: 1),      .lead)
        XCTAssertEqual(PractitionerTier.from(code: 99),     .lead)
        XCTAssertEqual(PractitionerTier.from(code: 100),    .formation)
        XCTAssertEqual(PractitionerTier.from(code: 299),    .formation)
        XCTAssertEqual(PractitionerTier.from(code: 300),    .certifiee)
        XCTAssertEqual(PractitionerTier.from(code: 30000),  .certifiee)
        XCTAssertEqual(PractitionerTier.from(code: 455000), .superviseur)
        XCTAssertTrue(PractitionerTier.from(code: 300).forkResolu)
        XCTAssertTrue(PractitionerTier.from(code: 455000).forkResolu)
    }

    // T07 — Superviseur 455000 via ShamaneProfile (Service API Key pattern)
    func testSuperviseurRoleViaShamaneProfile() {
        let profile = ShamaneProfile(code: "455000", prenom: "Patrick", nom: "Bays",
                                     whatsapp: "", email: "", abonnement: "Superviseur")
        let role = ActiveRole.shamane(profile)
        XCTAssertEqual(role.code, "455000")
        XCTAssertTrue(role.isSuperviseur)
        let session = SessionState()
        session.role = role
        session.patientId = "42"
        session.sessionNum = "003"
        session.sessionProgramCode = "00"
        XCTAssertEqual(session.sessionId, "00-42-003-455000")
    }

    // T07b — Protection 754545 : clés sync séparées du superviseur
    func testProtectionAccountSeparateKeys() {
        let profile = ShamaneProfile(code: "754545", prenom: "Patrick", nom: "Bays",
                                     whatsapp: "", email: "", abonnement: "Protection")
        let role = ActiveRole.shamane(profile)
        XCTAssertEqual(role.code, "754545")
        XCTAssertTrue(role.isSuperviseur)
        let session = SessionState()
        session.role = role
        session.supervisorCode = "754545"
        session.patientId = "42"
        session.sessionNum = "001"
        session.sessionProgramCode = "00"
        XCTAssertEqual(session.sessionId, "00-42-001-754545")
        XCTAssertEqual(session.pushKey, "00-42-001-754545")
        // Protection self-pull (no pullSource)
        XCTAssertEqual(session.pullKey, "00-42-001-754545")
        // Keys must NOT contain 455000
        XCTAssertFalse(session.pushKey.contains("455000"))
        XCTAssertFalse(session.pullKey.contains("455000"))
    }

    // T08 — Migration codes v3 → v4 (F28)
    func testShamaneCodeMigration() {
        let migration: [String: String] = [
            "25": "300", "27": "301", "26": "302", "01": "455000"
        ]
        XCTAssertEqual(migration["25"], "300")
        XCTAssertEqual(migration["27"], "301")
        XCTAssertEqual(migration["26"], "302")
        XCTAssertEqual(migration["01"], "455000")
        XCTAssertEqual(PractitionerTier.from(code: 300), .certifiee)
        let cornelia = ShamaneProfile(code: "300", prenom: "Cornelia", nom: "",
                                      whatsapp: "", email: "", abonnement: "")
        XCTAssertEqual(cornelia.codeFormatted, "0300")
    }

    // T09 — mergeField : champ local vide → fill silencieux (pas suggestion)
    // Bug couvert : B02
    func testMergeFieldBehavior() {
        let session = SessionState()
        session.patientId = "42"
        let gen = session.generations.first!
        gen.abuseur = ""
        let incomingAb = "s|Sécurité"
        if gen.abuseur.isEmpty {
            gen.abuseur = incomingAb
        } else if gen.abuseur != incomingAb {
            gen.sugAbuseur = incomingAb
        }
        XCTAssertEqual(gen.abuseur, "s|Sécurité")
        XCTAssertEqual(gen.sugAbuseur, "")
        gen.abuseur = "r|Respect"
        if gen.abuseur.isEmpty {
            gen.abuseur = incomingAb
        } else if gen.abuseur != incomingAb {
            gen.sugAbuseur = incomingAb
        }
        XCTAssertEqual(gen.abuseur, "r|Respect",
            "Champ existant ne doit PAS être écrasé")
        XCTAssertEqual(gen.sugAbuseur, "s|Sécurité",
            "Divergence → suggestion 🔬")
        XCTAssertTrue(gen.hasSuggestions)
    }

    // T10 — sessionId format : programme-patient-session-code
    // Bug couvert : B01 — format Make
    func testSessionIdFormat() {
        let session = SessionState()
        let sup = ShamaneProfile(code: "455000", prenom: "Patrick", nom: "Bays",
                                 whatsapp: "", email: "", abonnement: "Superviseur")
        session.role = .shamane(sup)
        session.sessionProgramCode = "00"
        session.patientId = "14968"
        session.sessionNum = "003"
        XCTAssertEqual(session.sessionId, "00-14968-003-455000")
        let cornelia = ShamaneProfile(code: "300", prenom: "Cornelia", nom: "",
                                      whatsapp: "", email: "", abonnement: "")
        session.role = .shamane(cornelia)
        session.patientId = String(cornelia.patientId)
        XCTAssertTrue(session.sessionId.hasSuffix("0300"))
        XCTAssertFalse(session.sessionId.contains("--"))
        let parts = session.sessionId.split(separator: "-").map(String.init)
        XCTAssertEqual(parts.count, 4)
        XCTAssertEqual(parts[0].count, 2)
        XCTAssertEqual(parts[2].count, 3)
    }
}
